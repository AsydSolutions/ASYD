require 'sinatra'
require_relative 'routes/init'
require_relative 'models/init'

class ASYD < Sinatra::Application
  configure do
    set :public_folder, Proc.new { File.join(root, "static/lib") }
    # set :environment, :production
    enable :sessions
  end

  helpers do
    def user
      if session[:username]
        User.first(:username => session[:username])
      else
        nil
      end
    end
    def timezone
      session[:timezone] ? session[:timezone] : "UTC"
    end
    def t(*args)
      I18n.t(*args)
    end
  end

  before do
    loc = request.env["HTTP_ACCEPT_LANGUAGE"] ? request.env["HTTP_ACCEPT_LANGUAGE"][0,2] : "en"
    I18n.locale = I18n.available_locales.map(&:to_s).include?(loc) ? loc : "en"
  end

  # Check if ASYD was installed or user is logged in before doing anything
  # before /^(?!\/(setup))(?!\/(login))/ do
  #   if !File.directory? 'data'
  #     redirect '/setup'
  #   else
  #     if !session[:username] then
  #       redirect '/login'
  #     end
  #   end
  # end

  # 404 Error!
  not_found do
    status 404
    erb :oops
  end

  # monitoring on the background
  bgmonit = Spork.spork do
   Monitoring.background
  end

end
