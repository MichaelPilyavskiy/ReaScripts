-- @description Send control
-- @version 1.14
-- @author MPL
-- @about Controlling selected track sends
-- @website http://forum.cockos.com/showthread.php?t=165672 
-- @changelog
--    # color prefaders sliders back with blue



    
--NOT reaper NOT gfx


--------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
  if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end 
  local ImGui
  
  if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
  package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  ImGui = require 'imgui' '0.9'
  
  
  
-------------------------------------------------------------------------------- init external defaults 
EXT = {
        viewport_posX = 0,
        viewport_posY = 0,
      }
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'MPL_SendControl',
        UI_name = 'MPL Send Control',
        
        upd = true, 
        perform_quere = {}, 
        
        custom_fader_scale_lim = 0.8,
        custom_fader_coeff = 30,
        
        send_folder_names = 'send',
        }
        
-------------------------------------------------------------------------------- INIT UI locals
for key in pairs(reaper) do _G[key]=reaper[key] end 
--local ctx
-------------------------------------------------------------------------------- UI init variables
UI = {}
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
  UI.sliderbackcol = 0x4F6C97
-- alpha
  UI.textcol_a_enabled = 1
  UI.textcol_a_disabled = 0.5
  
  
-- special 
  UI.windowBg_plugin = 0x505050
  UI.butBg_green = 0x00B300
  UI.butBg_red = 0xB31F0F












function msg(s) 
  if not s then return end 
  if type(s) == 'boolean' then
    if s then s = 'true' else  s = 'false' end
  end
  ShowConsoleMsg(s..'\n') 
end 
-------------------------------------------------------------------------------- 
function UI.MAIN_PushStyle(key, value, value2, iscol)  
  if not iscol then 
    ImGui.PushStyleVar(ctx, key, value, value2)
    UI.pushcnt = UI.pushcnt + 1
  else 
    ImGui.PushStyleColor(ctx, key, math.floor(value2*255)|(value<<8) )
    UI.pushcnt2 = UI.pushcnt2 + 1
  end 
end
-------------------------------------------------------------------------------- 
function UI.MAIN_draw(open) 
  local w_min = 250
  local h_min = 150
  -- window_flags
    local window_flags = ImGui.WindowFlags_None
    --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar()
    --window_flags = window_flags | ImGui.WindowFlags_NoScrollbar()
    --window_flags = window_flags | ImGui.WindowFlags_MenuBar()
    --window_flags = window_flags | ImGui.WindowFlags_NoMove()
    --window_flags = window_flags | ImGui.WindowFlags_NoReSize
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
    UI.MAIN_PushStyle(ImGui.StyleVar_FrameRounding,5)  
    UI.MAIN_PushStyle(ImGui.StyleVar_GrabRounding,5)  
    UI.MAIN_PushStyle(ImGui.StyleVar_WindowRounding,10)  
    UI.MAIN_PushStyle(ImGui.StyleVar_ChildRounding,5)  
    UI.MAIN_PushStyle(ImGui.StyleVar_PopupRounding,0)  
    UI.MAIN_PushStyle(ImGui.StyleVar_ScrollbarRounding,9)  
    UI.MAIN_PushStyle(ImGui.StyleVar_TabRounding,4)   
  -- Borders
    UI.MAIN_PushStyle(ImGui.StyleVar_WindowBorderSize,0)  
    UI.MAIN_PushStyle(ImGui.StyleVar_FrameBorderSize,0) 
  -- spacing
    UI.MAIN_PushStyle(ImGui.StyleVar_WindowPadding,UI.spacingX,UI.spacingY)  
    UI.MAIN_PushStyle(ImGui.StyleVar_FramePadding,10,5) 
    UI.MAIN_PushStyle(ImGui.StyleVar_CellPadding,UI.spacingX, UI.spacingY) 
    UI.MAIN_PushStyle(ImGui.StyleVar_ItemSpacing,UI.spacingX, UI.spacingY)
    UI.MAIN_PushStyle(ImGui.StyleVar_ItemInnerSpacing,4,0)
    UI.MAIN_PushStyle(ImGui.StyleVar_IndentSpacing,20)
    UI.MAIN_PushStyle(ImGui.StyleVar_ScrollbarSize,20)
  -- size
    UI.MAIN_PushStyle(ImGui.StyleVar_GrabMinSize,30)
    UI.MAIN_PushStyle(ImGui.StyleVar_WindowMinSize,w_min,h_min)
  -- align
    UI.MAIN_PushStyle(ImGui.StyleVar_WindowTitleAlign,0.5,0.5)
    UI.MAIN_PushStyle(ImGui.StyleVar_ButtonTextAlign,0.5,0.5)
    --UI.MAIN_PushStyle(ImGui.StyleVar_SelectableTextAlign,0,0 )
    --UI.MAIN_PushStyle(ImGui.StyleVar_SeparatorTextAlign,0,0.5 )
    --UI.MAIN_PushStyle(ImGui.StyleVar_SeparatorTextPadding,20,3 )
    --UI.MAIN_PushStyle(ImGui.StyleVar_SeparatorTextBorderSize,3 )
  -- alpha
    UI.MAIN_PushStyle(ImGui.StyleVar_Alpha,0.98)
    --UI.MAIN_PushStyle(ImGui.StyleVar_DisabledAlpha,0.6 ) 
    UI.MAIN_PushStyle(ImGui.Col_Border,UI.main_col, 0.3, true)
  -- colors
    --UI.MAIN_PushStyle(ImGui.Col_BorderShadow(),0xFFFFFF, 1, true)
    UI.MAIN_PushStyle(ImGui.Col_Button,UI.main_col, 0.3, true) 
    UI.MAIN_PushStyle(ImGui.Col_ButtonActive,UI.main_col, 1, true) 
    UI.MAIN_PushStyle(ImGui.Col_ButtonHovered,UI.but_hovered, 0.8, true)
    --UI.MAIN_PushStyle(ImGui.Col_CheckMark(),UI.main_col, 0, true)
    --UI.MAIN_PushStyle(ImGui.Col_ChildBg(),UI.main_col, 0, true)
    --UI.MAIN_PushStyle(ImGui.Col_ChildBg(),UI.main_col, 0, true) 
    
    
    --Constant: Col_DockingEmptyBg
    --Constant: Col_DockingPreview
    --Constant: Col_DragDropTarget 
    UI.MAIN_PushStyle(ImGui.Col_DragDropTarget,0xFF1F5F, 0.6, true)
    UI.MAIN_PushStyle(ImGui.Col_FrameBg,0x1F1F1F, 0.7, true)
    UI.MAIN_PushStyle(ImGui.Col_FrameBgActive,UI.main_col, .6, true)
    UI.MAIN_PushStyle(ImGui.Col_FrameBgHovered,UI.main_col, 0.7, true)
    UI.MAIN_PushStyle(ImGui.Col_Header,UI.main_col, 0.5, true) 
    UI.MAIN_PushStyle(ImGui.Col_HeaderActive,UI.main_col, 1, true) 
    UI.MAIN_PushStyle(ImGui.Col_HeaderHovered,UI.main_col, 0.98, true) 
    --Constant: Col_MenuBarBg
    --Constant: Col_ModalWindowDimBg
    --Constant: Col_NavHighlight
    --Constant: Col_NavWindowingDimBg
    --Constant: Col_NavWindowingHighlight
    --Constant: Col_PlotHistogram
    --Constant: Col_PlotHistogramHovered
    --Constant: Col_PlotLines
    --Constant: Col_PlotLinesHovered 
    UI.MAIN_PushStyle(ImGui.Col_PopupBg,0x303030, 0.9, true) 
    UI.MAIN_PushStyle(ImGui.Col_ResizeGrip,UI.main_col, 1, true) 
    --Constant: Col_ResizeGripActive 
    UI.MAIN_PushStyle(ImGui.Col_ResizeGripHovered,UI.main_col, 1, true) 
    --Constant: Col_ScrollbarBg
    --Constant: Col_ScrollbarGrab
    --Constant: Col_ScrollbarGrabActive
    --Constant: Col_ScrollbarGrabHovered
    --Constant: Col_Separator
    --Constant: Col_SeparatorActive
    --Constant: Col_SeparatorHovered
    --Constant: Col_SliderGrab
    --Constant: Col_SliderGrabActive
    UI.MAIN_PushStyle(ImGui.Col_Tab,UI.main_col, 0.37, true) 
    UI.MAIN_PushStyle(ImGui.Col_TabActive,UI.main_col, 1, true) 
    UI.MAIN_PushStyle(ImGui.Col_TabHovered,UI.main_col, 0.8, true) 
    --Constant: Col_TabUnfocused
    --ImGui.Col_TabUnfocusedActive
    --UI.MAIN_PushStyle(ImGui.Col_TabUnfocusedActive(),UI.main_col, 0.8, true)
    --Constant: Col_TableBorderLight
    --Constant: Col_TableBorderStrong
    --Constant: Col_TableHeaderBg
    --Constant: Col_TableRowBg
    --Constant: Col_TableRowBgAlt
    UI.MAIN_PushStyle(ImGui.Col_Text,UI.textcol, UI.textcol_a_enabled, true) 
    --Constant: Col_TextDisabled
    --Constant: Col_TextSelectedBg
    UI.MAIN_PushStyle(ImGui.Col_TitleBg,UI.main_col, 0.7, true) 
    UI.MAIN_PushStyle(ImGui.Col_TitleBgActive,UI.main_col, 0.95, true) 
    --Constant: Col_TitleBgCollapsed 
    UI.MAIN_PushStyle(ImGui.Col_WindowBg,UI.windowBg, 1, true)
    
  -- We specify a default position/size in case there's no data in the .ini file.
    local main_viewport = ImGui.GetMainViewport(ctx)
    local x, y =EXT.viewport_posX,EXT.viewport_posY-- ImGui.Viewport_GetPos(main_viewport)
    ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
    ImGui.SetNextWindowSize(ctx, 550, 680, ImGui.Cond_FirstUseEver)
    
    
  -- init UI 
    ImGui.PushFont(ctx, DATA.font1) 
    local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) 
    if rv then
      local Viewport = ImGui.GetWindowViewport(ctx)
      --DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport)
      DATA.display_w, DATA.display_h = reaper.ImGui_GetContentRegionAvail( ctx )
      DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport)
      --DATA.display_w, DATA.display_h = ImGui.GetWindowContentRegionMin(ctx)
      
    -- calc stuff for childs
      UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
      local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
      local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test', nil, nil, false, -1.0)
      UI.calc_itemH = calcitemh + frameh * 2
      UI.calc_itemH_small = math.floor(UI.calc_itemH*0.8)
      
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
function DATA:perform_add(f) DATA.perform_quere[#DATA.perform_quere+1] = f end
-------------------------------------------------------------------------------- 
function DATA:perform()
  if not DATA.perform_quere then return end
  for i = 1, #DATA.perform_quere do if DATA.perform_quere[i] then DATA.perform_quere[i]() end end
  DATA.perform_quere = {} --- clear
end
-------------------------------------------------------------------------------- 
function UI.MAINloop() 
  DATA.clock = os.clock() 
  DATA:handleProjUpdates()
  
  if DATA.upd == true then  DATA:CollectData()  end 
  DATA.upd = false
  
  -- draw UI
  UI.open = UI.MAIN_draw(true) 
  
  -- handle xy
  DATA:handleViewportXY()
  -- data
  if UI.open then defer(UI.MAINloop) end
end
-------------------------------------------------------------------------------- 
function DATA:handleViewportXY()
  if not (DATA.display_x and DATA.display_y) then return end
  
  if not DATA.display_x_last then DATA.display_x_last = DATA.display_x end
  if not DATA.display_y_last then DATA.display_y_last = DATA.display_y end
  
  if DATA.display_x_last~= DATA.display_x or DATA.display_y_last~= DATA.display_y then DATA.display_schedule_save = os.clock() end
  if DATA.display_schedule_save and os.clock() - DATA.display_schedule_save > 0.3 then 
    EXT.viewport_posX = DATA.display_x
    EXT.viewport_posY = DATA.display_y
    EXT:save() 
    DATA.display_schedule_save = nil 
  end
  DATA.display_x_last = DATA.display_x
  DATA.display_y_last = DATA.display_y
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
-------------------------------------------------------------------------------- 
function DATA:handleProjUpdates()
  local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
  local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
  local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
end
------------------------------------------------------------------------------------------------------
function VF_Action(s, sectionID, ME )   
  if sectionID == 32060 and ME then 
    MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
   else
    Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
  end
end 
--------------------------------------------------------------------------------  
function DATA:CollectData_GetAvailableSends()
  DATA.available_sends = {}
  local ret, tr, idx = DATA:CollectData_GetAvailableSends_GetFolder()
  if not ret then return end
  local level = 0
  for i = idx, CountTracks(0) do
    local tr = GetTrack(0,i-1)
    level = level + GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH'  )
    
    local ret, trname =  GetTrackName(tr)
    --msg(trname)
    if level>=0 and i~= idx then 
      local GUID = reaper.GetTrackGUID( tr )
      -- check if already used
      if DATA.tr_data.sends then 
        for j = 1, #DATA.tr_data.sends do
          if GUID==DATA.tr_data.sends[j].destGUID then goto nextsend end
        end
      end
      
      DATA.available_sends[#DATA.available_sends+1] = 
        {  GUID = GUID,
          name = trname
          }
          
      ::nextsend::
    end
    if level == 0 then break end
  end
end
--------------------------------------------------------------------------------  
function DATA:CollectData_GetAvailableSends_GetFolder()
  local foldname = {}
  for name in DATA.send_folder_names:gmatch('[^,]+') do foldname[#foldname+1] = name end 
  if #foldname == 0 then return end
  for i = 1, CountTracks(0) do
    local tr = GetTrack(0,i-1)
    if GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH'  ) == 1 then
      local retval, trname = GetTrackName( tr )
      for i2=1,#foldname do
        if trname:lower():match(foldname[i2]:lower()) then
          return true, tr, i
        end
      end
    end
  end
end
--------------------------------------------------------------------------------  
function DATA:CollectData()

  -- collect sel track data
  DATA.tr_data = {sends={}}
  local tr = GetSelectedTrack(0,0)
  if not tr then return end
  
  local sendscnt =  GetTrackNumSends( tr, 0 )
  DATA.tr_data.ptr = tr
  for sendidx =1, sendscnt do
    local D_VOL = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'D_VOL' )
    local B_MUTE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'B_MUTE' )
    local P_DESTTRACK = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'P_DESTTRACK' )
    local I_SENDMODE = GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_SENDMODE' ) --0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fx
    local retval, desttrname = reaper.GetTrackName( P_DESTTRACK )
    local destGUID = GetTrackGUID( P_DESTTRACK )
    local voldb = WDL_VAL2DB(D_VOL)
    local voldbformat = string.format("%.03f dB",voldb)
    DATA.tr_data.sends[sendidx] = {
      sendidx = sendidx,
      D_VOL = D_VOL,
      D_VOLdb = voldb,
      D_VOLdb_format = voldbformat,
      D_VOL_scaled = DATA.Convert_Val2Fader(D_VOL),
      B_MUTE = B_MUTE,
      I_SENDMODE = I_SENDMODE,
      desttrname=desttrname,
      destGUID=destGUID,
      }
  end
  
  DATA:CollectData_GetAvailableSends()
  
end
--------------------------------------------------------------------------------  
function main()
  UI.MAIN() 
end
--------------------------------------------------------------------------------  
function DATA.Send_params_set(send_t, param)
  if not param then return end
  local immode = 0
  if param.mute~= nil then SetTrackSendInfo_Value( DATA.tr_data.ptr, 0, send_t.sendidx-1, 'B_MUTE', param.mute) end
  if param.vol_lin~= nil then 
    local outvol = DATA.Convert_Fader2Val(param.vol_lin)
    SetTrackSendInfo_Value( DATA.tr_data.ptr, 0, send_t.sendidx-1, 'D_VOL', outvol) 
    SetTrackSendUIVol( DATA.tr_data.ptr, send_t.sendidx-1, outvol, immode)
  end
  if param.vol_dB~= nil then 
    local outvol = WDL_DB2VAL(param.vol_dB)
    SetTrackSendInfo_Value( DATA.tr_data.ptr, 0, send_t.sendidx-1, 'D_VOL',outvol )
    SetTrackSendUIVol( DATA.tr_data.ptr, send_t.sendidx-1, outvol, immode)
  end
  if param.mode~= nil then SetTrackSendInfo_Value( DATA.tr_data.ptr, 0, send_t.sendidx-1, 'I_SENDMODE', param.mode) end
  
  DATA.upd = true
end
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x, reduce)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else return v end
  end
  function VF_lim(val, min,max) if not min or not max then min, max = 0,1 end return math.max(min,  math.min(val, max) )  end
  -------------------------------------------------------------------- 
  function DATA.Convert_Fader2Val(fader_val)
    
    local fader_val = VF_lim(fader_val,0,1)
    local gfx_c, coeff = DATA.custom_fader_scale_lim,DATA.custom_fader_coeff 
    local val
    if fader_val <=gfx_c then
      local lin2 = fader_val/gfx_c
      local real_dB = coeff*math.log(lin2, 10)
      val = 10^(real_dB/20)
     else
      local real_dB = 12 * (fader_val  / (1 - gfx_c) - gfx_c/ (1 - gfx_c))
      val = 10^(real_dB/20)
    end
    if val > 4 then val = 4 end
    if val < 0 then val = 0 end
    return val
  end
  -------------------------------------------------------------------- 
  function DATA.Convert_Val2Fader(rea_val)
    if not rea_val then return end 
    local rea_val = VF_lim(rea_val, 0, 4)
    local val 
    local gfx_c, coeff = DATA.custom_fader_scale_lim,DATA.custom_fader_coeff 
    local real_dB = 20*math.log(rea_val, 10)
    local lin2 = 10^(real_dB/coeff)  
    if lin2 <=1 then val = lin2*gfx_c else val = gfx_c + (real_dB/12)*(1-gfx_c) end
    if val > 1 then val = 1 end
    return VF_lim(val, 0.0001, 1)
  end

  --------------------------------------------------
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or 0) do
      local tr = GetTrack(reaproj or 0,i-1)
      --local GUID = reaper.GetTrackGUID( tr )
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end
--------------------------------------------------------------------------------  
function UI.draw_send(send_t)  
  --UI.MAIN_PushStyle(ImGui.Col_ChildBg(),UI.windowBg_plugin, 0.2, true)
  --UI.MAIN_PushStyle(ImGui.Col_ChildBg(),plugdata.tr_col, 0.2, true)
  UI.MAIN_PushStyle(ImGui.Col_FrameBgHovered,UI.main_col, 0.2, true)
  local but_h = 20
  local ctrlw = 120
  local slider_w = DATA.display_w-UI.calc_xoffset*2
  local butw = (DATA.display_w-UI.calc_xoffset*7)/7
  if ImGui.BeginChild( ctx, send_t.sendidx..'##'..send_t.sendidx, 0, 0,  ImGui.ChildFlags_AutoResizeY|ImGui.ChildFlags_Border, 0 ) then
    
    ImGui.PushFont(ctx, DATA.font3) 
    
    -- on / mute
    local online = 'M' 
    if send_t.B_MUTE&1~=1 then UI.draw_setbuttoncolor(UI.main_col) else UI.draw_setbuttoncolor(UI.butBg_red) end 
    local ret = ImGui.Button( ctx, 'M##off'..send_t.sendidx, butw, but_h ) UI.draw_unsetbuttoncolor() --UI.SameLine(ctx)
    if ret then DATA.Send_params_set(send_t,{mute= send_t.B_MUTE~1}) end
    
    UI.SameLine(ctx) 
    if send_t.I_SENDMODE==0 then UI.draw_setbuttoncolor(UI.main_col) else UI.draw_setbuttoncolor(UI.butBg_green) end  
    local txt = 'PostFX'
    local set = 0
    if send_t.I_SENDMODE==0 then txt = 'PostFader' set = 3 else set = 0 end  
    
    
    local ret = ImGui.Button( ctx, txt..'##sm1'..send_t.sendidx, butw*2, but_h ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Send_params_set(send_t,{mode= set}) end
    --[[if send_t.I_SENDMODE==1 then UI.draw_setbuttoncolor(UI.butBg_green) else UI.draw_setbuttoncolor(UI.main_col) end  
    local ret = ImGui.Button( ctx, 'PreFX##sm2'..send_t.sendidx, butw*2, but_h ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Send_params_set(send_t,{mode= 1}) end
    if send_t.I_SENDMODE==3 then UI.draw_setbuttoncolor(UI.butBg_green) else UI.draw_setbuttoncolor(UI.main_col) end  
    local ret = ImGui.Button( ctx, 'PostFX##sm3'..send_t.sendidx, butw*2, but_h ) UI.draw_unsetbuttoncolor()
    if ret then DATA.Send_params_set(send_t,{mode= 3}) end ]]   
    local ret = ImGui.Button( ctx, 'FX##sm1fx'..send_t.sendidx, butw, but_h ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then 
      local destGUID = send_t.destGUID
      local tr = VF_GetTrackByGUID(destGUID)
      if ValidatePtr(tr, 'MediaTrack*') then 
        TrackFX_Show( tr, 0, 1 )
      end
        
    end
    
    if send_t.I_SENDMODE~=0 then  
      UI.MAIN_PushStyle(ImGui.Col_FrameBg,UI.sliderbackcol, 0.2, true)
      UI.MAIN_PushStyle(ImGui.Col_FrameBgHovered,UI.sliderbackcol, 0.5, true)
     else
      UI.MAIN_PushStyle(ImGui.Col_FrameBg,UI.main_col, 0.2, true)
      UI.MAIN_PushStyle(ImGui.Col_FrameBgHovered,UI.main_col, 0.5, true)
    end
    
    ImGui.SetNextItemWidth( ctx, butw*3+UI.calc_xoffset*2 )
    local step, step2 = 0.5, 0.2
    local retval, v = ImGui.InputDouble( ctx, '##slidervol2'..send_t.sendidx, send_t.D_VOLdb, step, step2, "%.01f", ImGui.InputTextFlags_CharsDecimal|ImGui.InputTextFlags_EnterReturnsTrue )-- dB 
    if retval then 
      v = VF_lim(v, -150,12)
      DATA.Send_params_set(send_t, {vol_dB=v}) 
    end 
    ImGui.PopFont(ctx) 
    local curposX, curposY = ImGui.GetCursorPos(ctx)
    ImGui.SetNextItemWidth( ctx, slider_w )
    local retval, v = ImGui.SliderDouble(ctx, '##slidervol'..send_t.sendidx, send_t.D_VOL_scaled, 0, 1, '', ImGui.SliderFlags_None| ImGui.SliderFlags_NoInput)
    if ImGui_IsItemHovered( ctx ) then
      local ctrl = ( 
        ImGui.IsKeyPressed( ctx, ImGui.Mod_Ctrl, 1 )or
        ImGui.IsKeyPressed( ctx, ImGui.Key_LeftCtrl, 1 )or
        ImGui.IsKeyPressed( ctx, ImGui.Key_RightCtrl,1 )
        ) 
        
      local vertical, horizontal = ImGui_GetMouseWheel( ctx )
      if vertical ~=0  then
        local dir = -1
        if vertical>0 then dir = 1 end
        local step= 0.1
        DATA.Send_params_set(send_t, {vol_dB=send_t.D_VOLdb+dir*step})
      end
    end
    if retval then DATA.Send_params_set(send_t, {vol_lin=v}) end UI.SameLine(ctx)
    ImGui.SetCursorPos(ctx, curposX, curposY)
    ImGui.Indent(ctx) ImGui.Text(ctx, send_t.desttrname) 
    ImGui.EndChild( ctx )
  end
  
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col) 
    UI.MAIN_PushStyle(ImGui.Col_Button,col, 0.5, true) 
    UI.MAIN_PushStyle(ImGui.Col_ButtonActive,col, 1, true) 
    UI.MAIN_PushStyle(ImGui.Col_ButtonHovered,col, 0.8, true)
end
--------------------------------------------------------------------------------  
function UI.draw_unsetbuttoncolor() 
  ImGui.PopStyleColor(ctx,3)
  UI.pushcnt2 = UI.pushcnt2 -3
end
--------------------------------------------------------------------------------  
function GetTrackByGUID(GUIDin)
  for i = 1, CountTracks(0) do
    local tr = GetTrack(0,i-1)
    local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
    if GUID:gsub('%p+','') == GUIDin:gsub('%p+','') then return tr end
  end
end
--------------------------------------------------------------------------------  
function UI.draw() 
  
  
  local sendcnt= #DATA.tr_data.sends
  for i = 1, sendcnt do UI.draw_send(DATA.tr_data.sends[i]) end 
  
  
  if not (DATA.available_sends and #DATA.available_sends>0) then return end
  
  if  ImGui.IsMouseClicked( ctx,  ImGui.MouseButton_Right, false ) then ImGui.OpenPopup(ctx, 'sendspopup') end
  
  ImGui.SameLine(ctx)
  --ImGui.Text(ctx, '<None>')
  if ImGui.BeginPopup(ctx, 'sendspopup') then
    ImGui.SeparatorText(ctx, 'Available sends')
    for i = 1 , #DATA.available_sends do 
      if ImGui.Selectable(ctx, DATA.available_sends[i].name..'##send'..i) then 
      
        local desttr = GetTrackByGUID(DATA.available_sends[i].GUID)
        if desttr then 
          reaper.Undo_BeginBlock2( 0 )
          CreateTrackSend( DATA.tr_data.ptr, desttr ) 
          reaper.Undo_EndBlock2( 0, 'Send control - add send', 0xFFFFFFFF )
          DATA.upd = true 
          ImGui.EndMenu(ctx) 
          return 
        end
        
      end
    end
    ImGui.EndPopup(ctx)
  end
      
      
  
  
end
-----------------------------------------------------------------------------------------
  main()