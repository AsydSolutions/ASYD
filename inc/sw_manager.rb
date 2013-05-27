def install_pkg(host,pkg)
  begin
    path = "data/servers/"+host+"/srv.info"
    f = File.open(path, "r")
    host = f.gets.strip
    dist_name = f.gets.strip
    dist_ver  = f.gets.strip
    pkg_mgr = f.gets.strip
    f.close

    if pkg.include? "&" or pkg.include? "|" or pkg.include? ">" or pkg.include? "<" or pkg.include? "`" or pkg.include? "$"
      exit
    end
    if pkg_mgr == "apt"
      cmd = pkg_mgr+"-get -y -q install "+pkg
    end

    result = exec_cmd(host,cmd)
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
    path = "data/deploys/"+dep+"/def"
    f = File.open(path, "r").read
    f.gsub!(/\r\n?/, "\n")
    f.each_line do |line|
      if line.start_with?("install:")
        line = line.split(':')
        pkgs = line[1].strip

        p "Installing: "+pkgs
      elsif line.start_with?("config file:")
        line = line.split(':')
        cfg = line[1].split(',')
        cfg_src = "configs/"+cfg[0].strip
        cfg_dst = cfg[1].strip

        p "Set up config file "+cfg_src+" as "+cfg_dst
      elsif line.start_with?("config dir:")
        line = line.split(':')
        cfg = line[1].split(',')
        cfg_src = "configs/"+cfg[0].strip
        cfg_dst = cfg[1].strip

        p "Set up config directory "+cfg_src+" as "+cfg_dst
      elsif line.start_with?("exec:")
        line = line.split(':')
        cmd = line[1].strip

        p "Exec "+cmd
      else
        exit
      end
    end
  rescue SystemExit
    @error = 'Bad formatting, check your deploy file'
    return @error
  end
end
