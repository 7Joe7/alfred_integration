# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'Start AnyBar Ports'}
communicate do
  if @config[:asana][:anybar_active]
    cache = Nokogiri::XML(File.open(CACHE_ADDRESS, 'r') { |f| f.read })
    tasks = cache.xpath('//items/item/anybar/ancestor::item').to_a
    tasks.each do |task|
      start_session(task.at('anybar').content.to_i, task.at('title').content)
      (task.at('subtitle').content =~ /#{STATUSES[:in_progress][:name]}/) ?
          start_anybar(task, STATUSES[:in_progress][:colour]) :
          start_anybar(task, STATUSES[:behind_schedule][:colour])
    end
    load_habits
    # @habits.each { |habit| start_habit_port(habit) if habit[:port] && habit[:active] }
    @result = 'AnyBar ports started.'
  end
end