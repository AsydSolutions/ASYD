class HostStats
  include DataMapper::Resource

  def self.default_repository_name #here we use the stats_db for the HostStats objects
    :stats_db
  end

  property :created_at, DateTime, :key => true
  property :total_hosts, Integer
end

class TaskStats
  include DataMapper::Resource

  def self.default_repository_name #here we use the stats_db for the HostStats objects
    :stats_db
  end

  property :created_at, DateTime, :key => true
  property :started_tasks, Integer, :default => 0
  property :completed_tasks, Integer, :default => 0
  property :failed_tasks, Integer, :default => 0

  # This function gets a series of date,value and fills the missing dates to complete a month
  def self.fill_missing_dates(series)
    last_day = series.last[0]
    series.map do |date, value|
      [date, value]
    end.inject([]) do |series, date_and_value|
      filler = if series.empty?
        []
      else
        ((series.last[0]+ 1)..(date_and_value[0] - 1)).map do |date|
          [date, 0]
        end
      end
      prefiller = if series.empty?
        []
      else
        (((DateTime.now-30).to_date)..(series.first[0]- 1)).map do |date|
          [date, 0]
        end
      end
      postfiller = if series.empty?
        []
      else
        ((last_day + 1)..((DateTime.now).to_date)).map do |date|
          [date, 0]
        end
      end
      series + prefiller + filler + postfiller + [date_and_value]
    end.map do |date, value|
      [date, value]
    end
  end
end
