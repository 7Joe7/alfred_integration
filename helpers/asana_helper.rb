require 'nokogiri'
require 'json'
require 'rest-client'
require 'base64'
require './helpers/jira_helper.rb'
require './helpers/alfred_helper.rb'
require './helpers/anybar_helper.rb'
require './helpers/sync_helper.rb'

module AsanaHelper
  include JiraHelper
  include AlfredHelper
  include AnybarHelper
  include SyncHelper

  NVPREFS = "#{ENV['HOME']}/Library/Application Support/Alfred 2/Workflow Data/"
  BUNDLE_ID = 'com.herokuapp.jotc.asana'
  CACHE_ADDRESS = "#{NVPREFS}#{BUNDLE_ID}/cache.xml"
  LOGS_ADDRESS = "#{NVPREFS}#{BUNDLE_ID}/asana.log"
  VIEW_LOGS_ADDRESS = "#{NVPREFS}#{BUNDLE_ID}/logs.xml"
  CONFIG_PATH = "#{NVPREFS}#{BUNDLE_ID}/config.json"
  SYNC_REGEX = { :jira_key => /^[A-Z]{2,}-\d+/, :asana_log => /Log (\d{4}-\d{2}-\d{2} \d{2}:\d{2})( - \d{4}-\d{2}-\d{2} \d{2}:\d{2})?/ }
  ASANA_LOG_TIME_FORMAT = '%Y-%m-%d %H:%M'
  LOG_DATE_FORMAT = '%Y-%m-%d'
  STATUS_NAMES = { :in_progress => 'In Progress', :cached_for_completion => 'Cached for Completion' }
  SUPPORTED_FOR_CACHING = %w(create update delete toggle_task_progress pause_task)

  def communicate(params = {})
    if File.exists?(CONFIG_PATH)
      @config = JSON.parse(File.read(CONFIG_PATH), :symbolize_names => true)
      if @config[:asana][:api_key] && @config[:asana][:workspace_name]
        @result = ''
        begin
          setup unless @config[:asana][:my_id]
          yield
          commit
        rescue SocketError => e
          File.write(LOGS_ADDRESS, "#{e}, #{e.backtrace}")
          if SUPPORTED_FOR_CACHING.include?(params[:action])
            @config[:asana][:cache] ||= []
            @config[:asana][:cache] << params
            @result = "#{params[:action]} cached. "
          else
            @result = "#{params[:action]} failed due to bad connection."
          end
          File.write(CONFIG_PATH, JSON.pretty_unparse(@config))
        ensure
          @config[params[:action]] = Time.now
          File.write(CONFIG_PATH, JSON.pretty_unparse(@config))
          puts @result
        end
      else
        puts 'Set up Asana API key and workspace name first'
      end
    else
      puts 'Set up Asana API key and workspace name first'
    end
  rescue Exception => e
    puts 'Operation failed, see logs'
    File.write(LOGS_ADDRESS, "#{e}, #{e.backtrace}")
  end

  def process_logs(logs, params)
    params[:logged], params[:logs] = 0, []
    logs.each do |log|
      start_time = Time.parse(log['start'])
      log['end'] ||= Time.now
      end_time = Time.parse(log['end'])
      params[:logged] += (end_time - start_time).to_i
      params[:logs] << "Log #{start_time.strftime(ASANA_LOG_TIME_FORMAT)} - #{end_time.strftime(ASANA_LOG_TIME_FORMAT)}"
    end
  end

  def pause_task(params)
    cache = Nokogiri::XML(File.open(CACHE_ADDRESS, 'r') { |f| f.read })
    task = cache.xpath("//items/item[@arg='#{params[:task_id]}']").first
    params[:complete] = false
    project, old_status, due_on, _ = parse_subtitle(task.at('subtitle').content)
    if old_status == STATUS_NAMES[:in_progress]
      process_logs(task.xpath("//item[@arg='#{params[:task_id]}']/log"), params)
      quit_anybar(task) if @config[:asana][:anybar_active]
      task.at('subtitle').content = create_subtitle(project, nil, due_on, params[:logged])
      begin
        stop_task(params)
        @result += "#{task.at('title').content} is paused."
      rescue SocketError => e
        File.write(CACHE_ADDRESS, cache.to_xml)
        raise e
      end
      File.write(CACHE_ADDRESS, cache.to_xml)
    else
      @result += "#{task.at('title').content} was not in progress."
    end
  end

  def stop_task(params)
    task_data = get_from_asana("tasks/#{params[:task_id]}")['data']
    if params[:complete] && @config[:asana][:synchronise_due_on_today_active] &&
        task_data['projects'].find { |task_project| task_project['id'] == @config[:asana][:scheduled_project][:id]}
      post_to_asana("tasks/#{params[:task_id]}/removeProject", { :project => @config[:asana][:next_project][:id] })
    end
    task_data['notes'].scan(SYNC_REGEX[:asana_log]) { |log| params[:logs] << log unless params[:logs].include?(log) }
    old_notes = task_data['notes'].gsub(SYNC_REGEX[:asana_log], '')
    new_notes = "#{old_notes}\n#{params[:logs].join("\n")}"
    if params[:complete]
      update_task(params[:task_id], { :notes => old_notes } )
      update_task(params[:task_id], { :completed => true } )
    end
    update_task(params[:task_id], { :notes => new_notes })
    params[:name] = task_data['name']
  end

  def toggle_task_progress(params = {})
    cache = Nokogiri::XML(File.open(CACHE_ADDRESS, 'r') { |f| f.read })
    task = cache.xpath("//items/item[@arg='#{params[:task_id]}']").first
    project, params[:old_status], due_on, _ = parse_subtitle(task.at('subtitle').content)
    process_logs(task.xpath("//item[@arg='#{params[:task_id]}']/log"), params)
    params[:complete] = params[:old_status] == STATUS_NAMES[:in_progress]
    if params[:complete]
      quit_anybar(task) if @config[:asana][:anybar_active]
      begin
        task.remove
        stop_task(params)
        @result += "#{params[:name]} is put to completed."
      rescue SocketError => e
        File.write(CACHE_ADDRESS, cache.to_xml)
        raise e
      end
    else
      start_anybar(task) if @config[:asana][:anybar_active]
      task.remove
      task.add_child("<log start=\"#{params[:time]}\"/>")
      task.at('subtitle').content = create_subtitle(project, STATUS_NAMES[:in_progress], due_on, params[:logged])
      cache.xpath('//items').first.children.before(task)
      @result += "#{task.at('title').content} is put #{STATUS_NAMES[:in_progress]}"
    end
    File.write(CACHE_ADDRESS, cache.to_xml)
  end

  def add_tag(id, tag)
    post_to_asana("tasks/#{id}/addTag", { :tag => tag })
  end

  def create_task(params = {})
    data = { :name => params[:name], :notes => params[:notes] || '', :due_on => params[:due_on] || 'null' }
    data[:projects] = params[:project][:id] if params[:project][:id]
    task = JSON.load(post_to_asana('tasks', data))['data']
    move_task(task['id'], params[:project], params[:section]) if params[:section]
    params[:tags].each { |tag| add_tag(task['id'], tag) } if params[:tags]
    @result += "#{params[:name]} task created. "
    task
  end

  def delete_task(id)
    delete_from_asana("tasks/#{id}")
    @result += 'Task was deleted. '
  end

  def update_task(id, params)
    put_on_asana("tasks/#{id}", params)
  end

  def move_task(id, project, section)
    if section == 'null'
      post_to_asana("tasks/#{id}/addProject", { :project => project[:id], :section => 'null' })
    elsif project[:sections][section]
      post_to_asana("tasks/#{id}/addProject", { :project => project[:id], :section => project[:sections][section] })
    else
      actualize_projects
      if project[:sections][section]
        post_to_asana("tasks/#{id}/addProject", { :project => project[:id], :section => project[:sections][section] })
      else
        new_section = create_task(:name => "#{section}:", :project => project)
        project[:sections][section] = new_section['id']
        post_to_asana("tasks/#{id}/addProject", { :project => project[:id], :section => project[:sections][section] })
      end
    end
  end

  def post_to_asana(resource, pars)
    RestClient.post(
        "https://app.asana.com/api/1.0/#{resource}",
        { :workspace => @config[:asana][:workspace_id], :assignee => @config[:asana][:my_id] }.merge(pars),
        { :Authorization => "Basic #{@config[:asana][:basic_key]}"}
    )
  end

  def get_from_asana(url)
    JSON.load(RestClient.get("https://app.asana.com/api/1.0/#{url}", { :Authorization => "Basic #{@config[:asana][:basic_key]}"}))
  end

  def delete_from_asana(resource)
    RestClient.delete("https://app.asana.com/api/1.0/#{resource}", { :Authorization => "Basic #{@config[:asana][:basic_key]}" })
  end

  def put_on_asana(resource, pars)
    RestClient.put("https://app.asana.com/api/1.0/#{resource}", pars, { :Authorization => "Basic #{@config[:asana][:basic_key]}"})
  end

  def for_each_project
    get_from_asana("projects?workspace=#{@config[:asana][:workspace_id]}")['data'].each { |project| yield project }
  end

  def create_tag(name)
    tag = JSON.load(post_to_asana('tags', { :name => name, :workspace => @config[:asana][:workspace_id]}))['data']
    @config[:asana][:tags][tag['name'].downcase.to_sym] = tag['id']
  end

  def get_tag(tag_name)
    tag_stored_name = tag_name.downcase.to_sym
    actualize_tags unless @config[:asana][:tags][tag_stored_name]
    @config[:asana][:tags][tag_stored_name]
  end

  def get_tasks
    @tasks ||= get_from_asana("tasks?workspace=#{@config[:asana][:workspace_id]}&assignee=me&completed_since=now&opt_fields=due_on,name,completed,parent")['data']
  end

  def get_managed_tasks(except = [])
    tasks = get_next_tasks
    tasks.delete_if { |task| task['name'] =~ /:$/ || except.find { |next_task| next_task.to_i == task['id'] } }
    for_each_project do |project|
      if project['id'] != @config[:asana][:next_project][:id] &&
          project['id'] != @config[:asana][:inbox_project][:id] &&
          project['id'] != @config[:asana][:scheduled_project][:id] &&
          project['id'] != @config[:asana][:someday_project][:id]
        get_tasks_by_project(project).each do |task|
          next_task = tasks.find { |next_task| next_task['id'] == task['id'] }
          next_task['project'] = project['name'] if next_task
        end
      end
    end
    tasks.each do |task|
      all_logged_time = 0
      task['logs'] = []
      task['notes'].scan(SYNC_REGEX[:asana_log]) do |start_time, end_time|
        start_time = Time.strptime("#{start_time}+0200", '%Y-%m-%d %H:%M%z')
        logged_time = nil
        if end_time
          end_time = Time.strptime("#{end_time}+0200", ' - %Y-%m-%d %H:%M%z')
          logged_time = end_time - start_time
          all_logged_time += logged_time
        else
          task['status'] = 'In Progress'
        end
        task['logs'] << [start_time, end_time, logged_time]
      end
      task['logged_time'] = all_logged_time unless all_logged_time == 0
    end
    tasks.sort do |x, y|
      if x['status'] == 'In Progress'
        -1
      else
        y['status'] == 'In Progress' ? 1 : 0
      end
    end
  end

  def get_next_tasks
    @next_tasks ||= get_from_asana("tasks?project=#{@config[:asana][:next_project][:id]}&assignee=me&completed_since=now&opt_fields=id,due_on,name,completed,parent,notes")['data']
  end

  def get_tasks_by_project(project, fields = 'id', completed_since = 'now')
    get_from_asana("tasks?project=#{project['id'] || project[:id]}&assignee=me&completed_since=#{completed_since}&opt_fields=#{fields}")['data']
  end

  def get_tasks_by_tag(tag_key)
    get_from_asana("tasks?tag=#{@config[:asana][:tags][tag_key]}&assignee=me&completed_since=now&opt_fields=id,name")['data']
  end

  def task_exists?(key)
    get_tasks.find { |task| task['name'] =~ /^#{key}/ }
  end
end