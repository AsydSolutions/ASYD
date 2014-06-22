require 'bcrypt'

def add_user(user, email, password)
  enc_pw = BCrypt::Password.create(password)
  userdb = SQLite3::Database.new "data/db/users.db"
  ret = userdb.execute("select user,email from users where user=? or email=?", [user, email])
  if ret.nil? || ret.empty?
    userdb.execute("INSERT INTO users (user, email, password) VALUES (?, ?, ?)", [user, email, enc_pw])
    userdb.close
    return 1
  else
    userdb.close
    return 3
  end
end

def auth_user(user, password)
  userdb = SQLite3::Database.new "data/db/users.db"
  row = userdb.get_first_row("select user,password from users where user=?", user)
  userdb.close
  if row.nil?
    return false
  end
  enc_pw = BCrypt::Password.new(row[1])
  if enc_pw == password
    return true
  else
    return false
  end
end

def add_team(name)
  userdb = SQLite3::Database.new "data/db/users.db"
  ret = userdb.execute("select team from teams where team=?", name)
  if ret.nil? || ret.empty?
    userdb.execute("INSERT INTO teams (team) VALUES (?)", name)
    userdb.close
    return 1
  else
    userdb.close
    return 3
  end
end

def del_team(name)
  userdb = SQLite3::Database.new "data/db/users.db"
  userdb.execute("DELETE FROM teams WHERE team=?", name)
  userdb.close
end

def add_team_member(team, user)
  userdb = SQLite3::Database.new "data/db/users.db"
  team_members = userdb.get_first_row("select members from teams where team=?", team)
  if team_members[0].nil?
    members = [user]
  else
    members = Marshal.load(team_members[0])
    members << user
  end
  members = members.uniq
  members_srlzd = Marshal.dump(members)
  userdb.execute("UPDATE teams SET members=? WHERE team=?", [members_srlzd, team])
  userdb.close
end

def del_team_member(team, user)
  userdb = SQLite3::Database.new "data/db/users.db"
  team_members = userdb.get_first_row("select members from teams where team=?", team)
  if team_members[0].nil?
    error = "No members found in team "+team
    userdb.close
    return error
  else
    members = Marshal.load(team_members[0])
    members.delete(user) {
      userdb.close
      return user+" not found in team "+team
    }
    members_srlzd = Marshal.dump(members)
    userdb.execute("UPDATE teams SET members=? WHERE team=?", [members_srlzd, team])
    userdb.close
  end
end

def is_admin?(user)
  userdb = SQLite3::Database.new "data/db/users.db"
  ret = userdb.get_first_row("select members from teams where team='admins'")
  if ret.nil?
    return false
  else
    members = Marshal.load(ret[0])
    if members.include? user
      return true
    else
      return false
    end
  end
end
