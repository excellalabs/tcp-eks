
def createCommonInfrastructure(projectKey, app) {
  environment = 'common'

  vars = [
    project_key: projectKey,
    app_name: app,
    environment: environment,
  ]

  planAndApplyTerraform(app, environment, 'lock', vars, false)
  planAndApplyTerraform(app, environment, 'common', vars)
}

def createDatabase(host, db_name, username, password) {
  sh """
    PGPASSWORD=${password} psql -h ${host} -U ${username} -tc "SELECT 1 FROM pg_database WHERE datname = '${db_name}';" postgres | grep -q 1 || \
    (PGPASSWORD=${password} psql -h ${host} -U ${username} -c "create database ${db_name};" postgres; \
    PGPASSWORD=${password} psql -h ${host} -U ${username} -c "grant all privileges on database ${db_name} to ${username};" postgres)
  """
}

def ecrLogin() {
  sh """
    eval \$(aws ecr get-login --no-include-email)
  """
}

def buildDockerImage(app, gitcommitsha, String toolchain_ecr_url = '') {
  String image = ''
  timeout(time: 10, unit: 'MINUTES') {
    String ecr_repo_url = getSSMParam("${app}_ecr_url")
    image = "${ecr_repo_url}:git-${gitcommitsha}"

    if (toolchain_ecr_url) {
      sh "sed -i 's#FROM .*#FROM ${toolchain_ecr_url}#g' pipeline/Dockerfile"
    }

    ecrLogin()

    sh """
      docker build -t "${image}" -f pipeline/Dockerfile .
      docker tag "${image}" "${ecr_repo_url}:latest"
      docker push "${image}" 
      docker push "${ecr_repo_url}:latest"
    """
  }
  return image
}

def getSSMParam(param) {
  String value = sh(script: "aws ssm get-parameters --with-decryption --names '${param}' | jq -r '.Parameters[0].Value'", returnStdout:true).trim()
  if (value == 'null') {
    throw new Exception("No SSM value for '${param}'") 
  }
  return value
}

def planAndApplyTerraform(app, environment, file, vars, lock=true) {

  // conditionally always apply any changes found, regardless of the consequence
  def alwaysApply = true

  String aws_region = getSSMParam("terraform-state-region")
  String aws_bucket = getSSMParam("terraform-state-bucket")
  String dir = "./pipeline/terraform/${file}"

  vars += [
    aws_region: aws_region,
    aws_credentials_filepath: '~/.aws/credentials',
    aws_profile: 'default',
  ]
  
  def backendVars = [
    'bucket': aws_bucket,
    'region': aws_region,
    'key': "${environment}/${app}/${file}.tfstate",
  ]

  if (lock) {
    backendVars += ['dynamodb_table': "${app}-terraform-state-lock"]
  }

  wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
    sh "terraform --version"

    // remove the terraform state file so we always start from a clean state
    if (fileExists(".terraform/terraform.tfstate")) {
      sh "rm -rf .terraform/terraform.tfstate"
    }
    if (fileExists("tfplan")) {
      sh "rm tfplan"
    }
    if (fileExists("${file}.tfvars")) {
      sh "rm -rf ${file}.tfvars"
    }

    def backendVarsStr = ""
    vars.each{ k, v -> sh "echo '${k} = \"${v}\"\n' >> ${file}.tfvars" }
    backendVars.each{ k, v -> backendVarsStr += " -backend-config '${k}=${v}'" }
    sh "cat ${file}.tfvars"

    sh "terraform init -input=false ${backendVarsStr} ${dir}"
    def planExitCode = sh(script:"terraform plan -input=false -var-file=${file}.tfvars -out=tfplan -detailed-exitcode ${dir}", returnStatus:true)

    def apply = false
    echo "Terraform Plan Exit Code: ${planExitCode}"
    if (planExitCode == 0) {
      currentBuild.result = 'SUCCESS'
    } else if (planExitCode == 1) {
      currentBuild.result = 'FAILURE'
    } else if (planExitCode == 2) {
      if (alwaysApply) {
        apply = true
      } else {
        try {
          input message: 'Apply Plan?', ok: 'Apply'
          apply = true
        } catch (err) {
          apply = false
          currentBuild.result = 'UNSTABLE'
        }
      }
    } else  {
      echo "Unknown plan status: ${planExitCode}"
      currentBuild.result = 'FAILURE'
    }

    sh "aws s3 cp ${file}.tfvars s3://${aws_bucket}/${environment}/${app}/${file}.tfvars" 

    if (apply) {
      applyExitCode = sh(script:"terraform apply -input=false tfplan", returnStatus:true)
      if (applyExitCode != 0) {
        currentBuild.result = 'FAILURE'
      }
    }
  }

}

def notifySlack(String app, String environment, String buildStatus = 'STARTED') {
  buildStatus = buildStatus ?: 'SUCCESS'

  def task = "deployment #${env.BUILD_NUMBER} of `${app}` to `${environment}`"
  def (color, state, tail) = ["", "", ""]
  
  if (buildStatus == 'STARTED') {
    state = 'Starting'
    color = '#D4DADF'
  } else if (buildStatus == 'SUCCESS' || buildStatus == 'UNSTABLE') {
    state = 'Completed'
    color = '#88C100'
    tail = ':tada:'
  } else {
    state = '*FAILED*'
    color = '#FF003C'
    tail = " :flushed: @here:\nPipeline: ${env.BUILD_URL}"
  }

  // def msg = "${state} ${task} (${env.COMMIT_TEXT}) ${tail}"
  def msg = "${state} ${task} ${tail}"

  slackSend(color: color, message: msg)
}

return this;
