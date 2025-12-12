# -*- mode: ruby -*-
# vi: set ft=ruby :
RAM_SIZE = 8

CPU_CORES = 8

IP_NW = "192.168.56."

NUM_CONTROL_NODES = 2
NUM_WORKER_NODES = 2


MASTER_IP_START = 10
NODE_IP_START = 20
LB_IP_START = 30

ram_selector = (RAM_SIZE / 4) * 4
if ram_selector < 8
  raise "Unsufficient memory #{RAM_SIZE}GB. min 8GB"
end

def setup_dns(node)
  # Set up /etc/hosts
  node.vm.provision "setup-hosts", :type => "shell", :path => "setup-hosts.sh" do |s|
    s.args = ["enp0s8", node.vm.hostname]
  end
  node.vm.provision "setup-dns", type: "shell", :path => "update-dns.sh"
end

def provision_kubernetes_node(node)
  node.vm.provision "setup-kernel", :type => "shell", :path => "setup-kernel.sh"
  node.vm.provision "setup-ssh", :type => "shell", :path => "ssh.sh"

  setup_dns node
end

RESOURCES = {
  "control" => {
    1 => {
      "ram" => [ram_selector * 128, 2048].max(),
      "cpu" => CPU_CORES >= 12 ? 4 : 2,
    },
    2 => {
      "ram" => [ram_selector * 128, 2048].min(),
      "cpu" => CPU_CORES > 8 ? 2 : 1,
    },
  },  
  "worker" => {
    "ram" => [ram_selector * 128, 4096].min(),
    "cpu" => (((CPU_CORES / 4) * 4) - 4) / 4,
  }
}

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "ubuntu/jammy64"
  config.vm.boot_timeout = 900

  config.vm.box_check_update = false

  # Provision Control Nodes
  (1..NUM_CONTROL_NODES).each do |i|
    config.vm.define "controlplane0#{i}" do |node|
      # Name shown in the GUI
      node.vm.provider "virtualbox" do |vb|
        vb.name = "kubernetes-ha-controlplane-#{i}"
        vb.memory = RESOURCES["control"][i > 2 ? 2 : i]["ram"]
        vb.cpus = RESOURCES["control"][i > 2 ? 2 : i]["cpu"]
      end
      node.vm.hostname = "controlplane0#{i}"
      node.vm.network :private_network, ip: IP_NW + "#{MASTER_IP_START + i}"
      node.vm.network "forwarded_port", guest: 22, host: "#{2710 + i}"
      provision_kubernetes_node node
     end
  end  

  # Provision Load Balancer Node
  config.vm.define "loadbalancer" do |node|
    node.vm.provider "virtualbox" do |vb|
      vb.name = "kubernetes-ha-lb"
      vb.memory = 512
      vb.cpus = 1
    end
    node.vm.hostname = "loadbalancer"
    node.vm.network :private_network, ip: IP_NW + "#{LB_IP_START}"
    node.vm.network "forwarded_port", guest: 22, host: 2730
    # Set up ssh
    node.vm.provision "setup-ssh", :type => "shell", :path => "ubuntu/ssh.sh"
    setup_dns node
  end

  # Provision Worker Nodes
  (1..NUM_WORKER_NODES).each do |i|
    config.vm.define "node0#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "kubernetes-ha-node-#{i}"
        vb.memory = RESOURCES["worker"]["ram"]
        vb.cpus = RESOURCES["worker"]["cpu"]
      end
      node.vm.hostname = "node0#{i}"
      node.vm.network :private_network, ip: IP_NW + "#{NODE_IP_START + i}"
      node.vm.network "forwarded_port", guest: 22, host: "#{2720 + i}"
      provision_kubernetes_node node
    end
  end
  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Disable the default share of the current code directory. Doing this
  # provides improved isolation between the vagrant box and your host
  # by making sure your Vagrantfile isn't accessible to the vagrant box.
  # If you use this you may want to enable additional shared subfolders as
  # shown above.
  # config.vm.synced_folder ".", "/vagrant", disabled: true

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
