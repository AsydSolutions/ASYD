class Host
  include DataMapper::Resource
  include Monitoring::Host

  def self.default_repository_name #here we use the hosts_db for the Host objects
   :hosts_db
  end

  property :hostname, String, :key => true
  property :ip, String
  property :ssh_port, Integer
  property :user, String
  property :dist, String
  property :dist_ver, Float
  property :arch, String
  property :pkg_mgr, String
  property :svc_mgr, String
  property :monit_pw, String
  property :monitored, Boolean, :default => false # <-- DEPRECATED, keep for compatibility, will be removed in 2 releases
  property :opt_vars, Object
  property :created_at, DateTime
  property :updated_at, DateTime
  has n, :hostgroup_members
  has n, :hostgroups, :through => :hostgroup_members

  def self.init(hostname, ip, user, ssh_port, password)
    begin
      host = Host.create(:hostname => hostname.strip)
      #set the parameters as object properties
      host.ip = ip
      host.user = user
      host.ssh_port = ssh_port
      #generate random monit password
      o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
      host.monit_pw = (0...8).map { o[rand(o.length)] }.join
      host.opt_vars = {} #initialize opt_vars as an empty hash
      #start connection to remote host
      Net::SSH.start(host.ip, host.user, :port => host.ssh_port, :keys => "data/ssh_key", :password => password, :timeout => 10, :user_known_hosts_file => "/dev/null", :compression => true) do |ssh|
        #check for admin capabilities/nopasswd
        if user != "root"
          need_passwd = false
          last = nil
          ssh.exec!("echo 1 > /tmp/1")
          ssh.open_channel do |channel|
            channel.request_pty do |ch, success|
              raise StandardError, "Could not obtain pty" unless success
            end
            channel.exec("sudo cat /tmp/1") do |ch, success|
              raise unless success
              channel.on_data do |ch, data|
                if data =~ /^\[sudo\] password/ || data =~ /^Password/
                  need_passwd = true
                  channel.send_data "#{password}\n"
                elsif data.strip == "1"
                  last = "1"
                end
              end
            end
          end
          ssh.loop
          unless last == "1"
            raise StandardError, "User has no admin privileges"
          end
          if need_passwd
            cmd = "if [ -f \"/etc/sudoers.d/#{user}\" ]; then sudo cp /etc/sudoers.d/#{user} /tmp/sudoers#{user}; fi; sudo sh -c 'echo \"Defaults:#{user} !requiretty\" >> /tmp/sudoers#{user}'; sudo sh -c 'echo \"#{user} ALL=NOPASSWD: ALL\" >> /tmp/sudoers#{user}'; sudo sh -c 'uniq /tmp/sudoers#{user} > /etc/sudoers.d/#{user}'; sudo rm /tmp/sudoers#{user}"
            ssh.open_channel do |channel|
              channel.request_pty do |ch, success|
                raise StandardError, "Could not obtain pty" unless success
              end
              channel.exec(cmd) do |ch, success|
                raise unless success
                channel.on_data do |ch, data|
                  if data =~ /^\[sudo\] password/ || data =~ /^Password/
                    channel.send_data "#{password}\n"
                  end
                end
              end
            end
            ssh.loop
          end
          ret = ssh.exec!("sudo cat /tmp/1") # first check
          unless ret.strip == "1"            # if this fails likely there's a requiretty on sudoers
            cmd = "sudo sed -i '/requiretty/d' /etc/sudoers"
            ssh.open_channel do |channel|
              channel.request_pty do |ch, success|
                raise StandardError, "Could not obtain pty" unless success
              end
              channel.exec(cmd) do |ch, success|
                raise unless success
                channel.on_data do |ch, data|
                  # NOPASSWD already in sudoers file
                end
              end
            end
            ssh.loop
          end
          ret = ssh.exec!("sudo cat /tmp/1") # second check
          raise StandardError, "User has no admin privileges, please add '#{user} ALL=NOPASSWD: ALL' to /etc/sudoers and try again" unless ret.strip == "1"
          ssh.exec!("rm /tmp/1")
        end

        #upload the ssh key
        ssh.scp.upload!("data/ssh_key.pub", "/tmp/ssh_key.pub")
        ssh.exec "mkdir -p $HOME/.ssh && touch $HOME/.ssh/authorized_keys && mv $HOME/.ssh/authorized_keys /tmp/authorized_keys && cat /tmp/ssh_key.pub >> /tmp/authorized_keys && uniq /tmp/authorized_keys > $HOME/.ssh/authorized_keys && chmod 700 $HOME/.ssh/authorized_keys && rm /tmp/ssh_key.pub && rm /tmp/authorized_keys"
      end

      ret = Host.detect(host)
      raise StandardError, ret[1] if ret[0] == 5

      if !host.save
        raise StandardError, "Couldn't save the host" #couldn't save the object
      end
      Spork.spork do #we fork the monitoring setup for saving time
        host.monitor()
      end
      NOTEX.synchronize do
        msg = "Monitoring setup for "+host.hostname+" in progress"
        Notification.create(:type => :info, :message => msg)
      end
      return host #return the object itself
    rescue Net::SSH::AuthenticationFailed
      NOTEX.synchronize do
        Notification.create(:type => :error, :sticky => false, :message => I18n.t('error.host.auth'))
      end
      host.delete(false)
      return false
    rescue Errno::EHOSTUNREACH
      NOTEX.synchronize do
        Notification.create(:type => :error, :sticky => false, :message => I18n.t('error.host.unreach'))
      end
      host.delete(false)
      return false
    rescue => e
      error = I18n.t('error.host.misc')+": "+e.message
      NOTEX.synchronize do
        Notification.create(:type => :error, :sticky => false, :message => error)
      end
      host.delete(false) unless host.nil?
      return false
    end
  end

  after :create do
    # Add the new server to the statistics
    if HostStats.last.nil?
      t_hosts = 0
    else
      t_hosts = HostStats.last.total_hosts
    end
    stat = HostStats.first(:created_at => DateTime.now.beginning_of_day)
    if !stat
      HostStats.create(:created_at => DateTime.now.beginning_of_day, :total_hosts => t_hosts+1)
    else
      stat.total_hosts = stat.total_hosts + 1
      stat.save
    end
  end

  def add_var(name, value)
    vars = self.opt_vars #load opt_vars
    if !vars[name].nil?
      del_var(name)
    end
    vars[name] = value #add a new variable to the hash and update
    self.update(:opt_vars => nil)
    self.update(:opt_vars => vars)
    return true #all ok
  end

  def del_var(name)
    vars = self.opt_vars #load opt_vars
    if vars[name].nil?
      return false #error = varname doesn't exists
    end
    vars.delete(name) #delete the variable and update
    self.update(:opt_vars => nil)
    self.update(:opt_vars => vars)
    return true #all ok
  end

  def delete(revoke)
    if revoke == true
      ssh_key = File.open("data/ssh_key.pub", "r").read.strip
      cmd1 = '/bin/grep -v "'+ssh_key+'" /root/.ssh/authorized_keys > /tmp/auth_keys'
      cmd2 = 'mv /tmp/auth_keys /root/.ssh/authorized_keys'
      exec_cmd(cmd1)
      exec_cmd(cmd2)
    end
    self.hostgroup_members.all.destroy
    reload

    # remove the server from the statistics
    t_hosts = HostStats.last.total_hosts
    stat = HostStats.first(:created_at => DateTime.now.beginning_of_day)
    if !stat
      HostStats.create(:created_at => DateTime.now.beginning_of_day, :total_hosts => t_hosts-1)
    else
      stat.total_hosts = stat.total_hosts - 1
      stat.save
    end

    return self.destroy
  end

  def self.detect(host, save = false)
    begin
      sudo = ""
      sudo = "sudo " if host.user != "root"
      Net::SSH.start(host.ip, host.user, :port => host.ssh_port, :keys => "data/ssh_key", :timeout => 10, :user_known_hosts_file => "/dev/null", :compression => true) do |ssh|
        #check for package manager and add distro
        #1. debian-based
        if !(ssh.exec!("which apt-get") =~ /\/bin\/apt-get$/).nil?
          host.pkg_mgr = "apt"
          if (ssh.exec!("which wget") =~ /\/bin\/wget$/).nil?
            ssh.exec!(sudo+"apt-get -y -q install wget")
          end
          ssh.exec!("wget --no-check-certificate https://raw.githubusercontent.com/AsydSolutions/lsb_release/master/lsb_release -O /tmp/lsb_release && chmod +x /tmp/lsb_release")
          host.dist = ssh.exec!(sudo+"/tmp/lsb_release -s -i").strip
          host.dist_ver = ssh.exec!(sudo+"/tmp/lsb_release -s -r").strip.to_f
          host.arch = ssh.exec!("uname -m").strip
        #2. redhat-based w/ dnf package manager (Fedora 22)
        elsif !(ssh.exec!("which dnf") =~ /\/bin\/dnf$/).nil?
          host.pkg_mgr = "dnf"
          if (ssh.exec!("which scp") =~ /\/bin\/scp$/).nil? || (ssh.exec!("which wget") =~ /\/bin\/wget$/).nil?
            ssh.exec!(sudo+"dnf install -y openssh-clients wget")
          end
          ssh.exec!("wget --no-check-certificate https://raw.githubusercontent.com/AsydSolutions/lsb_release/master/lsb_release -O /tmp/lsb_release && chmod +x /tmp/lsb_release")
          host.dist = ssh.exec!(sudo+"/tmp/lsb_release -s -i").strip
          host.dist_ver = ssh.exec!(sudo+"/tmp/lsb_release -s -r").strip.to_f
          host.arch = ssh.exec!("uname -m").strip
        #3. redhat-based
        elsif !(ssh.exec!("which yum") =~ /\/bin\/yum$/).nil?
          host.pkg_mgr = "yum"
          if (ssh.exec!("which scp") =~ /\/bin\/scp$/).nil? || (ssh.exec!("which wget") =~ /\/bin\/wget$/).nil?
            ssh.exec!(sudo+"yum install -y openssh-clients wget")
          end
          ssh.exec!("wget --no-check-certificate https://raw.githubusercontent.com/AsydSolutions/lsb_release/master/lsb_release -O /tmp/lsb_release && chmod +x /tmp/lsb_release")
          host.dist = ssh.exec!(sudo+"/tmp/lsb_release -s -i").strip
          host.dist_ver = ssh.exec!(sudo+"/tmp/lsb_release -s -r").strip.to_f
          host.arch = ssh.exec!("uname -m").strip
        #4. arch-based
        elsif !(ssh.exec!("which pacman") =~ /\/bin\/pacman$/).nil?
          host.pkg_mgr = "pacman"
          if (ssh.exec!("which wget") =~ /\/bin\/wget$/).nil?
            ssh.exec!(sudo+"pacman -S --noconfirm --noprogressbar wget")
          end
          ssh.exec!("wget --no-check-certificate https://raw.githubusercontent.com/AsydSolutions/lsb_release/master/lsb_release -O /tmp/lsb_release && chmod +x /tmp/lsb_release")
          host.dist = ssh.exec!(sudo+"/tmp/lsb_release -s -i").strip
          host.dist_ver = 0
          host.arch = ssh.exec!("uname -m").strip
        #5. opensuse
        elsif !(ssh.exec!("which zypper") =~ /\/bin\/zypper$/).nil?
          host.pkg_mgr = "zypper"
          if (ssh.exec!("which wget") =~ /\/bin\/wget$/).nil?
            ssh.exec!(sudo+"zypper -q -n in wget")
          end
          ssh.exec!("wget --no-check-certificate https://raw.githubusercontent.com/AsydSolutions/lsb_release/master/lsb_release -O /tmp/lsb_release && chmod +x /tmp/lsb_release")
          host.dist = ssh.exec!(sudo+"/tmp/lsb_release -s -i").strip
          host.dist_ver = ssh.exec!(sudo+"/tmp/lsb_release -s -r").strip.to_f
          host.arch = ssh.exec!("uname -m").strip
        #6. void-linux
        elsif !(ssh.exec!("which xbps-install") =~ /\/bin\/xbps-install$/).nil?
          host.pkg_mgr = "xbps"
          host.dist = "Void Linux"
          host.dist_ver = ssh.exec!("uname -r").strip.to_f
          host.arch = ssh.exec!("uname -m").strip
        #7. solaris
        elsif !(ssh.exec!("export PATH=$PATH:/sbin:/usr/sbin/ && which pkgadd") =~ /\/sbin\/pkgadd$/).nil?
          host.pkg_mgr = "pkgadd"
          if !(ssh.exec!("which pkg") =~ /\/bin\/pkg$/).nil?
            host.pkg_mgr = "pkg"
          end
          ret = ssh.exec!("cat /etc/release").lines.first.strip
          if ret.include? "OpenIndiana"
            host.dist = "OpenIndiana"
            ret = ret.split(" ")
            ret.each do |item|
              if item =~ /oi_/
                dv = item.gsub(/oi_/, '')
                host.dist_ver = dv.to_f
              end
            end
          else
            host.dist = "Solaris"
            ret = ret.split("Solaris ")
            dv = ret[1].split(" ")
            host.dist_ver = dv[0].to_f
          end
          host.arch = ssh.exec!("uname -p").strip
        #8. openbsd
        elsif !(ssh.exec!("which pkg_add") =~ /\/sbin\/pkg_add$/).nil?
          host.pkg_mgr = "pkg_add"
          host.dist = ssh.exec!("uname -s").strip
          host.dist_ver = ssh.exec!("uname -r").strip.to_f
          host.arch = ssh.exec!("uname -m").strip
        else
          raise StandardError, "The OS of the machine is not yet supported" #OS not supported yet
        end

        #check for services (initscript) manager
        if !(ssh.exec!(sudo+"which systemctl") =~ /\/bin\/systemctl$/).nil?
          ssh.exec!(sudo+"mkdir -p /usr/lib/systemd/system/")
          host.svc_mgr = "systemctl"    # most newer distros
        elsif !(ssh.exec!(sudo+"which update-rc.d") =~ /\/sbin\/update-rc.d$/).nil?
          host.svc_mgr = "update-rc.d"  # old debian
        elsif !(ssh.exec!(sudo+"which chkconfig") =~ /\/sbin\/chkconfig$/).nil?
          host.svc_mgr = "chkconfig"    # old rhel
        elsif !(ssh.exec!("which runit") =~ /\/bin\/runit$/).nil?
          host.svc_mgr = "runit"  # void-linux
        elsif host.pkg_mgr == "pkg_add"
          host.svc_mgr = "rc.d"         # openbsd
        else
          host.svc_mgr = "none"         # else (i.e. solaris)
        end
        host.save if save
        return [1, ""]

      end
    rescue => e
      return [5, e.message]
    end
  end
end
