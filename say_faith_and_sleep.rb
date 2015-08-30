# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

sleep = nil
communicate(:action => 'Faith recall') do
  actualize_tags unless @config[:asana][:tags][:faith]
  if @config[:asana][:tags][:faith]
    faiths = get_tasks_by_tag(:faith)
    (0..(faiths.size - 1)).to_a.shuffle.take(7).each { |i| `say #{faiths[i]['name'].gsub("'", '')}` }
    sleep = true
    puts 'Faith recalled.'
  else
    puts 'Put your faith under faith tag.'
  end
end

`pmset sleepnow` if sleep