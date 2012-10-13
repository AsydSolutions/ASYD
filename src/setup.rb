require 'fileutils'

def setup(*params)
  FileUtils.mkdir_p("data/servers")
  if params.length == 1
    `ssh-keygen -f data/ssh_key_test -t rsa -P "#{params[0]}"`
  elsif params.length == '2'
    
  end
end
