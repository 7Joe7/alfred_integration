# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = parse_input(@input, [:name, :project, :section]).merge(:action => 'create', :label => "Creation of task #{@input}")
communicate do
  @params[:project] = @params[:project] ? @config[:asana]["#{@params[:project]}_project".to_sym] : @config[:asana][:inbox_project]
  arg = create_task(:name => @params[:name], :project => @params[:project], :section => @params[:section])['id']
  if @params[:project] && @params[:project][:id] && @params[:project][:id] == @config[:asana][:next_project][:id]
    new_task = "<item arg=#{arg}><title>#{@params[:name]}</title><subtitle/><icon>icon.png</icon></item>"
    cache = Nokogiri::XML(File.read(CACHE_ADDRESS))
    tasks_in_progress = cache.xpath("//items/item/subtitle[contains(text(), '#{STATUSES[:in_progress][:name]}')]")
    tasks_in_progress.empty? ?
        cache.xpath('//items').first.children.before(new_task) :
        tasks_in_progress.last.after(new_task)
    File.write(CACHE_ADDRESS, cache.to_xml)
  end
end