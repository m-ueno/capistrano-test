# -*- coding:utf-8 -*-

# goal: create vsys using chef-solo
# goal: manage 2VMs in parallel
# ================================
# <= openstack floatingip
#   <= routing
# <= chef-install
#   <= proxy

set :application, "trigger-chef-solo"
set :topdir, File.dirname(__FILE__)
set :chef_dir, "#{topdir}/chef-repo"

# ================================
# Functions
# ================================
def get_floating_ip(name)
  # ...
end

def get_fixed_ip(name)
  ip = `nova list| grep [[:space:]]#{node}[[:space:]]`.scan(/[\d\.]+/).flatten!
  raise "error: #{name} -- get_fixed_ip" if ip == []
  ip
end

def is_active?(name)
  "judge the node is active or not"
  `nova list`.each_line do |l|
    return true if l =~ /\s#{name}\s/ and l =~ /ACTIVE/
  end
  false
end

def init_role
  "initialize role, if node is active"
  @system_config[:nodes].each do |node|
    if is_active?(n)
      role :n, get_fixed_ip(n)
    end
  end
end

# ================================
# Define Role
# ================================
role :openstack_compute, "localhost"
role :openstack_network, "localhost"

# prototype: must be initialized before run task (with `nova list` commands)
role :web, "xxx.xxx.xxx.xxx" # floatingip
role :app, "xxx.xxx.xxx.xxx"
role :db,  "xxx.xxx.xxx.xxx" #, :primary => true
role :db,  "xxx.xxx.xxx.xxx"

# ================================
# Define system (as systemconfig.sh)
# ================================
@subnet_private = "192.168.60.0/24"
@subnet_public = "172.16.10.0/24"
nodes = [
  node_web = {
    type: "node",
    subnet: @subnet_public,
    ipv4: nil,
    role: :web
  },
  node_app = {
    type: "node",
    subnet: @subnet_private,
    ipv4: nil,
    role: :app
  },
  node_db = {
    type: "node",
    subnet: @subnet_private,
    ipv4: nil,
    role: :db
  }
]

@small_system = {
  type: "system",
  nodes: nodes
}

set :system_config, @small_system

# ================================
# Define tasks
# ================================

namespace :mytest do
  task :hello do
    puts "hey"
  end

  task :os, :role => :openstack_compute do
    puts "os_compute"
    run "uptime"
  end
end


namespace :chef do

  task :default do
    init_config
    sync
  end

  desc "prototype: configure firewall rules on vpn-gw"
  task :conf_vpn_gw, :roles => :vpn_gw do
    run "chef-solo solo.rb -j #{chef_repo}/cookbooks/recipe/"
  end

  desc "install chef-solo"
  task :prepare do
    run "knife-solo prepare #{node}"
  end


  desc "trigger for `web'"
  task :conf_web, :roles => :web do
    run "chef-solo #{config_dir}/solo.rb -j #{chef_repo}/cookbooks/recipe"
    # and more...
  end

  # ----------------

  desc "install mysql (without chef?)"
  task :mysql, :roles => :db do
    run "yum install -y mysql-server"
  end

  desc "install nginx"
  task :nginx, :roles => :web do
    run "yum install -y nginx"
  end
end
