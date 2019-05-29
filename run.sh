#!/usr/bin/env bash
set -eu

realpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

KEY_ROOT=$(realpath keys)
export CI_PROJECT_NAME="tcp-eks"
export AWS_DEFAULT_REGION="us-east-1"
USAGE="Usage: $0 init|plan|apply|destroy|chef|kube"

NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
BOLD=$(tput bold)
UNDERLINE=$(tput smul)

cleanup() {
  popd &> /dev/null
}

error_and_exit () {
  cleanup
  echo "${RED}${BOLD}$1${NORMAL}" >&2;
  exit 1
}

if [ $# -gt 2 ]; then
  error_and_exit "$USAGE"
fi

exes=(git terraform python)
for i in "${exes[@]}"
do
 #command -v $i >/dev/null 2>&1 || error_and_exit "$i is not installed. Aborting."
  command -v $i >/dev/null 2>&1 || brew install $i
done

echo "Running [$1]"

pushd aws &> /dev/null
case "$1" in
  init)
    if aws s3 ls "s3://${CI_PROJECT_NAME}" 2>&1 | grep -q 'NoSuchBucket'; then
      aws s3api create-bucket --acl private --bucket ${CI_PROJECT_NAME} --region ${AWS_DEFAULT_REGION}
    fi
    if [ ! -d ${KEY_ROOT} ]; then
      mkdir ${KEY_ROOT}
    fi
    for key in bastion cluster jenkins; do
      if [ ! -f ${KEY_ROOT}/${CI_PROJECT_NAME}-${key}.pem ]; then
        echo "Creating SSH keys for ${CI_PROJECT_NAME}-${key} instance"
        ssh-keygen -t rsa -b 4096 -o -a 100 -N "" -f ${KEY_ROOT}/${CI_PROJECT_NAME}-${key}
        ssh-keygen -f ${KEY_ROOT}/${CI_PROJECT_NAME}-${key}.pub -m pem -e > ${KEY_ROOT}/${CI_PROJECT_NAME}-${key}.pem
        aws s3 cp ${KEY_ROOT}/${CI_PROJECT_NAME}-${key}.pub s3://${CI_PROJECT_NAME}/${KEY_ROOT}/${CI_PROJECT_NAME}-${key}.pub
        aws s3 ls s3://${CI_PROJECT_NAME}/${KEY_ROOT}/
      fi
    done
    terraform init -backend-config="bucket=${CI_PROJECT_NAME}" \
      -backend-config="key=terraform/terraform.tfstate" \
      -backend-config="region=${AWS_DEFAULT_REGION}" \
      -backend-config="encrypt=true"
    ;;
  plan)
    terraform plan -out tfplan
    ;;
  apply)
    terraform apply tfplan
    ;;
  all)
    popd &> /dev/null
    curl -s -qL -o terraform.zip https://releases.hashicorp.com/terraform/0.12.0/terraform_0.12.0_darwin_amd64.zip
    unzip -o terraform.zip
    chmod +x ./terraform
    eval $0 init
    eval $0 plan
    eval $0 apply
    ;;
  destroy)
    terraform destroy 
    ;;
  chef)
    pushd modules/jenkins
    berks package ./cookbooks.tar.gz --berksfile=./cookbooks/demo/Berksfile
    popd
    scp -i ../keys/jenkins modules/jenkins/cookbooks.tar.gz ubuntu@$(terraform output jenkins_master_public_dns):/tmp/
    ssh -i ../keys/jenkins ubuntu@$(terraform output jenkins_public_dns) sudo chef-solo --recipe-url /tmp/cookbooks.tar.gz -j /tmp/chef.json
    ;;
  kube)
    curl -s -qL -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.13/2019-03-13/bin/darwin/amd64/kubectl
    curl -s -qL -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.13/2019-03-13/bin/darwin/amd64/aws-iam-authenticator
    chmod +x ./kubectl ./aws-iam-authenticator
    ;;
  *)
    error_and_exit "$USAGE"
    ;;
esac
cleanup