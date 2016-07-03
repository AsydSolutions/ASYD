class Host

  def add_var(name, value)
    if self.opt_vars.nil?
      self.opt_vars = {}
      self.save
    end
    self.update(:opt_vars => opt_vars.merge(name => value))
    return true #all ok
  end

  def del_var(name)
    if self.opt_vars[name].nil?
      return false #error = varname doesn't exists
    end
    self.update(:opt_vars => opt_vars.except(name))
    return true #all ok
  end

  def delete(revoke)
    if revoke == true
      ssh_key = File.open("data/ssh_key.pub", "r").read.strip
      cmd1 = '/bin/grep -v "'+ssh_key+'" /root/.ssh/authorized_keys > /tmp/auth_keys'
      cmd2 = 'mv /tmp/auth_keys /root/.ssh/authorized_keys'
      exec_cmd(cmd1)
      exec_cmd(cmd2)
    end
    self.hostgroup_members.all.destroy
    reload

    # remove the server from the statistics
    t_hosts = HostStats.last.total_hosts
    stat = HostStats.first(:created_at => DateTime.now.beginning_of_day)
    if !stat
      HostStats.create(:created_at => DateTime.now.beginning_of_day, :total_hosts => t_hosts-1)
    else
      stat.total_hosts = stat.total_hosts - 1
      stat.save
    end

    return self.destroy
  end

end
