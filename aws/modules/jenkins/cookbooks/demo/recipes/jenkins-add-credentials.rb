jenkins_password_credentials node['jenkins']['github']['user'] do
  id          "#{node['jenkins']['github']['credentials-id']}"
  description 'GitHub API user + token'
  password    "#{node['jenkins']['github']['token']}"
end

jenkins_secret_text_credentials node['jenkins']['github']['user'] do
  id          "#{node['jenkins']['github']['token-id']}"
  description 'GitHub API token'
  secret      "#{node['jenkins']['github']['token']}"
end