class ASYD < Sinatra::Application
  get '/task/list' do
    erb "-WIP-"
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
