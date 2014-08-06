class Status
  attr_reader :system_status
  attr_reader :services

  attr_reader :total_memory, :used_sysmem_mb, :used_sysmem_percent
  attr_reader :total_cpu, :load_15, :load_5, :load_1, :cpu_wa, :cpu_sy, :cpu_us

  def initialize(host, short)
    begin
      if !Misc::is_port_open?(host.ip, 2812)
        @system_status = 'down'
      else
        monit_status = Monit::Status.new({ :host => host.ip,
                                     :auth => true,
                                     :username => "asyd",
                                     :password => host.monit_pw })
        if !monit_status.get
          @system_status = 'down'
        end
        @total_cpu = monit_status.platform.cpu unless short
        @total_memory = monit_status.platform.memory/1024 unless short # converted to MB
        monit_status.services.each do |service|
          if Integer(service.service_type) == 5  # if is the system
            if !short
              @used_sysmem_mb = Integer(service.system['memory']['kilobyte'])/1024  # converted to MB
              @used_sysmem_percent = Float(service.system['memory']['percent'])
              @load_15 = Float(service.system['load']['avg15'])
              @load_5 = Float(service.system['load']['avg05'])
              @load_1 = Float(service.system['load']['avg01'])
              @cpu_wa = Float(service.system['cpu']['wait'])
              @cpu_sy = Float(service.system['cpu']['system'])
              @cpu_us = Float(service.system['cpu']['user'])
            end
            if Integer(service.status) > 0
              @system_status = service.status_message
            else
              @system_status = 'ok'
            end
          else
            @services= {}
            if Integer(service.status) > 0
              @services[service.name] = service.status_message
            end
            if Integer(service.monitor) == 0
              @services[service.name] = 'not monitored'
            else
              if Integer(service.status) == 0
                @services[service.name] = 'ok'
              end
            end
          end
        end
      end
      return self
    rescue
      return nil
    end
  end
end

class HostStatus
  include DataMapper::Resource

  def self.default_repository_name #here we use the hosts_db for the Host objects
   :status_db
  end

  property :host_hostname, String, :key => true
  property :status, Integer
end
