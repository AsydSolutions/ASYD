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
    erb :'system/updater'
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
      elsif action == "populate_host_stats"
        repository(:stats_db).adapter.select('PRAGMA journal_mode = WAL')
        hosts = Host.all(:order => [ :created_at.asc ])
        hosts.each do |host|
          if HostStats.last.nil?
            t_hosts = 0
          else
            t_hosts = HostStats.last.total_hosts
          end
          stat = HostStats.first(:created_at => host.created_at.beginning_of_day)
          if !stat
            HostStats.create(:created_at => host.created_at.beginning_of_day, :total_hosts => t_hosts+1)
          else
            stat.total_hosts = stat.total_hosts + 1
            stat.save
          end
        end
      elsif action == "populate_task_stats"
        repository(:stats_db).adapter.select('PRAGMA journal_mode = WAL')
        tasks = Task.all(:order => [ :created_at.asc ])
        tasks.each do |task|
          stat = TaskStats.first(:created_at => task.created_at.beginning_of_day)
          if !stat
            stat = TaskStats.create(:created_at => task.created_at.beginning_of_day)
          end
          stat.started_tasks = stat.started_tasks + 1
          stat.completed_tasks = stat.completed_tasks + 1 if task.status == :finished
          stat.failed_tasks = stat.failed_tasks + 1 if task.status == :failed
          stat.save
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

    #-#-#
    # Populate HostStats and TaskStats database
    if Host.all.count != 0 and HostStats.all.count == 0
      actions << "populate_host_stats"
    end
    if Task.all.count != 0 and TaskStats.all.count == 0
      actions << "populate_task_stats"
    end
    #-#-#

    return actions
  end

  def self.remove_installer_dir
    FileUtils.remove_dir("installer")
  end
end
