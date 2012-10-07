require 'net/ssh'
require 'net/scp'

def monitor
  arr = get_dirs("data/servers/")
  arr.each do |srv|
    Thread.new do
      name = srv.to_s
      path = "data/servers/" + name + "/srv.info"
      f = File.open(path, "r")
      host = f.gets
      var_name = "$up_" + name
      Net::SSH.start(host.strip, "root", :keys => "data/private_key") do |ssh|
        while true do
          uptime = ssh.exec!("uptime")
          eval("#{var_name} = uptime")
          sleep 10
        end
      end
    end
  end
end
