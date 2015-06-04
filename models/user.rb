class User
  include DataMapper::Resource

  def self.default_repository_name #here we use the users_db for the User objects
   :users_db
  end

  property :username, String, :key => true
  property :email, String
  property :password, BCryptHash
  property :receive_notifications, Boolean, :default => true
  property :token, String
  property :api_key, String # For ASYD Enterprise only
  property :created_at, DateTime
  property :updated_at, DateTime
  has n, :team_members
  has n, :teams, :through => :team_members

  def initialize(username, email, password)
    begin
      self.username = username
      self.email = email
      enc_pw = BCrypt::Password.create(password)
      self.password = enc_pw
      if !self.save
        raise #couldn't save the object
      end
    rescue
      return false
    end
  end

  def self.auth(username, password)
    un = username.to_s.downcase
    u = first(:conditions => ['lower(email) = ? OR lower(username) = ?', un, un])
    if u && u.password == password
      return u
    else
      return false
    end
  end

  def is_admin?
    is_admin = self.teams.count(:capabilities => :admin)
    if is_admin == 0
      return false
    else
      return true
    end
  end

end
