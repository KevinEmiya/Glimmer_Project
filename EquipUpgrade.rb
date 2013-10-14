#==============================================================================
# 
# ☆ Glimmer/Fatal Guise 灵石系统·装备强化
# -- Last Updated: 2013.10.09
# -- by ArcDriver
# -- 转载请保留以上信息
# 
#==============================================================================
module GFG_EqUp
  LV_VARIABLE_0 = 100
  STONE_ID = 14
  STONE_NUM_BASIC = 1
  STONE_NUM_GROWTH = 0
  UPGRADE_RATE = 10
  UPGRADE_LV_NEGATIVE = 2
end # of module GFG_EqUp


#==============================================================================
# ■ Window_UpgradeCommand
#------------------------------------------------------------------------------
# 　Scene for equip upgrade
#==============================================================================
class Scene_EquipUpgrade < Scene_MenuBase
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
  end
  #--------------------------------------------------------------------------
  # * Create Command Window
  #--------------------------------------------------------------------------
  def create_command_window
    wx = 0
    wy = 0
    ww = 128
    @command_window = Window_UpgradeCommand.new(wx, wy, ww)
    @command_window.viewport = @viewport
    @command_window.help_window = @help_window
    @command_window.set_handler(:equip_upgrade,    method(:command_equip_upgrade))
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
      @equip_window.set_handler(:ok,       method(:on_equip_ok))
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
  #--------------------------------------------------------------------------
  def create_confirm_window
      @window_confirm  = Window_Yes_Or_No.new("确定", "取消")
      @window_confirm.set_handler(:yes,    method(:do_upgrade))
      @window_confirm.set_handler(:cancel, method(:do_cancel))
      @window_confirm.x = 272 - @window_confirm.width/2
      @window_confirm.y = 208 - @window_confirm.height/2
      @window_confirm.z = 9999
      @window_confirm.visible = false
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
  # * [on_equip_ok] Command
  #--------------------------------------------------------------------------
  def on_equip_ok
      if upgrade_possible?
        @window_confirm.visible = true
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
      @equip_window.visible = false
      @window_stone.visible = false
      @status_window.hide
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
      @window_confirm.visible = false
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
end #of Scene_EquipUpgrade

#==============================================================================
# ■ Game_Actor 
#------------------------------------------------------------------------------
# 　overwrite some methods
#==============================================================================
class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # * Overwrite Get Added Value of Parameter
  #--------------------------------------------------------------------------
  def param_plus(param_id)
    param_plus = equips.compact.inject(super) {|r, item| r += item.params[param_id] }
    for i in 0..equips.size
      if equips[i]
        if equips[i].is_a?(RPG::Weapon)
           eq_id = equips[i].id + GFG_EqUp::LV_VARIABLE_0
         else
           eq_id = equips[i].id + GFG_EqUp::LV_VARIABLE_0 + $data_weapons.size
        end
        if param_plus > 0
           param_plus *= (1 + $game_variables[eq_id] * GFG_EqUp::UPGRADE_RATE / 100.0)
        else 
           param_plus_temp = param_plus + $game_variables[eq_id] / GFG_EqUp::UPGRADE_LV_NEGATIVE
           param_plus = [param_plus_temp, 0].min
        end
      end 
    end
    return param_plus.to_i
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
  end
end # of Window_UpgradeCommand

#==============================================================================
# ■ Window_EquipType
#------------------------------------------------------------------------------
# 　Window of equip list
#==============================================================================
class Window_EquipType < Window_ItemList
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height, type)
    @window_type = type
    super(x, y, width, height)
    refresh
  end
  #--------------------------------------------------------------------------
  # * Get Digit Count
  #--------------------------------------------------------------------------
  def col_max
    return 1
  end
  #--------------------------------------------------------------------------
  # * Def Item
  #--------------------------------------------------------------------------
  def item
    @item = [[],[]]
    $game_party.all_members.each do |actor|
      return unless actor
      for i in 0..actor.equips.length - 1
        if actor.equips[i] != nil and i != actor.equips.length - 1
          if actor.equips[i].is_a?(RPG::Weapon)
             eq_id = actor.equips[i].id
             @item[1].insert(@item[0].size,0)
           else
             eq_id = actor.equips[i].id + $data_weapons.size
             @item[1].insert(@item[0].size,1)
          end
          @item[0].insert(@item[0].size,eq_id)
        end
      end
    end
    return @item
  end
  #--------------------------------------------------------------------------
  # * Get Number of Items
  #--------------------------------------------------------------------------
  def item_max
      item[0].size
  end
  #--------------------------------------------------------------------------
  # * judge if it's possible to upgrade
  #--------------------------------------------------------------------------
  def upgrade_possible?
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
  # * Get Activation State of Selection Item
  #--------------------------------------------------------------------------
  def current_item_enabled?
      return upgrade_possible? 
  end
  #--------------------------------------------------------------------------
  # * Get Rectangle for Drawing Items
  #--------------------------------------------------------------------------
  def item_rect(index)
    rect = Rect.new
    rect.width = item_width
    rect.height = item_height
    rect.x = index % col_max * (item_width + spacing)
    rect.y = index / col_max * item_height * 2
    rect
  end
  #--------------------------------------------------------------------------
  # * Draw Item
  #--------------------------------------------------------------------------
  def draw_item(index)
    all_num = 0
    for i in 0 .. item[0].size - 1
      rect = item_rect_for_text(0)
      eq_id = item[0][i]
      if eq_id <= $data_weapons.size
        draw_item_name($data_weapons[eq_id], rect.x, rect.y + 48 * all_num, true)
      else
        draw_item_name($data_armors[eq_id - $data_weapons.size], rect.x, rect.y + 48 * all_num, true)
      end
      eq_id = item[0][i] + GFG_EqUp::LV_VARIABLE_0
      draw_equip_lv(rect.x, rect.y + 48 * all_num + 24, eq_id)
      all_num += 1
    end
  end
  #--------------------------------------------------------------------------
  # * Set Status Window
  #--------------------------------------------------------------------------
  def status_window=(status_window)
    @status_window = status_window
    call_update_help
  end
  #--------------------------------------------------------------------------
  # * Call update help
  #--------------------------------------------------------------------------
  def call_update_help
      get_currend_item if @status_window
      super
  end
  #--------------------------------------------------------------------------
  # * get current item
  #--------------------------------------------------------------------------
  def get_currend_item
      eq_id = item[0][index]
      if eq_id <= $data_weapons.size
         @status_window.item = $data_weapons[eq_id]
      else
         @status_window.item = $data_armors[eq_id - $data_weapons.size] 
      end
  end
end # of Window_EquipType

#==============================================================================
# ■ Window_EqUpStatus
#==============================================================================

class Window_EqUpStatus < Window_ShopStatus
  
  def line_height
    return 65
  end
  
  #--------------------------------------------------------------------------
  # overwrite method: page_size
  #--------------------------------------------------------------------------
  def page_size
    n = contents.height - line_height
    n /= line_height
    return n
  end
  
  #--------------------------------------------------------------------------
  # overwrite method: update_page
  #--------------------------------------------------------------------------
  def update_page
    return unless visible
    return if @item.nil?
    return if @item.is_a?(RPG::Item)
    return unless Input.trigger?(:A)
    return unless page_max > 1
    Sound.play_cursor
    @page_index = (@page_index + 1) % page_max
    refresh
  end
  
  def draw_possession(x, y)
  end
  
  #--------------------------------------------------------------------------
  # overwrite method: draw_equip_info
  #--------------------------------------------------------------------------
  def draw_equip_info(dx, dy)
    dy -= line_height
    status_members.each_with_index do |actor, i|
      if actor.equippable?(@item)
        draw_actor_equip_info(dx, dy, actor)
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # overwrite method: draw_actor_equip_info
  #--------------------------------------------------------------------------
  def draw_actor_equip_info(dx, dy, actor)
    enabled = actor.equippable?(@item)
    change_color(normal_color, enabled)
    #draw_actor_megaface(actor, dx, dy + 16) #if enabled
    draw_text(dx, dy, contents.width, line_height, actor.name)
    contents.font.size  -= 2 
    item1 = current_equipped_item(actor, @item.etype_id)
    if enabled
      draw_actor_param_change(0, dy + 16, actor, item1)
    end
    contents.font.size  += 2
  end
  
  #--------------------------------------------------------------------------
  # ☆ 绘制角色的能力值变化  #SR
  #--------------------------------------------------------------------------
  def draw_actor_param_change(x, y, actor, item1)
    for param_id in 2..7
      dx = ( param_id -1 ) % 2 * 100
      dy = ( param_id -1 ) % 3 * 16
      rect = Rect.new(x - dx, y + dy, contents.width - 4 - x, line_height)
      change = get_change(param_id)
      change_color(param_change_color(change))
      draw_parameter_name(x - dx, y + dy, param_id)
      draw_text(rect, sprintf("%+d", change), 2)
    end
  end
  
  #--------------------------------------------------------------------------
  # ☆ 绘制参数名  #SR
  #--------------------------------------------------------------------------
  def draw_parameter_name(x, y, param_id)
      param_str = Vocab::param(param_id)
      rect = Rect.new(x + 104, y, contents.width - 4 - x, line_height)
      draw_text(rect, param_str, 0)
  end
  
  #--------------------------------------------------------------------------
  # get param change
  #--------------------------------------------------------------------------
  def get_change(param_id)
      change = 0
      if @item
        if @item.is_a?(RPG::Weapon)
           eq_id = @item.id + GFG_EqUp::LV_VARIABLE_0
         else
           eq_id = @item.id + GFG_EqUp::LV_VARIABLE_0 + $data_weapons.size
        end
        param = @item.params[param_id]
        next_lv = $game_variables[eq_id] + 1
        if next_lv < 11
          if param > 0
             change =  next_lv * GFG_EqUp::UPGRADE_RATE / 100.0 * param
          else 
            param_plus = [param +  next_lv / GFG_EqUp::UPGRADE_LV_NEGATIVE , 0].min
            param_plus_0 = [param +  $game_variables[eq_id] / GFG_EqUp::UPGRADE_LV_NEGATIVE , 0].min
            change = param_plus - param_plus_0
          end
        end
      end
    return change.to_i
  end
  
end # Window_EqUpStatusStatus

#==============================================================================
# ■ Window_Yes_Or_No
#------------------------------------------------------------------------------
# 　Confirm window. From PS0 - Window_SaveFile_Plus by RadioNoise
#   Reference: http://bbs.66rpg.com/thread-217062-1-1.html
#==============================================================================
class Window_Yes_Or_No < Window_HorzCommand
  #--------------------------------------------------------------------------
  # ● オブジェクト初期化
  #--------------------------------------------------------------------------
  def initialize(yes, no)
    @yes = yes
    @no = no
    super(130, 0)
    self.visible = false
    self.active = false
    @index = 0
  end
  #--------------------------------------------------------------------------
  # ● 桁数の取得
  #--------------------------------------------------------------------------
  def col_max
    return 2
  end
  #--------------------------------------------------------------------------
  # ● コマンドリストの作成
  #--------------------------------------------------------------------------
  def make_command_list
    add_command(@yes,   :yes)
    add_command(@no,    :cancel)
  end
  #--------------------------------------------------------------------------
  # ● 決定ボタンが押されたときの処理
  #--------------------------------------------------------------------------
  def process_ok
    Input.update
    call_ok_handler
  end
  #--------------------------------------------------------------------------
  # ● 按下取消键时的处理
  #--------------------------------------------------------------------------
  def process_cancel
    Input.update
    call_cancel_handler
  end
  #--------------------------------------------------------------------------
  # ● 启用窗口
  #--------------------------------------------------------------------------
  def activate
    temp = self.y + self.height - Graphics.height
    if temp > 0
      self.y -= (temp + 12)
    end
    self.active = true
    self
  end
end #of Window_Yes_Or_No

#==============================================================================
# ■ Window_StoneNum
#==============================================================================

class Window_StoneNum < Window_Base
  #--------------------------------------------------------------------------
  # ● 初始化对象
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super(x, y, width, height)
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    draw_icon(359, 0, 0)
    text = value.to_s
    self.contents.draw_text(-24, 0, 128, 24, text, 2)
  end
  #--------------------------------------------------------------------------
  # ● 获取原石数量
  #--------------------------------------------------------------------------
  def value
    return $game_party.item_number($data_items[GFG_EqUp::STONE_ID])
  end
  #--------------------------------------------------------------------------
  # ● 打开窗口
  #--------------------------------------------------------------------------
  def open
    refresh
    super
  end
end