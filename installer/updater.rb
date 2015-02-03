class ASYD < Sinatra::Application
  get '/confirm_update' do
    if !session[:username] then
      redirect '/login'
    end
    Updater.update
    redirect to '/'
  end

  get '/update' do
    if !session[:username] then
      redirect '/login'
    end
    @actions = Updater.update_actions
    erb :updater
  end
end

module Updater
  def self.update
    actions = update_actions
    actions.each do |action|
      if action == "update_monit"
        FileUtils.mv("installer/monit/def", "data/deploys/monit/def")
        FileUtils.mv("installer/monit/def.sudo", "data/deploys/monit/def.sudo")
      elsif action == "update_monitored_status"
        hosts = Host.all(:monitored => true)
        hosts.each do |host|
          host.add_var("monitored", "1")
          host.monitored = false
          host.save
        end
      end
    end
    remove_installer_dir
  end

  def self.update_actions
    actions = Array.new # Array for defining actions

    #-#-#
    # Check for monit deploy version
    old_version = nil
    path = "data/deploys/monit/def" # the old def file
    f = File.open(path, "r").read
    f.gsub!(/\r\n?/, "\n")
    f.each_line do |line|
      if !line.match(/^# ?version:/i).nil?
        old_version = line.gsub!(/^# ?version:/i, "").strip
      end
    end
    new_version = nil
    path = "installer/monit/def" # the new def file
    f = File.open(path, "r").read
    f.gsub!(/\r\n?/, "\n")
    f.each_line do |line|
      if !line.match(/^# ?version:/i).nil?
        new_version = line.gsub!(/^# ?version:/i, "").strip
      end
    end
    if old_version.nil? or old_version.to_f < new_version.to_f then
      actions << "update_monit"
    end
    #-#-#

    #-#-#
    # Migration from old host.monitored to new "monitored" opt_var
    hosts = Host.all(:monitored => true)
    if hosts.length > 0
      actions << "update_monitored_status"
    end
    #-#-#

    return actions
  end

  def self.remove_installer_dir
    FileUtils.remove_dir("installer")
  end
end
