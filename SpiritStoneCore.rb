#==============================================================================
# 
# ☆ Glimmer/Fatal Guise 灵石系统·核心系统
# -- Last Updated: 2013.10.09
# -- by ArcDriver
# -- 转载请保留以上信息
#==============================================================================
$imported = {} if $imported.nil?
$imported["GFG-SpiritStone"] = true

#==============================================================================
#module GFG_EqUp
#==============================================================================
module GFG_EqUp
  LV_VARIABLE_0 = 100
  STONE_ID = 14
  STONE_NUM_BASIC = 1
  STONE_NUM_GROWTH = 0
  UPGRADE_RATE = 10
  UPGRADE_LV_NEGATIVE = 2
  
  # Should crafting be available from the menu?
  # If not, set to false.
  MENU_COMMAND = true
  # Label for the menu command
  MENU_COMMAND_TEXT = "灵石"
  # Menu command is always enabled?
  MENU_COMMAND_ENABLE = true
  # Menu command enabled by switch?
  # set to the switch number to use that switch.
  MENU_COMMAND_SWITCH = 0
  # Menu command enabled when specific actor ID in party?
  MENU_COMMAND_ACTOR = 0
  # Menu command enabled when specific class ID in party?
  MENU_COMMAND_CLASS = 0
  
end # of module GFG_EqUp

#==============================================================================
# Window_MenuCommand
# Integrate spirit stone command
#==============================================================================
class Window_MenuCommand < Window_Command
  alias add_original_commands_crafting add_original_commands
  def add_original_commands
    add_original_commands_crafting
    if (GFG_EqUp::MENU_COMMAND)
      enable = GFG_EqUp::MENU_COMMAND_ENABLE
      if (!enable && GFG_EqUp::MENU_COMMAND_SWITCH)
        enable = $game_switches[GFG_EqUp::MENU_COMMAND_SWITCH]
      end
      if (!enable && GFG_EqUp::MENU_COMMAND_ACTOR)
        required = $game_actors[GFG_EqUp::MENU_COMMAND_ACTOR]
        enable = $game_party.members.include?(required)
      end
      if (!enable && GFG_EqUp::MENU_COMMAND_CLASS)
        enable = $game_party.members.map { |a| a.class_id }\
          .include?(GFG_EqUp::MENU_COMMAND_CLASS)
      end
      add_command(GFG_EqUp::MENU_COMMAND_TEXT, :stone, enable)
    end
    
  end
end

class Scene_Menu < Scene_MenuBase
  def command_stone
    SceneManager.call(Scene_SpiritStone)
  end

  alias create_command_window_stone create_command_window
  def create_command_window
    create_command_window_stone
    @command_window.set_handler(:stone, method(:command_stone))
  end
end

#==============================================================================
# ■ Window_UpgradeCommand
#------------------------------------------------------------------------------
# 　List of Commands
#==============================================================================
class Window_UpgradeCommand < Window_Command
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(x, y, width)
    @window_width = width
    super(x, y)
  end
  #--------------------------------------------------------------------------
  # * Get Window Width
  #--------------------------------------------------------------------------
  def window_width
    @window_width
  end
  #--------------------------------------------------------------------------
  # * Create Command List
  #--------------------------------------------------------------------------
  def make_command_list
    add_command("装备强化",   :equip_upgrade)
    add_command("灵石融合", :item_crafting)
    add_command("返回菜单", :command_return)
  end
end # of Window_UpgradeCommand

#==============================================================================
# ■ Scene_SpiritStone
#------------------------------------------------------------------------------
# 　Scene for spirit stone
#==============================================================================
class  Scene_SpiritStone < Scene_MenuBase
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  def start
    super
    create_command_window
    create_equip_window
    create_status_window
    create_stone_window
    create_confirm_window
    create_confirm_help_window
  end
  #--------------------------------------------------------------------------
  # * Create Command Window
  #--------------------------------------------------------------------------
  def create_command_window
    wx = 0
    wy = 0
    ww = 128
    @command_window = Window_UpgradeCommand.new(wx, wy, ww)
    @command_window.y = Graphics.height / 2 - @command_window.height / 2 - 48
    @command_window.viewport = @viewport
    @command_window.help_window = @help_window
    @command_window.set_handler(:equip_upgrade,    method(:command_equip_upgrade))
    @command_window.set_handler(:item_crafting,    method(:command_item_crafting))
    @command_window.set_handler(:command_return, method(:return_scene))
    @command_window.set_handler(:cancel,   method(:return_scene))
  end
  
  #--------------------------------------------------------------------------
  # * Create equip Window
  #--------------------------------------------------------------------------
  def create_equip_window
      wx = @command_window.width
      wy = 0
      ww = 192
      wh = 416
      @equip_window = Window_EquipType.new(wx, wy, ww, wh, 0)
      @equip_window.viewport = @viewport
      @equip_window.help_window = @help_window
      #@equip_window.set_handler(:ok,       method(:on_equip_ok))
      @equip_window.set_handler(:ok,       method(:do_upgrade))
      @equip_window.set_handler(:cancel,   method(:on_equip_cancel))
      @equip_window.visible = false
  end
  
  #--------------------------------------------------------------------------
  # * Create Status Window
  #--------------------------------------------------------------------------
  def create_status_window
    wx = @command_window.width + @equip_window.width
    wy = 0
    ww = Graphics.width - wx
    wh = 416
    @status_window = Window_EqUpStatus.new(wx, wy, ww, wh)
    @status_window.viewport = @viewport
    @status_window.hide
  end
  
  #--------------------------------------------------------------------------
  # * Create confirm Window
  # 调用PS0-截图存档脚本中的Window_Yes_Or_No窗口
  #--------------------------------------------------------------------------
  def create_confirm_window # for equip upgrade
      @window_confirm  = Window_Yes_Or_No.new("确定", "取消")
      @window_confirm.set_handler(:yes,    method(:do_upgrade))
      @window_confirm.set_handler(:cancel, method(:do_cancel))
      @window_confirm.x = 272 - @window_confirm.width/2
      @window_confirm.y = 208 - @window_confirm.height/2
      @window_confirm.z = 9999
      @window_confirm.visible = false
  end
    
  #--------------------------------------------------------------------------
  # * Create Confirm Help Window
  #--------------------------------------------------------------------------
  def create_confirm_help_window
      ww = 216
      wh = 48
      wx = @window_confirm.x + @window_confirm.width / 2 - ww / 2 
      wy = @window_confirm.y - wh
      @confirm_help_window  = Window_ConfirmHelp.new(wx, wy, ww, wh)
      @confirm_help_window.viewport = @viewport
      @confirm_help_window.visible = false
  end  
  
  #--------------------------------------------------------------------------
  # * Create Stone Window
  #--------------------------------------------------------------------------
  def create_stone_window
      wx = 0
      ww = @command_window.width
      wh = 48
      wy = 416 - wh
      @window_stone  = Window_StoneNum.new(wx, wy, ww, wh)
      @window_stone.viewport = @viewport
      @window_stone.visible = false
  end
  
  #--------------------------------------------------------------------------
  # * [equip Upgrade] Command
  #--------------------------------------------------------------------------
  def command_equip_upgrade
      @equip_window.visible = true
      @equip_window.activate
      @equip_window.select(0)
      @equip_window.status_window = @status_window
      @status_window.show
      @window_stone.visible = true
  end
    
  #--------------------------------------------------------------------------
  # * [Item crafting] Command
  #--------------------------------------------------------------------------
  def command_item_crafting
      item_crafting_start
  end  
  
  #--------------------------------------------------------------------------
  # * [on_equip_ok] Command
  #--------------------------------------------------------------------------
  def on_equip_ok
      if upgrade_possible?
        @window_confirm.visible = true
        @confirm_help_window.text = "确定要强化这件装备吗？"
        @confirm_help_window.visible = true
        @window_confirm.select(0)
        @window_confirm.activate
      else
        @equip_window.activate
      end
  end
  #--------------------------------------------------------------------------
  # * [on_equip_cancel] Command
  #--------------------------------------------------------------------------
  def on_equip_cancel
      @equip_window.unselect
      @equip_window.hide
      @window_stone.hide
      @status_window.hide
      @window_confirm.unselect
      @command_window.activate
  end
  #--------------------------------------------------------------------------
  # * judge if it's possible to upgrade
  #--------------------------------------------------------------------------
  def upgrade_possible?
      index = @equip_window.index
      item = @equip_window.item
      eq_id = item[0][index] + GFG_EqUp::LV_VARIABLE_0
      stone_num = $game_party.item_number($data_items[GFG_EqUp::STONE_ID])
      eq_lv = $game_variables[eq_id]
      upgrade_num = GFG_EqUp::STONE_NUM_BASIC + GFG_EqUp::STONE_NUM_GROWTH * eq_lv
      if eq_lv < 10 and stone_num >= upgrade_num
        return true
      end
      return false
  end  
    
  #--------------------------------------------------------------------------
  # * [do_upgrade] Command
  #--------------------------------------------------------------------------
  def do_upgrade
      if upgrade_possible?
        Sound.play_ok
        index = @equip_window.index
        item = @equip_window.item
        eq_id = item[0][index] + GFG_EqUp::LV_VARIABLE_0
        upgrade_num = GFG_EqUp::STONE_NUM_BASIC + GFG_EqUp::STONE_NUM_GROWTH * $game_variables[eq_id]
        $game_variables[eq_id] += 1
        stone = $data_items[GFG_EqUp::STONE_ID]
        $game_party.lose_item(stone, upgrade_num)
        @window_confirm.hide
        @confirm_help_window.hide
        @equip_window.activate
        refresh
      else
        refresh
      end
  end
  #--------------------------------------------------------------------------
  # * [do_cancel] Command
  #--------------------------------------------------------------------------
  def do_cancel
      Sound.play_cancel
      @window_confirm.hide
      @confirm_help_window.hide
      @equip_window.activate
  end
  #--------------------------------------------------------------------------
  # * refresh
  #--------------------------------------------------------------------------  
  def refresh
      @equip_window.refresh
      @window_stone.refresh
      @status_window.refresh
  end
  
  #---------------------------------------------------------------------------
  #* Integrated from item crafting script
  #---------------------------------------------------------------------------
  def item_crafting_start
      create_help_window
      create_recipe_list
      create_ingredient_list
      #@help_window.height = @help_window.height / 2 + 16
      @help_window.y = Graphics.height - @help_window.height
  end
  
  def craft_item
    @recipe_window.item
  end
  
  def on_item_ok
    Sound.play_ok
    craft_item.crafting_items.each \
    { |key,value| ok &= $game_party.gain_item($data_items[key], -value) }
    craft_item.crafting_weapons.each \
    { |key,value| ok &= $game_party.gain_item($data_weapons[key], -value) }
    craft_item.crafting_armors.each \
    { |key,value| ok &= $game_party.gain_item($data_armors[key], -value) }
    $game_party.gain_item(craft_item, 1)
    $game_party.lose_gold(craft_item.crafting_gold)
    @recipe_window.refresh
    @recipe_window.activate
    @window_stone.refresh
  end
  
  def on_item_cancel
    @recipe_window.ingredient_window.hide
    @recipe_window.hide
    @help_window.hide
    @command_window.activate
    @command_window.select(1)
  end

  def create_ingredient_list
    wx = @recipe_window.x + @recipe_window.width
    wh = Graphics.height - @help_window.height
    wy = 0#Graphics.height / 2 - wh / 2
    ww = Graphics.width - @command_window.width - @recipe_window.width
    @ingredient_window = \
      Window_IngredientList.new(wx,wy,ww,wh)
    @recipe_window.ingredient_window = @ingredient_window
    @recipe_window.activate
    @recipe_window.select_last
  end

  def create_recipe_list
    wx = @command_window.width
    wh = Graphics.height - @help_window.height
    wy = 0#Graphics.height / 2 - wh / 2
    ww = 200
    @recipe_window = Window_RecipeList.new(wx ,wy, ww, wh)
    @recipe_window.viewport = @viewport
    @recipe_window.help_window = @help_window
    @recipe_window.set_handler(:cancel, method(:on_item_cancel))
    @recipe_window.set_handler(:ok,     method(:on_item_ok))
  end
  
    
end #of Scene_SpiritStone

#==============================================================================
# ■ Window_ConfirmHelp
#==============================================================================

class Window_ConfirmHelp < Window_Base
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super(x, y, width, height)
    @text = ""
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    self.contents.draw_text(0, 0, 200, 24, @text, 1)
  end
  #--------------------------------------------------------------------------
  # ● 获取帮助文字
  #--------------------------------------------------------------------------
  def text=(text)
      @text = text
      refresh
  end 
  
  #--------------------------------------------------------------------------
  # ● 打开窗口
  #--------------------------------------------------------------------------
  def open
    refresh
    super
  end
end
