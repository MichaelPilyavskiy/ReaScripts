-- @description Notification
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @about Script for showing custom notification
-- @provides
--    [main] mpl_Notification, set track volume changed.lua
-- @changelog
--    + pass through keyboard shortcuts

--------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
  if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end 
  local ImGui
  
  if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
  package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  ImGui = require 'imgui' '0.9.3.2'
  
  
-------------------------------------------------------------------------------- init external defaults 
EXT = {
        viewport_posX = 0,
        viewport_posY = 0,
        viewport_posW = 600,
        viewport_posH = 480,
        
         
        -- global
        CONF_name = 'default',
        CONF_txt1 = 'Test',
        CONF_txt2 = 'Test2', 
        CONF_png = [[]],
        CONF_png_scaling = 0.8,
        CONF_autoterminatetime = 4, -- seconds, script will close after this time
        CONF_autoterminate_fadetime = 2,-- seconds, fade time to make script fully transparent bofore close
      }
      
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'MPL_notification',
        UI_name = 'Notification', 
        upd = true, 
        preset_name = 'untitled', -- for inputtext
        presets_factory = {
          },
        presets = {
          factory= {},
          user= {}, 
          },
        }
        
        
-------------------------------------------------------------------------------- UI init variables
UI = {}
  
  UI.popups = {}
-- font  
  UI.font='Arial'
  UI.font1sz=48
  UI.font2sz=25
  UI.font3sz=12
-- style
  UI.pushcnt = 0
  UI.pushcnt2 = 0
-- size / offset
  UI.spacingX = 4
  UI.spacingY = 3
-- mouse
  UI.hoverdelay = 0.8
  UI.hoverdelayshort = 0.8
-- colors 
  UI.main_col = 0x7F7F7F -- grey
  UI.textcol = 0xFFFFFF
  UI.but_hovered = 0x878787
  UI.windowBg = 0x303030
-- alpha
  UI.textcol_a_enabled = 1
  UI.textcol_a_disabled = 0.5
  
  UI.knob_handle = 0xc8edfa
  UI.default_data_col_adv = '#00ff00' -- green
  UI.default_data_col_adv2 = '#e61919 ' -- red

  UI.indent = 20
  UI.knob_resY = 120
  






function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
-------------------------------------------------------------------------------- 
function UI.MAIN_PushStyle(key, value, value2)  
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
  local w_min = 250
  local h_min = 80
  -- window_flags
    local window_flags = ImGui.WindowFlags_None
    window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
    window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
    --window_flags = window_flags | ImGui.WindowFlags_MenuBar()
    --window_flags = window_flags | ImGui.WindowFlags_NoMove()
    --window_flags = window_flags | ImGui.WindowFlags_NoResize
    window_flags = window_flags | ImGui.WindowFlags_NoCollapse
    --window_flags = window_flags | ImGui.WindowFlags_NoNav()
    --window_flags = window_flags | ImGui.WindowFlags_NoBackground()
    window_flags = window_flags | ImGui.WindowFlags_NoDocking
    --window_flags = window_flags | ImGui.WindowFlags_TopMost
    window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
    --if UI.disable_save_window_pos == true then window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings() end
    --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
    --open = false -- disable the close button
  
  
    -- set style
      UI.pushcnt = 0
      UI.pushcnt2 = 0
    -- rounding
      UI.MAIN_PushStyle('StyleVar_FrameRounding',5)  
      UI.MAIN_PushStyle('StyleVar_GrabRounding',5)  
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
      UI.MAIN_PushStyle('StyleVar_FramePadding',10,5) 
      UI.MAIN_PushStyle('StyleVar_CellPadding',UI.spacingX, UI.spacingY) 
      UI.MAIN_PushStyle('StyleVar_ItemSpacing',UI.spacingX, UI.spacingY)
      UI.MAIN_PushStyle('StyleVar_ItemInnerSpacing',4,0)
      UI.MAIN_PushStyle('StyleVar_IndentSpacing',20)
      UI.MAIN_PushStyle('StyleVar_ScrollbarSize',20)
    -- size
      UI.MAIN_PushStyle('StyleVar_GrabMinSize',30)
      UI.MAIN_PushStyle('StyleVar_WindowMinSize',w_min,h_min)
    -- align
      UI.MAIN_PushStyle('StyleVar_WindowTitleAlign',0.5,0.5)
      UI.MAIN_PushStyle('StyleVar_ButtonTextAlign',0.5,0.5)
      --UI.MAIN_PushStyle('StyleVar_SelectableTextAlign,0,0 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextAlign,0,0.5 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextPadding,20,3 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextBorderSize,3 )
    -- alpha
      UI.MAIN_PushStyle('StyleVar_Alpha',0.9*(1-DATA.transparencyratio_inverted))
      --UI.MAIN_PushStyle('StyleVar_DisabledAlpha',1) 
      UI.MAIN_PushStyle('Col_Border',UI.main_col, 0.3)
    -- colors
      --UI.MAIN_PushStyle('Col_BorderShadow(),0xFFFFFF, 1)
      UI.MAIN_PushStyle('Col_Button',UI.main_col, 0.3) 
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
      --Constant: Col_SliderGrab
      --Constant: Col_SliderGrabActive
      UI.MAIN_PushStyle('Col_Tab',UI.main_col, 0.37) 
      --UI.MAIN_PushStyle('Col_TabActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_TabHovered',UI.main_col, 0.8) 
      --Constant: Col_TabUnfocused
      --'Col_TabUnfocusedActive
      --UI.MAIN_PushStyle('Col_TabUnfocusedActive(),UI.main_col, 0.8, true)
      --Constant: Col_TableBorderLight
      --Constant: Col_TableBorderStrong
      --Constant: Col_TableHeaderBg
      --Constant: Col_TableRowBg
      --Constant: Col_TableRowBgAlt
      UI.MAIN_PushStyle('Col_Text',UI.textcol, UI.textcol_a_enabled) 
      --Constant: Col_TextDisabled
      --Constant: Col_TextSelectedBg
      UI.MAIN_PushStyle('Col_TitleBg',UI.main_col, 0.7) 
      UI.MAIN_PushStyle('Col_TitleBgActive',UI.main_col, 0.95) 
      --Constant: Col_TitleBgCollapsed 
      UI.MAIN_PushStyle('Col_WindowBg',UI.windowBg, 0.6)
    
  -- We specify a default position/size in case there's no data in the .ini file.
    local main_viewport = ImGui.GetMainViewport(ctx)
    local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
    ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
    ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    
  -- init UI 
    
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
      --UI.calc_itemH = calcitemh + frameh * 2
      --UI.calc_childH = math.floor(DATA.display_h_region - UI.calc_yoffset*6 - UI.calc_itemH*2)/3
      --UI.calc_mainbut = math.floor(DATA.display_w_region - UI.calc_xoffset*4)/3
      UI.calc_maintxt_h = math.floor(DATA.display_h*0.7)
      UI.calc_maintxt2_h = DATA.display_h - UI.calc_maintxt_h-UI.calc_yoffset*3
      
      
    -- draw stuff
      UI.draw_passthroughshortcuts()
    
      UI.draw()
      ImGui.Dummy(ctx,0,0) 
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
      ImGui.End(ctx)
     else
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
    end 
    if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
  
    return open
end
--------------------------------------------------------------------------------  
function UI.draw_passthroughshortcuts()
  local ret, unicode_char = ImGui.GetInputQueueCharacter(ctx, 0)
  if ret == true then
    
    --Main=0, Main (alt recording)=100, MIDI Editor=32060, MIDI Event List Editor=32061, MIDI Inline Editor=32062, Media Explorer=32063
    
    local section = 0
    cmd = GetCommandByShortcut(section, ConvertCharToShortcut(unicode_char))
    if cmd then reaper.Main_OnCommand(cmd, section) return end
    
    if  reaper.MIDIEditor_GetActive() then
      local section = 32060
      cmd = GetCommandByShortcut(section, ConvertCharToShortcut(unicode_char))
      if cmd then reaper.Main_OnCommand(cmd, section) return end
    end
  end
end
--------------------------------------------------------------------------------  
function ConvertCharToShortcut(char) -- https://forums.cockos.com/showthread.php?p=2620519
  local special_chars = {}
  special_chars[8] = 'Backspace'
  special_chars[9] = 'Tab'
  special_chars[13] = 'Enter'
  special_chars[27] = 'ESC'
  special_chars[32] = 'Space'
  special_chars[176] = '°'
  special_chars[26161] = 'F1'
  special_chars[26162] = 'F2'
  special_chars[26163] = 'F3'
  special_chars[26164] = 'F4'
  special_chars[26165] = 'F5'
  special_chars[26166] = 'F6'
  special_chars[26167] = 'F7'
  special_chars[26168] = 'F8'
  special_chars[26169] = 'F9'
  special_chars[6697264] = 'F10'
  special_chars[6697265] = 'F11'
  special_chars[6697266] = 'F12'
  special_chars[65105] = '﹑'
  special_chars[65106] = '﹒'
  special_chars[6579564] = 'Delete'
  special_chars[6909555] = 'Insert'
  special_chars[1752132965] = 'Home'
  special_chars[6647396] = 'End'
  special_chars[1885828464] = 'Page Up'
  special_chars[1885824110] = 'Page Down'
  
    local is_ctrl = gfx.mouse_cap & 4 == 4
    local is_shift = gfx.mouse_cap & 8 == 8
    local is_alt = gfx.mouse_cap & 16 == 16

    local key

    -- Check for special characters, avoid 1..26 (Ctrl+A..Z)
    if not (is_ctrl and char <= 26) then key = special_chars[char] end

    if not key then
        -- Add offset for 1..26 (Ctrl+A..Z)
        if char >= 1 and char <= 26 then char = char + 64 end
        -- Add offset for 257..282 (Ctrl+Alt+A..Z)
        if char >= 257 and char <= 282 then char = char - 192 end
        -- Convert char to key string
        key = string.char(char & 0xFF):upper()
    end

    -- Add keyboard modifiers in text form
    if is_shift and key ~= key:lower() then key = 'Shift+' .. key end
    if is_alt then key = 'Alt+' .. key end
    if is_ctrl then key = 'Ctrl+' .. key end

    return key
end
--------------------------------------------------------------------------------  
function GetCommandByShortcut(section_id, shortcut) -- https://forums.cockos.com/showthread.php?p=2620519
    -- On MacOS, replace Ctrl with Cmd etc.
    local is_macos = reaper.GetOS():match('OS')
    if is_macos then
        shortcut = shortcut:gsub('Ctrl%+', 'Cmd+', 1)
        shortcut = shortcut:gsub('Alt%+', 'Opt+', 1)
    end
    
    -- Go through all actions of the section
    local sec = reaper.SectionFromUniqueID(section_id)
    local i = 0
    repeat
        local cmd = reaper.kbd_enumerateActions(sec, i)
        if cmd ~= 0 then
            -- Go through all shortcuts of each action
            for n = 0, reaper.CountActionShortcuts(sec, cmd) - 1 do
                -- Find the action that matches the given shortcut
                local _, desc = reaper.GetActionShortcutDesc(sec, cmd, n, '')
                if desc == shortcut then return cmd, n end
            end
        end
        i = i + 1
    until cmd == 0
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
function DATA:CollectData() 

  
end
-------------------------------------------------------------------------------- 
function DATA:CollectData_Always()
  if reaper.gmem_read(1 ) == 1 then 
    reaper.gmem_write(1,0 )
    EXT:load()
    DATA.upd = true
  end
end
-------------------------------------------------------------------------------- 
function UI.MAINloop() 
  DATA.transparencyratio_inverted = 0
  -- calc timer
  if not DATA.clock then 
    DATA.timerTS = os.clock() 
    DATA.timer = 0
   else
    DATA.timer = DATA.clock - DATA.timerTS
  end
  if DATA.timer> EXT.CONF_autoterminatetime then 
    return 
  end
  
  -- calc transparency ratio
  if DATA.timer> EXT.CONF_autoterminatetime - EXT.CONF_autoterminate_fadetime then
    DATA.transparencyratio_inverted = (DATA.timer - (EXT.CONF_autoterminatetime - EXT.CONF_autoterminate_fadetime)) / (EXT.CONF_autoterminatetime - EXT.CONF_autoterminate_fadetime)
   else
    
    DATA.transparencyratio_inverted = 0
  end
  
  
  DATA.clock = os.clock() 
  DATA:handleProjUpdates()
  
  if DATA.upd == true then  DATA:CollectData()  end 
  DATA.upd = false
  DATA:CollectData_Always()
  -- draw UI
  UI.open = UI.MAIN_draw(true) 
  
  if DATA.updXYWH == true then DATA.updXYWH = nil  end 
  -- handle xy
  DATA:handleViewportXYWH()
  -- data
  if UI.open then defer(UI.MAINloop) end
end
-------------------------------------------------------------------------------- 
function UI.MAIN() 
  EXT:load() 
  EXT.CONF_autoterminate_fadetime = math.min(EXT.CONF_autoterminate_fadetime,EXT.CONF_autoterminatetime)
  
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
function main() 
  EXT:load()  
  UI.MAIN() 
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col) 
    UI.MAIN_PushStyle('Col_Button',col, 0.5) 
    UI.MAIN_PushStyle('Col_ButtonActive',col, 1) 
    UI.MAIN_PushStyle('Col_ButtonHovered',col, 0.8)
end
--------------------------------------------------------------------------------  
function UI.draw()  
  -- png
    if EXT.CONF_png ~= '' and reaper.file_exists(EXT.CONF_png) then
      -- make sure image not cached every frame
      if not DATA.last_CONF_png or (DATA.last_CONF_png  and DATA.last_CONF_png ~= EXT.CONF_png) or DATA.updXYWH == true  then 
        DATA.ImGui_Image = ImGui.CreateImage(EXT.CONF_png)
        DATA.ImGui_Image_w, DATA.ImGui_Image_h = ImGui.Image_GetSize(DATA.ImGui_Image) 
        minsize_wind = math.min(DATA.display_w,UI.calc_maintxt_h)
        minsize_img = math.min(DATA.ImGui_Image_w, DATA.ImGui_Image_h)
        DATA.ImGui_Image_scale = minsize_wind / minsize_img
        ImGui.Attach(ctx,  DATA.ImGui_Image)
      end  
      DATA.last_CONF_png = EXT.CONF_png
      
      if DATA.ImGui_Image then 
        local addscaling = EXT.CONF_png_scaling or 1 
        local imgw = DATA.ImGui_Image_w*DATA.ImGui_Image_scale*addscaling
        local imgh = DATA.ImGui_Image_h*DATA.ImGui_Image_scale*addscaling
        local_pos_x= 0.5*(DATA.display_w - imgw)
        local_pos_y=(UI.calc_maintxt_h-imgh)*0.5
        ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y )
        ImGui.Image(ctx, DATA.ImGui_Image, imgw, imgh, 0, 0, 1, 1, 0xFFFFFFFF, 0x00000000)
      end
    end
  
  -- txt 1
    UI.draw_setbuttonbackgtransparent() 
    if EXT.CONF_txt1 ~= '' then 
      ImGui.PushFont(ctx, DATA.font1)  
      txtw, txth = ImGui.CalcTextSize(ctx, EXT.CONF_txt1, nil, nil, false, -1.0)
      local_pos_x= 0.5*(DATA.display_w - txtw)
      local_pos_y=(UI.calc_maintxt_h-txth)*0.5
      ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y )
      ImGui.Text(ctx,EXT.CONF_txt1)
      ImGui.PopFont( ctx ) 
    end
    
  -- txt 2
    if EXT.CONF_txt2~= '' then 
      ImGui.PushFont(ctx, DATA.font2)  
      txtw, txth = ImGui.CalcTextSize(ctx, EXT.CONF_txt2, nil, nil, false, -1.0)
      local_pos_x= 0.5*(DATA.display_w - txtw)
      local_pos_y=UI.calc_maintxt_h + (UI.calc_maintxt2_h-txth)*0.5
      ImGui.SetCursorPos( ctx, local_pos_x, local_pos_y )
      ImGui.Text(ctx,EXT.CONF_txt2)
      ImGui.PopFont( ctx )
    end
    UI.draw_unsetbuttonstyle()
    
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col) 
    UI.MAIN_PushStyle('Col_Button',col, 0.5) 
    UI.MAIN_PushStyle('Col_ButtonActive',col, 1) 
    UI.MAIN_PushStyle('Col_ButtonHovered',col, 0.8)
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttonbackgtransparent() 
    UI.MAIN_PushStyle('Col_Button',0, 0) 
    UI.MAIN_PushStyle('Col_ButtonActive',0, 0) 
    UI.MAIN_PushStyle('Col_ButtonHovered',0, 0)
end
--------------------------------------------------------------------------------  
function UI.draw_unsetbuttonstyle() UI.MAIN_PopStyle(ctx, nil, 3)end
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
    DATA.updXYWH = true
  end
  if DATA.display_schedule_save and os.clock() - DATA.display_schedule_save > 0.3 then 
    EXT.viewport_posX = DATA.display_x
    EXT.viewport_posY = DATA.display_y
    EXT.viewport_posW = DATA.display_w
    EXT.viewport_posH = DATA.display_h
    EXT:save() 
    DATA.display_schedule_save = nil 
    DATA.updXYWH = true
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
-----------------------------------------------------------------------------------------
reaper.gmem_attach('mpl_notification_trig' )
reaper.set_action_options(3)
main()
  
  
  
  