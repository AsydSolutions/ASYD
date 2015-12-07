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
    if self.opt_vars.nil?
      self.opt_vars = {}
      self.save
    end
    self.update(:opt_vars => opt_vars.merge(name => value))
    return true #all ok
  end

  def del_var(name)
    if self.opt_vars[name].nil?
      return false #error = varname doesn't exists
    end
    self.update(:opt_vars => opt_vars.except(name))
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
          forks2 = forks      # Ensure there's no completed forks on the fork list
          forks2.each do |pid|
            forks.delete(pid) unless Misc::checkpid(pid)
          end
          if forks.count >= max_forks #if we reached the "forkability" limit
            id = Process.wait #then we wait for some child to finish
            forks.delete(id) #and we remove it from the forks array
          end
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
