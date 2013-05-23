require 'net/ssh'
require 'net/scp'
require 'fileutils'

def srv_init(name, host, password)
  dist = ""
  Net::SSH.start(host, "root", :password => password) do |ssh|
    ssh.scp.upload!("data/ssh_key.pub", "/tmp/ssh_key.pub")
    ssh.exec "mkdir -p /root/.ssh && touch /root/.ssh/authorized_keys && cat /tmp/ssh_key.pub >> /root/.ssh/authorized_keys && rm /tmp/ssh_key.pub"
#    ssh.exec "touch /root/.ssh/authorized_keys"
#    ssh.exec "cat /tmp/ssh_key.pub >> /root/.ssh/authorized_keys"
#    ssh.exec "rm /tmp/ssh_key.pub"
    path = ""
    ssh.exec!("which apt-get")  do |channel, stream, data|
      path << data if stream == :stdout
    end
    if path.include? "/apt-get"
      dist = "apt"
    else
      dist = "yum"
    end
  end
  FileUtils.mkdir_p("data/servers/" + name)
  f = File.new("data/servers/"+name+"/srv.info",  "w+")
  f.puts host
  f.puts dist
  f.close
end
