require 'fileutils'

def setup
  FileUtils.mkdir_p("data")
  `ssh-keygen -f data/ssh_key_test -t rsa -P "somepassword"`
end
