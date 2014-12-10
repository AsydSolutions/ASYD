class ASYD < Sinatra::Application
  get '/setup' do
    if File.directory? 'data'
      #redirect to home
      halt 404
    else
      erb :setup, :layout => false
    end
  end

  post '/setup' do
    if File.directory? 'data'
      halt 404
    else
      if params['password'].empty? || params['username'].empty? || params['email'].empty?
        @error = 'All fields required'
        halt erb(:setup)
      end
      if params['generate'] == '1'
        Setup.new()
      else
        if params[:priv_key].nil? || params[:pub_key].nil?
          @error = 'All files required'
          halt erb(:setup)
        end
        Setup.new(params[:priv_key], params[:pub_key])
      end
      user = User.new(params['username'], params['email'], params['password'])
      admins = Team.new(:name => "admins", :capabilities => :admin)
      admins.add_member(user)
    end
    redirect to home
  end
end
