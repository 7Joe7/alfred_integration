module AnybarHelper

  ANYBAR_APP_ADDRESS = '/Applications/AnyBar.app'

  def pop_port
    port = nil
    while_ports { |ports| port = ports.pop}
    puts 'Set up new range of ports for AnyBar support.' unless port
    port
  end

  def return_port(port)
    while_ports { |ports| ports << port }
  end

  def while_ports
    if @config[:asana][:anybar_active]
      if File.exists?(PORTS_PATH)
        ports = JSON.parse(File.read(PORTS_PATH), :symbolize_names => true)
        ports.uniq! if ports
        if ports
          yield ports
          File.write(PORTS_PATH, JSON.pretty_unparse(ports))
        else
          puts 'Set up new range of ports for AnyBar support.'
        end
      else
        puts 'Set up AnyBar ports or deactivate AnyBar support.'
      end
    end
  end

  def start_session(port, title)
    `ANYBAR_PORT=#{port} ANYBAR_TITLE="#{title}" open -n #{ANYBAR_APP_ADDRESS}`
  end

  def start_anybar(task, colour)
    port = get_task_anybar_port(task)
    unless port
      port = pop_port
      return unless port
      start_session(port, task.at('title').content)
      task.add_child("<anybar>#{port}</anybar>")
    end
    sleep 2
    anybar(colour, port)
    task.at('icon').content = "pictures/#{colour}@2x.png"
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
      return_port(port)
    end
  end

  def get_task_anybar_port(task, remove = false)
    anybar_element = task.at('anybar')
    port = nil
    if anybar_element
      port = anybar_element.content.to_i
      anybar_element.remove if remove
    end
    port
  end
end