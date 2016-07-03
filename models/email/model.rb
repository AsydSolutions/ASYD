class Email
  include DataMapper::Resource


  SMTP_ERRORS = [Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
                 Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
                 Errno::ECONNREFUSED, Net::SMTPSyntaxError, Net::SMTPFatalError]

  SSL_ERRORS = [OpenSSL::SSL::SSLError]

  def self.default_repository_name #here we use the hosts_db for the Host objects
   :config_db
  end

  property :_id, Integer, :default => 1, :key => true  # we just store one object, but key property is needed
  property :method, Enum[ :sendmail, :smtp, :exchange ], :default => :sendmail
  property :path, String, :default => "/usr/sbin/sendmail"
  property :host, String, :default => "localhost"
  property :port, String, :default => "587", :length => 5
  property :tls, Boolean, :default => true
  property :user, String
  property :password, String, :length => 100
end
