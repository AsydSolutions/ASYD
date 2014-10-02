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
    @notifications = task.notifications.all(:order => [ :host.desc, :created_at.asc])
    @hosts = Array.new
    @notifications.each do |notif|
      @hosts << notif.host unless notif.host.nil?
    end
    @hosts.uniq!

    erb :notifications, :layout => false
  end
end
