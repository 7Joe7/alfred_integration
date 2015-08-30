# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

begin
  params = parse_input(@input, [:username, :password, :hostname])
  if params[:username] && !params[:username].empty? && params[:password] && !params[:password].empty? && params[:hostname] && !params[:hostname].empty?
    if File.exists?(CONFIG_PATH)
      @config = JSON.parse(File.read(CONFIG_PATH), :symbolize_names => true)
    else
      Dir.mkdir("#{NVPREFS}#{BUNDLE_ID}") unless Dir.exists?("#{NVPREFS}#{BUNDLE_ID}")
      @config = {}
    end
    @config[:jira] ||= {}
    @config[:jira][:credentials] ||= {}
    @config[:jira][:credentials][:username] = params[:username]
    @config[:jira][:credentials][:password] = params[:password]
    @config[:jira][:credentials][:hostname] = params[:hostname]
    File.write(CONFIG_PATH, JSON.pretty_unparse(@config))
    puts 'Jira credentials are set.'
  else
    puts 'Put username, password and hostname in format <username>:<password>:<hostname>.'
  end
rescue Exception => e
  File.write(LOGS_ADDRESS, "#{e}, #{e.backtrace}")
  puts 'Setting Asana credentials failed, check format of input.'
end