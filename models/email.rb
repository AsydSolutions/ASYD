class Email
  include DataMapper::Resource

  def self.default_repository_name #here we use the hosts_db for the Host objects
   :config_db
  end

  property :_id, Integer, :default => 1, :key => true  # we just store one object, but key property is needed
  property :method, Enum[ :sendmail, :smtp ], :default => :sendmail
  property :path, String, :default => "/usr/sbin/sendmail"
  property :host, String, :default => "localhost"
  property :port, String, :default => "587"
  property :tls, Boolean, :default => true
  property :user, String
  property :password, String

  if Email.all.first.nil?
    Email.create
  end

  def initialize(_to, _subject, _body)
    begin
      cfg = Email.all.first
      mail = Mail.new do
        to _to
        from cfg.user
        subject _subject
        text_part do
          body _body
        end
      end
      if cfg.method == :smtp
        mail.delivery_method :smtp, address: cfg.host, port: cfg.port.to_i, user_name: cfg.user, password: cfg.password, authentication: 'plain', enable_starttls_auto: cfg.tls
        mail.deliver!
      elsif cfg.method == :sendmail
        mail.delivery_method :sendmail, :location => cfg.path
        mail.deliver!
      end
    rescue
      return false
    end
  end

  def edit(method, data)
    if method == "sendmail"

    elsif method == "smtp"

    end
  end
end
