class ASYD < Sinatra::Application
  get '/help' do
    @doc = 'doc/en/README.md'
    erb :help
  end

  get '/help/:doc' do
    loc = I18n.locale.to_s
    @doc = 'doc/'+loc+'/'+params[:doc]
    if !File.exists?("static/"+@doc)
      @doc = 'doc/en/'+params[:doc]
    end
    if File.exists?("static/"+@doc)
      erb :help
    else
      not_found
    end
  end
end
