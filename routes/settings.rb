class ASYD < Sinatra::Application
  get '/settings' do
    dangerzone!
    cfg = Email.first_or_create
    @method = cfg.method
    @path = cfg.path
    @host = cfg.host
    @port = cfg.port
    @tls = cfg.tls
    @user = cfg.user ? cfg.user : ""
    @password = cfg.password ? cfg.password : ""
    erb :system_settings
  end

  post '/settings/email' do
    dangerzone!
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
  end
end
