class ASYD < Sinatra::Application
  get '/login' do
    if !File.directory? 'data'
      redirect '/setup'
    end
    if session[:username].blank?
      erb :login, :layout => false
    else
      redirect '/'
    end
  end

  post '/login' do
    if session[:username].blank?
      u = User.auth(params['username'], params['password'])
      if u
        session[:username] = u.username
        redirect '/'
      else
        @error = "Failed login"
        erb :login, :layout => false
      end
    else
      redirect '/'
    end
  end

  get '/logout' do
    if !session[:username].blank?
      session.delete(:username)
      erb "<div class='alert alert-message'>Logged out</div>"
    else
      redirect '/login'
    end
  end
end
