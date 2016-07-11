class Deploy
  include Misc

  # Return a list of deploys
  #
  def self.all
    deploys = Misc::get_dirs("data/deploys/").sort_by{|entry| entry.downcase}
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
    if File.exist?("data/deploys/"+dep+"/undeploy")
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
  def self.launch(host, dep, task, dry_run = false, from_deploy = false)
    begin
      if host.nil?
        error = "Error: host not found"
        raise ExecutionError, error
      end
      if host.ssh.nil? or host.ssh.closed?
        raise TargetUnreachable, "Error: host "+host.hostname+" unreachable" if !Misc::is_port_open?(host.ip, host.ssh_port, pingback=true, ssh=true)
      end

      cfg_root = "data/deploys/"+dep+"/configs/"
      if host.user != "root" && File.exist?("data/deploys/"+dep+"/def.sudo")
        path = "data/deploys/"+dep+"/def.sudo"
      else
        path = "data/deploys/"+dep+"/def"
      end

      host.ssh = Net::SSH.start(host.ip, host.user, :port => host.ssh_port, :keys => "data/ssh_key", :timeout => 30, :user_known_hosts_file => "/dev/null", :compression => true) if host.ssh.nil? or host.ssh.closed?

      # Check deploy (dry run)
      unless from_deploy and !dry_run # check only once when calling from deploy
        ret = Deploy.deploy(host, path, cfg_root, task, true)
        if ret[0] == 5
          raise FormatException, ret[1]
        elsif ret[0] == 4
          raise ExecutionError, ret[1]
        end
      end

      ret = Deploy.deploy(host, path, cfg_root, task, false) unless dry_run
      return ret
    rescue ExecutionError => e
      return [4, e.message] # 4 == execution error
    rescue FormatException => e
      return [5, e.message] # 5 == format exception
    rescue TargetUnreachable => e
      return [6, e.message] # 6 == host unreachable
    ensure
      host.ssh.close unless dry_run or from_deploy or host.ssh.nil? or host.ssh.closed?
    end
  end

  # Undeploy a given deploy on the defined host
  #
  def self.undeploy(host, dep, task, dry_run = false, from_deploy = false)
    begin
      if host.nil?
        error = "Error: host not found"
        raise ExecutionError, error
      end
      if host.ssh.nil? or host.ssh.closed?
        raise TargetUnreachable, "Error: host "+host.hostname+" unreachable" if !Misc::is_port_open?(host.ip, host.ssh_port, pingback=true, ssh=true)
      end

      cfg_root = "data/deploys/"+dep+"/configs/"
      if host.user != "root" && File.exist?("data/deploys/"+dep+"/undeploy.sudo")
        path = "data/deploys/"+dep+"/undeploy.sudo"
      else
        path = "data/deploys/"+dep+"/undeploy"
      end

      host.ssh = Net::SSH.start(host.ip, host.user, :port => host.ssh_port, :keys => "data/ssh_key", :timeout => 30, :user_known_hosts_file => "/dev/null", :compression => true) if host.ssh.nil? or host.ssh.closed?

      # Check deploy (dry run)
      unless from_deploy and !dry_run # check only once when calling from deploy
        ret = Deploy.deploy(host, path, cfg_root, task, true)
        if ret[0] == 5
          raise FormatException, ret[1]
        elsif ret[0] == 4
          raise ExecutionError, ret[1]
        end
      end

      ret = Deploy.deploy(host, path, cfg_root, task, false) unless dry_run
      return ret
    rescue ExecutionError => e
      return [4, e.message] # 4 == execution error
    rescue FormatException => e
      return [5, e.message] # 5 == format exception
    rescue TargetUnreachable => e
      return [6, e.message] # 6 == host unreachable
    ensure
      host.ssh.close unless dry_run or from_deploy or host.ssh.nil? or host.ssh.closed?
    end
  end
  
end
