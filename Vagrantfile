# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile para provisionamento de laboratório Kubernetes local (1 control plane e 2 workers)
# Utilizando provider KVM (libvirt) e Box Ubuntu 22.04 LTS (Jammy)

Vagrant.configure("2") do |config|
  # Configuração padrão da Box
  config.vm.box = "generic/ubuntu2204"

  # =============================================================
  # CORREÇÃO PARA LIBVIRT (9p): Força sincronização bidirecional
  # =============================================================
  config.vm.synced_folder ".", "/vagrant",
    type: "nfs",
    nfs_version: 4,
    nfs_udp: false,
    mount_options: ["actimeo=1", "tcp"]
  # =============================================================
  
  # -------------------------------------------------------------
  # 1. Nó Control Plane (Master)
  # -------------------------------------------------------------
  config.vm.define "control-plane" do |node|
    node.vm.hostname = "control-plane"
    
    # IP Estático para comunicação e acesso via kubectl
    node.vm.network "private_network", ip: "192.168.56.10", libvirt__dhcp_enabled: false

    node.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
      libvirt.title = "k8s-control-plane"
    end

    # Provisionamento sequencial
    node.vm.provision "shell", path: "scripts/common.sh"
    node.vm.provision "shell", path: "scripts/control-plane.sh"
  end

  # -------------------------------------------------------------
  # 2. Nós Workers (Agentes)
  # -------------------------------------------------------------
  (1..2).each do |i|
    config.vm.define "worker-#{i}" do |node|
      node.vm.hostname = "worker-#{i}"
      
      # IPs: worker-1 (192.168.56.11), worker-2 (192.168.56.12)
      node.vm.network "private_network", ip: "192.168.56.1#{i}", libvirt__dhcp_enabled: false

      node.vm.provider :libvirt do |libvirt|
        libvirt.memory = 1024
        libvirt.cpus = 1
        libvirt.title = "k8s-worker-#{i}"
      end

      # Provisionamento sequencial
      node.vm.provision "shell", path: "scripts/common.sh"
      node.vm.provision "shell", path: "scripts/worker.sh"
    end
  end
end
