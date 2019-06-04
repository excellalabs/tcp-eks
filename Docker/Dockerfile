# This Dockerfile adds AWS CLI, Chef, and Terraform to the Ubuntu image

FROM ubuntu:18.04

ARG AWS_EKS_URL=https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.13/2019-03-13/bin

WORKDIR tcp-eks
COPY / .

RUN apt-get update -y && apt-get install curl wget unzip -y
RUN wget https://packages.chef.io/files/stable/chefdk/3.2.30/ubuntu/18.04/chefdk_3.2.30-1_amd64.deb \
&& dpkg -i chefdk_3.2.30-1_amd64.deb

RUN wget --quiet https://releases.hashicorp.com/terraform/0.11.3/terraform_0.11.3_linux_amd64.zip \
  && unzip terraform_0.11.3_linux_amd64.zip \
  && mv terraform /usr/bin \
  && rm terraform_0.11.3_linux_amd64.zip

RUN curl "${AWS_EKS_URL}/linux/amd64/kubectl" -o "/usr/local/bin/kubectl" && \
    curl "${AWS_EKS_URL}/linux/amd64/aws-iam-authenticator" -o "/usr/local/bin/aws-iam-authenticator" && \
    cd /usr/local/bin && chmod +x ./kubectl ./aws-iam-authenticator

RUN echo -n "pwd: " && pwd && \
    echo -n "Terraform v: " && terraform --version && \
    echo -n "kubectl v: " && kubectl version --client --short && \
    echo -n "aws-iam-authenticator v: " && aws-iam-authenticator | head -4

RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
    unzip awscli-bundle.zip && \
    apk add --update python && \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && \
    echo -n "aws cli v: " && aws --version

CMD sh

ENTRYPOINT sh
