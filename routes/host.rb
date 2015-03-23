class ASYD < Sinatra::Application
  get '/hosts/overview' do
    status 200
    @groups = Hostgroup.all
    @hosts = Host.all
    @host_status = {}
    @hosts.each do |host|
      @host_status[host.hostname] = host.is_ok?
    end
    erb :'host/hosts_overview'
  end

  get '/host/:host' do
    status 200
    @host = Host.first(:hostname => params[:host])
    if @host.nil?
      not_found
    else
      @status = @host.get_full_status
      erb :'host/host_detail'
    end
  end

  post '/host/add' do
    status 200
    HOSTEX.synchronize do
      Host.init(params['hostname'], params['ip'], params['user'], params['ssh_port'].to_i, params['password'])
    end
    if params['more'].nil?
      hostlist = '/hosts/overview'
    else
      hostlist = '/hosts/overview#addServer'
    end
    redirect to hostlist
  end

  post '/host/del' do
    status 200
    if params['revoke'] == "true"
      revoke = true
    else
      revoke = false
    end
    HOSTEX.synchronize do
      host = Host.first(:hostname => params['hostname'])
      host.delete(revoke)
    end
    hostlist = '/hosts/overview'
    redirect to hostlist
  end

  post '/host/reboot' do
    host = Host.first(:hostname => params['hostname'])
    host.reboot
    hostlist = '/hosts/overview'
    redirect to hostlist
  end

  post '/host/add-var' do
    status 200
    HOSTEX.synchronize do
      host = Host.first(:hostname => params['hostname'])
      host.add_var(params['var_name'], params['value'])
    end
    redir = '/host/'+params['hostname']
    redirect to redir
  end

  post '/host/del-var' do
    status 200
    HOSTEX.synchronize do
      host = Host.first(:hostname => params['hostname'])
      host.del_var(params['var_name'])
    end
    redir = '/host/'+params['hostname']
    redirect to redir
  end

  post '/host/edit' do
    HOSTEX.synchronize do
      oldhost = Host.first(:hostname => params['old_hostname'])
      newhost = Host.create(:hostname => params['hostname'],
                            :ip => params['ip'],
                            :ssh_port => params['ssh_port'],
                            :user => oldhost.user,
                            :dist => oldhost.dist,
                            :dist_ver => oldhost.dist_ver,
                            :arch => oldhost.arch,
                            :pkg_mgr => oldhost.pkg_mgr,
                            :monit_pw => oldhost.monit_pw,
                            :opt_vars => oldhost.opt_vars,
                            :created_at => oldhost.created_at)
      oldhost.hostgroups.each do |group|
        group.add_member(newhost)
      end
      oldhost.delete(false)
    end
    redir = '/host/'+params['hostname']
    redirect to redir
  end
end
