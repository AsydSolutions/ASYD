class Deploy
  include Misc

  # Deploy a deploy on the defined host
  #
  def self.launch(host, dep, task)
    begin
      ret = check_deploy(dep)
      if ret[0] == 5
        raise FormatException, ret[1]
      end

      if host.nil?
        error = "host not found"
        raise ExecutionError, error
      end

      cfg_root = "data/deploys/"+dep+"/configs/"
      path = "data/deploys/"+dep+"/def"
      f = File.open(path, "r").read
      f.gsub!(/\r\n?/, "\n")
      f.each_line do |line|
        # COMMENT
        if line.start_with?("#") || line.strip.empty?
          # Ignore comments and empty lines
        # INSTALL BLOCK
        elsif line.start_with?("install")
          doit = true
          m = line.match(/^install if (.+):/)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(':', 2)
            pkgs = line[1].strip
            ret = Deploy.install(host, pkgs)
            if ret[0] == 1
              msg = "Installed "+pkgs+" on "+host.hostname+": "+ret[1]
              NOTEX.synchronize do
                notification = Notification.create(:type => :info, :dismiss => true, :message => msg, :task => task)
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
          m = line.match(/^uninstall if (.+):/)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(':', 2)
            pkgs = line[1].strip
            ret = Deploy.uninstall(host, pkgs)
            if ret[0] == 1
              msg = "Removed "+pkgs+" from "+host.hostname+": "+ret[1]
              NOTEX.synchronize do
                notification = Notification.create(:type => :info, :dismiss => true, :message => msg, :task => task)
              end
            elsif ret[0] == 4
              raise ExecutionError, ret[1]
            elsif ret[0] == 5
              raise FormatException, ret[1]
            end
          end
        # /UNINSTALL BLOCK
        # CONFIG FILE BLOCK
        elsif line.match(/^(noparse )?config file/)
          noparse = false
          if line.start_with?("noparse")
            noparse = true
          end
          doit = true
          m = line.match(/config file if (.+):/)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(':', 2)
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
              notification = Notification.create(:type => :info, :dismiss => true, :message => msg, :task => task)
            end
          end
        # /CONFIG FILE BLOCK
        # CONFIG DIR BLOCK
        elsif line.match(/^(noparse )?config dir/)
          noparse = false
          if line.start_with?("noparse")
            noparse = true
          end
          doit = true
          m = line.match(/config dir if (.+):/)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(':', 2)
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
              notification = Notification.create(:type => :info, :dismiss => true, :message => msg, :task => task)
            end
          end
        # /CONFIG DIR BLOCK
        # EXEC BLOCK
        elsif line.start_with?("exec")
          doit = true
          m = line.match(/^exec (.[^:]+)/)
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
                # if complies then execute the command on remote host
                if doit
                  line = line.split(':', 2)
                  cmd = parse(host, line[1].strip) #parse for vars
                  ret = other_host.exec_cmd(cmd)
                  msg = "Executed '"+cmd+"' on "+other_host.hostname
                  msg = msg+": "+ret unless ret.nil?
                  NOTEX.synchronize do
                    notification = Notification.create(:type => :info, :dismiss => true, :message => msg, :task => task)
                  end
                end
              else
                doit = check_condition(m2, host)
                if doit
                  line = line.split(':', 2)
                  cmd = parse(host, line[1].strip) #parse for vars
                  ret = host.exec_cmd(cmd)
                  msg = "Executed '"+cmd+"' on "+host.hostname
                  msg = msg+": "+ret unless ret.nil?
                  NOTEX.synchronize do
                    notification = Notification.create(:type => :info, :dismiss => true, :message => msg, :task => task)
                  end
                end
              end
            elsif !m2[0].nil? #no conditionals but remote execution
              other_host = Host.first(:hostname => m2[0].strip)
              if other_host.nil?  #the defined host doesn't exists
                error = "Host "+m2[0].strip+" not found"
                raise FormatException, error
              end
              if doit
                line = line.split(':', 2)
                cmd = parse(host, line[1].strip) #parse for vars
                ret = other_host.exec_cmd(cmd)
                msg = "Executed '"+cmd+"' on "+other_host.hostname
                msg = msg+": "+ret unless ret.nil?
                NOTEX.synchronize do
                  notification = Notification.create(:type => :info, :dismiss => true, :message => msg, :task => task)
                end
              end
            end
          else #just act normally, no params
            if doit
              line = line.split(':', 2)
              cmd = parse(host, line[1].strip) #parse for vars
              ret = host.exec_cmd(cmd)
              msg = "Executed '"+cmd+"' on "+host.hostname
              msg = msg+": "+ret unless ret.nil?
              NOTEX.synchronize do
                notification = Notification.create(:type => :info, :dismiss => true, :message => msg, :task => task)
              end
            end
          end
        # /EXEC BLOCK
        # MONITOR BLOCK
        elsif line.start_with?("monitor")
          doit = true
          m = line.match(/^monitor if (.+):/)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(':', 2)
            services = line[1].split(' ')
            services.each do |service|
              host.monitor_service(service)
              msg = "Monitoring service "+service+" on "+host.hostname
              NOTEX.synchronize do
                notification = Notification.create(:type => :info, :dismiss => true, :message => msg, :task => task)
              end
            end
          end
        # /MONITOR BLOCK
        # DEPLOY BLOCK
        elsif line.start_with?("deploy")
            doit = true
            m = line.match(/^deploy if (.+):/)
            if !m.nil?
              doit = check_condition(m, host)
            end
            if doit
              line = line.split(':', 2)
              deploys = line[1].split(' ')
              deploys.each do |deploy|
                ret = Deploy.launch(host, deploy, task)
                if ret == 1
                  msg = "Deploy "+deploy+" successfully deployed on "+host.hostname
                  NOTEX.synchronize do
                    notification = Notification.create(:type => :info, :dismiss => true, :message => msg, :task => task)
                  end
                elsif ret[0] == 5
                  raise FormatException, ret[1]
                elsif ret[0] == 4
                  raise ExecutionError, ret[1]
                end
              end
            end
        # /DEPLOY BLOCK
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
                notification = Notification.create(:type => :info, :dismiss => true, :message => msg, :task => task)
              end
            end
        # /REBOOT BLOCK
        # undefined command
        else
          error = "Bad formatting, check your deploy file"
          raise FormatException, error
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
  def self.install(host, pkg)
    begin
      if pkg.include? "&" or pkg.include? "|" or pkg.include? ">" or pkg.include? "<" or pkg.include? "`" or pkg.include? "$"
        raise FormatException
      end
      pkg_mgr = host.pkg_mgr
      if host.user != "root"
        pkg_mgr = "sudo "+pkg_mgr
      end
      if pkg_mgr == "apt"
        cmd = pkg_mgr+"-get update && "+pkg_mgr+"-get -y -q install "+pkg
      elsif pkg_mgr == "yum"
        cmd = pkg_mgr+" install -y "+pkg		## NOT TESTED, DEVELOPMENT IN PROGRESS
      elsif pkg_mgr == "pacman"
        cmd = pkg_mgr+" -Sy --noconfirm --noprogressbar "+pkg    ## NOT TESTED, DEVELOPMENT IN PROGRESS
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
      error = e.message.split("\n")
      return [4, error.last]
    rescue
      error = "Something really bad happened when installing "+pkg+" on "+host.hostname
      return [4, error]
    end
  end

  # Uninstall package or packages on defined host
  #
  def self.uninstall(host, pkg)
    begin
      if pkg.include? "&" or pkg.include? "|" or pkg.include? ">" or pkg.include? "<" or pkg.include? "`" or pkg.include? "$"
        raise FormatException
      end
      pkg_mgr = host.pkg_mgr
      if pkg_mgr == "apt"
        cmd = pkg_mgr+"-get -y -q remove "+pkg
      elsif pkg_mgr == "yum"
        cmd = pkg_mgr+" remove -y "+pkg		## NOT TESTED, DEVELOPMENT IN PROGRESS
      elsif pkg_mgr == "pacman"
        cmd = pkg_mgr+" -R --noconfirm --noprogressbar "+pkg    ## NOT TESTED, DEVELOPMENT IN PROGRESS
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
      error = e.message.split("\n")
      return [4, error.last]
    rescue
      error = "Something really bad happened when uninstalling "+pkg+" on "+host.hostname
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
        varname = line.match(/<%VAR:(.+)%>/i)[1]
        if !host.opt_vars[varname].nil?
          line.gsub!(/<%VAR:.+%>/i, host.opt_vars[varname])
        else
          host.hostgroups.each do |hostgroup|
            if !hostgroup.opt_vars[varname].nil?
              line.gsub!(/<%VAR:.+%>/i, hostgroup.opt_vars[varname])
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
            m = line.match(/^<%if (.+)%>$/)
            if !m.nil?
              doit = check_condition(m, host)
              condition = true
              skip = true
            end
          else
            if line.match(/^<%endif%>$/)
              condition = false
              doit = true
              skip = true
            end
          end
        end
        if !noparse
          if line.match(/^<%noparse%>$/)
            noparse = true
            skip = true
          end
        else
          if line.match(/^<%\/noparse%>$/)
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

  # Delete a deploy
  #
  def self.delete(dep)
    path='data/deploys/'+dep
    FileUtils.rm_r path, :secure=>true
  end

  def self.all
    all = Misc::get_dirs("data/deploys/")
    return all
  end

  private

  # Validate deploy file
  #
  def self.check_deploy(dep)
    begin
      error = nil
      cfg_root = "data/deploys/"+dep+"/configs/"
      path = "data/deploys/"+dep+"/def"
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
            unless File.exists?("data/monitors/modules/"+service)
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
            comply_prev = comply_curr
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
  # TODO: evaluate custom vars
  #
  def self.evaluate_condition(st, host)
    st = parse(host, st)

    condition = st.match(/(.+)(==|!=|>=|<=)(.+)/)
    case condition[2]
    when "=="
      if condition[1].nan? && condition[3].nan?
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
      if condition[1].nan? && condition[3].nan?
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
