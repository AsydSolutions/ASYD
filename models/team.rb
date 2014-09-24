class Team
  include DataMapper::Resource

  def self.default_repository_name #here we use the users_db for the User objects
   :users_db
  end

  property :name, String, :key => true
  property :capabilities, Flag[ :admin ]
  property :notifications_enabled, Boolean, :default => true
  property :created_at, DateTime
  property :updated_at, DateTime
  has n, :team_members
  has n, :users, :through => :team_members

  def add_member(user)
    self.users << user
    self.save
  end

  def del_member(user)
    member_rel = TeamMember.get(user.username, self.name)
    if member_rel.nil?
      return false
    end
    member_rel.destroy
    self.reload
    user.reload
    return true
  end

end

class TeamMember
  include DataMapper::Resource

  def self.default_repository_name #here we use the hosts_db for the TeamMember relation
   :users_db
  end

  belongs_to :user,   :key => true
  belongs_to :team, :key => true
end
