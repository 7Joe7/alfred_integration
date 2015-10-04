# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'Say by Tag' }
communicate do
  tag_stored_name = @input.gsub(' ', '_').downcase.to_sym
  actualize_tags unless @config[:asana][:tags][tag_stored_name]
  if @config[:asana][:tags][tag_stored_name]
    tasks = get_tasks_by_tag(tag_stored_name)
    tasks.each { |task| `say #{task['name'].gsub(/['\(\)]/, '')}` }
    @result += 'You have heard your part'
  else
    @result += 'You don\'t have a tag with this name.'
  end
end