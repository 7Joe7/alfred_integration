# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = parse_input(@input, [:next_jira_project, :section_in_next, :section_in_scheduled]).merge(:action => 'Set sections for Jira tasks')
communicate do
  if @params[:next_jira_project] && !@params[:next_jira_project].empty?
    if File.exists?(CONFIG_PATH)
      @config = JSON.parse(File.read(CONFIG_PATH), :symbolize_names => true)
    else
      Dir.mkdir("#{NVPREFS}#{BUNDLE_ID}") unless Dir.exists?("#{NVPREFS}#{BUNDLE_ID}")
      @config = {}
    end
    @config[:asana] ||= {}
    project_found = false
    for_each_project do |project|
      if project['name'] == @params[:next_jira_project]
        configure_project(:next_jira_project, project)
        project_found = true
      elsif project['name'] == @config[:asana][:scheduled_project][:name]
        configure_project(:scheduled_project, project)
      end
    end
    if project_found
      if @params[:section_in_next] && !@params[:section_in_next].empty?
        section_next = @params[:section_in_next].downcase.gsub(' ', '_').to_sym
        if @config[:asana][:next_jira_project][:sections][section_next]
          @config[:asana][:next_jira_project][:jira_section] = section_next
          if @params[:section_in_scheduled] && !@params[:section_in_scheduled].empty?
            section_scheduled = @params[:section_in_scheduled].downcase.gsub(' ', '_').to_sym
            if @config[:asana][:scheduled_project][:sections][section_scheduled]
              @config[:asana][:scheduled_project][:jira_section] = section_scheduled
            else
              @result += "Inserted section in Scheduled doesn't respond to any existing section."
            end
          end
        else
          @result += "Inserted section in Next doesn't respond to any existing section."
        end
      end
      File.write(CONFIG_PATH, JSON.pretty_unparse(@config))
      @result += 'Asana location for Jira tasks is set.'
    else
      @result += "Project #{@params[:next_jira_project]} doesn't exist"
    end
  else
    @result += 'Put location in format <next_jira_project>:<section_in_next>:<section_in_scheduled>'
  end
end