# encoding: UTF-8

module SyncHelper
  def setup
    me_data = get_from_asana('users/me')['data']
    @config[:asana][:my_id] = me_data['id']
    me_data['workspaces'].each do |workspace|
      @config[:asana][:workspace_id] = workspace['id'] if workspace['name'] == @config[:asana][:workspace_name]
    end
    @config[:asana][:synchronise_with_jira_active] = false if @config[:asana][:synchronise_with_jira_active].nil?
    @config[:asana][:synchronise_due_on_today_active] = false if @config[:asana][:synchronise_due_on_today_active].nil?
    @config[:asana][:refresh_cache_active] = true if @config[:asana][:refresh_cache_active].nil?
    @config[:asana][:basic_sync_active] = true if @config[:asana][:basic_sync_active].nil?
    @config[:asana][:anybar_active] = false if @config[:asana][:anybar_active].nil?
    @config[:asana][:habits_active] = false if @config[:asana][:habits_active].nil?
    actualize_projects
    actualize_tags
  end

  def commit
    @config[:asana][:cache] ||= []
    backup = @config[:asana][:cache].dup
    @config[:asana][:cache].each do |params|
      backup.delete(params)
      case params[:action]
        when 'create'
          create_task(params)
        when 'delete', 'delete_habit'
          delete_task(params[:id])
        when 'update'
          params.delete(:action)
          id = params[:id]
          params.delete(:id)
          update_task(id, params)
        when 'toggle_task_progress', 'pause_task'
          stop_task(params)
        else
          send(params[:action], params)
      end
    end
  ensure
    @config[:asana][:cache] = backup
  end

  def actualize_projects
    @config[:asana][:inbox_project] ||= {}
    @config[:asana][:inbox_project][:name] ||= 'Inbox'
    @config[:asana][:next_project] ||= {}
    @config[:asana][:next_project][:name] ||= 'Next'
    @config[:asana][:someday_project] ||= {}
    @config[:asana][:someday_project][:name] ||= 'Someday'
    @config[:asana][:scheduled_project] ||= {}
    @config[:asana][:scheduled_project][:name] ||= 'Scheduled'
    @config[:asana][:work_project] ||= {}
    for_each_project do |project|
      case project['name']
        when @config[:asana][:inbox_project][:name] then configure_project(:inbox_project, project)
        when @config[:asana][:next_project][:name] then configure_project(:next_project, project)
        when @config[:asana][:someday_project][:name] then configure_project(:someday_project, project)
        when @config[:asana][:scheduled_project][:name] then configure_project(:scheduled_project, project)
        when @config[:asana][:work_project][:name]
          configure_project(:work_project, project)
        else
      end
    end
  end

  def actualize_tags
    @config[:asana][:tags] = {}
    get_from_asana('tags')['data'].each { |tag| @config[:asana][:tags][tag['name'].downcase.gsub(' ', '_').to_sym] = tag['id'] }
  end

  def configure_project(project_symbol, project)
    @config[:asana][project_symbol] ||= {}
    @config[:asana][project_symbol][:id] = project['id']
    @config[:asana][project_symbol][:sections] = {}
    get_from_asana("projects/#{project['id']}/sections")['data'].each do |section|
      @config[:asana][project_symbol][:sections][section['name'][0..-2].downcase.gsub(' ', '_').to_sym] = section['id']
    end
  end

  def insert_due_today_into_today
    now = Time.now
    today_project = @config[:asana][:today_project]
    today_section = @config[:asana][:today_project][:today_section] ? @config[:asana][:today_project][:today_section].to_sym : 'null'
    if @config[:asana][:synchronise_with_jira_active] && @config[:asana][:work_project] && @config[:asana][:work_project][:id]
      work_project = @config[:asana][:work_project]
      work_section = @config[:asana][:work_project][:today_section] ? @config[:asana][:work_project][:today_section].to_sym : 'null'
      work_tasks = get_tasks_by_project(work_project)
      get_tasks.each do |task|
        if task['due_on'] && now > Time.parse(task['due_on'])
          found = false
          work_tasks.each do |work_task|
            if work_task['id'] == task['id']
              move_task(task['id'], work_project, work_section)
              found = true
              break
            end
          end
          unless found
            (task['name'] =~ SYNC_REGEX[:jira_key]) ?
                move_task(task['id'], work_project, work_section) :
                move_task(task['id'], today_project, today_section)
          end
        end
      end
    else
      get_tasks.each do |task|
        move_task(task['id'], today_project, today_section) if task['due_on'] && now > Time.parse(task['due_on'])
      end
    end
  end
end