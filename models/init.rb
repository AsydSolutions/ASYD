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
DataMapper.setup(:config_db, "sqlite3:data/db/config.db") #load the status database
require_relative "email"
DataMapper.finalize
if File.directory? 'data'
  DataMapper.auto_upgrade!
  # Some cleanup to avoid fragmentation
  repository(:tasks_db).adapter.select('VACUUM')
  repository(:notifications_db).adapter.select('VACUUM')
  repository(:hosts_db).adapter.select('VACUUM')
  repository(:monitoring_db).adapter.select('VACUUM')
  repository(:users_db).adapter.select('VACUUM')
  repository(:status_db).adapter.select('VACUUM')
  repository(:config_db).adapter.select('VACUUM')
  # And we set the synchronous to normal
  repository(:tasks_db).adapter.select('PRAGMA synchronous = 1')
  repository(:notifications_db).adapter.select('PRAGMA synchronous = 1')
  repository(:monitoring_db).adapter.select('PRAGMA synchronous = 1')
  repository(:hosts_db).adapter.select('PRAGMA synchronous = 1')
  repository(:users_db).adapter.select('PRAGMA synchronous = 1')
  repository(:status_db).adapter.select('PRAGMA synchronous = 1')
  repository(:config_db).adapter.select('PRAGMA synchronous = 1')
  if Email.all.first.nil?
    Email.create
  end
end

MOTEX = ProcessShared::Mutex.new #mutex for monitoring handling
MNOTEX = ProcessShared::Mutex.new #mutex for monitoring::notification handling
NOTEX = ProcessShared::Mutex.new #mutex for notification handling
HOSTEX = ProcessShared::Mutex.new #mutex for hosts operations
