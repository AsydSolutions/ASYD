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
      Net::SSH.start(host.ip, host.user, :port => host.ssh_port, :keys => "data/ssh_key", :password => password, :timeout => 10) do |ssh|
        #check for package manager and add distro
        #1. debian-based
        if !(ssh.exec!("which apt-get") =~ /\/bin\/apt-get$/).nil?
          host.pkg_mgr = "apt"
          if (ssh.exec!("which lsb_release") =~ /\/bin\/lsb_release$/).nil?
            if user != "root"
              ssh.exec!("sudo apt-get -y -q install lsb-release")
            else
              ssh.exec!("apt-get -y -q install lsb-release")
            end
          end
          host.dist = ssh.exec!("lsb_release -s -i").strip
          host.dist_ver = ssh.exec!("lsb_release -s -r").strip.to_f
          host.arch = ssh.exec!("uname -m").strip
        #2. redhat-based
        elsif !(ssh.exec!("which yum") =~ /\/bin\/yum$/).nil?
          host.pkg_mgr = "yum"
          if (ssh.exec!("which scp") =~ /\/bin\/scp$/).nil?
            if user != "root"
              ssh.exec!("sudo yum install -y openssh-clients")
            else
              ssh.exec!("yum install -y openssh-clients")
            end
          end
          host.dist = ssh.exec!("cat /etc/issue |awk 'NR == 1 {print $1}'").strip
          if host.dist == "Red"
            host.dist = "RedHat"
          end
          host.dist_ver = ssh.exec!("cat /etc/issue |awk -F\"release\" 'NR==1 {print $2}'|awk '{print $1}'").strip.to_f
          host.arch = ssh.exec!("uname -m").strip
        #3. arch-based
        elsif !(ssh.exec!("which pacman") =~ /\/bin\/pacman$/).nil?
          host.pkg_mgr = "pacman"
          if (ssh.exec!("which lsb_release") =~ /\/bin\/lsb_release$/).nil?
            if user != "root"
              ssh.exec!("sudo pacman -S --noconfirm --noprogressbar lsb-release")
            else
              ssh.exec!("pacman -S --noconfirm --noprogressbar lsb-release")
            end
          end
          host.dist = ssh.exec!("lsb_release -s -i").strip
          host.dist_ver = 0
          host.arch = ssh.exec!("uname -m").strip
        #4. opensuse
        elsif !(ssh.exec!("which zypper") =~ /\/bin\/zypper$/).nil?
          host.pkg_mgr = "zypper"
          host.dist = ssh.exec!("cat /etc/issue |awk 'NR == 1 {print $3}'").strip
          host.dist_ver = ssh.exec!("cat /etc/issue |awk 'NR == 1 {print $4}'").strip.to_f
          host.arch = ssh.exec!("uname -m").strip
        #5. solaris
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
        #6. openbsd
        elsif !(ssh.exec!("which pkg_add") =~ /\/sbin\/pkg_add$/).nil?
          host.pkg_mgr = "pkg_add"
          host.dist = ssh.exec!("uname -s").strip
          host.dist_ver = ssh.exec!("uname -r").strip.to_f
          host.arch = ssh.exec!("uname -p").strip
        else
          raise #OS not supported yet
        end
        #upload the ssh key
        ssh.scp.upload!("data/ssh_key.pub", "/tmp/ssh_key.pub")
        ssh.exec "mkdir -p $HOME/.ssh && touch $HOME/.ssh/authorized_keys && mv $HOME/.ssh/authorized_keys /tmp/authorized_keys && cat /tmp/ssh_key.pub >> /tmp/authorized_keys && uniq /tmp/authorized_keys > $HOME/.ssh/authorized_keys && rm /tmp/ssh_key.pub && rm /tmp/authorized_keys"
      end

      if !host.save
        raise #couldn't save the object
      end
      mon = Spork.spork do #we fork the monitoring setup for saving time
        host.monitor()
      end
      NOTEX.synchronize do
        msg = "Monitoring setup for "+host.hostname+" in progress"
        Notification.create(:type => :info, :message => msg)
      end
      return host #return the object itself
    rescue Net::SSH::AuthenticationFailed
      NOTEX.synchronize do
        notification = Notification.create(:type => :error, :sticky => false, :message => I18n.t('error.host.auth'))
      end
      return false
    rescue Errno::EHOSTUNREACH
      NOTEX.synchronize do
        notification = Notification.create(:type => :error, :sticky => false, :message => I18n.t('error.host.unreach'))
      end
      return false
    rescue => e
      error = I18n.t('error.host.misc')+": "+e.message
      NOTEX.synchronize do
        notification = Notification.create(:type => :error, :sticky => false, :message => error)
      end
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
end
