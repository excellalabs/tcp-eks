
def getSSMParam(param) {
  String value = sh(script: "aws ssm get-parameters --names '${param}' | jq -r '.Parameters[0].Value'", returnStdout:true).trim()
  if (value == 'null') {
    throw new Exception("No SSM value for '${param}'") 
  }
  return value
}

def destroyTerraform(app, environment, file, lock=true) {
  String aws_region = getSSMParam("terraform-state-region")
  String aws_bucket = getSSMParam("terraform-state-bucket")
  String dir = './pipeline/terraform/${file}'

  def backendVars = [
    'bucket': aws_bucket,
    'region': aws_region,
    'key': "${environment}/${app}/${file}.tfstate",
  ]

  if (lock) {
    backendVars += ['dynamodb_table': "${app}-terraform-state-lock"]
  }

  if (fileExists(".terraform/terraform.tfstate")) {
    sh "rm -rf .terraform/terraform.tfstate"
  }
  if (fileExists("${file}.tfvars")) {
    sh "rm -rf ${file}.tfvars"
  }

  def fetchVarsCode = sh(script:"aws s3 cp s3://${aws_bucket}/${environment}/${app}/${file}.tfvars ${file}.tfvars", returnStatus:true)
  if (fetchVarsCode != 0) {
    println "Destroy SKIPPED..."
    return 
  }

  def backendVarsStr = ""
  backendVars.each{ k, v -> backendVarsStr += " -backend-config '${k}=${v}'" }

  wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
    sh "terraform init -input=false ${backendVarsStr} ${dir}"

    destroyExitCode = sh(script:"terraform destroy -auto-approve -var-file=./${file}.tfvars -input=false ${dir}", returnStatus:true)
    if (destroyExitCode != 0) {
      // currentBuild.result = 'FAILURE'
      println "Destroy FAILED!"
    } else {
      sh "aws s3 rm s3://${aws_bucket}/${environment}/${app}/${file}.tfvars"
      println "Destroy Successful!"
    }
  }

}

return this
