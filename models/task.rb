class Task
  include DataMapper::Resource

  def self.default_repository_name #here we use the tasks_db for the Task objects
   :tasks_db
  end

  property :id, Serial
  property :action, Enum[ :installing, :deploying ]
  property :target, Object
  property :status, Enum[ :in_progress, :finished, :failed ], :default => :in_progress
  property :created_at, DateTime
  property :created_on, Date
  property :updated_at, DateTime
  property :updated_on, Date

  has n, :notifications
end
