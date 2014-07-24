module Monitoring

  TTL = 15 #store/refresh the status for 15 seconds

  class Notification < ::Notification
    property :acknowledge, Boolean, :default => false
    property :host_hostname, String
    property :service, String
  end

  module Host
    include Misc

    def monitor
      begin
        ret = Deploy.install(self, "monit")
        if ret[0] != 1
          raise ExecutionError, ret[1]
        end
        parsed_cfg = Deploy.parse_config(self, "data/monitors/monitrc")
        upload_file(parsed_cfg.path, "/etc/monit/monitrc")
        parsed_cfg.unlink
        exec_cmd('echo "startup=1" > /etc/default/monit')
        exec_cmd('service monit restart')
        self.monitored = true
        self.save
      rescue ExecutionError => e
        NOTEX.synchronize do
          msg = "Unable to monitor host "+self.hostname+": "+e.message
          Notification.create(:type => :error, :sticky => true, :message => msg)
        end
      end
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
          stat = nil
          MOTEX.synchronize do
            status.destroy
            stat = Status.new(self)
          end
          if stat.id.nil?
            self.status = nil
          else
            self.status = stat
          end
          return self.status
        else
          return self.status
        end
      else
        stat = nil
        MOTEX.synchronize do
          stat = Status.new(self)
        end
        if stat.id.nil?
          self.status = nil
        else
          self.status = stat
        end
        return self.status
      end
    end

    # @param refresh [Boolean] refresh the status?
    # Status codes:
    # 4 == not monitored
    # 3 == host down
    # 2 == problem
    # 1 == all ok
    def is_ok?
      if self.monitored == false
        return 4
      else
        if self.status.nil?
          return 3
        else
          if self.status.system_status != 'ok'
            return 2
          end
          self.status.services.each do |service|
            if service[1] != 'ok'
              return 2
            end
          end
          return 1
        end
      end
    end
  end

  module Hostgroup
    def members_status
      stat = {}
      stat[:total] = self.hosts.count
      stat[:failed] = 0
      stat[:sane] = 0
      if stat[:total] == 0
        return stat
      else
        self.hosts.each do |host|
          ret = host.is_ok?
          if ret != 1
            stat[:failed] = stat[:failed] + 1
          end
        end
        stat[:sane] = stat[:total] - stat[:failed]
        return stat
      end
    end
  end

  def self.background
    while true
      hosts = ::Host.all
      hosts.each do |host|
        stat = host.get_status
        if stat.nil?
          NOTEX.synchronize do
            error = "Unable to get monitoring status for host "+host.hostname
            Monitoring::Notification.create(:type => :error, :message => error, :sticky => true, :host_hostname => host.hostname, :service => "system")
          end
        end
      end
      sleep TTL
    end
  end
end
