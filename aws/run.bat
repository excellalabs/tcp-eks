@ECHO OFF
SET KEY_ROOT="..\keys"

IF NOT EXIST %KEY_ROOT%\ecs (
  ssh-keygen -t rsa -b 4096 -a 100 -N "" -f %KEY_ROOT%\ecs
  ssh-keygen -f %KEY_ROOT%\ecs.pub -m pem -e > %KEY_ROOT%\ecs.pem
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
  berks package cookbooks.tar.gz --berksfile=cookbooks\bench-demo\Berksfile
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
  ECHO Valid arguments are: init, plan, apply, and destroy, and chef
)

IF NOT EXIST "%1" (
  ECHO Running ALL Teraform options: init, plan, apply
  IF NOT EXIST .terraform (
    terraform init 
  )
  terraform plan -out=tfplan
  terraform apply tfplan
)
