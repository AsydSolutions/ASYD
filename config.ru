if $UNICORN != 1
  begin
    exit
  rescue SystemExit
    puts "######################################\n#\n# This spawning method is deprecated\n#\n# Please start ASYD using:\n# ./asyd.sh start\n#\n# Remember to run bundle install if you\n# are updating from an earlier ASYD version\n#\n######################################\n\n"
    Process.exit!
  end
end

require 'rubygems'
require 'i18n'
require 'bundler'
# Load gems in Gemfile
Bundler.require
# Unicorn self-process killer
require 'unicorn/worker_killer'
# Max requests per worker
use Unicorn::WorkerKiller::MaxRequests, 150, 200

load 'main.rb'

I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'static', 'lang', '*.yml').to_s]
I18n.enforce_available_locales = true

run ASYD
