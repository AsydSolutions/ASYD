def install_pkg(host,pkg)
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
      $error = result.last
      return $error
    else
      result = result.split("\n")
      $done = result.last
      return $done
    end
  rescue StandardError,SystemExit => e
    if e.inspect.include? "SystemExit"
      $error = "Invalid characters detected"
    else
      $error = "Something really bad happened when installing packages"
    end
    return $error
  end
end

def deploy(host,dep)
  begin
    hostdata = get_host_data(host)
    ip = hostdata[:ip]
    
    cfg_root = "data/deploys/"+dep+"/configs/"
    path = "data/deploys/"+dep+"/def"
    f = File.open(path, "r").read
    f.gsub!(/\r\n?/, "\n")
    f.each_line do |line|
      if line.start_with?("install:")
        line = line.split(':')
        pkgs = line[1].strip
        install_pkg(host, pkgs)
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
  rescue SystemExit
    @error = 'Bad formatting, check your deploy file'
    return @error
  end
end
