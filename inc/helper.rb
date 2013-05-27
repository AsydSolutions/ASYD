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

def exec_cmd(host,cmd)
  Net::SSH.start(host.strip, "root", :keys => "data/ssh_key") do |ssh|
    result = ssh.exec!(cmd)
    return result
  end
end
