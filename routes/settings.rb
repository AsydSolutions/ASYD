class ASYD < Sinatra::Application
  get '/settings' do
    if user.is_admin?
      cfg = Email.first_or_create
      @method = cfg.method
      @path = cfg.path
      @host = cfg.host
      @port = cfg.port
      @tls = cfg.tls
      @user = cfg.user ? cfg.user : ""
      @password = cfg.password ? cfg.password : ""
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
      end
      cfg.save
      redirect to "/settings"
    else
      not_found
    end
  end
end
