module HabitsHelper

  def load_habits
    @habits ||= JSON.parse(File.read(HABITS_PATH), :symbolize_names => true)
    @habits.each do |habit|
      habit[:deadline] &&= Time.parse(habit[:deadline])
      habit[:last_streak_end_date] &&= Time.parse(habit[:last_streak_end_date])
      habit[:start] &&= Time.parse(habit[:start])
      habit[:created] &&= Time.parse(habit[:created])
    end
    @habits
  end

  def save_habits(habits)
    habits_to_save = habits.dup
    habits_to_save.each do |habit_to_save|
      habit_to_save[:deadline] &&= habit_to_save[:deadline].to_date
      habit_to_save[:last_streak_end_date] &&= habit_to_save[:last_streak_end_date].to_date
      habit_to_save[:start] &&= habit_to_save[:start].to_date
      habit_to_save[:created] &&= habit_to_save[:created].to_date
    end
    File.write(HABITS_PATH, JSON.pretty_unparse(habits_to_save))
  end

  def update_habit(params)
    habits = load_habits
    habit = @habits.find { |habit| habit[:id] == params[:id] }
    if block_given?
      habits.delete(habit)
      yield habit, [habit] + habits
    end
    update_task(habit[:id], {notes: get_habit_notes(habit)})
    habit
  end

  def create_habit(params)
    create_task({ name: params[:name], tags: [@config[:asana][:tags][:habit]]})
  end

  def fail_habit(habit)
    @now ||= Time.now
    habit[:last_streak_end_date] = @now
    habit[:last_streak_length] = habit[:actual]
    habit[:done] = false
    habit[:tries] += 1
    habit[:actual] = 0
  end

  def habit_done(habit)
    habit[:done] = true
    habit[:successes] += 1
    habit[:tries] += 1
    habit[:actual] += 1
    habit[:longest] = habit[:actual] if habit[:actual] > habit[:longest]
  end

  def verify_habits(habits)
    @now ||= Time.now
    needs_saving = false
    active_habits = habits.find_all { |habit| habit[:active] }
    active_habits.each do |habit|
      if habit[:deadline] < @now
        needs_saving = true
        done = habit[:done]
        habit.delete(:done)
        if habit[:repetition] == 'daily'
          habit[:deadline] = habit[:deadline] + 86400
        elsif habit[:repetition] == 'weekly'
          habit[:deadline] = habit[:deadline] + 7 * 86400
        end
        update_fail_habit(habit) if done.nil?
      end
      needs_saving ||= resolve_anybar_port(habit)
    end
    needs_saving
  end

  def update_fail_habit(habit)
    fail_habit(habit)
    habit.delete(:done)
    update_task(habit[:id], {notes: get_habit_notes(habit)})
  end

  def to_habit(task)
    @today ||= Time.now.to_date
    habit = { :id => task['id'], :name => task['name'], :created => @today, :active => false, :successes => 0, :tries => 0, :longest => 0, :actual => 0, :last_streak_end_date => nil, :last_streak_length => 0, :notes => task['notes'] }
    task['notes'].match(/created: (?<created>\d{4}-\d{1,2}-\d{1,2})\nactive: (?<active>\w+)\nsuccesses: (?<successes>\d+)\/(?<tries>\d+)\nlongest: (?<longest>\d+)\nactual: (?<actual>\d+)\nlast_streak_end_date: ?(?<last_streak_end_date>\d{4}-\d{1,2}-\d{1,2})?\nlast_streak_length: ?(?<last_streak_length>\d+)\nrepetition: (?<repetition>\w*?)\nstart: (?<start>\d{4}-\d{1,2}-\d{1,2})\ndeadline: (?<deadline>\d{4}-\d{1,2}-\d{1,2})?\ndone: ?(?<done>\w*)\nonly_on_deadline: ?(?<only_on_deadline>\w*)/) do |match|
      habit[:created] = match[:created] ? Time.parse(match[:created]) : nil
      habit[:active] = match[:active] == 'true'
      habit[:successes] = match[:successes].to_i
      habit[:tries] = match[:tries].to_i
      habit[:longest] = match[:longest].to_i
      habit[:actual] = match[:actual].to_i
      habit[:last_streak_end_date] = match[:last_streak_end_date] ? Time.parse(match[:last_streak_end_date]) : nil
      habit[:last_streak_length] = match[:last_streak_length].to_i
      habit[:repetition] = match[:repetition]
      habit[:start] = match[:start] ? Time.parse(match[:start]) : nil
      habit[:deadline] = match[:deadline] ? Time.parse(match[:deadline]) : nil
      if match[:done] == 'true'
        habit[:done] = true
      elsif match[:done] == 'false'
        habit[:done] = false
      else
        habit[:done] = nil
      end
      habit[:only_on_deadline] = match[:only_on_deadline] == 'true'
      habit[:notes] = task['notes'].sub(match[0], '')
    end
    habit
  end

  def get_habit_notes(habit)
    notes = ''
    if habit[:notes]
      notes = habit[:notes]
      notes += "\n" unless notes[-1] == "\n"
    end
    notes + "created: #{habit[:created] && habit[:created].to_date}\nactive: #{habit[:active]}\nsuccesses: #{habit[:successes]}/#{habit[:tries]}\nlongest: #{habit[:longest]}\nactual: #{habit[:actual]}\nlast_streak_end_date: #{habit[:last_streak_end_date] && habit[:last_streak_end_date].to_date}\nlast_streak_length: #{habit[:last_streak_length]}\nrepetition: #{habit[:repetition]}\nstart: #{habit[:start] && habit[:start].to_date}\ndeadline: #{habit[:deadline] && habit[:deadline].to_date}\ndone: #{habit[:done].nil? ? '' : habit[:done]}\nonly_on_deadline: #{habit[:only_on_deadline]}"
  end

  def get_habit_colour(habit)
    @now ||= Time.now
    if is_resolved_for_this_period?(habit)
      habit[:done] ? 'green' : 'red'
    else
      if habit[:only_on_deadline] && !is_day_before_deadline?(habit)
        'cyan'
      else
        if habit[:actual] < 21
          'orange'
        elsif habit[:actual] < 49
          'yellow'
        else
          'white'
        end
      end
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
end