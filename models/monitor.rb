module Monitoring
  module Host
    include Misc

    TTL = 15 #store the status for 15 seconds

    def monitor
      Deploy.install(self, "monit")
      parsed_cfg = Deploy.parse_config(self, "data/monitors/monitrc")
      upload_file(parsed_cfg.path, "/etc/monit/monitrc")
      parsed_cfg.unlink
      exec_cmd('echo "startup=1" > /etc/default/monit')
      exec_cmd('service monit restart')
    end

    def monitor_service(service)
      begin
        parsed_cfg = Deploy.parse_config(self, "data/monitors/modules/"+service)
        upload_file(parsed_cfg.path, "/etc/monit/conf.d/"+service)
        parsed_cfg.unlink
        exec_cmd("service monit restart")
      end
    end

    def get_status
      if !self.status.nil?
        if ((DateTime.now - status.created_at)  * 24 * 60 * 60).to_i > TTL
          status.destroy
          stat = Status.new(self)
          if stat.id.nil?
            error = "Unable to get monitoring status for host "+self.hostname
            Notification.create(:type => :error, :message => error)
            self.status = nil
          else
            self.status = stat
          end
          return self.status
        else
          return self.status
        end
      else
        stat = Status.new(self)
        if stat.id.nil?
          error = "Unable to get monitoring status for host "+self.hostname
          Notification.create(:type => :error, :message => error)
          self.status = nil
        else
          self.status = stat
        end
        return self.status
      end
    end

    def is_ok?
      status = get_status
      if status.nil?
        return 3
      else
        if status.system_status != 'ok'
          return 2
        end
        status.services.each do |service|
          if service != 'ok'
            return 2
          end
        end
        return 1
      end
    end
  end

  module Hostgroup
    def members_status(q)
      if self.hosts.nil?
        return 0
      else
        stat = {}
        stat[:total] = self.hosts.count
        stat[:failed] = 0
        self.hosts.each do |host|
          ret = host.is_ok?
          if ret != 1
            stat[:failed] = stat[:failed] + 1
          end
        end
        stat[:sane] = stat[:total] - stat[:failed]
        return stat[q]
      end
    end
  end
end
