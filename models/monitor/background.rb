module Monitoring

  TTL = 30 #store/refresh the status for 30 seconds
  $mem_mail = ProcessShared::SharedMemory.new(2048)
  $mem_mail.write_object({})

  module Host
    include Misc

    def perform_monitoring_operations
      begin
        Timeout::timeout(5) do   # If it takes more than 5 seconds just kill it
          if self.opt_vars["monitored"].to_i == 1 #do things
            stat = self.get_status
            if stat == 3 #the host is down
              MNOTEX.synchronize do
                last = Monitoring::Notification.last(:host_hostname => self.hostname)
                notif = last
                if last.nil? #no previous notification
                  msg = "Unable to get monitoring status for host "+self.hostname
                  notif = Monitoring::Notification.create(:type => :error, :message => msg, :host_hostname => self.hostname, :service => "system")
                else
                  if last.acknowledge == false && last.dismiss == true #the last notification was already dismissed and is not acknowledged
                    msg = "Unable to get monitoring status for host "+self.hostname
                    notif = Monitoring::Notification.create(:type => :error, :message => msg, :host_hostname => self.hostname, :service => "system")
                  end
                end
                if last.nil? || last.acknowledge == false
                  errmail = $mem_mail.read_object
                  if errmail[self.hostname].nil?
                    errmail[self.hostname] = 1
                  else
                    if errmail[self.hostname] < -2
                      errmail[self.hostname] = 0
                    else
                      errmail[self.hostname] = errmail[self.hostname]+1
                    end
                  end
                  if errmail[self.hostname] == 2 #first email alert at second check (30 seconds since failure)
                    errmail[self.hostname] = -2 #then we set the counter to -2 so we get an email every minute
                    subject = "Critical: Host "+self.hostname+" Down"
                    msg = "Unable to get monitoring status for host "+self.hostname+"\n\n"
                    Monitoring.notify_by_mail(subject, msg)
                  end
                  $mem_mail.write_object(errmail)
                end
              end
            elsif stat == 2 #warning
              MNOTEX.synchronize do
                last = Monitoring::Notification.last(:host_hostname => self.hostname)
                if !last.nil?
                  last.update(:acknowledge => false, :dismiss => true)
                else
                  last = Monitoring::Notification.create(:type => :error, :message => msg, :dismiss => true, :host_hostname => self.hostname, :service => "misc")
                end
                errmail = $mem_mail.read_object
                if errmail[self.hostname].nil?
                  errmail[self.hostname] = 1
                else
                  errmail[self.hostname] = errmail[self.hostname]+1
                end
                if errmail[self.hostname] == 2 #first email alert at second check (30 seconds since failure)
                  errmail[self.hostname] = -18 #then we set the counter to -18 so the next email will arrive in 5 minutes
                  subject = "Warning: Check failed on Host "+self.hostname
                  msg = ""
                  status = Status.new(self, true)
                  unless status.system_status.nil? || status.system_status == 'down'
                    if status.system_status != 'ok'
                      msg = msg+"System: "+status.system_status+"\n\n"
                    end
                    status.services.each do |service|
                      if service[1] != 'ok' and service[1] != 'not monitored'
                        msg = msg+service[0]+": "+service[1]+"\n\n"
                      end
                    end unless status.services.nil?
                  end
                  Monitoring.notify_by_mail(subject, msg) unless msg.empty?
                end
                $mem_mail.write_object(errmail)
              end
            elsif stat == 1 #the host recovered?
              errmail = $mem_mail.read_object
              unless errmail[self.hostname].nil?
                errmail[self.hostname] = 0
                $mem_mail.write_object(errmail)
              end
              MNOTEX.synchronize do
                last = Monitoring::Notification.last(:host_hostname => self.hostname, :dismiss => false)
                if !last.nil?
                  last.update(:acknowledge => false, :dismiss => true)
                  subject = "Recovery: Host "+self.hostname+" Up"
                  msg = "The host "+self.hostname+" recovered"
                  Monitoring.notify_by_mail(subject, msg)
                end
              end
            end
          end
          return true
        end
      rescue => e
        return e.message
      end
    end
  end

  def self.background
    begin
      while true
        Timeout::timeout(60+TTL) do # Wait for 1 minute plus TTL, kill if executing takes more time
          max_forks = 15 #we hard limit the max checks to 15 at a time
          forks = [] #and initialize an empty array
          hosts = File.exist?("data/db/hosts.db") ? ::Host.all : nil
          unless hosts.nil? || hosts.empty?
            hosts.each do |host|
              if forks.count >= max_forks #if we reached the max forks
                forks2 = forks      # Ensure there's no completed forks on the fork list
                forks2.each do |pid|
                  forks.delete(pid) unless Misc::checkpid(pid)
                end
                if forks.count >= max_forks
                  id = Process.wait #then we wait for some child to finish
                  forks.delete(id) #and we remove it from the forks array
                end
              end
              frk = Spork.spork do #so we can continue executing a new fork
                ret = host.perform_monitoring_operations
                puts "Error when monitoring "+host.hostname+" on the background: "+ret if ret != true and $DBG == 1
              end
              forks << frk #and store the fork id on the forks array
            end
            Process.waitall
          end
          sleep TTL
          FileUtils.touch 'data/.monitoring.pid'
          Net::HTTP.get_response(URI.parse("http://localhost:#{$PORT}/api/ping"))
          Dmon::start('dmon') unless Dmon::check('dmon')
        end
      end
    rescue => e
      puts "Error on background monitoring: "+e.message if $DBG == 1
      exit unless Misc::checkpid($ASYD_PID)
      sleep TTL
      Dmon::start('monitoring')
    end
  end

end
