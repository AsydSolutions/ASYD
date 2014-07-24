class Task
  include DataMapper::Resource

  def self.default_repository_name #here we use the tasks_db for the Task objects
   :tasks_db
  end

  property :id, Serial
  property :action, Enum[ :installing, :deploying ]
  property :object, String
  property :target, String
  property :target_type, Enum[ :host, :hostgroup ]
  property :status, Enum[ :in_progress, :finished, :failed ], :default => :in_progress
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :notifications
end
