-- @description Send control
-- @version 1.06
-- @author MPL
-- @about Controlling selected track sends
-- @website http://forum.cockos.com/showthread.php?t=165672 
-- @changelog
--  # fix refresh

    
    
--NOT reaper NOT gfx


-------------------------------------------------------------------------------- init external defaults 
EXT = {
        
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
    ImGui_PushStyleVar(ctx, key, value, value2)
    UI.pushcnt = UI.pushcnt + 1
  else 
    ImGui_PushStyleColor(ctx, key, math.floor(value2*255)|(value<<8) )
    UI.pushcnt2 = UI.pushcnt2 + 1
  end 
end
-------------------------------------------------------------------------------- 
function UI.MAIN_draw(open) 
  local w_min = 250
  local h_min = 150
  -- window_flags
    local window_flags = ImGui_WindowFlags_None()
    --window_flags = window_flags | ImGui_WindowFlags_NoTitleBar()
    --window_flags = window_flags | ImGui_WindowFlags_NoScrollbar()
    --window_flags = window_flags | ImGui_WindowFlags_MenuBar()
    --window_flags = window_flags | ImGui_WindowFlags_NoMove()
    --window_flags = window_flags | ImGui_WindowFlags_NoResize()
    window_flags = window_flags | ImGui_WindowFlags_NoCollapse()
    --window_flags = window_flags | ImGui_WindowFlags_NoNav()
    --window_flags = window_flags | ImGui_WindowFlags_NoBackground()
    window_flags = window_flags | ImGui_WindowFlags_NoDocking()
    window_flags = window_flags | ImGui_WindowFlags_TopMost()
    --if UI.disable_save_window_pos == true then window_flags = window_flags | ImGui_WindowFlags_NoSavedSettings() end
    --window_flags = window_flags | ImGui_WindowFlags_UnsavedDocument()
    --open = false -- disable the close button
  
  
  -- set style
    UI.pushcnt = 0
    UI.pushcnt2 = 0
  -- rounding
    UI.MAIN_PushStyle(ImGui_StyleVar_FrameRounding(),5)  
    UI.MAIN_PushStyle(ImGui_StyleVar_GrabRounding(),5)  
    UI.MAIN_PushStyle(ImGui_StyleVar_WindowRounding(),10)  
    UI.MAIN_PushStyle(ImGui_StyleVar_ChildRounding(),5)  
    UI.MAIN_PushStyle(ImGui_StyleVar_PopupRounding(),0)  
    UI.MAIN_PushStyle(ImGui_StyleVar_ScrollbarRounding(),9)  
    UI.MAIN_PushStyle(ImGui_StyleVar_TabRounding(),4)   
  -- Borders
    UI.MAIN_PushStyle(ImGui_StyleVar_WindowBorderSize(),0)  
    UI.MAIN_PushStyle(ImGui_StyleVar_FrameBorderSize(),0) 
  -- spacing
    UI.MAIN_PushStyle(ImGui_StyleVar_WindowPadding(),UI.spacingX,UI.spacingY)  
    UI.MAIN_PushStyle(ImGui_StyleVar_FramePadding(),10,5) 
    UI.MAIN_PushStyle(ImGui_StyleVar_CellPadding(),UI.spacingX, UI.spacingY) 
    UI.MAIN_PushStyle(ImGui_StyleVar_ItemSpacing(),UI.spacingX, UI.spacingY)
    UI.MAIN_PushStyle(ImGui_StyleVar_ItemInnerSpacing(),4,0)
    UI.MAIN_PushStyle(ImGui_StyleVar_IndentSpacing(),20)
    UI.MAIN_PushStyle(ImGui_StyleVar_ScrollbarSize(),14)
  -- size
    UI.MAIN_PushStyle(ImGui_StyleVar_GrabMinSize(),30)
    UI.MAIN_PushStyle(ImGui_StyleVar_WindowMinSize(),w_min,h_min)
  -- align
    UI.MAIN_PushStyle(ImGui_StyleVar_WindowTitleAlign(),0.5,0.5)
    UI.MAIN_PushStyle(ImGui_StyleVar_ButtonTextAlign(),0.5,0.5)
    --UI.MAIN_PushStyle(ImGui_StyleVar_SelectableTextAlign(),0,0 )
    --UI.MAIN_PushStyle(ImGui_StyleVar_SeparatorTextAlign(),0,0.5 )
    --UI.MAIN_PushStyle(ImGui_StyleVar_SeparatorTextPadding(),20,3 )
    --UI.MAIN_PushStyle(ImGui_StyleVar_SeparatorTextBorderSize(),3 )
  -- alpha
    UI.MAIN_PushStyle(ImGui_StyleVar_Alpha(),0.98)
    --UI.MAIN_PushStyle(ImGui_StyleVar_DisabledAlpha(),0.6 ) 
    UI.MAIN_PushStyle(ImGui_Col_Border(),UI.main_col, 0.3, true)
  -- colors
    --UI.MAIN_PushStyle(ImGui_Col_BorderShadow(),0xFFFFFF, 1, true)
    UI.MAIN_PushStyle(ImGui_Col_Button(),UI.main_col, 0.3, true) 
    UI.MAIN_PushStyle(ImGui_Col_ButtonActive(),UI.main_col, 1, true) 
    UI.MAIN_PushStyle(ImGui_Col_ButtonHovered(),UI.but_hovered, 0.8, true)
    --UI.MAIN_PushStyle(ImGui_Col_CheckMark(),UI.main_col, 0, true)
    --UI.MAIN_PushStyle(ImGui_Col_ChildBg(),UI.main_col, 0, true)
    --UI.MAIN_PushStyle(ImGui_Col_ChildBg(),UI.main_col, 0, true) 
    
    
    --Constant: Col_DockingEmptyBg
    --Constant: Col_DockingPreview
    --Constant: Col_DragDropTarget 
    UI.MAIN_PushStyle(ImGui_Col_DragDropTarget(),0xFF1F5F, 0.6, true)
    UI.MAIN_PushStyle(ImGui_Col_FrameBg(),0x1F1F1F, 0.7, true)
    UI.MAIN_PushStyle(ImGui_Col_FrameBgActive(),UI.main_col, .6, true)
    UI.MAIN_PushStyle(ImGui_Col_FrameBgHovered(),UI.main_col, 0.7, true)
    UI.MAIN_PushStyle(ImGui_Col_Header(),UI.main_col, 0.5, true) 
    UI.MAIN_PushStyle(ImGui_Col_HeaderActive(),UI.main_col, 1, true) 
    UI.MAIN_PushStyle(ImGui_Col_HeaderHovered(),UI.main_col, 0.98, true) 
    --Constant: Col_MenuBarBg
    --Constant: Col_ModalWindowDimBg
    --Constant: Col_NavHighlight
    --Constant: Col_NavWindowingDimBg
    --Constant: Col_NavWindowingHighlight
    --Constant: Col_PlotHistogram
    --Constant: Col_PlotHistogramHovered
    --Constant: Col_PlotLines
    --Constant: Col_PlotLinesHovered 
    UI.MAIN_PushStyle(ImGui_Col_PopupBg(),0x303030, 0.9, true) 
    UI.MAIN_PushStyle(ImGui_Col_ResizeGrip(),UI.main_col, 1, true) 
    --Constant: Col_ResizeGripActive 
    UI.MAIN_PushStyle(ImGui_Col_ResizeGripHovered(),UI.main_col, 1, true) 
    --Constant: Col_ScrollbarBg
    --Constant: Col_ScrollbarGrab
    --Constant: Col_ScrollbarGrabActive
    --Constant: Col_ScrollbarGrabHovered
    --Constant: Col_Separator
    --Constant: Col_SeparatorActive
    --Constant: Col_SeparatorHovered
    --Constant: Col_SliderGrab
    --Constant: Col_SliderGrabActive
    UI.MAIN_PushStyle(ImGui_Col_Tab(),UI.main_col, 0.37, true) 
    UI.MAIN_PushStyle(ImGui_Col_TabActive(),UI.main_col, 1, true) 
    UI.MAIN_PushStyle(ImGui_Col_TabHovered(),UI.main_col, 0.8, true) 
    --Constant: Col_TabUnfocused
    --ImGui_Col_TabUnfocusedActive
    --UI.MAIN_PushStyle(ImGui_Col_TabUnfocusedActive(),UI.main_col, 0.8, true)
    --Constant: Col_TableBorderLight
    --Constant: Col_TableBorderStrong
    --Constant: Col_TableHeaderBg
    --Constant: Col_TableRowBg
    --Constant: Col_TableRowBgAlt
    UI.MAIN_PushStyle(ImGui_Col_Text(),UI.textcol, UI.textcol_a_enabled, true) 
    --Constant: Col_TextDisabled
    --Constant: Col_TextSelectedBg
    UI.MAIN_PushStyle(ImGui_Col_TitleBg(),UI.main_col, 0.7, true) 
    UI.MAIN_PushStyle(ImGui_Col_TitleBgActive(),UI.main_col, 0.95, true) 
    --Constant: Col_TitleBgCollapsed 
    UI.MAIN_PushStyle(ImGui_Col_WindowBg(),UI.windowBg, 1, true)
    
  -- We specify a default position/size in case there's no data in the .ini file.
    local main_viewport = ImGui_GetMainViewport(ctx)
    local work_pos = {ImGui_Viewport_GetWorkPos(main_viewport)}
    x, y = reaper.GetMousePosition()
    --ImGui_SetNextWindowPos(ctx, work_pos[1] + 20, work_pos[2] + 20)
    ImGui_SetNextWindowPos(ctx, x+ 20, y+ 20, ImGui_Cond_Appearing())
    local useini = ImGui_Cond_FirstUseEver()
    ImGui_SetNextWindowSize(ctx, 550, 680, useini)
    
    
  -- init UI 
    ImGui_PushFont(ctx, DATA.font1) 
    rv,open = ImGui_Begin(ctx, DATA.UI_name, open, window_flags) if not rv then return open end  
    local ImGui_Viewport = ImGui_GetWindowViewport(ctx)
    DATA.display_w, DATA.display_h = ImGui_Viewport_GetSize(ImGui_Viewport)
    --DATA.display_w, DATA.display_h = ImGui_GetWindowContentRegionMin(ctx)
    
  -- calc stuff for childs
    UI.calc_xoffset,UI.calc_yoffset = reaper.ImGui_GetStyleVar(ctx, ImGui_StyleVar_WindowPadding())
    local framew,frameh = reaper.ImGui_GetStyleVar(ctx, ImGui_StyleVar_FramePadding())
    local calcitemw, calcitemh = ImGui_CalcTextSize(ctx, 'test', nil, nil, false, -1.0)
    UI.calc_itemH = calcitemh + frameh * 2
    UI.calc_itemH_small = math.floor(UI.calc_itemH*0.8)
    
  -- draw stuff
    UI.draw()
    ImGui_PopFont( ctx ) 
    ImGui_PopStyleVar(ctx, UI.pushcnt)
    ImGui_PopStyleColor(ctx, UI.pushcnt2)
    
    ImGui_Dummy(ctx,0,0)
    
  ImGui_End(ctx)
  
  if  reaper.ImGui_IsKeyPressed( ctx, ImGui_Key_Escape(),false )  then return end
  
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
  
  -- data
  if UI.open then defer(UI.MAINloop) end
end
-------------------------------------------------------------------------------- 
function UI.SameLine(ctx) reaper.ImGui_SameLine(ctx) end
-------------------------------------------------------------------------------- 
function UI.MAIN()
  
  EXT:load() 
  -- imgUI init
  ctx = ImGui_CreateContext(DATA.UI_name) 
  -- fonts
  DATA.font1 = ImGui_CreateFont(UI.font, UI.font1sz) ImGui_Attach(ctx, DATA.font1)
  DATA.font2 = ImGui_CreateFont(UI.font, UI.font2sz) ImGui_Attach(ctx, DATA.font2)
  DATA.font3 = ImGui_CreateFont(UI.font, UI.font3sz) ImGui_Attach(ctx, DATA.font3)  
  -- config
  reaper.ImGui_SetConfigVar(ctx, ImGui_ConfigVar_HoverDelayNormal(), UI.hoverdelay)
  reaper.ImGui_SetConfigVar(ctx, ImGui_ConfigVar_HoverDelayShort(), UI.hoverdelayshort)
  
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
  if param.mute~= nil then SetTrackSendInfo_Value( DATA.tr_data.ptr, 0, send_t.sendidx-1, 'B_MUTE', param.mute) end
  if param.vol_lin~= nil then SetTrackSendInfo_Value( DATA.tr_data.ptr, 0, send_t.sendidx-1, 'D_VOL', DATA.Convert_Fader2Val(param.vol_lin)) end
  if param.vol_dB~= nil then SetTrackSendInfo_Value( DATA.tr_data.ptr, 0, send_t.sendidx-1, 'D_VOL', WDL_DB2VAL(param.vol_dB)) end
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
  
--------------------------------------------------------------------------------  
function UI.draw_send(send_t)  
  --UI.MAIN_PushStyle(ImGui_Col_ChildBg(),UI.windowBg_plugin, 0.2, true)
  --UI.MAIN_PushStyle(ImGui_Col_ChildBg(),plugdata.tr_col, 0.2, true)
  UI.MAIN_PushStyle(ImGui_Col_FrameBgHovered(),UI.main_col, 0.2, true)
  local but_h = 20
  local ctrlw = 120
  local slider_w = DATA.display_w-UI.calc_xoffset*4
  local butw = (DATA.display_w-UI.calc_xoffset*7)/7
  if ImGui_BeginChild( ctx, send_t.sendidx..'##'..send_t.sendidx, 0, 0,  ImGui_ChildFlags_AutoResizeY()|ImGui_ChildFlags_Border(), 0 ) then
    
    ImGui_PushFont(ctx, DATA.font3) 
    
    -- on / mute
    local online = 'M' 
    if send_t.B_MUTE&1~=1 then UI.draw_setbuttoncolor(UI.main_col) else UI.draw_setbuttoncolor(UI.butBg_red) end 
    local ret = ImGui_Button( ctx, 'M##off'..send_t.sendidx, butw, but_h ) UI.draw_unsetbuttoncolor() --UI.SameLine(ctx)
    if ret then DATA.Send_params_set(send_t,{mute= send_t.B_MUTE~1}) end
    
    UI.SameLine(ctx) 
    if send_t.I_SENDMODE==0 then UI.draw_setbuttoncolor(UI.butBg_green) else UI.draw_setbuttoncolor(UI.main_col) end  
    local txt = 'PostFX'
    local set = 0
    if send_t.I_SENDMODE==0 then txt = 'PostFader' set = 3 else set = 0 end  
    local ret = ImGui_Button( ctx, txt..'##sm1'..send_t.sendidx, butw*2, but_h ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Send_params_set(send_t,{mode= set}) end
    --[[if send_t.I_SENDMODE==1 then UI.draw_setbuttoncolor(UI.butBg_green) else UI.draw_setbuttoncolor(UI.main_col) end  
    local ret = ImGui_Button( ctx, 'PreFX##sm2'..send_t.sendidx, butw*2, but_h ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Send_params_set(send_t,{mode= 1}) end
    if send_t.I_SENDMODE==3 then UI.draw_setbuttoncolor(UI.butBg_green) else UI.draw_setbuttoncolor(UI.main_col) end  
    local ret = ImGui_Button( ctx, 'PostFX##sm3'..send_t.sendidx, butw*2, but_h ) UI.draw_unsetbuttoncolor()
    if ret then DATA.Send_params_set(send_t,{mode= 3}) end ]]   
    
    
    ImGui_SetNextItemWidth( ctx, butw*4+UI.calc_xoffset*2 )
    local step, step2 = 0.5, 0.2
    local retval, v = reaper.ImGui_InputDouble( ctx, '##slidervol2'..send_t.sendidx, send_t.D_VOLdb, step, step2, "%.01f dB", ImGui_InputTextFlags_CharsDecimal()|ImGui_InputTextFlags_EnterReturnsTrue() )-- 
    if retval then 
      v = VF_lim(v, -150,12)
      DATA.Send_params_set(send_t, {vol_dB=v}) 
    end 
    ImGui_PopFont(ctx) 
    
    local curposX, curposY = ImGui_GetCursorPos(ctx)
    ImGui_SetNextItemWidth( ctx, slider_w )
    local retval, v = ImGui_SliderDouble(ctx, '##slidervol'..send_t.sendidx, send_t.D_VOL_scaled, 0, 1, '', ImGui_SliderFlags_None()| ImGui_SliderFlags_NoInput())
    if retval then DATA.Send_params_set(send_t, {vol_lin=v}) end UI.SameLine(ctx)
    ImGui_SetCursorPos(ctx, curposX, curposY)
    ImGui_Indent(ctx) ImGui_Text(ctx, send_t.desttrname) 
    ImGui_EndChild( ctx )
  end
  
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col) 
    UI.MAIN_PushStyle(ImGui_Col_Button(),col, 0.5, true) 
    UI.MAIN_PushStyle(ImGui_Col_ButtonActive(),col, 1, true) 
    UI.MAIN_PushStyle(ImGui_Col_ButtonHovered(),col, 0.8, true)
end
--------------------------------------------------------------------------------  
function UI.draw_unsetbuttoncolor() 
  ImGui_PopStyleColor(ctx,3)
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
  
  if  ImGui_IsMouseClicked( ctx,  ImGui_MouseButton_Right(), false ) then ImGui_OpenPopup(ctx, 'sendspopup') end
  
  ImGui_SameLine(ctx)
  --ImGui_Text(ctx, '<None>')
  if ImGui_BeginPopup(ctx, 'sendspopup') then
    ImGui_SeparatorText(ctx, 'Available sends')
    for i = 1 , #DATA.available_sends do 
      if ImGui_Selectable(ctx, DATA.available_sends[i].name..'##send'..i) then 
      
        local desttr = GetTrackByGUID(DATA.available_sends[i].GUID)
        if desttr then 
          reaper.Undo_BeginBlock2( 0 )
          CreateTrackSend( DATA.tr_data.ptr, desttr ) 
          reaper.Undo_EndBlock2( 0, 'Send control - add send', 0xFFFFFFFF )
          DATA.upd = true 
          ImGui_EndMenu(ctx) 
          return 
        end
        
      end
    end
    ImGui_EndPopup(ctx)
  end
      
      
  
  
end
--------------------------------------------------------------------------------  
app_vrs = tonumber(reaper.GetAppVersion():match('[%d%.]+'))
if app_vrs < 7 then 
  MB('This script require REAPER 7.0+','',0)
 else
  if not APIExists( 'ImGui_GetVersion' ) then MB('This script require ReaImGui extension','',0) return end
  main()
end