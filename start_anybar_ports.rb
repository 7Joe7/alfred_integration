# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Start AnyBar Ports') do
  cache = Nokogiri::XML(File.open(CACHE_ADDRESS, 'r') { |f| f.read })
  tasks = cache.xpath('//items/item/anybar/ancestor::item').to_a
  tasks.each do |task|
    start_session(task.at('anybar').content.to_i, task)
    sleep 2
    (task.at('subtitle').content =~ /#{STATUSES[:in_progress][:name]}/) ?
        start_anybar(task, STATUSES[:in_progress][:colour]) :
        start_anybar(task, STATUSES[:behind_schedule][:colour])
  end
  @result = 'AnyBar ports started.'
end