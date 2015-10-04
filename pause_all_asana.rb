# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'Pause all tasks' }
communicate do
  cache = Nokogiri::XML(File.open(CACHE_ADDRESS, 'r') { |f| f.read })
  cache.xpath("//items/item[contains(@subtitle, 'In Progress')]").each do |task|
    status = nil
    project, old_status, due_on, logged = parse_subtitle(task.at('subtitle').content)
    if old_status == 'In Progress'
      last_logs = task.xpath('//item/log[not(@end)]')
      unless last_logs.empty?
        last_log = last_logs.first
        start_time = Time.parse(last_log.attr('start'))
        end_time = Time.now
        logged = logged.to_i + end_time - start_time
        last_log['end'] = end_time
        last_log['logged'] = logged
        formatted_start_time = start_time.strftime(ASANA_LOG_TIME_FORMAT)
        notes = get_from_asana("tasks/#{@input}")['data']['notes']
        notes = "#{notes}\nLog #{formatted_start_time} - #{end_time.strftime(ASANA_LOG_TIME_FORMAT)}"
        update_task(@input, { :notes => notes })
      end
      task.at('subtitle').content = create_subtitle(project, status, due_on, logged)
    end
  end
  File.write(CACHE_ADDRESS, cache.to_xml)
  @result += 'All tasks are paused.'
end