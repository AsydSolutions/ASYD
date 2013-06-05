require 'fileutils'
require 'net/ssh'
require 'net/scp'
require 'pathname'
require 'find'

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
