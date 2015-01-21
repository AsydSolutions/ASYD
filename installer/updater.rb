class ASYD < Sinatra::Application
  get '/confirm_update' do
    include Updater

    Updater.update
    redirect to '/'
  end
end

module Updater
  def self.update
    actions = update_actions
    actions.each do |action|
      if action == "update_monit"
        FileUtils.mv("installer/monit/def", "data/deploys/monit/def")
        FileUtils.mv("installer/monit/def.sudo", "data/deploys/monit/def.sudo")
      end
    end
    remove_installer_dir
  end

  def self.update_actions
    actions = Array.new # Array for defining actions

    #-#-#
    # Check for monit deploy version
    path = "data/deploys/monit/def" # the old def file
    f = File.open(path, "r").read
    f.gsub!(/\r\n?/, "\n")
    f.each_line do |line|
      if !line.match(/^# ?version:/i).nil?
        old_version = line.gsub!(/^# ?version:/i, "").strip
      end
    end
    path = "installer/monit/def" # the new def file
    f = File.open(path, "r").read
    f.gsub!(/\r\n?/, "\n")
    f.each_line do |line|
      if !line.match(/^# ?version:/i).nil?
        new_version = line.gsub!(/^# ?version:/i, "").strip
      end
    end
    if old_version.nil? || Gem::Version.new(old_version) < Gem::Version.new(new_version)
      actions << "update_monit"
    end
    #-#-#

    return actions
  end

  def self.remove_installer_dir
    FileUtils.remove_dir("installer")
  end
end
