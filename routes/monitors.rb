class ASYD < Sinatra::Application
  get '/monitors/list' do
    @monitors = Monitor.all
    @hosts = Host.all
    @hostgroups = Hostgroup.all
    erb :'monitor/monitors'
  end

  get '/monitors/:monitor' do
    @base = 'data/monitors/'+params[:monitor]
    erb :'monitor/monitor_detail'
  end

  post '/monitors/monitor' do
    target = params['target'].split(";")
    mon = params['monitor']

    if target[0] == "host"
      host = Host.first(:hostname => target[1])
      task = nil
      TATEX.synchronize do
        task = Task.create(:action => :monitoring, :object => mon, :target => host.hostname, :target_type => :host)
      end
      NOTEX.synchronize do
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+mon+" on "+host.hostname, :task => task)
      end
      inst = Spork.spork do
        sleep 0.2
        result = host.monitor_service(mon, task)
        if result == 1
          NOTEX.synchronize do
            msg = "Service "+mon+" successfully monitored on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :finished)
          end
        else
          TATEX.synchronize do
            task.update(:status => :failed)
          end
        end
      end
    elsif target[0] == "hostgroup"
      hostgroup = Hostgroup.first(:name => target[1])
      hostgroup_hosts = hostgroup.hosts
      task = nil
      TATEX.synchronize do
        task = Task.create(:action => :monitoring, :object => mon, :target => hostgroup.name, :target_type => :hostgroup)
      end
      NOTEX.synchronize do
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+mon+" on "+hostgroup.name, :task => task)
      end
      success = ProcessShared::SharedMemory.new(:int) #shared with the forks
      success.put_int(0, 1) #default to true
      inst = Spork.spork do
        hostgroup.group_launch { |host|
          result = host.monitor_service(mon, task)
          if result != 1
            NOTEX.synchronize do
              msg = "Error when monitoring "+mon+" on "+host.hostname
              notification = Notification.create(:type => :error, :dismiss => true, :message => msg, :task => task)
            end
            success.put_int(0, 0)
          end
        }
        if success.get_int(0) == 1
          NOTEX.synchronize do
            msg = "Service "+mon+" successfully monitored on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :finished)
          end
        else
          NOTEX.synchronize do
            msg = "Error when monitoring service "+mon+" on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :error, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :failed)
          end
        end
        success.close
      end
    end
    monitors = '/monitors/list'
    redirect to monitors
  end

  post '/monitors/unmonitor' do
    target = params['target'].split(";")
    mon = params['monitor']

    if target[0] == "host"
      host = Host.first(:hostname => target[1])
      task = nil
      TATEX.synchronize do
        task = Task.create(:action => :unmonitoring, :object => mon, :target => host.hostname, :target_type => :host)
      end
      NOTEX.synchronize do
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+mon+" on "+host.hostname, :task => task)
      end
      inst = Spork.spork do
        sleep 0.2
        result = host.unmonitor_service(mon, task)
        if result == 1
          NOTEX.synchronize do
            msg = "Service "+mon+" is not longer being monitored on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :finished)
          end
        else
          TATEX.synchronize do
            task.update(:status => :failed)
          end
        end
      end
    elsif target[0] == "hostgroup"
      hostgroup = Hostgroup.first(:name => target[1])
      hostgroup_hosts = hostgroup.hosts
      task = nil
      TATEX.synchronize do
        task = Task.create(:action => :monitoring, :object => mon, :target => hostgroup.name, :target_type => :hostgroup)
      end
      NOTEX.synchronize do
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+mon+" on "+hostgroup.name, :task => task)
      end
      success = ProcessShared::SharedMemory.new(:int) #shared with the forks
      success.put_int(0, 1) #default to true
      inst = Spork.spork do
        hostgroup.group_launch { |host|
          result = host.unmonitor_service(mon, task)
          if result != 1
            NOTEX.synchronize do
              msg = "Error when un-monitoring "+mon+" on "+host.hostname
              notification = Notification.create(:type => :error, :dismiss => true, :message => msg, :task => task)
            end
            success.put_int(0, 0)
          end
        }
        if success.get_int(0) == 1
          NOTEX.synchronize do
            msg = "Service "+mon+" is not longer being monitored on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :finished)
          end
        else
          NOTEX.synchronize do
            msg = "Error when un-monitoring service "+mon+" on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :error, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :failed)
          end
        end
        success.close
      end
    end
    monitors = '/monitors/list'
    redirect to monitors
  end

  post '/monitors/new' do
    name = params['monitor_name']
    path = "data/monitors/"
    unless name.include? "/" or name.include? "|" or name.include? "\\"
      FileUtils.touch path+name
    end
    deploys = '/monitors/list'
    redirect to deploys
  end

  post '/monitors/del' do
    monitor = params['monitor']
    Monitor.delete(monitor)
    monitors = '/monitors/list'
    redirect to monitors
  end

  # accessed by ajax only
  get %r{/monitors/get_file_contents/(.+)} do
    path = params[:captures].first
    if path.start_with?("data/monitors/") and !path.include? "../"
      send_file path
    end
  end

  # accessed by ajax only
  post '/monitors/edit' do
    path = params['path']
    text = params['text']
    if path.start_with?("data/monitors/") and !path.include? "../"
      open(path, 'w') { |file|
        file.puts text
      }
    end
  end
end
