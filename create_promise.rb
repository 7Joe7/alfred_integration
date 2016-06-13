# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'create_promise', :name => @input }
communicate do
  load_promises
  @promises << create_promise(@params)
  save_promises
end