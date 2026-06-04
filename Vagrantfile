# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"

  config.vm.synced_folder ".", "/vagrant",
    type: "nfs",
    nfs_version: 4,
    nfs_udp: false,
    mount_options: ["actimeo=1", "tcp"]

  config.vm.define "control-plane" do |node|
    node.vm.hostname = "control-plane"
    
    node.vm.network "private_network", ip: "192.168.56.10", libvirt__dhcp_enabled: false

    node.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
      libvirt.title = "k8s-control-plane"
    end

    node.vm.provision "shell", path: "scripts/common.sh"
    node.vm.provision "shell", path: "scripts/control-plane.sh"
  end

  (1..2).each do |i|
    config.vm.define "worker-#{i}" do |node|
      node.vm.hostname = "worker-#{i}"
      
      node.vm.network "private_network", ip: "192.168.56.1#{i}", libvirt__dhcp_enabled: false

      node.vm.provider :libvirt do |libvirt|
        libvirt.memory = 1024
        libvirt.cpus = 1
        libvirt.title = "k8s-worker-#{i}"
      end

      node.vm.provision "shell", path: "scripts/common.sh"
      node.vm.provision "shell", path: "scripts/worker.sh"
    end
  end
end
