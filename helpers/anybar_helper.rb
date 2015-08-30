module AnybarHelper

  ANYBAR_APP_ADDRESS = '/Applications/AnyBar.app'

  def start_session(port, task)
    `ANYBAR_PORT=#{port} ANYBAR_TITLE="#{task.at('title').content}" open -n #{ANYBAR_APP_ADDRESS}`
  end

  def start_anybar(task)
    port = get_task_anybar_port(task)
    unless port
      port = @config[:anybar][:ports].pop
      start_session(port, task)
      task.add_child("<anybar>#{port}</anybar>")
    end
    sleep 2
    anybar('blue', port)
    task.at('icon').content = 'pictures/blue@2x.png'
  end

  def anybar(command, port)
    any_bar = UDPSocket.new
    any_bar.connect 'localhost', port
    any_bar.send command, 0
    any_bar.close
  end

  def quit_anybar(task)
    port = get_task_anybar_port(task, true)
    if port
      anybar('quit', port)
      task.at('icon').content = 'icon.png'
      @config[:anybar][:ports] << port
    end
  end

  def pause_anybar(task)
    port = get_task_anybar_port(task)
    unless port
      port = @config[:anybar][:ports].pop
      start_session(port, task)
    end
    anybar('yellow', port)
    task.at('icon').content = 'pictures/yellow@2x.png'
  end

  def get_task_anybar_port(task, remove = false)
    anybar_elements = task.xpath("//item[@arg='#{task['arg']}']/anybar")
    port = nil
    unless anybar_elements.empty?
      port = anybar_elements.first.content.to_i
      anybar_elements.remove if remove
    end
    port
  end
end