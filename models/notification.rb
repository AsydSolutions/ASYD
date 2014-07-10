class Notification
  include DataMapper::Resource

  def self.default_repository_name #here we use the tasks_db for the Notification objects
   :tasks_db
  end

  property :id, Serial
  property :type, Enum[ :error, :info, :success ]
  property :message, Text
  property :sticky, Boolean, :default => false
  property :dismiss, Boolean, :default => false
  property :created_at, DateTime
  property :created_on, Date
  property :updated_at, DateTime
  property :updated_on, Date

  belongs_to :task, :required => false
end
