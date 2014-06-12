require 'monit'

def monitor(host)
  begin
    hostdata = get_host_data(host)
    ip = hostdata[:ip]

    install_pkg(host,"monit",true)
    parsed_cfg = parse_config(host, "data/monitors/monitrc")
    upload_file(ip, parsed_cfg.path, "/etc/monit/monitrc")
    parsed_cfg.unlink
    exec_cmd(ip, 'echo "startup=1" > /etc/default/monit')
    exec_cmd(ip, 'service monit restart')
  end
end


def monitor_service(service, host)
  begin
    hostdata = get_host_data(host)
    ip = hostdata[:ip]

    parsed_cfg = parse_config(host, "data/monitors/modules/"+service)
    upload_file(ip, parsed_cfg.path, "/etc/monit/conf.d/"+service)
    parsed_cfg.unlink
    exec_cmd(ip, "service monit restart")
  end
end


def get_host_status(host)
  hostdata = get_host_data(host)
  ip = hostdata[:ip]
  monit_pw = hostdata[:monit_pw]

  status = Monit::Status.new({ :host => ip,
                               :auth => true,
                               :username => "asyd",
                               :password => monit_pw })
  if !status.get
    exit
  end

  data = {}
  data[:total_cpu] = status.platform.cpu
  data[:total_memory] = status.platform.memory/1024  # converted to MB
  data[:used_sysmem_mb] = ''
  data[:used_sysmem_percent] = ''
  data[:load_15] = ''
  data[:load_5] = ''
  data[:load_1] = ''
  data[:services] = Array.new

  i = 0
  status.services.each do |service|
  if Integer(service.service_type) == 5  # if is the system
    data[:used_sysmem_mb] = String(Integer(service.system['memory']['kilobyte'])/1024)  # converted to MB
    data[:used_sysmem_percent] = service.system['memory']['percent']
    data[:load_15] = service.system['load']['avg15']
    data[:load_5] = service.system['load']['avg05']
    data[:load_1] = service.system['load']['avg01']
    data[:cpu_wa] = service.system['cpu']['wait']
    data[:cpu_sy] = service.system['cpu']['system']
    data[:cpu_us] = service.system['cpu']['user']
  else

    data[:services][i] = {}
    data[:services][i][:name] = service.name

    if Integer(service.status) > 0
      data[:services][i][:status] = service.status_message
    end
    if Integer(service.monitor) == 0
      data[:services][i][:status] = 'not monitored'
    else
      if Integer(service.status) == 0
        data[:services][i][:status] = 'ok'
      end
    end
    i += 1
  end
  end
  return data
end
