@ECHO OFF

IF NOT "%~4"=="" GOTO USAGE

@SET PROJECT_NAME=%1
@SET AWS_DEFAULT_REGION=%2
@SET ENVIRONMENT=%3
@SET CLUSTER_NAME=%CI_PROJECT_NAME%-%ENVIRONMENT%

SET KEY_ROOT="keys"

IF NOT EXIST %KEY_ROOT%\%CI_PROJECT_NAME%.pem (
  ssh-keygen -t rsa -b 4096 -a 100 -N "" -f %KEY_ROOT%\%CI_PROJECT_NAME%
  ssh-keygen -f %KEY_ROOT%\%CI_PROJECT_NAME%.pub -t pem -e > %KEY_ROOT%\%CI_PROJECT_NAME%.pem
  aws s3 cp %KEY_ROOT%\%CI_PROJECT_NAME%.pub s3://%CLUSTER_NAME%/%KEY_ROOT%/%CI_PROJECT_NAME%.pub
  aws s3 ls s3://%CLUSTER_NAME%/%AWS_DEFAULT_REGION%/%KEY_ROOT%
)

@ECHO Creating %CLUSTER_NAME% cluster in %AWS_DEFAULT_REGION% region

cd aws
terraform init -backend-config="bucket=%CLUSTER_NAME%" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=%AWS_DEFAULT_REGION%" \
  -backend-config="encrypt=true"
terraform plan
terraform apply -auto-approve
aws s3 cp kubeconfig.yaml s3://%CLUSTER_NAME%/%AWS_DEFAULT_REGION%/
aws s3 ls s3://%CLUSTER_NAME%/%AWS_DEFAULT_REGION%/
GOTO :EOF

:USAGE
@ECHO "Usage: %0 <CI_PROJECT_NAME> <AWS_DEFAULT_REGION> <ENVIRONMENT>"