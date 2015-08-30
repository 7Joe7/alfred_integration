# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Set sections for Jira tasks') do
  params = parse_input(@input, [:section_in_next, :section_in_scheduled])
  if params[:section_in_next] && !params[:section_in_next].empty?
    if File.exists?(CONFIG_PATH)
      @config = JSON.parse(File.read(CONFIG_PATH), :symbolize_names => true)
    else
      Dir.mkdir("#{NVPREFS}#{BUNDLE_ID}") unless Dir.exists?("#{NVPREFS}#{BUNDLE_ID}")
      @config = {}
    end
    @config[:asana] ||= {}
    for_each_project do |project|
      if project['name'] == @config[:asana][:next_project][:name]
        configure_project(:next_project, project)
      elsif project['name'] == @config[:asana][:scheduled_project][:name]
        configure_project(:scheduled_project, project)
      end
    end
    section_next = params[:section_in_next].downcase.gsub(' ', '_').to_sym
    if @config[:asana][:next_project][:sections][section_next]
      @config[:asana][:next_project][:jira_section] = section_next
      if params[:section_in_scheduled] && !params[:section_in_scheduled].empty?
        section_scheduled = params[:section_in_scheduled].downcase.gsub(' ', '_').to_sym
        if @config[:asana][:scheduled_project][:sections][section_scheduled]
          @config[:asana][:scheduled_project][:jira_section] = section_scheduled
        else
          puts "Inserted section in Scheduled doesn't respond to any existing section."
        end
      end
    else
      puts "Inserted section in Next doesn't respond to any existing section."
    end
    File.write(CONFIG_PATH, JSON.pretty_unparse(@config))
    puts 'Asana location for Jira tasks is set.'
  else
    puts 'Put location in format <section_in_next>:<section_in_scheduled>'
  end
end