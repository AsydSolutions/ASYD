def setup(*params)
  # Create directories
  FileUtils.mkdir_p("data/db")
  FileUtils.mkdir_p("data/deploys")
  FileUtils.mv("installer/monitors", "data/monitors") # Move predefined monitors
  FileUtils.remove_dir("installer") # Remove installer directory
  # Create or upload an SSH key
  if params.length == 1
    `ssh-keygen -f data/ssh_key -t rsa -N ""`
  elsif params.length == 2
    File.open('data/ssh_key', "w") do |f|
      f.write(params[0][:tempfile].read)
    end
    File.open('data/ssh_key.pub', "w") do |f|
      f.write(params[1][:tempfile].read)
    end
  end
  begin
    # Create users database
    users = SQLite3::Database.new "data/db/users.db"
    users.execute <<-SQL
    create table users (
      user text not null primary key,
      email text not null,
      password text not null
      notifications integer DEFAULT 0,
    );
    SQL
    users.execute <<-SQL
    create table groups (
      name text not null primary key,
      members text,
      notifications integer DEFAULT 0,
    );
    SQL
    # Create servers database
    servers = SQLite3::Database.new "data/db/servers.db"
    servers.execute <<-SQL
    create table servers (
      hostname text not null primary key,
      ip text not null,
      dist text not null,
      dist_ver real not null,
      arch text not null,
      pkg_mgr text not null,
      monit_pw text not null,
      opt_vars text
    );
    SQL
    # Create hostgroups database
    hostgroups = SQLite3::Database.new "data/db/hostgroups.db"
    hostgroups.execute <<-SQL
    create table hostgroups (
      name text not null primary key,
      members text,
      opt_vars text
    );
    SQL
    # Create notifications database
    notifications = SQLite3::Database.new "data/db/notifications.db"
    notifications.execute <<-SQL
    create table notifications (
      id integer primary key AUTOINCREMENT,
      type integer not null,
      message text not null,
      dismiss integer DEFAULT 0,
      task_id integer,
      created DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    SQL
    notifications.execute <<-SQL
    create table monitoring (
      id integer primary key AUTOINCREMENT,
      host text not null,
      service text default 'system',
      message text not null,
      acknowledge integer DEFAULT 0,
      solved integer DEFAULT 0,
      created DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    SQL
    # Create activity database
    activity = SQLite3::Database.new "data/db/activity.db"
    activity.execute <<-SQL
    create table activity (
      id integer primary key AUTOINCREMENT,
      action text not null,
      target text not null,
      status text DEFAULT "in progress",
      seen integer DEFAULT 0,
      created DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    SQL
    # Any errors?
  rescue SQLite3::Exception => e
    puts e
    # Close databases
  ensure
    servers.close if servers
    hostgroups.close if hostgroups
    notifications.close if notifications
  end
end
