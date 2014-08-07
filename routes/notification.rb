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
end
