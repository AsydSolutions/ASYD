class Task
  include DataMapper::Resource

  def self.default_repository_name #here we use the tasks_db for the Task objects
   :tasks_db
  end

  property :id, Serial
  property :action, Enum[ :installing, :deploying, :undeploying ]
  property :object, String
  property :target, String
  property :target_type, Enum[ :host, :hostgroup ]
  property :status, Enum[ :in_progress, :finished, :failed ], :default => :in_progress
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :notifications, :repository => :notifications_db

  # Update stats (new task)
  after :create do
    stat = TaskStats.first(:created_at => DateTime.now.beginning_of_day)
    if !stat
      stat = TaskStats.create(:created_at => DateTime.now.beginning_of_day)
    end
    stat.started_tasks = stat.started_tasks + 1
    stat.save
  end

  # Update stats (finished/failed task)
  after :update do
    stat = TaskStats.first(:created_at => DateTime.now.beginning_of_day)
    if !stat
      stat = TaskStats.create(:created_at => DateTime.now.beginning_of_day)
    end
    stat.completed_tasks = stat.completed_tasks + 1 if self.status == :finished
    stat.failed_tasks = stat.failed_tasks + 1 if self.status == :failed
    stat.save
  end
end
