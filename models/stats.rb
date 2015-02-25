class HostStats
  include DataMapper::Resource

  def self.default_repository_name #here we use the stats_db for the HostStats objects
    :stats_db
  end

  property :created_at, DateTime, :key => true
  property :total_hosts, Integer

end
