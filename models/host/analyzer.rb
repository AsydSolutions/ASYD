class Host

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
        #9. freebsd
        elsif !(ssh.exec!("which freebsd-version") =~ /\/bin\/freebsd-version$/).nil?
          host.pkg_mgr = "pkg"
          host.dist = ssh.exec!("uname -s").strip
          host.dist_ver = ssh.exec!("uname -r").strip[/\d+(?:\.\d+)?/]
          host.arch = ssh.exec!("uname -m").strip
        #10. MacOsX
        elsif !(ssh.exec!("which sw_vers") =~ /\/bin\/sw_vers$/).nil?
          host.pkg_mgr = "port"
          host.dist = ssh.exec!("sw_vers -productName").gsub(/\s+/, "")
          host.dist_ver = ssh.exec!("sw_vers -productVersion").strip
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
        elsif !(ssh.exec!(sudo+"which runit") =~ /\/bin\/runit$/).nil?
          host.svc_mgr = "runit"  # void-linux
        elsif host.pkg_mgr == "pkg_add"
          host.svc_mgr = "rc.d"         # openbsd
        elsif !(ssh.exec!(sudo+"which freebsd-version") =~ /\/bin\/freebsd-version$/).nil?
          host.svc_mgr = "service"
        elsif !(ssh.exec!(sudo+"which launchd") =~ /\/sbin\/launchd$/).nil?
          host.svc_mgr = "launchd"
        else
          host.svc_mgr = "none"         # else (i.e. solaris)
        end
        host.save if save
        return [1, ""]

      end
    rescue => e
      e.backtrace.each { |etrace| puts etrace }
      return [5, e.message]
    end
  end

end
