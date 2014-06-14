class SilentFormatException < StandardError
end

class FormatException < StandardError
end

class ExecutionError < StandardError
end

# Install package or packages on defined host
#
def install_pkg(host,pkg,dep)
  act_id = add_activity("Installing "+pkg, host) unless dep
  begin
    hostdata = get_host_data(host)
    ip = hostdata[:ip]
    pkg_mgr = hostdata[:pkg_mgr]

    if pkg.include? "&" or pkg.include? "|" or pkg.include? ">" or pkg.include? "<" or pkg.include? "`" or pkg.include? "$"
      exit
    end
    if pkg_mgr == "apt"
      cmd = pkg_mgr+"-get -y -q install "+pkg
    else
      cmd = pkg_mgr+" install -y "+pkg		## NOT TESTED, DEVELOPMENT IN PROGRESS
    end

    result = exec_cmd(ip, cmd)
    if result.include? "\nE: "
      result = result.split("\n")
      add_notification(0, result.last, act_id) unless dep
      update_activity(act_id, "failed") unless dep
      return [4, result] # 0 == error
    else
      result = result.split("\n")
      add_notification(2, result.last, act_id) unless dep
      update_activity(act_id, "completed") unless dep
      return [1, result] # 1 == all ok
    end
  rescue StandardError,SystemExit => e
    if e.inspect.include? "SystemExit"
      if dep
        error = "Invalid characters detected on package name: "+pkg
      else
        error = "Invalid characters detected on package name: "+pkg+" (task <a href='/tasks/"+act_id.to_s+"'>#"+act_id.to_s+"</a>)"
      end
    else
      if dep
        error = "Invalid characters detected on package name: "+pkg
      else
        error = "Something really bad happened when installing "+pkg+" on "+host+" (task <a href='/tasks/"+act_id.to_s+"'>#"+act_id.to_s+"</a>)"
      end
    end
    add_notification(0, error, act_id) unless dep
    update_activity(act_id, "failed") unless dep
    return [4, error] # 4 == execution error
  end
end

# Deploy a deploy on the defined host
#
def deploy(host,dep,group)
  act_id = add_activity("Deploying "+dep, host) unless group
  begin
    ret = check_deploy(dep)
    if ret[0] == 5
      p ret[1]
      raise FormatException, ret[1]
    end

    hostdata = get_host_data(host)
    ip = hostdata[:ip]

    cfg_root = "data/deploys/"+dep+"/configs/"
    path = "data/deploys/"+dep+"/def"
    f = File.open(path, "r").read
    f.gsub!(/\r\n?/, "\n")
    f.each_line do |line|
      if line.start_with?("#")
        # Ignore comments
      elsif line.start_with?("install")
        doit = true
        m = line.match(/^install if (.+):/)
        if !m.nil?
          doit = check_condition(m, host)
        end
        if doit
          line = line.split(':')
          pkgs = line[1].strip
          ret = install_pkg(host, pkgs, true)
          if ret[0] == 4
            raise ExecutionError, ret[1].last
          end
        end
      elsif line.start_with?("config file")
        doit = true
        m = line.match(/^config file if (.+):/)
        if !m.nil?
          doit = check_condition(m, host)
        end
        if doit
          line = line.split(':')
          cfg = line[1].split(',')
          cfg_src = cfg_root+cfg[0].strip
          parsed_cfg = parse_config(host, cfg_src)
          cfg_dst = cfg[1].strip
          upload_file(ip, parsed_cfg.path, cfg_dst)
          parsed_cfg.unlink
        end
      elsif line.start_with?("config dir")	## TODO: parse each config file in the directory
        doit = true
        m = line.match(/^config dir if (.+):/)
        if !m.nil?
          doit = check_condition(m, host)
        end
        if doit
          line = line.split(':')
          cfg = line[1].split(',')
          cfg_src = cfg_root+cfg[0].strip
          cfg_dst = cfg[1].strip
          upload_dir(ip, cfg_src, cfg_dst)
        end
      elsif line.start_with?("exec")
        doit = true
        m = line.match(/^exec if (.+):/)
        if !m.nil?
          doit = check_condition(m, host)
        end
        if doit
          line = line.split(':')
          cmd = line[1].strip
          exec_cmd(ip, cmd)
        end
      elsif line.start_with?("monitor")
        doit = true
        m = line.match(/^monitor if (.+):/)
        if !m.nil?
          doit = check_condition(m, host)
        end
        if doit
          line = line.split(':')
          services = line[1].split(' ')
          services.each do |service|
            monitor_service(ip, service)
          end
        end
      elsif line.start_with?("deploy")
          doit = true
          m = line.match(/^deploy if (.+):/)
          if !m.nil?
            doit = check_condition(m, host)
          end
          if doit
            line = line.split(':')
            deploys = line[1].split(' ')
            deploys.each do |deploy|
              ret = deploy(host,deploy,true)
              if ret[0] == 6
                raise SilentFormatException, ret[1]
              elsif ret[0] == 5
                raise FormatException, ret[1]
              elsif ret[0] == 4
                raise ExecutionError, ret[1]
              end
            end
          end
      else
        error = "Bad formatting, check your deploy file"
        raise SilentFormatException, error
      end
    end
    done = "Deploy "+dep+" successfully deployed on "+host
    add_notification(2, done, act_id) unless group
    update_activity(act_id, "completed") unless group
    return [1, done] # 1 == all ok

  rescue SilentFormatException => e
    error = "Bad formatting, check your deploy file (task <a href='/tasks/"+act_id.to_s+"'>#"+act_id.to_s+"</a>)"
    add_notification(0, error, act_id) unless group
    update_activity(act_id, "failed") unless group
    return [6, error] # 6 == format exeption without output
  rescue FormatException => e
    error = "Bad formatting, check your deploy file (task <a href='/tasks/"+act_id.to_s+"'>#"+act_id.to_s+"</a>)"
    add_notification(0, e.message, act_id) unless group
    add_notification(0, error, act_id) unless group
    update_activity(act_id, "failed") unless group
    return [5, e.message] # 5 == format exeption with output
  rescue ExecutionError => e
    error = e.message+" (task <a href='/tasks/"+act_id.to_s+"'>#"+act_id.to_s+"</a>)"
    add_notification(0, error, act_id) unless group
    update_activity(act_id, "failed") unless group
    return [4, e.message] # 4 == execution error
  end
end

# Deploy a deploy on defined hostgroup
#
def group_deploy(group, dep)
  act_id = add_activity("Deploying "+dep, group+" hostgroup")
  begin
    members = get_group_members(group)
    members.each do |host|
      ret = deploy(host,dep,true)
      if ret[0] == 6
        raise SilentFormatException, ret[1]
      elsif ret[0] == 5
        raise FormatException, ret[1]
      elsif ret[0] == 4
        raise ExecutionError, ret[1]
      end
    end
    done = "Deploy "+dep+" successfully deployed on "+group+" hostgroup"
    add_notification(2, done, act_id)
    update_activity(act_id, "completed")
  rescue SilentFormatException => e
    error = "Bad formatting, check your deploy file (task <a href='/tasks/"+act_id.to_s+"'>#"+act_id.to_s+"</a>)"
    add_notification(0, error, act_id)
    update_activity(act_id, "failed")
  rescue FormatException => e
    error = "Bad formatting, check your deploy file (task <a href='/tasks/"+act_id.to_s+"'>#"+act_id.to_s+"</a>)"
    add_notification(0, e.message, act_id)
    add_notification(0, error, act_id)
    update_activity(act_id, "failed")
  rescue ExecutionError => e
    error = e.message+" (task <a href='/tasks/"+act_id.to_s+"'>#"+act_id.to_s+"</a>)"
    add_notification(0, error, act_id)
    update_activity(act_id, "failed")
  end
end

# Validate deploy file
#
def check_deploy(dep)
  begin
    error = nil
    cfg_root = "data/deploys/"+dep+"/configs/"
    path = "data/deploys/"+dep+"/def"
    f = File.open(path, "r").read
    f.gsub!(/\r\n?/, "\n")
    f.each_line do |line|
      if line.start_with?("#")
        # Ignore comments
      elsif line.start_with?("install")
        l = line.split(':')
        pkgs = l[1].strip
        if pkgs.include? "&" or pkgs.include? "|" or pkgs.include? ">" or pkgs.include? "<" or pkgs.include? "`" or pkgs.include? "$"
          error = "Invalid characters found: "+line.strip
          exit
        end
      elsif line.start_with?("config file")
        l = line.split(':')
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
      elsif line.start_with?("config dir")
        l = line.split(':')
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
        # We imply we actually WANT to execute the command
      elsif line.start_with?("monitor")
        line = line.split(':')
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
    return [5, error] # 5 == format exeption with output
  end
end

# Checks conditionals on dep file
#
def check_condition(m, host)
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
        ret = evaluale_condition(st, host)
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
        ret = evaluale_condition(st, host)
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
        ret = evaluale_condition(st, host)
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
def evaluale_condition(st, host)
  hostdata = get_host_data(host)
  hostname = hostdata[:hostname]
  ip = hostdata[:ip]
  dist = hostdata[:dist_name]
  dist_ver = hostdata[:dist_ver]
  arch = hostdata[:arch]
  monit_pw = hostdata[:monit_pw]
  asyd = get_asyd_ip

  st.gsub!('<%ASYD%>', asyd)
  st.gsub!('<%MONIT_PW%>', monit_pw)
  st.gsub!('<%IP%>', ip)
  st.gsub!('<%DIST%>', dist)
  st.gsub!('<%DIST_VER%>', dist_ver)
  st.gsub!('<%ARCH%>', arch)
  st.gsub!('<%HOSTNAME%>', hostname)

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
