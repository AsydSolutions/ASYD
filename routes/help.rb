class ASYD < Sinatra::Application
  get '/help' do
    erb :help
  end
end
