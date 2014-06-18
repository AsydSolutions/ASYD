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
  begin
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
        if Integer(service.status) > 0
          data[:status] = service.status_message
        else
          data[:status] = 'ok'
        end
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
  rescue SystemExit
    error = "Unable to get monitoring status for host "+host
    add_notification(0, error, 0)
    return nil
  end
end

def background_monitoring()
  n = ''
  f = File.open("data/monitors/monitrc", "r").read
  f.gsub!(/\r\n?/, "\n")
  f.each_line do |line|
    m = line.match(/^set daemon (\d+)/)
    if !m.nil?
      n = m[1].to_i
    end
  end
  while true
    servers = get_server_list
    monitoring = SQLite3::Database.new "data/db/notifications.db"
    servers.each do |host|
      status = get_host_status(host)
      if status[:status] == 'ok'
        oldstatus = monitoring.get_first_row("select id,solved from monitoring where host=? and service='system' order by id desc", host)
        if !oldstatus.nil?
          if oldstatus[1] == 0  # the issue is now solved
            monitoring.execute("UPDATE monitoring SET solved=1 WHERE id=?", oldstatus[0])
          end
        end
      else
        oldstatus = monitoring.get_first_row("select id,acknowledge,solved from monitoring where host=? and service='system' order by id desc", host)
        if !oldstatus.nil?
          if oldstatus[2] == 0 # exists in db and not solved
            if oldstatus[1] == 0 # also not acknowledged
              msg = "Alert on "+host+": "+status[:status]
              notify(msg)
            end
          else # must be old so we create a new one
            monitoring.execute("INSERT INTO monitoring (host, message) VALUES (?, ?)", [host, status[:status]])
            msg = "Alert on "+host+": "+status[:status]
            notify(msg)
          end
        else # new on the db
          monitoring.execute("INSERT INTO monitoring (host, message) VALUES (?, ?)", [host, status[:status]])
          msg = "Alert on "+host+": "+status[:status]
          notify(msg)
        end
      end
      status[:services].each do |service|
        if service[:status] == 'ok'
          oldstatus = monitoring.get_first_row("select id,solved from monitoring where host=? and service=? order by id desc", [host, service[:name]])
          if !oldstatus.nil?
            if oldstatus[1] == 0  # the issue is now solved
              monitoring.execute("UPDATE monitoring SET solved=1 WHERE id=?", oldstatus[0])
            end
          end
        else
          oldstatus = monitoring.get_first_row("select id,acknowledge,solved from monitoring where host=? and service=? order by id desc", [host, service[:name]])
          if !oldstatus.nil?
            if oldstatus[2] == 0 # exists in db and not solved
              if oldstatus[1] == 0 # also not acknowledged
                msg = "Alert service "+service[:name]+" on "+host+": "+service[:status]
                notify(msg)
              end
            else # must be old so we create a new one
              monitoring.execute("INSERT INTO monitoring (host, service, message) VALUES (?, ?, ?)", [host, service[:name], service[:status]])
              msg = "Alert service "+service[:name]+" on "+host+": "+service[:status]
              notify(msg)
            end
          else # new on the db
            monitoring.execute("INSERT INTO monitoring (host, service, message) VALUES (?, ?, ?)", [host, service[:name], service[:status]])
            msg = "Alert service "+service[:name]+" on "+host+": "+service[:status]
            notify(msg)
          end
        end
      end
    end
    monitoring.close
    sleep n
  end
end

def notify(msg)
  userdb = SQLite3::Database.new "data/db/users.db"
  userdb.execute("select email,notifications from users") do |row|
    if row[1].to_i == 1
      p email
      p msg
    end
  end
  userdb.close
end

def acknowledge(host, service)
  monitoring = SQLite3::Database.new "data/db/notifications.db"
  monitoring.execute("UPDATE monitoring SET acknowledge=1 WHERE host=? and service=?", [host, service])
  monitoring.close
end
