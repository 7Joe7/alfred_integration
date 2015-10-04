# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

data = nil
Dir.mkdir "#{NVPREFS}#{BUNDLE_ID}" unless Dir.exists?("#{NVPREFS}#{BUNDLE_ID}")
@params = { :action => 'Log work' }
communicate { File.write(CACHE_ADDRESS, data = get_new_cache) } unless File.exists?(CACHE_ADDRESS)

xml = Nokogiri::XML(data || File.open(CACHE_ADDRESS, 'r') { |f| f.read })
in_progress_tasks = xml.xpath("//items/item/subtitle[contains(text(), '#{STATUSES[:in_progress][:name]}')]/ancestor::item")
in_progress_tasks.each do |task|
  subtitle = task.css('subtitle')[0]
  project, status, due_on, logged = parse_subtitle(subtitle.content)
  start_time = Time.now
  task.css('log').each { |log| start_time = Time.parse(log['start']) unless log['end'] }
  logged += (Time.now - start_time).to_i
  subtitle.content = create_subtitle(project, status, due_on, logged)
end
result = xml.xpath("//items/item/title[contains(translate(text(), '#{@input.upcase}', '#{@input.downcase}'), '#{@input.downcase}')]/ancestor::item")
if result.empty?
  puts "<?xml version=\"1.0\"?><items><item arg='NoMatch' valid='NO'><title>No Match</title><subtitle/><icon>icon.png</icon></item></items>"
else
  puts "<?xml version=\"1.0\"?><items>#{result.to_xml}</items>"
end