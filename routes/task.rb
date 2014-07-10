class ASYD < Sinatra::Application
  get '/task/list' do
    erb "-WIP-"
  end

  get '/task/:id' do
    if @task.nil?
      erb :oops
    else
      erb :task_detail #WIP
    end
  end
end
