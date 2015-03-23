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

  # Launches a block of code on a hostgroup (used on routes/deploys.rb and routes/monitors.rb)
  #
  def group_launch
    sleep 0.2 # small delay
    if !self.hosts.nil? && !self.hosts.empty? #it's a valid hostgroup
      max_forks = Misc::get_max_forks #we get the "forkability"
      forks = [] #and initialize an empty array
      self.hosts.each do |host| #for each host
        if forks.count >= max_forks #if we reached the "forkability" limit
          id = Process.wait #then we wait for some child to finish
          forks.delete(id) #and we remove it from the forks array
        end
        frk = Spork.spork do #so we can continue executing a new fork
          yield host # the actual code
        end
        forks << frk #and store the fork id on the forks array
      end
    end
    Process.waitall
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
