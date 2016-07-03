module Monitoring

  module Host
    include Misc

    def monitor
      begin
        task = nil
        TATEX.synchronize do
          task = Task.create(:action => :deploying, :object => "monit", :target => self.hostname, :target_type => :host)
        end
        NOTEX.synchronize do
          ::Notification.create(:type => :info, :message => I18n.t('task.actions.deploying')+" monit on "+self.hostname, :task => task)
        end
        self.reload
        ret = Deploy.launch(self, "monit", task)
        if ret != 1
          raise ExecutionError, ret[1]
        else
          NOTEX.synchronize do
            msg = "Deploy monit successfully deployed on host "+self.hostname
            ::Notification.create(:type => :success, :sticky => false, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :finished)
          end
        end
      rescue ExecutionError => e
        NOTEX.synchronize do
          msg = "Unable to monitor host "+self.hostname+": "+e.message
          ::Notification.create(:type => :error, :sticky => true, :message => msg, :task => task)
        end
        TATEX.synchronize do
          task.update(:status => :failed)
        end
      end
    end

    def monitor_service(service, task = nil)
      begin
        unless File.exist?("data/monitors/"+service)
          raise
        end
        parsed_cfg = Deploy.parse_config(self, "data/monitors/"+service)
        if self.user != "root"
          upload_file(parsed_cfg.path, "/tmp/"+service)
          exec_cmd("sudo mv /tmp/"+service+" /etc/monit/conf.d/"+service)
          exec_cmd("sudo chown root:root /etc/monit/conf.d/"+service)
          exec_cmd("sudo /usr/bin/monit -c /etc/monit/monitrc reload")
        else
          upload_file(parsed_cfg.path, "/etc/monit/conf.d/"+service)
          exec_cmd("/usr/bin/monit -c /etc/monit/monitrc reload")
        end
        parsed_cfg.unlink
        return 1
      rescue
        NOTEX.synchronize do
          msg = "Monitor file not found for service "+service
          if task.nil?
            ::Notification.create(:type => :error, :sticky => true, :message => msg)
          else
            ::Notification.create(:type => :error, :sticky => true, :message => msg, :task => task)
          end
        end
        return 5
      end
    end

    def unmonitor_service(service, task = nil)
      begin
        if self.user != "root"
          exec_cmd("sudo rm /etc/monit/conf.d/"+service)
          exec_cmd("sudo /usr/bin/monit -c /etc/monit/monitrc reload")
        else
          exec_cmd("rm /etc/monit/conf.d/"+service)
          exec_cmd("/usr/bin/monit -c /etc/monit/monitrc reload")
        end
        return 1
      rescue => e
        NOTEX.synchronize do
          msg = "Error un-monitoring "+service+": "+e.message
          if task.nil?
            ::Notification.create(:type => :error, :sticky => true, :message => msg)
          else
            ::Notification.create(:type => :error, :sticky => true, :message => msg, :task => task)
          end
        end
        return 5
      end
    end

    def get_status
      short = true
      stat = Status.new(self, short)
      status = 1
      if stat.system_status.nil? || stat.system_status == 'down'
        status = 3
      else
        if stat.system_status != 'ok'
          status = 2
        end
        stat.services.each do |service|
          if service[1] != 'ok'
            status = 2
          end
        end unless stat.services.nil?
      end
      MOTEX.synchronize do
        hoststatus = HostStatus.first(:host_hostname => self.hostname)
        if hoststatus.nil?
          HostStatus.create(:host_hostname => self.hostname, :status => status)
        else
          hoststatus.update(:status => status)
        end
      end
      return status
    end

    def get_full_status
      short = false
      stat = Status.new(self, short)
      return stat
    end

    # Status codes:
    # 4 == not monitored
    # 3 == host down
    # 2 == problem
    # 1 == all ok
    def is_ok?
      if self.opt_vars.nil? or self.opt_vars["monitored"].nil? or self.opt_vars["monitored"].to_i != 1
        return 4
      else
        hoststatus = HostStatus.first(:host_hostname => self.hostname)
        if hoststatus.nil?
          return self.get_status
        else
          return hoststatus.status
        end
      end
    end
  end

end
