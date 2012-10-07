# dev hint: shotgun login.rb

require 'rubygems'
require 'sinatra'
require 'pathname'
require 'find'
load 'src/server.rb'

configure do
  set :public_folder, Proc.new { File.join(root, "static") }
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end

  def get_dirs path
    dir_array = Array.new
    Pathname.new(path).children.select do |dir|
      dir_array << dir.basename
    end
    return dir_array
  end

  def get_files path
    files_array = Array.new
    Find.find(path) do |f|
      files_array << File.basename(f, "*")
    end
    return files_array
  end  
end

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'
end

get '/server/list' do
  @arr = get_dirs("data/servers/")
  erb :serverlist
end

get '/server/:name' do
  f = File.open("data/servers/"+params[:name]+"/srv.info", "r")
  @host = f.gets
  erb 'Hostname for <%=params[:name]%> is <%=@host%>'
end

post '/server/add' do
  srv_init(params['name'], params['host'], params['password'])
  serverlist = '/server/list'
  redirect to serverlist 
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
