class ASYD < Sinatra::Application
  get '/' do
    erb "- Dashboard -"
  end
end
