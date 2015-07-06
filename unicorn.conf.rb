$UNICORN = 1
$ASYD_PID = Process.pid
$ASYD_VERSION = 0.091
$DBG = 0 #debug?

FileUtils.mkdir("log") unless File.directory?("log")

listen 3000
worker_processes 1
pid ".asyd.pid"
stderr_path "log/asyd.log"
stdout_path "log/asyd.log"

preload_app true

before_fork do |server, worker|
  if File.exist?('data/.dmon.pid')
    Dmon::stop('dmon')
  end

  DataObjects::Pooling.pools.each do |pool|
    pool.dispose
  end
end

after_fork do |server, worker|
  $0 = 'ASYD Web Worker'

  DataMapper.setup(:tasks_db,  "sqlite3:data/db/tasks.db") #load the tasks database
  DataMapper.setup(:notifications_db,  "sqlite3:data/db/notifications.db") #load the notifications database
  DataMapper.setup(:monitoring_db,  "sqlite3:data/db/monitoring.db") #load the monitoring database
  DataMapper.setup(:hosts_db,  "sqlite3:data/db/hosts.db") #load the hosts database
  DataMapper.setup(:users_db,  "sqlite3:data/db/users.db") #load the users database
  DataMapper.setup(:status_db, "sqlite3:data/db/status.db") #load the status database
  DataMapper.setup(:config_db, "sqlite3:data/db/config.db") #load the config database
  DataMapper.setup(:stats_db, "sqlite3:data/db/stats.db") #load the stats database

  Dmon::init
end
