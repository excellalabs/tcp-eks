template '/var/lib/jenkins/org.jenkins.plugins.lockableresources.LockableResourcesManager.xml' do
  source 'lockable.xml.erb'
  owner 'jenkins'
  group 'jenkins'
  action :create
  variables(
    lockable: node['jenkins']['lockable']
  )
end