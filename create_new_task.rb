# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'create') do
  params = parse_input(@input, [:name, :project, :section])
  project, section = @config[:asana][:inbox_project], nil
  if params[:project]
    project_symbol = "#{params[:project]}_project".to_sym
    if @config[:asana][project_symbol]
      project = @config[:asana][project_symbol]
      section = params[:section].to_sym if params[:section] && @config[:asana][project_symbol][:sections][params[:section].to_sym]
    end
  end
  arg = create_task(:name => params[:name], :project => project, :section => section)['id']
  if project[:id] && project[:id] == @config[:asana][:next_project][:id]
    new_task = "<item arg=#{arg}><title>#{params[:name]}</title><subtitle/><icon>icon.png</icon></item>"
    cache = Nokogiri::XML(File.read(CACHE_ADDRESS))
    tasks_in_progress = cache.xpath("//items/item/subtitle[contains(text(), '#{STATUSES[:in_progress][:name]}')]")
    tasks_in_progress.empty? ?
        cache.xpath('//items').first.children.before(new_task) :
        tasks_in_progress.last.after(new_task)
    File.write(CACHE_ADDRESS, cache.to_xml)
  end
end