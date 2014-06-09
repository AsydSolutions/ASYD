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
  # Create servers database
  begin
  servers = SQLite3::Database.new "data/db/servers.db"
  servers.execute <<-SQL
  create table servers (
    hostname text not null primary key,
    ip text not null,
    dist text not null,
    dist_ver real not null,
    arch text not null,
    pkg_mgr text not null,
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
  # Any errors?
  rescue SQLite3::Exception => e
    puts e
  # Close databases
  ensure
    servers.close if servers
    hostgroups.close if hostgroups
  end
end
