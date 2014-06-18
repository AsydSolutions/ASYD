require 'rubygems'
load 'asyd.rb'

bgmonit = Spork.spork do
  background_monitoring()
end
run Sinatra::Application
