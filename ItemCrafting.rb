#==============================================================================
# Coelocanth's item crafting system
# Version: 0.9.4 (beta)
#==============================================================================
# License Information:
# Free for non commercial use.
# Please give attribution in your credits file.
#
# Commercial use is permitted in exchange for a free copy of the full game,
# and attribution in your credits file and any in game credits.
# 
# from: http://rpgmaker.net/scripts/319/
#==============================================================================
# Crafting system
#
# Concept:
# 
# Crafting assembles a new item by consuming ingredients.
# If you don't have the required ingredients, the item will be
# disabled in the crafting interface
#
# A recipe may be required to know how to craft an item
# One recipe can cover any number of items
# (e.g. a blacksmithing for beginners book could be the recipe for
# tier 1-2 weapons and armors in your game)
# If you don't have the recipe, the item won't even show up in the
# crafting interface.
#
# A tool may be required to craft an item.
# Tools are like ingredients but not consumed.
# (e.g. you need an alchemist's still to craft elixirs)
# If you don't have the tool, the item will be disabled in the
# crafting interface
#
# Ingredients to craft an item are specified by notetags
# on the item that can be crafted.
#
# <craft item:id>            - consume 1 item in crafting
# <craft item:id:quantity>   - consume (quantity) of item in crafting
# <craft weapon:id>          - consume 1 item in crafting
# <craft weapon:id:quantity> - consume (quantity) of item in crafting
# <craft armor:id>           - consume 1 item in crafting
# <craft armor:id:quantity>  - consume (quantity) of item in crafting
# <craft gold:quantity>      - price to craft this recipe
# <craft recipe:id>          - item id required to be able to see this
#                              craftable item in the interface
# <craft switch:id>          - game switch must be ON to see this recipe
# <craft tool:id>            - item id is required to craft this item,
#                              but is not consumed
#
# Additionally, there are tags to allow items to be broken down
# into ingredients.
#
# <craft break item:id>            - give 1 item in breakdown
# <craft break item:id:quantity>   - give (quantity) of item in breakdown
# <craft break weapon:id>          - give 1 item in breakdown
# <craft break weapon:id:quantity> - give (quantity) of item in breakdown
# <craft break armor:id>           - give 1 item in breakdown
# <craft break armor:id:quantity>  - give (quantity) of item in breakdown
# <craft break gold:quantity>      - price to perform this breakdown
# <craft break recipe:id>          - item id required to be able to see this
#                                    breakable item in the interface
# <craft break switch:id>          - game switch must be ON to see this recipe
# <craft break tool:id>            - item id is required to break this item.
#
# example: crafting a partisan requires 3 iron bars and a spear.
# And it can be broken down to give 2 iron bars back.
# <craft item:72:3>
# <craft weapon: 13>
# <craft break item:72:2>
#
# example: crafting spicy soup requires potato, meat and chilli
#          as well as a cauldron tool to cook it in.
# <craft item: 74>
# <craft item: 75>
# <craft item: 76>
# <craft tool: 80>
#
# Integration:
#
# By default, "Crafting" and "Breakdown" commands are added to the menu.
# To change this, or control when the commands are available, set the
# configuration variables in the section below.
#
# To call the crafting system from an event, use a script item:
# SceneManager.call(Scene_Crafting)
# Fiber.yield
#
# To call the breakdown system from an event, use a script item:
# SceneManager.call(Scene_Craft_Breakdown)
# Fiber.yield
#
#==============================================================================
# Version History
# 0.9.4: Crafting shop features:
#        - gold price to craft
#        - switch to allow different shops to enable different recipes
# 0.9.3: Fixed script error on OK key when recipe window is empty
# 0.9.2: Added breakdown system and title texts
# 0.9.1: Fixed capturing of item counts in craft tags
#        Visual improvements to ingredient window
# 0.9.0: Initial release
#==============================================================================
#
# Script configuration
#
module CRAFTING
  # Text for ingredients panel, note \\ is needed in ruby where \ is used in DB
  TEXT_INGREDIENTS_TITLE = "\\c[6]材料:"
  TEXT_INGREDIENTS_TOOLS = "\\c[6]Tools:"
  TEXT_INGREDIENTS_PRICE = "\\c[6]Price:"
end

#==============================================================================
# DataManager
# Hook to read notetags after database load
#==============================================================================

module DataManager
  
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_crafting load_database; end
  def self.load_database
    load_database_crafting
    load_notetags_crafting
  end
  
  #--------------------------------------------------------------------------
  # new method: load_notetags_crafting
  #--------------------------------------------------------------------------
  def self.load_notetags_crafting
    groups = [$data_items, $data_weapons, $data_armors]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_crafting
      end
    end
  end
  
end # DataManager

#==============================================================================
# RPG::BaseItem
# Parse notetags when loading items from the database.
# Adds readable properties for the ingredient lists.
#==============================================================================

class RPG::BaseItem
  
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_reader :crafting_items
  attr_reader :crafting_weapons
  attr_reader :crafting_armors
  attr_reader :crafting_recipes
  attr_reader :crafting_tools
  attr_reader :crafting_gold
  attr_reader :crafting_switches
    
  #--------------------------------------------------------------------------
  # common cache: load_notetags_crafting
  #--------------------------------------------------------------------------
  #<craft item:68>
  #<craft item:68:3>
  def load_notetags_crafting
    @crafting_items = {}
    @crafting_weapons = {}
    @crafting_armors = {}
    @crafting_recipes = {}
    @crafting_tools = {}
    @crafting_switches = []
    @crafting_gold = 0

    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when /<craft item:[[:space:]]*(\d+(?:[[:space:]]*:[[:space:]]*(\d+)){0,1})>/i
        @crafting_items[$1.to_i] = ($2 ? $2.to_i : 1)
      when /<craft weapon:[[:space:]]*(\d+(?:[[:space:]]*:[[:space:]]*(\d+)){0,1})>/i
        @crafting_weapons[$1.to_i] = ($2 ? $2.to_i : 1)
      when /<craft armor:[[:space:]]*(\d+(?:[[:space:]]*:[[:space:]]*(\d+)){0,1})>/i
        @crafting_armors[$1.to_i] = ($2 ? $2.to_i : 1)
      when /<craft recipe:[[:space:]]*(\d+(?:[[:space:]]*:[[:space:]]*(\d+)){0,1})>/i
        @crafting_recipes[$1.to_i] = ($2 ? $2.to_i : 1)
      when /<craft tool:[[:space:]]*(\d+(?:[[:space:]]*:[[:space:]]*(\d+)){0,1})>/i
        @crafting_tools[$1.to_i] = ($2 ? $2.to_i : 1)
      when /<craft switch:[[:space:]]*(\d+)>/i
        @crafting_switches.push($1.to_i)
      when /<craft gold:[[:space:]]*(\d+)>/i
        @crafting_gold = $1.to_i
      end
    } # self.note.split
    #---
  end
  
  def is_craftable?
    !(@crafting_items.empty? && \
       @crafting_weapons.empty? && \
       @crafting_armors.empty? && \
       @crafting_recipes.empty? && \
       @crafting_tools.empty? && \
       @crafting_switches.empty? && \
       @crafting_gold == 0)
  end

end # RPG::BaseItem

#==============================================================================
# Recipe list window, for the crafting scene.
# It's based on the item list, but populated with items the player
# knows the crafting recipe for, rather than current inventory
#==============================================================================
class Window_RecipeList < Window_ItemList
  attr_accessor :ingredient_window
  
  def initialize(x,y,width, height)
    super(x, y, width, height)
    @data = []
    refresh
  end
  
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end
  
  def make_item_list
    tdata = $data_items.compact + $data_weapons.compact + $data_armors.compact
    @data = tdata.select { |item| include?(item) }
  end
  
  def item_max
    @data ? @data.size : 1
  end
  
  def col_max
    1
  end
  
  def include?(item)
    #ok = super && item && item.is_craftable?
    ok = item && item.is_craftable?
    if ok
      item.crafting_recipes.each \
      { |key,value| ok &= $game_party.item_number($data_items[key]) >= value }
      item.crafting_switches.each { |id| ok &= $game_switches[id] }
    end
    ok
  end

  def enable?(item)
    ok = false
    if item
      ok = ($game_party.gold >= item.crafting_gold)
      item.crafting_items.each \
      { |key,value| ok &= $game_party.item_number($data_items[key]) >= value }
      item.crafting_weapons.each \
      { |key,value| ok &= $game_party.item_number($data_weapons[key]) >= value }
      item.crafting_armors.each \
      { |key,value| ok &= $game_party.item_number($data_armors[key]) >= value }
      item.crafting_recipes.each \
      { |key,value| ok &= $game_party.item_number($data_items[key]) >= value }
      item.crafting_tools.each \
      { |key,value| ok &= $game_party.item_number($data_items[key]) >= value }
    end
    ok
  end
  
  def update_help
    @help_window.set_item(item)
    @ingredient_window.set_item(item)
  end
end

#==============================================================================
# Base ingredient list window
# common to crafting ingredients and breakdown results.
#==============================================================================
class Window_IngredientListBase < Window_Base
  def initialize(x,y,width, height)
    super(x, y, width, height)
    @ingredients_title = "Ingredients:"
    @ingredients = []
    @tools_title = "Tools:"
    @tools = []
    @price_title = "Price:"
    @gold = 0
    @recipe_item = nil
    refresh
  end
  
  def set_item(item)
    @recipe_item = item
    refresh
  end
  
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end
  
  def make_metadata(item, need)
    metadata = {item: item}
    metadata[:got] = $game_party.item_number(item)
    metadata[:need] = need
    metadata
  end
  
  def make_item_list
    @ingredients = []
    @tools = []
    @gold = 0
  end
  
  def draw_all_items
    # title text
    ypos = calc_line_height(@ingredients_title)
    draw_text_ex(0,0, @ingredients_title)
    reset_font_settings
    # ingredient list
    @ingredients.each {|item| draw_item(item, ypos); ypos += line_height }
    # tools separator text
    if (@tools.size > 0)
      draw_text_ex(0,ypos, @tools_title)
      ypos += calc_line_height(@tools_title)
      reset_font_settings
      # tools list
      @tools.each {|item| draw_item(item, ypos); ypos += line_height }
    end
    # gold?
    if @gold != 0
      ypos = draw_gold(ypos)
    end
  end

  def item_max
    @data ? @data.size : 1
  end
  
  def col_max
    1
  end

  # override - adding enable flag
  def draw_currency_value(value, unit, x, y, width, enable = true)
    cx = text_size(unit).width
    change_color(normal_color, enable)
    draw_text(x, y, width - cx - 2, line_height, value, 2)
    change_color(system_color)
    draw_text(x, y, width, line_height, unit, 2)
  end

  def draw_gold(ypos)
    got = $game_party.gold

    have_enough = got >= @gold
    draw_text_ex(0, ypos, @price_title)
    ypos += calc_line_height(@price_title)
    draw_currency_value(@gold, Vocab::currency_unit, 0, ypos, contents_width, have_enough)
    ypos += line_height
    return ypos
  end

  def draw_item(item, ypos)
    if item
      have_enough = item[:got] >= item[:need]
      color = have_enough ? normal_color : power_down_color
      draw_item_name(item[:item], 0, ypos, have_enough)
      draw_current_and_max_values(contents_width - 96, ypos, \
                                  96, item[:got], item[:need], \
                                  color, normal_color)
    end
  end

  def update_help
    @help_window.set_item(item)
  end
end

#==============================================================================
# ingredient list window
# shows what the player needs to craft an item
#==============================================================================
class Window_IngredientList < Window_IngredientListBase
  def initialize(x,y,width, height)
    super(x, y, width, height)
    @ingredients_title = CRAFTING::TEXT_INGREDIENTS_TITLE
    @tools_title = CRAFTING::TEXT_INGREDIENTS_TOOLS
    @price_title = CRAFTING::TEXT_INGREDIENTS_PRICE
    refresh
  end

  def make_item_list
    super
    if @recipe_item
      @recipe_item.crafting_items.each \
      { |key,value| @ingredients.push(make_metadata($data_items[key], value)) }
      @recipe_item.crafting_weapons.each \
      { |key,value| @ingredients.push(make_metadata($data_weapons[key], value)) }
      @recipe_item.crafting_armors.each \
      { |key,value| @ingredients.push(make_metadata($data_armors[key], value)) }

      @gold = @recipe_item.crafting_gold

      @recipe_item.crafting_recipes.each \
      { |key,value| @tools.push(make_metadata($data_items[key], value)) }
      @recipe_item.crafting_tools.each \
      { |key,value| @tools.push(make_metadata($data_items[key], value)) }
    end
  end

end

#==============================================================================
# Common code for crafting and breakdown scenes.
#==============================================================================
class Scene_CraftBase < Scene_MenuBase
  def start
    super
    create_help_window
    create_recipe_list
    create_ingredient_list
  end
  
  #--------------------------------------------------------------------------
  # * Get Currently Selected Item
  #--------------------------------------------------------------------------
  def item
    @recipe_window.item
  end
end

#==============================================================================
# Crafting scene
#==============================================================================
class Scene_Crafting < Scene_CraftBase
  #--------------------------------------------------------------------------
  # * Item [OK]
  # remove ingredients, add new item to inventory
  #--------------------------------------------------------------------------
  def on_item_ok
    Sound.play_ok
    item.crafting_items.each \
    { |key,value| ok &= $game_party.gain_item($data_items[key], -value) }
    item.crafting_weapons.each \
    { |key,value| ok &= $game_party.gain_item($data_weapons[key], -value) }
    item.crafting_armors.each \
    { |key,value| ok &= $game_party.gain_item($data_armors[key], -value) }
    $game_party.gain_item(item, 1)
    $game_party.lose_gold(item.crafting_gold)
    @recipe_window.refresh
    @recipe_window.activate
  end

  def create_ingredient_list
    wx = @recipe_window.x + @recipe_window.width
    wy = @help_window.y + @help_window.height
    wh = Graphics.height - wy
    @ingredient_window = \
      Window_IngredientList.new(wx,wy,Graphics.width / 2, wh)
    @recipe_window.ingredient_window = @ingredient_window
    @recipe_window.activate
    @recipe_window.select_last
  end

  def create_recipe_list
    wy = @help_window.y + @help_window.height + 40
    wh = Graphics.height - wy
    @recipe_window = Window_RecipeList.new(40 ,wy,Graphics.width / 2 - 40, wh)
    @recipe_window.viewport = @viewport
    @recipe_window.help_window = @help_window
    @recipe_window.set_handler(:cancel, method(:return_scene))
    @recipe_window.set_handler(:ok,     method(:on_item_ok))
  end
end

