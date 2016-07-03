module Monitoring

  def self.notify_by_mail(subject, msg)
    users = User.all(:receive_notifications => true)
    users.each do |user|
      Email.mail(user.email, subject, msg)
    end unless users.nil?
  end
end

class Monitor
  # Return a list of monitors
  #
  def self.all
    monitors = Misc::get_files("data/monitors/").sort_by{|entry| entry.downcase}
    return monitors
  end

  # Delete a monitor
  #
  def self.delete(monitor)
    path='data/monitors/'+monitor
    FileUtils.rm_r path, :secure=>true
  end
end
