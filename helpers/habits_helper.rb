module HabitsHelper

  def load_habits
    @habits ||= JSON.parse(File.read(HABITS_PATH), :symbolize_names => true)
    @habits.each do |habit|
      habit[:deadline] &&= Time.parse(habit[:deadline])
      habit[:last_streak_end_date] &&= Time.parse(habit[:last_streak_end_date])
      habit[:start] &&= Time.parse(habit[:start])
      habit[:created] &&= Time.parse(habit[:created])
    end
  end

  def save_habits(habits = @habits)
    File.write(HABITS_PATH, JSON.pretty_unparse(habits))
  end

  def update_habit
    load_habits
    habit = @habits.find { |habit| habit[:id] == @params[:id] }
    verify_habit(habit) if habit[:active]
    @habits.delete(habit)
    @habits.unshift(habit)
    yield habit
    save_habits
  end

  def create_habit(params)
    to_habit(create_task({ name: params[:name], tags: [@config[:asana][:tags][:habit]]}))
  end

  def fail_habit(habit)
    habit[:last_streak_end_date] = habit[:deadline]
    habit[:last_streak_length] = habit[:actual]
    habit[:tries] += 1
    habit[:actual] = 0
  end

  def set_habit_done(habit)
    habit[:done] = true
    habit[:successes] += 1
    habit[:tries] += 1
    habit[:actual] += 1
    habit[:longest] = habit[:actual] if habit[:actual] > habit[:longest]
  end

  def verify_habits
    active_habits = @habits.find_all { |habit| habit[:active] }
    active_habits.each { |habit| verify_habit(habit) }
  end

  def verify_habit(habit)
    @now ||= Time.now
    until habit[:deadline] > @now
      habit[:done].nil? ? fail_habit(habit) : habit.delete(:done)
      case habit[:repetition]
        when 'daily' then habit[:deadline] += 86400
        when 'weekly' then habit[:deadline] += 7 * 86400
        else
          break
      end
    end
    resolve_anybar_port(habit)
  end

  def to_habit(task)
    @now ||= Time.now
    @today ||= Time.new(@now.year, @now.month, @now.day)
    { :id => task['id'],
      :name => task['name'],
      :created => @today,
      :active => false,
      :successes => 0,
      :tries => 0,
      :longest => 0,
      :actual => 0,
      :last_streak_length => 0,
      :notes => task['notes'] }
  end

  def get_habit_colour(habit)
    @now ||= Time.now
    if !habit[:done].nil?
       habit[:done] ? 'green' : 'red'
    elsif habit[:only_on_deadline] && !is_day_before_deadline?(habit)
      'cyan'
    elsif habit[:actual] < 21
      'orange'
    elsif habit[:actual] < 49
      'yellow'
    else
      'white'
    end
  end

  def habit_to_xml(xml, habit, all)
    xml.item('arg' => habit[:id]) do
      xml.title habit[:name]
      xml.subtitle "#{habit[:successes]}/#{habit[:tries]} #{habit[:tries] == 0 ? 0 : (habit[:successes].to_f * 100 / habit[:tries]).round}%, longest: #{habit[:longest]}, actual: #{habit[:actual]}#{", repeating: #{habit[:repetition]}" if habit[:repetition]}"
      if all
        xml.subtitle habit[:active] ? 'Stop pursuing habit' : 'Pursue habit daily', 'mod' => 'cmd'
        xml.subtitle habit[:active] ? 'Stop pursuing habit' : 'Pursue habit weekly', 'mod' => 'alt'
      end
      xml.icon habit[:active] ? "pictures/#{get_habit_colour(habit)}@2x.png" : 'pictures/black@2x.png'
    end
  end

  def sync_habits
    if File.exists?(HABITS_PATH)
      load_habits
      verify_habits
    end
    actualize_tags unless @config[:asana][:tags][:habit]
    if @config[:asana][:tags][:habit]
      new_habits = []
      get_tasks_by_tag(:habit).each do |task|
        habit = to_habit(task)
        old_habit = @habits.find { |old_habit| old_habit[:id] == habit[:id] }
        old_habit[:notes] = habit[:notes]
        old_habit[:name] = habit[:name]
        new_habits << old_habit
      end
      save_habits(new_habits)
    else
      @result += "You don't have habit tag"
    end
  end

  def resolve_anybar_port(habit)
    if !habit[:active] || is_resolved_for_this_period?(habit) || (habit[:only_on_deadline] && !is_day_before_deadline?(habit))
      quit_habit_port(habit) if habit[:port]
    elsif habit[:port] # do nothing
    elsif !habit[:only_on_deadline] || is_day_before_deadline?(habit)
      start_habit_port(habit)
    end
  end

  def is_resolved_for_this_period?(habit)
    !habit[:done].nil? && habit[:deadline] > @now
  end

  def is_day_before_deadline?(habit)
    habit[:deadline] > @now && habit[:deadline] < (@now + 86400)
  end
end