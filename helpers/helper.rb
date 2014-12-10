helpers do

   def user
     if session[:username]
       User.first(:username => session[:username])
     else
      nil
    end
  end
  
  def protected!
    if session[:username]
      un = User.first(:username => session[:username])
    else
      halt 401
    end
  end

  def dangerzone!
    if session[:username]
      un = User.first(:username => session[:username])
      if !un.is_admin?
        halt 403
      end
    else
      halt 401
    end
  end


end

