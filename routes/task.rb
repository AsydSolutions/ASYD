class ASYD < Sinatra::Application
  get '/task/list' do
    @tasks_progress = Task.all(:status => :in_progress, :order => [ :id.desc ])
    @tasks_finished = Task.all(:status => :finished, :order => [ :id.desc ], :limit => 10)
    @tasks_failed = Task.all(:status => :failed, :order => [ :id.desc ], :limit => 10)
    erb :task_list
  end

  get '/task/:id' do
    @task = Task.first(:id => params[:id])
    @notifications = @task.notifications.all
    if @task.nil?
      erb :oops
    else
      erb :task_detail
    end
  end
end
