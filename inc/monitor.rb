require 'monit'

def get_host_status(host)

  status = Monit::Status.new({ :host => "localhost",
                               :auth => true,
                               :username => "admin",
                               :password => "monit" })
  if !status.get
    exit
  end

  @data = {}
  @data[:total_cpu] = status.platform.cpu
  @data[:total_memory] = status.platform.memory/1024  # converted to MB
  @data[:architecture] = status.platform.machine
  @data[:used_sysmem_mb] = ''
  @data[:used_sysmem_percent] = ''
  @data[:load_15] = ''
  @data[:load_5] = ''
  @data[:load_1] = ''
  @data[:services] = Array.new

  i = 0
  status.services.each do |service|
  if Integer(service.service_type) == 5  # if is the system
    @data[:used_sysmem_mb] = String(Integer(service.system['memory']['kilobyte'])/1024)  # converted to MB
    @data[:used_sysmem_percent] = service.system['memory']['percent']
    @data[:load_15] = service.system['load']['avg15']
    @data[:load_5] = service.system['load']['avg05']
    @data[:load_1] = service.system['load']['avg01']
  else

    @data[:services][i] = {}
    @data[:services][i][:name] = service.name

    if Integer(service.status) > 0
      @data[:services][i][:status] = service.status_message
    end
    if Integer(service.monitor) == 0
      @data[:services][i][:status] = 'not monitored'
    else
      if Integer(service.status) == 0
        @data[:services][i][:status] = 'ok'
      end
    end
    i += 1 
  end
  end
end
