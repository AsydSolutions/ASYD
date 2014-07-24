class Hostgroup
  include DataMapper::Resource
  include Monitoring::Hostgroup

  def self.default_repository_name #here we use the hosts_db for the Hostgroup objects
   :hosts_db
  end

  property :name, String, :key => true
  property :autodeploy, Object
  property :opt_vars, Object, :default  => {}
  property :created_at, DateTime
  property :updated_at, DateTime
  has n, :hostgroup_members
  has n, :hosts, :through => :hostgroup_members

  def add_member(host)
    self.hosts << host
    self.save
  end

  def del_member(host)
    member_rel = HostgroupMember.get(host.hostname, self.name)
    if member_rel.nil?
      return false
    end
    member_rel.destroy
    self.reload
    host.reload
    return true
  end

  def add_var(name, value)
    vars = self.opt_vars #load opt_vars
    if !vars[name].nil?
      return false #error = varname exists
    end
    vars[name] = value #add a new variable to the hash and update
    self.update(:opt_vars => nil)
    self.update(:opt_vars => vars)
    return true #all ok
  end

  def del_var(name)
    vars = self.opt_vars #load opt_vars
    if vars[name].nil?
      return false #error = varname doesn't exists
    end
    vars.delete(name) #delete the variable and update
    self.update(:opt_vars => nil)
    self.update(:opt_vars => vars)
    return true #all ok
  end

  def delete
    self.hosts.each do |host|
      del_member(host)
    end
    reload
    return self.destroy
  end
end

class HostgroupMember
  include DataMapper::Resource

  def self.default_repository_name #here we use the hosts_db for the HostgroupMember relation
   :hosts_db
  end

  belongs_to :host,   :key => true
  belongs_to :hostgroup, :key => true
end
