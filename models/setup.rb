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
      DataMapper.auto_upgrade!
      # And now we set some SQLite pragmas for performance
      repository(:tasks_db).adapter.select('PRAGMA journal_mode = WAL')
      repository(:notifications_db).adapter.select('PRAGMA journal_mode = WAL')
      repository(:hosts_db).adapter.select('PRAGMA journal_mode = WAL')
      repository(:monitoring_db).adapter.select('PRAGMA journal_mode = WAL')
      repository(:users_db).adapter.select('PRAGMA journal_mode = WAL')
      repository(:status_db).adapter.select('PRAGMA journal_mode = WAL')
      repository(:config_db).adapter.select('PRAGMA journal_mode = WAL')
  end

  def self.one_click_update
    Spork.spork do
      system 'git pull origin master'
      bundle = Gem.bin_path("bundler", "bundle")
      system "#{bundle} install && #{bundle} update"
    end
    Process.waitall
    Spork.spork do
      Process.setsid
      Spork.spork do
        exec "./asyd.sh restart"
      end
      exit
    end
  end

  def self.one_click_install_exchange
    Spork.spork do
      open('Gemfile', 'a') do |f|
        f.puts 'gem "viewpoint"'
      end
      bundle = Gem.bin_path("bundler", "bundle")
      system "#{bundle} install && #{bundle} update"
    end
    Process.waitall
    Spork.spork do
      Process.setsid
      Spork.spork do
        exec "./asyd.sh restart"
      end
      exit
    end
  end

  def self.update_available?
    begin
      last_ver = Net::HTTP.get(URI 'https://raw.githubusercontent.com/AsydSolutions/ASYD/master/version').strip
      return true unless Gem::Version.new(last_ver) <= Gem::Version.new($ASYD_VERSION)
      return false
    rescue
      return false
    end
  end
end
