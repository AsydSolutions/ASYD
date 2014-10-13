class ASYD < Sinatra::Application
  get '/deploys/list' do
    status 200
    @deploys = Misc::get_dirs("data/deploys/")
    @hosts = Host.all
    @hostgroups = Hostgroup.all
    erb :deploys
  end

  get '/deploys/:dep' do
    erb "-WIP-"
  end

  post '/deploys/install-pkg' do
    target = params['target'].split(";")
    if target[0] == "host"
      host = Host.first(:hostname => target[1])
      task = nil
      NOTEX.synchronize do
        task = Task.create(:action => :installing, :object => params['package'], :target => host.hostname, :target_type => :host)
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+params['package']+" on "+host.hostname, :task => task)
      end
      inst = Spork.spork do
        sleep 0.2
        result = Deploy.install(host, params['package'])
        if result[0] == 1
          NOTEX.synchronize do
            notification = Notification.create(:type => :success, :sticky => true, :message => result[1], :task => task)
            task.update(:status => :finished)
          end
        else
          NOTEX.synchronize do
            notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
            task.update(:status => :failed)
          end
        end
      end
    elsif target[0] == "hostgroup"
      hostgroup = Hostgroup.first(:name => target[1])
      task = nil
      NOTEX.synchronize do
        task = Task.create(:action => :installing, :object => params['package'], :target => hostgroup.name, :target_type => :hostgroup)
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+params['package']+" on "+hostgroup.name, :task => task)
      end
      inst = Spork.spork do
        sleep 0.2
        success = ProcessShared::SharedMemory.new(:int) #shared with the forks
        success.put_int(0, 1)
        if !hostgroup.hosts.nil? && !hostgroup.hosts.empty? #it's a valid hostgroup
          max_forks = Misc::get_max_forks #we get the "forkability"
          forks = [] #and initialize an empty array
          hostgroup.hosts.each do |host| #for each host
            if forks.count >= max_forks #if we reached the "forkability" limit
              id = Process.wait #then we wait for some child to finish
              forks.delete(id) #and we remove it from the forks array
            end
            frk = Spork.spork do #so we can continue executing a new fork
              result = Deploy.install(host, params['package'])
              if result[0] == 1
                NOTEX.synchronize do
                  msg = "Installed "+params['package']+" on "+host.hostname+": "+result[1]
                  notification = Notification.create(:type => :success, :dismiss => true, :message => msg, :task => task)
                end
              else
                NOTEX.synchronize do
                  msg = "Error installing "+params['package']+" on "+host.hostname+": "+result[1]
                  notification = Notification.create(:type => :error, :dismiss => true, :message => msg, :task => task)
                end
                success.put_int(0, 0)
              end
            end
            forks << frk #and store the fork id on the forks array
          end
        end
        Process.waitall
        if success.get_int(0) == 1
          NOTEX.synchronize do
            msg = "Packages successfully installed on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
            task.update(:status => :finished)
          end
        else
          NOTEX.synchronize do
            msg = "Error installing packages on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :error, :sticky => true, :message => msg, :task => task)
            task.update(:status => :failed)
          end
        end
        success.close
      end
    end
    deploys = '/deploys/list'
    redirect to deploys
  end

  post '/deploys/deploy' do
    target = params['target'].split(";")
    dep = params['deploy']

    if target[0] == "host"
      host = Host.first(:hostname => target[1])
      task = nil
      NOTEX.synchronize do
        task = Task.create(:action => :deploying, :object => params['deploy'], :target => host.hostname, :target_type => :host)
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+params['deploy']+" on "+host.hostname, :task => task)
      end
      inst = Spork.spork do
        sleep 0.2
        result = Deploy.launch(host, dep, task)
        if result == 1
          NOTEX.synchronize do
            msg = "Deploy "+params['deploy']+" successfully deployed on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
            task.update(:status => :finished)
          end
        else
          NOTEX.synchronize do
            notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
            task.update(:status => :failed)
          end
        end
      end
    elsif target[0] == "hostgroup"
      hostgroup = Hostgroup.first(:name => target[1])
      hostgroup_hosts = hostgroup.hosts
      task = nil
      NOTEX.synchronize do
        task = Task.create(:action => :deploying, :object => params['deploy'], :target => hostgroup.name, :target_type => :hostgroup)
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+params['deploy']+" on "+hostgroup.name, :task => task)
      end
      inst = Spork.spork do
        sleep 0.2
        success = ProcessShared::SharedMemory.new(:int) #shared with the forks
        success.put_int(0, 1)
        if !hostgroup_hosts.nil? && !hostgroup_hosts.empty? #it's a valid hostgroup
          max_forks = Misc::get_max_forks #we get the "forkability"
          forks = [] #and initialize an empty array
          hostgroup_hosts.each do |host| #for each host
            if forks.count >= max_forks #if we reached the "forkability" limit
              id = Process.wait #then we wait for some child to finish
              forks.delete(id) #and we remove it from the forks array
            end
            frk = Spork.spork do #so we can continue executing a new fork
                result = Deploy.launch(host, dep, task)
              if result != 1
                NOTEX.synchronize do
                  msg = "Error when deploying "+params['deploy']+" on "+host.hostname+": "+result[1]
                  notification = Notification.create(:type => :error, :dismiss => true, :message => result[1], :task => task)
                end
                success.put_int(0, 0)
              end
            end
            forks << frk #and store the fork id on the forks array
          end
        end
        Process.waitall
        if success.get_int(0) == 1
          NOTEX.synchronize do
            msg = "Deploy "+params['deploy']+" successfully deployed on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
            task.update(:status => :finished)
          end
        else
          NOTEX.synchronize do
            msg = "Deploy "+params['deploy']+" had errors when deploying on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :error, :sticky => true, :message => msg, :task => task)
            task.update(:status => :failed)
          end
        end
        success.close
      end
    end
    deploys = '/deploys/list'
    redirect to deploys
  end
end
