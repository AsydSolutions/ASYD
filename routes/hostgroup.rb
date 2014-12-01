class ASYD < Sinatra::Application
  get '/hostgroup/:hostgroup' do
    status 200
    @hostgroup = Hostgroup.first(:name => params[:hostgroup])
    @host_status = {}
    @hostgroup.hosts.each do |host|
      @host_status[host.hostname] = host.is_ok?
    end
    erb :hostgroup_detail
  end

  post '/hostgroup/add' do
    status 200
    Hostgroup.create(:name => params['hostgroup'])
    redirect to '/hosts/overview'
  end

  post '/hostgroup/del' do
    status 200
    hostgroup = Hostgroup.first(:name => params['hostgroup'])
    hostgroup.delete
    redirect to '/hosts/overview'
  end

  post '/hostgroup/add-member' do
    status 200
    hostgroup = Hostgroup.first(:name => params['hostgroup'])
    host = Host.first(:hostname => params['hostname'])
    hostgroup.add_member(host)
    redir = '/hostgroup/'+params['hostgroup']
    redirect to redir
  end

  post '/hostgroup/del-member' do
    status 200
    hostgroup = Hostgroup.first(:name => params['hostgroup'])
    host = Host.first(:hostname => params['hostname'])
    hostgroup.del_member(host)
    redir = '/hostgroup/'+params['hostgroup']
    redirect to redir
  end

  post '/hostgroup/add-var' do
    status 200
    hostgroup = Hostgroup.first(:name => params['hostgroup'])
    hostgroup.add_var(params['var_name'], params['value'])
    redir = '/hostgroup/'+params['hostgroup']
    redirect to redir
  end

  post '/hostgroup/del-var' do
    status 200
    hostgroup = Hostgroup.first(:name => params['hostgroup'])
    hostgroup.del_var(params['var_name'])
    redir = '/hostgroup/'+params['hostgroup']
    redirect to redir
  end

  post '/hostgroup/edit' do
    hostgroup = Hostgroup.first(:name => params['old_name'])
    members = Array.new
    hostgroup.hosts.each do |host|
      members << host
    end
    hostgroup.name = params['name']
    hostgroup.save
    redir = '/hostgroup/'+params['name']
    redirect to redir
  end
end
