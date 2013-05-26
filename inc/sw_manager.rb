require 'net/ssh'
require 'net/scp'
require 'fileutils'

def install_pkg(host,pkg)
  begin
    path = "data/servers/"+host+"/srv.info"
    f = File.open(path, "r")
    host = f.gets.strip
    dist_name = f.gets.strip
    dist_ver  = f.gets.strip
    pkg_mgr = f.gets.strip
    if pkg_mgr == "apt"
      cmd = pkg_mgr+"-get -y install "+pkg
    end
    f.close
    Net::SSH.start(host.strip, "root", :keys => "data/ssh_key") do |ssh|
      result = ssh.exec!(cmd)
      p result
    end    
  rescue SystemExit
    @error = ''
    return @error
  end
end
