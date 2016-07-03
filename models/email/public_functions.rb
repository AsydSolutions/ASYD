class Email

  def self.mail(to_, subject_, body_)
    begin
      cfg = Email.all.first
      if cfg.method != :exchange
        mail = Mail.new do
          to to_
          from cfg.user if cfg.method == :smtp
          smtp_envelope_from 'notification-mailer@asyd.eu' if cfg.method == :sendmail
          subject subject_
          text_part do
            body body_
          end
        end
        if cfg.method == :smtp
          mail.raise_delivery_errors = true
          # setting open_ssl_verify_mode to true, makes mail to use the SSL, if it's valid or self-signed
          # Maybe, in future we should verify it, but the info is a bit obscure: http://www.rubydoc.info/github/meskyanichi/backup/Backup/Notifier/Mail#openssl_verify_mode-instance_method
          mail.delivery_method :smtp, address: cfg.host, port: cfg.port.to_i, user_name: cfg.user, password: cfg.password, authentication: 'plain', enable_starttls_auto: cfg.tls, return_response: true, openssl_verify_mode: "none"
          mail.deliver!

        elsif cfg.method == :sendmail
          mail.delivery_method :sendmail, :location => cfg.path
          mail.deliver!
        end
      elsif cfg.method == :exchange
        if Gem::Specification::find_all_by_name('viewpoint').any?
          require 'viewpoint'
          endpoint = cfg.host
          ews_user = cfg.user
          ews_pass = cfg.password
          ews_cli = Viewpoint::EWSClient.new endpoint, ews_user, ews_pass
          ews_cli.send_message subject: subject_, body: body_, to_recipients: [ to_ ]
        end
      end
    rescue *SMTP_ERRORS => e
      NOTEX.synchronize do
        Notification.create(:type => :error, :sticky => false, :message => "Email error: "+e.message)
      end
      return false
    rescue *SSL_ERRORS => e
      NOTEX.synchronize do
        Notification.create(:type => :error, :sticky => false, :message => "Email error: "+e.message)
      end
      return false
    rescue => e
      NOTEX.synchronize do
        Notification.create(:type => :error, :sticky => false, :message => "Email error: "+e.message)
      end
      return false
    end
  end
end
