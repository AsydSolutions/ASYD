module Monitoring

  module Hostgroup
    def members_status
      stat = {}
      stat[:total] = self.hosts.count
      stat[:warning] = 0
      stat[:critical] = 0
      stat[:sane] = 0
      if stat[:total] == 0
        return stat
      else
        self.hosts.each do |host|
          ret = host.is_ok?
          if ret == 2
            stat[:warning] = stat[:warning] + 1
          elsif ret == 3
            stat[:critical] = stat[:critical] + 1
          end
        end
        stat[:sane] = stat[:total] - stat[:warning] - stat[:critical]
        return stat
      end
    end
  end
  
end
