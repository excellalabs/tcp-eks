# Deploying a Google Kubernetes Engine cluster

This is a guide to getting started with Terraform and actually doing something useful with it: We are deploying a Kubernetes cluster to Google Cloud Platform (GCP). To follow along with this guide you will need to do a few things first:

1. Create an account with GCP and set up a project. There is a free tier, plus $300 in credits for new users that you can apply for here.
2. Download the terraform binary for your platform.

Quick note: In this guide my project name is `gke-tf-bench`, please swap this for the name of the project you have just created. We are deploying to the `europe-west1` region, but you can change that to suit your needs as well.

## Service Accounts
We need a way for the Terraform runtime to authenticate with the GCP API. We could use the local gcloud SDK and our own user account, but a better practice is to create a dedicated service account for Terraform. This gives us greater control over the resources Terraform can interact with, and opens the door to future security measures like key rotation. That is outside the scope of this guide, but for now go to the Cloud Console, navigate to IAM & Admin > Service Accounts, and click Create Service Account.

Name the service account `terraform` and assign it the Project Editor role. Tick Furnish a new private key and click Create. Your browser will download a JSON file containing the details of the service account and a private key that can authenticate as a project editor to your project. Keep this JSON file safe! Anyone with access to this file can create billable resources in your project.

Create a directory called creds and copy this JSON file into it. The filename will contain a random hash, so rename it to `service_account.json` for convenience.

## APIs
Each major product group in GCP has its own API, so one more quick thing we need to do is enable the Kubernetes API for our project before Terraform can talk to it.

From the Cloud Console, navigate to APIs & Services > Dashboard, then click Enable APIs and Services. Type `kubernetes` in the search box, and you should find the Kubernetes Engine API. Then just click Enable. APIs can take a few minutes to enable fully, so fetch yourself a hot beverage at this point.

## Providers
Terraform can interact with the APIs of all the major cloud providers, plus several PaaS offerings and other applications. This is achieved through providers. So to create resources in GCP we declare that we are using the google provider. Now run `terraform init` to initialize your local environment.

If you have a problem at this stage you may not have installed the Terraform binary correctly, so please check the instructions on their website for help.

## Resources
Once the provider is in place we declare resources for Terraform to deploy. Resources are simply the pieces of infrastructure we want to create: compute instances, disks, storage buckets and so on. Declaring resources will form the bulk of most infrastructure code.

As you can see, declaring resources with Terraform is very simple. A resource definition has 2 primary arguments: the resource type (google_container_cluster) and a unique name. Note that in this example, `gke-cluster` is the unique name of the resource Terraform will use to manage its state, while `gke-rc-bench-cluster` will be the actual name of the cluster that gets created in GCP.

This short snippet of code in `gkecluster.tf` is all we need to create a fully managed Kubernetes cluster in GCP. There are lots of other options we could define for this resource (as covered in Terraform's excellent documentation) but they are all optional.

## Plan & Apply
Now run `terraform plan -out myplan` and see what happens. This is the often overlooked beauty of Terraform's declarative lifecycle. You are specifying (ie. declaring) in code the desired state of your infrastructure. It is Terraform's job to make sure that real life reflects this, so when it runs it compares the existing state of the infrastructure, any stored state that it knows about and the state you have declared in code. When you run `terraform plan` it does all this, then tells you what steps it needs to take to ensure parity between all those things.

With this command we have also told Terraform to save the plan in a local file called `myplan`. This allows us to specify a known plan in the apply stage. If you ask Terraform to apply changes without specifying a plan it will create one, but you will not get a chance to review it before it is applied.

Now you can apply the plan with: `terraform apply myplan`

After a couple of minutes, Terraform will have deployed our Kubernetes cluster. You can see this from the Cloud Console by navigating to Kubernetes Engine from the main menu.

## Changes
As stated earlier, Terraform plans changes by comparing live state, stored state and desired state. You will notice your working directory now contains a file called `terraform.tfstate` which is a JSON representation of the last known state of your managed infrastructure (that is, resources you have defined via Terraform - not necessarily all of the resources in your project). Every time this file gets updated, the previous known state is written to `terraform.tfstate.backup`. When you start working on bigger projects or wish to collaborate with other team members on changes, you can utilise a storage bucket for remote state, but that is outside the scope of this guide.

# Deploy Jenkins to Google Kubernetes Engine with Helm
You now have a Google Kubernetes Cluster up and running in Google Cloud Platform ready to start orchestrating things for you. In this guide we will explore how we can interact with our new cluster and install the Jenkins CI tool to help us automate future deployments. We will cover a lot of ground here so I will link to some deep dives on the specific tools just in case you need to take a quick detour and brush up on anything.

## gcloud + kubectl
`kubectl` is the de facto command line tool for interacting with your Kubernetes cluster. If you hare already used the `gcloud` command line tool then its likely you have `kubectl` installed, but if not you can download it. It can be configured to control multiples clusters, each within their own "context". So to begin, we will use `gcloud` to authenticate with Kubernetes and create a context for `kubectl`.

First check on the cluster you created previously:
```
gcloud container clusters list
```

This should give you a list of any GKE clusters you have along with version information, status, number of nodes etc. Your output should look similar to this:
```
NAME        LOCATION       MASTER_VERSION
gke-cluster europe-west1-b 1.8.10-gke.0
```
Our cluster looks good! Let us now use gcloud to set up the context for kubectl. You will need to specify the name of your cluster and its location:
```
gcloud container clusters get-credentials gke-cluster --zone=europe-west1-b
```

`gcloud` will tell you that it has generated a kubeconfig entry for `kubectl`. We can check that it works by querying the list of running pods in our cluster:
```
kubectl get pods --all-namespaces
```

There is a bunch of stuff running already. Tools like `kube-dns`, `heapster` and `fluentd` are part of the managed services running on your GKE cluster. If this is your first time using `kubectl` or running things on a Kubernetes cluster, I would recommend you take a quick break and follow a tutorial on the Kubernetes site. There is no point me refactoring a great tutorial. Instead, I am skipping over the basics so we can concentrate on Helm and Jenkins.

## Helm
Hopefully you are familiar with the concepts of deployments, services and other Kubernetes objects and how they can be declared and instantiated on Kubernetes clusters. The Helm project started as a Kubernetes sub-project to provide a way to simplify complex applications by grouping together all of their necessary components, parameterising them and packaging them up into a single Helm "chart". This is why Helm calls itself the package manager for Kubernetes. It has now reached a certain maturity and has been accepted by the Cloud Native Computing Foundation as an incubator project in its own right.

Helm charts are easy to write, but there are also curated charts available in their repo for most common applications. To get started with Helm, download and install the binary. There are 2 components to Helm:

1. The helm client (called, you guessed it, `helm`)
2. The helm server component, called `tiller`. `tiller` is responsible for handling requests from the helm client and interacting with the Kubernetes APIs

Before you install `tiller` on your cluster you will need to quickly set up a service account with a defined role for tiller to operate within. This is due to the introduction of Role Based Access Control (RBAC) - another huge subject for a different guide. But do not panic, it is actually very easy to set up. Apply `tiller-rbac.yaml` to your cluster with:
```
kubectl apply -f tiller-rbac.yaml
```

You are now ready to set up helm and install tiller. Run the following command and you should be good to go:
```
helm init --service-account tiller
```

Wait a few minutes to allow the tiller pod to spin up, then run: helm version

## Jenkins
Jenkins has been around a long time, and is essentially an automation server written in Java. It is commonly used for automating software builds and more recently can be found providing Continuous Integration services as well. In my personal opinion this tends to be because Jenkins is a "kitchen-sink"; in other words, you can pretty much do anything with it. This does not mean it is the best tool for the job. One of my biggest gripes with Jenkins is that traditionally it has been a pain to automate its own installation, as its XML config does not lend itself to being managed that easily, the Puppet module for Jenkins is buggy and out of date, and managing Jenkins plugins can land you in dependency hell.

Thankfully Helm has come to the rescue with a magic chart that takes most of the pain away from you. In fact once you have helm and tiller configured for your cluster, deploying the Jenkins application including persistent volumes, pods, services and a load balancer is as easy as running one command:
```
helm install --name my-release stable/jenkins
```

Helm will output some helpful instructions that guide you in accessing your newly deployed application (although it may take a few minutes for everything to get up and running the first time). You should be able to access Jenkins via its external IP address, and grab the admin password following the instructions Helm gave you.

*Quick note: By default this will stand up an external load balancer with a public IP. This is not very secure, and it will incur costs if you leave it running. You are advised to delete all these resources when you are finished with this guide.*

Helm manages the lifecycle of its deployments, so you can manage your release (which in this example we called my-release) with some simple commands:

Outputs some useful information about the deployed release
```
helm status my-release
```

Deletes the release from your cluster and purges any of its resources (services, disks etc.)
```
helm delete --purge my-release
```

Show all releases deployed to the cluster
```
helm list
```

Most Helm charts make use of a parameters file to define the attributes of a deployment, such as docker image names, resources to assign, node selectors and so forth. We did not specify a parameters file in the above example, so we just inherited the default one from the published Jenkins chart. Sometimes its useful to provide your own values, and we can do that by obtaining a copy of the default file and modifying it.

Have a browse through values.yaml and you should start to see how these values map to the pods and services that are deployed as part of this chart. For demonstration purposes, we will just make one change here, adding an extra plugin to the InstallPlugins list (around line 80):
    - blueocean:1.5.0

Now we can upgrade our release and apply the new values:
```
helm upgrade -f values.yaml my-release stable/jenkins
```

If you quickly run `kubectl get pods` you will see that the old version of your release is terminating and the new one is starting up. Once the new release is deployed, the external IP should be the same but you will need to retrieve the new admin password.

Once you have logged in you can see that Jenkins has attempted to install the BlueOcean plugin that we specified. However you may also see some errors. It appears that even with a well-written Helm chart, we cannot always escape Jenkins dependency-hell.

We can fix this by painstakingly going through the plugin dependencies and correcting the version numbers in your `values.yaml` file, then upgrading your release again.

One last thing: Newer version of Kubernetes enforce the use of Role Based Access Control (RBAC), so at the bottom of values.yaml make sure that you enable this:
```
rbac:
  install: true
```
Once you have updated these values, just run the previous helm upgrade command again.

Now your Jenkins system is up and running you will put it to work with a custom agent for continuous deployment of the infrastructure code we built in the first place!

## Destroy
Finally get rid of any resources you have created so you do not incur any charges. You can do this with one easy command: `terraform destroy`. Terraform will ask you to confirm before it carries out this instruction, because it cannot be undone. You should also delete the service account you created earlier unless you are going to experiment further with this project.

Hopefully this guide has given you a quick demonstration of the principles behind Terraform and how powerful it can be.

# Terraform Pipelines in Jenkins
You have now used Terraform to create a Google Kubernetes Engine cluster, and you hsve deployed Jenkins (with the Blue Ocean pipelines plugin) to your cluster with Helm. To complete our journey we will now build a pipeline in Jenkins to manage future changes to our infrastructure.

## Pipelines
What is a pipeline exactly? The traditional or literal interpretation is that it is a way to pipe something from one place to another. In computing we bend that a bit to reference a way we move something (perhaps a code change) towards something else (say, our infrastructure). In this context it almost always comprises a set of linear steps, or tasks to get from A to B.

We typically see pipelines referred to as part of Continuous Integration, which at its most basic is simply the practice of frequently merging developer changes into a code mainline. A pipeline is often triggered by a code change (like a post-commit hook in git) and can help merge that change by providing testing, approval and deployment stages.

Recall that we argued for the benefit of defining infrastructure as code. Now we are all caught up, let us set up a pipeline in Jenkins to deploy changes to that code.

## Agent Containers
The Helm chart we used has helpfully installed the Kubernetes plugin for Jenkins, which means our pipeline jobs will run in pods on our cluster, and we do not have to worry about managing standalone Jenkins agents. However the agent image will not contain the terraform binary that we need to manage our infrastructure code.

Rather than building a custom "kitchen sink" agent, we can configure additional container templates for the Jenkins Kubernetes plugin to use. This means you can run multiple lightweight containers with the tools you need to accomplish your task, all within the same pod and with access to the same Jenkins workspace.

Configure a container template for Terraform. Login to your Jenkins UI and navigate to Manage Jenkins > Configure System. Scroll down to the section for Cloud > Kubernetes, then look for Kubernetes Pod Template and Container Template. You can see the jnlp slave image configured here.

Click Add Container > Container Template

Then click Save at the bottom of this page.

Now we have configured our agents to use Terraform, there are just a couple of other bits of configuration we need to do.

## Service Account
Jenkins needs credentials that it will use in its pipeline so that Terraform is authorised to control the resources in our infrastructure. We already have a service account key in the form of a JSON file that we have used with Terraform on the command line. We can add this to Jenkins own credentials store, and reference it later in our pipeline.

Back in the Jenkins UI, navigate to Credentials > System > Global Credentials then click Add Credentials, then:

1. From the Kind drop down select Secret text.
2. Leave the Scope as Global
3. Specify the ID of terraform-auth

For the secret itself, we need to base64 encode the file. This converts the multi-line JSON file into a single large string that we can copy and paste into the secret. Hopefully your system has the base64 tool, if not please Google how to install it. Then run:
```
base64 -w0 ./creds/serviceaccount.json
```

The -w0 will remove any line breaks. Copy the entire string and paste it into the Secret box, then click OK.

## Remote State
We also need to take a quick segue back to Terraform school to learn about remote state. Previously when we have run Terraform, you will notice that some state files get written to your local directory. Terraform uses these to make its graph of changes every time it runs. So if we run Terraform in a fancy container in a pipeline, where does it write its state file?

The answer is to store the state in a bucket in the project itself. Then anyone can run Terraform in the pipeline and the remote state is centrally stored and shared. Terraform will also manage locking of the state to make sure conflicting jobs are not run at the same time.

So create a Google Cloud Storage bucket (change your-region and your-project-id accordingly):
```
gsutil mb -c regional -l <your-region> gs://<your-project-id>-tfstate
```

Run `terraform init` and Terraform will helpfully offer to copy your local state to your new remote backend. Respond with yes.

## Jenkinsfile
We made it! It is time to create a pipeline. In Jenkins, pipelines are written in groovy (a sort of scripting language spin off of Java that nobody asked for). They can be scripted, using most of the functionality of the groovy language, or declarative, which is much simpler.

At the beginning of the file we are declaring that this is a pipeline and we do not care what agent it runs on (because the Kubernetes plugin will manage that for us). We can define environment variables for our agents in the environment section, and here we call the credentials groovy function to get the value of the terraform-auth secret we set earlier.

In the "Checkout" stage the Jenkins agents checks out our git repo into its workspace. It then creates the creds directory and base64 decodes the secret that we set as an environment variable. The workspace now has a creds directory and service_account.json file just like our local directory does.

In the "Plan" stage we perform our Terraform planning, in exactly the same way we have previously in our local environment. We are specifying the terraform container template that we added earlier, so this stage will run with that image in the same pod as our Jenkins agent container, and write to the same workspace.

The "Approval" stage is optional, but it pauses the pipeline and waits for the approval of a human operator before continuing. In this example, it gives you a chance to check the output of terraform plan before applying it. Note that the script function lets us break out of the simplified declarative pipeline stuff and write some native groovy script.

Finally the "Apply" stage applies the terraform plan that was previously created, again using the terraform container template.

## Adding the Pipeline
Back in the Jenkins UI, select New Item from the homepage. Specify that this item is a Pipeline and give it a name, then click OK.

On the next page you are presented with lots of configuration options. All we need to do for now is tell Jenkins that it can find the Pipeline in a repo. Scroll down to the Pipeline section, and select Pipeline script from SCM, then choose Git and enter your repository URL. Then click Save.

Jenkins adds the Pipeline and throws you back to its homepage. Now for the fancy stuff. If you think the Jenkins UI looks a bit web 1.0, get ready to be impressed. Select Open Blue Ocean from the menu on the left.

It is like a whole new world! And it gets better. Click Run. You will be notified that a job has started, and you can click it to watch the progress. It might take a few moments the first time you do this. Jenkins is asking GKE to fire up an agent container, and it will need to grab the necessary images from Docker Hub on the first run.

You get a nice visual representation of the pipeline from this UI. When we get to the approval stage, Jenkins will wait for your input. At this point you can click back on the TF Plan stage and make sure you are happy with the plan that is going to be applied. Since we created our remote state backend, Terraform should know there are no changes to make, unless you have altered your Terraform code.

If you are happy with the plan, go ahead and give your approval. Everything should go green and give you a warm fuzzy feeling inside.

## This is So Much Work!
Well, it can be the first time. Once you get into the habit of doing things this way though, it really takes no time at all to set up these tools and processes. It is worth the effort because you gain a lot using this `DevOps` approach:

Everything is done via git, which makes team collaboration more effective
Pipelines can integrate dependencies, tests, other builds, whatever is necessary to make your deployment work the way it should
Jenkins maintains a history of changes, build stages, pipeline runs and deployments

Needless to say, you can build pipelines for anything, not just Terraform. In fact it is much more common to use them for application deployment than infrastructure life-cycle management. But anytime you have to get some code from A to B, a pipeline is probably the way to do it.

## What is Next?
In a real-world environment, you should trigger pipelines like this from a `git commit`. This can be done with a `post-commit` hook that calls the Jenkins API. You can read more about Jenkins pipelines at their website. If you need to deploy a certain kind of app, google around and the chances are someone has built a pipeline for it.

You may also want to consider `GitLab CI` as an alternative to `Jenkins`. It arguably has a much more powerful and clearer `Pipeline` syntax, and tightly integrates the pipeline process with the repo itself, by hosting both.