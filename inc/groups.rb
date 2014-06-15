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
  groups.execute("INSERT INTO hostgroups (name) VALUES (?)", group)
  groups.close
end

def del_group(group)
  groups = SQLite3::Database.new "data/db/hostgroups.db"
  groups.execute("DELETE FROM hostgroups WHERE name=?", group)
  groups.close
end

def add_group_member(group, server)
  groups = SQLite3::Database.new "data/db/hostgroups.db"
  group_members = groups.get_first_row("select members from hostgroups where name=?", group)
  if group_members[0].nil?
    members = [server]
  else
    members = Marshal.load(group_members[0])
    members << server
  end
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
