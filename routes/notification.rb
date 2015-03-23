class ASYD < Sinatra::Application
  post '/notification/dismiss' do
    NOTEX.synchronize do
      notification = Notification.first(:id => params['msg_id'].to_i)
      notification.update(:dismiss => true)
    end
  end

  post '/notification/monitoring/dismiss' do
    MNOTEX.synchronize do
      notification = Monitoring::Notification.first(:id => params['msg_id'].to_i)
      notification.update(:dismiss => true)
    end
  end

  post '/notification/monitoring/acknowledge' do
    MNOTEX.synchronize do
      notification = Monitoring::Notification.first(:id => params['msg_id'].to_i)
      notification.update(:acknowledge => true)
    end
  end

  get '/notifications/bytask/:taskid' do
    task = Task.first(:id => params[:taskid])
    @finished = true if task.status != :in_progress
    @notifications = task.notifications.all(:order => [ :host.asc, :created_at.asc])
    @hosts = Array.new
    @errors = Array.new
    @notifications.each do |notif|
      @hosts << notif.host unless notif.host.nil?
      @errors << notif.host unless notif.type != :error
    end
    @hosts.uniq!
    @errors.uniq!

    erb :'task/notifications', :layout => false
  end
end
