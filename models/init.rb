require "data_mapper"
require "dm-sqlite-adapter"
require 'fileutils'
require 'net/ssh'
require 'net/scp'
require 'open-uri'
require 'pathname'
require 'find'
require 'tempfile'
require 'socket'
require 'timeout'
require 'sqlite3'
require 'redcarpet'
require 'bcrypt'
require 'monit'
require 'mail'
require 'htmlentities'
require_relative "lib/spork"
require_relative "lib/flavored_markdown"
require_relative "lib/errors"
require_relative "lib/URI-monkey-patch"
require_relative "lib/asyd-wal"
require_relative "misc"
require_relative "setup"
require_relative "deploy"
DataMapper.setup(:tasks_db,  "sqlite3:data/db/tasks.db") #load the tasks database
require_relative "task"
DataMapper.setup(:notifications_db,  "sqlite3:data/db/notifications.db") #load the notifications database
require_relative "notification"
DataMapper.setup(:monitoring_db,  "sqlite3:data/db/monitoring.db") #load the monitoring database
require_relative "monitor"
DataMapper.setup(:hosts_db,  "sqlite3:data/db/hosts.db") #load the hosts database
require_relative "host"
require_relative "hostgroup"
DataMapper.setup(:users_db,  "sqlite3:data/db/users.db") #load the users database
require_relative "user"
require_relative "team"
DataMapper.setup(:status_db, "sqlite3:data/db/status.db") #load the status database
require_relative "status"
DataMapper.setup(:config_db, "sqlite3:data/db/config.db") #load the config database
require_relative "email"
DataMapper.setup(:stats_db, "sqlite3:data/db/stats.db") #load the stats database
require_relative "stats"
DataMapper.finalize
if File.directory? 'data'
  DataMapper.auto_upgrade!

  # Check and configure SQLite Options
  tasks_journal = repository(:tasks_db).adapter.select('PRAGMA journal_mode')[0]
  if tasks_journal != "wal"
    repository(:tasks_db).adapter.select('PRAGMA journal_mode = WAL')
    repository(:tasks_db).adapter.select('PRAGMA default_synchronous = 2')
    repository(:tasks_db).adapter.select('PRAGMA default_cache_size = 1000')
  end
  notifications_journal = repository(:notifications_db).adapter.select('PRAGMA journal_mode')[0]
  if notifications_journal != "wal"
    repository(:notifications_db).adapter.select('PRAGMA journal_mode = WAL')
    repository(:notifications_db).adapter.select('PRAGMA default_synchronous = 2')
    repository(:notifications_db).adapter.select('PRAGMA default_cache_size = 2000')
  end
  monitoring_journal = repository(:monitoring_db).adapter.select('PRAGMA journal_mode')[0]
  if monitoring_journal != "wal"
    repository(:monitoring_db).adapter.select('PRAGMA journal_mode = WAL')
    repository(:monitoring_db).adapter.select('PRAGMA default_synchronous = 2')
    repository(:monitoring_db).adapter.select('PRAGMA default_cache_size = 1000')
  end
  hosts_journal = repository(:hosts_db).adapter.select('PRAGMA journal_mode')[0]
  if hosts_journal != "wal"
    repository(:hosts_db).adapter.select('PRAGMA journal_mode = WAL')
    repository(:hosts_db).adapter.select('PRAGMA default_synchronous = 2')
    repository(:hosts_db).adapter.select('PRAGMA default_cache_size = 1000')
  end
  users_journal = repository(:users_db).adapter.select('PRAGMA journal_mode')[0]
  if users_journal != "wal"
    repository(:users_db).adapter.select('PRAGMA journal_mode = WAL')
    repository(:users_db).adapter.select('PRAGMA default_synchronous = 2')
    repository(:users_db).adapter.select('PRAGMA default_cache_size = 500')
  end
  status_journal = repository(:status_db).adapter.select('PRAGMA journal_mode')[0]
  if status_journal != "wal"
    repository(:status_db).adapter.select('PRAGMA journal_mode = WAL')
    repository(:status_db).adapter.select('PRAGMA default_synchronous = 2')
    repository(:status_db).adapter.select('PRAGMA default_cache_size = 500')
  end
  config_journal = repository(:config_db).adapter.select('PRAGMA journal_mode')[0]
  if config_journal != "wal"
    repository(:config_db).adapter.select('PRAGMA journal_mode = WAL')
    repository(:config_db).adapter.select('PRAGMA default_synchronous = 2')
    repository(:config_db).adapter.select('PRAGMA default_cache_size = 500')
  end
  stats_journal = repository(:stats_db).adapter.select('PRAGMA journal_mode')[0]
  if stats_journal != "wal"
    repository(:stats_db).adapter.select('PRAGMA journal_mode = WAL')
    repository(:stats_db).adapter.select('PRAGMA default_synchronous = 2')
    repository(:stats_db).adapter.select('PRAGMA default_cache_size = 1000')
  end

  # Disable wal autocheckpoint (crashes DB)
  repository(:notifications_db).adapter.select('PRAGMA wal_autocheckpoint = 0')
  repository(:tasks_db).adapter.select('PRAGMA wal_autocheckpoint = 0')
  repository(:monitoring_db).adapter.select('PRAGMA wal_autocheckpoint = 0')
  repository(:hosts_db).adapter.select('PRAGMA wal_autocheckpoint = 0')
  repository(:status_db).adapter.select('PRAGMA wal_autocheckpoint = 0')

  # Some cleanup to avoid fragmentation
  repository(:tasks_db).adapter.select('VACUUM')
  repository(:notifications_db).adapter.select('VACUUM')
  repository(:hosts_db).adapter.select('VACUUM')
  repository(:monitoring_db).adapter.select('VACUUM')
  repository(:users_db).adapter.select('VACUUM')
  repository(:status_db).adapter.select('VACUUM')
  repository(:config_db).adapter.select('VACUUM')
  repository(:stats_db).adapter.select('VACUUM')

  # Checkpoint at exit to ensure database consistency
  at_exit {
    repository(:users_db).adapter.select('PRAGMA wal_checkpoint(FULL)')
    repository(:config_db).adapter.select('PRAGMA wal_checkpoint(FULL)')
    repository(:stats_db).adapter.select('PRAGMA wal_checkpoint(FULL)')
  }

  if Email.all.first.nil?
    Email.create
  end
end

MOTEX = Awal::Mutex.new #mutex for monitoring handling
MNOTEX = Awal::Mutex.new #mutex for monitoring::notification handling
NOTEX = Awal::Mutex.new #mutex for notification handling
TATEX = Awal::Mutex.new #mutex for task handling
HOSTEX = Awal::Mutex.new #mutex for hosts operations

# check for checkpoints
walcheck = Spork.spork do
  Awal::should_checkpoint?
end
