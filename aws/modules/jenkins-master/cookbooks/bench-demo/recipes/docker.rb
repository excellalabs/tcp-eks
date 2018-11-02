docker_service 'default' do
  action :create
end

group 'docker' do
  append true
  members 'jenkins'
  action :modify
end

docker_service 'default' do
  action :start
end