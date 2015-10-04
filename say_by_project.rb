# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'Say by Project' }
communicate do
  if @input && @input != ''
    @input.downcase!
    found = false
    for_each_project do |project|
      if project['name'].downcase == @input
        found = true
        get_tasks_by_project(project, 'id,name').each { |task| `say #{task['name'].gsub(/['\(\)]/, '')}` }
        @result += 'Project reviewed.'
      end
    end
    @result += 'Project with such name doesn\'t exist.' unless found
  else
    @result += 'Insert name of project.'
  end
end