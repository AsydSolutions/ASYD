class ASYD < Sinatra::Application
  before /^(\/user|team)/ do
    unless user.is_admin?
      redirect "/"
    end
  end

  get '/users' do
    @users = User.all
    @teams = Team.all
    erb :'user/users_overview'
  end

  post '/user/add' do
    User.new(params['username'], params['email'], params['password'])
    userlist = '/users'
    redirect to userlist
  end

  post '/user/edit' do
    user = User.first(:username => params['username'])
    if params['email'] != ""
      user.update(:email => params['email'])
    end
    if params['password'] != ""
      enc_pw = BCrypt::Password.create(params['password'])
      user.update(:password => enc_pw)
    end
    userlist = '/users'
    redirect to userlist
  end

  post '/user/del' do
    user = User.first(:username => params['username'])
    user.team_members.all.destroy
    user.reload
    user.destroy
    userlist = '/users'
    redirect to userlist
  end

  post '/team/add' do
    Team.create(:name => params['name'])
    userlist = '/users'
    redirect to userlist
  end

  get '/team/edit/:team' do
    @team = Team.first(:name => params[:team])
    erb :'user/edit_team', :layout => false
  end

  post '/team/edit' do  ## TODO
    team = Team.first(:name => params['name'])
    userlist = '/users'
    redirect to userlist
  end

  post '/team/add-member' do
    team = Team.first(:name => params['team'])
    user = User.first(:username => params['username'])
    team.add_member(user)
  end

  post '/team/del-member' do
    team = Team.first(:name => params['team'])
    user = User.first(:username => params['username'])
    team.del_member(user)
  end

  post '/team/del' do
    team = Team.first(:name => params['name'])
    team.team_members.all.destroy
    team.reload
    team.destroy
    userlist = '/users'
    redirect to userlist
  end

  get "/password/request" do
    erb :'user/password_request', :layout => false
  end

  post "/password/request" do
    email = params['email'].downcase
    un = User.first(:email => email)
    if !un.nil?
      elapsed_time = Time.now - un.updated_at
      if ( elapsed_time.to_s.to_i > 300 )
        newtoken = SecureRandom.urlsafe_base64
        un.update(:token => newtoken)
        base_url = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
        reset_path = "#{base_url}/password/reset/#{newtoken}"
        Email.mail(email, "Password recovery", "Hello #{un.username},\nClick to Reset Your Password:\n #{reset_path}")
        un.updated_at = Time.now
        un.save
        un.reload
        erb "An email was sent to #{params[:email]} to recover your password."
      else
        erb "<div class='alert alert-error'>"+t('token.wait')+"</div>"
      end
    else
      erb "<div class='alert alert-error'>"+t('error.email.invalid')+"</div>"
    end
  end

  get "/password/reset/:token" do
    if !params[:token].nil?
      un = User.first(:token => (params['token']))
      if !un.nil?
        erb :'user/password_reset', :layout => false, :locals => {:token => params['token']}
      else
        erb "<div class='alert alert-error'>"+t('token.invalid') + params['token'] +"</div>"
      end
    else
      halt 401
    end
  end

  post "/password/reset" do
    if !params['token'].nil?
      un = User.first(:token => (params['token']) )
      if !un.nil?
        if un.username == params['username']
          if params['confirm_password'] == params['password']
            encpw = BCrypt::Password.create(params['password'])
            un.password = encpw
          else
            erb t('password.match')
          end
        else
          halt 403
        end
        un.token = nil
        un.updated_at = Time.now
        un.save
        un.reload
        redirect '/'
      else
        erb "<div class='alert alert-error'>"+t('token.invalid')+"</div>"
      end
    else
      halt 401
    end
  end

  get "/password/change" do
    erb :'user/password_change'
  end

  post "/password/change" do
    un = User.first(:username => (session[:username]))
    if un.password == params['password']
      if params['new_password'] == params['confirm_password']
        un.password = BCrypt::Password.create(params['new_password'])
        un.updated_at = Time.now
        un.save
        un.reload()
        erb "<div class='alert alert-info'>"+t('action.saved')+"</div>"
      else
        erb "<div class='alert alert-error'>"+t('password.match')+"</div>"
      end
    else
      erb "<div class='alert alert-error'>"+t('password.wrong')+"</div>"
    end
  end

  get "/users/:user/notifications/:action" do
    user = User.first(:username => params[:user])
    if params[:action] == "enable"
      user.receive_notifications = true
      user.save
    elsif params[:action] == "disable"
      user.receive_notifications = false
      user.save
    end
    redirect to '/users'
  end

end
