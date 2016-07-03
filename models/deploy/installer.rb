class Deploy
  include Misc

  # Install package or packages on defined host
  #
  def self.install(host, pkg, dry_run = false, pkg_mgr = nil)
    begin
      if pkg.include? "&" or pkg.include? "|" or pkg.include? ">" or pkg.include? "<" or pkg.include? "`" or pkg.include? "$"
        raise FormatException
      end
      if host.dist == "Solaris" || host.dist == "OpenIndiana"
        if pkg_mgr == "pkgadd"  #ok
        elsif pkg_mgr == "pkgutil"  #ok
        elsif pkg_mgr == "pkg"  #ok
        else
          pkg_mgr = host.pkg_mgr  #use standard
        end
      else
        pkg_mgr = host.pkg_mgr
      end
      cmd = pkg_mgr
      #1. apt
      if pkg_mgr == "apt"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+"-get update && "+cmd+"-get -y -q --no-install-recommends install "+pkg
      #2. yum
      elsif pkg_mgr == "yum"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" install -y "+pkg
      #3. dnf (used by Fedora 22)
      elsif pkg_mgr == "dnf"
        if host.user != "root"
          cmd = "sudo " + pkg_mgr
        end
        cmd = cmd + " install -y " + pkg
      #4. pacman
      elsif pkg_mgr == "pacman"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" -Sy --noconfirm --noprogressbar "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #5. zypper
      elsif pkg_mgr == "zypper"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" -q -n in "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #6. void-linux
      elsif pkg_mgr == "xbps"
        if host.user != "root"
          cmd = "sudo /usr/bin/"+pkg_mgr
        else
          cmd = "/usr/bin/"+pkg_mgr
        end
        cmd = cmd + "-install -y " + pkg     ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #7.1. solaris pkgadd
      elsif pkg_mgr == "pkgadd"
        if host.user != "root"
          cmd = "sudo /usr/sbin/"+pkg_mgr
        else
          cmd = "/usr/sbin/"+pkg_mgr
        end
        cmd = cmd+" -a /etc/admin -d "+pkg+" all"    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #7.2. solaris pkg
      elsif pkg_mgr == "pkg"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        # 7.3 freebsd also uses pkg
        if host.dist == "FreeBSD"
          cmd = cmd+" install --yes "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
        else
          cmd = cmd+" install --accept "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
        end
      #7.4. solaris pkgutil
      elsif pkg_mgr == "pkgutil"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" -y -i "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #8. openbsd pkg_add
      elsif pkg_mgr == "pkg_add"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        pkg_path = 'export PKG_PATH="http://ftp.openbsd.org/pub/OpenBSD/'+host.dist_ver.to_s+'/packages/'+host.arch+'/"'
        cmd = pkg_path+" && "+cmd+" -U -I -x "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #9. macosx port
      elsif pkg_mgr == "port"
        if host.user != "root"
          cmd = "sudo " + pkg_mgr
        end
        cmd = cmd + " install -c " + pkg ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      end
      unless dry_run
        result = host.exec_cmd(cmd)
        unless result.nil?
          if result.include? "\nE: "
            raise ExecutionError, result
          else
            result = result.split("\n").last
            return [1, result]
          end
        else
          return [1, "--"]
        end
      else
        return [0, ""]
      end
    rescue FormatException
      error = "Invalid characters detected on package name: "+pkg
      return [5, error]
    rescue ExecutionError => e
      err = e.message.split("\n")
      error = "Error installing "+pkg+" on "+host.hostname+": "+err.last
      return [4, error]
    rescue => e
      error = "Something really bad happened when installing "+pkg+" on "+host.hostname+": "+e.message
      return [4, error]
    end
  end

  # Uninstall package or packages on defined host
  #
  def self.uninstall(host, pkg, dry_run = false, pkg_mgr = nil)
    begin

      if pkg.include? "&" or pkg.include? "|" or pkg.include? ">" or pkg.include? "<" or pkg.include? "`" or pkg.include? "$"
        raise FormatException
      end
      if host.dist == "Solaris" || host.dist == "OpenIndiana"
        if pkg_mgr == "pkgadd"  #ok
        elsif pkg_mgr == "pkgutil"  #ok
        elsif pkg_mgr == "pkg"  #ok
        else
          pkg_mgr = host.pkg_mgr  #use standard
        end
      else
        pkg_mgr = host.pkg_mgr
      end
      cmd = pkg_mgr
      #1. apt
      if pkg_mgr == "apt"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+"-get -y -q remove "+pkg
      #2. yum
      elsif pkg_mgr == "yum"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" remove -y "+pkg
      #3. dnf (used by Fedora 22)
      elsif pkg_mgr == "dnf"
        if host.user != "root"
          cmd = "sudo " + pkg_mgr
        end
        cmd = cmd + " remove -y " + pkg
      #4. pacman
      elsif pkg_mgr == "pacman"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" -R --noconfirm --noprogressbar "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #5. zypper
      elsif pkg_mgr == "zypper"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" -q -n rm "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #6. void-linux
      elsif pkg_mgr == "xbps"
        if host.user != "root"
          cmd = "sudo /usr/bin/"+pkg_mgr
        else
          cmd = "/usr/bin/"+pkg_mgr
        end
        cmd = cmd + "-remove -y "+pkg     ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #7.1. solaris pkgadd
      elsif pkg_mgr == "pkgadd"
        if host.user != "root"
          cmd = "sudo /usr/sbin/pkgrm"
        else
          cmd = "/usr/sbin/pkgrm"
        end
        cmd = cmd+" -a /etc/admin "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #7.2. solaris pkg
      elsif pkg_mgr == "pkg"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        #7.3 freebsd also uses pkg
        if host.dist == "FreeBSD"
          cmd = cmd+" uninstall --yes"+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
        else
          cmd = cmd+" uninstall "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
        end
      #7.4. solaris pkgutil
      elsif pkg_mgr == "pkgutil"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" -y -r "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #8. openbsd pkg_add
      elsif pkg_mgr == "pkg_add"
        cmd = "pkg_delete"
        if host.user != "root"
          cmd = "sudo "+cmd
        end
        cmd = cmd+" -I -x "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #9. macosx port
      elsif pkg_mgr == "port"
        if host.user != "root"
          cmd = "sudo " + pkg_mgr
        end
        cmd = cmd + " -u uninstall " + pkg ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      end
      unless dry_run
        result = host.exec_cmd(cmd)
        if result.include? "\nE: "
          raise ExecutionError, result
        else
          result = result.split("\n").last
          return [1, result]
        end
      else
        return [0, ""]
      end
    rescue FormatException
      error = "Invalid characters detected on package name: "+pkg
      return [5, error]
    rescue ExecutionError => e
      err = e.message.split("\n")
      error = "Error uninstalling "+pkg+" on "+host.hostname+": "+err.last
      return [4, error]
    rescue => e
      error = "Something really bad happened when uninstalling "+pkg+" on "+host.hostname+": "+e.message
      return [4, error]
    end
  end

end
