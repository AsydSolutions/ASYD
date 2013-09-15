# dev hint: shotgun login.rb

require 'rubygems'
require 'sinatra'
load 'inc/helper.rb'
load 'inc/setup.rb'
load 'inc/server.rb'
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

def alerts
  if $error
    p $error
    @error = $error
    $error = nil
  end
  if $info
    p $info
    @info = $info
    $info = nil
  end
  if $done
    p $done
    @done = $done
    $done = nil
  end
end

before /^(?!\/(setup))/ do
  if !File.directory? 'data'
    redirect '/setup'
  end
end

get '/' do
  alerts
  erb "- Dashboard -"
end

## SERVERS BLOCK START
get '/server/list' do
  @hosts = get_dirs("data/servers/")
  alerts
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
  if @error
    $error = @error
  end
  redirect to serverlist
end
## SERVERS BLOCK END

## DEPLOYS BLOCK START
get '/deploys/list' do
  @deploys = get_dirs("data/deploys/")
  @hosts = get_dirs("data/servers/")
  alerts
  erb :deploys
end

post '/deploys/install-pkg' do
  inst = Thread.fork do
    install_pkg(params['host'],params['package'])
  end
  sleep 0.2
  if not $error
    $info = "Installation in progress"
  end
  deploys = '/deploys/list'
  redirect to deploys
end

get '/deploys/deploy/:host/:dep' do
  inst = Thread.fork do
    deploy(params[:host], params[:dep])
  end
  sleep 0.2
  if not $error
    $info = "Deployment in progress"
  end
  deploys = '/deploys/list'
  redirect to deploys
end
## DEPLOYS BLOCK END

## HELP BLOCK START
get '/help' do
  alerts
  erb :help
end
## HELP BLOCK END

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
