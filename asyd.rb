# dev hint: shotgun login.rb

require 'rubygems'
require 'sinatra'
load 'inc/helper.rb'
load 'inc/setup.rb'
load 'inc/server.rb'
load 'inc/monitor.rb'

if File.directory? 'data'
  monitor_all
end

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


if File.directory? 'data'

get '/' do
    erb "- Dashboard -"
end

get '/server/list' do
  @arr = get_dirs("data/servers/")
  erb :serverlist
end

get '/server/:name' do
  f = File.open("data/servers/"+params[:name]+"/srv.info", "r")
  @host = f.gets
  @var_name = "$up_"+params[:name]
  erb 'Hostname for <%=params[:name]%> is <%=@host%>, uptime: <%=eval("#{@var_name}")%>'
end

post '/server/add' do
  srv_init(params['name'], params['host'], params['password'])
  monitor(params['name'])
  serverlist = '/server/list'
  redirect to serverlist 
end

# if not data show setup
else
get '*' do
  erb :setup
end
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
