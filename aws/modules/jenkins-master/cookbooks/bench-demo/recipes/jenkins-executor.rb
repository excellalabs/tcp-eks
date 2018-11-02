jenkins_script 'update_executors' do
  command <<-EOH.gsub(/^ {4}/, '')
    import hudson.model.*

    Hudson hudson = Hudson.getInstance()
    hudson.setNumExecutors(50)
    hudson.setNodes(hudson.getNodes())
    hudson.save()
  EOH

end