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
      return [0, result] # 0 == error
    else
      result = result.split("\n")
      add_notification(2, result.last, act_id) unless dep
      update_activity(act_id, "completed") unless dep
      return [1, result] # 1 == all ok
    end
  rescue StandardError,SystemExit => e
    if e.inspect.include? "SystemExit"
      error = "Invalid characters detected on package name: "+pkg+" (task <a href='/tasks/"+act_id.to_s+"'>#"+act_id.to_s+"</a>)"
    else
      error = "Something really bad happened when installing "+pkg+" on "+host+" (task <a href='/tasks/"+act_id.to_s+"'>#"+act_id.to_s+"</a>)"
    end
    add_notification(0, error, act_id) unless dep
    update_activity(act_id, "failed") unless dep
    return [0, error] # 0 == error
  end
end

def deploy(host,dep,group)
  act_id = add_activity("Deploying "+dep, host) unless group
  begin
    unless group
      ret = check_deploy(dep)
      if ret[0] == 0
        add_notification(0, ret[1], act_id)
        update_activity(act_id, "failed")
        exit
      end
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
      elsif line.start_with?("install:")
        line = line.split(':')
        pkgs = line[1].strip
        ret = install_pkg(host, pkgs, true)
        if ret[0] == 0
          raise ret[1]
        end
      elsif line.start_with?("config file:")
        line = line.split(':')
        cfg = line[1].split(',')
        cfg_src = cfg_root+cfg[0].strip
        parsed_cfg = parse_config(host, cfg_src)
        cfg_dst = cfg[1].strip
        upload_file(ip, parsed_cfg.path, cfg_dst)
        parsed_cfg.unlink
      elsif line.start_with?("config dir:")	## TODO: parse each config file in the directory
        line = line.split(':')
        cfg = line[1].split(',')
        cfg_src = cfg_root+cfg[0].strip
        cfg_dst = cfg[1].strip
        upload_dir(ip, cfg_src, cfg_dst)
      elsif line.start_with?("exec:")
        line = line.split(':')
        cmd = line[1].strip
        exec_cmd(ip, cmd)
      elsif line.start_with?("monitor:")
        line = line.split(':')
        services = line[1].split(' ')
        services.each do |service|
          monitor_service(ip, service)
        end
      else
        exit
      end
    end
    done = "Deploy "+dep+" successfully deployed on "+host
    add_notification(2, done, act_id) unless group
    update_activity(act_id, "completed") unless group
    return [1, done] # 1 == all ok
  rescue SystemExit,Exception => e
    if e.inspect.include? "SystemExit"
      error = "Bad formatting, check your deploy file (task <a href='/tasks/"+act_id.to_s+"'>#"+act_id.to_s+"</a>)"
      add_notification(0, error, act_id) unless group
      update_activity(act_id, "failed") unless group
      return [5, error] # 5 == error without output
    else
      error = e.message
      return [0, error] # 0 == error
    end
  end
end

def group_deploy(group, dep)
  act_id = add_activity("Deploying "+dep, group+" hostgroup")
  begin
    ret = check_deploy(dep)
    if ret[0] == 0
      add_notification(0, ret[1], act_id)
      update_activity(act_id, "failed")
      exit
    end
    members = get_group_members(group)
    members.each do |host|
      ret = deploy(host,dep,true)
      if ret[0] == 0
        exit
      end
    end
  rescue SystemExit,Exception => e
    if e.inspect.include? "SystemExit"
      error = "Bad formatting, check your deploy file (task <a href='/tasks/"+act_id.to_s+"'>#"+act_id.to_s+"</a>)"
    else
      error = e.message
    end
    add_notification(0, error, act_id)
    update_activity(act_id, "failed")
  end
end

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
      elsif line.start_with?("install:")
        l = line.split(':')
        pkgs = l[1].strip
        if pkgs.include? "&" or pkg.include? "|" or pkg.include? ">" or pkg.include? "<" or pkg.include? "`" or pkg.include? "$"
          error = "Invalid characters found: "+line.strip
          exit
        end
      elsif line.start_with?("config file:")
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
      elsif line.start_with?("config dir:")
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
      elsif line.start_with?("exec:")
        # We imply we actually WANT to execute the command
      elsif line.start_with?("monitor:")
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
    return [0, error] # 0 == error
  end
end
