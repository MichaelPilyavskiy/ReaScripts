-- @description InstrumentRack
-- @version 2.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672 
-- @about Script for showing instruments in currently opened REAPER project
-- @changelog
--  # fix parsing instruments
    
    
--NOT reaper NOT gfx


-------------------------------------------------------------------------------- init external defaults 
EXT = {
  hiders5k = 0,
  scrolltotrackonedit = 0,
  floatchain = 0,
  
  showofflineattheend = 0, 
  collectsamefoldinstr = 0,
  
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
    ImGui_PushStyleVar(ctx, key, value, value2)
    UI.pushcnt = UI.pushcnt + 1
  else 
    ImGui_PushStyleColor(ctx, key, math.floor(value2*255)|(value<<8) )
    UI.pushcnt2 = UI.pushcnt2 + 1
  end 
end
-------------------------------------------------------------------------------- 
function UI.MAIN_draw(open) 
  
  if not (ctx and  ImGui_ValidatePtr( ctx, 'ImGui_Context*' ) ) then return end
  -- window_flags
    local window_flags = ImGui_WindowFlags_None()
    --window_flags = window_flags | ImGui_WindowFlags_NoTitleBar()
    --window_flags = window_flags | ImGui_WindowFlags_NoScrollbar()
    window_flags = window_flags | ImGui_WindowFlags_MenuBar()
    --window_flags = window_flags | ImGui_WindowFlags_NoMove()
    --window_flags = window_flags | ImGui_WindowFlags_NoResize()
    window_flags = window_flags | ImGui_WindowFlags_NoCollapse()
    --window_flags = window_flags | ImGui_WindowFlags_NoNav()
    --window_flags = window_flags | ImGui_WindowFlags_NoBackground()
    --window_flags = window_flags | ImGui_WindowFlags_NoDocking()
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
    UI.MAIN_PushStyle(ImGui_StyleVar_FramePadding(),5,5) 
    UI.MAIN_PushStyle(ImGui_StyleVar_CellPadding(),UI.spacingX, UI.spacingY) 
    UI.MAIN_PushStyle(ImGui_StyleVar_ItemSpacing(),UI.spacingX, UI.spacingY)
    UI.MAIN_PushStyle(ImGui_StyleVar_ItemInnerSpacing(),4,0)
    UI.MAIN_PushStyle(ImGui_StyleVar_IndentSpacing(),20)
    UI.MAIN_PushStyle(ImGui_StyleVar_ScrollbarSize(),14)
  -- size
    UI.MAIN_PushStyle(ImGui_StyleVar_GrabMinSize(),10)
    UI.MAIN_PushStyle(ImGui_StyleVar_WindowMinSize(),400,150)
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
    
    
    --Constant: Col_DockingEmptyBg
    --Constant: Col_DockingPreview
    --Constant: Col_DragDropTarget 
    UI.MAIN_PushStyle(ImGui_Col_DragDropTarget(),0xFF1F5F, 0.6, true)
    UI.MAIN_PushStyle(ImGui_Col_FrameBg(),0x1F1F1F, 0.7, true)
    UI.MAIN_PushStyle(ImGui_Col_FrameBgActive(),UI.main_col, .9, true)
    UI.MAIN_PushStyle(ImGui_Col_FrameBgHovered(),UI.main_col, 1, true)
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
    UI.MAIN_PushStyle(ImGui_Col_PopupBg(),0x303030, 1, true) 
    UI.MAIN_PushStyle(ImGui_Col_ResizeGrip(),UI.main_col, 1, true) 
    --Constant: Col_ResizeGripActive 
    UI.MAIN_PushStyle(ImGui_Col_ResizeGripHovered(),UI.main_col, 1, true) 
    --Constant: Col_ScrollbarBg
    --Constant: Col_ScrollbarGrab
    UI.MAIN_PushStyle(ImGui_Col_ScrollbarGrab(),UI.main_col, 1, true) 
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
    --ImGui_SetNextWindowPos(ctx, work_pos[1] + 20, work_pos[2] + 20, ImGui_Cond_FirstUseEver())
    local useini = ImGui_Cond_FirstUseEver()
    ImGui_SetNextWindowSize(ctx, 550, 680, useini)
    
    
  -- init UI 
    ImGui_PushFont(ctx, DATA.font1) 
    rv,open = ImGui_Begin(ctx, DATA.UI_name, open, window_flags) if not rv then return open end  
    local ImGui_Viewport = ImGui_GetWindowViewport(ctx)
    DATA.display_w, DATA.display_h = ImGui_Viewport_GetSize(ImGui_Viewport)
    
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
  UI.open = UI.MAIN_draw(true) 
  
  -- data
  if UI.open then defer(UI.MAINloop) end
end
-------------------------------------------------------------------------------- 
function UI.SameLine(ctx) reaper.ImGui_SameLine(ctx) reaper.ImGui_SameLine(ctx)end
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
      local tr = GetTrack(0,trid-1)
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
function DATA.PluginsExtState_Read()
  DATA.extplugins = {}
  local retval, val = GetProjExtState( 0, 'MPL_InstrumentRack', 'pluginsdata' )
  if not retval then return end
  for line in val:gmatch('[^\r\n]+') do 
    local t = {}
    for key in line:gmatch('[^|]+') do t[#t+1] = key end
    local fxGUID   = t[1]
    local customname  = t[2]:gsub('\n','')
    if not DATA.extplugins[fxGUID] then DATA.extplugins[fxGUID] = {} end
    DATA.extplugins[fxGUID].customname = customname
  end
end
--------------------------------------------------------------------------------  
function DATA.PluginsExtState_Write()
  local str = ''
  for fxGUID in pairs(DATA.extplugins) do
    str = str..fxGUID..'|'..DATA.extplugins[fxGUID].customname..'\n' 
  end
  SetProjExtState( 0, 'MPL_InstrumentRack', 'pluginsdata', str )
end
--------------------------------------------------------------------------------  
function DATA.CtrlsExtState_Read()
  DATA.extctrls = {}
  local retval, val = GetProjExtState( 0, 'MPL_InstrumentRack', 'macro' )
  if not retval then return end
  
  for line in val:gmatch('[^\r\n]+') do 
    local parent_GUID, child_GUID, paramidx = line:match('(%{.-%})%s+(%{.-%})%s+(%d+)')
    if not DATA.extctrls[parent_GUID] then DATA.extctrls[parent_GUID] = {} end
    local id = #DATA.extctrls[parent_GUID]+1
    
    -- pass params
    local ret, tr, fx = VF_GetFXByGUID(child_GUID)
    if ret then 
      
      local paramval = TrackFX_GetParamNormalized( tr, fx, paramidx )
      local retval, paramname = reaper.TrackFX_GetParamName( tr, fx, paramidx )
      DATA.extctrls[parent_GUID][id] = {
        fxGUID = child_GUID, 
        paramidx = tonumber(paramidx),
        paramval=paramval,
        paramname=paramname,
        }
    end
  end
end
--------------------------------------------------------------------------------  
function DATA:CollectData()
  DATA.CtrlsExtState_Read()
  DATA.PluginsExtState_Read()

  DATA.plugins_data = {}
  DATA.plugins_tree = {}
  for trid = 1, CountTracks(0) do
    local tr = GetTrack(0,trid-1)
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
      local txt_out =  '['..trid..'] '..trname..' | '..fxname
      
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
        }
      
      ::skipnextFX::
    end
  end
  
end
--------------------------------------------------------------------------------  
function main()
  DATA.plugins_data = DATA.EnumeratePlugins()
  UI.MAIN() 
end
--------------------------------------------------------------------------------  
function DATA.Plugin_params_set(GUID,params)
  local ret, tr, id = VF_GetFXByGUID(GUID)
  if not ret then return end
  if params.online ~= nil then TrackFX_SetOffline(tr, id, params.online) end
  if params.bypass ~= nil then TrackFX_SetEnabled(tr, id, params.bypass) end
  if params.open ~= nil then 
    if params.open == false then 
      TrackFX_Show( tr, id, 2)
     else 
      if EXT.floatchain == 1 then TrackFX_Show( tr, id, 1 ) else TrackFX_Show( tr, id, 3 )end
    end
    if EXT.scrolltotrackonedit == 1 then
      SetMixerScroll( tr )
      SetOnlyTrackSelected( tr )
      VF_Action(40913)--Track: Vertical scroll selected tracks into view
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
  if  ImGui_IsItemActivated( ctx ) then DATA.latchstate = t.paramval return end 
  
  if  reaper.ImGui_IsItemActive( ctx ) then
    local x, y = reaper.ImGui_GetMouseDragDelta( ctx, x, y,  ImGui_MouseButton_Left(), -1 )
    local outval = DATA.latchstate - y/500
    outval = math.max(0,math.min(outval,1))
    local fxGUID = t.fxGUID
    local dx, dy = reaper.ImGui_GetMouseDelta( ctx )
    if dy~=0 then
      DATA.Plugin_params_set(fxGUID,{paramidx = t.paramidx, paramval = outval})
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
  --UI.MAIN_PushStyle(ImGui_Col_ChildBg(),UI.windowBg_plugin, 0.2, true)
  UI.MAIN_PushStyle(ImGui_Col_ChildBg(),plugdata.tr_col, 0.2, true)
  local sz_w,sz_h = 0,0
  if EXT.usesecondcol == 1 then 
    sz_w = DATA.display_w/2-UI.spacingX*2
  end
  if ImGui_BeginChild( ctx, plugname..'##'..fxGUID, sz_w,sz_h,  ImGui_ChildFlags_AutoResizeY()|ImGui_ChildFlags_Border(), 0 ) then
    
    
    
    -- online
    local online = 'Online' 
    if plugdata.online == false then online = 'Offline' UI.draw_setbuttoncolor(UI.main_col) else UI.draw_setbuttoncolor(UI.butBg_red) end 
    local ret = ImGui_Button( ctx, online..'##off'..fxGUID, butw, 0 ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Plugin_params_set(fxGUID,{online= plugdata.online}) end
    
    -- bypass
    local bypass = 'Bypass' 
    if plugdata.enabled == true then bypass = 'Bypass' UI.draw_setbuttoncolor(UI.main_col) else UI.draw_setbuttoncolor(UI.butBg_green) end 
    local ret = ImGui_Button( ctx, bypass..'##byp'..fxGUID, butw, 0 ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Plugin_params_set(fxGUID,{bypass= not plugdata.enabled}) end
    
    ImGui_Dummy(ctx,20,0) UI.SameLine(ctx)
    local txtout =  plugdata.txt_out
    if DATA.extplugins[fxGUID] and DATA.extplugins[fxGUID].customname and DATA.extplugins[fxGUID].customname ~= 'nil' then txtout = DATA.extplugins[fxGUID].customname end
    if not (DATA.editfield and DATA.editfield == fxGUID) then ImGui_Text(ctx, txtout) end
    if ImGui_IsItemClicked( ctx,  ImGui_MouseButton_Right() ) then
      DATA.editfield = fxGUID
    end
    
    if DATA.editfield == fxGUID then
      UI.SameLine(ctx)
      ImGui_SetKeyboardFocusHere( ctx, 0 )
      local retval, buf = ImGui_InputText( ctx,  '##'..fxGUID, txtout, ImGui_InputTextFlags_None()|ImGui_InputTextFlags_EnterReturnsTrue(), nil )
      if retval then 
        if not DATA.extplugins[fxGUID] then DATA.extplugins[fxGUID] = {} end
        if buf == '' then buf = 'nil' end
        DATA.extplugins[fxGUID].customname = buf
        DATA.PluginsExtState_Write()
        
        DATA.editfield = nil
      end
    end
    --
    ImGui_PushFont(ctx, DATA.font3) 
    -- open
    if plugdata.open == true then UI.draw_setbuttoncolor(UI.butBg_green) else UI.draw_setbuttoncolor(UI.main_col) end 
    local ret = ImGui_Button( ctx, 'FX'..'##fx'..fxGUID, butw_low, UI.calc_itemH_small ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Plugin_params_set(fxGUID,{open= not plugdata.open}) end

    -- solo
    if plugdata.tr_solo == true then UI.draw_setbuttoncolor(UI.butBg_green) else UI.draw_setbuttoncolor(UI.main_col) end 
    local ret = ImGui_Button( ctx, 'S'..'##s'..fxGUID, butw_low, UI.calc_itemH_small ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Plugin_params_set(fxGUID,{solo = not plugdata.tr_solo}) end

    
    -- mute
    if plugdata.tr_mute == true then UI.draw_setbuttoncolor(UI.butBg_red) else UI.draw_setbuttoncolor(UI.main_col) end 
    local ret = ImGui_Button( ctx, 'M', butw_low, UI.calc_itemH_small ) UI.draw_unsetbuttoncolor() UI.SameLine(ctx)
    if ret then DATA.Plugin_params_set(fxGUID,{mute = not plugdata.tr_mute}) end
    
    ImGui_Dummy(ctx,20,0) UI.SameLine(ctx)
    
    -- preset
    UI.draw_setbuttoncolor(UI.main_col)
    local ret = ImGui_Button( ctx, '<'..'##presL'..fxGUID, 0, UI.calc_itemH_small )  UI.SameLine(ctx) if ret then DATA.Plugin_params_set(fxGUID,{preset = -1}) end
    local ret = ImGui_Button( ctx, '>'..'##presR'..fxGUID, 0, UI.calc_itemH_small )  UI.SameLine(ctx) if ret then DATA.Plugin_params_set(fxGUID,{preset = 1}) end
    ImGui_Text(ctx, plugdata.presetname)
    UI.draw_unsetbuttoncolor()
    
    -- add fx
    local ret = ImGui_Button( ctx, '+'..'##addparam'..fxGUID, 0, UI.calc_itemH) 
    if ImGui_IsItemHovered(ctx, ImGui_HoveredFlags_ForTooltip()) then ImGui_SetTooltip(ctx, 'Add last touched parameter for instrument of FX') end
    if ret ==true then DATA.Plugin_params_extset(plugdata) DATA.upd = true end
    
    if DATA.extctrls[fxGUID] then  
      
      UI.extinfo[fxGUID] = ""
      UI.SameLine(ctx) 
      UI.MAIN_PushStyle(ImGui_Col_SliderGrab(),UI.main_col, 0, true) 
      UI.MAIN_PushStyle(ImGui_Col_SliderGrabActive(),UI.main_col, 0, true) 
      UI.MAIN_PushStyle(ImGui_Col_FrameBgHovered(),UI.main_col, .1, true)
      UI.MAIN_PushStyle(ImGui_Col_FrameBgActive(),UI.main_col, .3, true)
      for extid = 1, #DATA.extctrls[fxGUID] do
        if not DATA.extctrls[fxGUID][extid] then goto skipnextctrl end
        -- define
        local butid = '##ext'..extid..fxGUID
        local retval, v = reaper.ImGui_VSliderDouble( ctx, butid,  UI.calc_itemH,  UI.calc_itemH, DATA.extctrls[fxGUID][extid].paramval, 0, 1, '',  ImGui_SliderFlags_None() )
        UI.draw_plugin_handlelatchstate(DATA.extctrls[fxGUID][extid])  
        -- tooltip
        if ImGui_IsItemHovered( ctx,  ImGui_HoveredFlags_None() ) or ImGui_IsItemActive( ctx )  then  
          UI.extinfo[fxGUID] = DATA.extctrls[fxGUID][extid].paramname  
        end
        if ImGui_IsItemHovered( ctx,  ImGui_HoveredFlags_None() )  then 
          -- delete click
          if  ImGui_IsKeyPressed( ctx,   ImGui_Key_Delete(), 0 ) then 
            table.remove(DATA.extctrls[fxGUID], extid)
            DATA.CtrlsExtState_Write()
            DATA.upd = true
          end
        end
        UI.draw_knob(DATA.extctrls[fxGUID][extid].paramval)
        UI.SameLine(ctx)
        ::skipnextctrl::
      end
      ImGui_PopStyleColor(ctx,4)UI.pushcnt2 = UI.pushcnt2 - 4
      
      ImGui_Text(ctx,UI.extinfo[fxGUID])
    end
    
    ImGui_PopFont(ctx) 
    ImGui_EndChild( ctx )
  end
  if EXT.usesecondcol == 1 then
    if sec_col  then UI.SameLine(ctx) end
  end
end
-------------------------------------------------------------------------------- 
function UI.draw_knob(val) 
  if not val then return end
  --local draw_list = ImGui_GetWindowDrawList(ctx)
  local draw_list = ImGui_GetForegroundDrawList(ctx)
  if UI.menuopened == true then 
    return 
  end
  ImGui_SameLine( ctx, 0, 0 ) 
  local curposx, curposy = ImGui_GetCursorScreenPos(ctx)
  local knob_w = ImGui_CalcItemWidth( ctx )
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
  --ImGui_DrawList_AddRect( draw_list, p_min_x, p_min_y, p_max_x, p_max_y, col_rgba, roundingIn,  ImGui_DrawFlags_None(), thicknessIn )
  --ImGui_DrawList_AddCircle(draw_list, center_x, center_y, radius, 0xF0F0F0FF, 0,1.0)
  local ang_min = -220
  local ang_max = 40
  local ang_val = ang_min + math.floor((ang_max - ang_min)*val)
  local radiusshift_y = (radius_draw- radius)
  ImGui_DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_max), 0)
  ImGui_DrawList_PathStroke(draw_list, 0xF0F0F02F,  ImGui_DrawFlags_None(), 2)
  ImGui_DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_val+2), 0)
  ImGui_DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui_DrawFlags_None(), 2)
  
  local radius_draw2 = radius_draw-1
  local radius_draw3 = radius_draw-6
  ImGui_DrawList_PathClear(draw_list)
  ImGui_DrawList_PathLineTo(draw_list, center_x + radius_draw2 * math.cos(math.rad(ang_val)), center_y - radiusshift_y + radius_draw2 * math.sin(math.rad(ang_val)))
  ImGui_DrawList_PathLineTo(draw_list, center_x + radius_draw3 * math.cos(math.rad(ang_val)), center_y -radiusshift_y + radius_draw3 * math.sin(math.rad(ang_val)))
  ImGui_DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui_DrawFlags_None(), 2)
end
-------------------------------------------------------------------------------- 
function DATA.Plugin_params_extset(plugdata) 
  local retval, trackidx, itemidx, takeidx, fxidx, parm = GetTouchedOrFocusedFX( 0 )
  if retval ~= true then return end
  if trackidx ==-1 then return end
  if itemidx ~=-1 then return end
  if fxidx&0x2000000==0x2000000 then return end
  if fxidx&0x1000000==0x1000000 then return end
  
  local tr = GetTrack(0,trackidx)
  local tr_GUID = GetTrackGUID( tr )
  if tr_GUID ~= plugdata.tr_GUID then return end
  
  local fxGUID = reaper.TrackFX_GetFXGUID( tr, fxidx )
  local parfxGUID = plugdata.fxGUID
  if not DATA.extctrls then DATA.extctrls = {} end
  if not DATA.extctrls[parfxGUID] then DATA.extctrls[parfxGUID] ={} end
  DATA.extctrls[parfxGUID]  [#DATA.extctrls[parfxGUID] + 1] = {fxGUID=fxGUID,paramidx=parm}
  
  DATA.CtrlsExtState_Write()
end

--------------------------------------------------------------------------------  
function DATA.CtrlsExtState_Write()
  local str = ''
  for fxGUID in pairs(DATA.extctrls) do
    for i = 1, #DATA.extctrls[fxGUID] do
      str = str..fxGUID..' '..DATA.extctrls[fxGUID][i].fxGUID..' '..DATA.extctrls[fxGUID][i].paramidx..'\n' 
    end
  end
  SetProjExtState( 0, 'MPL_InstrumentRack', 'macro', str )
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col) 
    UI.MAIN_PushStyle(ImGui_Col_Button(),col, 0.7, true) 
    UI.MAIN_PushStyle(ImGui_Col_ButtonActive(),col, 1, true) 
    UI.MAIN_PushStyle(ImGui_Col_ButtonHovered(),col, 0.8, true)
end
--------------------------------------------------------------------------------  
function UI.draw_unsetbuttoncolor() 
  ImGui_PopStyleColor(ctx,3)
  UI.pushcnt2 = UI.pushcnt2 -3
end
--------------------------------------------------------------------------------  
function UI.draw() 
  UI.menuopened = false
  if ImGui_BeginMenuBar(ctx) then
    if ImGui_MenuItem(ctx, 'Add FX', nil, false, true) then VF_Action(40701) end
    if ImGui_BeginMenu(ctx,'Options') then
      UI.menuopened = true
      ImGui_SeparatorText(ctx, 'General')
      local ret = ImGui_MenuItem(ctx, 'Select and scroll to track on click', nil, EXT.scrolltotrackonedit == 1, true) if ret then DATA.upd = true EXT.scrolltotrackonedit=EXT.scrolltotrackonedit~1 EXT:save() end
      local ret = ImGui_MenuItem(ctx, 'Show FX chain instead floating FX', nil, EXT.floatchain == 1, true) if ret then DATA.upd = true EXT.floatchain=EXT.floatchain~1 EXT:save() end
      local ret = ImGui_MenuItem(ctx, 'Hide RS5k instances', nil, EXT.hiders5k == 1, true) if ret then DATA.upd = true EXT.hiders5k=EXT.hiders5k~1 EXT:save() end
      --local ret = ImGui_MenuItem(ctx, 'Use second column', nil, EXT.usesecondcol == 1, true) if ret then DATA.upd = true EXT.usesecondcol=EXT.usesecondcol~1 EXT:save() end
      --local ret = ImGui_MenuItem(ctx, 'Sorting', nil, nil, false)
      ImGui_SeparatorText(ctx, 'Sorting')
      local ret = ImGui_MenuItem(ctx, 'Show offline FX at the end of list', nil, EXT.showofflineattheend == 1, true) if ret then 
        DATA.upd = true 
        EXT.showofflineattheend=EXT.showofflineattheend~1 
        if EXT.showofflineattheend ==1 then EXT.collectsamefoldinstr =0 end 
        EXT:save() 
      end
      local ret = ImGui_MenuItem(ctx, 'Show folders as tree', nil, EXT.collectsamefoldinstr == 1, true) if ret then 
        DATA.upd = true 
        EXT.collectsamefoldinstr=EXT.collectsamefoldinstr~1 
        if EXT.collectsamefoldinstr ==1 then EXT.showofflineattheend =0 end 
        EXT:save() 
      end
      ImGui_EndMenu(ctx)
    end
    
    local retval, search = ImGui_InputText(ctx, '', EXT.searchfilter, ImGui_InputTextFlags_None()|ImGui_InputTextFlags_AutoSelectAll())--|ImGui_InputTextFlags_EnterReturnsTrue()
    if retval then 
      EXT.searchfilter = search
      EXT:save() 
    end
    ImGui_EndMenuBar(ctx)
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
    if ImGui_TreeNode(ctx, '[Offline plugins]##off', ImGui_TreeNodeFlags_None()) then--ImGui_TreeNodeFlags_DefaultOpen()) then
      for i = 1, plugcnt do if DATA.plugins_data[i].online == false then UI.draw_plugin(DATA.plugins_data[i]) end end
      ImGui_TreePop(ctx)
    end
  end
  
  if EXT.collectsamefoldinstr == 1 then
    for partrGUID in pairs(DATA.plugins_tree) do
      if ImGui_TreeNode(ctx, '##'..partrGUID, ImGui_TreeNodeFlags_DefaultOpen()) then
        for j = 1, #DATA.plugins_tree[partrGUID] do   
          local id = DATA.plugins_tree[partrGUID][j]
          UI.draw_plugin(DATA.plugins_data[id]) 
        
        end 
        ImGui_TreePop(ctx)
      end
    end
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