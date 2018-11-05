# install jenkins first (other steps depend on the jenkins user existing)
include_recipe 'java'
include_recipe 'jenkins::master'

include_recipe 'demo::awscli'
include_recipe 'terraform::default'
include_recipe 'demo::docker'

# to ensure idempotency, disable authentication for the remainder of the recipe
include_recipe 'demo::jenkins-disable-authentication'

include_recipe 'demo::jenkins-plugins'

include_recipe 'demo::jenkins-add-credentials'

include_recipe 'demo::github-plugin-configuration'

include_recipe 'demo::jenkins-executor'

include_recipe 'demo::lockable'

# security approvals must be done before the seed job runs
include_recipe 'demo::jenkins-script-approvals'

include_recipe 'demo::jenkins-seed-job'

# add users and enable authentication last
include_recipe 'demo::jenkins-enable-authentication'

include_recipe 'postgresql'
