class Status
  include DataMapper::Resource

  property :id, Serial
  property :total_cpu, Integer
  property :total_memory, Integer
  property :used_sysmem_mb, Integer
  property :used_sysmem_percent, Float
  property :load_15, Float
  property :load_5, Float
  property :load_1, Float
  property :cpu_wa, Float
  property :cpu_sy, Float
  property :cpu_us, Float
  property :system_status, Text
  property :services, Object #services is a hash with the format {service_name => status}
  property :created_at, DateTime
  belongs_to :host, :child_repository_name => :hosts_db

  def initialize(host)
    begin
      monit_status = Monit::Status.new({ :host => host.ip,
                                   :auth => true,
                                   :username => "asyd",
                                   :password => host.monit_pw })
      if !monit_status.get
        raise
      end
      self.total_cpu = monit_status.platform.cpu
      self.total_memory = monit_status.platform.memory/1024  # converted to MB
      monit_status.services.each do |service|
        if Integer(service.service_type) == 5  # if is the system
          self.used_sysmem_mb = Integer(service.system['memory']['kilobyte'])/1024  # converted to MB
          self.used_sysmem_percent = Float(service.system['memory']['percent'])
          self.load_15 = Float(service.system['load']['avg15'])
          self.load_5 = Float(service.system['load']['avg05'])
          self.load_1 = Float(service.system['load']['avg01'])
          self.cpu_wa = Float(service.system['cpu']['wait'])
          self.cpu_sy = Float(service.system['cpu']['system'])
          self.cpu_us = Float(service.system['cpu']['user'])
          if Integer(service.status) > 0
            self.system_status = service.status_message
          else
            self.system_status = 'ok'
          end
        else
          self.services= {}
          if Integer(service.status) > 0
            self.services[service.name] = service.status_message
          end
          if Integer(service.monitor) == 0
            self.services[service.name] = 'not monitored'
          else
            if Integer(service.status) == 0
              self.services[service.name] = 'ok'
            end
          end
        end
      end
      self.host = host
      if !self.save
        raise #couldn't save the object
      end
      return self
    rescue
      return nil
    end
  end
end
