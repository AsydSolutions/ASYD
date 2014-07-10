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
    task = Task.create(:action => :installing, :target => target[1])
    notification = Notification.create(:type => :info, :message => task.action.to_s+" "+params['package']+" on "+task.target.to_s, :task => task)
    inst = Spork.spork do
      if target[0] == "host"
        host = Host.first(:hostname => target[1])
        result = Deploy.install(host, params['package'])
        if result[0] == 1
          notification = Notification.create(:type => :success, :sticky => true, :message => result[1], :task => task)
        else
          notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
        end
      elsif target[0] == "hostgroup"
        hostgroup = Hostgroup.first(:name => target[1])
        if !hostgroup.hosts.nil? && !hostgroup.hosts.empty?
          hostgroup.hosts.each do |host|
            result = Deploy.install(host, params['package'])
            if result[0] == 1
              notification = Notification.create(:type => :success, :sticky => true, :message => result[1], :task => task)
            else
              notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
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
    task = Task.create(:action => :deploying, :target => target[1])
    notification = Notification.create(:type => :info, :message => task.action.to_s+" "+params['deploy']+" on "+task.target.to_s, :task => task)
    inst = Spork.spork do
      if target[0] == "host"
        host = Host.first(:hostname => target[1])
        result = Deploy.launch(host, params['deploy'], nil)
        if result == 1
          msg = "Deploy "+params['deploy']+" successfully deployed on "+target[0]+" "+target[1]
          notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
        else
          notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
        end
      elsif target[0] == "hostgroup"
        hostgroup = Hostgroup.first(:name => target[1])
        if !hostgroup.hosts.nil? && !hostgroup.hosts.empty?
          hostgroup.hosts.each do |host|
            result = Deploy.launch(host, params['deploy'], nil)
            if result == 1
              msg = "Deploy "+params['deploy']+" successfully deployed on "+target[0]+" "+target[1]
              notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
            else
              notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
            end
          end
        end
      end
    end
    deploys = '/deploys/list'
    redirect to deploys
  end
end
