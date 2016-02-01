module HabitsHelper

  def update_habit(params)
    habits = JSON.parse(File.read(HABITS_PATH), :symbolize_names => true)
    habit = habits.find { |habit| habit[:id] == params[:id] }
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
    habit[:last_streak_end_date] = @now.to_date
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
    @now = Time.now
    save = false
    active_habits = habits.find_all { |habit| habit[:active] }
    active_habits.each do |habit|
      if (deadline = Time.parse(habit[:deadline])) < @now
        save = true
        done = habit[:done]
        habit.delete(:done)
        if habit[:repetition] == 'daily'
          habit[:deadline] = (deadline + 86400).to_date
        elsif habit[:repetition] == 'weekly'
          habit[:deadline] = (deadline + 7 * 86400).to_date
        end
        update_fail_habit(habit) if done.nil?
      end
    end
    save
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
      habit[:created] = match[:created]
      habit[:active] = match[:active] == 'true'
      habit[:successes] = match[:successes].to_i
      habit[:tries] = match[:tries].to_i
      habit[:longest] = match[:longest].to_i
      habit[:actual] = match[:actual].to_i
      habit[:last_streak_end_date] = match[:last_streak_end_date] ? Time.parse(match[:last_streak_end_date]) : nil
      habit[:last_streak_length] = match[:last_streak_length].to_i
      habit[:repetition] = match[:repetition]
      habit[:start] = match[:start]
      habit[:deadline] = match[:deadline]
      if Time.parse(match[:deadline]) > Time.now
        if match[:done] == 'true'
          habit[:done] = true
        elsif match[:done] == 'false'
          habit[:done] = false
        else
          habit[:done] = nil
        end
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
    notes + "created: #{habit[:created]}\nactive: #{habit[:active]}\nsuccesses: #{habit[:successes]}/#{habit[:tries]}\nlongest: #{habit[:longest]}\nactual: #{habit[:actual]}\nlast_streak_end_date: #{habit[:last_streak_end_date]}\nlast_streak_length: #{habit[:last_streak_length]}\nrepetition: #{habit[:repetition]}\nstart: #{habit[:start]}\ndeadline: #{habit[:deadline]}\ndone: #{habit[:done].nil? ? '' : habit[:done]}\nonly_on_deadline: #{habit[:only_on_deadline]}"
  end
end