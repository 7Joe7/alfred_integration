# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'fulfil_promise', :id => @input.to_i }
communicate do
  update_promise do |promise|
    update_task(@params[:id], { :completed => true })
    @promises.delete(promise)
    @score += 25
    @result += "Promise #{promise[:name]} fulfilled"
  end
end