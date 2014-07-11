class ASYD < Sinatra::Application
  get '/deploys/list' do
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
      task = Task.create(:action => :installing, :target => host.hostname, :target_type => :host)
      notification = Notification.create(:type => :info, :message => task.action.to_s+" "+params['package']+" on "+host.hostname, :task => task)
      inst = Spork.spork do
        result = Deploy.install(host, params['package'])
        if result[0] == 1
          notification = Notification.create(:type => :success, :sticky => true, :message => result[1], :task => task)
          task.update(:status => :finished)
        else
          notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
          task.update(:status => :failed)
        end
      end
    elsif target[0] == "hostgroup"
      hostgroup = Hostgroup.first(:name => target[1])
      task = Task.create(:action => :installing, :target => hostgroup.name, :target_type => :hostgroup)
      notification = Notification.create(:type => :info, :message => task.action.to_s+" "+params['package']+" on "+hostgroup.name, :task => task)
      inst = Spork.spork do
        if !hostgroup.hosts.nil? && !hostgroup.hosts.empty?
          hostgroup.hosts.each do |host|
            result = Deploy.install(host, params['package'])
            if result[0] == 1
              notification = Notification.create(:type => :success, :sticky => true, :message => result[1], :task => task)
              task.update(:status => :finished)
            else
              notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
              task.update(:status => :failed)
            end
          end
        end
      end
    end
    deploys = '/deploys/list'
    redirect to deploys
  end

  post '/deploys/deploy' do
    target = params['target'].split(";")
    if target[0] == "host"
      host = Host.first(:hostname => target[1])
      task = Task.create(:action => :deploying, :target => host.hostname, :target_type => :host)
      notification = Notification.create(:type => :info, :message => task.action.to_s+" "+params['deploy']+" on "+host.hostname, :task => task)
      inst = Spork.spork do
        result = Deploy.launch(host, params['deploy'], task)
        if result == 1
          msg = "Deploy "+params['deploy']+" successfully deployed on "+target[0]+" "+target[1]
          notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
          task.update(:status => :finished)
        else
          notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
          task.update(:status => :failed)
        end
      end
    elsif target[0] == "hostgroup"
      hostgroup = Hostgroup.first(:name => target[1])
      task = Task.create(:action => :deploying, :target => hostgroup.name, :target_type => :hostgroup)
      notification = Notification.create(:type => :info, :message => task.action.to_s+" "+params['deploy']+" on "+hostgroup.name, :task => task)
      inst = Spork.spork do
        success = true
        if !hostgroup.hosts.nil? && !hostgroup.hosts.empty?
          hostgroup.hosts.each do |host|
            result = Deploy.launch(host, params['deploy'], task)
            if result != 1
              msg = "Error when deploying "+params['deploy']+" on "+host.hostname+": "+result[1]
              notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
              success = false
            end
          end
        end
        if success == true
          msg = "Deploy "+params['deploy']+" successfully deployed on "+target[0]+" "+target[1]
          notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
          task.update(:status => :finished)
        else
          msg = "Deploy "+params['deploy']+" had errors when deploying on "+target[0]+" "+target[1]
          notification = Notification.create(:type => :error, :sticky => true, :message => msg, :task => task)
          task.update(:status => :failed)
        end
      end
    end
    deploys = '/deploys/list'
    redirect to deploys
  end
end
