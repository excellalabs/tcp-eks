FROM ubuntu:18.04

WORKDIR tcp-eks
COPY / .

RUN apt-get update -y && apt-get install wget unzip -y
RUN wget https://packages.chef.io/files/stable/chefdk/3.2.30/ubuntu/18.04/chefdk_3.2.30-1_amd64.deb \
&& dpkg -i chefdk_3.2.30-1_amd64.deb

RUN wget --quiet https://releases.hashicorp.com/terraform/0.11.3/terraform_0.11.3_linux_amd64.zip \
  && unzip terraform_0.11.3_linux_amd64.zip \
  && mv terraform /usr/bin \
  && rm terraform_0.11.3_linux_amd64.zip
