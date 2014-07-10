class ASYD < Sinatra::Application
  post '/notification/dismiss' do
    notification = Notification.first(:id => params['msg_id'].to_i)
    notification.update(:dismiss => true)
  end
end
