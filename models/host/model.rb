class Host
  include DataMapper::Resource

  def self.default_repository_name #here we use the hosts_db for the Host objects
   :hosts_db
  end

  property :hostname, String, :key => true
  property :ip, String
  property :ssh_port, Integer
  property :user, String
  property :dist, String
  property :dist_ver, Float
  property :arch, String
  property :pkg_mgr, String
  property :svc_mgr, String
  property :monit_pw, String
  property :opt_vars, Object
  property :created_at, DateTime
  property :updated_at, DateTime
  has n, :hostgroup_members
  has n, :hostgroups, :through => :hostgroup_members

  attr_accessor :ssh

  after :create do
    # Add the new server to the statistics
    if HostStats.last.nil?
      t_hosts = 0
    else
      t_hosts = HostStats.last.total_hosts
    end
    stat = HostStats.first(:created_at => DateTime.now.beginning_of_day)
    if !stat
      HostStats.create(:created_at => DateTime.now.beginning_of_day, :total_hosts => t_hosts+1)
    else
      stat.total_hosts = stat.total_hosts + 1
      stat.save
    end
  end

end
