# Here we load all the application files
require 'rubygems'
require 'sinatra'
load 'inc/lib/spork.rb'
load 'inc/lib/subclassess.rb'
load 'inc/helper.rb'
load 'inc/setup.rb'
load 'inc/users.rb'
load 'inc/server.rb'
load 'inc/groups.rb'
load 'inc/monitor.rb'
load 'inc/deployer.rb'

configure do
  set :public_folder, Proc.new { File.join(root, "static") }
  #set :environment, :production
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : nil
  end
end

# Check if ASYD was installed or user is logged in before doing anything
before /^(?!\/(setup))(?!\/(login))/ do
  if !File.directory? 'data'
    redirect '/setup'
  else
    if !session[:identity] then
      redirect '/login'
    end
  end
end

# Dashboard
get '/' do
  erb "- Dashboard -"
end

## LOGIN/LOGOUT BLOCK START
get '/login' do
  if !File.directory? 'data'
    redirect '/setup'
  end
  erb :login
end

post '/login' do
  ret = auth_user(params['username'], params['password'])
  if ret
    session[:identity] = params['username']
    redirect '/'
  else
    @error = "Failed login"
    erb :login
  end
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end
## LOGIN/LOGOUT BLOCK END

## SERVERS BLOCK START
get '/servers/overiew' do
  @groups = get_hostgroup_list
  @hosts = get_server_list
  erb :servers_overiew
end

get '/server/:host' do
  @data = get_host_data(params[:host])
  if @data.nil?
    erb :oops
  else
    @status = get_host_status(params[:host])
    @opt_vars = @data[:opt_vars]
    erb :hostdetail
  end
end

post '/server/add' do
  srv_init(params['name'], params['host'], params['password'])
  serverlist = '/servers/overiew'
  redirect to serverlist
end

post '/server/del' do
  if params['revoke'] == "true"
    revoke = true
  else
    revoke = false
  end
  remove_server(params['host'], revoke)
  serverlist = '/servers/overiew'
  redirect to serverlist
end

post '/server/add-var' do
  add_host_var(params['host'], params['var_name'], params['value'])
  redir = '/server/'+params['host']
  redirect to redir
end

post '/server/del-var' do
  del_host_var(params['host'], params['var_name'])
  redir = '/server/'+params['host']
  redirect to redir
end
## SERVERS BLOCK END

## HOST GROUPS START
get '/groups/:group' do
  @group = params[:group]
  @members = get_group_members(params[:group])
  if @members.nil?
    erb :oops
  else
    @opt_vars = get_group_vars(params[:group])
    erb :groupdetail
  end
end

post '/groups/edit' do
  if params[:action] == "add_member" || params[:action] == "del_member"
    redir = '/groups/'+params[:params][:group]
  else
    redir = '/servers/overiew'
  end
  groups_edit(params[:action], params[:params])
  redirect to redir
end

post '/groups/add-var' do
  add_group_var(params['group'], params['var_name'], params['value'])
  redir = '/groups/'+params['group']
  redirect to redir
end

post '/groups/del-var' do
  del_group_var(params['group'], params['var_name'])
  redir = '/groups/'+params['group']
  redirect to redir
end
## HOST GROUPS END

## DEPLOYS BLOCK START
get '/deploys/list' do
  @deploys = get_dirs("data/deploys/")
  @hosts = get_server_list
  @groups = get_hostgroup_list
  erb :deploys
end

get '/deploys/:dep' do
  erb "-WIP-"
end

post '/deploys/install-pkg' do
  inst = Spork.spork do
    target = params['target'].split(";")
    if target[0] == "host"
      install_pkg(target[1],params['package'],false)
    elsif target[0] == "group"
      members = get_group_members(target[1])
      if !members.nil? && !members.empty?
        members.each do |host|
          install_pkg(host,params['package'],false)
        end
      end
    end
  end
  deploys = '/deploys/list'
  redirect to deploys
end

get '/deploys/deploy/:dep/:target' do  ##TODO: switch to POST
  target = params[:target].split(";")
  if target[0] == "host"
    # inst = Spork.spork do
    inst = Thread.fork do #debug
      deploy(target[1], params[:dep],false)
    end
    inst.join #debug
  end
  if target[0] == "group"
    inst = Spork.spork do
      group_deploy(target[1], params[:dep])
    end
  end
  deploys = '/deploys/list'
  redirect to deploys
end

post '/deploys/del' do
  del_deploy(params['deploy'])
  redir = '/deploys/list'
  redirect to redir
end
## DEPLOYS BLOCK END

## TASKS BLOCK START
get '/tasks/list' do
  erb "-WIP-"
end

get '/tasks/:id' do
  activity = SQLite3::Database.new "data/db/activity.db"
  @task = activity.get_first_row("select id,action,target,status,created from activity where id=?", params[:id].to_i)
  if @task.nil?
    erb :oops
  else
    notifications = SQLite3::Database.new "data/db/notifications.db"
    @alerts = notifications.execute("select message,created from notifications where task_id=?", params[:id].to_i)
    erb :taskdetail
  end
end
## TASKS BLOCK END

## NOTIFICATIONS BLOCK START
post '/notifications/dismiss' do
  notifications = SQLite3::Database.new "data/db/notifications.db"
  notifications.execute("UPDATE notifications SET dismiss=1 WHERE id=?", params['msg_id'])
  notifications.close
end
## NOTIFICATIONS BLOCK END

## HELP BLOCK START
get '/help' do
  erb :help
end
## HELP BLOCK END

## SETUP START
get '/setup' do
  home = '/'
  if File.directory? 'data'
    redirect to home
  else
    erb :setup, :layout => false
  end
end

post '/setup' do
  home = '/'
  if File.directory? 'data'
    redirect to home
  else
    if params['password'].empty? || params['username'].empty? || params['email'].empty?
      @error = 'All fields required'
      halt erb(:setup)
    end
    if params['generate'] == '1'
      setup()
    else
      if params[:priv_key].nil? || params[:pub_key].nil?
        @error = 'All files required'
        halt erb(:setup)
      end
      setup(params[:priv_key], params[:pub_key])
    end
    add_user(params['username'], params['email'], params['password'])
    add_team("admins")
    add_team_member("admins", params['username'])
  end
  redirect to home
end
## SETUP END

# 404 Error!
not_found do
  status 404
  erb :oops
end
