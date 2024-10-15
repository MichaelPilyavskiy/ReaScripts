-- @description Keyboard Shortcuts Visualizer
-- @version 1.07
-- @author MPL
-- @about Script for showing keyboard shortcuts
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # test patch for Mac users




    
local vrs = 1.07

--------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end
  app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
  if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end
  local ImGui
  
  if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
  package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  ImGui = require 'imgui' '0.9.3'
  
  ismac = reaper.GetOS():match('Win')==nil
  
-------------------------------------------------------------------------------- init external defaults 
EXT = {
        viewport_posX = 10,
        viewport_posY = 10,
        viewport_posW = 1024,
        viewport_posH = 300, 
        categoriescnt = 16,
        search = '',
        section_ID = 0,
        layout = 0,
        extlayoutname = 'QWERTY',
        dev_char = 0,
        
      }
for i =1, EXT.categoriescnt do EXT['category'..i..'_color'] = '' end
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'kb_shortcuts',
        UI_name = 'Keyboard Shortcuts Visualizer', 
        upd = true, 
        kb={},
        actions= {},
        section_ID = 0,
        selectedkey = '',
        
        
        reapervisiblemodifiers_mapping = {
            ['Ctrl'] = ImGui.Mod_Ctrl,
            ['Alt'] = ImGui.Mod_Alt,
            ['Shift'] = ImGui.Mod_Shift,
            ['Win'] = 1<<15, -- reversed, didn`t found this one from ReaImGui API
          },
          
        category={
          {name = 'All', color = 0x0F9F0F}, 
          
          {name = 'Item / Take',      color = 0xa4c5ea, str = 'item,take,comp'},
          {name = 'Track',            color = 0xF8FF02, str='track'},
          {name = 'FX',               color = 0xFFe0a3, str = 'fx,mixer'},
          {name = 'View / Navigation',color = 0x9de19a, str='view,grid,layout,marker,region,edit_cursor,play cursor,ruler,screenset,time_selection,toolbar'}, 
          {name = 'Automation',       color = 0xbca9e1, str = 'Automation,Envelope'}, 
          {name = 'Edit',             color = 0xedff71, str='edit'},   
          
          {name = 'Transport',        color = 0xf06543, str = 'transport'},  
          {name = 'Custom',           color = 0x4F3bFd, str='custom'},
          {name = 'Controller/Wheel', color = 0x08605f, str = 'OSC_only,MIDI_CC_relative,mousewheel'},
          {name = '3rd party',        color = 0xF03353, str='Script:,SWS,reapack'},
        },
        
        sections ={
          [0]='Main',
          [100]='Main (alt recording)',
          [32060]='MIDI Editor',
          [32061]='MIDI Event List Editor',
          [32062]='MIDI Inline Editor',
          [32063]='Media Explorer',
          [1]='Main Alt 1',
          [2]='Main Alt 2',
          [3]='Main Alt 3',
          [4]='Main Alt 4',
          [5]='Main Alt 5',
          [6]='Main Alt 6',
          [7]='Main Alt 7',
          [8]='Main Alt 8',
          [9]='Main Alt 9',
          [10]='Main Alt 10',
          [11]='Main Alt 11',
          [12]='Main Alt 12',
          [13]='Main Alt 13',
          [14]='Main Alt 14',
          [15]='Main Alt 15',
          [16]='Main Alt 16',
          
        },
        
        layouts = {
          [0] = 'QWERTY',
          [1] = 'AZERTY (experimental)',
          --[2] = 'MIDI',
        }
        }
if ismac ==true then   
  DATA.reapervisiblemodifiers_mapping = {
      ['Ctrl'] = ImGui.Mod_Super,
      ['Command'] = ImGui.Mod_Ctrl,
      ['Option'] = ImGui.Mod_Alt,
    }
end
-------------------------------------------------------------------------------- INIT UI locals
for key in pairs(reaper) do _G[key]=reaper[key] end 
--local ctx
-------------------------------------------------------------------------------- UI init variables
  UI = {  tempcoloring = {},
          popups = {},}
-- font  
  UI.font='Arial'
  UI.font1sz=15
  UI.font2sz=14
  UI.font3sz=12
-- style
  UI.pushcnt = 0
  UI.pushcnt2 = 0
-- size / offset
  UI.spacingX = 2
  UI.spacingY = 3
-- mouse
  UI.hoverdelay = 0.3
  UI.hoverdelayshort = 0.1
-- colors 
  UI.main_col = 0x7F7F7F -- grey
  UI.textcol = 0xFFFFFF
  UI.but_hovered = 0x878787
  UI.windowBg = 0x303030
-- alpha
  UI.textcol_a_enabled = 1
  UI.textcol_a_disabled = 0.5
-- special 
  UI.butBg_green = 0x00B300
  UI.butBg_red = 0xB31F0F

-- size
  UI.main_W = 800
  UI.main_H = 600
  
--keyb vis
  UI.release_time = 0.5
  UI.main_butcol = 0x7F7F7F 
  UI.main_butcol_other = 0x0F9F0F
  UI.main_butcol_script = 0xFF0F0F
  UI.main_butcol_sws = 0x0F0FFF
  







function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  ------------------------------------------------------------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end              
-------------------------------------------------------------------------------- 
function DATA:Init_GetColorByActionName(action_name) 
  if not action_name then return end
  
  action_name = action_name:lower()
  for catID =1 , #DATA.category do
    local str = DATA.category[catID].str
    if str then
    
      if action_name:match(str:gsub('_', ' ')) then 
        return DATA.category[catID].color
      end
      
      str = str:lower()
      if str:match(',') then 
        for matchstr in str:gmatch('[^%,]+') do
          if action_name:match(matchstr:gsub('_', ' ')) then 
            return DATA.category[catID].color
          end
        end 
      end
    end
  end
  
  return DATA.category[1].color
end
-------------------------------------------------------------------------------- 
function DATA:Init_kbDefinition_ActionList() 
  local section_ID = EXT.section_ID
  
  local maxactionscnt = 100000
  local retval, name
  for cmdID = 0, maxactionscnt do
    local action_ID, action_name = kbd_enumerateActions( section_ID, cmdID )
    if action_ID then
      local action_bindings = {}
      local shortcutscnt = CountActionShortcuts( section_ID, action_ID )
      for shortcutidx = 1, shortcutscnt do
        local retval, shortcut_str = GetActionShortcutDesc( section_ID, action_ID, shortcutidx-1 )
        
        local used_shortcuts_t = {}
        used_shortcuts_t.section_ID=section_ID
        used_shortcuts_t.action_ID=action_ID
        used_shortcuts_t.action_name=action_name
        used_shortcuts_t.shortcut_str=shortcut_str
        
        -- patch for parsing [Something] + [Num +]
          shortcut_str = shortcut_str:gsub('Num %+', 'Num plus')
        
        local modifierflags = 0
        if shortcut_str:match('+') then 
          for key in shortcut_str:gmatch('[^%+]+') do  
            local modkey_match
            for mod in pairs(DATA.reapervisiblemodifiers_mapping) do if key:match(mod) then modifierflags = modifierflags|DATA.reapervisiblemodifiers_mapping[mod] modkey_match = true end end --any of mod keys
            if not modkey_match then used_shortcuts_t.mainkey = key:gsub('Num plus','Num +') end
          end 
         else
          used_shortcuts_t.mainkey = shortcut_str:gsub('Num plus','Num +')
        end 
        
        used_shortcuts_t.modifierflags=modifierflags
        used_shortcuts_t.shortcutidx= shortcutidx-1
        used_shortcuts_t.color = DATA:Init_GetColorByActionName(used_shortcuts_t.action_name)  
        DATA:Init_kbDefinition_fitUItoActionList(used_shortcuts_t)  
        action_bindings[#action_bindings+1] = used_shortcuts_t
      end
      
      --local action_color = DATA:Init_GetColorByActionName(action_name) 
      DATA.actions[action_ID] = {action_name = action_name,action_bindings=action_bindings,action_color=action_color}
    end
  end
end
-------------------------------------------------------------------------------- 
function  DATA:Init_kbDefinition_fitUItoActionList(used_shortcuts_t)
  if not (used_shortcuts_t and used_shortcuts_t.mainkey) then return end
  local mainkey = used_shortcuts_t.mainkey
  for key in pairs(DATA.kb) do
    if DATA.kb[key].mainkey and DATA.kb[key].mainkey:lower() == mainkey:lower() then
      if not DATA.kb[key].bindings then DATA.kb[key].bindings = {} end
      local bindingID = used_shortcuts_t.modifierflags 
      
      for key_shortcut in pairs(used_shortcuts_t) do
        if not DATA.kb[key].bindings[bindingID] then DATA.kb[key].bindings[bindingID] = {} end
        DATA.kb[key].bindings[bindingID][key_shortcut]=used_shortcuts_t[key_shortcut]
      end
      
      return
    end
  end 
end
-------------------------------------------------------------------------------- 
function DATA:Init_kbDefinition_UI_MIDIOSC()
    DATA.kb['CC'] = { block = 1, level = 1, pos = 1}
end
-------------------------------------------------------------------------------- 
function  DATA:Init_kbDefinition_UI()
  local extlayoutname = EXT.extlayoutname
  if not (DATA.extlayouts and extlayoutname and DATA.extlayouts[extlayoutname] and DATA.extlayouts[extlayoutname].BLOCKS) then return end
  for block in pairs(DATA.extlayouts[extlayoutname].BLOCKS) do
    if not DATA.extlayouts[extlayoutname].BLOCKS[block].LEVELS then goto nextlevel end
    
    for level in pairs(DATA.extlayouts[extlayoutname].BLOCKS[block].LEVELS) do 
      local pos = 1
      for keyID = 1, #DATA.extlayouts[extlayoutname].BLOCKS[block].LEVELS[level] do
        local keyt = DATA.extlayouts[extlayoutname].BLOCKS[block].LEVELS[level][keyID]
        local KBNAME = keyt.KBNAME
        local EXTW = keyt.EXTW or 1
        local EXTH = keyt.EXTH or 1
        local BINDINGNAME = keyt.BINDINGNAME
        
        if BINDINGNAME:match('C%d+') then
          local char = BINDINGNAME:match('C(%d+)')
          if tonumber(char) and string.char(tonumber(char)) then BINDINGNAME = string.char(tonumber(char)) end
        end
        
        local IMGUI = keyt.IMGUI
        DATA.kb[KBNAME] = { 
          block = block, 
          level = level, 
          pos = pos, 
          extw = EXTW or 1,
          exth = EXTH or 1,
          mainkey = BINDINGNAME} 
          
        if IMGUI ~= 'dummy' and DATA.kb[KBNAME] then
          if tonumber(IMGUI) then 
            DATA.kb[KBNAME].reaimguikeyID = IMGUI 
           else 
            if ImGui[IMGUI] then DATA.kb[KBNAME].reaimguikey = ImGui[IMGUI] end
          end  
        end
        
        pos = pos + EXTW
      end
    end
    ::nextlevel::
  end
  
end
--------------------------------------------------------------------------------  
function UI.MAIN_calc_layout() 
  if not (UI.calc_butW and UI.calc_butW[1]) then return end
  UI.calc_butW[2] = UI.calc_butW[1]
  UI.calc_butW[3] = UI.calc_butW[1]
  UI.calc_butW[4] = UI.calc_butW[1]
  UI.calc_butW[5] = UI.calc_butW[1]
  UI.calc_butW[6] = UI.calc_butW[1] 
  
  local extlayoutname = EXT.extlayoutname
  if not (DATA.extlayouts and extlayoutname and DATA.extlayouts[extlayoutname] and DATA.extlayouts[extlayoutname].BLOCKS and DATA.extlayouts[extlayoutname].BLOCKS[1] and DATA.extlayouts[extlayoutname].BLOCKS[1].LEVELS) then return end
  
  -- 2nd level
  for level = 2, 6 do
    if DATA.extlayouts[extlayoutname].BLOCKS[1].LEVELS[level] then
      local but_cnt = #DATA.extlayouts[extlayoutname].BLOCKS[1].LEVELS[level]
      local but_cnt_ext = 0
      for keyID = 1, but_cnt do
        local EXTW = 1
        if DATA.extlayouts[extlayoutname].BLOCKS[1].LEVELS[level][keyID].EXTW then EXTW = DATA.extlayouts[extlayoutname].BLOCKS[1].LEVELS[level][keyID].EXTW end
        but_cnt_ext = but_cnt_ext + 1*EXTW 
      end
      local xspacing = UI.spacingX*(but_cnt-1)
      UI.calc_butW[level] = ((UI.calc_mainblockw - xspacing) / but_cnt_ext )
    end
  end
  UI.cachedlayoutsize = true
end
--------------------------------------------------------------------------------  
function UI.MAIN_calc() 
  -- define x/w
  UI.calc_butHref= 35
  UI.calc_spacingX_wide = UI.spacingX * 4
  UI.calc_spacingY_wide = UI.spacingY * 4
  
  if not UI.calc_butW then UI.calc_butW = {} end
  UI.calc_blockoffs_X= {}
   
  UI.calc_butW[1] = math.floor((DATA.display_w - UI.calc_spacingX_wide*4 - UI.spacingX*17)/20) 
  UI.calc_blockoffs_X[1] = UI.calc_spacingX_wide
  UI.calc_blockoffs_X[2] = UI.calc_spacingX_wide*2 + UI.calc_butW[1]*13 + UI.spacingX*12
  UI.calc_blockoffs_X[3] = UI.calc_spacingX_wide*3 + UI.calc_butW[1]*16 + UI.spacingX*15 
  UI.calc_mainblockw = UI.calc_blockoffs_X[2] - UI.calc_blockoffs_X[1] - UI.calc_spacingX_wide 
  
  if not UI.cachedlayoutsize then UI.MAIN_calc_layout()  end
  -- define y/h
  
  UI.calc_butH = {
    math.floor(UI.calc_butHref*0.8),
    math.floor(UI.calc_butHref*1.2),
    UI.calc_butHref,
    UI.calc_butHref,
    UI.calc_butHref,
    UI.calc_butHref,
    }
    
  UI.calc_blockoffs_Y= {
    UI.calc_itemH+UI.spacingY,
    UI.calc_itemH+UI.spacingY*2+ UI.calc_butH[1] + UI.calc_spacingY_wide,
    UI.calc_itemH+UI.spacingY*2+ UI.calc_butH[1] + UI.calc_spacingY_wide +  UI.calc_butH[2] + UI.spacingY,
    UI.calc_itemH+UI.spacingY*2+ UI.calc_butH[1] + UI.calc_spacingY_wide +  UI.calc_butH[2] + UI.spacingY + UI.calc_butH[3] + UI.spacingY,
    UI.calc_itemH+UI.spacingY*2+ UI.calc_butH[1] + UI.calc_spacingY_wide +  UI.calc_butH[2] + UI.spacingY + UI.calc_butH[3] + UI.spacingY + UI.calc_butH[3] + UI.spacingY,
    UI.calc_itemH+UI.spacingY*2+ UI.calc_butH[1] + UI.calc_spacingY_wide +  UI.calc_butH[2] + UI.spacingY + UI.calc_butH[3] + UI.spacingY + UI.calc_butH[3] + UI.spacingY + UI.calc_butH[3] + UI.spacingY,
    UI.calc_itemH+UI.spacingY*2+ UI.calc_butH[1] + UI.calc_spacingY_wide +  UI.calc_butH[2] + UI.spacingY + UI.calc_butH[3] + UI.spacingY + UI.calc_butH[3] + UI.spacingY + UI.calc_butH[3] + UI.spacingY + UI.calc_butH[3] + UI.calc_spacingY_wide,
    }
    
  -- define current action
    local subblockW = UI.calc_butW[1] * 7 + UI.calc_spacingX_wide + UI.spacingX * 5
    UI.calc_KeyDetails_x = UI.calc_spacingX_wide + UI.calc_butW[1]*4 + UI.spacingX * 3
    UI.calc_KeyDetails_y = UI.calc_blockoffs_Y[7]
    UI.calc_KeyDetails_w = subblockW
    
    UI.calc_KeyCategories_x = UI.calc_spacingX_wide
    UI.calc_KeyCategories_y = UI.calc_KeyDetails_y
    UI.calc_KeyCategories_w = UI.calc_butW[1]*4 + UI.spacingX * 2
    
    UI.calc_ActList_x = UI.calc_spacingX_wide + UI.calc_butW[1]*4 + UI.spacingX * 3
    UI.calc_ActList_y = UI.calc_KeyDetails_y
    UI.calc_ActList_w = UI.calc_KeyDetails_x - (UI.calc_KeyCategories_x + UI.calc_KeyCategories_w) - UI.calc_spacingX_wide
  
  -- combos
    UI.calc_combo1_x =  UI.calc_blockoffs_X[3]
    UI.calc_combo1_y =  UI.calc_blockoffs_Y[1]
    UI.calc_combo1_w =  UI.calc_butW[1] * 4+ UI.spacingX*3
    UI.calc_combo1_h =  UI.calc_butH[1]
    
    UI.calc_combo2_x =  UI.calc_blockoffs_X[2]
    UI.calc_combo2_y =  UI.calc_blockoffs_Y[1]
    UI.calc_combo2_w =  UI.calc_butW[1] * 3+ UI.spacingX*2
    UI.calc_combo2_h =  UI.calc_butH[1]
    
end
-------------------------------------------------------------------------------- 
function DATA:SetSelectionFromReimGuiKey(reaimguikey)
  for key in pairs(DATA.kb) do
    if DATA.kb[key].disabled ~= true and 
      (
        (DATA.kb[key].reaimguikey and DATA.kb[key].reaimguikey  == reaimguikey )
        or
        (DATA.kb[key].reaimguikeyID and DATA.kb[key].reaimguikeyID  == DATA.input_char ) 
      )
      
      then
      DATA.selectedkey = key
      return
    end
  end
end
-------------------------------------------------------------------------------- 
function UI.HelpMarker(desc)
  if ImGui.BeginItemTooltip(ctx) then
    ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
    ImGui.Text(ctx, desc)
    ImGui.PopTextWrapPos(ctx)
    ImGui.EndTooltip(ctx)
  end
end
-------------------------------------------------------------------------------- 
function UI.draw_KeyDetails_tooltip(key_src)
  if key_src == DATA.selectedkey then return end
  if ImGui.BeginItemTooltip(ctx) then
    
    
    local Shift_flag = DATA.reapervisiblemodifiers_mapping.Shift
    local Ctrl_flag = DATA.reapervisiblemodifiers_mapping.Ctrl
    local Alt_flag = DATA.reapervisiblemodifiers_mapping.Alt
    local Win_flag = DATA.reapervisiblemodifiers_mapping.Win
    
    local modifiers = {
      {str = '-', flags = 0},
      {str = 'Shift', flags = Shift_flag},
      {str = 'Ctrl', flags = Ctrl_flag},
      {str = 'Shift+Ctrl', flags = Shift_flag|Ctrl_flag},
      {str = 'Alt', flags = Alt_flag},
      {str = 'Shift+Alt', flags = Shift_flag|Alt_flag},
      {str = 'Ctrl+Alt', flags = Ctrl_flag|Alt_flag},
      {str = 'Shift+Ctrl+Alt', flags = Shift_flag|Ctrl_flag|Alt_flag},
      
      {str = 'Win', flags = Win_flag}, 
      {str = 'Shift+Win', flags = Shift_flag|Win_flag},
      {str = 'Ctrl+Win', flags = Ctrl_flag|Win_flag},
      {str = 'Shift+Ctrl+Win', flags = Shift_flag|Ctrl_flag|Win_flag},
      {str = 'Alt+Win', flags = Alt_flag|Win_flag},
      {str = 'Shift+Alt+Win', flags = Shift_flag|Alt_flag|Win_flag},
      {str = 'Ctrl+Alt+Win', flags = Ctrl_flag|Alt_flag|Win_flag},
      {str = 'Shift+Ctrl+Alt+Win', flags = Shift_flag|Ctrl_flag|Alt_flag|Win_flag},
      }
    
    if ismac == true then
      Command_flag = DATA.reapervisiblemodifiers_mapping.Command
      Ctrl_flag = DATA.reapervisiblemodifiers_mapping.Ctrl
      Option_flag = DATA.reapervisiblemodifiers_mapping.Option
      
      
      modifiers = {
        {str = '-', flags = 0},
        {str = 'Command', flags = Command_flag},
        {str = 'Ctrl', flags = Ctrl_flag},
        {str = 'Command+Ctrl', flags = Command_flag|Ctrl_flag},
        {str = 'Option', flags = Option_flag},
        {str = 'Command+Option', flags = Command_flag|Option_flag},
        {str = 'Ctrl+Option', flags = Ctrl_flag|Option_flag},
        {str = 'Command+Ctrl+Option', flags = Command_flag|Ctrl_flag|Option_flag},
        }
    end
    
    for i = 1 , #modifiers do
      if DATA.kb[key_src].bindings and DATA.kb[key_src].bindings[modifiers[i].flags] then
        local strmod = modifiers[i].str
        if modifiers[i].str == '-' then strmod = 'No modifier' end
        ImGui.Selectable(ctx,strmod..':')ImGui.SameLine(ctx)
        ImGui.SetCursorPosX( ctx, 100 )
        ImGui.Selectable(ctx,DATA.kb[key_src].bindings[modifiers[i].flags].action_name)
      end
    end
    
    ImGui.EndTooltip(ctx)
  end
end
-------------------------------------------------------------------------------- 
function UI.draw_ActionList() 
  ImGui.SetCursorPos( ctx, UI.calc_ActList_x, UI.calc_ActList_y ) 
    
  if ImGui.BeginChild( ctx, 'actlist', UI.calc_ActList_w, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None|ImGui.WindowFlags_MenuBar ) then
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,5,2)
    if ImGui.BeginMenuBar( ctx ) then
      if ImGui.BeginMenu(ctx, 'Search action list:') then 
        ImGui.EndMenu(ctx)
      end
      local retval, buf = ImGui.InputText( ctx, '##Search', EXT.search,ImGui.InputTextFlags_AutoSelectAll )--|ImGui.InputTextFlags_EnterReturnsTrue
      if retval == true then 
        EXT.search = buf
        DATA:Init_Search_ActionList() 
        EXT:save()
      end
      ImGui.EndMenuBar( ctx ) 
    end
    
    for actionID in pairs(DATA.actions) do
      if DATA.actions[actionID].fitsearch == true then
        ImGui.Selectable(ctx,DATA.actions[actionID].action_name ) 
        if ImGui.BeginDragDropSource( ctx, ImGui.DragDropFlags_None ) then
          ImGui.SetDragDropPayload(ctx, 'actiondrop', actionID, ImGui.Cond_Always) 
          ImGui.EndDragDropSource(ctx)
        end
        
      end
    end
    
    ImGui.PopStyleVar(ctx,1)
    ImGui.EndChild( ctx)
  end 
end
-------------------------------------------------------------------------------- 
function UI.draw_KeyCategories()
  local indent = 7
  ImGui.SetCursorPos( ctx, UI.calc_KeyCategories_x, UI.calc_KeyCategories_y ) 
    
  if ImGui.BeginChild( ctx, 'categories', UI.calc_KeyCategories_w, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None|ImGui.WindowFlags_MenuBar ) then
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,5,2)
    if ImGui.BeginMenuBar( ctx ) then
      if ImGui.BeginMenu(ctx, 'Categories') then 
        ImGui.EndMenu(ctx)
      end
      ImGui.EndMenuBar( ctx ) 
    end
    
    --ImGui.PushFont(ctx, DATA.font3) 
    ImGui.Indent(ctx,indent)
    for catID = 1, #DATA.category do  
      local retval, col_rgb = ImGui.ColorEdit3(ctx, '##cat'..catID, DATA.category[catID].color, ImGui.ColorEditFlags_None|ImGui.ColorEditFlags_NoInputs)
      if retval then
        DATA.category[catID].color = col_rgb
        EXT['category'..catID..'_color'] = col_rgb
        EXT:save()
        DATA:Init_LoadExtColors() 
      end
      if ImGui.IsItemDeactivatedAfterEdit( ctx ) then
        DATA:CollectData()
      end
      ImGui.SameLine(ctx) ImGui.Selectable( ctx, DATA.category[catID].name ) 
    end
    
    
    
    ImGui.Unindent(ctx,indent)
    --ImGui.PopFont(ctx)
    
    ImGui.PopStyleVar(ctx,1)
    ImGui.EndChild( ctx)
  end 
end
-------------------------------------------------------------------------------- 
function UI.draw_KeyDetails(key_src0) 
  local key_src = key_src0
  if not key_src0 then key_src = DATA.selectedkey end
  if not (key_src ~= '' and DATA.kb[key_src]) then return end
  
  if key_src0 == nil then 
    ImGui.SetCursorPos( ctx, UI.calc_KeyDetails_x, UI.calc_KeyDetails_y ) 
  end
    
  if ImGui.BeginChild( ctx, 'currentkey'..key_src, 0, 0, ImGui.ChildFlags_None|ImGui.ChildFlags_Border, ImGui.WindowFlags_None|ImGui.WindowFlags_MenuBar ) then--UI.calc_KeyDetails_w
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,5,2)
    if ImGui.BeginMenuBar( ctx ) then
      ImGui.Text(ctx,'Key details ['..(DATA.selectedkey:match('(.-)##') or DATA.selectedkey )..']:')
      --[[if ImGui.BeginMenu(ctx, 'Key details ['..DATA.selectedkey..']:') then
        --ImGui_MenuItem( ctx, 'Key details ['..DATA.selectedkey..']:')
        --ImGui.SeparatorText(ctx, 'Actions')
        
        ImGui.EndMenu(ctx)
      end]]
      ImGui.EndMenuBar( ctx ) 
    end
    
    ImGui.PushFont(ctx, DATA.font3) 
    local Shift_flag = DATA.reapervisiblemodifiers_mapping.Shift
    local Ctrl_flag = DATA.reapervisiblemodifiers_mapping.Ctrl
    local Alt_flag = DATA.reapervisiblemodifiers_mapping.Alt
    local Win_flag = DATA.reapervisiblemodifiers_mapping.Win
    
    local modifiers = {
      {str = '-', flags = 0},
      {str = 'Shift', flags = Shift_flag},
      {str = 'Ctrl', flags = Ctrl_flag},
      {str = 'Shift+Ctrl', flags = Shift_flag|Ctrl_flag},
      {str = 'Alt', flags = Alt_flag},
      {str = 'Shift+Alt', flags = Shift_flag|Alt_flag},
      {str = 'Ctrl+Alt', flags = Ctrl_flag|Alt_flag},
      {str = 'Shift+Ctrl+Alt', flags = Shift_flag|Ctrl_flag|Alt_flag},
      
      {str = 'Win', flags = Win_flag}, 
      {str = 'Shift+Win', flags = Shift_flag|Win_flag},
      {str = 'Ctrl+Win', flags = Ctrl_flag|Win_flag},
      {str = 'Shift+Ctrl+Win', flags = Shift_flag|Ctrl_flag|Win_flag},
      {str = 'Alt+Win', flags = Alt_flag|Win_flag},
      {str = 'Shift+Alt+Win', flags = Shift_flag|Alt_flag|Win_flag},
      {str = 'Ctrl+Alt+Win', flags = Ctrl_flag|Alt_flag|Win_flag},
      {str = 'Shift+Ctrl+Alt+Win', flags = Shift_flag|Ctrl_flag|Alt_flag|Win_flag},
      
      
      }
      
    if ismac == true then
      Command_flag = DATA.reapervisiblemodifiers_mapping.Command
      Ctrl_flag = DATA.reapervisiblemodifiers_mapping.Ctrl
      Option_flag = DATA.reapervisiblemodifiers_mapping.Option
      
      
      modifiers = {
        {str = '-', flags = 0},
        {str = 'Command', flags = Command_flag},
        {str = 'Ctrl', flags = Ctrl_flag},
        {str = 'Command+Ctrl', flags = Command_flag|Ctrl_flag},
        {str = 'Option', flags = Option_flag},
        {str = 'Command+Option', flags = Command_flag|Option_flag},
        {str = 'Ctrl+Option', flags = Ctrl_flag|Option_flag},
        {str = 'Command+Ctrl+Option', flags = Command_flag|Ctrl_flag|Option_flag},
        }
    end
    
    
    if ImGui.BeginTable(ctx, 'currentkeytable', 2, ImGui.TableFlags_None|ImGui.TableFlags_BordersInnerV, 0, 0, 0) then 
      ImGui.TableSetupColumn(ctx, 'Modifier', ImGui.TableColumnFlags_None|ImGui.TableColumnFlags_WidthFixed, 100, 0)
      ImGui.TableSetupColumn(ctx, 'Command', ImGui.TableColumnFlags_None|ImGui.TableColumnFlags_WidthStretch, 0.65, 1)
      ImGui.TableHeadersRow(ctx)
      for i = 1 , #modifiers do
        ImGui.TableNextRow(ctx, ImGui.TableRowFlags_None,0)
        
        -- remove + modifier
          ImGui.TableSetColumnIndex(ctx,0)
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign,1,1)
          local bindings
          if modifiers[i].flags and DATA.kb[key_src] and DATA.kb[key_src].bindings and DATA.kb[key_src].bindings[modifiers[i].flags] then 
            bindings = DATA.kb[key_src].bindings[modifiers[i].flags]
          end
          if bindings then 
            if ImGui.Button(ctx, 'X##'..i) then
              
              UI.popups['Remove shortcut'] = {
                mode = 0,
                trig = true,
                captions_csv = 'Remove current shortcut?',
                func_setval = function(retval, retvals_csv)  
                  local section = bindings.section_ID
                  local cmdID = bindings.action_ID
                  local shortcutidx = bindings.shortcutidx 
                  DeleteActionShortcut( section, cmdID, shortcutidx )
                  DATA.upd = true
                end
                }
                
                
              
            end
          end
          ImGui.SameLine(ctx)
          ImGui.Selectable(ctx,modifiers[i].str)
          ImGui.PopStyleVar(ctx,1) 
        
        -- action
          ImGui.TableSetColumnIndex(ctx,1)
          local actionname = '-'
          if DATA.kb[key_src].bindings and DATA.kb[key_src].bindings[modifiers[i].flags] then actionname = DATA.kb[key_src].bindings[modifiers[i].flags].action_name end
          ImGui.Selectable(ctx,actionname)
          if ImGui.BeginDragDropTarget( ctx ) then
            local rv,cmdID = ImGui.AcceptDragDropPayload(ctx, 'actiondrop')
            if rv then
              DoActionShortcutDialog( hwnd, DATA.section_ID, cmdID, -1 )
              --[[msg(payload)
              msg(1)
              DATA:CollectData()]]
            end 
            ImGui.EndDragDropTarget( ctx )
          end
          --[[
          if retval then 
            msg(payload)
          end]]
      end
      ImGui.EndTable(ctx)
    end
    
    ImGui.PopFont(ctx)
    
    ImGui.PopStyleVar(ctx,1)
    ImGui.EndChild( ctx)
  end   
end
-------------------------------------------------------------------------------- 
function UI.draw_keyb() 
  --test
  --[[
  ImGui.SetCursorPos( ctx, UI.calc_blockoffs_X[1], UI.calc_blockoffs_Y[1]+80 )
  ImGui.Button(ctx, 'test',UI.calc_mainblockw,20)
  ]]
  
  -- show character
  if EXT.dev_char ==1 then
    ImGui.SetCursorPos( ctx, 10, 50 )
    ImGui.PushFont(ctx, DATA.font1) 
    local rv, c = ImGui.GetInputQueueCharacter(ctx, 0)
    if DATA.input_char_hex then ImGui.Text(ctx,DATA.input_char..': '..DATA.input_char_hex) end
    ImGui.PopFont(ctx)
  end
  
  ImGui.PushFont(ctx, DATA.font2) 
  local local_pos_x, local_pos_y
  for key in pairs(DATA.kb) do 
    if key:match('dummy') then goto nextkey end
    local block = DATA.kb[key].block
    local level = DATA.kb[key].level
    local pos =   DATA.kb[key].pos
    local extw =   DATA.kb[key].extw or 1
    local exth =   DATA.kb[key].exth or 1
    local butW = UI.calc_butW[level] or UI.calc_butW[1]
    local butH = UI.calc_butH[level] or UI.calc_butH[1]
    local_pos_x = math.floor(UI.calc_blockoffs_X[block] + (butW * (pos-1)) + UI.spacingX*(pos-1))
    local_pos_y = UI.calc_blockoffs_Y[level]
    local butw = butW*extw+(extw-1)*UI.spacingX
    local buth = butH*exth+(exth-1)*UI.spacingY
    if block == 2 or block == 3 then
      local_pos_x = UI.calc_blockoffs_X[block] + (UI.calc_butW[1] * (pos-1)) + UI.spacingX*(pos-1)
      butw = UI.calc_butW[1]*extw+(extw-1)*UI.spacingX
    end
    ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y )
    
    local col = UI.draw_keyb_definecolor(DATA.kb[key])
    
    local alphanormal0 = 0.5
    UI.draw_keyb_handleKBpress(DATA.kb[key])  
    if DATA.kb[key].state_pressed == true then alphanormal = 0.8 else alphanormal = alphanormal0 end
    if DATA.kb[key].state_release_fall == true then
      alphanormal = alphanormal0 + alphanormal * (1-DATA.kb[key].state_release_alphamult)
    end
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, math.floor(alphanormal*255)|(col<<8) )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, math.floor(0.9*255)|(col<<8) )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, math.floor(0.6*255)|(col<<8) )
    ImGui.BeginDisabled(ctx, DATA.kb[key].disabled or false)
    
    -- actually key
    local butx,buty,butx2,buty2=0,0,0,0
    local key_name = key:gsub('\\n','\n')
    if key_name:match('C%d+') then
      local char = key_name:match('C(%d+)')
      if tonumber(char) and string.char(tonumber(char)) then key_name = utf8.char(tonumber(char)) end
    end
    if ImGui.Button(ctx, key_name,butw,buth) then
      DATA.selectedkey = key
    end
    butx, buty = ImGui.GetItemRectMin(ctx)
    butx2, buty2 = ImGui.GetItemRectMax(ctx)
    if DATA.kb[key].disabled~= true and DATA.kb[key].bindings then UI.draw_KeyDetails_tooltip(key) end
    
    -- selection
    if DATA.selectedkey~= '' and DATA.selectedkey == key then
      local draw_list = ImGui.GetWindowDrawList(ctx)
      ImGui.DrawList_AddRect( draw_list, butx, buty,butx2,buty2, 0xFFFFFF8F, 5, ImGui.DrawFlags_None, 1)
    end
    
    ImGui.EndDisabled(ctx)
    ImGui.PopStyleColor(ctx, 3)
    ::nextkey::
  end
  ImGui.PopFont(ctx)
end
-------------------------------------------------------------------------------- 
function UI.draw_keyb_definecolor(kbt) 
  -- get color
    local inactive_col = UI.main_butcol 
    local active_col = UI.main_butcol_other
    if kbt.bindings and kbt.bindings[tflags] and kbt.bindings[tflags].color then active_col = kbt.bindings[tflags].color end
    
  -- return col
  if kbt.bindings then
    tflags = ImGui.GetKeyMods( ctx )
    if kbt.bindings[tflags] then -- no modifier flags
      
      return active_col
    end
  end
  
  return inactive_col
end
-------------------------------------------------------------------------------- 
function UI.draw_keyb_handleKBpress(keyt) 
  if not (keyt.reaimguikey or keyt.reaimguikeyID) then return end
  if keyt.reaimguikey then keyt.state_pressed = false end
  if keyt.reaimguikey and ImGui.IsKeyDown( ctx, keyt.reaimguikey ) then keyt.state_pressed = true end
  if keyt.reaimguikeyID then
    local curstate = keyt.reaimguikeyID == DATA.input_char
    if curstate == true and keyt.state_pressed ~= true then 
      DATA:SetSelectionFromReimGuiKey(keyt.reaimguikey)
    end
    if curstate == false and keyt.state_pressed ==true  then 
      DATA:SetSelectionFromReimGuiKey(keyt.reaimguikey)
      keyt.state_releaseTS = os.clock() 
    end
    keyt.state_pressed = curstate
  end
  
  -- handle smooth UI release 
  if keyt.reaimguikey and ImGui.IsKeyReleased( ctx, keyt.reaimguikey ) then 
    DATA:SetSelectionFromReimGuiKey(keyt.reaimguikey)
    keyt.state_releaseTS = os.clock() 
  end
  keyt.state_release_fall = false
  keyt.state_release_alphamult = 0
  if keyt.state_releaseTS and os.clock() - keyt.state_releaseTS  <UI.release_time  then
    keyt.state_release_fall = true
    keyt.state_release_alphamult = ((os.clock() - keyt.state_releaseTS)  / UI.release_time )
  end
  
  
end
-------------------------------------------------------------------------------- 
function UI.MAIN_PushStyle(key, value, value2)  
  if not ctx then return end
  local iscol = key:match('Col_')~=nil
  local keyid = ImGui[key]
  if not iscol then 
    ImGui.PushStyleVar(ctx, keyid, value, value2)
    UI.pushcnt = UI.pushcnt + 1
  else 
    ImGui.PushStyleColor(ctx, keyid, math.floor(value2*255)|(value<<8) )
    UI.pushcnt2 = UI.pushcnt2 + 1
  end 
end
-------------------------------------------------------------------------------- 
function UI.MAIN_draw(open) 
  local w_min = UI.main_W + UI.spacingX*2
  local h_min = UI.main_H
  
  
  -- window_flags
    local window_flags = ImGui.WindowFlags_None
    --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
    window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
    --window_flags = window_flags | ImGui.WindowFlags_MenuBar()
    --window_flags = window_flags | ImGui.WindowFlags_NoMove()
    --window_flags = window_flags | ImGui.WindowFlags_NoResize
    window_flags = window_flags | ImGui.WindowFlags_NoCollapse
    --window_flags = window_flags | ImGui.WindowFlags_NoNav()
    --window_flags = window_flags | ImGui.WindowFlags_NoBackground()
    window_flags = window_flags | ImGui.WindowFlags_NoDocking
    window_flags = window_flags | ImGui.WindowFlags_TopMost
    window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
    --if UI.disable_save_window_pos == true then window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings() end
    --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
    --open = false -- disable the close button
  
  
    -- set style
      UI.pushcnt = 0
      UI.pushcnt2 = 0
    -- rounding
      UI.MAIN_PushStyle('StyleVar_FrameRounding',5)  
      UI.MAIN_PushStyle('StyleVar_GrabRounding',3)  
      UI.MAIN_PushStyle('StyleVar_WindowRounding',10)  
      UI.MAIN_PushStyle('StyleVar_ChildRounding',5)  
      UI.MAIN_PushStyle('StyleVar_PopupRounding',0)  
      UI.MAIN_PushStyle('StyleVar_ScrollbarRounding',9)  
      UI.MAIN_PushStyle('StyleVar_TabRounding',4)   
    -- Borders
      UI.MAIN_PushStyle('StyleVar_WindowBorderSize',0)  
      UI.MAIN_PushStyle('StyleVar_FrameBorderSize',0) 
    -- spacing
      UI.MAIN_PushStyle('StyleVar_WindowPadding',UI.spacingX,UI.spacingY)  
      UI.MAIN_PushStyle('StyleVar_FramePadding',UI.spacingX,UI.spacingY) 
      UI.MAIN_PushStyle('StyleVar_CellPadding',UI.spacingX, UI.spacingY) 
      UI.MAIN_PushStyle('StyleVar_ItemSpacing',UI.spacingX, UI.spacingY)
      UI.MAIN_PushStyle('StyleVar_ItemInnerSpacing',4,0)
      UI.MAIN_PushStyle('StyleVar_IndentSpacing',20)
      UI.MAIN_PushStyle('StyleVar_ScrollbarSize',10)
    -- size
      UI.MAIN_PushStyle('StyleVar_GrabMinSize',20)
      UI.MAIN_PushStyle('StyleVar_WindowMinSize',w_min,h_min)
    -- align
      UI.MAIN_PushStyle('StyleVar_WindowTitleAlign',0.5,0.5)
      UI.MAIN_PushStyle('StyleVar_ButtonTextAlign',0.5,0.5)
      --UI.MAIN_PushStyle('StyleVar_SelectableTextAlign,0,0 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextAlign,0,0.5 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextPadding,20,3 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextBorderSize,3 )
    -- alpha
      UI.MAIN_PushStyle('StyleVar_Alpha',0.98)
      --UI.MAIN_PushStyle('StyleVar_DisabledAlpha,0.6 ) 
      UI.MAIN_PushStyle('Col_Border',UI.main_col, 0.3)
    -- colors
      --UI.MAIN_PushStyle('Col_BorderShadow(),0xFFFFFF, 1)
      UI.MAIN_PushStyle('Col_Button',UI.main_col, 0.2) --0.3
      UI.MAIN_PushStyle('Col_ButtonActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_ButtonHovered',UI.but_hovered, 0.8)
      --UI.MAIN_PushStyle('Col_CheckMark(),UI.main_col, 0, true)
      --UI.MAIN_PushStyle('Col_ChildBg(),UI.main_col, 0, true)
      --UI.MAIN_PushStyle('Col_ChildBg(),UI.main_col, 0, true) 
      
      
      --Constant: Col_DockingEmptyBg
      --Constant: Col_DockingPreview
      --Constant: Col_DragDropTarget 
      UI.MAIN_PushStyle('Col_DragDropTarget',0xFF1F5F, 0.6)
      UI.MAIN_PushStyle('Col_FrameBg',0x1F1F1F, 0.7)
      UI.MAIN_PushStyle('Col_FrameBgActive',UI.main_col, .6)
      UI.MAIN_PushStyle('Col_FrameBgHovered',UI.main_col, 0.7)
      UI.MAIN_PushStyle('Col_Header',UI.main_col, 0.5) 
      UI.MAIN_PushStyle('Col_HeaderActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_HeaderHovered',UI.main_col, 0.98) 
      --Constant: Col_MenuBarBg
      --Constant: Col_ModalWindowDimBg
      --Constant: Col_NavHighlight
      --Constant: Col_NavWindowingDimBg
      --Constant: Col_NavWindowingHighlight
      --Constant: Col_PlotHistogram
      --Constant: Col_PlotHistogramHovered
      --Constant: Col_PlotLines
      --Constant: Col_PlotLinesHovered 
      UI.MAIN_PushStyle('Col_PopupBg',0x303030, 0.9) 
      UI.MAIN_PushStyle('Col_ResizeGrip',UI.main_col, 1) 
      --Constant: Col_ResizeGripActive 
      UI.MAIN_PushStyle('Col_ResizeGripHovered',UI.main_col, 1) 
      --Constant: Col_ScrollbarBg
      --Constant: Col_ScrollbarGrab
      --Constant: Col_ScrollbarGrabActive
      --Constant: Col_ScrollbarGrabHovered
      --Constant: Col_Separator
      --Constant: Col_SeparatorActive
      --Constant: Col_SeparatorHovered
      --Constant: Col_SliderGrabActive
      UI.MAIN_PushStyle('Col_SliderGrab',UI.butBg_green, 0.4) 
      UI.MAIN_PushStyle('Col_Tab',UI.main_col, 0.37) 
      --UI.MAIN_PushStyle('Col_TabActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_TabHovered',UI.main_col, 0.8) 
      --Constant: Col_TabUnfocused
      --'Col_TabUnfocusedActive
      --UI.MAIN_PushStyle('Col_TabUnfocusedActive(),UI.main_col, 0.8, true)
      --Constant: Col_TableBorderLight
      --Constant: Col_TableBorderStrong
      
      UI.MAIN_PushStyle('Col_TableHeaderBg',UI.main_col, 0.5) 
      --Constant: Col_TableRowBg
      --Constant: Col_TableRowBgAlt
      UI.MAIN_PushStyle('Col_Text',UI.textcol, UI.textcol_a_enabled) 
      --Constant: Col_TextDisabled
      --Constant: Col_TextSelectedBg
      UI.MAIN_PushStyle('Col_TitleBg',UI.main_col, 0.7) 
      UI.MAIN_PushStyle('Col_TitleBgActive',UI.main_col, 0.95) 
      --Constant: Col_TitleBgCollapsed 
      UI.MAIN_PushStyle('Col_WindowBg',UI.windowBg, 1)
    
  -- We specify a default position/size in case there's no data in the .ini file.
    local main_viewport = ImGui.GetMainViewport(ctx)
    local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
    ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
    ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    --ImGui.SetNextWindowSize(ctx, w_min, h_min, ImGui.Cond_Always)
    
    
  -- init UI 
    ImGui.PushFont(ctx, DATA.font1) 
    local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) 
    if rv then
      local Viewport = ImGui.GetWindowViewport(ctx)
      DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport) 
      DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport) 
      DATA.display_w_region, DATA.display_h_region = ImGui.Viewport_GetSize(Viewport) 
      
    -- calc stuff for childs
      UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
      local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
      local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
      UI.calc_itemH = calcitemh + frameh * 2
      UI.calc_itemH_small = math.floor(UI.calc_itemH*0.8)
      
      UI.MAIN_calc() 
      
      local rv, unicode_char = ImGui.GetInputQueueCharacter(ctx, 0)
      if rv then  
        DATA.input_char = unicode_char
        DATA.input_char_hex = ("'%s' (0x%04X)"):format(utf8.char(unicode_char), unicode_char)
      end
      
    -- draw stuff
      UI.draw()
      ImGui.Dummy(ctx,0,0) 
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
      ImGui.End(ctx)
     else
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
    end 
    ImGui.PopFont( ctx ) 
    --if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
    
    
    -- popups
    for key in pairs(UI.popups) do
      -- trig
      if UI.popups[key] and UI.popups[key].trig == true then
        UI.popups[key].trig = false
        UI.popups[key].draw = true
        ImGui.OpenPopup( ctx, key, ImGui.PopupFlags_NoOpenOverExistingPopup )
      end
      -- draw
      if UI.popups[key] and UI.popups[key].draw == true then UI.GetUserInputMB_replica(UI.popups[key].mode or 1, key, DATA.UI_name, 1, UI.popups[key].captions_csv, UI.popups[key].func_getval, UI.popups[key].func_setval) end 
    end
    
    
    return open
end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_shortcuts()
    if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then 
      for key in pairs(UI.popups) do UI.popups[key].draw = false end
      ImGui.CloseCurrentPopup( ctx ) 
    end
   -- if  ImGui.IsKeyPressed( ctx, ImGui.Key_Space,false )  then  VF_Action(40044) end
  end  
  -------------------------------------------------------------------------------- 
  function UI.GetUserInputMB_replica(mode, key, title, num_inputs, captions_csv, retvals_csv_returnfunc, retvals_csv_setfunc) 
    local round = 4
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, round)
    
      -- draw content
      -- (from reaimgui demo) Always center this window when appearing
      local center_x, center_y = ImGui.Viewport_GetCenter(ImGui.GetWindowViewport(ctx))
      ImGui.SetNextWindowPos(ctx, center_x, center_y, ImGui.Cond_Appearing, 0.5, 0.5)
      if ImGui.BeginPopupModal(ctx, key, ImGui.ChildFlags_FrameStyle, ImGui.WindowFlags_AlwaysAutoResize|ImGui.ChildFlags_Border|ImGui.WindowFlags_TopMost) then
      
        -- MB replika
        if mode == 0 then
          ImGui.Text(ctx, captions_csv)
          ImGui.Separator(ctx) 
        
          if ImGui.Button(ctx, 'OK', 0, 0) then 
            UI.popups[key].draw = false
            if retvals_csv_setfunc then retvals_csv_setfunc(retval, buf) end
            ImGui.CloseCurrentPopup(ctx) 
          end
          
          ImGui.SetItemDefaultFocus(ctx)
          ImGui.SameLine(ctx)
          if ImGui.Button(ctx, 'Cancel', 120, 0) then 
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end
        end
        
        -- GetUserInput replika
        if mode == 1 then
          ImGui.SameLine(ctx)
          ImGui.SetKeyboardFocusHere( ctx )
          local retval, buf = ImGui.InputText( ctx, captions_csv, retvals_csv_returnfunc(), ImGui.InputTextFlags_EnterReturnsTrue ) 
          if retval then
            retvals_csv_setfunc(retval, buf)
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end 
        end
        
        ImGui.EndPopup(ctx)
      end 
    
    
    ImGui.PopStyleVar(ctx, 4)
  end 
  --------------------------------------------------------------------------------  
  function UI.MAIN_PopStyle(ctx, cnt, cnt2)
    if cnt then 
      ImGui.PopStyleVar(ctx,cnt)
      UI.pushcnt = UI.pushcnt -cnt
    end
    if cnt2 then
      ImGui.PopStyleColor(ctx,cnt2)
      UI.pushcnt2 = UI.pushcnt2 -cnt2
    end
  end
-------------------------------------------------------------------------------- 
function UI.MAINloop() 
  DATA.clock = os.clock() 
  DATA:handleProjUpdates()
  DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1))
  
  if DATA.upd == true then  DATA:CollectData()  end 
  DATA.upd = false
  
  -- draw UI
  UI.open = UI.MAIN_draw(true) 
  
  -- handle xy
  DATA:handleViewportXYWH()
  -- data
  if UI.open then defer(UI.MAINloop) end
end
-------------------------------------------------------------------------------- 
function UI.SameLine(ctx) ImGui.SameLine(ctx) end
-------------------------------------------------------------------------------- 
function UI.MAIN()
  
  EXT:load() 
  EXT.presetview = 0
  
  -- imgUI init
  ctx = ImGui.CreateContext(DATA.UI_name) 
  -- fonts
  DATA.font1 = ImGui.CreateFont(UI.font, UI.font1sz) ImGui.Attach(ctx, DATA.font1)
  DATA.font2 = ImGui.CreateFont(UI.font, UI.font2sz) ImGui.Attach(ctx, DATA.font2)
  DATA.font3 = ImGui.CreateFont(UI.font, UI.font3sz) ImGui.Attach(ctx, DATA.font3)  
  -- config
  ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
  ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort)
  
  
  -- run loop
  defer(UI.MAINloop)
end
-------------------------------------------------------------------------------- 
function DATA:Init_Search_ActionList() 
  local action_name
  for actionID in pairs(DATA.actions) do
    DATA.actions[actionID].fitsearch = false
    if EXT.search ~= '' then
      action_name = DATA.actions[actionID].action_name
      action_name = action_name:lower()
      if action_name:match(EXT.search:lower()) then
        DATA.actions[actionID].fitsearch = true
      end
     else 
      DATA.actions[actionID].fitsearch = true
    end
  end
end
-------------------------------------------------------------------------------- 
function DATA:Init_LoadExtColors() 
  EXT:load() 
  for i =1, EXT.categoriescnt do if EXT['category'..i..'_color'] and EXT['category'..i..'_color']~= '' then DATA.category[i].color = EXT['category'..i..'_color'] end end
end
-------------------------------------------------------------------------------- 
function DATA:CollectData()
  DATA.kb = {}
  DATA:Init_LoadExtColors() 
  DATA:Init_kbDefinition_UI()
  
  --[[if EXT.layout == 0 then 
    
   elseif EXT.layout == 1 then 
    DATA:Init_kbDefinition_UI_AZERTY()
   elseif EXT.layout == 2 then 
    DATA:Init_kbDefinition_UI_MIDIOSC() 
  end]]
  DATA:Init_kbDefinition_ActionList() 
  --DATA:Init_Search_ActionList() 
  
  UI.MAIN_calc_layout() 
  
  --[[ reset colors
    for i =1, EXT.categoriescnt do EXT['category'..i..'_col'] = '' end
    EXT:save()]]
end
-------------------------------------------------------------------------------- 
function EXT:save() 
  if not DATA.ES_key then return end 
  for key in pairs(EXT) do 
    if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then 
      SetExtState( DATA.ES_key, key, EXT[key], true  ) 
    end 
  end 
  EXT:load()
end
-------------------------------------------------------------------------------- 
function EXT:load() 
  if not DATA.ES_key then return end
  for key in pairs(EXT) do 
    if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then 
      if HasExtState( DATA.ES_key, key ) then 
        local val = GetExtState( DATA.ES_key, key ) 
        EXT[key] = tonumber(val) or val 
      end 
    end  
  end 
  DATA.upd = true
end
-------------------------------------------------------------------------------- 
function DATA:handleViewportXYWH()
  if not (DATA.display_x and DATA.display_y) then return end 
  if not DATA.display_x_last then DATA.display_x_last = DATA.display_x end
  if not DATA.display_y_last then DATA.display_y_last = DATA.display_y end
  if not DATA.display_w_last then DATA.display_w_last = DATA.display_w end
  if not DATA.display_h_last then DATA.display_h_last = DATA.display_h end
  
  if  DATA.display_x_last~= DATA.display_x 
    or DATA.display_y_last~= DATA.display_y 
    or DATA.display_w_last~= DATA.display_w 
    or DATA.display_h_last~= DATA.display_h 
    then 
    DATA.display_schedule_save = os.clock() 
  end
  if DATA.display_schedule_save and os.clock() - DATA.display_schedule_save > 0.3 then 
    EXT.viewport_posX = DATA.display_x
    EXT.viewport_posY = DATA.display_y
    EXT.viewport_posW = DATA.display_w
    EXT.viewport_posH = DATA.display_h
    EXT:save() 
    DATA.display_schedule_save = nil 
  end
  DATA.display_x_last = DATA.display_x
  DATA.display_y_last = DATA.display_y
  DATA.display_w_last = DATA.display_w
  DATA.display_h_last = DATA.display_h
end
-------------------------------------------------------------------------------- 
function DATA:handleProjUpdates()
  local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
  local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
  local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
end
--------------------------------------------------------------------------------  
function UI.draw_combo()
  ImGui.SetCursorPos( ctx, UI.calc_combo1_x, UI.calc_combo1_y ) 
  ImGui.SetNextItemWidth( ctx, UI.calc_combo1_w )
  
  -- current section
  local preview = EXT.section_ID
  local preview_str = DATA.sections[preview]
  if ImGui.BeginCombo( ctx, '##section', preview_str, ImGui.ComboFlags_None ) then
    for sectID in spairs(DATA.sections) do
      local sectname = DATA.sections[sectID]
      if ImGui.Selectable(ctx, sectname) then
        EXT.section_ID = sectID
        EXT:save()
        DATA.upd = true
      end
    end
    ImGui.EndCombo( ctx )
  end
  
  -- ext layout
  ImGui.SetCursorPos( ctx, UI.calc_combo2_x, UI.calc_combo2_y ) 
  ImGui.SetNextItemWidth( ctx, UI.calc_combo2_w )
  local preview_str = EXT.extlayoutname
  if ImGui.BeginCombo( ctx, '##layout', preview_str, ImGui.ComboFlags_None ) then
    for layout in spairs(DATA.extlayouts) do
      local layoutname = layout
      if ImGui.Selectable(ctx, layoutname) then
        EXT.extlayoutname = layoutname
        EXT:save()
        DATA.upd = true
      end
    end
    
    local retval, v = ImGui.Checkbox( ctx, 'dev_char', EXT.dev_char == 1 )
    if retval then
      local val = 0
      if v == true then val = 1 end
      EXT.dev_char =val
      EXT:save()
      DATA.upd = true
    end
    
    
    ImGui.EndCombo( ctx ) 
  end
  
end
--------------------------------------------------------------------------------  
  function UI.draw()  
    UI.draw_keyb()   
    UI.draw_combo() 
    UI.draw_KeyCategories() 
    --UI.draw_ActionList() 
    UI.draw_KeyDetails() 
  end
  ---------------------------------------------------
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
  end
---------------------------------------------------
function VF_CopyTable(orig)--http://lua-users.org/wiki/CopyTable
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[VF_CopyTable(orig_key)] = VF_CopyTable(orig_value)
        end
        setmetatable(copy, VF_CopyTable(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end 
----------------------------------------------------------------------------------------- 
function DATA:ValidateLayouts(filename)
  DATA.extlayouts = {}
  local layouts_fp = filename:gsub('%.lua',' - layout.txt')
  
  --local content = DATA:ValidateLayouts_Init(layouts_fp) 
  
  
  local f = io.open(layouts_fp, 'rb') 
  if f then 
    content = f:read('a')
    f:close()
   else
    content = DATA:ValidateLayouts_Init(layouts_fp)
  end
  if not content then return end
  
  
  -- parse  
  local id=0
  for layout in content:gmatch('<LAYOUT(.-)ENDLAYOUT>') do
    local name if layout:match('NAME (.-)') then name = layout:match('NAME (.-)[\r\n]') end
    if name then
      id = id + 1
      DATA.extlayouts[name] = {ID=id, BLOCKS={}}
      for line in layout:gmatch('[^\r\n]+') do
        if line:match('KEY') then
          local              KBNAME, BLOCK, LEVEL, IMGUI, BINDINGNAME, EXTW, EXTH = line:match('KEY KBNAME (.-) BLOCK (%d+) LEVEL (%d+) IMGUI (.-) BINDINGNAME ([%a%d%p%s]+) EXTW ([%d%.]+) EXTH ([%d%.]+)')
          if not KBNAME then KBNAME, BLOCK, LEVEL, IMGUI, BINDINGNAME, EXTH =       line:match('KEY KBNAME (.-) BLOCK (%d+) LEVEL (%d+) IMGUI (.-) BINDINGNAME ([%a%d%p%s]+) EXTH ([%d%.]+)') end
          if not KBNAME then KBNAME, BLOCK, LEVEL, IMGUI, BINDINGNAME, EXTW =       line:match('KEY KBNAME (.-) BLOCK (%d+) LEVEL (%d+) IMGUI (.-) BINDINGNAME ([%a%d%p%s]+) EXTW ([%d%.]+)') end
          if not KBNAME then KBNAME, BLOCK, LEVEL, IMGUI, BINDINGNAME =             line:match('KEY KBNAME (.-) BLOCK (%d+) LEVEL (%d+) IMGUI (.-) BINDINGNAME ([%a%d%p%s]+)') end 
          
          BLOCK = tonumber(BLOCK) or BLOCK
          LEVEL = tonumber(LEVEL) or LEVEL
          if not DATA.extlayouts[name].BLOCKS[BLOCK] then DATA.extlayouts[name].BLOCKS[BLOCK] = {} end
          if not DATA.extlayouts[name].BLOCKS[BLOCK].LEVELS then DATA.extlayouts[name].BLOCKS[BLOCK].LEVELS = {} end
          if not DATA.extlayouts[name].BLOCKS[BLOCK].LEVELS[LEVEL] then DATA.extlayouts[name].BLOCKS[BLOCK].LEVELS[LEVEL] = {} end 
          
          local id = #DATA.extlayouts[name].BLOCKS[BLOCK].LEVELS[LEVEL] +1
          DATA.extlayouts[name].BLOCKS[BLOCK].LEVELS[LEVEL][id] = {
            KBNAME=KBNAME,
            IMGUI=tonumber(IMGUI) or IMGUI, 
            BINDINGNAME=BINDINGNAME,
            EXTW=EXTW,
            EXTH=EXTH,
          }
        end 
      end
    end
  end
  
end
----------------------------------------------------------------------------------------- 
function DATA:ValidateLayouts_Init(layouts_fp)
  local content = [[
<LAYOUT
  NAME QWERTY
  KEY KBNAME Esc BLOCK 1 LEVEL 1 IMGUI Key_Escape BINDINGNAME ESC
  KEY KBNAME F1 BLOCK 1 LEVEL 1 IMGUI Key_F1 BINDINGNAME F1
  KEY KBNAME F2 BLOCK 1 LEVEL 1 IMGUI Key_F2 BINDINGNAME F2
  KEY KBNAME F3 BLOCK 1 LEVEL 1 IMGUI Key_F3 BINDINGNAME F3
  KEY KBNAME F4 BLOCK 1 LEVEL 1 IMGUI Key_F4 BINDINGNAME F4
  KEY KBNAME F5 BLOCK 1 LEVEL 1 IMGUI Key_F5 BINDINGNAME F5
  KEY KBNAME F6 BLOCK 1 LEVEL 1 IMGUI Key_F6 BINDINGNAME F6
  KEY KBNAME F7 BLOCK 1 LEVEL 1 IMGUI Key_F7 BINDINGNAME F7
  KEY KBNAME F8 BLOCK 1 LEVEL 1 IMGUI Key_F8 BINDINGNAME F8
  KEY KBNAME F9 BLOCK 1 LEVEL 1 IMGUI Key_F9 BINDINGNAME F9
  KEY KBNAME F10 BLOCK 1 LEVEL 1 IMGUI Key_F10 BINDINGNAME F10
  KEY KBNAME F11 BLOCK 1 LEVEL 1 IMGUI Key_F11 BINDINGNAME F11
  KEY KBNAME F12 BLOCK 1 LEVEL 1 IMGUI Key_F12 BINDINGNAME F12
  
  KEY KBNAME ~ BLOCK 1 LEVEL 2 IMGUI Key_GraveAccent BINDINGNAME `
  KEY KBNAME 1 BLOCK 1 LEVEL 2 IMGUI Key_1 BINDINGNAME 1
  KEY KBNAME 2 BLOCK 1 LEVEL 2 IMGUI Key_2 BINDINGNAME 2
  KEY KBNAME 3 BLOCK 1 LEVEL 2 IMGUI Key_3 BINDINGNAME 3
  KEY KBNAME 4 BLOCK 1 LEVEL 2 IMGUI Key_4 BINDINGNAME 4
  KEY KBNAME 5 BLOCK 1 LEVEL 2 IMGUI Key_5 BINDINGNAME 5
  KEY KBNAME 6 BLOCK 1 LEVEL 2 IMGUI Key_6 BINDINGNAME 6
  KEY KBNAME 7 BLOCK 1 LEVEL 2 IMGUI Key_7 BINDINGNAME 7
  KEY KBNAME 8 BLOCK 1 LEVEL 2 IMGUI Key_8 BINDINGNAME 8
  KEY KBNAME 9 BLOCK 1 LEVEL 2 IMGUI Key_9 BINDINGNAME 9
  KEY KBNAME 0 BLOCK 1 LEVEL 2 IMGUI Key_0 BINDINGNAME 0
  KEY KBNAME BackSpace BLOCK 1 LEVEL 2 IMGUI Key_Backspace BINDINGNAME Backspace EXTW 2
  
  KEY KBNAME Insert BLOCK 2 LEVEL 2 IMGUI Key_Insert BINDINGNAME Insert
  KEY KBNAME Home BLOCK 2 LEVEL 2 IMGUI Key_Home BINDINGNAME Home
  KEY KBNAME Page\nUp BLOCK 2 LEVEL 2 IMGUI Key_PageUp BINDINGNAME Page Up
  
  KEY KBNAME Num\nLock BLOCK 3 LEVEL 2 IMGUI Key_NumLock BINDINGNAME Num Lock
  KEY KBNAME /##Num/ BLOCK 3 LEVEL 2 IMGUI Key_KeypadDivide BINDINGNAME Num /
  KEY KBNAME *##Num* BLOCK 3 LEVEL 2 IMGUI Key_KeypadMultiply BINDINGNAME Num *
  KEY KBNAME -##Num- BLOCK 3 LEVEL 2 IMGUI Key_KeypadSubtract BINDINGNAME Num -
  
  KEY KBNAME Tab BLOCK 1 LEVEL 3 IMGUI Key_Tab BINDINGNAME Tab EXTW 1.5
  KEY KBNAME Q BLOCK 1 LEVEL 3 IMGUI Key_Q BINDINGNAME Q
  KEY KBNAME W BLOCK 1 LEVEL 3 IMGUI Key_W BINDINGNAME W
  KEY KBNAME E BLOCK 1 LEVEL 3 IMGUI Key_E BINDINGNAME E
  KEY KBNAME R BLOCK 1 LEVEL 3 IMGUI Key_R BINDINGNAME R
  KEY KBNAME T BLOCK 1 LEVEL 3 IMGUI Key_T BINDINGNAME T
  KEY KBNAME Y BLOCK 1 LEVEL 3 IMGUI Key_Y BINDINGNAME Y
  KEY KBNAME U BLOCK 1 LEVEL 3 IMGUI Key_U BINDINGNAME U
  KEY KBNAME I BLOCK 1 LEVEL 3 IMGUI Key_I BINDINGNAME I
  KEY KBNAME O BLOCK 1 LEVEL 3 IMGUI Key_O BINDINGNAME O
  KEY KBNAME P BLOCK 1 LEVEL 3 IMGUI Key_P BINDINGNAME P
  KEY KBNAME [ BLOCK 1 LEVEL 3 IMGUI Key_LeftBracket BINDINGNAME [
  KEY KBNAME ] BLOCK 1 LEVEL 3 IMGUI Key_RightBracket BINDINGNAME ]
  KEY KBNAME \ BLOCK 1 LEVEL 3 IMGUI Key_Backslash BINDINGNAME \
  
  KEY KBNAME Del BLOCK 2 LEVEL 3 IMGUI Key_Delete BINDINGNAME Delete
  KEY KBNAME End BLOCK 2 LEVEL 3 IMGUI Key_End BINDINGNAME End
  KEY KBNAME Page\nDown BLOCK 2 LEVEL 3 IMGUI Key_PageDown BINDINGNAME Page Down
  
  KEY KBNAME 7##Num7 BLOCK 3 LEVEL 3 IMGUI Key_Keypad7 BINDINGNAME Num 7
  KEY KBNAME 8##Num8 BLOCK 3 LEVEL 3 IMGUI Key_Keypad8 BINDINGNAME Num 8
  KEY KBNAME 9##Num9 BLOCK 3 LEVEL 3 IMGUI Key_Keypad9 BINDINGNAME Num 9
  KEY KBNAME +##Num+ BLOCK 3 LEVEL 3 IMGUI Key_KeypadAdd BINDINGNAME Num + EXTH 2
  
  KEY KBNAME Caps\nLock BLOCK 1 LEVEL 4 IMGUI Key_CapsLock BINDINGNAME Caps Lock EXTW 2
  KEY KBNAME A BLOCK 1 LEVEL 4 IMGUI Key_A BINDINGNAME A
  KEY KBNAME S BLOCK 1 LEVEL 4 IMGUI Key_S BINDINGNAME S
  KEY KBNAME D BLOCK 1 LEVEL 4 IMGUI Key_D BINDINGNAME D
  KEY KBNAME F BLOCK 1 LEVEL 4 IMGUI Key_F BINDINGNAME F
  KEY KBNAME G BLOCK 1 LEVEL 4 IMGUI Key_G BINDINGNAME G
  KEY KBNAME H BLOCK 1 LEVEL 4 IMGUI Key_H BINDINGNAME H
  KEY KBNAME J BLOCK 1 LEVEL 4 IMGUI Key_J BINDINGNAME J
  KEY KBNAME K BLOCK 1 LEVEL 4 IMGUI Key_K BINDINGNAME K
  KEY KBNAME L BLOCK 1 LEVEL 4 IMGUI Key_L BINDINGNAME L
  KEY KBNAME ; BLOCK 1 LEVEL 4 IMGUI Key_Semicolon BINDINGNAME ;
  KEY KBNAME ' BLOCK 1 LEVEL 4 IMGUI Key_Apostrophe BINDINGNAME '
  KEY KBNAME Enter BLOCK 1 LEVEL 4 IMGUI Key_Enter BINDINGNAME Enter EXTW 2
  
  KEY KBNAME 4##Num4 BLOCK 3 LEVEL 4 IMGUI Key_Keypad4 BINDINGNAME Num 4
  KEY KBNAME 5##Num5 BLOCK 3 LEVEL 4 IMGUI Key_Keypad5 BINDINGNAME Num 5
  KEY KBNAME 6##Num6 BLOCK 3 LEVEL 4 IMGUI Key_Keypad6 BINDINGNAME Num 6
  
  KEY KBNAME Shift##Lshift BLOCK 1 LEVEL 5 IMGUI Key_LeftShift BINDINGNAME Shift EXTW 2
  KEY KBNAME Z BLOCK 1 LEVEL 5 IMGUI Key_Z BINDINGNAME Z
  KEY KBNAME X BLOCK 1 LEVEL 5 IMGUI Key_X BINDINGNAME X
  KEY KBNAME C BLOCK 1 LEVEL 5 IMGUI Key_C BINDINGNAME C
  KEY KBNAME V BLOCK 1 LEVEL 5 IMGUI Key_V BINDINGNAME V
  KEY KBNAME B BLOCK 1 LEVEL 5 IMGUI Key_B BINDINGNAME B
  KEY KBNAME N BLOCK 1 LEVEL 5 IMGUI Key_N BINDINGNAME N
  KEY KBNAME M BLOCK 1 LEVEL 5 IMGUI Key_M BINDINGNAME M
  KEY KBNAME < BLOCK 1 LEVEL 5 IMGUI Key_Comma BINDINGNAME ,
  KEY KBNAME > BLOCK 1 LEVEL 5 IMGUI Key_Period BINDINGNAME .
  KEY KBNAME ? BLOCK 1 LEVEL 5 IMGUI Key_Slash BINDINGNAME ?
  KEY KBNAME Shift##Rshift BLOCK 1 LEVEL 5 IMGUI Key_RightShift BINDINGNAME Shift EXTW 2
  
  KEY KBNAME dummy BLOCK 2 LEVEL 5 IMGUI dummy BINDINGNAME dummy
  KEY KBNAME Up##ArrUp BLOCK 2 LEVEL 5 IMGUI Key_UpArrow BINDINGNAME Up
  
  KEY KBNAME 1##Num1 BLOCK 3 LEVEL 5 IMGUI Key_Keypad1 BINDINGNAME Num 1
  KEY KBNAME 2##Num2 BLOCK 3 LEVEL 5 IMGUI Key_Keypad2 BINDINGNAME Num 2
  KEY KBNAME 3##Num3 BLOCK 3 LEVEL 5 IMGUI Key_Keypad3 BINDINGNAME Num 3
  KEY KBNAME Enter##NumEnter BLOCK 3 LEVEL 5 IMGUI Key_KeypadEnter BINDINGNAME Num Enter EXTH 2
  
  KEY KBNAME Ctrl##LCtrl BLOCK 1 LEVEL 6 IMGUI Key_LeftCtrl BINDINGNAME Ctrl
  KEY KBNAME Alt BLOCK 1 LEVEL 6 IMGUI Key_LeftAlt BINDINGNAME Alt  
  KEY KBNAME Win\nL Super##Win BLOCK 1 LEVEL 6 IMGUI Key_LeftSuper BINDINGNAME Win
  KEY KBNAME Win\nR Super##WinRight BLOCK 1 LEVEL 6 IMGUI Key_RightSuper BINDINGNAME Win
  KEY KBNAME App\nBack BLOCK 1 LEVEL 6 IMGUI Key_AppBack BINDINGNAME Browser Back
  KEY KBNAME App\nForward BLOCK 1 LEVEL 6 IMGUI Key_AppForward BINDINGNAME Browser Forward
  KEY KBNAME Space BLOCK 1 LEVEL 6 IMGUI Key_Space BINDINGNAME Space EXTW 2
  
  KEY KBNAME Left##ArrLeft BLOCK 2 LEVEL 6 IMGUI Key_LeftArrow BINDINGNAME Left
  KEY KBNAME Down##ArrDown BLOCK 2 LEVEL 6 IMGUI Key_DownArrow BINDINGNAME Down
  KEY KBNAME Right##ArrRight BLOCK 2 LEVEL 6 IMGUI Key_RightArrow BINDINGNAME Right
  
  KEY KBNAME 0##Num0 BLOCK 3 LEVEL 6 IMGUI Key_Keypad0 BINDINGNAME Num 0  EXTW 2
  KEY KBNAME ,##NumDel BLOCK 3 LEVEL 6 IMGUI Key_KeypadDecimal BINDINGNAME Num Del 
ENDLAYOUT>  




<LAYOUT
  NAME AZERTY
  KEY KBNAME Esc BLOCK 1 LEVEL 1 IMGUI Key_Escape BINDINGNAME ESC
  KEY KBNAME F1 BLOCK 1 LEVEL 1 IMGUI Key_F1 BINDINGNAME F1
  KEY KBNAME F2 BLOCK 1 LEVEL 1 IMGUI Key_F2 BINDINGNAME F2
  KEY KBNAME F3 BLOCK 1 LEVEL 1 IMGUI Key_F3 BINDINGNAME F3
  KEY KBNAME F4 BLOCK 1 LEVEL 1 IMGUI Key_F4 BINDINGNAME F4
  KEY KBNAME F5 BLOCK 1 LEVEL 1 IMGUI Key_F5 BINDINGNAME F5
  KEY KBNAME F6 BLOCK 1 LEVEL 1 IMGUI Key_F6 BINDINGNAME F6
  KEY KBNAME F7 BLOCK 1 LEVEL 1 IMGUI Key_F7 BINDINGNAME F7
  KEY KBNAME F8 BLOCK 1 LEVEL 1 IMGUI Key_F8 BINDINGNAME F8
  KEY KBNAME F9 BLOCK 1 LEVEL 1 IMGUI Key_F9 BINDINGNAME F9
  KEY KBNAME F10 BLOCK 1 LEVEL 1 IMGUI Key_F10 BINDINGNAME F10
  KEY KBNAME F11 BLOCK 1 LEVEL 1 IMGUI Key_F11 BINDINGNAME F11
  KEY KBNAME F12 BLOCK 1 LEVEL 1 IMGUI Key_F12 BINDINGNAME F12
  
  KEY KBNAME ~ BLOCK 1 LEVEL 2 IMGUI Key_GraveAccent BINDINGNAME `
  KEY KBNAME 1 BLOCK 1 LEVEL 2 IMGUI Key_1 BINDINGNAME 1
  KEY KBNAME 2 BLOCK 1 LEVEL 2 IMGUI Key_2 BINDINGNAME 2
  KEY KBNAME 3 BLOCK 1 LEVEL 2 IMGUI Key_3 BINDINGNAME 3
  KEY KBNAME 4 BLOCK 1 LEVEL 2 IMGUI Key_4 BINDINGNAME 4
  KEY KBNAME 5 BLOCK 1 LEVEL 2 IMGUI Key_5 BINDINGNAME 5
  KEY KBNAME 6 BLOCK 1 LEVEL 2 IMGUI Key_6 BINDINGNAME 6
  KEY KBNAME 7 BLOCK 1 LEVEL 2 IMGUI Key_7 BINDINGNAME 7
  KEY KBNAME 8 BLOCK 1 LEVEL 2 IMGUI Key_8 BINDINGNAME 8
  KEY KBNAME 9 BLOCK 1 LEVEL 2 IMGUI Key_9 BINDINGNAME 9
  KEY KBNAME 0 BLOCK 1 LEVEL 2 IMGUI Key_0 BINDINGNAME 0
  KEY KBNAME BackSpace BLOCK 1 LEVEL 2 IMGUI Key_Backspace BINDINGNAME Backspace EXTW 2
  
  KEY KBNAME Insert BLOCK 2 LEVEL 2 IMGUI Key_Insert BINDINGNAME Insert
  KEY KBNAME Home BLOCK 2 LEVEL 2 IMGUI Key_Home BINDINGNAME Home
  KEY KBNAME PG\nPRÈC BLOCK 2 LEVEL 2 IMGUI Key_PageUp BINDINGNAME PG.PRÈC
  
  KEY KBNAME Num\nLock BLOCK 3 LEVEL 2 IMGUI Key_NumLock BINDINGNAME Num Lock
  KEY KBNAME /##Num/ BLOCK 3 LEVEL 2 IMGUI Key_KeypadDivide BINDINGNAME Num /
  KEY KBNAME *##Num* BLOCK 3 LEVEL 2 IMGUI Key_KeypadMultiply BINDINGNAME Num *
  KEY KBNAME -##Num- BLOCK 3 LEVEL 2 IMGUI Key_KeypadSubtract BINDINGNAME Num -
  
  KEY KBNAME Tab BLOCK 1 LEVEL 3 IMGUI Key_Tab BINDINGNAME Tab EXTW 1.5
  KEY KBNAME A BLOCK 1 LEVEL 3 IMGUI Key_A BINDINGNAME A
  KEY KBNAME Z BLOCK 1 LEVEL 3 IMGUI Key_Z BINDINGNAME Z
  KEY KBNAME E BLOCK 1 LEVEL 3 IMGUI Key_E BINDINGNAME E
  KEY KBNAME R BLOCK 1 LEVEL 3 IMGUI Key_R BINDINGNAME R
  KEY KBNAME T BLOCK 1 LEVEL 3 IMGUI Key_T BINDINGNAME T
  KEY KBNAME Y BLOCK 1 LEVEL 3 IMGUI Key_Y BINDINGNAME Y
  KEY KBNAME U BLOCK 1 LEVEL 3 IMGUI Key_U BINDINGNAME U
  KEY KBNAME I BLOCK 1 LEVEL 3 IMGUI Key_I BINDINGNAME I
  KEY KBNAME O BLOCK 1 LEVEL 3 IMGUI Key_O BINDINGNAME O
  KEY KBNAME P BLOCK 1 LEVEL 3 IMGUI Key_P BINDINGNAME P
  KEY KBNAME ^ BLOCK 1 LEVEL 3 IMGUI 94 BINDINGNAME ^
  KEY KBNAME $ BLOCK 1 LEVEL 3 IMGUI 36 BINDINGNAME $
  
  KEY KBNAME Del BLOCK 2 LEVEL 3 IMGUI Key_Delete BINDINGNAME Delete
  KEY KBNAME End BLOCK 2 LEVEL 3 IMGUI Key_End BINDINGNAME End
  KEY KBNAME PG\nSUIV BLOCK 2 LEVEL 3 IMGUI Key_PageDown BINDINGNAME PG.SUIV
  
  KEY KBNAME 7##Num7 BLOCK 3 LEVEL 3 IMGUI Key_Keypad7 BINDINGNAME Num 7
  KEY KBNAME 8##Num8 BLOCK 3 LEVEL 3 IMGUI Key_Keypad8 BINDINGNAME Num 8
  KEY KBNAME 9##Num9 BLOCK 3 LEVEL 3 IMGUI Key_Keypad9 BINDINGNAME Num 9
  KEY KBNAME +##Num+ BLOCK 3 LEVEL 3 IMGUI Key_KeypadAdd BINDINGNAME Num + EXTH 2
  
  KEY KBNAME Caps\nLock BLOCK 1 LEVEL 4 IMGUI Key_CapsLock BINDINGNAME Caps Lock EXTW 2
  
  
  KEY KBNAME Q BLOCK 1 LEVEL 4 IMGUI Key_Q BINDINGNAME Q
  KEY KBNAME S BLOCK 1 LEVEL 4 IMGUI Key_S BINDINGNAME S
  KEY KBNAME D BLOCK 1 LEVEL 4 IMGUI Key_D BINDINGNAME D
  KEY KBNAME F BLOCK 1 LEVEL 4 IMGUI Key_F BINDINGNAME F
  KEY KBNAME G BLOCK 1 LEVEL 4 IMGUI Key_G BINDINGNAME G
  KEY KBNAME H BLOCK 1 LEVEL 4 IMGUI Key_H BINDINGNAME H
  KEY KBNAME J BLOCK 1 LEVEL 4 IMGUI Key_J BINDINGNAME J
  KEY KBNAME K BLOCK 1 LEVEL 4 IMGUI Key_K BINDINGNAME K
  KEY KBNAME L BLOCK 1 LEVEL 4 IMGUI Key_L BINDINGNAME L 
  KEY KBNAME M BLOCK 1 LEVEL 4 IMGUI Key_M BINDINGNAME M 
  KEY KBNAME C195 BLOCK 1 LEVEL 4 IMGUI 195 BINDINGNAME C195
  KEY KBNAME * BLOCK 1 LEVEL 4 IMGUI 24 BINDINGNAME *
  KEY KBNAME Enter BLOCK 1 LEVEL 4 IMGUI Key_Enter BINDINGNAME Enter EXTW 2
  
  KEY KBNAME 4##Num4 BLOCK 3 LEVEL 4 IMGUI Key_Keypad4 BINDINGNAME Num 4
  KEY KBNAME 5##Num5 BLOCK 3 LEVEL 4 IMGUI Key_Keypad5 BINDINGNAME Num 5
  KEY KBNAME 6##Num6 BLOCK 3 LEVEL 4 IMGUI Key_Keypad6 BINDINGNAME Num 6
  
  KEY KBNAME Shift##Lshift BLOCK 1 LEVEL 5 IMGUI Key_LeftShift BINDINGNAME Shift EXTW 2 
  KEY KBNAME W BLOCK 1 LEVEL 5 IMGUI Key_W BINDINGNAME W
  KEY KBNAME X BLOCK 1 LEVEL 5 IMGUI Key_X BINDINGNAME X
  KEY KBNAME C BLOCK 1 LEVEL 5 IMGUI Key_C BINDINGNAME C
  KEY KBNAME V BLOCK 1 LEVEL 5 IMGUI Key_V BINDINGNAME V
  KEY KBNAME B BLOCK 1 LEVEL 5 IMGUI Key_B BINDINGNAME B
  KEY KBNAME N BLOCK 1 LEVEL 5 IMGUI Key_N BINDINGNAME N
  KEY KBNAME , BLOCK 1 LEVEL 5 IMGUI Key_Comma BINDINGNAME ,
  KEY KBNAME ; BLOCK 1 LEVEL 5 IMGUI Key_Semicolon BINDINGNAME ;
  KEY KBNAME : BLOCK 1 LEVEL 5 IMGUI 58 BINDINGNAME :
  KEY KBNAME ! BLOCK 1 LEVEL 5 IMGUI 33 BINDINGNAME !
  
  KEY KBNAME Shift##Rshift BLOCK 1 LEVEL 5 IMGUI Key_RightShift BINDINGNAME Shift EXTW 2
  
  KEY KBNAME dummy BLOCK 2 LEVEL 5 IMGUI dummy BINDINGNAME dummy
  KEY KBNAME Up##ArrUp BLOCK 2 LEVEL 5 IMGUI Key_UpArrow BINDINGNAME Up
  
  KEY KBNAME 1##Num1 BLOCK 3 LEVEL 5 IMGUI Key_Keypad1 BINDINGNAME Num 1
  KEY KBNAME 2##Num2 BLOCK 3 LEVEL 5 IMGUI Key_Keypad2 BINDINGNAME Num 2
  KEY KBNAME 3##Num3 BLOCK 3 LEVEL 5 IMGUI Key_Keypad3 BINDINGNAME Num 3
  KEY KBNAME Enter##NumEnter BLOCK 3 LEVEL 5 IMGUI Key_KeypadEnter BINDINGNAME Num Enter EXTH 2
  
  KEY KBNAME Ctrl##LCtrl BLOCK 1 LEVEL 6 IMGUI Key_LeftCtrl BINDINGNAME Ctrl
  KEY KBNAME Alt BLOCK 1 LEVEL 6 IMGUI Key_LeftAlt BINDINGNAME Alt  
  KEY KBNAME Win\nL Super##Win BLOCK 1 LEVEL 6 IMGUI Key_LeftSuper BINDINGNAME Win
  KEY KBNAME Win\nR Super##WinRight BLOCK 1 LEVEL 6 IMGUI Key_RightSuper BINDINGNAME Win
  KEY KBNAME App\nBack BLOCK 1 LEVEL 6 IMGUI Key_AppBack BINDINGNAME Browser Back
  KEY KBNAME App\nForward BLOCK 1 LEVEL 6 IMGUI Key_AppForward BINDINGNAME Browser Forward
  KEY KBNAME Space BLOCK 1 LEVEL 6 IMGUI Key_Space BINDINGNAME Space
  
  KEY KBNAME Left##ArrLeft BLOCK 2 LEVEL 6 IMGUI Key_LeftArrow BINDINGNAME Left
  KEY KBNAME Down##ArrDown BLOCK 2 LEVEL 6 IMGUI Key_DownArrow BINDINGNAME Down
  KEY KBNAME Right##ArrRight BLOCK 2 LEVEL 6 IMGUI Key_RightArrow BINDINGNAME Right
  
  KEY KBNAME 0##Num0 BLOCK 3 LEVEL 6 IMGUI Key_Keypad0 BINDINGNAME Num 0  EXTW 2
  KEY KBNAME ,##NumDel BLOCK 3 LEVEL 6 IMGUI Key_KeypadDecimal BINDINGNAME Num Del 
  
  
  
ENDLAYOUT>   
]]

  local f = io.open(layouts_fp, 'wb')
  if f then 
    f:write(content)
    f:close()
  end
  
  return content
end
----------------------------------------------------------------------------------------- 
function main()
  local is_new_value,filename,sectionID,cmdID,mode,resolution,val,contextstr = reaper.get_action_context()
  DATA:ValidateLayouts(filename) 
  EXT_defaults = VF_CopyTable(EXT)
  UI.MAIN() 
end  
-----------------------------------------------------------------------------------------
main()