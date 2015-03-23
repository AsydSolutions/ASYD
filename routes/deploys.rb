class ASYD < Sinatra::Application
  get '/deploys/list' do
    status 200
    @deploys = Deploy.all
    @deploy_alerts = Deploy.get_alerts
    @undeploy_alerts = Deploy.get_undeploy_alerts
    @hosts = Host.all
    @hostgroups = Hostgroup.all
    erb :'deploy/deploys'
  end

  get '/deploys/:dep' do
    @base = 'data/deploys/'+params[:dep]+'/'
    @deploy = params[:dep]
    erb :'deploy/deploy_detail'
  end

  # Install packages
  #
  post '/deploys/install-pkg' do
    target = params['target'].split(";")
    if target[0] == "host"
      host = Host.first(:hostname => target[1])
      task = nil
      TATEX.synchronize do
        task = Task.create(:action => :installing, :object => params['package'], :target => host.hostname, :target_type => :host)
      end
      NOTEX.synchronize do
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+params['package']+" on "+host.hostname, :task => task)
      end
      inst = Spork.spork do
        sleep 0.2
        result = Deploy.install(host, params['package'])
        if result[0] == 1
          NOTEX.synchronize do
            notification = Notification.create(:type => :success, :sticky => true, :message => result[1], :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :finished)
          end
        else
          NOTEX.synchronize do
            notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :failed)
          end
        end
      end
    elsif target[0] == "hostgroup"
      hostgroup = Hostgroup.first(:name => target[1])
      task = nil
      TATEX.synchronize do
        task = Task.create(:action => :installing, :object => params['package'], :target => hostgroup.name, :target_type => :hostgroup)
      end
      NOTEX.synchronize do
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+params['package']+" on "+hostgroup.name, :task => task)
      end
      success = ProcessShared::SharedMemory.new(:int) #shared with the forks
      success.put_int(0, 1) #default to true
      inst = Spork.spork do
        hostgroup.group_launch { |host|
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
        }
        if success.get_int(0) == 1
          NOTEX.synchronize do
            msg = "Packages successfully installed on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :finished)
          end
        else
          NOTEX.synchronize do
            msg = "Error installing packages on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :error, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :failed)
          end
        end
        success.close
      end
    end
    deploys = '/deploys/list'
    redirect to deploys
  end

  # Execute commands
  #
  post '/deploys/exec-cmd' do
    target = params['target'].split(";")
    if target[0] == "host"
      host = Host.first(:hostname => target[1])
      task = nil
      TATEX.synchronize do
        task = Task.create(:action => :executing, :object => params['cmd'], :target => host.hostname, :target_type => :host)
      end
      NOTEX.synchronize do
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" '"+params['cmd']+"' on "+host.hostname, :task => task)
      end
      inst = Spork.spork do
        sleep 0.2
        cmd = Deploy.parse(host, params['cmd'])
        result = host.exec_cmd(cmd)
        NOTEX.synchronize do
          notification = Notification.create(:type => :success, :sticky => true, :message => "Result: "+result, :task => task)
        end
        TATEX.synchronize do
          task.update(:status => :finished)
        end
      end
    elsif target[0] == "hostgroup"
      hostgroup = Hostgroup.first(:name => target[1])
      task = nil
      TATEX.synchronize do
        task = Task.create(:action => :executing, :object => params['cmd'], :target => hostgroup.name, :target_type => :hostgroup)
      end
      NOTEX.synchronize do
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" '"+params['cmd']+"' on "+hostgroup.name, :task => task)
      end
      inst = Spork.spork do
        hostgroup.group_launch { |host|
          cmd = Deploy.parse(host, params['cmd'])
          result = host.exec_cmd(cmd)
          NOTEX.synchronize do
            msg = "Executed "+cmd+" on "+host.hostname+": "+result
            notification = Notification.create(:type => :success, :dismiss => true, :message => msg, :task => task)
          end
        }
        NOTEX.synchronize do
          msg = "Command successfully executed on "+target[0]+" "+target[1]
          notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
        end
        TATEX.synchronize do
          task.update(:status => :finished)
        end
      end
    end
    deploys = '/deploys/list'
    redirect to deploys
  end

  # Launch a deploy
  #
  post '/deploys/deploy' do
    target = params['target'].split(";")
    dep = params['deploy']

    if target[0] == "host"
      host = Host.first(:hostname => target[1])
      task = nil
      TATEX.synchronize do
        task = Task.create(:action => :deploying, :object => params['deploy'], :target => host.hostname, :target_type => :host)
      end
      NOTEX.synchronize do
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+params['deploy']+" on "+host.hostname, :task => task)
      end
      inst = Spork.spork do
        sleep 0.2
        result = Deploy.launch(host, dep, task)
        if result == 1
          NOTEX.synchronize do
            msg = "Deploy "+params['deploy']+" successfully deployed on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :finished)
          end
        else
          NOTEX.synchronize do
            notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :failed)
          end
        end
      end
    elsif target[0] == "hostgroup"
      hostgroup = Hostgroup.first(:name => target[1])
      task = nil
      TATEX.synchronize do
        task = Task.create(:action => :deploying, :object => params['deploy'], :target => hostgroup.name, :target_type => :hostgroup)
      end
      NOTEX.synchronize do
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+params['deploy']+" on "+hostgroup.name, :task => task)
      end
      success = ProcessShared::SharedMemory.new(:int) #shared with the forks
      success.put_int(0, 1) #default to true
      inst = Spork.spork do
        hostgroup.group_launch { |host|
          result = Deploy.launch(host, dep, task)
          if result != 1
            NOTEX.synchronize do
              msg = "Error when deploying "+params['deploy']+" on "+host.hostname+": "+result[1]
              notification = Notification.create(:type => :error, :dismiss => true, :message => msg, :task => task)
            end
            success.put_int(0, 0)
          end
        }
        if success.get_int(0) == 1
          NOTEX.synchronize do
            msg = "Deploy "+params['deploy']+" successfully deployed on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :finished)
          end
        else
          NOTEX.synchronize do
            msg = "Deploy "+params['deploy']+" had errors when deploying on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :error, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :failed)
          end
        end
        success.close
      end
    end
    deploys = '/deploys/list'
    redirect to deploys
  end

  # Undeploy a deploy
  #
  post '/deploys/undeploy' do
    target = params['target'].split(";")
    dep = params['deploy']

    if target[0] == "host"
      host = Host.first(:hostname => target[1])
      task = nil
      TATEX.synchronize do
        task = Task.create(:action => :undeploying, :object => params['deploy'], :target => host.hostname, :target_type => :host)
      end
      NOTEX.synchronize do
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+params['deploy']+" on "+host.hostname, :task => task)
      end
      inst = Spork.spork do
        sleep 0.2
        result = Deploy.undeploy(host, dep, task)
        if result == 1
          NOTEX.synchronize do
            msg = "Deploy "+params['deploy']+" successfully undeployed (reverted) on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :finished)
          end
        else
          NOTEX.synchronize do
            notification = Notification.create(:type => :error, :sticky => true, :message => result[1], :task => task)
          end
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
        task = Task.create(:action => :undeploying, :object => params['deploy'], :target => hostgroup.name, :target_type => :hostgroup)
      end
      NOTEX.synchronize do
        notification = Notification.create(:type => :info, :message => t('task.actions.'+task.action.to_s)+" "+params['deploy']+" on "+hostgroup.name, :task => task)
      end
      success = ProcessShared::SharedMemory.new(:int) #shared with the forks
      success.put_int(0, 1) #default to true
      inst = Spork.spork do
        hostgroup.group_launch { |host|
          result = Deploy.undeploy(host, dep, task)
          if result != 1
            NOTEX.synchronize do
              msg = "Error when undeploying (reverting) "+params['deploy']+" on "+host.hostname+": "+result[1]
              notification = Notification.create(:type => :error, :dismiss => true, :message => result[1], :task => task)
            end
            success.put_int(0, 0)
          end
        }
        if success.get_int(0) == 1
          NOTEX.synchronize do
            msg = "Deploy "+params['deploy']+" successfully undeployed (reverted) on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :success, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :finished)
          end
        else
          NOTEX.synchronize do
            msg = "Deploy "+params['deploy']+" had errors when undeploying (reverting) on "+target[0]+" "+target[1]
            notification = Notification.create(:type => :error, :sticky => true, :message => msg, :task => task)
          end
          TATEX.synchronize do
            task.update(:status => :failed)
          end
        end
        success.close
      end
    end
    deploys = '/deploys/list'
    redirect to deploys
  end

  # accessed by ajax only
  get %r{/deploys/get_file_contents/(.+)} do
    path = params[:captures].first
    if path.start_with?("data/deploys/") and !path.include? "../"
      send_file path
    end
  end

  # accessed by ajax only
  post '/deploys/edit' do
    path = params['path']
    text = params['text']
    if path.start_with?("data/deploys/") and !path.include? "../"
      open(path, 'w') { |file|
        file.puts text
      }
    end
  end

  post '/deploys/new' do
    name = params['deploy_name']
    path = "data/deploys/"
    unless name.include? "/" or name.include? "|" or name.include? "\\"
      FileUtils.mkdir path+name
      FileUtils.mkdir path+name+"/configs"
      text = "# Alert: Empty deploy, modify before launching"
      open(path+name+'/def', 'w') { |file|
        file.puts text
      }
    end
    deploys = '/deploys/list'
    redirect to deploys
  end

  post '/deploys/del' do
    deploy = params['deploy']
    unless deploy == "monit"
      Deploy.delete(deploy)
    end
    deploys = '/deploys/list'
    redirect to deploys
  end

  post '/deploys/:deploy/create_file' do
    deploy = params[:deploy]
    path = params['path']
    fullpath = "data/deploys/"+deploy+"/"+path
    unless fullpath.include? "../" or fullpath.include? "|" or fullpath.include? "\\"
      FileUtils.mkdir_p File.dirname(fullpath)
      FileUtils.touch fullpath
    end
    deploy_view = '/deploys/'+deploy
    redirect to deploy_view
  end

  post '/deploys/:deploy/upload_file' do
    deploy = params[:deploy]
    path = params[:path]
    file = params[:file][:tempfile]
    fullpath = "data/deploys/"+deploy+"/"+path
    unless fullpath.include? "../" or fullpath.include? "|" or fullpath.include? "\\"
      FileUtils.mkdir_p File.dirname(fullpath)
      File.open(fullpath, "w") do |f|
        f.write(file.read)
      end
    end
    deploy_view = '/deploys/'+deploy
    redirect to deploy_view
  end

  post '/deploys/:deploy/del_file' do
    deploy = params[:deploy]
    path = params['path']
    unless path.include? "../" or path.include? "|" or path.include? "\\"
      FileUtils.rm path
    end
    deploy_view = '/deploys/'+deploy
    redirect to deploy_view
  end

  post '/deploys/:deploy/del_folder' do
    deploy = params[:deploy]
    path = params['path']
    unless path.include? "../" or path.include? "|" or path.include? "\\"
      FileUtils.rm_r path, :secure=>true
    end
    deploy_view = '/deploys/'+deploy
    redirect to deploy_view
  end
end
