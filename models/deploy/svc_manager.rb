class Deploy
  include Misc

  # Perform actions on target services
  #
  def self.manage_service(host, action, services, dry_run)
    begin
      svc_mgr = host.svc_mgr
      services = services.split(' ')
      result = ''
      services.each do |service|
        sudo = ""
        sudo = "sudo " if host.user != "root"
        if svc_mgr == "systemctl"
          case action
          when "enable"
            cmd = sudo+svc_mgr+" enable "+service
          when "disable"
            cmd = sudo+svc_mgr+" disable "+service
          when "start"
            cmd = sudo+svc_mgr+" start "+service
          when "stop"
            cmd = sudo+svc_mgr+" stop "+service
          when "restart"
            cmd = sudo+svc_mgr+" restart "+service
          else
            raise FormatException, "Action "+action+" not valid"
          end
        elsif svc_mgr == "update-rc.d"
          case action
          when "enable"
            cmd = sudo+svc_mgr+" "+service+" enable"
          when "disable"
            cmd = sudo+svc_mgr+" "+service+" disable"
          when "start"
            svc_mgr = "service"
            cmd = sudo+svc_mgr+" "+service+" start"
          when "stop"
            svc_mgr = "service"
            cmd = sudo+svc_mgr+" "+service+" stop"
          when "restart"
            svc_mgr = "service"
            cmd = sudo+svc_mgr+" "+service+" restart"
          else
            raise FormatException, "Action "+action+" not valid"
          end
        elsif svc_mgr == "chkconfig"
          case action
          when "enable"
            cmd = sudo+svc_mgr+" "+service+" on"
          when "disable"
            cmd = sudo+svc_mgr+" "+service+" off"
          when "start"
            svc_mgr = "service"
            cmd = sudo+svc_mgr+" "+service+" start"
          when "stop"
            svc_mgr = "service"
            cmd = sudo+svc_mgr+" "+service+" stop"
          when "restart"
            svc_mgr = "service"
            cmd = sudo+svc_mgr+" "+service+" restart"
          else
            raise FormatException, "Action "+action+" not valid"
          end
        elsif svc_mgr == "rc.d"
          case action
          when "enable"
            cmd = [sudo+"mv /etc/rc.conf.local /tmp/rc.conf.local",
                    sudo+"chmod 777 /tmp/rc.conf.local",
                    "echo 'pkg_scripts=\"$pkg_scripts "+service+"\"' >> /tmp/rc.conf.local",
                    sudo+"chmod 644 /tmp/rc.conf.local",
                    sudo+"sh -c 'uniq /tmp/rc.conf.local > /etc/rc.conf.local'"]
            cmd = cmd.join("; ")
          when "disable"
            cmd = [sudo+"sh -c \"sed '/"+service+"/d' /etc/rc.conf.local > /tmp/rc.conf.local\"",
                    sudo+"mv /tmp/rc.conf.local /etc/rc.conf.local"]
            cmd = cmd.join("; ")
          when "start"
            cmd = "/etc/rc.d/"
            cmd = sudo+cmd+service+" start"
          when "stop"
            cmd = "/etc/rc.d/"
            cmd = sudo+cmd+service+" stop"
          when "restart"
            cmd = "/etc/rc.d/"
            cmd = sudo+cmd+service+" restart"
          else
            raise FormatException, "Action "+action+" not valid"
          end
        elsif svc_mgr == "runit"
          case action
          when "enable"
            cmd = sudo + "ln -s /etc/sv/" + service + " /var/service/" + service
          when "start"
            cmd = sudo + "sv start" + service
          when "stop"
            cmd = [sudo + "sv stop " + service]
          when "disable"
            cmd = sudo + "rm /var/services/" + service
          when "restart"
            cmd = sudo + "sv restart " + service
          else
            raise FormatException, "Action "+action+" not valid"
          end
        elsif svc_mgr == "service"
          case action
          when "enable"
            cmd = "echo '"+ service + "_enable=\"yes\"' > /tmp/rc-" + service + " && " + sudo + "mv /tmp/rc-" + service + "  /etc/rc.conf.d/" + service
          when "start"
            cmd = "if [ -f /etc/rc.conf.d/"+service + " ] ; then " + sudo + "service " + service + " start; else " + sudo + "service + " + service + " onestart; fi"
          when "stop"
            cmd = "if [ -f /etc/rc.conf.d/"+service + " ] ; then " + sudo + "service " + service + " stop; else " + sudo + "service + " + service + " onestop; fi"
          when "disable"
            cmd = sudo + " rm -f /etc/rc.conf.d/"+service
          when "restart"
            cmd = "if [ -f /etc/rc.conf.d/"+service + " ] ; then " + sudo + "service " + service + " restart; else " + sudo + "service + " + service + " onerestart; fi"
          else
            raise FormatException, "Action "+action+" not valid"
          end
        elsif svc_mgr == "launchd"
          case action
          when "enable"
            cmd = "launchctl load /Library/LaunchDaemons/" + service
          when "start"
            cmd = "launchctl load -w /Library/LaunchDaemons/" + service
          when "stop"
            cmd = "launchctl unload /Library/LaunchDaemons/" + service
          when "disable"
            cmd = "launchctl unload -w /Library/LaunchDaemons/" + service
          when "restart"
            cmd = "launchctl unload -w /Library/LaunchDaemons/" + service + " && " + "launchctl load -w /Library/LaunchDaemons/" + service
          else
            raise FormatException, "Action "+action+" not valid"
          end
        else
          raise FormatException, "Host "+host.hostname+" doesn't support the 'service' command"
        end
        ret = host.exec_cmd(cmd) unless dry_run
        result = result+ret+";;\n" unless ret.nil?
      end
      unless dry_run
        return [1, result]
      else
        return [0, ""]
      end
    rescue FormatException => e
      return [5, e.message]
    rescue => e
      error = "Something really bad happened when "+action+"'ing "+services.join(" ").to_s+" on "+host.hostname+": "+e.message
      return [4, error]
    end
  end

end
