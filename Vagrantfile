# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "ca" do |ca|
    ca.vm.box = "terrywang/archlinux"
    ca.vm.hostname = "#{ENV['USER']}-ca.dev"
    ca.vm.provision :shell, path: "ca-bootstrap.sh"
    ca.vm.network :private_network, ip:"192.168.33.10"
    ca.vm.synced_folder "./shared", "/vagrant"
    ca.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
    end
  end

  config.vm.define "zk" do |zk|
    zk.vm.box = "terrywang/archlinux"
    zk.vm.hostname = "#{ENV['USER']}-zk.dev"
    zk.vm.provision :shell, path: "zk-bootstrap.sh"
    zk.vm.network :private_network, ip:"192.168.33.11"
    zk.vm.network :forwarded_port, host: 2181, guest: 2181
    zk.vm.synced_folder "./shared", "/vagrant"
    zk.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
    end
  end

  config.vm.define "kafka" do |kafka|
    kafka.vm.box = "terrywang/archlinux"
    kafka.vm.hostname = "#{ENV['USER']}-kafka.dev"
    kafka.vm.provision :shell, path: "kafka-bootstrap.sh"
    kafka.vm.network :private_network, ip:"192.168.33.12"
    kafka.vm.network :forwarded_port, host: 9092, guest: 9092
    kafka.vm.network :forwarded_port, host: 9093, guest: 9093
    kafka.vm.synced_folder "./shared", "/vagrant"
    kafka.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--memory", "2048"]
    end
  end

end
