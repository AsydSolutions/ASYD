class ASYD < Sinatra::Application
  get '/users' do
    @users = User.all
    @teams = Team.all
    erb :users_overview
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
    erb :edit_team, :layout => false
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
end
