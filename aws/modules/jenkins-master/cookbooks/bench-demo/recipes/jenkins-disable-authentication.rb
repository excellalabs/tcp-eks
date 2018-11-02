execute "Disable Jenkins Authentication" do
  command "sed -i 's@<useSecurity>true</useSecurity>@<useSecurity>false</useSecurity>@g' /var/lib/jenkins/config.xml"
end

# authentication is only disabled upon restart
service 'jenkins' do
  action :restart
end