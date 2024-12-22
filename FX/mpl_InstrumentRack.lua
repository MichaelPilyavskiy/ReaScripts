-- @description InstrumentRack
-- @version 2.05
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672 
-- @about Script for showing instruments in currently opened REAPER project
-- @changelog
--    # fixed "select and scroll to track on click"
--    + Allow to collect fx from multiple tabs
--    # change format of saving to project ext state, forward compatible
--    # UI: separate track/fx names, right click on fx name grabs only fx names
    
    
--NOT reaper NOT gfx


--------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
  if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end 
  local ImGui
  if APIExists('ImGui_GetBuiltinPath') then
    if not   reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
    package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
    ImGui = require 'imgui' '0.9'
   else 
    return reaper.MB('This script require ReaImGui extension 0.9+','',0) 
  end
  -------------------------------------------------------------------------------- 
  
-------------------------------------------------------------------------------- init external defaults 
EXT = {
  hiders5k = 0,
  scrolltotrackonedit = 0,
  floatchain = 0,
  
  showofflineattheend = 0, 
  collectsamefoldinstr = 0,
  collectalltabs = 0,
  
  searchfilter = '',
  usesecondcol = 0,
      }
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'MPL_InstrumentRack',
        UI_name = 'MPL Instrument Rack',
        
        upd = true, 
        perform_quere = {}, 
        }
        
-------------------------------------------------------------------------------- INIT UI locals
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
  UI.knob_handle = 0xc8edfa
  
  UI.butBg_red = 0xB30000
  UI.extinfo = {}
  UI.menuopened = false








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
    if not reaper.ImGui_ValidatePtr(ctx,'ImGui_Context*') then UI.MAIN_initcontext()  end
    ImGui.PushStyleVar(ctx, key, value, value2)
    UI.pushcnt = UI.pushcnt + 1
  else 
    ImGui.PushStyleColor(ctx, key, math.floor(value2*255)|(value<<8) )
    UI.pushcnt2 = UI.pushcnt2 + 1
  end 
end
-------------------------------------------------------------------------------- 
function UI.MAIN_draw()
  -- window_flags
    local window_flags = ImGui.WindowFlags_None
    --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
    --window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
    window_flags = window_flags | ImGui.WindowFlags_MenuBar
    --window_flags = window_flags | ImGui.WindowFlags_NoMove
    --window_flags = window_flags | ImGui.WindowFlags_NoResize
    window_flags = window_flags | ImGui.WindowFlags_NoCollapse
    --window_flags = window_flags | ImGui.WindowFlags_NoNav
    --window_flags = window_flags | ImGui.WindowFlags_NoBackground
    --window_flags = window_flags | ImGui.WindowFlags_NoDocking
    window_flags = window_flags | ImGui.WindowFlags_TopMost
    --if UI.disable_save_window_pos == true then window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings end
    --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument
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
    UI.MAIN_PushStyle(ImGui.StyleVar_GrabMinSize,10)
    UI.MAIN_PushStyle(ImGui.StyleVar_WindowMinSize,400,150)
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
    --UI.MAIN_PushStyle(ImGui.Col_BorderShadow,0xFFFFFF, 1, true)
    UI.MAIN_PushStyle(ImGui.Col_Button,UI.main_col, 0.3, true)
    UI.MAIN_PushStyle(ImGui.Col_ButtonActive,UI.main_col, 1, true)
    UI.MAIN_PushStyle(ImGui.Col_ButtonHovered,UI.but_hovered, 0.8, true)
    --UI.MAIN_PushStyle(ImGui.Col_CheckMark,UI.main_col, 0, true)
    --UI.MAIN_PushStyle(ImGui.Col_ChildBg,UI.main_col, 0, true)
    
    
    --Constant: Col_DockingEmptyBg
    --Constant: Col_DockingPreview
    --Constant: Col_DragDropTarget 
    UI.MAIN_PushStyle(ImGui.Col_DragDropTarget,0xFF1F5F, 0.6, true)
    UI.MAIN_PushStyle(ImGui.Col_FrameBg,0x1F1F1F, 0.7, true)
    UI.MAIN_PushStyle(ImGui.Col_FrameBgActive,UI.main_col, .9, true)
    UI.MAIN_PushStyle(ImGui.Col_FrameBgHovered,UI.main_col, 1, true)
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
    UI.MAIN_PushStyle(ImGui.Col_PopupBg,0x303030, 1, true)
    UI.MAIN_PushStyle(ImGui.Col_ResizeGrip,UI.main_col, 1, true)
    --Constant: Col_ResizeGripActive 
    UI.MAIN_PushStyle(ImGui.Col_ResizeGripHovered,UI.main_col, 1, true)
    --Constant: Col_ScrollbarBg
    --Constant: Col_ScrollbarGrab
    UI.MAIN_PushStyle(ImGui.Col_ScrollbarGrab,UI.main_col, 1, true)
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
    --UI.MAIN_PushStyle(ImGui.Col_TabUnfocusedActive,UI.main_col, 0.8, true)
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
    --ImGui.SetNextWindowPos(ctx, work_pos[1] + 20, work_pos[2] + 20, ImGui.Cond_FirstUseEver)
    local useini = ImGui.Cond_FirstUseEver
    ImGui.SetNextWindowSize(ctx, 550, 680, useini)
    
    
  -- init UI 
    ImGui.PushFont(ctx, DATA.font1)
    local visible,open = ImGui.Begin(ctx, DATA.UI_name, true, window_flags)
    if visible then
      DATA.display_w, DATA.display_h = ImGui.GetWindowSize(ctx) -- GetContentRegionAvail?

    -- calc stuff for childs
      UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
      local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
      local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
      UI.calc_itemH = calcitemh + frameh * 2
      UI.calc_itemH_small = math.floor(UI.calc_itemH*0.8)

    -- draw stuff
      UI.draw()

      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2)
      ImGui.End(ctx)
    else
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2)
    end

    ImGui.PopFont( ctx )
  
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
  
  if DATA.upd == true then 
    DATA:CollectData() 
  end 
  DATA.upd = false
  
  -- draw UI
  if not ctx then UI.MAIN_initcontext()  end
  UI.open = UI.MAIN_draw()
  
  -- data
  if UI.open then defer(UI.MAINloop) end
end
-------------------------------------------------------------------------------- 
function UI.SameLine(ctx) ImGui.SameLine(ctx) ImGui.SameLine(ctx)end
-------------------------------------------------------------------------------- 
function UI.MAIN_initcontext()  
  -- imGUI init
  ctx = ImGui.CreateContext(DATA.UI_name)
  -- fonts
  DATA.font1 = ImGui.CreateFont(UI.font, UI.font1sz) ImGui.Attach(ctx, DATA.font1)
  DATA.font2 = ImGui.CreateFont(UI.font, UI.font2sz) ImGui.Attach(ctx, DATA.font2)
  DATA.font3 = ImGui.CreateFont(UI.font, UI.font3sz) ImGui.Attach(ctx, DATA.font3)
  -- config
  ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
  ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort)
end
-------------------------------------------------------------------------------- 
function UI.MAIN()
  
  EXT:load() 
  UI.MAIN_initcontext() 
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
---------------------------------------------------
function VF_ReduceFXname(s) 
  local s_out = s:match('[%:%/%s]+(.*)')
  if not s_out then return s end
  s_out = s_out:gsub('%(.-%)','') 
  local pat_js = '.*[%/](.*)'
  if s_out:match(pat_js) then s_out = s_out:match(pat_js) end  
  if not s_out then return s else 
    if s_out ~= '' then return s_out else return s end
  end
end
------------------------------------------------------------------------------------------------------
function VF_Action(s, sectionID, ME )   
  if sectionID == 32060 and ME then 
    MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
   else
    Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
  end
end 
---------------------------------------------------
function VF_GetFXByGUID(GUID, tr, proj)
  if not GUID then return end
  local pat = '[%p]+'
  if not tr then
    for trid = 1, CountTracks(proj or 0) do
      local tr = GetTrack(proj or 0,trid-1)
      local fxcnt_main = TrackFX_GetCount( tr ) 
      local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
      for fx = 1, fxcnt do
        local fx_dest = fx
        if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
        if TrackFX_GetFXGUID( tr, fx-1) then 
          if TrackFX_GetFXGUID( tr, fx-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx-1 end 
        end
      end
    end  
   else
    if not (ValidatePtr2(proj or 0, tr, 'MediaTrack*')) then return end
    local fxcnt_main = TrackFX_GetCount( tr ) 
    local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
    for fx = 1, fxcnt do
      local fx_dest = fx
      if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
      if TrackFX_GetFXGUID( tr, fx-1) then 
        if TrackFX_GetFXGUID( tr, fx_dest-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx_dest-1 end 
      end
    end
  end    
end
--------------------------------------------------- 
function DATA.EnumeratePlugins()
  local plugs_data = {} 
  for i = 1, 10000 do
    local retval, name, ident = reaper.EnumInstalledFX( i-1 )
    if not retval then break end
    if name:match('i%:') then
      plugs_data[#plugs_data+1] = {name = name, 
                                   reduced_name = VF_ReduceFXname(name) ,
                                   ident = ident}
    end                                   
  end
  return plugs_data
end
--------------------------------------------------------------------------------  
function DATA.PluginsExtState_Read_sub(project)
  local retval, val = GetProjExtState( project, 'MPL_InstrumentRack', 'pluginsdata' )
  
  if not retval then return end
  for line in val:gmatch('[^\r\n]+') do 
    local t = {}
    local fxGUID, customname 
    if line:match('||') then
      for key in line:gmatch('[^||]+') do t[#t+1] = key end
      fxGUID   = t[1]
      if t[2] then customname = t[2]:gsub('\n','') end
     else
      for key in line:gmatch('[^|]+') do t[#t+1] = key end
      fxGUID   = t[1]
      if t[2] then customname = t[2]:gsub('\n','') end
    end
    
    if fxGUID and customname  then
      if not DATA.extplugins[fxGUID] then DATA.extplugins[fxGUID] = {} end
      DATA.extplugins[fxGUID].customname = customname
    end
  end
end
--------------------------------------------------------------------------------  
function DATA.PluginsExtState_Read()
  DATA.extplugins = {}
  
  if EXT.collectalltabs == 0 then
    DATA.PluginsExtState_Read_sub(-1)
   else
    for idx = 0, 100 do
      local reaproj = reaper.EnumProjects( idx )
      if not reaproj then break end
      DATA.PluginsExtState_Read_sub(reaproj)
    end
  end
  
end
--------------------------------------------------------------------------------  
function DATA.PluginsExtState_Write(project)
  local str = ''
  for fxGUID in pairs(DATA.extplugins) do
    local ret = VF_GetFXByGUID(fxGUID, nil, project)
    if ret==true then 
      str = str..fxGUID..'||'..DATA.extplugins[fxGUID].customname..'\n'  
    end
  end
  SetProjExtState( project, 'MPL_InstrumentRack', 'pluginsdata', str )
end
--------------------------------------------------------------------------------  
function DATA.CtrlsExtState_Read_sub(project)
  
  local legacyformat
  local retval, val = GetProjExtState( project, 'MPL_InstrumentRack', 'macro2' )
  
  --[[if not retval then 
    retval, val = GetProjExtState( project, 'MPL_InstrumentRack', 'macro' )
    if not retval then return end
    legacyformat = true
  end ]]
  
  for line in val:gmatch('[^\r\n]+') do 
    --local parent_GUID, child_GUID, paramidx = line:match('(%{.-%})%s+(%{.-%})%s+(%d+)')
    local fxGUID, paramidx = line:match('(%{.-%})%s+(%d+)') -- 2.04+  
    paramidx = tonumber(paramidx)
    if not DATA.extctrls[fxGUID] then DATA.extctrls[fxGUID] = {} end--[paramidx]={}

    -- pass params
    local ret, tr, fx = VF_GetFXByGUID(fxGUID,nil,project)
    if ret then  
      local paramval = TrackFX_GetParamNormalized( tr, fx, paramidx )
      local retval, paramname = reaper.TrackFX_GetParamName( tr, fx, paramidx )
      DATA.extctrls[fxGUID][paramidx] = {
        paramval=paramval,
        paramname=paramname,
        }
    end
  end
end
--------------------------------------------------------------------------------  
function DATA.CtrlsExtState_Read()
  DATA.extctrls = {}
  
  if EXT.collectalltabs == 0 then
    DATA.CtrlsExtState_Read_sub(-1)
   else
    for idx = 0, 100 do
      local reaproj = reaper.EnumProjects( idx )
      if not reaproj then break end
      DATA.CtrlsExtState_Read_sub(reaproj)
    end
  end
  
end
--------------------------------------------------------------------------------  
function DATA:CollectData_sub(project)
  for trid = 1, CountTracks(project) do
    local tr = GetTrack(project,trid-1)
    local parent = GetParentTrack( tr )
    local tr_solo = GetMediaTrackInfo_Value( tr, 'I_SOLO' )> 0
    local tr_mute = GetMediaTrackInfo_Value( tr, 'B_MUTE' )> 0
    local tr_automode = GetMediaTrackInfo_Value( tr, 'I_AUTOMODE' )
    local tr_GUID = reaper.GetTrackGUID( tr )
    local parenttr_GUID = tr_GUID
    if parent then parenttr_GUID = reaper.GetTrackGUID( parent) end
    for fx_id =1, TrackFX_GetCount( tr ) do
      local retval, buf = TrackFX_GetFXName( tr, fx_id-1, '' ) 
      if not buf:match('.-i%: ') then goto skipnextFX end 
      if EXT.hiders5k == 1 and (buf:lower():match('rs5k') or buf:lower():match('reasamplomatic5000') ) then goto skipnextFX end
      
      local retval, presetname = TrackFX_GetPreset( tr, fx_id-1, '' )
      local fxGUID = TrackFX_GetFXGUID( tr, fx_id-1)
      local retval, trname = reaper.GetTrackName( tr )
      local fxname = VF_ReduceFXname(buf)
      local txt_out =  fxname -- '['..trid..'] '..trname..' | '..
      
      local tr_col = GetTrackColor( tr )
      local r, g, b = reaper.ColorFromNative( tr_col )
      local tr_col = (r << 16) | (g << 8) | (b << 0) 
      local id = #DATA.plugins_data+1
      
      if not DATA.plugins_tree[parenttr_GUID] then DATA.plugins_tree[parenttr_GUID] = {} end
      DATA.plugins_tree[parenttr_GUID][#DATA.plugins_tree[parenttr_GUID]+1] = id
      DATA.plugins_data[id] = {
          name =    buf,
          fxGUID =  fxGUID,
          enabled = TrackFX_GetEnabled(tr, fx_id-1),
          online =  not TrackFX_GetOffline(tr, fx_id-1), 
          open =    TrackFX_GetOpen(tr, fx_id-1), 
          tr_solo = tr_solo,
          tr_mute = tr_mute,
          tr_col = tr_col,
          tr_GUID = tr_GUID,
          r=r,
          g=g,
          b=b,
          txt_out = txt_out, 
          presetname = presetname,
          parenttr_GUID=parenttr_GUID,
          project = project,
          tr=tr,
          trname=trname,
        }
      
      ::skipnextFX::
    end
  end
  
end
--------------------------------------------------------------------------------  
function DATA:CollectData()
  DATA.CtrlsExtState_Read()
  DATA.PluginsExtState_Read()

  DATA.plugins_data = {}
  DATA.plugins_tree = {}
  
  if EXT.collectalltabs == 0 then
    DATA:CollectData_sub(-1)
   else
    for idx = 0, 100 do
      local reaproj = reaper.EnumProjects( idx )
      if not reaproj then break end
      DATA:CollectData_sub(reaproj)
    end
  end
  
end
--------------------------------------------------------------------------------  
function main()
  DATA.plugins_data = DATA.EnumeratePlugins()
  UI.MAIN() 
end
--------------------------------------------------------------------------------  
function DATA.Plugin_params_set(plugdata,params)
  
  local ret, tr, id = VF_GetFXByGUID(plugdata.fxGUID,plugdata.tr,plugdata.project)
  if not ret then return end
  
  if EXT.scrolltotrackonedit == 1 then
    SetMixerScroll( tr )
    SetOnlyTrackSelected( tr )
    VF_Action(40913)--Track: Vertical scroll selected tracks into view 
  end  
  
  if params.online ~= nil then TrackFX_SetOffline(tr, id, params.online) end
  if params.bypass ~= nil then TrackFX_SetEnabled(tr, id, params.bypass) end
  if params.open ~= nil then  
    if params.open == false then 
      TrackFX_Show( tr, id, 2)
     else 
      if EXT.floatchain == 1 then TrackFX_Show( tr, id, 1 ) else TrackFX_Show( tr, id, 3 )end
    end 
  end
  
  if params.solo ~= nil then 
    local out_st = 0
    if not params.solo == false then out_st = 1 end
    CSurf_OnSoloChange(  tr, out_st )
  end
  if params.mute ~= nil then 
    local out_st = 0
    if not params.mute == false then out_st = 1 end
    CSurf_OnMuteChange(  tr, out_st )
  end
  if params.preset~=nil then
    TrackFX_NavigatePresets(tr, id, params.preset)
  end
  if (params.paramval ~= nil and params.paramidx ~= nil) then
    TrackFX_SetParamNormalized( tr, id, params.paramidx, params.paramval )
  end
  DATA.upd = true
end
--------------------------------------------------------------------------------  
function UI.draw_plugin_handlelatchstate(t)  
  -- handle mouse state
  if  ImGui.IsItemActivated( ctx ) then DATA.latchstate = t.paramval return end
  
  if  ImGui.IsItemActive( ctx ) then
    local x, y = ImGui.GetMouseDragDelta( ctx )
    local outval = DATA.latchstate - y/500
    outval = math.max(0,math.min(outval,1))
    local dx, dy = ImGui.GetMouseDelta( ctx )
    if dy~=0 then
      DATA.Plugin_params_set(t,{paramidx = t.paramidx, paramval = outval})
    end
  end
end
--------------------------------------------------------------------------------  
function UI.draw_plugin(plugdata,sec_col, islast)  
  local plugname = plugdata.name 
  if EXT.searchfilter ~= '' then 
    if plugname:lower():match(EXT.searchfilter:lower()) == nil then return end
  end
  local butw = 60
  local butw_low = math.floor(butw*2 - UI.spacingX)/3
  local fxGUID = plugdata.fxGUID
  --UI.MAIN_PushStyle(ImGui.Col_ChildBg,UI.windowBg_plugin, 0.2, true)
  UI.MAIN_PushStyle(ImGui.Col_ChildBg,plugdata.tr_col, 0.2, true)
  local sz_w,sz_h = 0,0
  if EXT.usesecondcol == 1 then 
    sz_w = DATA.display_w/2-UI.spacingX*2
  end
  if ImGui.BeginChild( ctx, plugname..'##'..fxGUID, sz_w,sz_h,  ImGui.ChildFlags_AutoResizeY|ImGui.ChildFlags_Border ) then
    
    
    
    -- online
    local online = 'Online' 
    if plugdata.online == false then online = 'Offline' UI.draw_setbuttoncolor(UI.main_col) else UI.draw_setbuttoncolor(UI.butBg_red) end 
    local ret = ImGui.Button( ctx, online..'##off'..fxGUID, butw ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Plugin_params_set(plugdata,{online= plugdata.online}) end
    
    -- bypass
    local bypass = 'Bypass' 
    if plugdata.enabled == true then bypass = 'Bypass' UI.draw_setbuttoncolor(UI.main_col) else UI.draw_setbuttoncolor(UI.butBg_green) end 
    local ret = ImGui.Button( ctx, bypass..'##byp'..fxGUID, butw ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Plugin_params_set(plugdata,{bypass= not plugdata.enabled}) end
    
    ImGui.Dummy(ctx,20,0) UI.SameLine(ctx)
    local txtout =  plugdata.txt_out 
    UI.draw_setbuttonbackgtransparent() 
    ImGui.Button( ctx, plugdata.trname)UI.SameLine(ctx)
    UI.draw_unsetbuttoncolor() 
    if DATA.extplugins[fxGUID] and DATA.extplugins[fxGUID].customname and DATA.extplugins[fxGUID].customname ~= 'nil' then txtout = DATA.extplugins[fxGUID].customname end
    if not (DATA.editfield and DATA.editfield == fxGUID) then ImGui.Text(ctx, txtout) end
    if ImGui.IsItemClicked( ctx,  ImGui.MouseButton_Right ) then DATA.editfield = fxGUID end
    
    if DATA.editfield == fxGUID then
      UI.SameLine(ctx)
      ImGui.SetKeyboardFocusHere( ctx )
      local retval, buf = ImGui.InputText( ctx,  '##'..fxGUID, txtout, ImGui.InputTextFlags_EnterReturnsTrue )
      if retval then 
        if not DATA.extplugins[fxGUID] then DATA.extplugins[fxGUID] = {} end
        if buf == '' then buf = 'nil' end
        DATA.extplugins[fxGUID].customname = buf
        DATA.PluginsExtState_Write(plugdata.project) 
        DATA.editfield = nil
      end
    end
    
    --
    ImGui.PushFont(ctx, DATA.font3)
    -- open
    if plugdata.open == true then UI.draw_setbuttoncolor(UI.butBg_green) else UI.draw_setbuttoncolor(UI.main_col) end 
    local ret = ImGui.Button( ctx, 'FX'..'##fx'..fxGUID, butw_low, UI.calc_itemH_small ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Plugin_params_set(plugdata,{open= not plugdata.open}) end

    -- solo
    if plugdata.tr_solo == true then UI.draw_setbuttoncolor(UI.butBg_green) else UI.draw_setbuttoncolor(UI.main_col) end 
    local ret = ImGui.Button( ctx, 'S'..'##s'..fxGUID, butw_low, UI.calc_itemH_small ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Plugin_params_set(plugdata,{solo = not plugdata.tr_solo}) end

    
    -- mute
    if plugdata.tr_mute == true then UI.draw_setbuttoncolor(UI.butBg_red) else UI.draw_setbuttoncolor(UI.main_col) end 
    local ret = ImGui.Button( ctx, 'M', butw_low, UI.calc_itemH_small ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Plugin_params_set(plugdata,{mute = not plugdata.tr_mute}) end
    
    ImGui.Dummy(ctx,20,0) UI.SameLine(ctx)
    
    -- preset
    UI.draw_setbuttoncolor(UI.main_col)
    local ret = ImGui.Button( ctx, '<'..'##presL'..fxGUID, 0, UI.calc_itemH_small )  UI.SameLine(ctx) if ret then DATA.Plugin_params_set(plugdata,{preset = -1}) end
    local ret = ImGui.Button( ctx, '>'..'##presR'..fxGUID, 0, UI.calc_itemH_small )  UI.SameLine(ctx) if ret then DATA.Plugin_params_set(plugdata,{preset = 1}) end
    ImGui.Text(ctx, plugdata.presetname)
    UI.draw_unsetbuttoncolor()
    
    -- add fx
    local ret = ImGui.Button( ctx, '+'..'##addparam'..fxGUID, 0, UI.calc_itemH)
    ImGui.SetItemTooltip(ctx, 'Add last touched parameter for instrument of FX')
    if ret ==true then DATA.Plugin_params_extset(plugdata) DATA.upd = true end
    
    if DATA.extctrls[fxGUID] then  
      
      UI.extinfo[fxGUID] = ""
      UI.SameLine(ctx) 
      UI.MAIN_PushStyle(ImGui.Col_SliderGrab,UI.main_col, 0, true)
      UI.MAIN_PushStyle(ImGui.Col_SliderGrabActive,UI.main_col, 0, true)
      UI.MAIN_PushStyle(ImGui.Col_FrameBgHovered,UI.main_col, .1, true)
      UI.MAIN_PushStyle(ImGui.Col_FrameBgActive,UI.main_col, .3, true)
      for paramID in pairs(DATA.extctrls[fxGUID]) do
        -- define
        local butid = '##ext'..fxGUID..paramID
        local retval, v = ImGui.VSliderDouble( ctx, butid,  UI.calc_itemH,  UI.calc_itemH, DATA.extctrls[fxGUID][paramID].paramval, 0, 1, '' )
        
        local plugdata = DATA.extctrls[fxGUID][paramID]
        plugdata.fxGUID = fxGUID
        plugdata.paramidx = paramID
        UI.draw_plugin_handlelatchstate(plugdata)  
        
        -- tooltip
        if ImGui.IsItemHovered( ctx ) or ImGui.IsItemActive( ctx )  then
          UI.extinfo[fxGUID] = DATA.extctrls[fxGUID][paramID].paramname  
        end
        if ImGui.IsItemHovered( ctx )  then
          -- delete/alt click
          if  ImGui.IsKeyPressed( ctx,   ImGui.Key_Delete, false ) then
            --[[or 
            ImGui.IsKeyPressed( ctx,  reaper.ImGui_Mod_Alt(), false ) or  
            ImGui.IsKeyPressed( ctx,  reaper.ImGui_Key_LeftAlt(), false ) or  
            ImGui.IsKeyPressed( ctx,  reaper.ImGui_Key_RightAlt(), false ) ]]  
            DATA.extctrls[fxGUID][paramID] = nil
            DATA.CtrlsExtState_Write(plugdata.project)
            DATA.upd = true
          end
        end
        if DATA.extctrls[fxGUID][paramID] then UI.draw_knob(DATA.extctrls[fxGUID][paramID].paramval) end
        UI.SameLine(ctx)
        ::skipnextctrl::
      end
      ImGui.PopStyleColor(ctx,4)UI.pushcnt2 = UI.pushcnt2 - 4
      
      ImGui.Text(ctx,UI.extinfo[fxGUID])
    end
    
    ImGui.PopFont(ctx)
    ImGui.EndChild( ctx )
  end
  if EXT.usesecondcol == 1 then
    if sec_col  then UI.SameLine(ctx) end
  end
end
-------------------------------------------------------------------------------- 
function UI.draw_knob(val) 
  if not val then return end
  --local draw_list = ImGui.GetWindowDrawList(ctx)
  local draw_list = ImGui.GetForegroundDrawList(ctx)
  if UI.menuopened == true then 
    return 
  end
  ImGui.SameLine( ctx, 0, 0 )
  local curposx, curposy = ImGui.GetCursorScreenPos(ctx)
  local knob_w = ImGui.CalcItemWidth( ctx )
  curposx = curposx - UI.calc_itemH
  
  local thicknessIn = 1
  local roundingIn = 0
  local col_rgba = 0xF0F0F0FF
  local p_min_x =curposx
  local p_min_y = curposy
  local p_max_x = curposx + UI.calc_itemH
  local p_max_y  =curposy + UI.calc_itemH
  
  
  local radius = math.floor(UI.calc_itemH/2)
  local radius_draw = math.floor(0.9 * radius)
  local center_x = curposx + radius
  local center_y = curposy + radius
  --ImGui.DrawList_AddRect( draw_list, p_min_x, p_min_y, p_max_x, p_max_y, col_rgba, roundingIn,  ImGui.DrawFlags_None, thicknessIn )
  --ImGui.DrawList_AddCircle(draw_list, center_x, center_y, radius, 0xF0F0F0FF, 0,1.0)
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
end
-------------------------------------------------------------------------------- 
function DATA.Plugin_params_extset(plugdata) 
  local retval, trackidx, itemidx, takeidx, fxidx, parm = GetTouchedOrFocusedFX( 0 )
  if retval ~= true then return end
  
  if trackidx ==-1 then return end
  if itemidx ~=-1 then return end
  if fxidx&0x2000000==0x2000000 then return end
  if fxidx&0x1000000==0x1000000 then return end
  
  local tr = GetTrack(plugdata.project,trackidx)
  local tr_GUID = GetTrackGUID( tr )
  if tr_GUID ~= plugdata.tr_GUID then return end
  
  local fxGUID = reaper.TrackFX_GetFXGUID( tr, fxidx )
  if not DATA.extctrls then DATA.extctrls = {} end
  if not DATA.extctrls[fxGUID] then DATA.extctrls[fxGUID] ={} end
  DATA.extctrls[fxGUID][parm] = {fxGUID=fxGUID,paramidx=parm,plugdata.project}
  DATA.CtrlsExtState_Write(plugdata.project)
end

--------------------------------------------------------------------------------  
function DATA.CtrlsExtState_Write(project)
  local str = ''
  for fxGUID in pairs(DATA.extctrls) do
    local ret = VF_GetFXByGUID(fxGUID, nil, project)
    if ret==true then 
      for paramidx in pairs(DATA.extctrls[fxGUID]) do 
        str = str..fxGUID..' '..paramidx..'\n' 
      end 
    end
  end
  
  SetProjExtState( project, 'MPL_InstrumentRack', 'macro2', str )
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttonbackgtransparent() 
    UI.MAIN_PushStyle(ImGui.Col_Button,0xFFFFFF, 0, true)
    UI.MAIN_PushStyle(ImGui.Col_ButtonActive,0xFFFFFF, 0, true)
    UI.MAIN_PushStyle(ImGui.Col_ButtonHovered,0xFFFFFF, 0, true)
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col) 
    UI.MAIN_PushStyle(ImGui.Col_Button,col, 0.7, true)
    UI.MAIN_PushStyle(ImGui.Col_ButtonActive,col, 1, true)
    UI.MAIN_PushStyle(ImGui.Col_ButtonHovered,col, 0.8, true)
end
--------------------------------------------------------------------------------  
function UI.draw_unsetbuttoncolor() 
  ImGui.PopStyleColor(ctx,3)
  UI.pushcnt2 = UI.pushcnt2 -3
end
--------------------------------------------------------------------------------  
function UI.draw() 
  UI.menuopened = false
  if ImGui.BeginMenuBar(ctx) then
    if ImGui.MenuItem(ctx, 'Add FX') then VF_Action(40701) end
    if ImGui.BeginMenu(ctx,'Options') then
      UI.menuopened = true
      ImGui.SeparatorText(ctx, 'General')
      local ret = ImGui.MenuItem(ctx, 'Select and scroll to track on click', nil, EXT.scrolltotrackonedit == 1) if ret then DATA.upd = true EXT.scrolltotrackonedit=EXT.scrolltotrackonedit~1 EXT:save() end
      local ret = ImGui.MenuItem(ctx, 'Show FX chain instead floating FX', nil, EXT.floatchain == 1) if ret then DATA.upd = true EXT.floatchain=EXT.floatchain~1 EXT:save() end
      local ret = ImGui.MenuItem(ctx, 'Hide RS5k instances', nil, EXT.hiders5k == 1) if ret then DATA.upd = true EXT.hiders5k=EXT.hiders5k~1 EXT:save() end
      local ret = ImGui.MenuItem(ctx, 'Collect instruments from all project tabs', nil, EXT.collectalltabs == 1) if ret then DATA.upd = true EXT.collectalltabs=EXT.collectalltabs~1 EXT:save() end
      --local ret = ImGui.MenuItem(ctx, 'Use second column', nil, EXT.usesecondcol == 1) if ret then DATA.upd = true EXT.usesecondcol=EXT.usesecondcol~1 EXT:save() end
      --local ret = ImGui.MenuItem(ctx, 'Sorting', nil, nil, false)
      ImGui.SeparatorText(ctx, 'Sorting')
      local ret = ImGui.MenuItem(ctx, 'Show offline FX at the end of list', nil, EXT.showofflineattheend == 1) if ret then
        DATA.upd = true 
        EXT.showofflineattheend=EXT.showofflineattheend~1 
        if EXT.showofflineattheend ==1 then EXT.collectsamefoldinstr =0 end 
        EXT:save() 
      end
      local ret = ImGui.MenuItem(ctx, 'Show folders as tree', nil, EXT.collectsamefoldinstr == 1) if ret then
        DATA.upd = true 
        EXT.collectsamefoldinstr=EXT.collectsamefoldinstr~1 
        if EXT.collectsamefoldinstr ==1 then EXT.showofflineattheend =0 end 
        EXT:save() 
      end
      ImGui.EndMenu(ctx)
    end
    
    local retval, search = ImGui.InputText(ctx, '##search', EXT.searchfilter, ImGui.InputTextFlags_AutoSelectAll)--|ImGui.InputTextFlags_EnterReturnsTrue
    if retval then 
      EXT.searchfilter = search
      EXT:save() 
    end
    ImGui.EndMenuBar(ctx)
  end
  
  -- normal sorting by found instrument
  if EXT.showofflineattheend == 0 then
    if EXT.collectsamefoldinstr == 0 then 
      local plugcnt = #DATA.plugins_data 
      for i = 1, plugcnt do UI.draw_plugin(DATA.plugins_data[i]) end
    end
   else
    local plugcnt = #DATA.plugins_data 
    for i = 1, plugcnt do 
      if DATA.plugins_data[i].online == true then 
        UI.draw_plugin(DATA.plugins_data[i], (i%2)==1,i==plugcnt) 
      end 
    end
    if ImGui.TreeNode(ctx, '[Offline plugins]##off', ImGui.TreeNodeFlags_None) then--ImGui.TreeNodeFlags_DefaultOpen) then
      for i = 1, plugcnt do if DATA.plugins_data[i].online == false then UI.draw_plugin(DATA.plugins_data[i]) end end
      ImGui.TreePop(ctx)
    end
  end
  
  if EXT.collectsamefoldinstr == 1 then
    for partrGUID in pairs(DATA.plugins_tree) do
      if ImGui.TreeNode(ctx, '##'..partrGUID, ImGui.TreeNodeFlags_DefaultOpen) then
        for j = 1, #DATA.plugins_tree[partrGUID] do   
          local id = DATA.plugins_tree[partrGUID][j]
          UI.draw_plugin(DATA.plugins_data[id]) 
        
        end 
        ImGui.TreePop(ctx)
      end
    end
  end
end




main()