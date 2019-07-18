# This Dockerfile adds AWS CLI, Chef, Git, and Terraform to the Ubuntu image

FROM ubuntu:18.04

ARG AWS_EKS_URL=https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.13/2019-03-13/bin
ARG CHEF_VER=3.2.30
ARG TERRAFORM_VER=0.12.5

WORKDIR tcp-eks
COPY / .
COPY .netrc /root

RUN apt-get update -y && apt-get install curl git wget unzip vim -y

RUN wget https://packages.chef.io/files/stable/chefdk/${CHEF_VER}/ubuntu/18.04/chefdk_${CHEF_VER}-1_amd64.deb \
  && dpkg -i chefdk_${CHEF_VER}-1_amd64.deb

RUN wget --quiet https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_linux_amd64.zip \
  && unzip terraform_${TERRAFORM_VER}_linux_amd64.zip \
  && mv terraform /usr/bin \
  && rm terraform_${TERRAFORM_VER}_linux_amd64.zip

RUN curl "${AWS_EKS_URL}/linux/amd64/kubectl" -o "/usr/local/bin/kubectl" && \
    curl "${AWS_EKS_URL}/linux/amd64/aws-iam-authenticator" -o "/usr/local/bin/aws-iam-authenticator" && \
    cd /usr/local/bin && chmod +x ./kubectl ./aws-iam-authenticator

RUN echo -n "pwd: " && pwd && \
    echo -n "Terraform v: " && terraform --version && \
    echo -n "kubectl v: " && kubectl version --client --short && \
    echo -n "aws-iam-authenticator v: " && aws-iam-authenticator | head -4

RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
    unzip awscli-bundle.zip && \
    apt-get install python -y && \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && \
    echo -n "aws cli v: " && aws --version

ENTRYPOINT ["/bin/sh", "-c", "bin/create_s3; bin/create_env; tail -f /dev/null;"]