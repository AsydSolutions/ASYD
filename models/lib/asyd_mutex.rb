module ASYDMutex
  class Mnotex < ProcessShared::Mutex
    def synchronize
      lock
      begin
        yield
      ensure
        repository(:monitoring_db).adapter.select('PRAGMA wal_checkpoint(PASSIVE)')
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
        repository(:tasks_db).adapter.select('PRAGMA wal_checkpoint(PASSIVE)')
        repository(:notifications_db).adapter.select('PRAGMA wal_checkpoint(PASSIVE)')
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
        repository(:hosts_db).adapter.select('PRAGMA wal_checkpoint(PASSIVE)')
        unlock
      end
    end
  end
end
