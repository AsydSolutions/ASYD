class Host
  include Monitoring::Host

  def self.init(hostname, ip, user, ssh_port, password)
    begin
      host = Host.create(:hostname => hostname.strip)
      #set the parameters as object properties
      host.ip = ip
      host.user = user
      host.ssh_port = ssh_port
      #generate random monit password
      o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
      host.monit_pw = (0...8).map { o[rand(o.length)] }.join
      host.opt_vars = {} #initialize opt_vars as an empty hash
      #start connection to remote host
      Net::SSH.start(host.ip, host.user, :port => host.ssh_port, :keys => "data/ssh_key", :password => password, :timeout => 10, :user_known_hosts_file => "/dev/null", :compression => true, :number_of_password_prompts => 0) do |ssh|
        #check for admin capabilities/nopasswd
        if user != "root"
          need_passwd = false
          last = nil
          ssh.exec!("echo 1 > /tmp/1")
          ssh.open_channel do |channel|
            channel.request_pty do |ch, success|
              raise StandardError, "Could not obtain pty" unless success
            end
            channel.exec("sudo cat /tmp/1") do |ch, success|
              raise unless success
              channel.on_data do |ch, data|
                if data =~ /^\[sudo\] password/ || data =~ /^Password/
                  need_passwd = true
                  channel.send_data "#{password}\n"
                elsif data.strip == "1"
                  last = "1"
                end
              end
            end
          end
          ssh.loop
          unless last == "1"
            raise StandardError, "User has no admin privileges"
          end
          if need_passwd
            cmd = "if [ -f \"/etc/sudoers.d/#{user}\" ]; then sudo cp /etc/sudoers.d/#{user} /tmp/sudoers#{user}; fi; sudo sh -c 'mkdir /etc/sudoers.d &>/dev/null'; sudo sh -c 'chown root:wheel /etc/sudoers.d'; sudo sh -c 'chmod 755 /etc/sudoers.d' ; sudo sh -c 'echo \"Defaults:#{user} !requiretty\" >> /tmp/sudoers#{user}'; sudo sh -c 'echo \"#{user} ALL=NOPASSWD: ALL\" >> /tmp/sudoers#{user}'; sudo sh -c 'uniq /tmp/sudoers#{user} > /etc/sudoers.d/#{user}'; sudo sh -c 'chmod 440 /etc/sudoers.d/#{user}'; sudo rm /tmp/sudoers#{user}"
            ssh.open_channel do |channel|
              channel.request_pty do |ch, success|
                raise StandardError, "Could not obtain pty" unless success
              end
              channel.exec(cmd) do |ch, success|
                raise unless success
                channel.on_data do |ch, data|
                  if data =~ /^\[sudo\] password/ || data =~ /^Password/
                    channel.send_data "#{password}\n"
                  end
                end
              end
            end
            ssh.loop
          end
          ret = ssh.exec!("sudo cat /tmp/1") # first check
          unless ret.strip == "1"            # if this fails likely there's a requiretty on sudoers
            cmd = "sudo sed -i '/requiretty/d' /etc/sudoers"
            ssh.open_channel do |channel|
              channel.request_pty do |ch, success|
                raise StandardError, "Could not obtain pty" unless success
              end
              channel.exec(cmd) do |ch, success|
                raise unless success
                channel.on_data do |ch, data|
                  # NOPASSWD already in sudoers file
                end
              end
            end
            ssh.loop
          end
          ret = ssh.exec!("sudo cat /tmp/1") # second check
          raise StandardError, "User has no admin privileges, please add '#{user} ALL=NOPASSWD: ALL' to /etc/sudoers and try again" unless ret.strip == "1"
          ssh.exec!("rm /tmp/1")
        end
        #upload the ssh key
        ssh.scp.upload!("data/ssh_key.pub", "/tmp/ssh_key.pub")
        ssh.exec "mkdir -p $HOME/.ssh && touch $HOME/.ssh/authorized_keys && mv $HOME/.ssh/authorized_keys /tmp/authorized_keys && cat /tmp/ssh_key.pub >> /tmp/authorized_keys && uniq /tmp/authorized_keys > $HOME/.ssh/authorized_keys && chmod 755 $HOME/.ssh && chmod 700 $HOME/.ssh/authorized_keys && rm /tmp/ssh_key.pub && rm /tmp/authorized_keys"
      end

      ret = Host.detect(host)
      raise StandardError, ret[1] if ret[0] == 5
      if !host.save
        raise StandardError, "Couldn't save the host" #couldn't save the object
      end
      Spork.spork do #we fork the monitoring setup for saving time
        host.monitor()
      end
      NOTEX.synchronize do
        msg = "Monitoring setup for "+host.hostname+" in progress"
        Notification.create(:type => :info, :message => msg)
      end
      return host #return the object itself
    rescue Net::SSH::AuthenticationFailed
      NOTEX.synchronize do
        Notification.create(:type => :error, :sticky => false, :message => I18n.t('error.host.auth', host: hostname))
      end
      host.delete(false)
      return false
    rescue Errno::EHOSTUNREACH
      NOTEX.synchronize do
        Notification.create(:type => :error, :sticky => false, :message => I18n.t('error.host.unreach', host: hostname))
      end
      host.delete(false)
      return false
    rescue => e
      error = I18n.t('error.host.misc', host: hostname)+e.message
      NOTEX.synchronize do
        Notification.create(:type => :error, :sticky => false, :message => error)
      end
      host.delete(false) unless host.nil?
      return false
    end
  end

end
