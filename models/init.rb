require "data_mapper"
require "dm-sqlite-adapter"
require 'fileutils'
require 'net/ssh'
require 'net/scp'
require 'pathname'
require 'find'
require 'tempfile'
require 'socket'
require 'sqlite3'
require 'redcarpet'
require 'bcrypt'
require 'monit'
require_relative "spork"
require_relative "errors"
require_relative "misc"
require_relative "setup"
require_relative "deploy"
DataMapper.setup(:tasks_db,  "sqlite3:data/db/tasks.db") #load the tasks database
require_relative "task"
require_relative "notification"
require_relative "monitor"
DataMapper.setup(:hosts_db,  "sqlite3:data/db/hosts.db") #load the hosts database
require_relative "host"
require_relative "hostgroup"
DataMapper.setup(:users_db,  "sqlite3:data/db/users.db") #load the users database
require_relative "user"
require_relative "team"
DataMapper.setup(:status_db, "sqlite3:data/db/status.db")
require_relative "status"
DataMapper.finalize
if File.directory? 'data'
  DataMapper.auto_upgrade!
end

MOTEX = ProcessShared::Mutex.new #mutex for monitoring handling
NOTEX = ProcessShared::Mutex.new #mutex for notification handling
