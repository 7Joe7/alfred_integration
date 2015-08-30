# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

# params = {}
# params[:task_id] = 45347987957689
# cache = Nokogiri::XML(File.open(CACHE_ADDRESS, 'r') { |f| f.read })
# task = cache.xpath("//items/item[@arg='#{params[:task_id]}']").first
# start_anybar(task)

anybar('blue', 1799)