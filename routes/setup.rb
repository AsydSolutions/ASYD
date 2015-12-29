class ASYD < Sinatra::Application
  get '/setup' do
    status 200
    home = '/'
    if File.directory? 'data'
      redirect to home
    else
      erb :'system/setup', :layout => false
    end
  end

  post '/setup' do
    status 200
    home = '/'
    if File.directory? 'data'
      redirect to home
    else
      if params['password'].empty? || params['username'].empty? || params['email'].empty?
        NOTEX.synchronize do
          Notification.create(:type => :error, :sticky => false, :message => 'All fields required')
        end
        halt erb(:'system/setup')
      end
      if params['generate'] == '1'
        Setup.new()
      else
        if params[:priv_key].nil? || params[:pub_key].nil?
          NOTEX.synchronize do
            Notification.create(:type => :error, :sticky => false, :message => 'All files required')
          end
          halt erb(:'system/setup')
        end
        Setup.new(params[:priv_key], params[:pub_key])
      end
      user = User.new(params['username'], params['email'], params['password'])
      admins = Team.new(:name => "admins", :capabilities => :admin)
      admins.add_member(user)
    end
    redirect to '/setup/finish'
  end

  get '/setup/finish' do
    Spork.spork do
      Process.setsid
      Spork.spork do
        sleep 1.5
        exec "./asyd.sh restart"
      end
      exit
    end
    erb 'Completing setup, please wait... <script> setTimeout(function () { window.location.href = "/"; }, 8000); </script>'
  end

  get '/upgrade' do
    redirect to '/' unless Setup.update_available?
    erb :'system/upgrade'
  end

  get '/confirm_upgrade' do
    Setup.one_click_update if Setup.update_available?
    erb 'Reloading, please wait... <script> setTimeout(function () { window.location.href = "/"; }, 5000); </script>'
  end

  get '/install/exchange' do
    Setup.one_click_install_exchange if !Gem::Specification::find_all_by_name('viewpoint').any?
    erb 'Reloading, please wait... <script> setTimeout(function () { window.location.href = "/settings"; }, 5000); </script>'
  end

  get '/api/ping' do
    'pong'
  end

end
