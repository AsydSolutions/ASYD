class ASYD < Sinatra::Application
  get '/login' do
    status 200
    if !File.directory? 'data'
      redirect '/setup'
    end
    erb :'user/login', :layout => false
  end

  post '/login' do
    status 200
    u = User.auth(params['username'], params['password'])
    if u
      session[:username] = u.username
      redirect '/'
    else
      @error = "Failed login"
      erb :'user/login', :layout => false
    end
  end

  get '/logout' do
    status 200
    session.delete(:username)
    erb "<div class='alert alert-message'>Logged out</div>"
  end
end
