# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'delete', :id => @input, :label => 'Deletion of task' }
communicate do
  cache = Nokogiri::XML(File.open(CACHE_ADDRESS, 'r') { |f| f.read })
  task = cache.xpath("//items/item[@arg='#{@input}']").first
  quit_anybar(task)
  task.remove
  File.write(CACHE_ADDRESS, cache.to_xml)
  delete_task(@input)
end