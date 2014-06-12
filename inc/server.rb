def srv_init(host, ip, password)
  begin
  distro,dist_host,dist_ver,arch,pkg_mgr = ""
  o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
  monit_pw = (0...8).map { o[rand(o.length)] }.join


  Net::SSH.start(ip, "root", :password => password) do |ssh|
    distro = ssh.exec!("cat /etc/issue")
    distro = distro.split
    dist_host = distro[0]
    dist_ver  = distro[2]

    if dist_host == "Debian" or dist_host == "Ubuntu"
      pkg_mgr = "apt"
    elsif dist_host == "Fedora" or dist_host == "CentOS"
      pkg_mgr = "yum"
    else
      exit
    end

    arch = ssh.exec!("uname -m")

    ssh.scp.upload!("data/ssh_key.pub", "/tmp/ssh_key.pub")
    ssh.exec "mkdir -p /root/.ssh && touch /root/.ssh/authorized_keys && cat /tmp/ssh_key.pub >> /root/.ssh/authorized_keys && rm /tmp/ssh_key.pub"

  end

  servers = SQLite3::Database.new "data/db/servers.db"
  servers.execute("INSERT INTO servers (hostname, ip, dist, dist_ver, arch, pkg_mgr, monit_pw) VALUES (?, ?, ?, ?, ?, ?, ?)", [host, ip, dist_host, dist_ver, arch, pkg_mgr, monit_pw])
  servers.close

  monitor(host)

  done = host+" successfully added"
  add_notification(2, done, 0)

  rescue SystemExit
    error = 'Unsupported system'
    add_notification(0, error, 0)
  end
end

def remove_server(host, revoke)
  if revoke == true
    hostdata = get_host_data(host)
    ip = hostdata[:ip]
    ssh_key = File.open("data/ssh_key.pub", "r").read.strip
    cmd = '/bin/grep -v "'+ssh_key+'" /root/.ssh/authorized_keys > /tmp/auth_keys && mv /tmp/auth_keys /root/.ssh/authorized_keys'
    exec_cmd(ip, cmd)
  end
  servers = SQLite3::Database.new "data/db/servers.db"
  servers.execute("DELETE FROM servers WHERE hostname=?", host)
  servers.close
  groups = get_hostgroup_list
  groups.each do |group|
    del_group_member(group, host)
  end
end
