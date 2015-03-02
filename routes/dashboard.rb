class ASYD < Sinatra::Application
  get '/' do
    @render_host_stats = [] # Array for storing the total hosts on certain days for statistics
    @render_host_stats << ["Date", "Total Hosts"]
    HostStats.all.each do |hostStat|
      @render_host_stats << [hostStat.created_at.to_date, hostStat.total_hosts]
    end

    @render_task_stats = [] # Array for storing the total hosts on certain days for statistics
    started_tasks = []
    completed_tasks = []
    failed_tasks = []

    TaskStats.all(:created_at.gte => DateTime.now-30).each do |taskStat|
      started_tasks << [taskStat.created_at.to_date, taskStat.started_tasks]
      completed_tasks << [taskStat.created_at.to_date, taskStat.completed_tasks]
      failed_tasks << [taskStat.created_at.to_date, taskStat.failed_tasks]
    end
    @render_task_stats << ["Started Tasks", "Completed Tasks", "Failed Tasks"]
    @render_task_stats << TaskStats.fill_missing_dates(started_tasks)
    @render_task_stats << TaskStats.fill_missing_dates(completed_tasks)
    @render_task_stats << TaskStats.fill_missing_dates(failed_tasks)

    erb :dashboard
  end
end
