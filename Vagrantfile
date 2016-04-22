# -*- mode: ruby -*-
# vi: set ft=ruby :
# vi: set sts=2 ts=2 sw=2 :

VAGRANTFILE_API_VERSION = '2'.freeze

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'ubuntu/trusty64'
  config.vm.provision :shell, path: 'provision/vagrant.sh'
  config.vm.provision :shell, path: 'provision/docker.sh', args: '/vagrant'
  config.vm.provision :shell, path: 'provision/pam_docker.sh'
  config.vm.provision :shell, path: 'provision/bootstrap.sh', args: '/vagrant'
end
