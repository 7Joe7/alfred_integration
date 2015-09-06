# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Future recall') do
  actualize_tags unless @config[:asana][:tags][:future]
  if @config[:asana][:tags][:future]
    future = get_tasks_by_tag(:future)
    future.shuffle.each { |f| `say #{f['name'].gsub(/[']/, '')}`}
    puts 'Future recalled.'
  else
    puts 'Put your future under future tag.'
  end
end

`pmset sleepnow`