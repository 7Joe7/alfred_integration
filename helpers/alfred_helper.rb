module AlfredHelper
  def parse_input(input, keys)
    params = {}
    if input =~ /:/
      args = input.split(':')
      args.each_with_index { |arg, i| params[keys[i]] = arg }
    else
      params[keys[0]] = input
      keys[1..-1].each { |key| params[key] = nil }
    end
    params
  end

  def get_items_set(uid_postfix, enumerable)
    Nokogiri::XML::Builder.new do |xml|
      xml.items do
        enumerable.each_with_index do |something, i|
          params = yield something
          uid = uid_postfix ? { 'uid' => "#{i}#{uid_postfix}" } : nil
          item_params = { 'arg' => params[:arg] }
          xml.item(uid ? item_params.merge(uid) : item_params) do
            xml.title params[:title]
            xml.subtitle params[:subtitle]
            xml.status params[:status] if params[:status]
            if params[:logs]
              params[:logs].each do |log|
                log[1] ? xml.log('start' => log[0], 'end' => log[1], 'logged' => log[2]) : xml.log('start' => log[0])
              end
            end
            xml.icon 'icon.png'
          end
        end
      end
    end
  end

  def get_new_cache
    builder = get_items_set(nil, get_managed_tasks) do |task|
      subtitle = create_subtitle(task['project'], task['status'], task['due_on'], task['logged_time'])
      {:arg => task['id'], :title => task['name'], :subtitle => subtitle, :logs => task['logs']}
    end
    Nokogiri::XML(builder.to_xml)
  end

  def create_subtitle(project, status, due_on, logged_time)
    before_block_present, subtitle = false, ''
    if status
      subtitle += status
      before_block_present = true
    end
    if due_on
      subtitle += ' | ' if before_block_present
      subtitle += "Due on #{due_on}"
      before_block_present = true
    end
    if logged_time
      subtitle += ' | ' if before_block_present
      subtitle += "Logged #{create_logged_time(logged_time)}"
      before_block_present = true
    end
    if project
      subtitle += ' | ' if before_block_present
      subtitle += project
    end
    subtitle
  end

  def parse_subtitle(subtitle)
    parsed_subtitle = subtitle.dup
    parsed_subtitle =~ /In Progress/ ? status = 'In Progress' : status = nil
    parsed_subtitle.gsub!(/In Progress/, '')
    due_on = parsed_subtitle.match(/Due on (\d{4}-\d{2}-\d{2})/)
    due_on &&= due_on[1]
    parsed_subtitle.gsub!(/Due on (\d{4}-\d{2}-\d{2})/, '')
    logged = parsed_subtitle.match(/Logged (\d+) hours? and (\d+) minutes?/)
    logged &&= (logged[1].to_i * 3600 + logged[2].to_i * 60)
    parsed_subtitle.gsub!(/Logged (\d+ hours? and \d+ minutes?)/, '')
    parsed_subtitle.gsub!(/ \| /, '')
    project = parsed_subtitle == '' ? nil : parsed_subtitle
    return project, status, due_on, logged
  end

  def process_log_filter_input(input, since)
    params = {:input => input }
    if params[:input] =~ /C/
      params[:input] = params[:input][1..-1]
      params[:complted_only] = true
    elsif params[:input] =~ /I/
      params[:input] = params[:input][1..-1]
      params[:incomplete_only] = true
    end
    if params[:input] =~ /\d{4}-\d{2}-\d{2}/ || params[:input] == 'ever'
      params[:valid] = true
      if since
        params[:mode] = 'since'
        params[:date_since] = params[:input]
        params[:date_match] = '\d{4}-\d{2}-\d{2}'
      elsif params[:input] == 'ever'
        params[:date_since] = '1950-01-01'
        params[:mode] = 'ever'
        params[:date_match] = '\d{4}-\d{2}-\d{2}'
      else
        params[:date_match] = params[:input]
        params[:date_since] = params[:input]
        params[:mode] = 'at'
      end
      params[:regex] = /Log (#{params[:date_match]} \d{2}:\d{2}) - (\d{4}-\d{2}-\d{2} \d{2}:\d{2})/
    end
    params
  end

  def get_incomplete_tasks(tasks, params)
    cache = Nokogiri::XML(File.read(CACHE_ADDRESS))
    logs = []
    case params[:mode]
      when 'at'
        logs = cache.xpath("//items/item/log[contains(@start, '#{params[:date_match]}')]")
      when 'ever'
        logs = cache.xpath('//items/item/log')
      when 'since'
        date = Time.strptime(params[:date_since], '%Y-%m-%d')
        now = Time.new
        until now < date
          logs += cache.xpath("//items/item/log[contains(@start, '#{date.strftime('%Y-%m-%d')}')]")
          date += 86400
        end
      else
    end
    logs.each do |log|
      id = log.parent['arg']
      tasks[id] ||= {}
      tasks[id][:title] ||= log.parent.at('title').content
      tasks[id][:logged] ||= 0
      tasks[id][:logged] += log['logged'].to_i
    end
  end

  def get_completed_tasks(tasks, params)
    date_since = Time.strptime(params[:date_since], '%Y-%m-%d')
    potentially_completed_tasks = get_tasks_by_project(@config[:asana][:next_project], 'id,name,completed,notes', "#{params[:date_since]}T00:00:00.000Z")
    potentially_completed_tasks += get_tasks_by_project(@config[:asana][:scheduled_project], 'id,name,completed,notes', "#{params[:date_since]}T00:00:00.000Z") if @config[:asana][:scheduled_project]
    potentially_completed_tasks.each do |task|
      if task['completed'] && task['notes'] =~ params[:regex]
        all_logged_time = 0
        task['notes'].scan(params[:regex]) do |start_time, end_time|
          start_time = Time.strptime("#{start_time}+0200", '%Y-%m-%d %H:%M%z')
          if date_since < start_time
            end_time = Time.strptime("#{end_time}+0200", '%Y-%m-%d %H:%M%z')
            all_logged_time += end_time - start_time
          end
        end
        id = task['id'].to_s
        tasks[id] ||= {}
        tasks[id][:title] ||= task['name']
        tasks[id][:logged] ||= 0
        tasks[id][:logged] += all_logged_time.to_ i
      end
    end
  end

  def build_filtered_logs(tasks, params)
    Nokogiri::XML::Builder.new do |xml|
      xml.items do
        if params[:valid]
          tasks.each do |id, task|
            xml.item('arg' => id, 'valid' => 'No') do
              xml.title task[:title]
              xml.subtitle "Logged #{create_logged_time(task[:logged].to_i)}."
              xml.icon 'icon.png'
            end
          end
        else
          xml.item('valid' => 'No') do
            xml.title 'Input was not valid, use format YYYY-MM-DD with leading zeros.'
            xml.subtitle ''
            xml.icon 'icon.png'
          end
        end
      end
    end
  end

  def create_logged_time(time)
    time = time.to_i
    hours = (time / 3600)
    minutes = ((time - 3600 * hours) / 60.0).ceil
    "#{hours} #{hours == 1 ? 'hour' : 'hours'} and #{minutes} #{minutes == 1 ? 'minute' : 'minutes'}"
  end

  def filter_logs(tasks, params)
    @params = params.merge(:action => 'View Logs')
    communicate do
      if params[:valid]
        get_completed_tasks(tasks, params) unless params[:incomplete_only]
        get_incomplete_tasks(tasks, params) unless params[:completed_only]
      end
      builder = build_filtered_logs(tasks, params)
      File.write(VIEW_LOGS_ADDRESS, builder.to_xml)
    end
  end

  def sync_cache
    if File.exists?(CACHE_ADDRESS)
      cache = Nokogiri::XML(File.open(CACHE_ADDRESS, 'r') { |f| f.read })
      backup = cache.xpath("//items/item/subtitle[contains(text(), '#{STATUSES[:in_progress][:name]}')]/ancestor::item|//items/item/anybar/ancestor::item").to_a
    else
      backup = []
    end
    now = Time.now
    cache_xml = get_new_cache
    cache_xml.xpath('//items/item').each do |task|
      project, _, due_on, logged = parse_subtitle(task.at('subtitle').content)
      logged ||= 0
      backed_up_task = backup.find { |backup_task| backup_task['arg'] == task['arg'] }
      backup.delete(backed_up_task)
      if backed_up_task
        task.add_child(backed_up_task.at('anybar').dup)
        _, status, _, _ = parse_subtitle(backed_up_task.at('subtitle').content)
        if status == STATUSES[:in_progress][:name]
          unfinished_log = backed_up_task.css('log').find { |log| !log['end'] }
          task.add_child(unfinished_log.dup) if unfinished_log
          start_anybar(task, STATUSES[:in_progress][:colour])
          task.at('subtitle').content = create_subtitle(project, status, due_on, logged)
        elsif @config[:asana][:anybar_active] && due_on && Time.parse(due_on) < now
          start_anybar(task, STATUSES[:behind_schedule][:colour])
        end
      elsif @config[:asana][:anybar_active] && due_on && Time.parse(due_on) < now
        start_anybar(task, STATUSES[:behind_schedule][:colour])
      end
    end
    items = cache_xml.at('//items')
    cache_xml.xpath("//items/item/subtitle[contains(text(), 'Due on ')]/ancestor::item").each do |task|
      items.children.before(task) unless items.children.first == task
    end
    cache_xml.xpath("//items/item/subtitle[contains(text(), '#{STATUSES[:in_progress][:name]}')]/ancestor::item").each do |task|
      items.children.before(task) unless items.children.first == task
    end
    File.write(CACHE_ADDRESS, cache_xml)
    backup.each { |old_task| quit_anybar(old_task) } if @config[:asana][:anybar_active]
  end

  def habit_to_xml(xml, habit, all)
    xml.item('arg' => habit[:id]) do
      xml.title habit[:name]
      xml.subtitle "#{habit[:successes]}/#{habit[:tries]}, longest: #{habit[:longest]}, actual: #{habit[:actual]}#{", repeating: #{habit[:repetition]}" if habit[:repetition]}"
      if all
        xml.subtitle habit[:active] ? 'Stop pursuing habit' : 'Pursue habit daily', 'mod' => 'cmd'
        xml.subtitle habit[:active] ? 'Stop pursuing habit' : 'Pursue habit weekly', 'mod' => 'alt'
      end
      xml.icon habit[:active] ? "pictures/#{get_habit_colour(habit)}@2x.png" : 'pictures/black@2x.png'
    end
  end

  def get_habit_colour(habit)
    if habit[:done].nil?
      if habit[:only_on_deadline]
        'cyan'
      else
        if habit[:actual] < 21
          'orange'
        elsif habit[:actual] < 49
          'yellow'
        else
          'white'
        end
      end
    else
      habit[:done] ? 'green' : 'red'
    end
  end
end