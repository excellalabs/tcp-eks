@ECHO OFF
SET KEY_ROOT="..\keys"
SET CI_PROJECT_NAME="tcp-eks"

IF NOT EXIST %KEY_ROOT%\%CI_PROJECT_NAME% (
  ssh-keygen -t rsa -b 4096 -a 100 -N "" -f %KEY_ROOT%\%CI_PROJECT_NAME%
  ssh-keygen -f %KEY_ROOT%\%CI_PROJECT_NAME%.pub -m pem -e > %KEY_ROOT%\%CI_PROJECT_NAME%.pem
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

IF /I "%1"=="destroy" (
  terraform destroy -force 
)

IF /I "%1"=="help" (
  ECHO Valid arguments are: init, plan, apply, and destroy
)

IF NOT EXIST "%1" (
  ECHO Running ALL Teraform options: init, plan, apply
  IF NOT EXIST .terraform (
    terraform init 
  )
  terraform plan -out=tfplan
  terraform apply tfplan
)
