def srv_init(host, ip, password)
  begin
  distro,dist_host,dist_ver,arch,pkg_mgr = ""

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
  servers.execute("INSERT INTO servers (hostname, ip, dist, dist_ver, arch, pkg_mgr) VALUES (?, ?, ?, ?, ?, ?)", [host, ip, dist_host, dist_ver, arch, pkg_mgr])
  servers.close

  monitor(host)

  if $error.nil?
    $done = host+" successfully added"
  end

  rescue SystemExit
    @error = 'Unsupported system'
    return @error
  end
end
