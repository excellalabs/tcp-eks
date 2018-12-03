#!/usr/bin/env bash
set -eu

realpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

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
    if [ ! -d $KEY_ROOT ]; then
      mkdir $KEY_ROOT
    fi
    if [ ! -f $KEY_ROOT/bastion ]; then
      echo "${BOLD}Creating SSH keys for bastion instance${NORMAL}"
      ssh-keygen -t rsa -b 4096 -o -a 100 -f $KEY_ROOT/bastion
      ssh-keygen -f $KEY_ROOT/bastion.pub -m pem -e > $KEY_ROOT/bastion.pem
    fi
    if [ ! -f $KEY_ROOT/cluster ]; then
      echo "${BOLD}Creating SSH keys for cluster instances${NORMAL}"
      ssh-keygen -t rsa -b 4096 -o -a 100 -N "" -f $KEY_ROOT/cluster
      ssh-keygen -f $KEY_ROOT/cluster.pub -m pem -e > $KEY_ROOT/cluster.pem
    fi
    if [ ! -f $KEY_ROOT/jenkins ]; then
      echo "${BOLD}Creating SSH keys for Jenkins instance${NORMAL}"
      ssh-keygen -t rsa -b 4096 -o -a 100 -N "" -f $KEY_ROOT/jenkins
      ssh-keygen -f $KEY_ROOT/jenkins.pub -m pem -e > $KEY_ROOT/jenkins.pem
    fi
    terraform init 
    ;;
  plan)
    terraform plan -out tfplan
    ;;
  apply)
    terraform apply tfplan
    ;;
  all)
    popd &> /dev/null
    eval $0 init
    eval $0 plan
    eval $0 apply
    ;;
  destroy)
    terraform destroy 
    ;;
  chef)
    pushd modules/jenkins-master
    berks package ./cookbooks.tar.gz --berksfile=./cookbooks/demo/Berksfile
    popd
    scp -i ../keys/jenkins modules/jenkins-master/cookbooks.tar.gz  ubuntu@$(terraform output jenkins_master_public_dns):/tmp/
    ssh -i ../keys/jenkins ubuntu@$(terraform output jenkins_master_public_dns) sudo chef-solo --recipe-url /tmp/cookbooks.tar.gz -j /tmp/chef.json
    ;;
  kube)
    curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/darwin/amd64/kubectl
    curl -o aws-iam-authenticator https://amazon-eks.s3-uswest-2.amazonaws.com/1.10.3/2018-07-26/bin/darwin/amd64/aws-iam-authenticator
    chmod +x ./kubectl
    chmod +x ./aws-iam-authenticator
    ;;
  *)
    error_and_exit "$USAGE"
    ;;
esac
cleanup
