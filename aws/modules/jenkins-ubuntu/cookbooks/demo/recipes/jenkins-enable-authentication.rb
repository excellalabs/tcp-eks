# only enable JNLP4 for agent server connections (addresses banner warning)
jenkins_script 'restrict jnlp protocols' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*

    Jenkins.instance.agentProtocols = ['JNLP4-connect', 'Ping']
    Jenkins.instance.save()
  EOH
end

# enable agent-to-master security (addresses banner warning)
jenkins_script 'enable master security' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.model.*
    import jenkins.security.s2m.AdminWhitelistRule

    Jenkins.instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)
  EOH
end

# add users
jenkins_user 'admin' do
  full_name 'admin'
  email "#{node['jenkins']['users']['email']}"
  password "#{node['jenkins']['users']['adminPassword']}"
end

jenkins_user 'developer' do
  full_name 'developer'
  email "#{node['jenkins']['users']['email']}"
  password "#{node['jenkins']['users']['developerPassword']}"
end

# enable authentication and resource roles
jenkins_script 'add_authentication' do
  command <<-EOH.gsub(/^ {4}/, '')
    import hudson.model.Hudson;
    import hudson.model.Job;
    import hudson.model.View;
    import hudson.security.GlobalMatrixAuthorizationStrategy;
    import hudson.security.HudsonPrivateSecurityRealm;
    import com.cloudbees.plugins.credentials.CredentialsProvider;

    // turn off signups
    doNotAllowSignup = false;
    privateSecurityRealm = new HudsonPrivateSecurityRealm(doNotAllowSignup);
    Hudson.instance.setSecurityRealm(privateSecurityRealm);

    // turn on global matrix auth
    authzStrategy = new GlobalMatrixAuthorizationStrategy();

    // add admin user
    authzStrategy.add(Hudson.ADMINISTER, "admin");

    // add jobrunner user
    authzStrategy.add(Hudson.READ, "developer");
    authzStrategy.add(Job.WORKSPACE, "developer");
    authzStrategy.add(Job.DISCOVER, "developer");
    authzStrategy.add(Job.READ, "developer");
    authzStrategy.add(Job.BUILD, "developer");
    authzStrategy.add(View.READ, "developer");
    authzStrategy.add(CredentialsProvider.VIEW, "developer");

    // save
    Hudson.instance.setAuthorizationStrategy(authzStrategy);
    Hudson.instance.save();
  EOH
end

# authentication is only enabled upon restart
service 'jenkins' do
  action :restart
end