# dev hint: shotgun login.rb

require 'rubygems'
require 'sinatra'
require 'sqlite3'
load 'inc/lib/spork.rb'
load 'inc/helper.rb'
load 'inc/setup.rb'
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
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

# Check if ASYD was installed
before /^(?!\/(setup))/ do
  if !File.directory? 'data'
    redirect '/setup'
  end
end

# Dashboard
get '/' do
  erb "- Dashboard -"
end

## SERVERS BLOCK START
get '/server/list' do
  @hosts = get_server_list
  erb :serverlist
end

get '/server/:host' do
  @status = get_host_status(params[:host])
  @data = get_host_data(params[:host])
  erb :hostdetail
end

post '/server/add' do
  srv_init(params['name'], params['host'], params['password'])
  serverlist = '/server/list'
  redirect to serverlist
end

post '/server/del' do
  if params['revoke'] == "true"
    revoke = true
  else
    revoke = false
  end
  remove_server(params['host'], revoke)
  serverlist = '/server/list'
  redirect to serverlist
end
## SERVERS BLOCK END

## HOST GROUPS START
get '/groups/list' do
  @groups = get_hostgroup_list
  erb :grouplist
end

get '/groups/:group' do
  @group = params[:group]
  @members = get_group_members(params[:group])
  erb :groupdetail
end

post '/groups/edit' do
  if params[:action] == "add_member" || params[:action] == "del_member"
    redir = '/groups/'+params[:params][:group]
  else
    redir = '/groups/list'
  end
  groups_edit(params[:action], params[:params])
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

post '/deploys/install-pkg' do
  inst = Spork.spork do
    install_pkg(params['host'],params['package'],false)
  end
  deploys = '/deploys/list'
  redirect to deploys
end

get '/deploys/deploy/:target/:dep' do
  target = params[:target].split(";")
  if target[0] == "host"
    inst = Spork.spork do
    # inst = Thread.fork do #debug
      deploy(target[1], params[:dep],false)
    end
    # inst.join #debug
  end
  if target[0] == "group"
    inst = Spork.spork do
      group_deploy(target[1], params[:dep])
    end
  end
  deploys = '/deploys/list'
  redirect to deploys
end
## DEPLOYS BLOCK END

## TASKS BLOCK START
get '/tasks/:id' do
  activity = SQLite3::Database.new "data/db/activity.db"
  @task = activity.get_first_row("select id,action,target,status,created from activity where id=?", params[:id].to_i)
  notifications = SQLite3::Database.new "data/db/notifications.db"
  @alerts = notifications.execute("select message,created from notifications where task_id=?", params[:id].to_i)
  erb :taskdetail
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
  @vars = "<%ASYD%> - ASYD IP\n <%HOSTNAME%> - Target host name\n <%IP%> - Target host IP\n <%DIST%> - Target host linux distribution\n <%DIST_VER%> - Target host distribution version\n <%ARCH%> - Target host architecture\n <%MONITOR:service%> - Monitors the service 'service'"
  erb :help
end
## HELP BLOCK END

## SETUP START
get '/setup' do
  erb :setup
end

post '/setup' do
  home = '/'
  if File.directory? 'data'
    redirect to home
  else
    if params['generate'] == '1'
      if params['password'] == ""
        @error = 'Password required'
        halt erb(:setup)
      end
      setup(params['password'])
    else
      if params[:priv_key].nil? || params[:pub_key].nil?
        @error = 'All files required'
        halt erb(:setup)
      end
      setup(params[:priv_key], params[:pub_key])
    end
  end
  redirect to home
end
## SETUP END

get '/test' do
  ret = check_condition([0, "<%DIST%> == centos or <%DIST_VER%> == 6 and <%DIST%> == debian"], "localhost")
  p ret
end



before '/secure/*' do
  if !session[:identity] then
    session[:previous_url] = request['REQUEST_PATH']
    @error = 'Sorry guacamole, you need to be logged in to do that'
    halt erb(:login_form)
  end
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb "This is a secret place that only <%=session[:identity]%> has access to!"
end
