require 'fileutils'

def setup(*params)
  FileUtils.mkdir_p("data/servers")
  if params.length == 1
    `ssh-keygen -f data/ssh_key_test -t rsa -P "#{params[0]}"`
  elsif params.length == 2
    File.open('data/ssh_key', "w") do |f|
      f.write(params[0][:tempfile].read)
    end
    File.open('data/ssh_key.pub', "w") do |f|
      f.write(params[1][:tempfile].read)
    end
  end
end
