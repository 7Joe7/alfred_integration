module JiraHelper

  LOG_DATE_FORMAT = '%Y-%m-%d'
  ISSUE_STATUS_NAMES = { :in_progress => 'In Progress', :testing_in_progress => 'Testing in Progress', :open => 'Open',
                        :waiting_for_feedback => 'Waiting for Feedback', :closed => 'Closed', :to_test => 'To Test', :prereleased => 'Prereleased' }

  def insert_from_jira_into_asana
    next_jira_project = @config[:asana][:next_jira_project] || @config[:asana][:next_project]
    next_section = @config[:asana][:next_jira_project][:jira_section] ? @config[:asana][:next_jira_project][:jira_section] : nil
    next_section &&= next_section.to_sym
    scheduled_section = @config[:asana][:scheduled_project][:jira_section] ? @config[:asana][:scheduled_project][:jira_section].to_sym : nil
    # someday_section = @config[:asana][:someday_project][:jira_section] ? @config[:asana][:someday_project][:jira_section].to_sym : nil
    for_each_issue_in("jql=assignee%3D#{@config[:jira][:credentials][:username]}") do |issue|
      task = task_exists?(issue['key'])
      if task
        if (issue['fields']['status']['name'] == ISSUE_STATUS_NAMES[:closed] ||
            issue['fields']['status']['name'] == ISSUE_STATUS_NAMES[:to_test] ||
            issue['fields']['status']['name'] == ISSUE_STATUS_NAMES[:testing_in_progress] ||
            issue['fields']['status']['name'] == ISSUE_STATUS_NAMES[:prereleased]) && !task['completed']
          update_task(task['id'], { :completed => true })
        end
      else
        time_estimate_tag = get_estimate_tag(issue['fields']['timeestimate'])
        tags = time_estimate_tag ? [get_tag('Work'), time_estimate_tag] : [get_tag('Work')]
        data = { :name => "#{issue['key']} - #{issue['fields']['summary']}",
            :notes => "http://#{@config[:jira][:credentials][:hostname]}/browse/#{issue['key']}",
            :tags => tags }
        if issue['fields']['status']['name'] == ISSUE_STATUS_NAMES[:closed] ||
            issue['fields']['status']['name'] == ISSUE_STATUS_NAMES[:to_test] ||
            issue['fields']['status']['name'] == ISSUE_STATUS_NAMES[:testing_in_progress] ||
            issue['fields']['status']['name'] == ISSUE_STATUS_NAMES[:prereleased]
          # don't add it
        elsif issue['fields']['customfield_10005'] && issue['fields']['customfield_10005'][0] =~ /state=FUTURE/
          data.merge!(:section => scheduled_section) if scheduled_section
          create_task(data.merge(:project => @config[:asana][:scheduled_project],
              :due_on => get_first_sprint_day(issue['fields']['customfield_10005'][0])))
        elsif issue['fields']['status']['name'] == ISSUE_STATUS_NAMES[:in_progress] ||
            (issue['fields']['customfield_10005'] && issue['fields']['customfield_10005'][0] =~ /state=ACTIVE/) ||
            issue['fields']['status']['name'] == ISSUE_STATUS_NAMES[:waiting_for_feedback]
          data.merge!(:section => next_section) if next_section
          create_task(data.merge(:project => next_jira_project))
        else
          # TODO either implement a way to update the task when it is planned in or let it not created at all
          # data.merge!(:section => someday_section) if someday_section
          # create_task(data.merge(:project => @config[:asana][:someday_project]))
        end
      end
    end
  end

  def get_first_sprint_day(sprint_info)
    match = sprint_info.match(/state=FUTURE,name=Sprint \d+ (\d+)\.(\d+)\. - /)
    now = Time.new
    first_sprint_day = Time.new(now.year, match[2].to_i, match[1].to_i)
    first_sprint_day = Time.new(now.year + 1, match[2].to_i, match[1].to_i) if now > first_sprint_day
    first_sprint_day.strftime(LOG_DATE_FORMAT)
  end

  def get_from_jira(jql)
    max_results = 1000
    start_at = 0
    result = RestClient.get("http://#{@config[:jira][:credentials][:username]}:#{@config[:jira][:credentials][:password]}@#{@config[:jira][:credentials][:hostname]}/rest/api/2/search?#{jql}&maxResults=#{max_results}&startAt=#{start_at}")
    max_results = result['maxResults'].to_i
    while result['issues'].size == start_at + max_results
      start_at += max_results
      result['issues'] += RestClient.get("http://#{@config[:jira][:credentials][:username]}:#{@config[:jira][:credentials][:password]}@#{@config[:jira][:credentials][:hostname]}/rest/api/2/search?#{jql}&maxResults=#{max_results}&startAt=#{start_at}")['issues']
    end
    result
  end

  def for_each_issue_in(jql)
    JSON.load(get_from_jira(jql))['issues'].each { |issue| yield issue }
  end

  def get_estimate_tag(time_estimate)
    if time_estimate
      pomodoro_length = @config[:asana][:pomodoro_length] ? @config[:asana][:pomodoro_length].to_f : 30
      tag_name = (time_estimate / (60.0 * pomodoro_length)).ceil.to_s
      get_tag(tag_name)
    end
  end
end