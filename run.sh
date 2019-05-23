#!/usr/bin/env bash
set -eu

realpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

PROJECT_NAME="bench-tc"
AWS_REGION="us-east-1"
ENVIRONMENT="dev"
KEY_ROOT=$(realpath keys)
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

exes=(git terraform)
for i in "${exes[@]}"
do
  command -v $i >/dev/null 2>&1 || error_and_exit "$i is not installed. Aborting."
done

echo "Running [$1]"

pushd aws &> /dev/null
case "$1" in
  init)
    if [ ! -d ${KEY_ROOT} ]; then
      mkdir ${KEY_ROOT}
    fi
    if [ ! -f ${KEY_ROOT}/${PROJECT_NAME}-bastion.pub ]; then
      echo "Creating SSH keys for ${PROJECT_NAME}-bastion instance"
      ssh-keygen -t rsa -b 4096 -o -a 100 -f ${KEY_ROOT}/${PROJECT_NAME}-bastion
      ssh-keygen -f ${KEY_ROOT}/${PROJECT_NAME}-bastion.pub -m pem -e > ${KEY_ROOT}/${PROJECT_NAME}-bastion.pem
    fi
    if [ ! -f ${KEY_ROOT}/${PROJECT_NAME}-cluster.pub ]; then
      echo "Creating SSH keys for ${PROJECT_NAME}-cluster instances"
      ssh-keygen -t rsa -b 4096 -o -a 100 -N "" -f ${KEY_ROOT}/${PROJECT_NAME}-cluster
      ssh-keygen -f ${KEY_ROOT}/${PROJECT_NAME}-cluster.pub -m pem -e > ${KEY_ROOT}/${PROJECT_NAME}-cluster.pem
    fi
    if [ ! -f ${KEY_ROOT}/${PROJECT_NAME}-jenkins.pub ]; then
      echo "Creating SSH keys for ${PROJECT_NAME}-jenkins instance"
      ssh-keygen -t rsa -b 4096 -o -a 100 -N "" -f ${KEY_ROOT}/${PROJECT_NAME}-jenkins
      ssh-keygen -f ${KEY_ROOT}/${PROJECT_NAME}-jenkins.pub -m pem -e > ${KEY_ROOT}/${PROJECT_NAME}-jenkins.pem
    fi
    terraform init -backend-config="bucket=${PROJECT_NAME}-${ENVIRONMENT}" -backend-config="key=terraform.tfstate" -backend-config="region=${AWS_REGION}" -backend-config="encrypt=true"
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