require_relative '../helpers/init'

class ASYD < Sinatra::Application
  get '/' do
    if user
      erb "- Dashboard -"
    else
      erb :login, :layout=>false
    end
  end
end
