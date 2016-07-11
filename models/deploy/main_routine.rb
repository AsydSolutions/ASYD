class Deploy
  include Misc

  # Deploys the file in "path" (def, def.sudo, undeploy or undeploy.sudo)
  #
  def self.deploy(host, path, cfg_root, task, dry_run)
    begin
      level_if = 0
      level_nodoit = 0
      level_for = 0
      @for_loop = {}
      gdoit = true #global doit, used for conditional blocks
      skip = false
      line_nr = 0

      f = IO.readlines(path)
      total_lines = f.count
      while line_nr < total_lines do
        line = f[line_nr].strip

        # Check for deploy "for" (foreach) loops
        m = line.match(/^for (.+) in (.+)$/i)
        if !m.nil?
          # ignore for loop if you are on a nodoit
          if gdoit
            new_varname = m[1].strip
            search_key = m[2].strip
            level_for = level_for + 1
            @for_loop[level_for] = {}
            @for_loop[level_for][:line] = line_nr
            @for_loop[level_for][:vars] = parse_var_array(host, search_key, new_varname)
          end
          skip = true
        end
        # check for endfors
        if line.match(/^endfor$/i)
          @for_loop[level_for][:vars].shift if @for_loop[level_for][:vars].length > 0 #consume first element after reaching endfor
          if @for_loop[level_for][:vars].length > 0
            line_nr = @for_loop[level_for][:line]
          else
            level_for = level_for - 1
          end
          skip = true
        end

        # Check for deploy global conditionals
        m = line.match(/^if (.+)$/i)
        if !m.nil?
          # ignore conditions if you are on a nodoit
          if gdoit
            gdoit = check_condition(m, host)
            level_nodoit = level_if unless gdoit
          end
          level_if = level_if + 1
          skip = true
        end
        # check for endifs
        if line.match(/^endif$/i)
          level_if = level_if - 1
          if level_nodoit == level_if
            gdoit = true
          end
          skip = true
        end

        # Set variables from a Deploy
        if gdoit && m = line.match(/^var ([^\s]+) = (exec|http)/i)
          varname = m[1] #we create varname here
          line = line.split(/ = /, 2)[1].strip #and remove the start of the line so we have only the exec or http part
        end

        # Set variables from json from a Deploy
        if gdoit && m = line.match(/^var from json = (exec|http)/i)
          json_vars = true #we will handle it later
          line = line.split(/ = /, 2)[1].strip #and remove the start of the line so we have only the exec or http part
        end

        # Set variables from XML from a Deploy
        if gdoit && m = line.match(/^var from xml = (exec|http)/i)
          xml_vars = true #we will handle it later
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
            if pkgs.include? "&" or pkgs.include? "|" or pkgs.include? ">" or pkgs.include? "<" or pkgs.include? "`" or pkgs.include? "$"
              error = "Invalid characters detected on package name: "+pkgs
              raise FormatException, error
            end
            ret = Deploy.install(host, pkgs, dry_run, pkg_mgr)
            if ret[0] == 1
              msg = "Installed "+pkgs+" on "+host.hostname+": "+ret[1]
              NOTEX.synchronize do
                Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
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
          pkg_mgr = line.match(/^install (pkgutil|pkg|pkgadd)?(?: if .+)?(?<!var):/i) ? line.match(/^install (pkgutil|pkg|pkgadd)?(?: if .+)?(?<!var):/i) : nil
          m = line.match(/^uninstall if (.+)(?<!var):/i)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(/(?<!var):/i, 2)
            pkgs = line[1].strip
            if pkgs.include? "&" or pkgs.include? "|" or pkgs.include? ">" or pkgs.include? "<" or pkgs.include? "`" or pkgs.include? "$"
              error = "Invalid characters detected on package name: "+pkgs
              raise FormatException, error
            end
            ret = Deploy.uninstall(host, pkgs, dry_run, pkg_mgr)
            if ret[0] == 1
              msg = "Removed "+pkgs+" from "+host.hostname+": "+ret[1]
              NOTEX.synchronize do
                Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
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
            unless dry_run
              if noparse
                ret = host.upload_file(cfg_src, cfg_dst, cfg_src)
              else
                ret = host.upload_file(parsed_cfg.path, cfg_dst, cfg_src)
              end
              raise ExecutionError, ret[1] if ret.kind_of?(Array) and ret[0] == 4
            end
            parsed_cfg.unlink unless noparse
            unless dry_run
              msg = "Uploaded "+cfg_src+" to "+cfg_dst+" on "+host.hostname
              NOTEX.synchronize do
                Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
              end
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
            unless dry_run
              if noparse
                ret = host.upload_dir(cfg_src, cfg_dst, cfg_src)
              else
                ret = host.upload_dir(parsed_cfg, cfg_dst, cfg_src)
              end
              raise ExecutionError, ret[1] if ret.kind_of?(Array) and ret[0] == 4
            end
            FileUtils.rm_r parsed_cfg, :secure=>true unless noparse
            unless dry_run
              msg = "Uploaded "+cfg_src+" to "+cfg_dst+" on "+host.hostname
              NOTEX.synchronize do
                Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
              end
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
            unless dry_run
              ret = exec_host.exec_cmd(cmd)
              raise ExecutionError, ret[1] if ret.kind_of?(Array) and ret[0] == 4
              msg = "Executed '"+cmd+"' on "+exec_host.hostname
              msg = msg+": "+ret unless ret.nil?
              NOTEX.synchronize do
                Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
              end
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
          if doit
            if method == "GET"
              url = line.strip
              uri = URI.parse(url)
              http = Net::HTTP.new(uri.host, uri.port)
              if url.start_with?("https")
                http.use_ssl = true
                http.verify_mode = OpenSSL::SSL::VERIFY_NONE
              end
              request = Net::HTTP::Get.new(uri.request_uri)
              unless dry_run
                response = http.request(request)
              end
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
              unless dry_run
                response = http.request(request)
              end
            end
            unless dry_run
              ret = response.body
              msg = "HTTP "+method+" "+url+": "+response.body
              NOTEX.synchronize do
                Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
              end
            end
          end
        # /HTTP BLOCK

        # SERVICE BLOCK
        elsif line.match(/^(enable|disable|start|stop|restart) service/i)
          doit = true
          m = line.match(/if (.+)(?<!var):/i)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            action = line.match(/^(enable|disable|start|stop|restart) service/i)[1].downcase
            line = line.split(/(?<!var):/i, 2)
            services = line[1].strip
            ret = Deploy.manage_service(host, action, services, dry_run)
            if ret[0] == 1
              msg = action+"'d services "+services+" on "+host.hostname+": "+ret[1]
              NOTEX.synchronize do
                Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
              end
            elsif ret[0] == 4
              raise ExecutionError, ret[1]
            elsif ret[0] == 5
              raise FormatException, ret[1]
            end
          end
        # /SERVICE BLOCK

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
              ret = dry_run ? 0 : host.monitor_service(service, task)
              if ret == 1
                NOTEX.synchronize do
                  msg = "Service "+service+" successfully monitored on "+host.hostname
                  Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
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
              ret = dry_run ? 0 : host.unmonitor_service(service, task)
              if ret == 1
                NOTEX.synchronize do
                  msg = "Service "+service+" now un-monitored on "+host.hostname
                  Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
                end
              end
            end
          end
        # /UNMONITOR BLOCK

        # DEPLOY BLOCK
        elsif line.start_with?("deploy")
          doit = true
          dep_host = host
          m = line.match(/^deploy.* if (.+)(?<!var):/i)
          if !m.nil?
            dep_host = Host.first(:hostname => line.match(/^deploy (.+) if/i)[1].strip) if line.match(/^deploy (.+) if/i)
            if dep_host.nil?  #the defined host doesn't exists
              error = "Host "+line.match(/^deploy (.+) if/i)[1].strip+" not found"
              raise FormatException, error
            end
            doit = check_condition(m, dep_host)
          else
            dep_host = Host.first(:hostname => line.match(/^deploy (.+):/i)[1].strip) if line.match(/^deploy (.+):/i)
            if dep_host.nil?  #the defined host doesn't exists
              error = "Host "+line.match(/^deploy (.+):/i)[1].strip+" not found"
              raise FormatException, error
            end
          end
          if doit
            line = line.split(/(?<!var):/i, 2)
            deploys = line[1].split(' ')
            deploys.each do |deploy|
              ret = Deploy.launch(dep_host, deploy, task, dry_run, true)
              if ret == 1 and !dry_run
                msg = "Deploy "+deploy+" successfully deployed on "+dep_host.hostname
                NOTEX.synchronize do
                  Notification.create(:type => :info, :dismiss => true, :host => dep_host.hostname, :message => msg, :task => task)
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
          dep_host = host
          m = line.match(/^undeploy.* if (.+)(?<!var):/i)
          if !m.nil?
            dep_host = Host.first(:hostname => line.match(/^undeploy (.+) if/i)[1].strip) if line.match(/^undeploy (.+) if/i)
            if dep_host.nil?  #the defined host doesn't exists
              error = "Host "+line.match(/^undeploy (.+) if/i)[1].strip+" not found"
              raise FormatException, error
            end
            doit = check_condition(m, dep_host)
          else
            dep_host = Host.first(:hostname => line.match(/^undeploy (.+):/i)[1].strip) if line.match(/^undeploy (.+):/i)
            if dep_host.nil?  #the defined host doesn't exists
              error = "Host "+line.match(/^undeploy (.+):/i)[1].strip+" not found"
              raise FormatException, error
            end
          end
          if doit
            line = line.split(/(?<!var):/i, 2)
            deploys = line[1].split(' ')
            deploys.each do |deploy|
              ret = Deploy.undeploy(dep_host, deploy, task, dry_run, true)
              if ret == 1 and !dry_run
                msg = "Deploy "+deploy+" undeployed from "+dep_host.hostname
                NOTEX.synchronize do
                  Notification.create(:type => :info, :dismiss => true, :host => dep_host.hostname, :message => msg, :task => task)
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
            unless dry_run
              host.reboot
              msg = "Reboot "+host.hostname
              NOTEX.synchronize do
                Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
              end
            end
          end
        # /REBOOT BLOCK

        # undefined command
        else
          error = "Bad formatting, check your deploy file: "+line
          raise FormatException, error
        end

        # Here we set the value itself of the var if varname is defined
        if !varname.nil? and !dry_run
          value = ret.strip #the output of exec goes in ret
          HOSTEX.synchronize do
            host.add_var(varname, value) #and we save the variable as a host variable
          end
          NOTEX.synchronize do
            msg = "Setting variable "+varname+" with value "+value
            Notification.create(:type => :info, :dismiss => true, :host => host.hostname, :message => msg, :task => task)
          end
        end

        # Also for json variables
        if json_vars == true and !dry_run
          vars = JSON.parse(ret.strip) #the output of exec goes in ret
          host.hash_to_host_vars(vars, task)
        end

        # And XML
        if xml_vars == true and !dry_run
          vars = Hash.from_xml(ret.strip) #the output of exec goes in ret
          host.hash_to_host_vars(vars, task)
        end

        #Increase line_nr to read next line
        line_nr = line_nr + 1
      end
      return 1
    rescue FormatException => e
      return [5, e.message+" (line #{line_nr+1})"] # 5 == format exeption
    rescue ExecutionError => e
      return [4, e.message+" (line #{line_nr+1})"] # 4 == execution error
    rescue => e
      return [4, e.message+" (line #{line_nr+1})"] # unknown errors are handled as execution error
    end # Line numbers are incremembed by one to reflect the ACTUAL line number and not the array position
  end

end
