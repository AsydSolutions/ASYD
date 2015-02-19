class Setup
  def initialize(*params)
    # Create directories
    FileUtils.mkdir_p("data/db")
    FileUtils.mkdir_p("data/deploys")
    FileUtils.mv("installer/monit", "data/deploys/monit") # Move deploy for monit
    FileUtils.mv("installer/monitors", "data/monitors") # Move predefined monitors
    FileUtils.remove_dir("installer") # Remove installer directory
    # Create or upload an SSH key
    if params.length == 2 #upload pub and priv keys
      File.open('data/ssh_key', "w") do |f|
        f.write(params[0][:tempfile].read)
      end
      File.open('data/ssh_key.pub', "w") do |f|
        f.write(params[1][:tempfile].read)
      end
    else #or generate a new key
      `ssh-keygen -f data/ssh_key -t rsa -N ""`
    end
      # Create models databases
      DataMapper.auto_migrate!
      # And now we set some SQLite pragmas for performance
      repository(:tasks_db).adapter.select('PRAGMA journal_mode = WAL')
      repository(:notifications_db).adapter.select('PRAGMA journal_mode = WAL')
      repository(:hosts_db).adapter.select('PRAGMA journal_mode = WAL')
      repository(:monitoring_db).adapter.select('PRAGMA journal_mode = WAL')
      repository(:users_db).adapter.select('PRAGMA journal_mode = WAL')
      repository(:status_db).adapter.select('PRAGMA journal_mode = WAL')
      repository(:config_db).adapter.select('PRAGMA journal_mode = WAL')
  end
end
