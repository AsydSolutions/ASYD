module ASYDMutex
  class Motex < ProcessShared::Mutex
    def synchronize
      lock
      begin
        yield
      ensure
        sleep 0.05
        repository(:status_db).adapter.select('PRAGMA wal_checkpoint(RESTART)')
        sleep 0.05
        unlock
      end
    end
  end

  class Mnotex < ProcessShared::Mutex
    def synchronize
      lock
      begin
        yield
      ensure
        sleep 0.05
        repository(:monitoring_db).adapter.select('PRAGMA wal_checkpoint(RESTART)')
        sleep 0.05
        unlock
      end
    end
  end

  class Notex < ProcessShared::Mutex
    def synchronize
      lock
      begin
        yield
      ensure
        sleep 0.05
        repository(:notifications_db).adapter.select('PRAGMA wal_checkpoint(RESTART)')
        sleep 0.05
        unlock
      end
    end
  end

  class Tatex < ProcessShared::Mutex
    def synchronize
      lock
      begin
        yield
      ensure
        sleep 0.05
        repository(:tasks_db).adapter.select('PRAGMA wal_checkpoint(RESTART)')
        sleep 0.05
        unlock
      end
    end
  end

  class Hostex < ProcessShared::Mutex
    def synchronize
      lock
      begin
        yield
      ensure
        sleep 0.05
        repository(:hosts_db).adapter.select('PRAGMA wal_checkpoint(RESTART)')
        sleep 0.05
        unlock
      end
    end
  end
end
