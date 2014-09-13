class ASYD < Sinatra::Application
  get '/help' do
    @doc = 'doc/en/README.md'
    erb :help
  end

  get '/help/:doc' do
    @doc = 'doc/en/'+params[:doc]
    erb :help
  end
end
