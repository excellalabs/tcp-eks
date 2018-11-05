# Bench CI/CD + EKS infrastructure

This repo uses Terraform and Chef to quickly create a Jenkins instance and two EKS clusters optimized for rapid prototype development in AWS. The jenkins instance acts as both the CI/CD facilitator as well as the bastion to access instances within the VPC.

![Architecture Overview](./doc/overview.png "Architecture Overview")

Each environment (development and production) is a standalone EKS cluster. Each cluster is split across multiple availability zones with the EC2 instances residing in private subnets. A single postgres RDS instance (with multi-az enabled) is provisioned for each cluster, each application is expected to create the databases it needs within the given instance. A single ALB is created for all ingress traffic into the cluster (it is depicted in the figure as two ALBs since it is redundant across AZs), furthermore a NAT Gateway is provided for each EKS cluster to allow internet connectivity for EC2 cluster instances. Note: if you need more environments and are running up against EIP account limits, then the reduntant NAT Gateway in each cluster can be safely removed.

![EKS Cluster](./doc/eks-cluster.png "EKS Cluster")

Upon running terraform to create the infrastructure in this repo, several AWS SSM key-value parameters will be available for reference in the CI/CD pipeline (e.g. deployment region, cluster names, ALB listener references, etc). Furthermore each application pipeline will need to coordinate resource creation/usage with what has been provided in this repo. Below is an example of such coordination:

![Pipeline Example](./doc/pipeline-flow.png "Pipeline Example")

First the `bench-infrastructure` pipeline should be run to create any globally used resources (such as docker images). In the example case above, ECR repos are created as well as SSM paramters for later use by the application pipelines, followed by building and publishing the "base" and "pipeline" docker images to ECR.

*What are these docker images?* The "base" image is what the application produciton docker image will be derived from. The "pipeline" image is used within the application pipeline to test and build the application. (It is assumed that any toolchains necessary to build and test an application will be containerized for speed and portability. In this way if a toolchain changes it will not require that Jenkins be reprovisoned, but instead, simply rebuilding the toolchain image in question. )

Once the `bench-infrastructure` pipeline completes successfully, then application pipelines can begin to run. In the example above a `bench-react` application is being tested, built, and deployed. The application pipeline in this example is using terraform to create and manage the EKS service, ECR repo (for the application production image), ALB Target changes (for facilitating routing), and persisting important key-value parameters in SSM. All terraform state is persisted to an S3 bucket and read/write coordination is achieved by locking on a dynamoDB table during any terraform action --this ensures that parallel pipeline runs aren't mutating shared state simultaneously.

Lastly, jenkins has resource locks for each environment to ensure that multiple applications are not attempting to modify the same environment at the same time. During any deployment the application pipeline should acquire an environment resource lock before attempting to deploy any application and release this lock after the deployment has finished.


## Prerequisites

Add a file called `./aws/terraform.tfvars` with the following contents:

```
# Change these
aws_access_key = "your access key"
aws_secret_key = "your secret key"
aws_region = "us-west-2"
aws_email = "your email address"

# only alpha-numeric and dashes allowed!
project_key = "something-unique"
environment = "development"

# no single quotes allowed
jenkins_developer_password = "a good password"

# no single quotes allowed
jenkins_admin_password = "a really good password"

# the user must have access to the repos that should be under ci/cd control
jenkins_github_ci_user = "your user"

# the token should have FULL repo access and FULL admin:web_hook access
jenkins_github_ci_token = "your token"

# these need to be unique per region
jenkins_key_name = "jenkins_master_ssh_key_pair_YOURNAME"
eks_key_name = "eks_ssh_key_pair_YOURNAME"

# credentials used to create any application database
# password must be greater than 8 characters
db_username = "something"
db_password = "anothergreatpasswordelse"
db_identifier = "pg-bench-db"

# Leave these alone
jenkins_seedjob_repo_owner = "excellaco"
jenkins_seedjob_repo_include = "bench-java bench-rails bench-react bench-infrastructure"
```

This is used by both of the jenkins and eks terraform modules.

[Generate Github token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) follow instructions here to generate a personal access token. Be sure to include scope for "repo" and "admin:repo_hook", otherwise your token will not allow you to scan the organization for exisiting repos.


## Provisioning Jenkins + Dev/Prod EKS Clusters

Head into the infrastructure toolchain container:
```
glue bash bench-infrastructure
```

To generate keys and provision the Jenkins infrastructure run the following from within the toolchain container:

```
./run.sh all
```

As you modify terraform code, replan and apply the changes as needed:

```
./run.sh plan
./run.sh apply
```

To destroy all created resources, run:

```
./run.sh destroy
```
