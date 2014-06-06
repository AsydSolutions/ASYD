def get_group_members(group)
  path = 'data/groups/'+group
  f = File.open(path, "r")
  line = f.gets
  if line.nil?
    members = ""
  else
    memberlist = line.strip
    members = memberlist.split(';')
  end
  f.close
  return members
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
  f = File.new("data/groups/"+group,  "w+")
  f.close
end

def del_group(group)
  FileUtils.rm("data/groups/"+group)
end

def add_group_member(group, server)
  path = 'data/groups/'+group
  f = File.open(path, "r+")
  line = f.gets
  if line.nil?
    f.puts(server)
  else
    f.seek(line.size-1)
    f.puts(";"+server)
  end
  f.close
end

def del_group_member(group, server)
  path = 'data/groups/'+group
  data = File.read(path).gsub(/^#{server};?|;?#{server}/, '')
  f = File.open(path, "w")
  f.puts data
  f.close
end
