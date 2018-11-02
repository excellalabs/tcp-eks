seed_xml = File.join(Chef::Config[:file_cache_path], 'seed-config.xml')

template seed_xml do
  source 'jenkins-seedjob-config.xml.erb'
  mode '0644'
  owner 'jenkins'
  group 'jenkins'
  variables(
    git_repo_owner:     node['jenkins']['seedjob']['repo']['owner'],
    git_credentials_id: node['jenkins']['github']['credentials-id'],
    repo_include:       node['jenkins']['seedjob']['repo']['include'],
    repo_exclude:       node['jenkins']['seedjob']['repo']['exclude'],
    branch_include:     node['jenkins']['seedjob']['branch']['include'],
    branch_exclude:     node['jenkins']['seedjob']['branch']['exclude'],
    branch_trigger:     node['jenkins']['seedjob']['branch']['trigger']
    )
end

jenkins_job 'Excella' do
  config seed_xml
  action :create
end