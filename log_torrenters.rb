#!/usr/bin/env ruby     

# This file lives on an admin controlled machine on the same network as your router

HOME_DIR =  "/Users/alex"
ROUTER_IP = "10.0.0.1"
REMOTE_SCRIPT = "sh /home/dbcnyadmin/torrscan"

def ssh command
  `/usr/bin/ssh -i #{HOME_DIR}/.ssh/id_rsa #{ROUTER_IP} 'sudo -u root #{command}' 2>/dev/null`
end

def live_connections  # -> {ip: connection_count, ip: connection_count}
  all = ssh(REMOTE_SCRIPT)
  Hash[all.split("\n").map{|line| line.split(" ").reverse }]
end

def clients_with_connections_over threshold
  live_connections.select {|ip, connections| connections.to_i > threshold.to_i}
end

def log_offenders baddies
  baddies.each do |ip, conns|
    arp = begin; ssh("sudo arp #{ip} | tail -1").split(/\s+/)[2]; rescue; end
    puts "#{ip} -> #{arp} -> #{conns}"
  end
end

log_offenders clients_with_connections_over 10
