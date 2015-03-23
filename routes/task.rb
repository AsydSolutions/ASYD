class ASYD < Sinatra::Application
  get '/task/list' do
    @tasks_progress = Task.all(:status => :in_progress, :order => [ :id.desc ])
    @tasks_completed = Task.all(:status => [ :finished, :failed ], :order => [ :id.desc ])
    erb :'task/task_list'
  end

  get '/task/:id' do
    @task = Task.first(:id => params[:id])
    if @task.nil?
      not_found
    else
      erb :'task/task_detail'
    end
  end

  get '/task/del/:id' do
    TATEX.synchronize do
      task = Task.first(:id => params[:id])
      NOTEX.synchronize do
        task.notifications.each do |notification|
          notification.destroy
        end
      end
      task.reload
      task.destroy
    end
  end
end
