# creates the directory to aws creds

directory '/var/lib/jenkins/.aws' do
    owner 'jenkins'
    group 'jenkins'
    mode '0755'
    action :create
end

template '/var/lib/jenkins/.aws/config' do
    source 'aws_config.erb'
    variables({
        aws_region: node['aws']['region']
    })
    owner 'jenkins'
    group 'jenkins'
    mode '0600'
end

# though the credentials can be placed in ~/.aws/config, terraform backed config requires this location
template '/var/lib/jenkins/.aws/credentials' do
    source 'aws_credentials.erb'
    variables({
        aws_access_key_id: node['aws']['access_key_id'],
        aws_secret_access_key: node['aws']['secret_access_key']
    })
    owner 'jenkins'
    group 'jenkins'
    mode '0600'
end

package 'python-minimal'
package 'python-pip'
execute 'install awscli' do
    command 'pip install awscli --upgrade'
end

# to parse output from aws-cli commands
package 'jq'