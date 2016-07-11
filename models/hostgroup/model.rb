class Hostgroup
  include DataMapper::Resource

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
end

class HostgroupMember
  include DataMapper::Resource

  def self.default_repository_name #here we use the hosts_db for the HostgroupMember relation
   :hosts_db
  end

  belongs_to :host,   :key => true
  belongs_to :hostgroup, :key => true
end
