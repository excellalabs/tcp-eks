remote_file '/tmp/jenkins-cli.jar' do
  source 'http://127.0.0.1:8080/jnlpJars/jenkins-cli.jar'
  mode '0755'
  retries 6
  retry_delay 10
end

node['jenkins']['plugins'].each do |plugin|
  execute "Install #{plugin}" do
    live_stream true
    command "java -jar /tmp/jenkins-cli.jar -http -auth 'admin:#{node['jenkins']['users']['adminPassword']}' -s http://127.0.0.1:8080 install-plugin #{plugin}"
    not_if "java -jar /tmp/jenkins-cli.jar -http -auth 'admin:#{node['jenkins']['users']['adminPassword']}' -s http://127.0.0.1:8080 list-plugins | grep '^#{plugin}\\s'"
  end
end

# we need to restart in case any of theses plugins need to be active for the following configuration
service 'jenkins' do
  action :restart
end