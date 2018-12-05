template '/var/lib/jenkins/scriptApproval.xml' do
  source 'scriptApproval.xml.erb'
  owner 'jenkins'
  group 'jenkins'
  action :create
  variables(
    scriptApprovals: node['jenkins']['scriptsecurityapprovals']
  )
end
