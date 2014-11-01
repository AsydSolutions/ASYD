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
  property :monitored, Boolean, :default => false
  property :opt_vars, Object
  property :created_at, DateTime
  property :updated_at, DateTime
  has n, :hostgroup_members
  has n, :hostgroups, :through => :hostgroup_members

  def initialize(hostname, ip, user, ssh_port, password)
    begin
      #set the parameters as object properties
      self.hostname = hostname
      self.ip = ip
      self.user = user
      self.ssh_port = ssh_port
      #generate random monit password
      o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
      self.monit_pw = (0...8).map { o[rand(o.length)] }.join
      self.opt_vars = {} #initialize opt_vars as an empty hash
      #start connection to remote host
      Net::SSH.start(ip, user, :port => self.ssh_port, :password => password, :timeout => 10) do |ssh|
        #check for package manager and add distro
        #1. debian-based
        if !(ssh.exec!("which apt-get") =~ /\/bin\/apt-get$/).nil?
          self.pkg_mgr = "apt"
          if user != "root"
            ssh.exec!("sudo apt-get update && sudo apt-get -y -q install lsb-release")
          else
            ssh.exec!("apt-get update && apt-get -y -q install lsb-release")
          end
          self.dist = ssh.exec!("lsb_release -s -i").strip
          self.dist_ver = ssh.exec!("lsb_release -s -r").strip.to_f
          self.arch = ssh.exec!("uname -m").strip
        #2. redhat-based
        elsif !(ssh.exec!("which yum") =~ /\/bin\/yum$/).nil?
          self.pkg_mgr = "yum"
          if user != "root"
            ssh.exec!("sudo yum install -y dkms")
          else
            ssh.exec!("yum install -y dkms")
          end
          self.dist = ssh.exec!("/usr/lib/dkms/lsb_release -s -i").strip
          self.dist_ver = ssh.exec!("/usr/lib/dkms/lsb_release -s -r").strip.to_f
          self.arch = ssh.exec!("uname -m").strip
        #3. arch-based
        elsif !(ssh.exec!("which pacman") =~ /\/bin\/pacman$/).nil?
          self.pkg_mgr = "pacman"
          if user != "root"
            ssh.exec!("sudo pacman -Sy --noconfirm --noprogressbar lsb-release")
          else
            ssh.exec!("pacman -Sy --noconfirm --noprogressbar lsb-release")
          end
          self.dist = ssh.exec!("lsb_release -s -i").strip
          self.dist_ver = 0
          self.arch = ssh.exec!("uname -m").strip
        #4. opensuse
        elsif !(ssh.exec!("which zypper") =~ /\/bin\/zypper$/).nil?
          self.pkg_mgr = "zypper"
          self.dist = ssh.exec!("cat /etc/issue |awk 'NR == 1 {print $3}'").strip
          self.dist_ver = ssh.exec!("cat /etc/issue |awk 'NR == 1 {print $4}'").strip.to_f
          self.arch = ssh.exec!("uname -m").strip
        #5. solaris
        elsif !(ssh.exec!("export PATH=$PATH:/sbin:/usr/sbin/ && which pkgadd") =~ /\/sbin\/pkgadd$/).nil?
          self.pkg_mgr = "pkgadd"
          if !(ssh.exec!("which pkg") =~ /\/bin\/pkg$/).nil?
            self.pkg_mgr = "pkg"
          end
          ret = ssh.exec!("cat /etc/release").lines.first.strip
          if ret.include? "OpenIndiana"
            self.dist = "OpenIndiana"
            ret = ret.split(" ")
            ret.each do |item|
              if item =~ /oi_/
                dv = item.gsub(/oi_/, '')
                self.dist_ver = dv.to_f
              end
            end
          else
            self.dist = "Solaris"
            ret = ret.split("Solaris ")
            dv = ret[1].split(" ")
            self.dist_ver = dv[0].to_f
          end
          self.arch = ssh.exec!("uname -p").strip
        #6. openbsd
        elsif !(ssh.exec!("which pkg_add") =~ /\/sbin\/pkg_add$/).nil?
          self.pkg_mgr = "pkg_add"
          self.dist = ssh.exec!("uname -s").strip
          self.dist_ver = ssh.exec!("uname -r").strip.to_f
          self.arch = ssh.exec!("uname -p").strip
        else
          raise #OS not supported yet
        end
        #upload the ssh key
        ssh.scp.upload!("data/ssh_key.pub", "/tmp/ssh_key.pub")
        ssh.exec "mkdir -p $HOME/.ssh && touch $HOME/.ssh/authorized_keys && cat /tmp/ssh_key.pub >> $HOME/.ssh/authorized_keys && rm /tmp/ssh_key.pub"
      end
      if !self.save
        raise #couldn't save the object
      end
      mon = Spork.spork do #we fork the monitoring setup for saving time
        self.monitor()
      end
      NOTEX.synchronize do
        msg = "Monitoring setup for "+self.hostname+" in progress"
        Notification.create(:type => :info, :message => msg)
      end
      return self #return the object itself
    rescue Net::SSH::AuthenticationFailed
      return false
    rescue Errno::EHOSTUNREACH
      return false
    rescue Timeout::Error
      return false
    end
  end

  def add_var(name, value)
    vars = self.opt_vars #load opt_vars
    if !vars[name].nil?
      return false #error = varname exists
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
    return self.destroy
  end
end
