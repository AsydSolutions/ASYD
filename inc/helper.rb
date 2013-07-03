require 'fileutils'
require 'net/ssh'
require 'net/scp'
require 'pathname'
require 'find'
require 'tempfile'
require 'socket'

def get_dirs path
  dir_array = Array.new
  Pathname.new(path).children.select do |dir|
    dir_array << dir.basename
  end
  return dir_array
end

def get_files path
  files_array = Array.new
  Find.find(path) do |f|
    files_array << File.basename(f, "*")
  end
  return files_array
end

def get_host_data(host)
  path = "data/servers/"+host+"/srv.info"
  f = File.open(path, "r")
  hostdata = {}
  hostdata[:hostname] = host
  hostdata[:ip] = f.gets.strip
  hostdata[:dist_name] = f.gets.strip
  hostdata[:dist_ver]  = f.gets.strip
  hostdata[:pkg_mgr] = f.gets.strip
  f.close
  return hostdata
end

def get_asyd_ip
  ip = UDPSocket.open {|s| s.connect("8.8.8.8", 1); s.addr.last}
  return ip
end

def exec_cmd(ip, cmd)
  Net::SSH.start(ip.strip, "root", :keys => "data/ssh_key") do |ssh|
    result = ssh.exec!(cmd)
    return result
  end
end

def upload_file(ip, local, remote)
  Net::SSH.start(ip.strip, "root", :keys => "data/ssh_key") do |ssh|
    ssh.scp.upload!(local, remote)
  end
end

def download_file(ip, remote, local)
  Net::SSH.start(ip.strip, "root", :keys => "data/ssh_key") do |ssh|
    ssh.scp.download!(remote, local)
  end
end

def upload_dir(ip, local, remote)
  Net::SSH.start(ip.strip, "root", :keys => "data/ssh_key") do |ssh|
    ssh.scp.upload!(local, remote, :recursive => true)
  end
end

def download_dir(ip, remote, local)
  Net::SSH.start(ip.strip, "root", :keys => "data/ssh_key") do |ssh|
    ssh.scp.download!(remote, local, :recursive => true)
  end
end

def parse_config(host, cfg)
  hostdata = get_host_data(host)
  hostname = hostdata[:hostname]
  ip = hostdata[:ip]
  asyd = get_asyd_ip

  newconf = Tempfile.new('conf')
  File.open(cfg, "r").each do |line|
    line = line.split('#')
    line = line[0]
    if !line.include?('<%MONITOR:')
      line.gsub!('<%ASYD%>', asyd)
      line.gsub!('<%IP%>', ip)
      line.gsub!('<%HOSTNAME%>', hostname)
      newconf << line
    else
      monitor = line.gsub!(/([<%>])/, '')
      monitor = monitor.split(':')
      monitor = monitor[1].strip
      p monitor
    end
  end
  newconf.flush
  return newconf
end
