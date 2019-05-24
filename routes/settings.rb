class ASYD < Sinatra::Application
  get '/settings' do
    if user.is_admin?
      git = File.file?('data/git_settings') ? JSON.parse(File.read('data/git_settings')) : {}
      @git_url = git['url'].nil? ? "" : git['url']
      @git_branch = git['branch'].nil? ? "master" : git['branch']
      @git_path = git['path'].nil? ? "/" : git['path']
      @git_ssh_key = git['ssh_key'].nil? ? "" : git['ssh_key']
      cfg = Email.first_or_create
      @method = cfg.method
      @path = cfg.path
      @host = cfg.host
      @port = cfg.port
      @tls = cfg.tls
      @user = cfg.user ? cfg.user : ""
      @password = cfg.password ? cfg.password : ""
      @disclaimer = false
      if !Gem::Specification::find_all_by_name('viewpoint').any?
        @disclaimer = true
      end
      @pub_key = File.read('data/ssh_key.pub')
      erb :'system/system_settings'
    else
      not_found
    end
  end

  post '/settings/email' do
    if user.is_admin?
      cfg = Email.all.first
      if params['method'] == "sendmail"
        cfg.method = :sendmail
        cfg.path = params['path']
      elsif params['method'] == "smtp"
        cfg.method = :smtp
        cfg.host = params['host']
        cfg.port = params['port']
        if params['tls'].nil?
          cfg.tls = false
        else
          cfg.tls = true
        end
        cfg.user = params['user']
        cfg.password = params['password']
      elsif params['method'] == "exchange"
        cfg.method = :exchange
        cfg.host = params['host']
        cfg.user = params['user']
        cfg.password = params['password']
      end
      cfg.save
      redirect to "/settings"
    else
      not_found
    end
  end

  post '/settings/ssh-keys' do
    if user.is_admin?
      File.open('data/ssh_key', "w") do |f|
        f.write(params[:priv_key][:tempfile].read)
      end
      File.open('data/ssh_key.pub', "w") do |f|
        f.write(params[:pub_key][:tempfile].read)
      end
      redirect to "/settings"
    else
      not_found
    end
  end

  post '/settings/git' do
    git_settings = {'url' => params['git_url'], 'path' => params['git_path'], 'branch' => params['git_branch']}
    git_settings['ssh_key'] = params['git_ssh_key'].nil? ? "" : params['git_ssh_key']
    File.open('data/git_settings', "w") do |f|
        f.write(git_settings.to_json)
    end
    redirect to "/settings"    
  end

  get '/settings/user' do
    erb :'user/settings'
  end

  post '/settings/user' do
    user.update(:email => params["email"])
    if params.has_key?('notifications')
      user.update(:receive_notifications => true)
    else
      user.update(:receive_notifications => false)
    end
    redirect to "/settings/user"
  end
end
