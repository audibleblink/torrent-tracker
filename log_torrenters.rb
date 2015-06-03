#!/usr/bin/env ruby

 EXCLUDED_PORTS     = %w(5060 5190  5353 5678 53 80 123 443 993 5000).map(&:to_i)
 EXCLUDED_RANGES    = [*16384..16403, *5297..5298, *5222..5228]
 CONNECTION_PATTERN = /src=([\d\.]+) dst=([\d\.]+) sport=(\d+) dport=(\d+)/
 ROUTER_IP = "10.0.0.1"


def ssh command
  `/usr/bin/ssh -i /Users/alex/.ssh/id_rsa #{ROUTER_IP} '#{command}' 2>/dev/null`
end

def filtered_live_connections
  live_connections.each_with_object({}) do |connection, memo|
    matches = CONNECTION_PATTERN.match(connection)
    source_ip, dest_ip, source_port, dest_port = matches[1..4] if matches
    unless contains_unwanted_ports? dest_port
      memo[source_ip] ||= []
      memo[source_ip] << [dest_ip, dest_port]
    end
  end
end

def live_connections
  ssh('sudo conntrack -L | grep udp').split("\n")  
end

def contains_unwanted_ports? dest_port
  (EXCLUDED_PORTS + EXCLUDED_RANGES).include?(dest_port.to_i)
end

def log clients
  clients.each_pair do |ip, connections|
    arp = begin; ssh("sudo arp #{ip} | tail -1").split(/\s+/)[2]; rescue; end
    puts "#{ip} -> #{connections.map(&:last).join(",")} ->  #{arp} -> #{connections.length}"
  end
end

def clients_with_connections_over threshold
  filtered_live_connections.reject { |c, v| v.length < threshold }
end

log clients_with_connections_over 10


