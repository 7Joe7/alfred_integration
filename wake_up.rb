# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

URLS = %w(
  https://www.youtube.com/watch?v=MYSVMgRr6pw&list=PLb8X-a7jz9yXTSZ-o2N0l09sCNmOwqFto
  https://www.youtube.com/watch?v=2vjPBrBU-TM&list=RD2vjPBrBU-TM#t=8
  https://www.youtube.com/watch?v=F3EG4olrFjY&list=RDEMOFv0exLsDkUlvSq0gIvUFQ
  https://www.youtube.com/watch?v=pB-5XG-DbAA&list=RDpB-5XG-DbAA
  https://www.youtube.com/watch?v=F90Cw4l-8NY&list=RDF90Cw4l-8NY
  https://www.youtube.com/watch?v=CfihYWRWRTQ&list=RDEM0Dxei3C_aBxVVglU-yA2CQ
  https://www.youtube.com/watch?v=CGyEd0aKWZE&list=RDEMw4pUX9POHNA4NYoqgKAsuw
  https://www.youtube.com/watch?v=aE2GCa-_nyU&list=RDaE2GCa-_nyU)

communicate(:action => 'Habits Recall') do
  actualize_tags unless @config[:asana][:tags][:habit]
  if @config[:asana][:tags][:habit]
    habits = get_tasks_by_tag(:habit)
    (0..(habits.size - 1)).to_a.shuffle.take(7).each { |i| `say #{habits[i]['name'].gsub("'", '')}` }
  else
    @result += 'You don\'t have a tag with name habit.'
  end
end

`say I am not telling you it is going to be easy, I am telling u it is going to be worth it.`

`say Can u do it?`
`say Will it work?`
`say Is it worth it?`

`open #{URLS[Random.rand(URLS.size)]}`

puts 'I am glad you are still with us :-)'