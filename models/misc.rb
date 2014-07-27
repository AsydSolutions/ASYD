#Miscellaneous utils
module Misc
  # Gets the directories inside a path.
  #
  # @param path [String] Route to the directory where you want to list the subdirectories.
  # @return dir_array [Array] The subdirectories in the given directory.
  def self.get_dirs path
    files_array = Array.new
    entries = Dir.entries(path)
    entries.each do |d|
      d = path+"/"+d
      if FileTest.directory?(d)
        unless File.basename(d, "*").match(/^\./)
          files_array << File.basename(d, "*")
        end
      end
    end
    return files_array
  end

  # Gets the files inside a path.
  #
  # @param path [String] Route to the directory where you want to list the file.
  # @return files_array [Array] The files in the given directory.
  def self.get_files path
    files_array = Array.new
    entries = Dir.entries(path)
    entries.each do |f|
      f = path+"/"+f
      if FileTest.file?(f)
        files_array << File.basename(f, "*")
      end
    end
    return files_array
  end

  # Gets ASYD server IP address
  def get_asyd_ip
    ip = UDPSocket.open {|s| s.connect(self.ip, 1); s.addr.last}
    return ip
  end

  # Get max allocable forks
  def self.get_max_forks
    free_mem = %x(free -m |grep cache: |awk '{print $4}')
    max_forks = free_mem.to_i / 30
    return max_forks
  end

  # Round number
  def round
      return (self+0.5).floor if self > 0.0
      return (self-0.5).ceil  if self < 0.0
      return 0
  end

  # Executes a command on a remote host
  #
  # @param ip [String] target ip address
  # @param cmd [String] command to be executed
  # @return result [String] the result of executing the command
  def exec_cmd(cmd)
    Net::SSH.start(self.ip, self.user, :port => self.ssh_port, :keys => "data/ssh_key") do |ssh|
      result = ssh.exec!(cmd)
      return result
    end
  end

  # Upload a file
  #
  # @param ip [String] target ip address
  # @param local [String] path to the local file
  # @param remote [String] remote path for uploading the file
  def upload_file(local, remote)
    Net::SSH.start(self.ip, self.user, :port => self.ssh_port, :keys => "data/ssh_key") do |ssh|
      ssh.scp.upload!(local, remote)
    end
  end

  # Download a file
  #
  # @param ip [String] target ip address
  # @param remote [String] remote path of the file
  # @param local [String] local path to store the file
  def download_file(remote, local)
    Net::SSH.start(self.ip, self.user, :port => self.ssh_port, :keys => "data/ssh_key") do |ssh|
      ssh.scp.download!(remote, local)
    end
  end

  # Upload a directory
  #
  # @param ip [String] target ip address
  # @param local [String] path to the local dir
  # @param remote [String] remote path for uploading the directory
  def upload_dir(local, remote)
    Net::SSH.start(self.ip, self.user, :port => self.ssh_port, :keys => "data/ssh_key") do |ssh|
      match = ssh.exec!("ls "+remote)
      if !match.nil? && match.start_with?("ls:")
        ssh.scp.upload!(local, remote, options={:recursive => true})
      else
        files = Misc.get_files(local)
        files.each do |file|
          newfile = local+"/"+file
          newremote = remote+"/"+file
          self.upload_file(newfile, newremote)
        end
        dirs = Misc.get_dirs(local)
        dirs.each do |dir|
          newdir = local+"/"+dir+"/"
          newremote = remote+"/"+dir
          self.upload_dir(newdir, newremote)
        end
      end
    end
  end

  # Download a directory
  #
  # @param ip [String] target ip address
  # @param remote [String] remote path of the directory
  # @param local [String] local path to store the directory
  def download_dir(remote, local)
    Net::SSH.start(self.ip, self.user, :port => self.ssh_port, :keys => "data/ssh_key") do |ssh|
      ssh.scp.download!(remote, local, :recursive => true)
    end
  end
end

# Returns true if the string is not a number
#
class String
  def nan?
    self !~ /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/
  end
end
