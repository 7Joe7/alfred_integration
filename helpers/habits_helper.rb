module HabitsHelper

  def load_habits
    @habits ||= JSON.parse(File.read(HABITS_PATH), :symbolize_names => true)
    @habits.each do |habit|
      habit[:deadline] &&= Time.parse(habit[:deadline])
      habit[:last_streak_end_date] &&= Time.parse(habit[:last_streak_end_date])
      habit[:start] &&= Time.parse(habit[:start])
      habit[:created] &&= Time.parse(habit[:created])
      habit[:priority] ||= 9
    end
    @habits.sort_by! { |habit| get_order(habit) }
    File.exists?(SCORE_PATH) ? @score = File.read(SCORE_PATH).to_i : @score = 0
  end

  def save_habits(habits = @habits)
    File.write(HABITS_PATH, JSON.pretty_unparse(habits))
    File.write(SCORE_PATH, @score)
  end

  def load_promises
    @promises ||= JSON.parse(File.read(PROMISES_PATH), :symbolize_names => true)
    @promises.each do |promise|
      promise[:deadline] &&= Time.parse(promise[:deadline])
      promise[:created] &&= Time.parse(promise[:created])
    end
    File.exists?(SCORE_PATH) ? @score = File.read(SCORE_PATH).to_i : @score = 0
  end

  def save_promises(promises = @promises)
    File.write(PROMISES_PATH, JSON.pretty_unparse(promises))
    File.write(SCORE_PATH, @score)
  end

  def update_habit
    load_habits
    habit = @habits.find { |habit| habit[:id] == @params[:id] }
    verify_habit(habit) if habit[:active] && !habit[:opportunity]
    @habits.delete(habit)
    @habits.unshift(habit)
    yield habit
    save_habits
  end

  def update_promise
    load_promises
    promise = @promises.find { |promise| promise[:id] == @params[:id] }
    @promises.delete(promise)
    @promises.unshift(promise)
    yield promise
    save_promises
  end

  def create_habit(params)
    to_habit(create_task({ name: params[:name], tags: [@config[:asana][:tags][:habit]]}))
  end

  def create_promise(params)
    to_promise(create_task({name: params[:name], tags: [@config[:asana][:tags][:promise]]}))
  end

  def fail_habit(habit)
    habit[:tries] += 1
    if habit[:actual] > 0
      habit[:last_streak_end_date] = habit[:deadline]
      habit[:last_streak_length] = habit[:actual]
      habit[:actual] = -1
    else
      habit[:actual] -= 1
    end
    @score -= habit[:actual] * (10 - habit[:priority])
  end

  def set_habit_done(habit)
    habit[:done] = true unless habit[:opportunity]
    habit[:successes] += 1
    habit[:tries] += 1
    habit[:actual] = 0 if habit[:actual] < 0
    habit[:actual] += 1
    @score += habit[:actual] * (10 - habit[:priority])
    habit[:longest] = habit[:actual] if habit[:actual] > habit[:longest]
    habit[:actual] >= 49
  end

  def verify_habits
    active_habits = @habits.find_all { |habit| habit[:active] }
    active_habits.each { |habit| verify_habit(habit) unless habit[:opportunity]}
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
    # resolve_anybar_port(habit)
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

  def to_promise(task)
    @now ||= Time.now
    @today ||= Time.new(@now.year, @now.month, @now.day)
    { :id => task['id'],
      :name => task['name'],
      :created => @today,
      :notes => task['notes'] }
  end

  def process_properties(habit)
    @now ||= Time.now
    if !habit[:done].nil?
      if habit[:done]
        habit[:order] = "5#{habit[:priority]}".to_i
        habit[:colour] = 'green'
      else
        habit[:order] = "4#{habit[:priority]}".to_i
        habit[:colour] = 'red'
      end
    elsif habit[:opportunity]
      habit[:order] = "6#{habit[:priority]}".to_i
      habit[:colour] = 'cyan'
    elsif habit[:only_on_deadline] && !is_day_before_deadline?(habit)
      habit[:order] = "7#{habit[:priority]}".to_i
      habit[:colour] = 'cyan'
    elsif habit[:actual] < 21
      habit[:order] = "1#{habit[:priority]}".to_i
      habit[:colour] = 'orange'
    elsif habit[:actual] < 49
      habit[:order] = "2#{habit[:priority]}".to_i
      habit[:colour] = 'yellow'
    else
      habit[:order] = "3#{habit[:priority]}".to_i
      habit[:colour] = 'green'
    end
  end

  def get_order(habit)
    process_properties(habit)
    habit[:order]
  end

  def get_habit_colour(habit)
    process_properties(habit)
    habit[:colour]
  end

  def promise_to_xml(xml, promise)
    @now ||= Time.now
    xml.item('arg' => promise[:id]) do
      xml.title promise[:name]
      xml.subtitle "#{"Created: #{promise[:created]}, " if promise[:created]}#{"Deadline: #{promise[:deadline]}, " if promise[:deadline]}Notes: #{promise[:notes]}"
      xml.icon (promise[:deadline] && promise[:deadline] < @now) ? 'pictures/red@2x.png' : 'pictures/blue@2x.png'
    end
  end

  def habit_to_xml(xml, habit, all)
    xml.item('arg' => habit[:id]) do
      xml.title habit[:name]
      xml.subtitle "#{habit[:successes]}/#{habit[:tries]} #{habit[:tries] == 0 ? 0 : (habit[:successes].to_f * 100 / habit[:tries]).round}%, longest: #{habit[:longest]}, actual: #{habit[:actual]}#{", repeating: #{habit[:repetition]}" if habit[:repetition]}#{", #{habit[:deadline].to_date}" if habit[:repetition] == 'weekly'}#{', opportunity' if habit[:opportunity]}"
      if all
        xml.subtitle habit[:active] ? 'Stop pursuing habit' : 'Pursue habit daily', 'mod' => 'cmd'
        xml.subtitle habit[:active] ? 'Stop pursuing habit' : 'Pursue habit weekly', 'mod' => 'alt'
      end
      xml.icon (
               if habit[:active]
                 "pictures/#{get_habit_colour(habit)}@2x.png"
               else
                 habit[:actual] > 49 ? 'pictures/green@2x.png' : 'pictures/black@2x.png'
               end)
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