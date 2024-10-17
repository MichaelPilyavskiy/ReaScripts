-- @description Return control
-- @version 1.12
-- @author MPL
-- @about Controlling send folder
-- @website http://forum.cockos.com/showthread.php?t=165672 
-- @changelog
--    # fix hidden slider steal cursor focus


    
--NOT reaper NOT gfx

--------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
  if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end 

  if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension 0.9+','',0) end
  package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  local ImGui = require 'imgui' '0.9.3'
  
-------------------------------------------------------------------------------- init external defaults 
EXT = {
        
      }
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'MPL_Return Control',
        UI_name = 'MPL Return Control',
        
        upd = true, 
        perform_quere = {}, 
        
        custom_fader_scale_lim = 0.8,
        custom_fader_coeff = 50,
        
        send_folder_names = 'send',
        find_plugin = {enabled=false},
        lastfilter = '',
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
    UI.MAIN_PushStyle(ImGui.StyleVar_FramePadding,5,5) 
    UI.MAIN_PushStyle(ImGui.StyleVar_CellPadding,UI.spacingX, UI.spacingY) 
    UI.MAIN_PushStyle(ImGui.StyleVar_ItemSpacing,UI.spacingX, UI.spacingY)
    UI.MAIN_PushStyle(ImGui.StyleVar_ItemInnerSpacing,4,0)
    UI.MAIN_PushStyle(ImGui.StyleVar_IndentSpacing,20)
    UI.MAIN_PushStyle(ImGui.StyleVar_ScrollbarSize,14)
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
    
    UI.MAIN_PushStyle(ImGui.Col_PlotHistogram,UI.butBg_green, 1, true) 
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
    UI.MAIN_PushStyle(ImGui.Col_SliderGrab,UI.butBg_green, 0.7, true) 
    UI.MAIN_PushStyle(ImGui.Col_SliderGrabActive,UI.butBg_green, 1, true) 
    --Constant: Col_SliderGrabActive
    UI.MAIN_PushStyle(ImGui.Col_Tab,UI.main_col, 0.37, true) 
    --UI.MAIN_PushStyle(ImGui.Col_TabActive,UI.main_col, 1, true) 
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
    local work_pos = {ImGui.Viewport_GetWorkPos(main_viewport)}
    --x, y = reaper.GetMousePosition()
    ImGui.SetNextWindowPos(ctx, work_pos[1] + 20, work_pos[2] + 20, ImGui.Cond_FirstUseEver)
    --ImGui.SetNextWindowPos(ctx, x+ 20, y+ 20, ImGui.Cond_Appearing())
    local useini = ImGui.Cond_FirstUseEver
    ImGui.SetNextWindowSize(ctx, 550, 680, useini)
    
    
  -- init UI 
    ImGui.PushFont(ctx, DATA.font1) 
    
    
    local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) 
    if rv then
      local Viewport = ImGui.GetWindowViewport(ctx)
      --DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport)
      DATA.display_w, DATA.display_h = ImGui.GetWindowContentRegionMax(ctx)
      
    -- calc stuff for childs
      UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
      local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
      local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test', nil, nil, false, -1.0)
      UI.calc_itemH = calcitemh + frameh * 2
      UI.calc_itemH_small = math.floor(UI.calc_itemH*0.8)
      
    -- draw stuff
      UI.draw() 
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
      ImGui.Dummy(ctx,0,0)
      
      if DATA.find_plugin.forcescrolltonewsend and os.clock()-DATA.find_plugin.forcescrolltonewsend>0.4 then  
       reaper.ImGui_SetScrollY( ctx, reaper.ImGui_GetScrollMaxY( ctx ) )
        DATA.find_plugin.forcescrolltonewsend = nil
      end
      
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
  
  DATA.CollectData_GetPeaks()
  
  -- draw UI
  UI.open = UI.MAIN_draw(true) 
  
  -- data
  if UI.open and not DATA.triggerstopdefer then defer(UI.MAINloop) end
end
-------------------------------------------------------------------------------- 
function UI.SameLine(ctx) ImGui.SameLine(ctx) ImGui.SameLine(ctx)end
--------------------------------------------------- 
function DATA.EnumeratePlugins()
  DATA.plugs_data = {} 
  for i = 1, 10000 do
    local retval, name, ident = reaper.EnumInstalledFX( i-1 )
    if not retval then break end
    if not name:match('i%:') then
      DATA.plugs_data[#DATA.plugs_data+1] = {name = name, 
                                   reduced_name = VF_ReduceFXname(name) ,
                                   ident = ident}
    end                                   
  end
  return plugs_data
end
---------------------------------------------------
function VF_ReduceFXname(s) 
  for man in s:gmatch('%(.-%)') do
    if man:len() > 1 and not (man:match('64') or man:match('86')) then
      s=s:gsub('%('..man..'%)', '')
    end
  end
  return s
  --[[local s_out = s:match('[%:%/%s]+(.*)')
  if not s_out then return s end
  s_out = s_out:gsub('%(.-%)','') 
  local pat_js = '.*[%/](.*)'
  if s_out:match(pat_js) then s_out = s_out:match(pat_js) end  
  if not s_out then 
   return s 
  else 
    if s_out ~= '' then return s_out else return s end
  end]]
end
-------------------------------------------------------------------------------- 
function UI.MAIN()
  DATA.EnumeratePlugins()
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
  local SCC =  GetProjectStateChangeCount( 0 ) 
  if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true  end  DATA.upd_lastSCC = SCC
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
    if level>=0 and i~= idx then 
      local GUID = reaper.GetTrackGUID( tr ) 
      local D_VOL =  GetMediaTrackInfo_Value( tr, 'D_VOL' )
      local B_MUTE =  GetMediaTrackInfo_Value( tr, 'B_MUTE' )
      local I_SOLO =  GetMediaTrackInfo_Value( tr, 'I_SOLO' )
      
      local voldb = WDL_VAL2DB(D_VOL)
      local voldbformat = string.format("%.03f dB",voldb) 
      local D_VOL_scaled = DATA.Convert_Val2Fader(D_VOL)
      
      
      DATA.available_sends[#DATA.available_sends+1] = 
        {  GUID = GUID,
          name = trname,
          ptr = tr,
          sendidx=idx,
          D_VOL=D_VOL,
          D_VOLdb = voldb,
          D_VOLdb_format = voldbformat,
          D_VOL_scaled = D_VOL_scaled,
          B_MUTE=B_MUTE,
          I_SOLO=I_SOLO,
          peaks = {}
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
  DATA:CollectData_GetAvailableSends()
  
end
--------------------------------------------------------------------------------  
function DATA:CollectData_GetPeaks()
  for i = 1, #DATA.available_sends do
    local tr = DATA.available_sends[i].ptr
    if tr and ValidatePtr(tr, 'MediaTrack*') then  
      local peak = Track_GetPeakInfo( tr, 0 )
      DATA.available_sends[i].peaks[#DATA.available_sends[i].peaks +1 ] = peak
      if #DATA.available_sends[i].peaks>10 then table.remove(DATA.available_sends[i].peaks,1) end
      local rms = 0
      for j= 1, #DATA.available_sends[i].peaks do rms = rms + DATA.available_sends[i].peaks[j]  end 
      local peaksrms = rms/#DATA.available_sends[i].peaks
      if DATA.available_sends[i].peaksrms_scaled then peaksrms_scaled = DATA.available_sends[i].peaksrms_scaled end
      DATA.available_sends[i].peaksrms_scaled = DATA.Convert_Val2Fader(peaksrms)
      if peaksrms_scaled then DATA.available_sends[i].peaksrms_scaled = (DATA.available_sends[i].peaksrms_scaled + peaksrms_scaled) /2 end
    end
  end
end
--------------------------------------------------------------------------------  
function main()
  UI.MAIN() 
end
--------------------------------------------------------------------------------  
function DATA.Send_params_set(send_t, param)
  if not param then return end
  if param.mute~= nil then SetMediaTrackInfo_Value( send_t.ptr, 'B_MUTE', param.mute) end
  if param.solo~= nil then SetMediaTrackInfo_Value( send_t.ptr, 'I_SOLO', param.solo) end
  if param.vol_lin~= nil then SetMediaTrackInfo_Value( send_t.ptr, 'D_VOL', DATA.Convert_Fader2Val(param.vol_lin)) end
  if param.vol_dB~= nil then SetMediaTrackInfo_Value( send_t.ptr, 'D_VOL', WDL_DB2VAL(param.vol_dB)) end
  
  DATA.upd = true
end
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
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
  local ctrlw = math.floor((DATA.display_w-UI.calc_xoffset*10)/8)
  local slider_w = DATA.display_w-UI.calc_xoffset*4
  if ImGui.BeginChild( ctx, send_t.name..'##'..send_t.GUID, 0, 0,  ImGui.ChildFlags_AutoResizeY|ImGui.ChildFlags_Border, 0 ) then
    
    ImGui.PushFont(ctx, DATA.font3) 
    
    -- mute
    if send_t.B_MUTE==0 then UI.draw_setbuttoncolor(UI.main_col) else UI.draw_setbuttoncolor(UI.butBg_red) end 
    local ret = ImGui.Button( ctx, 'M##off'..send_t.GUID, ctrlw, but_h ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then 
      local set = 1
      if send_t.B_MUTE>=1 then set = 0 end
      DATA.Send_params_set(send_t,{mute= set})
    end
    
    -- solo
    if send_t.I_SOLO==0 then UI.draw_setbuttoncolor(UI.main_col) else UI.draw_setbuttoncolor(UI.butBg_green) end 
    local ret = ImGui.Button( ctx, 'S##off'..send_t.GUID, ctrlw, but_h ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then 
      local set = 1
      if send_t.I_SOLO>=1 then set = 0 end
      DATA.Send_params_set(send_t,{solo= set})
    end

    -- FX
    UI.draw_setbuttoncolor(UI.main_col) 
    local ret = ImGui.Button( ctx, 'FX##off'..send_t.GUID, ctrlw, but_h ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then 
      TrackFX_Show( send_t.ptr, 0,1 )
    end
    
    -- goto
    UI.draw_setbuttoncolor(UI.main_col) 
    local ret = ImGui.Button( ctx, 'Select##off'..send_t.GUID, ctrlw*2, but_h ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then 
      reaper.SetOnlyTrackSelected( send_t.ptr)
      Action(40913)
    end 
    
    -- readout
    --if send_t.D_VOLdb > -6 and send_t.D_VOLdb < 6 then step, step2 = 0.5, 0.2 end
    ImGui.SetNextItemWidth( ctx, ctrlw*3+UI.calc_xoffset*3 )
    local step, step2 = 0.5, 0.2
    local retval, v = ImGui.InputDouble( ctx, '##slidervol2'..send_t.sendidx, send_t.D_VOLdb, step, step2, "%.01f dB", ImGui.InputTextFlags_CharsDecimal|ImGui.InputTextFlags_EnterReturnsTrue ) 
    if retval then 
      v = VF_lim(v, -150,12)
      DATA.Send_params_set(send_t, {vol_dB=v}) 
    end 
    ImGui.PopFont(ctx) 
    
    
    local curposX, curposY = ImGui.GetCursorPos(ctx)
    ImGui.SetCursorPos(ctx, curposX, curposY)
    local curposXabs, curposYabs = ImGui.GetCursorScreenPos(ctx)
    ImGui.SetNextItemWidth( ctx, slider_w )
    
    -- slider
    local sliderX, sliderY, sliderW, sliderH = 0,0,slider_w,UI.calc_itemH
    if send_t.rename_input_mode ~= true then --ImGui.BeginDisabled( ctx, true )  end 
      local retval, v = ImGui.SliderDouble(ctx, '##slidervol'..send_t.GUID, send_t.D_VOL_scaled, 0, 1, '', ImGui.SliderFlags_None| ImGui.SliderFlags_NoInput)
      sliderX, sliderY = ImGui.GetItemRectMin(ctx)
      sliderW, sliderH = ImGui.GetItemRectSize(ctx)
      if retval then DATA.Send_params_set(send_t, {vol_lin=v}) end UI.SameLine(ctx) 
      --if send_t.rename_input_mode == true then ImGui.EndDisabled( ctx) end
      if ImGui.IsItemHovered( ctx ) then DATA.slidernavigated = true end
      if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right) then send_t.rename_input_mode = true end
    end
    
    -- name edit field
    if send_t.rename_input_mode == true then
      ImGui.SetCursorPos(ctx, curposX, curposY)
      ImGui.SetKeyboardFocusHere( ctx, 0 )
      local retval, buf = ImGui.InputText( ctx, '##renametrdest'..send_t.GUID, send_t.name, ImGui.InputTextFlags_EnterReturnsTrue|ImGui.InputTextFlags_AutoSelectAll )
      if retval then
        local tr = VF_GetTrackByGUID(send_t.GUID)
        if tr then 
          if buf:lower():match('#fx') then
            local retfx, fxname0 = reaper.TrackFX_GetFXName( tr, 0 )
            if retfx then
              local fxname = VF_ReduceFXname(fxname0)
              if fxname: match('[%a%d]+%:%s(.*)') then fxname = fxname: match('[%a%d]+%:%s(.*)') end
              buf = buf:gsub('#fx', fxname)
            end
          end
          
          if buf:lower():match('#preset') then
            local retpres, presetname = reaper.TrackFX_GetPreset( tr, 0 )
            if retpres then
              buf = buf:gsub('#preset', presetname)
            end
          end
          
          
          
          GetSetMediaTrackInfo_String( tr, 'P_NAME', buf, true ) 
        end
        send_t.rename_input_mode = nil
        DATA.upd = true
      end
    end
    
    -- txt name
    --ImGui.Text(ctx, send_t.D_VOLdb_format ) 
    ImGui.SetCursorPos(ctx, curposX, curposY)
    ImGui.Indent(ctx) 
    if not send_t.rename_input_mode then ImGui.Text(ctx, send_t.name) end
    
    ImGui.SetCursorPos(ctx, curposX, curposY)
    if send_t.peaksrms_scaled then
      ImGui.SetCursorPosY(ctx, curposY+sliderH)
      ImGui.ProgressBar(ctx, send_t.peaksrms_scaled or 0, slider_w, 2,'')
    end
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
---------------------------------------------------
function Action(s,section,midieditor,flag,proj) 
  if not flag then flag = 0 end 
  if not proj then proj = 0 end 
  if not section then 
    Main_OnCommandEx(NamedCommandLookup(s), flag, proj) 
   elseif section == 32060 and midieditor then -- midi ed
    MIDIEditor_OnCommand( midieditor, NamedCommandLookup(s) )
  end
end
--------------------------------------------------------------------------------  
function UI.draw_search() 
  local retval, buf = reaper.ImGui_InputText( ctx, '##labinput', DATA.lastfilter, ImGui.InputTextFlags_None) UI.SameLine(ctx) 
  if ImGui.Button(ctx, 'X', 0,0) then 
    DATA.find_plugin.enabled = false
    DATA.find_plugin.first_time = nil
  end
  if retval and buf~= '' then 
    DATA.plugs_data_filtered = {}
    DATA.lastfilter = buf
    local buf = buf:gsub('[%p%s]+',''):lower()
    for i = 1, #DATA.plugs_data do
      local fxname =  DATA.plugs_data[i].name:lower():gsub('[%p%s]+','')
      if fxname:match(buf) then
        DATA.plugs_data_filtered[#DATA.plugs_data_filtered+1] = DATA.plugs_data[i]
      end
    end
  end
  
  if DATA.plugs_data_filtered then
    for i = 1, #DATA.plugs_data_filtered do
      if ImGui.Button(ctx, DATA.plugs_data_filtered[i].reduced_name..'##results'..i) then
        
        DATA.find_plugin.enabled = false
        DATA.find_plugin.first_time = nil
        DATA.lastfilter = ''
        local fxadd = DATA.plugs_data_filtered[i].name
        local trname = DATA.plugs_data_filtered[i].name
        if fxadd:match('AU%:') then
          fxadd = DATA.plugs_data_filtered[i].ident
        end
        DATA:Action_AddSend(fxadd,trname)
        
        
        DATA.find_plugin.forcescrolltonewsend = os.clock()
        
        return 
      end
    end
  end 
  
  
end
--------------------------------------------------------------------------------  
function UI.draw()  
  if DATA.find_plugin.enabled == true then 
    if not DATA.find_plugin.first_time then
      reaper.ImGui_SetKeyboardFocusHere( ctx, 0 )
      DATA.find_plugin.first_time = true
    end
    UI.draw_search() 
    return 
  end
  local sendcnt= #DATA.available_sends
  DATA.slidernavigated = false
  for i = 1, sendcnt do  UI.draw_send(DATA.available_sends[i])  end 
  if reaper.ImGui_IsMouseClicked( ctx,  ImGui.MouseButton_Right, 1 ) and not DATA.slidernavigated then 
    DATA.find_plugin = {enabled = true} 
  end
  
end
-------------------------------------------------------------------------------- 
function DATA:CollectData_GetLastAvailableSend()
  local ret, tr, idx = DATA:CollectData_GetAvailableSends_GetFolder()
  if not ret then return end
  local level = 0
  for i = idx, CountTracks(0) do
    local tr = GetTrack(0,i-1)
    level = level + GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH'  ) 
    if level == 0 then 
      return true, i-1
    end
  end
end
--------------------------------------------------------------------------------  
function DATA:Action_AddSend(fxnameadd, fxname)
  local ret, idx = DATA:CollectData_GetLastAvailableSend()
  if not ret then MB('Available send not found', 'Error',0)return end 
  local tr = GetTrack(0,idx)
  local level = GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH'  ) 
  local I_CUSTOMCOLOR = GetMediaTrackInfo_Value( tr, 'I_CUSTOMCOLOR'  ) 
  InsertTrackAtIndex( idx+1, false )
  local newtr = GetTrack(0,idx+1)
  GetSetMediaTrackInfo_String( newtr, 'P_NAME', fxname, true )
  SetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH',level+1  ) 
  SetMediaTrackInfo_Value( newtr, 'I_FOLDERDEPTH',level  ) 
  SetMediaTrackInfo_Value( newtr, 'I_CUSTOMCOLOR',I_CUSTOMCOLOR  ) 
  TrackFX_AddByName( newtr, fxnameadd, false, 1 )
  TrackFX_Show( newtr, 0, 3 )
end
--------------------------------------------------------------------------------  

  main()