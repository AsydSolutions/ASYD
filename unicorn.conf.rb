$UNICORN = 1
$ASYD_PID = Process.pid
$ASYD_VERSION = 0.0901
$DBG = 0 #debug?

FileUtils.mkdir("log") unless File.directory?("log")

listen 3000
worker_processes 1
pid ".asyd.pid"
stderr_path "log/asyd.log"
stdout_path "log/asyd.log"

preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

before_fork do |server, worker|
  wck = $WALCHECK.get_int(0)
  bgm = $BGMONIT.get_int(0)

  Process.kill("TERM", wck) if wck > 0
  Process.kill("TERM", bgm) if bgm > 0
end

after_fork do |server, worker|
  # check for checkpoints
  Spork.spork do
    Process.setsid
    wck = Spork.spork do
      # STDIN.reopen '/dev/null'
      # STDOUT.reopen '/dev/null', 'a'
      # STDERR.reopen STDOUT
      Awal::should_checkpoint?
    end
    $WALCHECK.put_int(0, wck)
    exit
  end

  # monitoring on the background
  Spork.spork do
    Process.setsid
    bgm = Spork.spork do
      # STDIN.reopen '/dev/null'
      # STDOUT.reopen '/dev/null', 'a'
      # STDERR.reopen STDOUT
      Monitoring.background
    end
    $BGMONIT.put_int(0, bgm)
    exit
  end
end
