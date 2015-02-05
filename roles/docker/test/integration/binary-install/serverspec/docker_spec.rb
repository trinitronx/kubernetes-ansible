require 'spec_helper'
# Hack to detect OS version at test-kitchen verify time
## Note: This was in ServerSpec v1
# Specinfra::Helper::DetectOS.commands
# os = Specinfra::Helper::Properties.property[:os_by_host]['localhost']

# New way is much cleaner!! Only need 1 line in spec_helper.rb!
# References:
#  - http://chocksaway.com/blog/?p=513
#  - http://serverspec.org/changes-of-v2.html
# Debug:
# puts Specinfra::Helper::Os.os

# Check the right package name depending on OS
docker_version = '1.3.3'

case os[:family]
when 'redhat'
  docker_service_config = '/etc/sysconfig/docker'
  docker_storage_config = '/etc/sysconfig/docker-storage'
when 'ubuntu'
  docker_service_config = '/etc/default/docker'
  docker_storage_config = '/etc/default/docker-storage'
when 'debian'
  docker_service_config = '/etc/sysconfig/docker'
  docker_storage_config = '/etc/sysconfig/docker-storage'
end

describe file("/etc/init.d/docker") do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_executable 'root' }
  it { should be_mode 755 }
end

describe file("/usr/bin/docker") do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_executable 'root' }
end

describe command('sudo docker version') do
  its(:stdout) { should match Regexp.new('^Client version:\s+' + Regexp.escape(docker_version)) }
# Client API version: 1.15
# Go version (client): go1.3.3
# Git commit (client): 39fa2fa/1.3.2

# Server version: 1.3.2
# Server API version: 1.15
# Go version (server): go1.3.3
# Git commit (server): 39fa2fa/1.3.2
  its(:exit_status) { should eq 0 }
end

describe command('sudo docker ps') do
  its(:stdout) { should match /^CONTAINER ID\s+IMAGE\s+COMMAND\s+CREATED\s+STATUS\s+PORTS\s+NAMES$/ }
  its(:exit_status) { should eq 0 }
end

describe command('sudo docker pull stackbrew/busybox') do
  its(:stdout) { should match /^Pulling repository stackbrew\/busybox$/ }
  its(:exit_status) { should eq 0 }
end

describe command('sudo docker run -d stackbrew/busybox /bin/sh -c "while true; do echo Hello world; sleep 5; done"') do
  its(:stdout) { should match /[a-fA-F0-9]{64}/ }
  its(:exit_status) { should eq 0 }
end

describe command('sudo docker ps') do
  its(:stdout) { should match /[a-fA-F0-9]{12}\s+stackbrew\/busybox:.+?\s+.*\/bin\/sh -c 'while t(.*)$/ }
  its(:exit_status) { should eq 0 }
end

# describe file('/usr/local/lib/docker') do
#   it { should be_directory }
#   it { should be_executable }
#   it { should be_executable.by('others') }
#   it { should be_owned_by 'root' }
#   it { should be_grouped_into 'root' }
# end

describe file(docker_service_config) do
 it { should be_file }
 its(:content) { should match /^other_args="-g \/usr\/local\/lib\/docker"$/ }
end

describe file(docker_storage_config) do
 it { should be_file }
 its(:content) { should match /^DOCKER_STORAGE_OPTIONS=""$/ }
end