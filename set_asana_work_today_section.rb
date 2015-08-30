# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Set work location for today') do
  params = parse_input(@input, [:project_name, :today_section])
  if params[:project_name] && !params[:project_name].empty?
    if File.exists?(CONFIG_PATH)
      @config = JSON.parse(File.read(CONFIG_PATH), :symbolize_names => true)
    else
      Dir.mkdir("#{NVPREFS}#{BUNDLE_ID}") unless Dir.exists?("#{NVPREFS}#{BUNDLE_ID}")
      @config = {}
    end
    @config[:asana] ||= {}
    @config[:asana][:work_project] = {}
    for_each_project do |project|
      if project['name'] == params[:project_name]
        @config[:asana][:work_project][:name] = params[:project_name]
        configure_project(:work_project, project)
      end
    end
    if @config[:asana][:work_project].empty?
      puts 'Inserted project was not found, today location set to default.'
    else
      if params[:today_section]
        section = params[:today_section].downcase.gsub(' ', '_').to_sym
        @config[:asana][:work_project][:today_section] = section if @config[:asana][:work_project][:sections][section]
      end
      File.write(CONFIG_PATH, JSON.pretty_unparse(@config))
      puts 'Asana location for today work tasks is set.'
    end
  else
    puts 'Put location in format <project_name>:<section_name>:<today_section_name>'
  end
end