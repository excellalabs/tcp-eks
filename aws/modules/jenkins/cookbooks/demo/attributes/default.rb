default['java']['jdk_version'] = '8'
default['java']['install_flavor'] = 'openjdk'

# Note: to get the short name of a plugin, install it on jenkins via the UI and run the following script 
# in the Jenkins Script Console (Manage Jenkins > Script Console)
#
# Jenkins.instance.pluginManager.plugins.each{
#   plugin -> 
#     println ("${plugin.getDisplayName()} (${plugin.getShortName()}): ${plugin.getVersion()}")
# }

default['jenkins']['plugins'] = [
  'github-branch-source', 
  'github-organization-folder',
  'matrix-auth',
  'greenballs',
  'blueocean',
  'ansicolor',
  'pipeline-stage-view',
  'lockable-resources',
  'slack',
  'aws-credentials',
  'aws-codebuild',
  'aws-codecommit-jobs',
  'aws-codepipeline',
  'aws-java-sdk',
  'ec2',
  'scalable-amazon-ecs',
  'kubernetes',
  'kubernetes-cd',
  'kubernetes-cli',
  'node-iterator-api'
]

# aws config values
default['aws']['access_key_id'] = ''
default['aws']['secret_access_key'] = ''
default['aws']['region'] = ''

# script security exceptions (needed for dynamically canceling builds to prevent PR builder queueing)
default['jenkins']['scriptsecurityapprovals'] = [
  'method hudson.model.Run _this',
  'method org.jenkinsci.plugins.workflow.job.WorkflowRun doTerm',
  'method org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper getRawBuild'
]

# Credentials and contact info for the default 'developer' and 'admin' users
default['jenkins']['users']['email'] = ''
default['jenkins']['users']['developerPassword'] = ''
default['jenkins']['users']['adminPassword'] = ''

# Provide jenkins with the github user and token for cloning git repos:
# - the token requires repo read/write access
# - the token requires webhook admin access
default['jenkins']['github']['user'] = ''
default['jenkins']['github']['token'] = ''
default['jenkins']['github']['credentials-id'] = 'github-ci-credentials'
default['jenkins']['github']['token-id'] = 'github-ci-token'

# The github organization job considers all of the repos that this configured
# user *owns*
default['jenkins']['seedjob']['repo']['owner'] = ''

# This is the set of repos from the github organization to consider as pipeline candidates.
# Note these are space delimited lists taking wildcard patterns (not full regexs).
# You might include "md-*-base md-infrastructure" and exclude "md-defunct-base"
default['jenkins']['seedjob']['repo']['include'] = ''
default['jenkins']['seedjob']['repo']['exclude'] = ''

# Of the repo pipeline candidates, only create pipelines for the following branchs in each repo. 
# Note these are space delimited lists taking wildcard patterns (not full regexs).
# In this case:
# - always create pipelines for "master"
# - "PR-\d+" is a "branch like object" to jenkins to describe PRs, keep this if you want a PR builder
# - devs may create ad-hoc branches starting with "build-*" that they want to test pipeline builds without needing to create a PR
default['jenkins']['seedjob']['branch']['include'] = ''
default['jenkins']['seedjob']['branch']['exclude'] = ''

# Of the brances discovered, trigger builds automatically for the branches matching this pattern (regex)
default['jenkins']['seedjob']['branch']['trigger'] = ''

#default['terraform']['version'] = '0.11.10'