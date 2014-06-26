def get_group_members(group)
  groups = SQLite3::Database.new "data/db/hostgroups.db"
  group_members = groups.get_first_row("select members from hostgroups where name=?", group)
  if group_members.nil?
    return nil
  else
    if group_members[0].nil?
      members = []
    else
      members = Marshal.load(group_members[0])
    end
    groups.close
    return members
  end
end

def groups_having(host)
  groupsdb = SQLite3::Database.new "data/db/hostgroups.db"
  groups = groupsdb.execute("select name,members from hostgroups")
  if groups.nil?
    groupsdb.close
    return nil
  else
    groups_in = []
    groups.each do |group|
      unless group[1].nil?
        members = Marshal.load(group[1])
        if members.include? host
          groups_in << group[0]
        end
      end
    end
    groupsdb.close
    return groups_in
  end
end

def get_group_vars(group)
  groups = SQLite3::Database.new "data/db/hostgroups.db"
  group_vars = groups.get_first_row("select opt_vars from hostgroups where name=?", group)
  if group_vars.nil?
    groups.close
    return nil
  else
    if group_vars[0].nil?
      vars = []
    else
      vars = Marshal.load(group_vars[0])
    end
    groups.close
    return vars
  end
end

def groups_edit(action, params)
  if action == "add_group"
    add_group(params[:group])
  elsif action == "del_group"
    del_group(params[:group])
  elsif action == "add_member"
    add_group_member(params[:group], params[:server])
  elsif action == "del_member"
    del_group_member(params[:group], params[:server])
  end
end

def add_group(group)
  groups = SQLite3::Database.new "data/db/hostgroups.db"
  ret = groups.execute("select name from hostgroups where name=?", group)
  if ret.nil? || ret.empty?
    groups.execute("INSERT INTO hostgroups (name) VALUES (?)", group)
    groups.close
    return 1
  else
    groups.close
    return 3
  end
end

def del_group(group)
  groups = SQLite3::Database.new "data/db/hostgroups.db"
  groups.execute("DELETE FROM hostgroups WHERE name=?", group)
  groups.close
end

def add_group_member(group, server)
  if get_host_data(server).nil?
    return 4
  end
  groups = SQLite3::Database.new "data/db/hostgroups.db"
  group_members = groups.get_first_row("select members from hostgroups where name=?", group)
  if group_members[0].nil?
    members = [server]
  else
    members = Marshal.load(group_members[0])
    members << server
  end
  members = members.uniq
  members_srlzd = Marshal.dump(members)
  groups.execute("UPDATE hostgroups SET members=? WHERE name=?", [members_srlzd, group])
  groups.close
end

def del_group_member(group, server)
  groups = SQLite3::Database.new "data/db/hostgroups.db"
  group_members = groups.get_first_row("select members from hostgroups where name=?", group)
  if group_members[0].nil?
    error = "No members found in group "+group
    groups.close
    return error
  else
    members = Marshal.load(group_members[0])
    members.delete(server) {
      groups.close
      return server+" not found in group "+group
    }
    members_srlzd = Marshal.dump(members)
    groups.execute("UPDATE hostgroups SET members=? WHERE name=?", [members_srlzd, group])
    groups.close
  end
end

def add_group_var(group, name, value)
  groups = SQLite3::Database.new "data/db/hostgroups.db"
  opt_vars = groups.get_first_row("select opt_vars from hostgroups where name=?", group)
  if opt_vars.nil?
    return 4
  else
    if opt_vars[0].nil?
      vars = {}
    else
      vars = Marshal.load(opt_vars[0])
    end
  end
  if vars[name].nil?  # avoid duplicates
    vars[name] = value
  end
  vars_srlzd = Marshal.dump(vars)
  groups.execute("UPDATE hostgroups SET opt_vars=? WHERE name=?", [vars_srlzd, group])
  groups.close
end

def del_group_var(group, name)
  groups = SQLite3::Database.new "data/db/hostgroups.db"
  opt_vars = groups.get_first_row("select opt_vars from hostgroups where name=?", group)
  if opt_vars.nil?
    return 4
  else
    if opt_vars[0].nil?
      return 4
    else
      vars = Marshal.load(opt_vars[0])
    end
  end
  vars.delete(name)
  vars_srlzd = Marshal.dump(vars)
  groups.execute("UPDATE hostgroups SET opt_vars=? WHERE name=?", [vars_srlzd, group])
  groups.close
end

def check_members_status(group)
  groups = SQLite3::Database.new "data/db/hostgroups.db"
  group_members = groups.get_first_row("select members from hostgroups where name=?", group)
  if group_members[0].nil?
    return [0,0,0]
  else
    members = Marshal.load(group_members[0])
  end
  total = members.count
  sane = members.count
  failed = 0
  members.each do |host|
    ret = all_ok(host)
    if ret != 1
      sane = sane - 1
      failed = failed + 1
    end
  end
  return [sane,total,failed]
end
