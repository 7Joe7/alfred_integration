# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'delete_promise', :id => @input.to_i }
communicate do
  update_promise do |promise|
    @promises.delete(promise)
    delete_task(promise[:id])
    @result += "Promise #{promise[:name]} deleted"
  end
end