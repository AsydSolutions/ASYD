# @author choms <choms@botmania.net>
# @!group Helpers
require 'fileutils'
require 'net/ssh'
require 'net/scp'
require 'pathname'
require 'find'
require 'tempfile'
require 'socket'

# Gets the directories inside a path.
#
# @param path [String] Route to the directory where you want to list the subdirectories.
# @return dir_array [Array] The subdirectories in the given directory.
def get_dirs path
  dir_array = Array.new
  Pathname.new(path).children.select do |dir|
    dir_array << dir.basename
  end
  return dir_array
end

# Gets the files inside a path.
#
# @param path [String] Route to the directory where you want to list the file.
# @return files_array [Array] The files in the given directory.
def get_files path
  files_array = Array.new
  Find.find(path) do |f|
    if !FileTest.directory?(f)
      files_array << File.basename(f, "*")
    end
  end
  return files_array
end

# Gets the server list
#
# @return serverlist [Array] Array with the added servers
def get_server_list
  servers = SQLite3::Database.new "data/db/servers.db"
  serverlist = []
  servers.execute("select hostname from servers") do |row|
    serverlist << row[0]
  end
  servers.close
  return serverlist
end

# Gets the hostgroups list
#
# @return grouplist [Array] Array with the added host groups
def get_hostgroup_list
  groups = SQLite3::Database.new "data/db/hostgroups.db"
  grouplist = []
  groups.execute("select name from hostgroups") do |row|
    grouplist << row[0]
  end
  groups.close
  return grouplist
end

# Gets all the host data stored for a host
#
# @param host [String] The name of the host you want to retreive the data from
# @return hostdata [Array] The data stored on ASYD about the host,
#   in the following format:
#     hostdata[:hostname]  <- the name of the host
#     hostdata[:ip]	 <- the ip of the host
#     hostdata[:dist_name] <- the name of the distribution
#     hostdata[:dist_ver]  <- the version of the distributions
#     hostdata[:pkg_mgr]   <- the package manager used, can be "apt" or "yum" atm
def get_host_data(host)
  host = host.to_s
  servers = SQLite3::Database.new "data/db/servers.db"
  ret = servers.get_first_row("select * from servers where hostname=?", host)
  hostdata = {}
  hostdata[:hostname] = host
  hostdata[:ip] = ret[1]
  hostdata[:dist_name] = ret[2]
  hostdata[:dist_ver] = ret[3].to_s
  hostdata[:arch] = ret[4]
  hostdata[:pkg_mgr] = ret[5]
  servers.close
  return hostdata
end

# Gets ASYD server IP address
def get_asyd_ip
  ip = UDPSocket.open {|s| s.connect("8.8.8.8", 1); s.addr.last}
  return ip
end

# Executes a command on a remote host
#
# @param ip [String] target ip address
# @param cmd [String] command to be executed
# @return result [String] the result of executing the command
def exec_cmd(ip, cmd)
  Net::SSH.start(ip.strip, "root", :keys => "data/ssh_key") do |ssh|
    result = ssh.exec!(cmd)
    return result
  end
end

# Upload a file
#
# @param ip [String] target ip address
# @param local [String] path to the local file
# @param remote [String] remote path for uploading the file
def upload_file(ip, local, remote)
  Net::SSH.start(ip.strip, "root", :keys => "data/ssh_key") do |ssh|
    ssh.scp.upload!(local, remote)
  end
end

# Download a file
#
# @param ip [String] target ip address
# @param remote [String] remote path of the file
# @param local [String] local path to store the file
def download_file(ip, remote, local)
  Net::SSH.start(ip.strip, "root", :keys => "data/ssh_key") do |ssh|
    ssh.scp.download!(remote, local)
  end
end

# Upload a directory
#
# @param ip [String] target ip address
# @param local [String] path to the local dir
# @param remote [String] remote path for uploading the directory
def upload_dir(ip, local, remote)
  Net::SSH.start(ip.strip, "root", :keys => "data/ssh_key") do |ssh|
    ssh.scp.upload!(local, remote, :recursive => true)
  end
end

# Download a directory
#
# @param ip [String] target ip address
# @param remote [String] remote path of the directory
# @param local [String] local path to store the directory
def download_dir(ip, remote, local)
  Net::SSH.start(ip.strip, "root", :keys => "data/ssh_key") do |ssh|
    ssh.scp.download!(remote, local, :recursive => true)
  end
end

# Parse a config file (read the documentation for syntax reference)
#
# @param host [String] host to take the data from
# @see #get_host_data
# @param cfg [String] config to be parsed
# @return newconf [Object] temporal file with the parameters substituted by the values
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
      service = monitor[1].strip
      monitor_service(service, host)
    end
  end
  newconf.flush
  return newconf
end

def round
    return (self+0.5).floor if self > 0.0
    return (self-0.5).ceil  if self < 0.0
    return 0
end

# @!endgroup
