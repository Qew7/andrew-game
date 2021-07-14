CLASSES = {
  warrior: { str: 15, agi: 10, sta: 15, int: 5 },
  rogue: { str: 10, agi: 15, sta: 10, int: 5 },
  mage: { str: 5, agi: 5, sta: 10, int: 20 }
}

IMPROVED_CLASSES = {
  warrior: {
    barbarian: { str: 20, agi: 15, sta: 20, int: 5 },
    paladin: { str: 15, agi: 15, sta: 20, int: 15 }
  },
  rogue: {
    thief: { str: 10, agi: 20, sta: 15, int: 10 },
    monk: { str: 15, agi: 15, sta: 20, int: 10 }
  },
  mage: {
    necromant: { str: 5, agi: 5, sta: 15, int:30 },
    druid: { str: 10, agi: 10, sta: 20, int: 25 }
  }
}

CLASSES_BATTLE_ABILITIES = {
  warrior: :multiple_attack,
  barbarian: :reduced_damage,
  paladin: :holy_heal,
  rogue: :backstab,
  thief: :steal_gold,
  monk: :peace,
  mage: :arcane_aura,
  necromant: :life_drain,
  druid: :nature_heal,
}

MONSTERS = {
  roach: { str: 2 , agi: 5, sta: 5, int: 0 },
  creep: { str: 3, agi: 6, sta: 6, int: 0 },
  goblin: { str: 5, agi: 5, sta: 7, int:0 },
  goblin_shaman: { str: 5, agi: 5, sta: 9, int: 5 },
  cringe: { str: 10, agi: 7, sta: 11, int: 7 },
  ghost: { str: 12, agi: 9, sta: 13, int: 9 },
  redneck: { str: 15, agi: 11, sta: 15, int: 5},
}

MONSTER_ATTACKS = [
  'lunges at you',
  'bites you',
  'swings at you',
  'punches you',
  'kicks you',
  'scratches you',
]

CITY_FIRST_NAMES = %w[
  Edru
  Morgu
  Bara
  Tar
  Mork
  Erka
  Jino
]

CITY_LAST_NAMES = %w[
  gend
  burg
  land
  town
  beld
  stan
]

WEATHER_DESCRIPTIONS = [
  'lifless grey',
  'hammering rain',
  'piercing wind',
  'deafening storm',
  'black as night',
  'dead quiet',
  'cloudburst',
  'soup-thick mist',
  'cracling frost',
  'irritating drizzle',
  'roaring thunder',
  'gravelike cold',
]

DUNGEON_DESCRIPTIONS = [
  'you sense rotten stench, its hot here',
  'its cool, slightly smoky air everywhere',
  'you cant handle this repulsive stench of death and gore, you see bodies everywhere',
  'you sense subtle smell of sulfur',
  'its dimly lit, weirdly chilly and windy here',
  'stuffy air is reeking of sulfur',
  'air here is very stale, its hard to breath',
  'you sense vomit-inducing smell of rotting remains',
]
require 'io/console'
require 'byebug'

def enter_dungeon
  @dungeon_lvl = 1
  rooms_count = 0
  left_dungeon_alive = false
  puts "You've entered the dungeon, #{DUNGEON_DESCRIPTIONS.sample}"
  until left_dungeon_alive do
    aviable_commands(%w[forth leave status])
    input = player_input
    (new_room(rooms_count) && rooms_count += 1) if input == 'forth'
    player_description if input == 'status'
    (try_to_leave && (left_dungeon_alive = true)) if input == 'leave'
  end
end

def try_to_leave
  dungeon_lvl.times do
    roll = roll_dice(20)
    if (roll - dungeon_lvl) <= 10
      puts "You've encountered enemies while trying to surface"
      monster_encounter
    end
    if roll == 1
      puts "You've found yourself in a trap while trying to surface"
      trap_encounter
    end
  end
end

def dungeon_lvl
  @dungeon_lvl
end

def new_room(rooms_count)
  delve_chance = 20 - player[:lvl] + dungeon_lvl - rooms_count
  case roll_dice(20)
  when 1
    trap_encounter
  when 2..6
    print 'room is empty'
  when 7..(delve_chance - 1)
    monster_encounter
  when delve_chance..20
    puts 'You found a way to delve deeper into dungeon'
    @dungeon_lvl += 1
  end
end

def trap_encounter
end

def monster_encounter
  encounter_monsters = []
  monster_names = []
  roll_dice(dungeon_lvl).times do
    name = MONSTERS.keys.sample
    encounter_monsters << {
      name: name,
      stats: MONSTERS[name],
      hp: MONSTERS[name][:sta] + MONSTERS[name][:str],
      attack: MONSTERS[name][:agi] + 20,
      dmg: (MONSTERS[name][:str]/3..MONSTERS[name][:str]),
    }
  end
  monster_names = encounter_monsters.map { |m| m[:name] }
  puts "You've encountered #{monster_names.map{|mn| mn.to_s.gsub('_', ' ')}.join(', ')}"
  if player_input == 'run' && roll_dice(20) > 17
    puts 'Succesfully run away'
  else
    fight(encounter_monsters)
  end
  puts "You've survived"
  award(encounter_monsters)
end

def award(monsters)
  gold_amount = rand(monsters.count..monsters.sum { |m| m[:stats][:sta] + m[:stats][:str] })
  puts "You've found #{gold_amount} gold pieces"
  player[:inventory][:gold][:amount] += gold_amount
end

def fight(monsters)
  until monsters.sum { |m| m[:hp] } <= 0 do
    clear_screen
    monsters.each do |monster|
      puts "#{monster[:name]} #{MONSTER_ATTACKS.sample}"
      hit_chance = monster[:attack] - player[:class][:stats][:agi]
      if roll_dice(100) <= hit_chance
        damage = rand(monster[:dmg])
        puts "It hits for #{damage}"
        player[:hp] = player[:hp] - damage
      else
        puts "It misses"
      end
    end
    (awaiting_key_press && player_death) if player[:hp] <= 0
    aviable_commands(%w[hit run status])
    input = player_input
    player_description if input == 'status'
    break if input == 'run' && roll_dice(20) >= (monsters.count + 13)
    if input == 'hit'
      target = nil
      until target != nil do
        puts 'Who?'
        monsters.each do |m|
          puts "#{m[:name].to_s.gsub('_', ' ')}: hp: #{m[:hp]}"
        end
        target = monsters.find { |m| m[:name] == player_input.gsub(' ', '_').to_sym && m[:hp] > 0 }
      end
      hit_chance = player[:attack] - target[:stats][:agi]
      if roll_dice(100) <= hit_chance
        damage = rand(player[:dmg])
        puts "You hit #{target[:name]} for #{damage}"
        target[:hp] = target[:hp] - damage
      else
        puts "You missed"
      end
      awaiting_key_press
    end
  end
end

def player
  @player ||= {}
end

def player_description
  puts "You are #{player[:name]}, a #{player[:class][:name]}. You have #{player[:hp]} health and #{player[:mp]} mana. Your abilities are #{player[:class][:abilities].join(', ')}. You own #{player[:inventory][:gold][:amount]} gold pieces."
  awaiting_key_press
end

def game_loop
  input = ''
  until input == 'quit game' do
    clear_screen
    town_graphic
    town_description
    aviable_commands(%w[tavern dungeon status])
    input = player_input
    visit_tavern if input == 'tavern'
    enter_dungeon if input == 'dungeon'
    player_description if input == 'status'
  end
  clear_screen
  exit
end

def town_graphic
  puts "                          /\\"
  puts "                         /%%\/\\"
  puts "                     ,`./,--.\%\\"
  puts "                    /%%%\|  |--.\\"
  puts "                   /,---.|[]|  |"
  puts "                    |]_'||__| [|"
  puts "                    ||]|[|]|[| |"
  puts "               ._..-':\._ ''/`-'.._."
  puts "        ._._.  |  _.:''|-'`|-..__.:|  ._._."
  puts "        '._,'_.''_    _|  _| .-. ``'._'._.'"
  puts "         | |_  ,'.\  '-| '-| |_|   [] _| |"
  puts "    _____|]|-'|,++:_   ||] |_     _  '-|[|_________"
  puts "    ~  ,-|`|  |+++|-'  |  _|-'   '-'   |.|  ~   "
  puts "      ~) |_|__||  |    ; '-:         __|_|`-.___ ~"
  puts "    _  \-._..''`--:.__/-'   \__..--''    __...-,'__"
  puts "     `-,-'    _.-'-.   `---''   _____..')..-~~'|\\"
  puts "       `-._.-'`-._'`)         ,'`_..-~~' ~_____;'"
  puts "            `. ~~ `.`.________`.( ~~  ___)"
  puts "              )    ~`.\ '  '    ,'  ~\\"
  puts "            ,'|  ~    ')__:__:_( ~   |)"
  puts "             `-...______________....-'"
  puts
end

def city_name
  @city_name ||= CITY_FIRST_NAMES.sample + CITY_LAST_NAMES.sample
end

def town_description
  puts "In #{city_name} its #{WEATHER_DESCRIPTIONS.sample} outside"
end

def start_game
  clear_screen
  puts '              _.--._'
  puts '              \ ** /'
  puts '               (<>)'
  puts '       .       )  (      .'
  puts '        )\ _.._/ /\ \_.._/('
  puts '          (*_<>_  _<>_*)'
  puts '         )/\'\' \ \/ / '' \('
  puts '       \'       )  (      \''
  puts '               (  ) '
  puts '               )  ('
  puts '               (<>)'
  puts '              / ** \\'
  puts '             /.-..-.\\'
  puts ''
  puts ' Welcome to the MINES OF CERTAIN DEATH'
  awaiting_key_press
  clear_screen
  player_classes = CLASSES.keys
  input = ''
  until player_classes.map(&:to_s).include?(input) do
    puts 'Select your class:'
    aviable_commands(player_classes)
    input = player_input
  end
  prepare_player(input)
end

def prepare_player(player_class)
  player_class = player_class.to_sym
  player[:class] = {
    name: player_class,
    stats: CLASSES[player_class],
  }
  class_stats = player[:class][:stats]
  player[:max_hp] = [
    class_stats[:str],
    class_stats[:sta],
  ].sum
  player[:hp] = player[:max_hp]
  player[:max_mp] = class_stats[:int] * 10
  player[:mp] = player[:max_mp]
  player[:attack] = class_stats[:agi] + 40
  player[:dmg] = (class_stats[:str]..class_stats[:str] + 12)
  player[:hunger] = class_stats[:sta] * 10
  player[:class][:abilities] = [CLASSES_BATTLE_ABILITIES[player_class]]
  player[:inventory] = { gold: { amount: rand(0..100) } }
  player[:current_exp] = 0
  player[:lvl] = 1
  puts 'Your name is:'
  player[:name] = player_input
  player_description
  awaiting_key_press
end

def clear_screen
  print "\e[H\e[2J"
end

def awaiting_key_press
  STDIN.getch
end

def player_input
  puts
  print '> '
  gets.chomp
end

def aviable_commands(commands = [])
  commands.each do |c|
    puts "--> #{c}"
  end
  puts
end

def player_death
  clear_screen
  puts "                             ,--."
  puts "                          {    }"
  puts "                          K,   }"
  puts "                         /  ~Y`"
  puts "                    ,   /   /"
  puts "                   {_'-K.__/"
  puts "                     `/-.__L._"
  puts "                     /  ' /`\_}"
  puts "                    /  ' /"
  puts "            ____   /  ' /"
  puts "     ,-'~~~~    ~~/  ' /_"
  puts "   ,'             ``~~~  ',"
  puts "  (                        Y"
  puts " {                         I"
  puts "{      -                    `,"
  puts "|       ',                   )"
  puts "|        |   ,..__      __. Y"
  puts "|    .,_./  Y ' / ^Y   J   )|"
  puts "\           |' /   |   |   ||"
  puts " \          L_/    . _ (_,.'("
  puts "  \,   ,      ^^""' / |      )"
  puts "    \_  \          /,L]     /"
  puts "      '-_~-,       ` `   ./`"
  puts "         `'{_            )"
  puts "             ^^\..___,.--`"
  puts
  puts 'MINES OF CERTAIN DEATH KILLED YOU'
  awaiting_key_press
  save_progress(player)
  exit
end

def save_progress(player_data)
end

def roll_dice(sides)
  rand(1..sides)
end

clear_screen
start_game
game_loop
