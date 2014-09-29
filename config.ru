require 'rubygems'
require 'i18n'
load 'asyd.rb'

I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'static', 'lang', '*.yml').to_s]
I18n.enforce_available_locales = true

run ASYD
