# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = parse_input(@input, [:project_name, :section_name]).merge(:action => 'Set location for Today')
communicate do
  if @params[:project_name] && !@params[:project_name].empty?
    if File.exists?(CONFIG_PATH)
      @config = JSON.parse(File.read(CONFIG_PATH), :symbolize_names => true)
    else
      Dir.mkdir("#{NVPREFS}#{BUNDLE_ID}") unless Dir.exists?("#{NVPREFS}#{BUNDLE_ID}")
      @config = {}
    end
    @config[:asana] ||= {}
    @config[:asana][:today_project] = {}
    for_each_project do |project|
      if project['name'] == @params[:project_name]
        @config[:asana][:today_project][:name] = @params[:project_name]
        configure_project(:today_project, project)
      end
    end
    if @config[:asana][:today_project].empty?
      puts 'Inserted project was not found, today location set to default.'
    else
      if @params[:section_name]
        section = @params[:section_name].downcase.gsub(' ', '_').to_sym
        @config[:asana][:today_project][:today_section] = section if @config[:asana][:today_project][:sections][section]
      end
      File.write(CONFIG_PATH, JSON.pretty_unparse(@config))
      puts 'Asana location for today tasks is set.'
    end
  else
    puts 'Put location in format <project_name>:<section_name>'
  end
end