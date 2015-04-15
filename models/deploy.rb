class Deploy
  include Misc

  # Return a list of deploys
  #
  def self.all
    deploys = Misc::get_dirs("data/deploys/")
    return deploys
  end

  # Return the alerts for all the deploys
  #
  def self.get_alerts
    deploys = Deploy.all
    alerts = {}
    deploys.each do |deploy|
      path = "data/deploys/"+deploy+"/def"
      f = File.open(path, "r").read
      f.gsub!(/\r\n?/, "\n")
      f.each_line do |line|
        if !line.match(/^# ?alert:/i).nil?
          if alerts[deploy].nil? #first alert on the deploy
            alert = line.gsub!(/^# ?alert:/i, "").strip
            alerts[deploy] = HTMLEntities.new.encode(HTMLEntities.new.encode(alert))
          else #more alerts with newlines
            alert = line.gsub!(/^# ?alert:/i, "").strip
            alerts[deploy] = alerts[deploy]+"<br />"+HTMLEntities.new.encode(HTMLEntities.new.encode(alert))
          end
        end
      end
    end
    return alerts
  end

  # Return the alerts for all the undeploys
  #
  def self.get_undeploy_alerts
    deploys = Deploy.all
    alerts = {}
    deploys.each do |deploy|
      if can_undeploy?(deploy)
        path = "data/deploys/"+deploy+"/undeploy"
        f = File.open(path, "r").read
        f.gsub!(/\r\n?/, "\n")
        f.each_line do |line|
          if !line.match(/^# ?alert:/i).nil?
            if alerts[deploy].nil?
              alert = line.gsub!(/^# ?alert:/i, "").strip
              alerts[deploy] = HTMLEntities.new.encode(HTMLEntities.new.encode(alert))
            else
              alert = line.gsub!(/^# ?alert:/i, "").strip
              alerts[deploy] = alerts[deploy]+"<br />"+HTMLEntities.new.encode(HTMLEntities.new.encode(alert))
            end
          end
        end
      end
    end
    return alerts
  end

  # Return true if it can be undeployed
  #
  def self.can_undeploy?(dep)
    if File.exists?("data/deploys/"+dep+"/undeploy")
      return true
    else
      return false
    end
  end

  # Delete a deploy
  #
  def self.delete(dep)
    path='data/deploys/'+dep
    FileUtils.rm_r path, :secure=>true
  end

  # Deploy a deploy on the defined host
  #
  def self.launch(host, dep, task)
    begin
      if host.nil?
        error = "Error: host not found"
        raise ExecutionError, error
      end
      if !Misc::is_port_open?(host.ip, host.ssh_port, pingback=true)
        error = "Error: host "+host.hostname+" unreachable"
        raise TargetUnreachable, error
      end

      cfg_root = "data/deploys/"+dep+"/configs/"
      if host.user != "root" && File.exists?("data/deploys/"+dep+"/def.sudo")
        path = "data/deploys/"+dep+"/def.sudo"
        sudo = true
      else
        path = "data/deploys/"+dep+"/def"
        sudo = false
      end

      # TODO
      # ret = check_deploy(dep, sudo)
      # if ret[0] == 5
      #   raise FormatException, ret[1]
      # end

      ret = Deploy.deploy(host, path, cfg_root, task)
      return ret
    rescue ExecutionError => e
      return [4, e.message] # 4 == execution error
    rescue TargetUnreachable => e
      return [6, e.message] # 6 == host unreachable
    end
  end

  # Undeploy a given deploy on the defined host
  #
  def self.undeploy(host, dep, task)
    begin
      if host.nil?
        error = "Error: host not found"
        raise ExecutionError, error
      end
      if !Misc::is_port_open?(host.ip, host.ssh_port, pingback=true)
        error = "Error: host "+host.hostname+" unreachable"
        raise TargetUnreachable, error
      end

      cfg_root = "data/deploys/"+dep+"/configs/"
      if host.user != "root" && File.exists?("data/deploys/"+dep+"/undeploy.sudo")
        path = "data/deploys/"+dep+"/undeploy.sudo"
        sudo = true
      else
        path = "data/deploys/"+dep+"/undeploy"
        sudo = false
      end

      # TODO
      # ret = check_deploy(dep, sudo)
      # if ret[0] == 5
      #   raise FormatException, ret[1]
      # end

      ret = Deploy.deploy(host, path, cfg_root, task)
      return ret
    rescue ExecutionError => e
      return [4, e.message] # 4 == execution error
    rescue TargetUnreachable => e
      return [6, e.message] # 6 == host unreachable
    end
  end

  # Deploys the file in "path" (def, def.sudo, undeploy or undeploy.sudo)
  #
  def self.deploy(host, path, cfg_root, task)
    begin
      condition = false #indicates if you are inside a conditional block
      gdoit = true #global doit, used for conditional blocks
      skip = false

      f = File.open(path, "r").read
      f.gsub!(/\r\n?/, "\n")
      f.each_line do |line|
        line = line.strip

        # Check for deploy global conditionals
        if !condition
          m = line.match(/^if (.+)$/i)
          if !m.nil?
            gdoit = check_condition(m, host)
            condition = true
            skip = true
          end
        else
          if line.match(/^endif$/i)
            condition = false
            gdoit = true
            skip = true
          end
        end

        # Set variables from a Deploy
        if gdoit && m = line.match(/^var (.+) = (exec|http)/i)
          varname = m[1] #we create varname here
          line = line.split(/ = /, 2)[1].strip #and remove the start of the line so we have only the exec or http part
        end

        # IGNORE
        if line.start_with?("#") || line.strip.empty? || skip || !gdoit
          # Ignore comments, empty lines, if it's a "skip" (conditional) line or if the global "doit" for the block is false
          skip = false #and reset the skip
        # /IGNORE

        # INSTALL BLOCK
        elsif line.start_with?("install")
          doit = true
          pkg_mgr = line.match(/^install (pkgutil|pkg|pkgadd)?(?: if .+)?(?<!var):/i) ? line.match(/^install (pkgutil|pkg|pkgadd)?(?: if .+)?(?<!var):/i) : nil
          m = line.match(/^install (?:pkgutil |pkg |pkgadd )?if (.+)(?<!var):/i)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(/(?<!var):/i, 2)
            pkgs = line[1].strip
            ret = Deploy.install(host, pkgs, pkg_mgr)
            if ret[0] == 1
              msg = "Installed "+pkgs+" on "+host.hostname+": "+ret[1]
              NOTEX.synchronize do
                notification = Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
              end
            elsif ret[0] == 4
              raise ExecutionError, ret[1]
            elsif ret[0] == 5
              raise FormatException, ret[1]
            end
          end
        # /INSTALL BLOCK

        # UNINSTALL BLOCK
        elsif line.start_with?("uninstall")
          doit = true
          m = line.match(/^uninstall if (.+)(?<!var):/i)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(/(?<!var):/i, 2)
            pkgs = line[1].strip
            ret = Deploy.uninstall(host, pkgs)
            if ret[0] == 1
              msg = "Removed "+pkgs+" from "+host.hostname+": "+ret[1]
              NOTEX.synchronize do
                notification = Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
              end
            elsif ret[0] == 4
              raise ExecutionError, ret[1]
            elsif ret[0] == 5
              raise FormatException, ret[1]
            end
          end
        # /UNINSTALL BLOCK

        # CONFIG FILE BLOCK
        elsif line.match(/^(noparse )?config file/i)
          noparse = false
          if line.start_with?("noparse")
            noparse = true
          end
          doit = true
          m = line.match(/config file if (.+)(?<!var):/i)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(/(?<!var):/i, 2)
            cfg = line[1].split(',')
            cfg_src = cfg_root+cfg[0].strip
            parsed_cfg = parse_config(host, cfg_src) unless noparse
            cfg_dst = cfg[1].strip
            if noparse
              host.upload_file(cfg_src, cfg_dst)
            else
              host.upload_file(parsed_cfg.path, cfg_dst)
            end
            parsed_cfg.unlink unless noparse
            msg = "Uploaded "+cfg_src+" to "+cfg_dst+" on "+host.hostname
            NOTEX.synchronize do
              notification = Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
            end
          end
        # /CONFIG FILE BLOCK

        # CONFIG DIR BLOCK
        elsif line.match(/^(noparse )?config dir/i)
          noparse = false
          if line.start_with?("noparse")
            noparse = true
          end
          doit = true
          m = line.match(/config dir if (.+)(?<!var):/i)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(/(?<!var):/i, 2)
            cfg = line[1].split(',')
            cfg_src = cfg_root+cfg[0].strip
            cfg_dst = cfg[1].strip
            parsed_cfg = parse_config_dir(host, cfg_src, nil) unless noparse
            if noparse
              host.upload_dir(cfg_src, cfg_dst)
            else
              host.upload_dir(parsed_cfg, cfg_dst)
            end
            FileUtils.rm_r parsed_cfg, :secure=>true unless noparse
            msg = "Uploaded "+cfg_src+" to "+cfg_dst+" on "+host.hostname
            NOTEX.synchronize do
              notification = Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
            end
          end
        # /CONFIG DIR BLOCK

        # EXEC BLOCK
        elsif line.start_with?("exec")
          doit = true
          m = line.match(/^exec (.(var:|[^:])+)/i)
          if !m.nil? #there's some param
            m2 = m[1].split(/if\s?/)
            if !m2[1].nil? #there's conditionals
              #if there's a host defined, we act over the defined host
              if !m2[0].nil? && !m2[0].empty?
                other_host = Host.first(:hostname => m2[0].strip)
                if other_host.nil?  #the defined host doesn't exists
                  error = "Host "+m2[0].strip+" not found"
                  raise FormatException, error
                end
                doit = check_condition(m2, other_host)
                exec_host = other_host #execute on remote host
              else #no host defined
                doit = check_condition(m2, host)
                exec_host = host #execute in host normally
              end
            elsif !m2[0].nil? #no conditionals but remote execution
              other_host = Host.first(:hostname => m2[0].strip)
              if other_host.nil?  #the defined host doesn't exists
                error = "Host "+m2[0].strip+" not found"
                raise FormatException, error
              end
              exec_host = other_host #use remote
            end
          else #just act normally, no params
            exec_host = host #use host
          end
          if doit #we have doit and exec_host defined, so execute the command
            line = line.split(/(?<!var):/i, 2)
            cmd = parse(host, line[1].strip) #parse for vars
            ret = exec_host.exec_cmd(cmd)
            msg = "Executed '"+cmd+"' on "+exec_host.hostname
            msg = msg+": "+ret unless ret.nil?
            NOTEX.synchronize do
              notification = Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
            end
          end
        # /EXEC BLOCK

        # HTTP BLOCK
        elsif line.match(/^http (get|post)/i)
          doit = true
          m = line.match(/if (.+)(?<!var):/i)
          if !m.nil?
            doit = check_condition(m, host)
          end
          method = line.match(/^http (get|post)/i)[1].upcase
          line = line.split(/(?<!var):/i, 2)
          line = parse(host, line[1].strip)
          if method == "GET"
            url = line.strip
            uri = URI.parse(url)
            http = Net::HTTP.new(uri.host, uri.port)
            if url.start_with?("https")
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
            request = Net::HTTP::Get.new(uri.request_uri)
            response = http.request(request)
          elsif method == "POST"
            args = line.split(',')
            url = args.shift.strip
            options = {}
            args.each do |arg|
              arg = arg.split("=")
              options[arg[0].strip] = arg[1].strip
            end
            uri = URI.parse(url)
            # Create the HTTP objects
            http = Net::HTTP.new(uri.host, uri.port)
            if url.start_with?("https")
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
            request = Net::HTTP::Post.new(uri.request_uri)
            request.set_form_data(options)
            # Send the request
            response = http.request(request)
          end
          msg = "HTTP "+method+" "+url+": "+response.body
          NOTEX.synchronize do
            notification = Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
          end
        # /HTTP BLOCK

        # MONITOR BLOCK
        elsif line.start_with?("monitor")
          doit = true
          m = line.match(/^monitor if (.+)(?<!var):/i)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(/(?<!var):/i, 2)
            services = line[1].split(' ')
            services.each do |service|
              ret = host.monitor_service(service, task)
              if ret == 1
                NOTEX.synchronize do
                  msg = "Service "+service+" successfully monitored on "+host.hostname
                  notification = Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
                end
              end
            end
          end
        # /MONITOR BLOCK

        # UNMONITOR BLOCK
        elsif line.start_with?("unmonitor")
          doit = true
          m = line.match(/^unmonitor if (.+)(?<!var):/i)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(/(?<!var):/i, 2)
            services = line[1].split(' ')
            services.each do |service|
              ret = host.unmonitor_service(service, task)
              if ret == 1
                NOTEX.synchronize do
                  msg = "Service "+service+" now un-monitored on "+host.hostname
                  notification = Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
                end
              end
            end
          end
        # /UNMONITOR BLOCK

        # DEPLOY BLOCK
        elsif line.start_with?("deploy")
          doit = true
          m = line.match(/^deploy if (.+)(?<!var):/i)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(/(?<!var):/i, 2)
            deploys = line[1].split(' ')
            deploys.each do |deploy|
              ret = Deploy.launch(host, deploy, task)
              if ret == 1
                msg = "Deploy "+deploy+" successfully deployed on "+host.hostname
                NOTEX.synchronize do
                  notification = Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
                end
              elsif ret[0] == 5
                raise FormatException, ret[1]
              elsif ret[0] == 4
                raise ExecutionError, ret[1]
              end
            end
          end
        # /DEPLOY BLOCK

        # UNDEPLOY BLOCK
        elsif line.start_with?("undeploy")
          doit = true
          m = line.match(/^undeploy if (.+)(?<!var):/i)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(/(?<!var):/i, 2)
            deploys = line[1].split(' ')
            deploys.each do |deploy|
              ret = Deploy.undeploy(host, deploy, task)
              if ret == 1
                msg = "Deploy "+deploy+" undeployed from "+host.hostname
                NOTEX.synchronize do
                  notification = Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
                end
              elsif ret[0] == 5
                raise FormatException, ret[1]
              elsif ret[0] == 4
                raise ExecutionError, ret[1]
              end
            end
          end
        # /UNDEPLOY BLOCK

        # REBOOT BLOCK
        elsif line.start_with?("reboot")
          doit = true
          m = line.match(/^reboot if (.+)/)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            host.reboot
            msg = "Reboot "+host.hostname
            NOTEX.synchronize do
              notification = Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
            end
          end
        # /REBOOT BLOCK

        # undefined command
        else
          error = "Bad formatting, check your deploy file"
          raise FormatException, error
        end

        # Here we set the value itself of the var if varname is defined
        if !varname.nil?
          value = ret.strip #the output of exec goes in ret
          HOSTEX.synchronize do
            host.add_var(varname, value) #and we save the variable as a host variable
          end
          NOTEX.synchronize do
            msg = "Setting variable "+varname+" with value "+value
            notification = Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
          end
        end
      end
      return 1
    rescue FormatException => e
      return [5, e.message] # 5 == format exeption
    rescue ExecutionError => e
      return [4, e.message] # 4 == execution error
    end
  end

  # Install package or packages on defined host
  #
  def self.install(host, pkg, pkg_mgr = nil)
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
      #3. pacman
      elsif pkg_mgr == "pacman"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" -Sy --noconfirm --noprogressbar "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #4. zypper
      elsif pkg_mgr == "zypper"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" -q -n in "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #5.1. solaris pkgadd
      elsif pkg_mgr == "pkgadd"
        if host.user != "root"
          cmd = "sudo /usr/sbin/"+pkg_mgr
        else
          cmd = "/usr/sbin/"+pkg_mgr
        end
        cmd = cmd+" -a /etc/admin -d "+pkg+" all"    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #5.2. solaris pkg
      elsif pkg_mgr == "pkg"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" install --accept "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #5.3. solaris pkgutil
      elsif pkg_mgr == "pkgutil"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" -y -i "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #6. openbsd pkg_add
      elsif pkg_mgr == "pkg_add"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        pkg_path = 'export PKG_PATH="http://ftp.openbsd.org/pub/OpenBSD/'+host.dist_ver.to_s+'/packages/'+host.arch+'/"'
        cmd = pkg_path+" && "+cmd+" -U -I -x "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      end
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
  def self.uninstall(host, pkg, pkg_mgr = nil)
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
      #3. pacman
      elsif pkg_mgr == "pacman"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" -R --noconfirm --noprogressbar "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #4. zypper
      elsif pkg_mgr == "zypper"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" -q -n rm "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #5.1. solaris pkgadd
      elsif pkg_mgr == "pkgadd"
        if host.user != "root"
          cmd = "sudo /usr/sbin/pkgrm"
        else
          cmd = "/usr/sbin/pkgrm"
        end
        cmd = cmd+" -a /etc/admin "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #5.2. solaris pkg
      elsif pkg_mgr == "pkg"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" uninstall "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #5.3. solaris pkgutil
      elsif pkg_mgr == "pkgutil"
        if host.user != "root"
          cmd = "sudo "+pkg_mgr
        end
        cmd = cmd+" -y -r "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      #6. openbsd pkg_add
      elsif pkg_mgr == "pkg_add"
        cmd = "pkg_delete"
        if host.user != "root"
          cmd = "sudo "+cmd
        end
        cmd = cmd+" -I -x "+pkg    ## NOT FULLY TESTED, DEVELOPMENT IN PROGRESS
      end
      result = host.exec_cmd(cmd)
      if result.include? "\nE: "
        raise ExecutionError, result
      else
        result = result.split("\n").last
        return [1, result]
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

  # Parse a line (read the documentation for syntax reference)
  #
  # @param host [String] host to take the data from
  # @param line [String] line to be parsed
  # @return line [String] parsed line
  def self.parse(host, line)
    asyd = host.get_asyd_ip
    if !line.start_with?("#") #the line is a comment
      if line.match(/^<%MONITOR:.+%>/i)
        service = line.match(/^<%MONITOR:(.+)%>/i)[1]
        host.monitor_service(service)
        line = ""
      elsif line.match(/<%VAR:.+%>/i)
        vars = line.scan(/<%VAR:(.+?)%>/i)
        vars.each do |varname|
          varname = varname[0].strip
          if !host.opt_vars[varname].nil?
            line.gsub!(/<%VAR:#{varname}%>/i, host.opt_vars[varname])
          else
            host.hostgroups.each do |hostgroup|
              if !hostgroup.opt_vars[varname].nil?
                line.gsub!(/<%VAR:#{varname}%>/i, hostgroup.opt_vars[varname])
              end
            end
          end
        end
      else
        line.gsub!(/<%ASYD%>/i, asyd)
        line.gsub!(/<%MONIT_PW%>/i, host.monit_pw)
        line.gsub!(/<%IP%>/i, host.ip)
        line.gsub!(/<%DIST%>/i, host.dist)
        line.gsub!(/<%DIST_VER%>/i, host.dist_ver.to_s)
        line.gsub!(/<%ARCH%>/i, host.arch)
        line.gsub!(/<%HOSTNAME%>/i, host.hostname)
        line.gsub!(/<%PKG_MANAGER%>/i, host.pkg_mgr)
      end
    end
    return line
  end

  # Parse a config file (read the documentation for syntax reference)
  #
  # @param host [String] host to take the data from
  # @param cfg [String] config to be parsed
  # @return newconf [Object] temporal file with the parameters substituted by the values
  def self.parse_config(host, cfg)
    begin
      noparse = false
      condition = false
      doit = true
      skip = false
      newconf = Tempfile.new('conf')
      File.open(cfg, "r").each do |line|
        if !noparse
          if !condition
            m = line.strip.match(/^<% ?if (.+)%>$/)
            if !m.nil?
              doit = check_condition(m, host)
              condition = true
              skip = true
            end
          else
            if line.strip.match(/^<% ?endif ?%>$/)
              condition = false
              doit = true
              skip = true
            end
          end
        end
        if !noparse
          if line.strip.match(/^<% ?noparse ?%>$/)
            noparse = true
            skip = true
          end
        else
          if line.strip.match(/^<% ?\/noparse ?%>$/)
            noparse = false
            skip = true
          end
        end
        if doit && !skip
          line = parse(host, line) unless noparse
          newconf << line
        end
        skip = false
      end
    ensure
      newconf.close
    end
    return newconf
  end

  # Parse recursively an entire config directory
  #
  def self.parse_config_dir(host, cfg_dir, tmpath)
    if tmpath.nil?
      o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
      tmpath = (0...8).map { o[rand(o.length)] }.join
    end
    tempdir = "/tmp/"+tmpath+"/"

    dirs = Misc::get_dirs(cfg_dir)
    files = Misc::get_files(cfg_dir)
    FileUtils.mkdir_p(tempdir)
    files.each do |file|
      parsed_cfg = parse_config(host, cfg_dir+"/"+file)
      FileUtils.mv parsed_cfg.path, tempdir+file
    end
    dirs.each do |dir|
      parse_config_dir(host, cfg_dir+"/"+dir, tmpath+"/"+dir)
    end
    return tempdir
  end

  private

  # Validate deploy file
  # TODO: review and improve
  #
  def self.check_deploy(dep, sudo)
    begin
      error = nil
      cfg_root = "data/deploys/"+dep+"/configs/"
      if sudo
        path = "data/deploys/"+dep+"/def.sudo"
      else
        path = "data/deploys/"+dep+"/def"
      end
      f = File.open(path, "r").read
      f.gsub!(/\r\n?/, "\n")
      f.each_line do |line|
        if line.start_with?("#") || line.strip.empty?
          # Ignore comments
        elsif line.start_with?("install")
          l = line.split(':', 2)
          pkgs = l[1].strip
          if pkgs.include? "&" or pkgs.include? "|" or pkgs.include? ">" or pkgs.include? "<" or pkgs.include? "`" or pkgs.include? "$"
            error = "Invalid characters found: "+line.strip
            exit
          end
        elsif line.match(/^(noparse )?config file/)
          l = line.split(':', 2)
          cfg = l[1].split(',')
          cfg_src = cfg_root+cfg[0].strip
          cfg_dst = cfg[1].strip
          if cfg_src.nil? || cfg_dst.nil?
            error = "Argument missing on line: "+line.strip
            exit
          end
          unless File.exists?(cfg_src)
            error = "Local config file not found: "+cfg_src
            exit
          end
        elsif line.match(/^(noparse )?config dir/)
          l = line.split(':', 2)
          cfg = l[1].split(',')
          cfg_src = cfg_root+cfg[0].strip
          cfg_dst = cfg[1].strip
          if cfg_src.nil? || cfg_dst.nil?
            error = "Argument missing on line: "+line.strip
            exit
          end
          unless File.directory?(cfg_src)
            error = "Local config directory not found: "+cfg_src
            exit
          end
        elsif line.start_with?("exec")
          #just imply we actually WANT to execute the command
        elsif line.start_with?("monitor")
          line = line.split(':', 2)
          services = line[1].split(' ')
          services.each do |service|
            unless File.exists?("data/monitors/"+service)
              error = "Monitor file not found for service "+service
              exit
            end
          end
        else
          error = "Invalid line: "+line.strip
          exit
        end
      end
      return [1, "pass"] # 1 == all ok
    rescue SystemExit
      return [5, error] # 5 == format exeption
    end
  end

  # Checks conditionals on dep file
  #
  def self.check_condition(m, host)
    statements = Array.new
    i = 0
    conditions = m[1].split(' ')
    conditions.each do |cond|
      if cond == "and" || cond == "or"
        i += 1
        if statements[i].nil?
          statements[i] = cond
        else
          statements[i] << cond
        end
        i += 1
      else
        if statements[i].nil?
          statements[i] = cond
        else
          statements[i] << cond
        end
      end
    end
    comply = false
    comply_prev,comply_curr = false,false
    vand,vor = false,false
    statements.each do |st|
      if st == "and"
        vand = true
      elsif st == "or"
        vor = true
      else
        if vand
          ret = evaluate_condition(st, host)
          if ret
            comply_curr = true
          else
            comply_curr = false
          end
          if comply_prev && comply_curr
            comply = true
            comply_prev = comply_curr
          else
            comply = false
            comply_prev = false
          end
          vand = false
        elsif vor
          ret = evaluate_condition(st, host)
          if ret
            comply_curr = true
          else
            comply_curr = false
          end
          if comply_prev || comply_curr
            comply = true
            if comply_prev
              break
            else
              comply_prev = true
            end
          else
            comply,comply_prev = false,false
          end
          vor = false
        else
          ret = evaluate_condition(st, host)
          if ret
            comply,comply_prev,comply_curr = true,true,true
          end
        end
      end
    end
    return comply
  end

  # Evaluate conditional
  #
  def self.evaluate_condition(st, host)
    st = parse(host, st)

    condition = st.match(/(.+)(==|!=|>=|<=)(.+)/)
    case condition[2]
    when "=="
      if condition[1].nan? || condition[3].nan?
        if condition[1].downcase == condition[3].downcase
          return true
        else
          return false
        end
      else
        if condition[1].to_f == condition[3].to_f
          return true
        else
          return false
        end
      end
    when "!="
      if condition[1].nan? || condition[3].nan?
        if condition[1].downcase == condition[3].downcase
          return false
        else
          return true
        end
      else
        if condition[1].to_f == condition[3].to_f
          return false
        else
          return true
        end
      end
    when ">="
      if condition[1].to_f >= condition[3].to_f
        return true
      else
        return false
      end
    when "<="
      if condition[1].to_f <= condition[3].to_f
        return true
      else
        return false
      end
    else
      return false
    end
  end
end
