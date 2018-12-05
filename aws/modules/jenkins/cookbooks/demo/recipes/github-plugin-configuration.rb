
template "/var/lib/jenkins/github-plugin-configuration.xml" do
  source 'github-plugin-configuration.xml.erb'
  mode '0644'
  owner 'jenkins'
  group 'jenkins'
  variables(
    github_token_id: node['jenkins']['github']['token-id']
  )
end
