-- @description Item ADSR
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @about Script for manipulating ADSR of selected items
-- @changelog
--    # fix spamming ext state




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
        
        preset_base64_user = '',
        update_presets = 1, -- grab presets ONCE from old version
        
        UI_compactmode =1,
        UI_appatchange = 0,
        
        -- global
        CONF_name = 'default',

        CONF_tve_attack = 0,
        CONF_tve_hold = 0,
        CONF_tve_decay = 0.5,
        CONF_tve_sustain = 0,
        CONF_tve_release = 0.5, 
        CONF_tve_attacktension = 0.5,
        CONF_tve_decaytension = 0.5,
        CONF_tve_releasetension = 0.5,
        
        CONF_tp_scale = 1,
        CONF_tp_attack = 0,
        CONF_tp_hold = 0,
        CONF_tp_decay = 0.5,
        CONF_tp_sustain = 0,
        CONF_tp_release = 0.5, 
        CONF_tp_attacktension = 0.5,
        CONF_tp_decaytension = 0.5,
        CONF_tp_releasetension = 0.5,
      }
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'MPL_ADSR',
        UI_name = 'Item ADSR', 
        upd = true, 
        preset_name = 'untitled', -- for inputtext
        presets_factory = {
          --['Align items to edit cursor'] = 'CkNPTkZfTkFNRT1BbGlnbiBpdGVtcyB0byBlZGl0IGN1cnNvcgpDT05GX2FjdF9hY3Rpb249MQpDT05GX2FjdF9hbGlnbmRpcj0xCkNPTkZfYWN0X2NhdGNocmVmdGltZXNlbD0wCkNPTkZfYWN0X2NhdGNoc3JjdGltZXNlbD0wCkNPTkZfYWN0X2luaXRhcHA9MApDT05GX2FjdF9pbml0Y2F0Y2hyZWY9MQpDT05GX2FjdF9pbml0Y2F0Y2hzcmM9MQpDT05GX2NvbnZlcnRub3Rlb252ZWwwdG9ub3Rlb2ZmPTAKQ09ORl9lbnZzdGVwcz0wCkNPTkZfZXhjbHdpdGhpbj0wCkNPTkZfaW5jbHdpdGhpbj0wCkNPTkZfaW5pdGF0bW91c2Vwb3M9MApDT05GX2l0ZXJhdGlvbmxpbT0zMDAwMApDT05GX29mZnNldD0wLjUKQ09ORl9yZWZfZWRpdGN1cj0xCkNPTkZfcmVmX2VudnBvaW50cz0wCkNPTkZfcmVmX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9yZWZfZ3JpZD0wCkNPTkZfcmVmX2dyaWRfc3c9MApDT05GX3JlZl9ncmlkX3ZhbD0wLjUKQ09ORl9yZWZfbWFya2VyPTAKQ09ORl9yZWZfbWlkaT0wCkNPTkZfcmVmX21pZGlfbXNnZmxhZz0xCkNPTkZfcmVmX21pZGlmbGFncz0xCkNPTkZfcmVmX3BhdHRlcm49MApDT05GX3JlZl9wYXR0ZXJuX2dlbnNyYz0xCkNPTkZfcmVmX3BhdHRlcm5fbGVuMj04CkNPTkZfcmVmX3BhdHRlcm5fbmFtZT1sYXN0X3RvdWNoZWQKQ09ORl9yZWZfc2VsaXRlbXM9MApDT05GX3JlZl9zZWxpdGVtc192YWx1ZT0wCkNPTkZfcmVmX3N0cm1hcmtlcnM9MApDT05GX3JlZl90aW1lbWFya2VyPTAKQ09ORl9zcmNfZW52cG9pbnRzPTAKQ09ORl9zcmNfZW52cG9pbnRzZmxhZz0xCkNPTkZfc3JjX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9zcmNfbWlkaT0wCkNPTkZfc3JjX21pZGlfbXNnZmxhZz01CkNPTkZfc3JjX21pZGlmbGFncz0xCkNPTkZfc3JjX3Bvc2l0aW9ucz0xCkNPTkZfc3JjX3NlbGl0ZW1zPTEKQ09ORl9zcmNfc2VsaXRlbXNmbGFnPTEKQ09ORl9zcmNfc3RybWFya2Vycz0w',
          },
        presets = {
          factory= {},
          user= {}, 
          },
          
        items = {},  
        
        CONF_tve_attack = 0,
        CONF_tve_hold = 0,
        CONF_tve_decay = 0.5,
        CONF_tve_sustain = 0,
        CONF_tve_release = 0,
        CONF_tve_attacktension = 0.5,
        CONF_tve_decaytension = 0.5,
        CONF_tve_releasetension = 0.5,
        
        CONF_tp_scale = 1,
        CONF_tp_attack = 0,
        CONF_tp_hold = 0,
        CONF_tp_decay = 0.5,
        CONF_tp_sustain = 0,
        CONF_tp_release = 0.5, 
        CONF_tp_attacktension = 0.5,
        CONF_tp_decaytension = 0.5,
        CONF_tp_releasetension = 0.5,
        
        }
        
        
-------------------------------------------------------------------------------- UI init variables
UI = {}
  
  UI.popups = {}
-- font  
  UI.font='Arial'
  UI.font1sz=15
  UI.font2sz=14
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
    UI.knob_resY = 150






function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
--------------------------------------------------------------------------------  
function UI.draw_plugin_handlelatchstate(t)  
  local paramval = DATA[t.param_key]
  
  -- trig
  --if  ImGui.IsItemActivated( ctx ) then 
  if  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then 
    DATA.latchstate = paramval 
    if t.appfunc_atclick then t.appfunc_atclick() end
    return 
  end
  
  if  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
    DATA.latchstate = paramval 
    if t.appfunc_atclickR then t.appfunc_atclickR() end
    return 
  end
  
  -- drag
  if  ImGui.IsItemActive( ctx ) then
    local x, y = ImGui.GetMouseDragDelta( ctx )
    local outval = DATA.latchstate - y/UI.knob_resY
    outval = math.max(0,math.min(outval,1))
    local fxGUID = t.fxGUID
    local dx, dy = ImGui.GetMouseDelta( ctx )
    if dy~=0 then
      DATA[t.param_key] = outval
      if t.appfunc_atdrag then t.appfunc_atdrag() end
     else
      if t.appfunc_atrelease then t.appfunc_atrelease() end
    end
  end
  
  --[[if  ImGui.IsItemDeactivated( ctx ) then
    if t.appfunc_atrelease then t.appfunc_atrelease() end
  end]]
  
  if ImGui.IsItemHovered( ctx, ImGui.HoveredFlags_None ) then
    local vertical, horizontal = ImGui.GetMouseWheel( ctx )
    if vertical ~= 0 then
      local mod = 1
      if ImGui.IsKeyDown( ctx, ImGui.Mod_Shift ) then mod = 10 end
      DATA[t.param_key] = VF_lim(DATA[t.param_key] + vertical*0.01*mod)
      if t.appfunc_atrelease then t.appfunc_atrelease() end
    end
  end
  
end

-------------------------------------------------------------------------------- 
function UI.draw_knob(t) 
  local curposx, curposy = ImGui.GetCursorScreenPos(ctx)
  local butid = '##knob'..t.knobGUID
  ImGui.Button( ctx, butid, t.w, t.h)
  local item_w, item_h = reaper.ImGui_GetItemRectSize( ctx )
  UI.draw_plugin_handlelatchstate(t)  
  
  local val = DATA[t.param_key]
  
  
  if not val then return end
  local draw_list = ImGui.GetForegroundDrawList(ctx)
  local roundingIn = 0
  local col_rgba = 0xF0F0F0FF
  
  local radius = math.floor(math.min(item_w, item_h )/2)
  local radius_draw = math.floor(0.9 * radius)
  local center_x = curposx + item_w/2--radius
  local center_y = curposy + item_h/2
  local ang_min = -220
  local ang_max = 40
  local ang_val = ang_min + math.floor((ang_max - ang_min)*val)
  local radiusshift_y = (radius_draw- radius)
  ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_max))
  ImGui.DrawList_PathStroke(draw_list, 0xF0F0F02F,  ImGui.DrawFlags_None, 2)
  ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_val+1))
  ImGui.DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2)
  
  local radius_draw2 = radius_draw-1
  local radius_draw3 = radius_draw-6
  ImGui.DrawList_PathClear(draw_list)
  ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw2 * math.cos(math.rad(ang_val)), center_y - radiusshift_y + radius_draw2 * math.sin(math.rad(ang_val)))
  ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw3 * math.cos(math.rad(ang_val)), center_y -radiusshift_y + radius_draw3 * math.sin(math.rad(ang_val)))
  ImGui.DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2)
  
  
  ImGui.SetCursorScreenPos(ctx, curposx, curposy)
  ImGui.Dummy(ctx,t.w,  t.h)
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
      if ImGui.BeginPopupModal(ctx, key, nil, ImGui.WindowFlags_AlwaysAutoResize|ImGui.ChildFlags_Border) then
      
        -- MB replika
        if mode == 0 then
          ImGui.Text(ctx, captions_csv)
          ImGui.Separator(ctx) 
        
          if ImGui.Button(ctx, 'OK', 0, 0) then 
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end
          
          --[[ImGui.SetItemDefaultFocus(ctx)
          ImGui.SameLine(ctx)
          if ImGui.Button(ctx, 'Cancel', 120, 0) then 
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end]]
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
  local h_min = 100
  -- window_flags
    local window_flags = ImGui.WindowFlags_None
    --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
    window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
    --window_flags = window_flags | ImGui.WindowFlags_MenuBar()
    --window_flags = window_flags | ImGui.WindowFlags_NoMove()
    window_flags = window_flags | ImGui.WindowFlags_NoResize
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
      UI.MAIN_PushStyle('StyleVar_Alpha',0.98)
      --UI.MAIN_PushStyle('StyleVar_DisabledAlpha,0.6 ) 
      UI.MAIN_PushStyle('Col_Border',UI.main_col, 0.3)
    -- colors
      --UI.MAIN_PushStyle('Col_BorderShadow(),0xFFFFFF, 1)
      UI.MAIN_PushStyle('Col_Button',UI.main_col, 0.3) 
      UI.MAIN_PushStyle('Col_ButtonActive',UI.main_col, 0.3) 
      UI.MAIN_PushStyle('Col_ButtonHovered',UI.but_hovered, 0.3)
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
      UI.MAIN_PushStyle('Col_WindowBg',UI.windowBg, 1)
    
  -- We specify a default position/size in case there's no data in the .ini file.
    local main_viewport = ImGui.GetMainViewport(ctx)
    local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
    ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
    --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    local fixedw = 410
    if EXT.UI_compactmode == 1 then
      ImGui.SetNextWindowSize(ctx, fixedw, 230, ImGui.Cond_Always)
     else
      ImGui.SetNextWindowSize(ctx, fixedw, 600, ImGui.Cond_Always)
    end
    
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
      UI.calc_childH = math.floor(DATA.display_h_region - UI.calc_yoffset*6 - UI.calc_itemH*2)/3
      UI.calc_mainbut = math.floor(DATA.display_w_region - UI.calc_xoffset*4)/3
      if EXT.CONF_act_appbuttoexecute ==1 then  
        UI.calc_mainbut = math.floor(DATA.display_w_region - UI.calc_xoffset*5)/4
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
    if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
  
    return open
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
function DATA:Apply_SetItemExtState()
  for GUID in pairs(DATA.items) do
    local t = DATA.items[GUID]
    local item = DATA.items_ptrs[GUID]
    if item then
      for key in pairs(DATA) do
        if key:match('CONF_') then
          GetSetMediaItemInfo_String( item, 'P_EXT:'..key, DATA[key], true )
        end
      end
    end
  end
end
-------------------------------------------------------------------------------- 
function DATA:CollectData() 
  DATA.items = {}
  local ex
  local cnt = CountMediaItems( -1 )
  for itemidx= 1, cnt do
    local item = GetMediaItem( -1, itemidx-1 )
    if IsMediaItemSelected( item ) then
      local retval, GUID = reaper.GetSetMediaItemInfo_String( item, 'GUID', '', false )
      DATA.items[GUID] = {}
      
      for key in pairs(DATA) do
        if key:match('CONF_') then
          local retval, val = reaper.GetSetMediaItemInfo_String( item, 'P_EXT:'..key, '', false )
          DATA.items[GUID][key] = tonumber(val) 
          if not ex and DATA.items[GUID][key] then DATA[key]= DATA.items[GUID][key] end -- port selected item settings to script values 
        end
      end
      
      ex = true
    end
  end
  DATA:Prepare_CachePointers()
end
-------------------------------------------------------------------------------- 
function DATA:CollectData_Always()

end
-------------------------------------------------------------------------------- 
function UI.MAINloop() 
  DATA.clock = os.clock() 
  DATA:handleProjUpdates()
  
  if DATA.upd == true then  DATA:CollectData()  end 
  DATA.upd = false
  DATA:CollectData_Always()
  -- draw UI
  UI.open = UI.MAIN_draw(true) 
  UI.MAIN_shortcuts()
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
-----------------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------  
function main() 
  EXT_defaults = VF_CopyTable(EXT)
  EXT:load()  
  DATA.PRESET_GetExtStatePresets()
  UI.MAIN() 
end
  -----------------------------------------------------------------------------------------    -- http://lua-users.org/wiki/SaveTableToFile
  function table.exportstring( s ) return string.format("%q", s) end
  
  --// The Save Function
  function table.save(  tbl )
  local outstr = ''
    local charS,charE = "   ","\n"
  
    -- initiate variables for save procedure
    local tables,lookup = { tbl },{ [tbl] = 1 }
    outstr = outstr..'\n'..( "return {"..charE )
  
    for idx,t in ipairs( tables ) do
       outstr = outstr..'\n'..( "-- Table: {"..idx.."}"..charE )
       outstr = outstr..'\n'..( "{"..charE )
       local thandled = {}
  
       for i,v in ipairs( t ) do
          thandled[i] = true
          local stype = type( v )
          -- only handle value
          if stype == "table" then
             if not lookup[v] then
                table.insert( tables, v )
                lookup[v] = #tables
             end
             outstr = outstr..'\n'..( charS.."{"..lookup[v].."},"..charE )
          elseif stype == "string" then
             outstr = outstr..'\n'..(  charS..table.exportstring( v )..","..charE )
          elseif stype == "number" then
             outstr = outstr..'\n'..(  charS..tostring( v )..","..charE )
          end
       end
  
       for i,v in pairs( t ) do
          -- escape handled values
          if (not thandled[i]) then
          
             local str = ""
             local stype = type( i )
             -- handle index
             if stype == "table" then
                if not lookup[i] then
                   table.insert( tables,i )
                   lookup[i] = #tables
                end
                str = charS.."[{"..lookup[i].."}]="
             elseif stype == "string" then
                str = charS.."["..table.exportstring( i ).."]="
             elseif stype == "number" then
                str = charS.."["..tostring( i ).."]="
             end
          
             if str ~= "" then
                stype = type( v )
                -- handle value
                if stype == "table" then
                   if not lookup[v] then
                      table.insert( tables,v )
                      lookup[v] = #tables
                   end
                   outstr = outstr..'\n'..( str.."{"..lookup[v].."},"..charE )
                elseif stype == "string" then
                   outstr = outstr..'\n'..( str..table.exportstring( v )..","..charE )
                elseif stype == "number" then
                   outstr = outstr..'\n'..( str..tostring( v )..","..charE )
                end
             end
          end
       end
       outstr = outstr..'\n'..( "},"..charE )
    end
    outstr = outstr..'\n'..( "}" )
    return outstr
  end
  
  --// The Load Function
  function table.load( str )
  if str == '' then return end
    local ftables,err = load( str )
    if err then return _,err end
    local tables = ftables()
    for idx = 1,#tables do
       local tolinki = {}
       for i,v in pairs( tables[idx] ) do
          if type( v ) == "table" then
             tables[idx][i] = tables[v[1]]
          end
          if type( i ) == "table" and tables[i[1]] then
             table.insert( tolinki,{ i,tables[i[1]] } )
          end
       end
       -- link indices
       for _,v in ipairs( tolinki ) do
          tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
       end
    end
    return tables[1]
  end

--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col) 
    UI.MAIN_PushStyle('Col_Button',col, 0.5) 
    UI.MAIN_PushStyle('Col_ButtonActive',col, 1) 
    UI.MAIN_PushStyle('Col_ButtonHovered',col, 0.8)
end
--------------------------------------------------------------------- 
function DATA.PRESET_GetExtStatePresets()
  DATA.presets.factory = DATA.presets_factory
  
  local preset_base64_user = EXT.preset_base64_user
  if preset_base64_user:match('{')== nil and preset_base64_user~= '' then preset_base64_user = DATA.PRESET_decBase64(preset_base64_user) end
  DATA.presets.user = table.load(preset_base64_user) or {}
  
  -- ported from old version
  if EXT.update_presets == 1 then
    local t = {}
    for id_out=1, 32 do
      local str = GetExtState( DATA.ES_key, 'PRESET'..id_out)
      local str_dec = DATA.PRESET_decBase64(str)
      if str_dec== '' then goto nextpres end
      local tid = #t+1
      t[tid] = {str=str}
      for line in str_dec:gmatch('[^\r\n]+') do
        local key,value = line:gsub('[%{}]',''):match('(.-)=(.*)') 
        if key and value then
          t[tid][key]= tonumber(value) or value
        end
      end   
      local name = t[tid].CONF_NAME
      test = t[tid]
      DATA.presets.user[name] = VF_CopyTable(t[tid])
      ::nextpres::
    end
    EXT.update_presets = 0
    EXT:save()
  end
end
--------------------------------------------------------------------------------  
function UI.draw_plugin_handlelatchstate(t)  
  local paramval = DATA[t.param_key]
  
  -- trig
  --if  ImGui.IsItemActivated( ctx ) then 
  if  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then 
    DATA.latchstate = paramval 
    if t.appfunc_atclick then t.appfunc_atclick() end
    return 
  end
  
  if  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
    DATA.latchstate = paramval 
    if t.appfunc_atclickR then t.appfunc_atclickR() end
    return 
  end
  
  -- drag
  if  ImGui.IsItemActive( ctx ) then
    local x, y = ImGui.GetMouseDragDelta( ctx )
    local outval = DATA.latchstate - y/UI.knob_resY
    outval = math.max(0,math.min(outval,1))
    local fxGUID = t.fxGUID
    local dx, dy = ImGui.GetMouseDelta( ctx )
    if dy~=0 then
      DATA[t.param_key] = outval
      if t.appfunc_atdrag then t.appfunc_atdrag() end
    end
  end
  
  if  ImGui.IsItemDeactivated( ctx ) then
    if t.appfunc_atrelease then t.appfunc_atrelease() end
  end
  
  if ImGui.IsItemHovered( ctx, ImGui.HoveredFlags_None ) then
    local vertical, horizontal = ImGui.GetMouseWheel( ctx )
    if vertical ~= 0 then
      local mod = 1
      if ImGui.IsKeyDown( ctx, ImGui.Mod_Shift ) then mod = 10 end
      DATA[t.param_key] = VF_lim(DATA[t.param_key] + vertical*0.01*mod)
      if t.appfunc_atrelease then t.appfunc_atrelease() end
    end
  end
  
end
-------------------------------------------------------------------------------- 
function UI.draw_knob(t) 
  local curposx, curposy = ImGui.GetCursorScreenPos(ctx)
  local butid = '##knob'..t.knobGUID
  ImGui.Button( ctx, butid, t.w, t.h)
  local item_w, item_h = reaper.ImGui_GetItemRectSize( ctx )
  UI.draw_plugin_handlelatchstate(t)  
  
  local val = DATA[t.param_key]
  
  
  if not val then return end
  local draw_list = ImGui.GetWindowDrawList(ctx)
  local roundingIn = 0
  local col_rgba = 0xF0F0F0FF
  
  local radius = math.floor(math.min(item_w, item_h )/2)
  local radius_draw = math.floor(0.9 * radius)
  local center_x = curposx + item_w/2--radius
  local center_y = curposy + item_h/2
  local ang_min = -220
  local ang_max = 40
  local ang_val = ang_min + math.floor((ang_max - ang_min)*val)
  local radiusshift_y = (radius_draw- radius)
  
  -- arc
    ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_max))
    ImGui.DrawList_PathStroke(draw_list, 0xF0F0F02F,  ImGui.DrawFlags_None, 2)
  -- val     
    if val ~= 0 then
      ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_val+1))
      ImGui.DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2)
    end 
  -- handle
    local radius_draw2 = radius_draw-1
    local radius_draw3 = radius_draw-6
    ImGui.DrawList_PathClear(draw_list)
    ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw2 * math.cos(math.rad(ang_val)), center_y - radiusshift_y + radius_draw2 * math.sin(math.rad(ang_val)))
    ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw3 * math.cos(math.rad(ang_val)), center_y -radiusshift_y + radius_draw3 * math.sin(math.rad(ang_val)))
    ImGui.DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2)
    
  -- val
    ImGui.PushFont(ctx, DATA.font3) 
    if t.val_format then 
      ImGui.SetCursorScreenPos(ctx, curposx, curposy +  t.h + 2 )
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,2,2) 
      ImGui.Button( ctx, t.val_format, t.w, 20)
      ImGui.PopStyleVar(ctx) 
    end
    ImGui.PopFont(ctx)
  
  if t.txt then 
    local txtsz = 10
    ImGui.SetCursorScreenPos(ctx, curposx + item_w/2-txtsz/2, curposy+item_h/2 -txtsz/2 )
    ImGui.Text( ctx, t.txt)
  end
  
  ImGui.SetCursorScreenPos(ctx, curposx, curposy)
  ImGui.Dummy(ctx,t.w,  t.h)
end
-------------------------------------------------------------------------------- 
function UI.MAIN_shortcuts()
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then 
    for key in pairs(UI.popups) do UI.popups[key].draw = false end
    ImGui.CloseCurrentPopup( ctx ) 
  end
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_Space,false )  then  reaper.Main_OnCommand(40044,0) end
end
--------------------------------------------------------------------------------  
function _Format_knob2conf(val, mode_str) 
  if not mode_str then return val end
  if mode_str == 'attack' then
    local out = math.floor(10000*(math.exp(val^4)-1))/10
    if out > 10 then out = math.floor(1000*(math.exp(val^4)-1)) end
    return out..'ms',out/1000
   elseif mode_str == 'decay' then
    local out = math.floor(10000*(math.exp(val^2)-1))/10
    if out > 10 then out = math.floor(1000*(math.exp(val^2)-1)) end
    return out..'ms',out/1000
   elseif mode_str == 'sustain' then
     local out = math.floor(100*WDL_VAL2DB(val^4))/100
     return out..'dB',out
  end
end
--------------------------------------------------------------------------------  
function _Format_conf2knob(val,mode_str) 
  if type(val)=='string'then 
    val = val:match('[%d%.%-]+')
    if val then val = tonumber(val) end
  end 
  
  if mode_str == 'attack' then
    return math.sqrt(math.sqrt((math.log(1 + (val / 1000)))))
   elseif mode_str == 'decay' then
    return math.sqrt((math.log(1 + (val / 1000))))
   elseif mode_str == 'sustain' then
    return math.sqrt(math.sqrt(WDL_DB2VAL(val)))
  end
  
end
------------------------------------------------------------------------------------------------------
function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
--function dBFromVal(val) if val < 0.5 then return 20*math.log(val*2, 10) else return (val*12-6) end end
------------------------------------------------------------------------------------------------------
function WDL_VAL2DB(x, reduce)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  if not x or x < 0.0000000298023223876953125 then return -150.0 end
  local v=math.log(x)*8.6858896380650365530225783783321
  if v<-150.0 then return -150.0 else 
    if reduce then 
      return string.format('%.2f', v)
     else 
      return v 
    end
  end
end
------------------------------------------------------------------------------------------------------
function VF_lim(val, min,max) --local min,max 
  if not min or not max then min, max = 0,1 end 
  return math.max(min,  math.min(val, max) ) 
end
--------------------------------------------------------------------------------  
function UI.draw_tab_pitch()  
  -- CONF_tp_attack
  UI.draw_knob({
    knobGUID = 'CONF_tp_attack',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH*2.5,
    param_key = 'CONF_tp_attack',
    txt = 'A',
    val_format = _Format_knob2conf(DATA.CONF_tp_attack, 'attack'),
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atclickR = function() 
      UI.popups['Set value'] = {
        trig = true,
        captions_csv = 'New value',
        func_getval = function() return _Format_knob2conf(DATA.CONF_tp_attack, 'attack') end, 
        func_setval = function(retval, retvals_csv) 
          if retvals_csv then
            local sec = VF_lim(_Format_conf2knob(retvals_csv, 'attack') )
            DATA.CONF_tp_attack = sec
            EXT.CONF_CONF_tp_attack = sec
            EXT:save()
            DATA:Apply()
          end
        end
        }
    end,
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })
  
  ImGui.SameLine(ctx)
  
  -- CONF_tp_decay
  UI.draw_knob({
    knobGUID = 'CONF_tp_hold',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH*2.5,
    param_key = 'CONF_tp_hold',
    txt = 'H',
    val_format = _Format_knob2conf(DATA.CONF_tp_hold, 'decay'),
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atclickR = function() 
      UI.popups['Set value'] = {
        trig = true,
        captions_csv = 'New value',
        func_getval = function() return _Format_knob2conf(DATA.CONF_tp_hold, 'decay') end, 
        func_setval = function(retval, retvals_csv) 
          if retvals_csv then
            local sec = VF_lim(_Format_conf2knob(retvals_csv, 'decay') )
            DATA.CONF_tp_hold = sec
            EXT.CONF_tp_hold = sec
            EXT:save()
            DATA:Apply() 
          end
        end
        }
    end,
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })
  
  ImGui.SameLine(ctx)
  
  -- CONF_tp_decay
  UI.draw_knob({
    knobGUID = 'CONF_tp_decay',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH*2.5,
    param_key = 'CONF_tp_decay',
    txt = 'D',
    val_format = _Format_knob2conf(DATA.CONF_tp_decay, 'decay'),
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atclickR = function() 
      UI.popups['Set value'] = {
        trig = true,
        captions_csv = 'New value',
        func_getval = function() return _Format_knob2conf(DATA.CONF_tp_decay, 'decay') end, 
        func_setval = function(retval, retvals_csv) 
          if retvals_csv then
            local sec = VF_lim(_Format_conf2knob(retvals_csv, 'decay') )
            DATA.CONF_tp_decay = sec
            EXT.CONF_tp_decay = sec
            EXT:save()
            DATA:Apply() 
          end
        end
        }
    end,
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })
  
  
  ImGui.SameLine(ctx)
  
  -- CONF_tp_sustain
  UI.draw_knob({
    knobGUID = 'CONF_tp_sustain',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH*2.5,
    param_key = 'CONF_tp_sustain',
    txt = 'S',
    --val_format = _Format_knob2conf(DATA.CONF_tp_sustain, 'sustain'),
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atclickR = function() 
      UI.popups['Set value'] = {
        trig = true,
        captions_csv = 'New value',
        func_getval = function() return _Format_knob2conf(DATA.CONF_tp_sustain, 'sustain') end, 
        func_setval = function(retval, retvals_csv) 
          if retvals_csv then
            local sec = VF_lim(_Format_conf2knob(retvals_csv, 'sustain') )
            DATA.CONF_tp_sustain = sec
            EXT.CONF_tp_sustain = sec
            EXT:save()
            DATA:Apply() 
          end
        end
        }
    end,
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })

  ImGui.SameLine(ctx) 
  
  -- CONF_tp_release
  UI.draw_knob({
    knobGUID = 'CONF_tp_release',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH*2.5,
    param_key = 'CONF_tp_release',
    txt = 'R',
    val_format = _Format_knob2conf(DATA.CONF_tp_release, 'decay'),
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atclickR = function() 
      UI.popups['Set value'] = {
        trig = true,
        captions_csv = 'New value',
        func_getval = function() return _Format_knob2conf(DATA.CONF_tp_release, 'decay') end, 
        func_setval = function(retval, retvals_csv) 
          if retvals_csv then
            local sec = VF_lim(_Format_conf2knob(retvals_csv, 'decay') )
            DATA.CONF_tp_release = sec
            EXT.CONF_tp_release = sec
            EXT:save()
            DATA:Apply() 
          end
        end
        }
    end,
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })

  -- attack tension
  ImGui.Dummy(ctx,10,UI.calc_itemH-5)
  --[[UI.draw_knob({
    knobGUID = 'CONF_tp_attacktension',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH,
    param_key = 'CONF_tp_attacktension',
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })

  ImGui.SameLine(ctx)]] 
  
  ImGui.Dummy(ctx,UI.calc_itemH*2,UI.calc_itemH-5)
  ImGui.SameLine(ctx)
  -- decay tension
  UI.draw_knob({
    knobGUID = 'CONF_tp_scale',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH,
    param_key = 'CONF_tp_scale',
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })
  
  --ImGui.SameLine(ctx) 
  --[[ decay tension
  UI.draw_knob({
    knobGUID = 'CONF_tp_decaytension',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH,
    param_key = 'CONF_tp_decaytension',
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })
  ImGui.Dummy(ctx,UI.calc_itemH*2,UI.calc_itemH-5)
  
  
  ImGui.SameLine(ctx) 
  -- release tension
  ImGui.Dummy(ctx,UI.calc_itemH*2,UI.calc_itemH-5)
  ImGui.SameLine(ctx) 
  UI.draw_knob({
    knobGUID = 'CONF_tp_releasetension',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH,
    param_key = 'CONF_tp_releasetension',
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })
  ]]
end--------------------------------------------------------------------------------  
function UI.draw_tab_volume()  
  -- CONF_tve_attack
  UI.draw_knob({
    knobGUID = 'CONF_tve_attack',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH*2.5,
    param_key = 'CONF_tve_attack',
    txt = 'A',
    val_format = _Format_knob2conf(DATA.CONF_tve_attack, 'attack'),
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atclickR = function() 
      UI.popups['Set value'] = {
        trig = true,
        captions_csv = 'New value',
        func_getval = function() return _Format_knob2conf(DATA.CONF_tve_attack, 'attack') end, 
        func_setval = function(retval, retvals_csv) 
          if retvals_csv then
            local sec = VF_lim(_Format_conf2knob(retvals_csv, 'attack') )
            DATA.CONF_tve_attack = sec
            EXT.CONF_CONF_tve_attack = sec
            EXT:save()
            DATA:Apply()
          end
        end
        }
    end,
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })
  
  ImGui.SameLine(ctx)
  
  -- CONF_tve_decay
  UI.draw_knob({
    knobGUID = 'CONF_tve_hold',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH*2.5,
    param_key = 'CONF_tve_hold',
    txt = 'H',
    val_format = _Format_knob2conf(DATA.CONF_tve_hold, 'decay'),
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atclickR = function() 
      UI.popups['Set value'] = {
        trig = true,
        captions_csv = 'New value',
        func_getval = function() return _Format_knob2conf(DATA.CONF_tve_hold, 'decay') end, 
        func_setval = function(retval, retvals_csv) 
          if retvals_csv then
            local sec = VF_lim(_Format_conf2knob(retvals_csv, 'decay') )
            DATA.CONF_tve_hold = sec
            EXT.CONF_tve_hold = sec
            EXT:save()
            DATA:Apply() 
          end
        end
        }
    end,
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })
  
  ImGui.SameLine(ctx)
  
  -- CONF_tve_decay
  UI.draw_knob({
    knobGUID = 'CONF_tve_decay',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH*2.5,
    param_key = 'CONF_tve_decay',
    txt = 'D',
    val_format = _Format_knob2conf(DATA.CONF_tve_decay, 'decay'),
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atclickR = function() 
      UI.popups['Set value'] = {
        trig = true,
        captions_csv = 'New value',
        func_getval = function() return _Format_knob2conf(DATA.CONF_tve_decay, 'decay') end, 
        func_setval = function(retval, retvals_csv) 
          if retvals_csv then
            local sec = VF_lim(_Format_conf2knob(retvals_csv, 'decay') )
            DATA.CONF_tve_decay = sec
            EXT.CONF_tve_decay = sec
            EXT:save()
            DATA:Apply() 
          end
        end
        }
    end,
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })
  
  
  ImGui.SameLine(ctx)
  
  -- CONF_tve_sustain
  UI.draw_knob({
    knobGUID = 'CONF_tve_sustain',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH*2.5,
    param_key = 'CONF_tve_sustain',
    txt = 'S',
    val_format = _Format_knob2conf(DATA.CONF_tve_sustain, 'sustain'),
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atclickR = function() 
      UI.popups['Set value'] = {
        trig = true,
        captions_csv = 'New value',
        func_getval = function() return _Format_knob2conf(DATA.CONF_tve_sustain, 'sustain') end, 
        func_setval = function(retval, retvals_csv) 
          if retvals_csv then
            local sec = VF_lim(_Format_conf2knob(retvals_csv, 'sustain') )
            DATA.CONF_tve_sustain = sec
            EXT.CONF_tve_sustain = sec
            EXT:save()
            DATA:Apply() 
          end
        end
        }
    end,
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })

  ImGui.SameLine(ctx) 
  
  -- CONF_tve_release
  UI.draw_knob({
    knobGUID = 'CONF_tve_release',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH*2.5,
    param_key = 'CONF_tve_release',
    txt = 'R',
    val_format = _Format_knob2conf(DATA.CONF_tve_release, 'decay'),
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atclickR = function() 
      UI.popups['Set value'] = {
        trig = true,
        captions_csv = 'New value',
        func_getval = function() return _Format_knob2conf(DATA.CONF_tve_release, 'decay') end, 
        func_setval = function(retval, retvals_csv) 
          if retvals_csv then
            local sec = VF_lim(_Format_conf2knob(retvals_csv, 'decay') )
            DATA.CONF_tve_release = sec
            EXT.CONF_tve_release = sec
            EXT:save()
            DATA:Apply() 
          end
        end
        }
    end,
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })

  -- attack tension
  ImGui.Dummy(ctx,10,UI.calc_itemH-5)
  UI.draw_knob({
    knobGUID = 'CONF_tve_attacktension',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH,
    param_key = 'CONF_tve_attacktension',
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })
  
  ImGui.SameLine(ctx) 
  -- decay tension
  ImGui.Dummy(ctx,UI.calc_itemH*2,UI.calc_itemH-5)
  ImGui.SameLine(ctx) 
  UI.draw_knob({
    knobGUID = 'CONF_tve_decaytension',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH,
    param_key = 'CONF_tve_decaytension',
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })
  
  
  ImGui.SameLine(ctx) 
  -- release tension
  ImGui.Dummy(ctx,UI.calc_itemH*2,UI.calc_itemH-5)
  ImGui.SameLine(ctx) 
  UI.draw_knob({
    knobGUID = 'CONF_tve_releasetension',
    w =UI.calc_itemH*2, 
    h = UI.calc_itemH,
    param_key = 'CONF_tve_releasetension',
    appfunc_atclick = function() DATA:Prepare_ClearTakeEnv() end, 
    appfunc_atdrag= function() DATA:Apply() end,
    appfunc_atrelease= function() EXT:save() end,
  })
  
end
--------------------------------------------------------------------------------  
function UI.draw()  
  UI.draw_preset() 
  
  --ImGui.SameLine(ctx)
  
  -- tabs
  if ImGui.BeginTabBar(ctx, 'tabs', ImGui.TabBarFlags_None) then 
    if ImGui.BeginTabItem(ctx, 'Pitch') then UI.draw_tab_pitch() ImGui.EndTabItem(ctx) end
    if ImGui.BeginTabItem(ctx, 'Volume') then UI.draw_tab_volume() ImGui.EndTabItem(ctx) end
    ImGui.EndTabBar(ctx) 
  end
   
  
  
  
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
  
end
--------------------------------------------------------------------------------  
function DATA:Prepare_CachePointers()
  DATA.items_ptrs = {}
  local cnt = CountMediaItems( -1 )
  for itemidx= 1, cnt do
    local item = GetMediaItem( -1, itemidx-1 )
    if IsMediaItemSelected( item ) then
      local retval, GUID = reaper.GetSetMediaItemInfo_String( item, 'GUID', '', false )
      DATA.items_ptrs[GUID] = item
    end
  end
end

--------------------------------------------------------------------------------  
function DATA:Prepare_ClearTakeEnv()
  local app
  for GUID in pairs(DATA.items) do
    local t = DATA.items[GUID]
    local it = DATA.items_ptrs[GUID] 
    if it then
      local take = GetActiveTake(it)
      
      if (take and not reaper.TakeIsMIDI(take)) then 
        env = reaper.GetTakeEnvelopeByName( take, 'Volume' )
        if env then 
          reaper.SetMediaItemSelected( it, false) 
          reaper.UpdateItemInProject(it)
         else
          app = true
        end
      end
    end
  end
  
  if app == true then reaper.Main_OnCommand(40693,0) end -- Take: Toggle take volume envelope
  for GUID in pairs(DATA.items) do
    local t = DATA.items[GUID]
    local it = DATA.items_ptrs[GUID] 
    if it 
    then SetMediaItemSelected( it, true) end
  end
  
  
  --pitch
  local app
  
  
  for GUID in pairs(DATA.items) do
    local t = DATA.items[GUID]
    local it = DATA.items_ptrs[GUID] 
    if it then
      local take = GetActiveTake(it)
      
      if (take and not reaper.TakeIsMIDI(take)) then 
        env = reaper.GetTakeEnvelopeByName( take, 'Pitch' )
        if env then 
          reaper.SetMediaItemSelected( it, false) 
          reaper.UpdateItemInProject(it)
         else
          app = true
        end
      end
    end
  end
  
  if app == true then reaper.Main_OnCommand(41612,0) end -- Take: Toggle take pitch envelope
  for GUID in pairs(DATA.items) do
    local t = DATA.items[GUID]
    local it = DATA.items_ptrs[GUID] 
    if it 
    then SetMediaItemSelected( it, true) end
  end
end
--------------------------------------------------------------------------------  
function DATA:Apply_GenerateSM(it) 
    local mult = 1
  --validate 
    if not it then return end
    local take = GetActiveTake(it)
    if not (take and not TakeIsMIDI(take)) then return end
  -- env
    local env = reaper.GetTakeEnvelopeByName( take, 'Pitch' )
    
  -- clear
    DeleteTakeStretchMarkers( take, 0, GetTakeNumStretchMarkers( take ) ) 
    local D_STARTOFFS = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
  
  -- add points 
    local max_mult = 1
    local val_format, val_sec = _Format_knob2conf(DATA.CONF_tp_attack, 'attack')
    local attack_time = math.max(10^-13, val_sec)
    local val_format, val_sec = _Format_knob2conf(DATA.CONF_tp_hold, 'decay')
    local hold_time = val_sec
    local val_format, val_sec = _Format_knob2conf(DATA.CONF_tp_decay, 'decay')
    local decay_time = math.max(10^-13, val_sec)
    local val_format, val_sec = _Format_knob2conf(DATA.CONF_tp_release, 'decay')
    local release_time = val_sec
    -- start
    SetTakeStretchMarker( take, -1,0, D_STARTOFFS) 
    -- attack
    local attackoffst = D_STARTOFFS + attack_time * (1+max_mult * DATA.CONF_tp_scale)
    SetTakeStretchMarker( take, -1, attack_time, attackoffst*mult)
    local slope = 0.5*DATA.CONF_tp_scale
    SetTakeStretchMarkerSlope( take, 0, slope) -- attack start 
    
    -- get attack dest rate -- https://forum.cockos.com/showpost.php?p=2400177&postcount=13
      retval, pos_a, srcpos_a = reaper.GetTakeStretchMarker( take, 0)
      retval, pos_b, srcpos_b = reaper.GetTakeStretchMarker( take, 1 )
      len_init = srcpos_b - srcpos_a -- length between two SM source positions
      len_after = pos_b - pos_a -- Length between two SM actual item positions
      right_rate_decay = len_init / len_after * (1+slope)
      left_rate_decay = (len_init / len_after) * (1-slope)
    
    -- hold
      local holdoffst = attackoffst+hold_time*right_rate_decay
      SetTakeStretchMarker( take, -1,attack_time+hold_time, holdoffst*mult)
    
    -- decay
      pos_a = attack_time+hold_time
      srcpos_a = holdoffst
      pos_b = attack_time+hold_time+decay_time 
      len_after = pos_b - pos_a -- Length between two SM actual item positions
      len_init =  ((len_after * (1+right_rate_decay*DATA.CONF_tp_sustain-DATA.CONF_tp_sustain) ) + (right_rate_decay * len_after)) / 2
      srcpos_decay = srcpos_a + len_init
      slope = 1 - (right_rate_decay / (len_init / len_after))
      right_rate_sus = len_init / len_after * (1+slope)
      decayID = SetTakeStretchMarker( take, -1,attack_time+hold_time+decay_time, srcpos_decay*mult)
      SetTakeStretchMarkerSlope( take, decayID-1,slope)
      
    -- release
      pos_a = attack_time+hold_time+decay_time
      srcpos_a = srcpos_decay
      pos_b = attack_time+hold_time+decay_time +release_time
      len_init = srcpos_b - srcpos_a -- length between two SM source positions
      len_after = pos_b - pos_a -- Length between two SM actual item positions
      len_init = ((1+right_rate_sus)*len_after) / 2 
      srcpos_rel = srcpos_a + len_init
      slope = 1 - (right_rate_sus / (len_init / len_after))
      releaseID = SetTakeStretchMarker( take, -1,attack_time+hold_time+decay_time+release_time, srcpos_rel*mult)
      SetTakeStretchMarkerSlope( take, releaseID-1,slope)
end
--------------------------------------------------------------------------------  
function DATA:Apply_GenerateEnvelope(it) 
  DATA:Apply_GenerateEnvelope_volume(it) 
  DATA:Apply_GenerateEnvelope_pitch(it) 
end
--------------------------------------------------------------------------------  
function DATA:Apply_GenerateEnvelope_pitch(it) 
  --validate 
    if not it then return end
    local take = GetActiveTake(it)
    if not (take and not TakeIsMIDI(take)) then return end
  -- env
    local env = reaper.GetTakeEnvelopeByName( take, 'Pitch' )
    GetSetEnvelopeInfo_String( env, 'ACTIVE', '0', 1 )
    GetSetEnvelopeInfo_String( env, 'VISIBLE', '1', 1 )
    reaper.DeleteEnvelopePointRange( env, 0, math.huge ) 
    local scaling_mode = GetEnvelopeScalingMode( env )
    
  -- starting point
    time = 0
    value = 0
    shape = 5
    tension = DATA.CONF_tp_attacktension*2-1
    InsertEnvelopePoint( env, time, value, shape, tension, 0, true )
      
  -- attack
    local val_format, val_sec = _Format_knob2conf(DATA.CONF_tp_attack, 'attack')
    local attack_time = math.max(10^-13, val_sec)
    value = DATA.CONF_tp_scale
    shape = 0
    tension = 0
    InsertEnvelopePoint( env, attack_time, value, shape, tension, 0, true )
  
  -- hold
    local val_format, val_sec = _Format_knob2conf(DATA.CONF_tp_hold, 'decay')
    local hold_time = val_sec
    value = DATA.CONF_tp_scale
    shape = 5
    tension = DATA.CONF_tp_decaytension*2-1
    InsertEnvelopePoint( env, attack_time + hold_time, value, shape, tension, 0, true )
    
  -- decay
    local val_format, val_sec = _Format_knob2conf(DATA.CONF_tp_decay, 'decay')
    local decay_time = math.max(10^-13, val_sec)
    value = DATA.CONF_tp_sustain*DATA.CONF_tp_scale
    shape = 5
    tension = DATA.CONF_tp_releasetension*2-1
    InsertEnvelopePoint( env, attack_time + hold_time + decay_time, value, shape, tension, 0, true )

  -- release
    local val_format, val_sec = _Format_knob2conf(DATA.CONF_tp_release, 'decay')
    local release_time = val_sec
    value = ScaleToEnvelopeMode( scaling_mode, 0 )
    shape = 0
    tension = 0
    InsertEnvelopePoint( env, attack_time + hold_time + decay_time + release_time, value, shape, tension, 0, true )
    
    Envelope_SortPoints( env )
end

--------------------------------------------------------------------------------  
function DATA:Apply_GenerateEnvelope_volume(it) 
  --validate 
    if not it then return end
    local take = GetActiveTake(it)
    if not (take and not TakeIsMIDI(take)) then return end
  -- env
    local env = reaper.GetTakeEnvelopeByName( take, 'Volume' )
    GetSetEnvelopeInfo_String( env, 'ACTIVE', '1', 1 )
    GetSetEnvelopeInfo_String( env, 'VISIBLE', '1', 1 )
    reaper.DeleteEnvelopePointRange( env, 0, math.huge ) 
    local scaling_mode = GetEnvelopeScalingMode( env )
    
  -- starting point
    time = 0
    value = 0
    shape = 5
    tension = DATA.CONF_tve_attacktension*2-1
    InsertEnvelopePoint( env, time, value, shape, tension, 0, true )
      
  -- attack
    local val_format, val_sec = _Format_knob2conf(DATA.CONF_tve_attack, 'attack')
    local attack_time = math.max(10^-13, val_sec)
    value = ScaleToEnvelopeMode( scaling_mode, 1 )
    shape = 0
    tension = 0
    InsertEnvelopePoint( env, attack_time, value, shape, tension, 0, true )
  
  -- hold
    local val_format, val_sec = _Format_knob2conf(DATA.CONF_tve_hold, 'decay')
    local hold_time = val_sec
    value = ScaleToEnvelopeMode( scaling_mode, 1 )
    shape = 5
    tension = DATA.CONF_tve_decaytension*2-1
    InsertEnvelopePoint( env, attack_time + hold_time, value, shape, tension, 0, true )
    
  -- decay
    local val_format, val_sec = _Format_knob2conf(DATA.CONF_tve_decay, 'decay')
    local _, susdB = _Format_knob2conf(DATA.CONF_tve_sustain, 'sustain')
    local decay_time = math.max(10^-13, val_sec)
    local normval = WDL_DB2VAL(susdB)
    value = ScaleToEnvelopeMode( scaling_mode, normval )
    shape = 5
    tension = DATA.CONF_tve_releasetension*2-1
    InsertEnvelopePoint( env, attack_time + hold_time + decay_time, value, shape, tension, 0, true )

  -- release
    local val_format, val_sec = _Format_knob2conf(DATA.CONF_tve_release, 'decay')
    local release_time = math.max(10^-13, val_sec)
    value = ScaleToEnvelopeMode( scaling_mode, 0 )
    shape = 0
    tension = 0
    InsertEnvelopePoint( env, attack_time + hold_time + decay_time + release_time, value, shape, tension, 0, true )
    
    Envelope_SortPoints( env )
end
--------------------------------------------------------------------------------  
function DATA:Apply() 
  for GUID in pairs(DATA.items) do
    local t = DATA.items[GUID]
    local it = DATA.items_ptrs[GUID]
    if it then 
      DATA:Apply_GenerateEnvelope(it) 
      DATA:Apply_GenerateSM(it) 
    end
  end
  
  DATA:Apply_SetItemExtState()
end
--------------------------------------------------------------------------------  
function UI.draw_flow_COMBO(t)
  local trig_action
  local preview_value
  
  if type(EXT[t.extstr]) == 'number' then 
    for key in pairs(t.values) do 
      local isint = ({math.modf(EXT[t.extstr])})[2] == 0 and ({math.modf(key)})[2] == 0 
      if type(key) == 'number' and key ~= 0 and ((isint==true and EXT[t.extstr]&key==key) or EXT[t.extstr]==key) then preview_value = t.values[key] break end 
    end
   elseif type(EXT[t.extstr]) == 'string' then 
    preview_value = EXT[t.extstr] 
  end
  if not preview_value and t.values[0] then preview_value = t.values[0] end 
  ImGui.SetNextItemWidth( ctx, 280 )
  if t.extw then ImGui.SetNextItemWidth( ctx, t.extw ) end
  if ImGui.BeginCombo( ctx, t.key, preview_value ) then
    for id in spairs(t.values) do
      local selected 
      if type(EXT[t.extstr]) == 'number' then 
        
        local isint = ({math.modf(EXT[t.extstr])})[2] == 0 and ({math.modf(id)})[2] == 0 
        selected = ((isint==true and id&EXT[t.extstr]==EXT[t.extstr]) or id==EXT[t.extstr])  and EXT[t.extstr]~= 0 
      end
      if type(EXT[t.extstr]) == 'string' then selected = EXT[t.extstr]==id end
      
      if ImGui.Selectable( ctx, t.values[id],selected  ) then
        EXT[t.extstr] = id
        trig_action = true
        EXT:save()
      end
    end
    ImGui.EndCombo(ctx)
  end
  
  -- reset
  if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
    DATA.PRESET_RestoreDefaults(t.extstr)
    trig_action = true
  end 
  
  if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  return  trig_action
end

--------------------------------------------------------------------------------  
function UI.draw_flow_SLIDER(t) 
  local trig_action
    ImGui.SetNextItemWidth( ctx, 150 )
    local retval, v
    if t.int or t.block then
      local format = t.format
      retval, v = reaper.ImGui_SliderInt ( ctx, t.key..'##'..t.extstr, math.floor(EXT[t.extstr]), t.min, t.max, format )
      if retval then trig_action = true end
     elseif t.percent then
      retval, v = reaper.ImGui_SliderDouble( ctx, t.key..'##'..t.extstr, EXT[t.extstr]*100, t.percent_min or 0, t.percent_max or 100, t.format or '%.1f%%' )
      if retval then trig_action = true end
     else  
      retval, v = reaper.ImGui_SliderDouble( ctx, t.key..'##'..t.extstr, EXT[t.extstr], t.min, t.max, t.format )
      if retval then trig_action = true end
    end
    
    
    if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
      DATA.PRESET_RestoreDefaults(t.extstr)
      trig_action = true
     else
      if retval then 
        if t.percent then EXT[t.extstr] = v /100 else EXT[t.extstr] = v  end
        EXT:save() 
        trig_action = true
      end
    end
  
    if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  return trig_action
end
--------------------------------------------------------------------------------  
function UI.draw_flow_CHECK(t)
  local trig_action
  local byte = t.confkeybyte or 0
  if reaper.ImGui_Checkbox( ctx, t.key, EXT[t.extstr]&(1<<byte)==(1<<byte) ) then 
    EXT[t.extstr] = EXT[t.extstr]~(1<<byte) 
    trig_action = true 
    EXT:save() 
  end
  -- reset
  if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
    DATA.PRESET_RestoreDefaults(t.extstr)
    trig_action = true 
  end
  
  if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  return trig_action
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
--------------------------------------------------------------------- 
  function DATA.PRESET_encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
      return ((data:gsub('.', function(x) 
          local r,b='',x:byte()
          for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
          return r;
      end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
          if (#x < 6) then return '' end
          local c=0
          for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
          return b:sub(c+1,c+1)
      end)..({ '', '==', '=' })[#data%3+1])
  end
--------------------------------------------------------------------- 
function DATA.PRESET_decBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
end
--------------------------------------------------------------------- 
function DATA.PRESET_ApplyPreset(base64str, preset_name)  
  if not base64str then return end
  local  preset_t = {}
  
  local str_dec = DATA.PRESET_decBase64(base64str)
  if str_dec~= '' then 
    for line in str_dec:gmatch('[^\r\n]+') do
      local key,value = line:gsub('[%{}]',''):match('(.-)=(.*)') 
      if key and value and key:match('CONF_') then preset_t[key]= tonumber(value) or value end
    end   
  end 
  for key in pairs(preset_t) do
    if key:match('CONF_') then 
      local presval = preset_t[key]
      EXT[key] = tonumber(presval) or presval
    end
  end 
  
  if preset_name then EXT.CONF_NAME = preset_name end
  EXT:save() 
end
--------------------------------------------------------------------------------  
function UI.draw_unsetbuttonstyle() 
  UI.MAIN_PopStyle(ctx, nil, 3)
end
--------------------------------------------------------------------- 
function DATA.PRESET_RestoreDefaults(key, UI)

  if not key then
    for key in pairs(EXT) do
      if key:match('CONF_') or (UI and UI == true and key:match('UI_'))then
        local val = EXT_defaults[key]
        if val then EXT[key]  = val end
      end
    end
   else
    local val = EXT_defaults[key]
    if val then EXT[key]  = val end
  end
  
  EXT:save() 
end
--------------------------------------------------------------------- 
function DATA.PRESET_GetCurrentPresetData()
  local str = ''
  for key in spairs(EXT) do if key:match('CONF_') then str = str..'\n'..key..'='..EXT[key] end end
  return DATA.PRESET_encBase64(str)
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
--------------------------------------------------------------------------------  
function UI.draw_preset() 
  -- preset 
  
  local select_wsz = 250
  local select_hsz = 18--UI.calc_itemH
  UI.draw_setbuttonbackgtransparent() ImGui.Button(ctx, 'Preset') UI.draw_unsetbuttonstyle() ImGui.SameLine(ctx)
  --ImGui.SetCursorPosX( ctx, DATA.display_w-UI.combo_w-UI.spacingX_wind )
  --ImGui.SetNextItemWidth( ctx, UI.combo_w )  
  local preview = EXT.CONF_name 
  
  
  
  if ImGui.BeginCombo(ctx, '##Preset', preview, ImGui.ComboFlags_HeightLargest) then 
    if ImGui.Button(ctx, 'Restore defaults') then DATA.PRESET_RestoreDefaults() end
    local retval, buf = reaper.ImGui_InputText( ctx, '##presname', DATA.preset_name )
    if retval then DATA.preset_name = buf end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Save current') then 
      local newID = DATA.preset_name--os.date()
      EXT.CONF_name = newID
      DATA.presets.user[newID] = DATA.PRESET_GetCurrentPresetData() 
      EXT.preset_base64_user =   DATA.PRESET_encBase64(table.save(DATA.presets.user))
      EXT:save() 
    end
    
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5,1)
    
    local id = 0
    for preset in spairs(DATA.presets.factory) do
      id = id + 1
      if ImGui.Selectable(ctx, '[F] '..preset..'##factorypresets'..id, nil,nil,select_wsz,select_hsz) then 
        DATA.PRESET_ApplyPreset(DATA.presets.factory[preset], preset)
        EXT:save() 
      end
    end 
    local id = 0
    for preset in spairs(DATA.presets.user) do
      id = id + 1
      if ImGui.Selectable(ctx, preset..'##userpresets'..id, nil,nil,select_wsz,select_hsz) then 
        DATA.PRESET_ApplyPreset(DATA.presets.user[preset], preset)
        EXT:save() 
      end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Remove##remove'..id,0,select_hsz) then 
        DATA.presets.user[preset] = nil
        EXT.preset_base64_user =   DATA.PRESET_encBase64(table.save(DATA.presets.user))
        EXT:save() 
      end
    end 
    
    
    
    ImGui.PopStyleVar(ctx)
    
    
    ImGui.EndCombo(ctx) 
  end  
  
  
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


  ---------------------------------------------------
  function CopyTable(orig)--http://lua-users.org/wiki/CopyTable
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[CopyTable(orig_key)] = CopyTable(orig_value)
          end
          setmetatable(copy, CopyTable(getmetatable(orig)))
      else -- number, string, boolean, etc
          copy = orig
      end
      return copy
  end 

-----------------------------------------------------------------------------------------
main()
  
  
  
  