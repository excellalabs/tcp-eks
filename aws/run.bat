@ECHO OFF

REM finds the architecture of the windows installation
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set arc=32BIT || set arc=64BIT

SET KEY_ROOT="..\keys"

IF NOT EXIST %KEY_ROOT%\bastion (
  ssh-keygen -t rsa -b 4096 -a 100 -N "" -f %KEY_ROOT%\bastion
  ssh-keygen -f %KEY_ROOT%\bastion.pub -t pem -e > %KEY_ROOT%\bastion.pem
)

IF NOT EXIST %KEY_ROOT%\cluster (
  ssh-keygen -t rsa -b 4096 -a 100 -N "" -f %KEY_ROOT%\cluster
  ssh-keygen -f %KEY_ROOT%\cluster.pub -t pem -e > %KEY_ROOT%\cluster.pem
)

IF /I "%1"=="init" (
  terraform init 
)

IF /I "%1"=="plan" (
  terraform plan -out=tfplan
)

IF /I "%1"=="apply" (
  terraform apply tfplan
)

IF /I "%1"=="chef" (
  cd modules\jenkins-master
  gem install berkshelf
  berks package cookbooks.tar.gz --berksfile=cookbooks\demo\Berksfile
  cd ..\..
  IF EXIST "%2" (
    scp -i ..\keys\jenkins cookbooks.tar.gz  ubuntu@%2:/tmp/
    ssh -i ..\keys\jenkins ubuntu@%2 sudo chef-solo --recipe-url /tmp/cookbooks.tar.gz -j /tmp/chef.json
  ) ELSE (
    ECHO Requires an EC2 instance IP/DNS as the second argument
  )
)

IF /I "%1"=="destroy" (
  terraform destroy -force 
)

IF /I "%1"=="help" (
  ECHO Valid arguments are: init, plan, apply, and destroy, chef, and kube
)

IF /I "%1"=="kube" (
  SET "amazon_url=https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/windows"
  SET "iam_file=%CD%\..\aws-iam-authenticator.exe"
  SET "kube_file=%CD%\..\kubectl.exe"
  IF EXIST "%iam_file%" DEL "%iam_file%"
  IF EXIST "%kube_file%" DEL "%kube_file%"
  IF %arc%==32BIT (
    SET "KUBE_URL=%amazon_url%/amd32/kubectl.exe"
    SET "IAM_URL=%amazon_url%/amd32/aws-iam-authenticator.exe"
  )
  IF %arc%==64BIT (
    SET "KUBE_URL=%amazon_url%/amd64/kubectl.exe"
    SET "IAM_URL=%amazon_url%/amd64/aws-iam-authenticator.exe"
  )
  Bitsadmin /transfer "kubectl" %KUBE_URL% "%kube_file%"
  IF EXIST "%kube_file%" START "" "%kube_file%"
  Bitsadmin /transfer "aws-iam-authenticator" %IAM_URL% "%iam_file%"
  IF EXIST "%iam_file%" START "" "%iam_file%"
)

IF NOT EXIST "%1" (
  IF NOT EXIST terraform.exe (
    SET "terraform_ver=0.11.10"
    SET "hashicorp_url=https://releases.hashicorp.com/terraform/%terraform_ver%"
    IF %arc%==32BIT (
	  SET "terraform_zip_file=terraform_%terraform_ver%_windows_386.zip"
      SET "terraform_url=%hashicorp_url%/%terraform_zip_file%"
    )
    IF %arc%==64BIT (
	  SET "terraform_zip_file=terraform_%terraform_ver%_windows_amd64.zip"
      SET "terraform_url=%hashicorp_url%/%terraform_zip_file%"
    )
    ECHO Installing from %terraform_url%
	ECHO [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 > download.ps1
	ECHO Invoke-WebRequest -Uri %terraform_url% -Outfile %terraform_zip_file% >> download.ps1
	ECHO Expand-Archive %terraform_zip_file% -DestinationPath . >> download.ps1
	Powershell -f download.ps1
	DEL download.ps1
    IF EXIST "%terraform_zip_file%" DEL "%terraform_zip_file%"
  )
  ECHO Running ALL Teraform options: init, plan, apply
  IF NOT EXIST .terraform (
    terraform init 
  )
  terraform plan -out=tfplan
  terraform apply tfplan
)
