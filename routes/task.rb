class ASYD < Sinatra::Application

  before /^(\/task)/ do
    protected!
  end


  get '/task/list' do
    @tasks_progress = Task.all(:status => :in_progress, :order => [ :id.desc ])
    @tasks_completed = Task.all(:status => [ :finished, :failed ], :order => [ :id.desc ])
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

  get '/task/del/:id' do
    task = Task.first(:id => params[:id])
    task.notifications.each do |notification|
      notification.destroy
    end
    task.reload
    task.destroy
  end
end
