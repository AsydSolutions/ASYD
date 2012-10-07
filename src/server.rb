require 'net/ssh'
require 'net/scp'
require 'fileutils'

def srv_init(name, host, password)
  Net::SSH.start(host, "root", :password => password) do |ssh|
    ssh.scp.upload!("data/ssh_key.pub", "/tmp/ssh_key.pub")
    ssh.exec "cat /tmp/ssh_key.pub >> /root/.ssh/authorized_keys"
    ssh.exec "rm /tmp/ssh_key.pub"
  end
  FileUtils.mkdir_p("data/servers/" + name)
  f = File.new("data/servers/"+name+"/srv.info",  "w+")
  f.puts host
  f.close
end
