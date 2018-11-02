# install jenkins first (other steps depend on the jenkins user existing)
include_recipe 'java'
include_recipe 'jenkins::master'

include_recipe 'bench-demo::awscli'
include_recipe 'terraform::default'
include_recipe 'bench-demo::docker'

# to ensure idempotency, disable authentication for the remainder of the recipe
include_recipe 'bench-demo::jenkins-disable-authentication'

include_recipe 'bench-demo::jenkins-plugins'

include_recipe 'bench-demo::jenkins-add-credentials'

include_recipe 'bench-demo::github-plugin-configuration'

include_recipe 'bench-demo::jenkins-executor'

include_recipe 'bench-demo::lockable'

# security approvals must be done before the seed job runs
include_recipe 'bench-demo::jenkins-script-approvals'

include_recipe 'bench-demo::jenkins-seed-job'

# add users and enable authentication last
include_recipe 'bench-demo::jenkins-enable-authentication'

include_recipe 'postgresql'
