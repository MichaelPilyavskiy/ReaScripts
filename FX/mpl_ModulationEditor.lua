-- @description ModulationEditor
-- @version 2.09
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Use delete for toggle selected mod active
--    + Improve docking



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
        viewport_dock = 0,
        
        CONF_dock = 0,
        
        -- global
        CONF_name = 'default',
        CONF_filtermode = 0,
        
        recent_add_list = '',
        recent_add_listMIDI = '',
      }
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'MPL_ModulationEditor',
        UI_name = 'Modulation editor', 
        upd = true,
        LiveLinkT = {},
        addlinkmidi = {
          msg1 = 176,
          msg2 = 1,
          chan = 0,
          bus = 1,
        }
        }
        
        
-------------------------------------------------------------------------------- UI init variables
UI = {}
  
  UI.popups = {}
-- font  
  UI.font='Arial'
  UI.font1sz=15
  UI.font2sz=14
  UI.font3sz=13
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
  UI.default_data_col_adv2 = '#e61919 ' -- red

  UI.indent = 20
  UI.knob_resY = 400
  UI.ctrl_w_active = 15 
  UI.activecol_on = 0x0Fff0F -- green
  UI.activecol_off = 0x808080 -- yellow





function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
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
  local w_min = 330
  local h_min = 80
  -- window_flags
    local window_flags = ImGui.WindowFlags_None
    --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
    --window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
    window_flags = window_flags | ImGui.WindowFlags_MenuBar
    --window_flags = window_flags | ImGui.WindowFlags_NoMove()
    --window_flags = window_flags | ImGui.WindowFlags_NoResize
    window_flags = window_flags | ImGui.WindowFlags_NoCollapse
    --window_flags = window_flags | ImGui.WindowFlags_NoNav()
    --window_flags = window_flags | ImGui.WindowFlags_NoBackground()
    --window_flags = window_flags | ImGui.WindowFlags_NoDocking
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
      UI.MAIN_PushStyle('StyleVar_ButtonTextAlign',0,0.5)
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
      UI.MAIN_PushStyle('Col_WindowBg',UI.windowBg, 1)
    
  -- We specify a default position/size in case there's no data in the .ini file.
    local main_viewport = ImGui.GetMainViewport(ctx)
    local x, y, w, h, dock =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH,EXT.viewport_dock
    --ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
    --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    --ImGui.SetNextWindowDockID( ctx, EXT.CONF_dock , ImGui.Cond_Always )
    
  -- init UI 
    ImGui.PushFont(ctx, DATA.font1) 
    local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) 
    if rv then
      local Viewport = ImGui.GetWindowViewport(ctx)
      DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport) 
      DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport) 
      DATA.display_w_region, DATA.display_h_region = ImGui.Viewport_GetSize(Viewport) 
      DATA.display_dock = ImGui.GetWindowDockID( ctx )
      --if DATA.display_dock ~= EXT.CONF_dock then EXT.CONF_dock = DATA.display_dock EXT:save() msg(DATA.display_dock) end
      
    -- calc stuff for childs
      UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
      local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
      local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
      UI.calc_itemH = calcitemh + frameh * 2
      UI.calc_childH = math.floor(DATA.display_h_region - UI.calc_yoffset*6 - UI.calc_itemH*2)/3
      UI.calc_mainbut = DATA.display_w_region - UI.calc_xoffset*4
      UI.calc_ctrlbut_w = math.floor((DATA.display_w_region - UI.calc_xoffset*7) / 4)
      
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
    if  ImGui.IsKeyPressed( ctx, ImGui.Key_Delete,false )  then 
      if DATA.modulationstate_ext.selected_key then
        local key = DATA.modulationstate_ext.selected_key
        local t = DATA.modulationstate[key]
        t.PMOD['mod.active']=t.PMOD['mod.active']~1 
        DATA:ApplyPMOD(t)
      end
    end
  
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
---------------------------------------------------
function VF_ReduceFXname(s)
  local s_out = s:match('[%:%/%s]+(.*)')
  if not s_out then return s end
  s_out = s_out:gsub('%(.-%)','') 
  --if s_out:match('%/(.*)') then s_out = s_out:match('%/(.*)') end
  local pat_js = '.*[%/](.*)'
  if s_out:match(pat_js) then s_out = s_out:match(pat_js) end  
  if not s_out then return s else 
    if s_out ~= '' then return s_out else return s end
  end
end 
-------------------------------------------------------------------------------- 
function DATA:CollectData_ModState_Sub(track,fx,pid,  trname,fxname,pname) 
  local trGUID = GetTrackGUID( track)
  local fxGUID = TrackFX_GetFXGUID( track, fx-1 )
  local key = fxGUID..'_'..pid
  
  -- init
    if not DATA.modulationstate[key] then 
      DATA.modulationstate[key]={
        trGUID = trGUID,
        fxGUID = fxGUID,
        param = pid,
        fxname=fxname,
        fxname_short = VF_ReduceFXname(fxname),
        trname=trname,
        pname = pname,
        butGUID = key,
      }
    end
  
    
  -- port params
    local params = {
      'mod.active',
      'mod.baseline',
      'mod.visible',
      
      'plink.active',
      'plink.scale',
      'plink.offset',
      'plink.effect',
      'plink.param',
      'plink.midi_bus',
      'plink.midi_chan',
      'plink.midi_msg',
      'plink.midi_msg2',
      
      'acs.active',
      'acs.dir',
      'acs.strength',
      'acs.attack',
      'acs.release',
      'acs.dblo',
      'acs.dbhi',
      'acs.chan',
      'acs.stereo',
      'acs.x2',
      'acs.y2',
      
      'lfo.active',
      'lfo.dir',
      'lfo.phase',
      'lfo.speed',
      'lfo.strength',
      'lfo.temposync',
      'lfo.free',
      'lfo.shape',
      
      }
    local params_val = {}
    for i = 1, #params do
      local _, str  = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..params[i] )
      params_val[params[i] ]=tonumber(str) or str
    end
    DATA.modulationstate[key].PMOD = params_val

  -- fx name
    local txt = 'Add last touched'
    if DATA.modulationstate[key].PMOD['plink.effect'] >=0 then
      local retval, fxname = TrackFX_GetFXName(track, DATA.modulationstate[key].PMOD['plink.effect'] )
      local retval, paramname = TrackFX_GetParamName( track, DATA.modulationstate[key].PMOD['plink.effect'], DATA.modulationstate[key].PMOD['plink.param'] )
      txt =  'from: '..VF_ReduceFXname(fxname)..' / '..paramname
     else
      local msg1 = tostring(DATA.modulationstate[key].PMOD['plink.midi_msg'])--:gsub(192,'CC')
        :gsub(176, 'CC')
        :gsub(144, 'Note')
        :gsub(160, 'Aftertouch')
        :gsub(224, 'Pitch')
        :gsub(192, 'Program change')
        :gsub(208, 'Channel pressure')
      local msg2 = DATA.modulationstate[key].PMOD['plink.midi_msg2']
      if not (msg1=='CC' or msg1=='Note' or msg1=='Aftertouch') then msg2 = '' end 
      if msg1=='CC' and tonumber(msg2)&0x80==0x80 then msg2 = ' '..tostring(tonumber(msg2)~0x80)..'/'..(tonumber(msg2)~0x80)+32 end
      
      txt = 
        msg1..
        msg2..' | '..
        'Chan '..tostring(DATA.modulationstate[key].PMOD['plink.midi_chan']):gsub(0,'Omni')..', '..
        'Bus '..DATA.modulationstate[key].PMOD['plink.midi_bus']+1
    end
    DATA.modulationstate[key].PMOD.fx_txt = txt
    
  -- take stuff from ext state
    if not DATA.modulationstate_ext[key] then 
      DATA.modulationstate_ext[key] = {}
      DATA.upd_projextstate = true
     else
      if DATA.modulationstate_ext[key].TS then DATA.modulationstate[key].ext_TS = DATA.modulationstate_ext[key].TS end
    end
    if not DATA.modulationstate_ext[key].TS then DATA.modulationstate_ext[key].TS = time_precise() DATA.upd_projextstate = true end
    if not DATA.modulationstate_ext[key].collapsed_state then DATA.modulationstate_ext[key].collapsed_state = 0 DATA.upd_projextstate = true end
    
  -- UI button
     DATA.modulationstate[key].UI_name =  
      DATA.modulationstate[key].trname..' / '..
      DATA.modulationstate[key].fxname_short..' / '..
      DATA.modulationstate[key].pname
  
end  
-------------------------------------------------------------------------------- 
function DATA:CollectData_FilterCondition(track,fx)
  return
    -- no filter
    EXT.CONF_filtermode == 0 or 
    -- selected track
    (IsTrackSelected( track ) and EXT.CONF_filtermode==1) or
    -- opened fx
    ( TrackFX_GetOpen( track, fx ) and EXT.CONF_filtermode==2)
  
end
-------------------------------------------------------------------------------- 
function DATA:CollectData_ModState() 
  DATA.modulationstate = {}
  local cnt_tracks = CountTracks( 0 )
  
  for trackidx =0, cnt_tracks do
    local track =  GetTrack( 0, trackidx-1 )
    if not track then track = GetMasterTrack() end
    local fx_cnt = TrackFX_GetCount( track )
    local trcol =  GetTrackColor( track )
    local retval, trname = GetTrackName( track )
    local fxcnt = TrackFX_GetCount( track )
    for fx = 1, fxcnt do
      local retval, fxname = TrackFX_GetFXName( track, fx-1, '' )
      local parmcnt =  TrackFX_GetNumParams( track, fx-1 )
      if DATA:CollectData_FilterCondition(track, fx-1) then 
      
        for pid =0 , parmcnt-1 do
          local retval, pname = TrackFX_GetParamName( track, fx-1, pid ) 
          local mod_ret, modactive = TrackFX_GetNamedConfigParm( track, fx-1, 'param.'..pid..'.mod.active' )
          if mod_ret then DATA:CollectData_ModState_Sub(track,fx,pid, trname,fxname,pname) end
        end 
        
      end
    end
  end
  
end
-------------------------------------------------------------------------------- 
function DATA:CollectData_ModStateSortByTS() 
  local lastTS = os.clock()
  if not DATA.modulationstate then return end
  -- sort by time added
  DATA.modulationstate_order = {}
  local increment = 0
  local change
  for key in pairs(DATA.modulationstate) do 
    local srcts = DATA.modulationstate[key].ext_TS 
    if DATA.modulationstate_ext[key].pin and DATA.modulationstate_ext[key].pin == 1  then srcts = srcts - 10^10 end
    local ext_TS = (srcts or 0 ) + increment
    if DATA.modulationstate_order[ext_TS] then
      change = true
      increment = increment +1
      local TS = 0
      if DATA.modulationstate[key] and DATA.modulationstate[key].ext_TS then TS =  DATA.modulationstate[key].ext_TS end
      local ext_TS_new = TS + increment
      DATA.modulationstate_order[ext_TS_new] = key 
     else
      DATA.modulationstate_order[ext_TS] = key
    end
  end
  
  if change == true then
    for ts in spairs(DATA.modulationstate_order) do
      local key = DATA.modulationstate_order[ts]
      DATA.modulationstate_ext[key].TS = ts
    end 
    DATA.upd_projextstate = true
  end
end
-------------------------------------------------------------------------------- 
function DATA:CollectData_ExtState() 
  -- ext
    DATA.modulationstate_ext = {}
    local retval, str_b64 = reaper.GetProjExtState( -1, DATA.ES_key, 'MOD_EDIT_EXT')
    local str = DATA.PRESET_decBase64(str_b64) 
    if retval then DATA.modulationstate_ext = table.load(str) or {} end
end
-------------------------------------------------------------------------------- 
function DATA:CollectData()   
  DATA:CollectData_ExtState() 
  DATA:CollectData_ModState() 
  DATA:CollectData_ModStateSortByTS() 
  
  DATA:Parse_RecentList()
end
--------------------------------------------------------------------------------
function DATA:Parse_RecentList()
  local recent_add_list = DATA.PRESET_decBase64(EXT.recent_add_list)
  DATA.recent_list = {}
  for block in recent_add_list:gmatch('<(.-)>') do
    local fxname,fxident,paramid,paramname = block:match('(.-)%|(.-)%|(.-)%|(.*)')
    
    if fxname then fxname = fxname:match('%=(.*)') end
    if fxident then fxident = fxident:match('%=(.*)') end
    if paramid then paramid = paramid:match('%=(.*)') end  if tonumber(paramid) then paramid = tonumber(paramid) end
    if paramname then paramname = paramname:match('%=(.*)') end
    
    if fxname and paramid and fxident and paramname then 
      DATA.recent_list[#DATA.recent_list+1] = 
        {block=block,
        fxname=fxname,fxident=fxident,paramid=paramid,paramname=paramname
        }
    end
  end
  
  local recent_add_listMIDI = DATA.PRESET_decBase64(EXT.recent_add_listMIDI)
  DATA.recent_listMIDI = {}
  for block in recent_add_listMIDI:gmatch('<(.-)>') do
    local msg1,msg2,chan,bus = block:match('(.-)%|(.-)%|(.-)%|(.*)')
    
    if msg1 then msg1 = msg1:match('%=(.*)') end
    if msg2 then msg2 = msg2:match('%=(.*)') end
    if chan then chan = chan:match('%=(.*)') end
    if bus then bus = bus:match('%=(.*)') end
    
    if msg1 and msg2 and chan and bus then 
      DATA.recent_listMIDI[#DATA.recent_listMIDI+1] = 
        {block=block,
        msg1=msg1,msg2=msg2,chan=chan,bus=bus
        }
    end
  end
end
-------------------------------------------------------------------------------- 
function DATA:CollectData_Always()
  DATA:LiveLink()
end
-------------------------------------------------------------------------------- 
function UI.MAINloop() 
  DATA.clock = os.clock() 
  DATA.alpha = math.sin(math.pi*(DATA.clock%1))
  DATA:handleProjUpdates()
  
  if DATA.upd_projextstate == true then
    local out_str = table.save( DATA.modulationstate_ext)
    local out_str_b64 = DATA.PRESET_encBase64(out_str) 
    SetProjExtState( -1, DATA.ES_key, 'MOD_EDIT_EXT', out_str_b64 )
    DATA.upd_projextstate = nil
  end
  
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
--------------------------------------------------------------------------------  
function main() 
  EXT:load()  
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
function UI.draw_setbuttoncolor(col,alpha) 
    UI.MAIN_PushStyle('Col_Button',col, (alpha or 1)*0.4 or 0.4) 
    UI.MAIN_PushStyle('Col_ButtonActive',col,alpha or  1) 
    UI.MAIN_PushStyle('Col_ButtonHovered',col, (alpha or 1)*0.8 or 0.8)
end
--------------------------------------------------------------------------------  
function UI.draw_plugin_handlelatchstate(t)  
  local paramval = DATA.modulationstate[t.butGUID].PMOD[t.param_key]
  local itemhovered , itemlatched
  -- trig
  --if  ImGui.IsItemActivated( ctx ) then 
  if  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then 
    local normval = paramval
    if t.val_min and t.val_max then normval = (paramval - t.val_min) / (t.val_max - t.val_min) end
    DATA.latchstate = normval 
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
    itemlatched = true
    local x, y = ImGui.GetMouseDragDelta( ctx )
    local normval = DATA.latchstate - y/UI.knob_resY
    normval = math.max(0,math.min(normval,1))
    local outval = normval
    if t.val_min and t.val_max then 
      outval = normval * (t.val_max - t.val_min) + t.val_min
      
    end 
    local fxGUID = t.fxGUID
    local dx, dy = ImGui.GetMouseDelta( ctx )
    if dy~=0 then
      DATA.modulationstate[t.butGUID].PMOD[t.param_key] = outval
      --if t.appfunc_atdrag then t.appfunc_atdrag() end
      --DATA:ApplyPMOD(t.srct)
    end 
  end
  
  if  ImGui.IsItemDeactivated( ctx ) then
    --if t.appfunc_atrelease then t.appfunc_atrelease() end
    DATA:ApplyPMOD(t.srct)
    t.dragtooltip = nil
  end
  
  if ImGui.IsItemHovered( ctx, ImGui.HoveredFlags_None ) then
    itemhovered = true
    local vertical, horizontal = ImGui.GetMouseWheel( ctx )
    if vertical ~= 0 then
      local mod = 1
      if ImGui.IsKeyDown( ctx, ImGui.Mod_Shift ) then mod = 10 end
      DATA.modulationstate[t.butGUID].PMOD[t.param_key] = VF_lim(DATA[t.param_key] + vertical*0.01*mod)
      --if t.appfunc_atrelease then t.appfunc_atrelease() end
      DATA:ApplyPMOD(t.srct)
    end
  end
  
  
  if (itemhovered or itemlatched) and  DATA.modulationstate[t.butGUID].PMOD[t.param_key] then 
    local outval = DATA.modulationstate[t.butGUID].PMOD[t.param_key]
    if t.formatstr then t.dragtooltip = t.formatstr(outval) else t.dragtooltip = outval end
  end
end
-------------------------------------------------------------------------------- 
function UI.draw_knob(t,valkey) 
  local curposx, curposy = ImGui.GetCursorScreenPos(ctx)
  local butid = '##knob'..t.butGUID..t.param_key
  UI.draw_setbuttonbackgtransparent() 
  ImGui.Button( ctx, butid, t.w or 0, t.h or 0)
  UI.draw_unsetbuttonstyle()
  local item_w, item_h = reaper.ImGui_GetItemRectSize( ctx )
  local item_w2, item_h2 = 0,0
  UI.draw_plugin_handlelatchstate(t)  
  if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then DATA.SetSelection(t.srct) end
  
  if not t.dragtooltip then 
    ImGui.SetItemTooltip( ctx, t.tooltip)
   else
    if ImGui.BeginTooltip( ctx ) then
      ImGui.Text(ctx,t.dragtooltip )
      ImGui.EndTooltip( ctx )
    end
  end
  
  if DATA.display_w > 500 and t.name then
    ImGui.SameLine(ctx)
    UI.draw_setbuttonbackgtransparent() 
    ImGui.Button( ctx, t.name..butid..'name')
    UI.draw_unsetbuttonstyle()
    item_w2, item_h2 = reaper.ImGui_GetItemRectSize( ctx )
    item_w2 = item_w2 + UI.spacingX
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then DATA.SetSelection(t.srct) end
  end
  
  local val = DATA.modulationstate[t.butGUID].PMOD[t.param_key]
  
  if t.val_min and t.val_max then val = (val - t.val_min) / (t.val_max - t.val_min) end
  
  if not val then return end
  local draw_list = ImGui.GetForegroundDrawList(ctx)
  local roundingIn = 0
  local col_rgba = 0xF0F0F0FF
  local controlsalpha = 0xFF
  local circlealpha = 0x2F
  if t.disabled == true then 
    controlsalpha =0x29
    circlealpha =0x09
  end
  local radius = math.floor(math.min(item_w, item_h )/2)
  local radius_draw = math.floor(0.9 * radius)
  local center_x = curposx + item_w/2--radius
  local center_y = curposy + item_h/2
  local ang_min = -220
  local ang_max = 40
  local ang_val = ang_min + math.floor((ang_max - ang_min)*val)
  local radiusshift_y = (radius_draw- radius)
  ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_max))
  ImGui.DrawList_PathStroke(draw_list, 0xF0F0F0<<8|circlealpha,  ImGui.DrawFlags_None, 1)
  ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_val+1))
  ImGui.DrawList_PathStroke(draw_list, (t.knob_col or UI.knob_handle)<<8|controlsalpha,  ImGui.DrawFlags_None, 2)
  
  local radius_draw2 = radius_draw-1
  local radius_draw3 = radius_draw-6
  ImGui.DrawList_PathClear(draw_list)
  ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw2 * math.cos(math.rad(ang_val)), center_y - radiusshift_y + radius_draw2 * math.sin(math.rad(ang_val)))
  ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw3 * math.cos(math.rad(ang_val)), center_y -radiusshift_y + radius_draw3 * math.sin(math.rad(ang_val)))
  ImGui.DrawList_PathStroke(draw_list, (t.knob_col or UI.knob_handle)<<8|controlsalpha,  ImGui.DrawFlags_None, 2)
  
  
  ImGui.SetCursorScreenPos(ctx, curposx, curposy)
  --ImGui.Dummy(ctx,t.w or UI.calc_itemH,  t.h or UI.calc_itemH)
  ImGui.Dummy(ctx,item_w+item_w2,item_h)
end
-------------------------------------------------------------------------------- 
function UI.MAIN_shortcuts()
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then 
    for key in pairs(UI.popups) do UI.popups[key].draw = false end
    ImGui.CloseCurrentPopup( ctx ) 
  end
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_Space,false )  then  reaper.Main_OnCommand(40044,0) end
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_L,false ) then
    if DATA.LiveLinkT.run == true then DATA.LiveLinkT.run = nil else DATA.LiveLinkT.run = true  end
  end
end
--------------------------------------------------------------------------------  
function UI.draw_mods_audio(t)  
  local str_id = t.fxGUID..'_'..t.param
  
  ImGui.PushFont(ctx, DATA.font3) 
  -- lfo toggle
    if t.PMOD['acs.active'] == 1 then 
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, UI.activecol_on<<8|0xFF)
     else
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, UI.activecol_off<<8|0xFF) 
    end
    UI.draw_setbuttonbackgtransparent() 
    if ImGui.Button(ctx, 'Audio##'..str_id..'acs') then t.PMOD['acs.active']=t.PMOD['acs.active']~1 DATA:ApplyPMOD(t) end
    UI.draw_unsetbuttonstyle()
    ImGui.PopStyleColor(ctx)
    ImGui.SameLine(ctx)
  
  local disabled = t.PMOD['acs.active']~=1
  if disabled==true then ImGui.BeginDisabled(ctx,true) end
  
    -- strength
      UI.draw_knob(
        {butGUID = t.butGUID,
        param_key = 'acs.strength',
        srct = t,
        --name = '|',
        knob_col = UI.activecol_on,
        disabled=disabled,
        formatstr = function(v) return 'Strength: '..math.floor(v*1000)/1000 end}) 
      ImGui.SameLine(ctx)
      
    -- dir
      local txt = 'Positive'
      if t.PMOD['acs.dir'] == 0 then txt = 'Center' end
      if t.PMOD['acs.dir'] == -1 then txt = 'Negative' end
      ImGui.SetNextItemWidth( ctx, 80 )
      if ImGui.BeginCombo( ctx, '##'..str_id..'Dir', txt, ImGui.ComboFlags_None ) then
        if ImGui.Selectable( ctx, 'Negative', t.PMOD['acs.dir'] == -1, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['acs.dir']=-1 DATA:ApplyPMOD(t) end
        if ImGui.Selectable( ctx, 'Centered', t.PMOD['acs.dir'] == 0, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['acs.dir']=0 DATA:ApplyPMOD(t) end
        if ImGui.Selectable( ctx, 'Positive', t.PMOD['acs.dir'] == 1, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['acs.dir']=1 DATA:ApplyPMOD(t) end
        ImGui.EndCombo( ctx)
      end
      ImGui.SameLine(ctx)
      
    -- attack
      UI.draw_knob(
        {butGUID = t.butGUID,
        param_key = 'acs.attack',
        srct = t,
        name = 'Attack',
        val_min = 0,
        val_max = 1000,
        disabled=disabled,
        formatstr = function(v) return 'Attack: '..math.floor(v*1000)/1000 end,})
      ImGui.SameLine(ctx)  

    -- release
      UI.draw_knob(
        {butGUID = t.butGUID,
        param_key = 'acs.release',
        srct = t,
        name = 'Release',
        val_min = 0,
        val_max = 1000,
        disabled=disabled,
        formatstr = function(v) return 'Release: '..math.floor(v*1000)/1000 end,})
      ImGui.SameLine(ctx)  

    -- dblo
      UI.draw_knob(
        {butGUID = t.butGUID,
        param_key = 'acs.dblo',
        srct = t,
        name = 'Min',
        disabled=disabled,
        val_min = -59.9,
        val_max = t.PMOD['acs.dbhi'],
        formatstr = function(v) return 'Min vol: '..math.floor(v*1000)/1000 end,})
      ImGui.SameLine(ctx) 

    -- dbhi
      UI.draw_knob(
        {butGUID = t.butGUID,
        param_key = 'acs.dbhi',
        srct = t,
        name = 'Max',
        val_min =  t.PMOD['acs.dblo'],
        val_max = 12,
        disabled=disabled,
        formatstr = function(v) return 'Max vol: '..math.floor(v*1000)/1000 end,})
      --ImGui.SameLine(ctx) 
  if disabled==true then ImGui.EndDisabled(ctx) end
  ImGui.PopFont(ctx) 
end  
--------------------------------------------------------------------------------  
function UI.draw_mods_link(t) 
  local str_id = t.fxGUID..'_'..t.param
  
  ImGui.PushFont(ctx, DATA.font3) 
  -- lfo toggle
    if t.PMOD['plink.active'] == 1 then 
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, UI.activecol_on<<8|0xFF)
     else
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, UI.activecol_off<<8|0xFF) 
    end
    UI.draw_setbuttonbackgtransparent() 
    if ImGui.Button(ctx, 'Link##'..str_id..'plink') then t.PMOD['plink.active']=t.PMOD['plink.active']~1 DATA:ApplyPMOD(t) end
    UI.draw_unsetbuttonstyle()
    ImGui.PopStyleColor(ctx)
    ImGui.SameLine(ctx)
  
  local disabled = t.PMOD['plink.active']~=1
  if disabled==true then ImGui.BeginDisabled(ctx,true) end
    -- offset
      UI.draw_knob(
        {butGUID = t.butGUID,
        param_key = 'plink.offset',
        srct = t,
        val_min = -1,
        val_max = 1,
        name= 'Offset',
        --knob_col = UI.activecol_on,
        disabled=disabled,
        --tooltip = 'Base value' ,
        formatstr = function(v) return 'Offset: '..math.floor(v*1000)/1000 end}) 
      ImGui.SameLine(ctx)  

    -- scale
      UI.draw_knob(
        {butGUID = t.butGUID,
        param_key = 'plink.scale',
        srct = t,
        val_min = -1,
        val_max = 1,
        name= 'Scale',
        --knob_col = UI.activecol_on,
        disabled=disabled,
        --tooltip = 'Base value' ,
        formatstr = function(v) return 'Scale: '..math.floor(v*1000)/1000 end}) 
      ImGui.SameLine(ctx)  
      
      UI.draw_mods_link_combo(t,str_id)
      
        
        
  if disabled==true then ImGui.EndDisabled(ctx) end
  ImGui.PopFont(ctx)   
end
-------------------------------------------------------------------------------- 
function DATA.AddLinkFromList(ctrl_t, recentlist_entry) 
  local track = VF_GetTrackByGUID(ctrl_t.trGUID)
  if not track then return end
  local fxident = recentlist_entry.fxname--fxident
  local parm = recentlist_entry.paramid
  if not fxident then return end
  
  local fxidx = TrackFX_AddByName( track, fxident, false, 1 )
  
  Undo_BeginBlock2( -1 )
  ctrl_t.PMOD['plink.effect']=fxidx
  ctrl_t.PMOD['plink.param']=parm
  DATA:ApplyPMOD(ctrl_t)
  Undo_EndBlock2( -1, 'Add link from last touched', 0xFFFFFFFF )
  DATA.upd = true
  
  local retval, fx_ident = reaper.TrackFX_GetNamedConfigParm( track, fxidx, 'fx_ident' )
  local retval, fxname = reaper.TrackFX_GetNamedConfigParm( track, fxidx, 'fx_name' )
  local retval, paramname = reaper.TrackFX_GetParamName( track, fxidx,parm )
  
  EXT.recent_add_list = DATA.PRESET_decBase64(EXT.recent_add_list)
  EXT.recent_add_list = '<fxname='..fxname..'|fx_ident='..fx_ident..'|param='..parm..'|paramname='..paramname..'>;'..EXT.recent_add_list
  EXT.recent_add_list = EXT.recent_add_list:sub(0,1000)
  EXT.recent_add_list = DATA.PRESET_encBase64(EXT.recent_add_list)
  
  EXT.recent_add_listMIDI = DATA.PRESET_decBase64(EXT.recent_add_listMIDI)
  EXT.recent_add_listMIDI = '<msg1='..msg1..'|msg2='..msg2..'|chan='..chan..'|bus='..bus..'>;'..EXT.recent_add_listMIDI
  EXT.recent_add_listMIDI = EXT.recent_add_listMIDI:sub(0,1000)
  EXT.recent_add_listMIDI = DATA.PRESET_encBase64(EXT.recent_add_listMIDI)
  
  EXT:save()
  
end
  --------------------------------------------------
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or -1) do
      local tr = GetTrack(reaproj or -1,i-1)
      --local GUID = reaper.GetTrackGUID( tr )
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end
--------------------------------------------------------------------------------  
function UI.draw_mods_link_combo(t,str_id) 
  --if t.PMOD.fx_txt and ImGui.Button(ctx, t.PMOD.fx_txt..'##'..str_id..'plink_fx',-1,0) then DATA.AddLinkFromLastTouched(t) end
  local txt = t.PMOD.fx_txt
  
  ImGui.SetNextItemWidth( ctx, -1 )
  if ImGui.BeginCombo( ctx, '##'..str_id..'linkcombo', txt, ImGui.ComboFlags_None|ImGui.ComboFlags_HeightLarge ) then
    ImGui.SeparatorText(ctx, 'FX')
    if ImGui.Button( ctx, 'Add last touched') then DATA.AddLinkFromLastTouched(t) end
    
    -- recent list
    if ImGui.BeginCombo( ctx, '##'..str_id..'linkcombo_reclist', 'RecentList', ImGui.ComboFlags_None|ImGui.ComboFlags_HeightLarge ) then
      for i = 1, #DATA.recent_list do
        if ImGui.Selectable( ctx, DATA.recent_list[i].fxname..' / '..DATA.recent_list[i].paramname, nil, ImGui.SelectableFlags_None, 0, 0 ) then 
          DATA.AddLinkFromList(t,DATA.recent_list[i])
        end
      end
      ImGui.EndCombo( ctx)
    end
    
    
    ImGui.SeparatorText(ctx, 'MIDI')
    local msg1_txt = tostring(DATA.addlinkmidi.msg1)
      :gsub(176, 'CC')
      :gsub(144, 'Note')
      :gsub(160, 'Aftertouch')
      :gsub(224, 'Pitch')
      :gsub(192, 'Program change')
      :gsub(208, 'Channel pressure')
    
    -- type
    if ImGui.BeginCombo( ctx, '##'..str_id..'linkcombo_type', msg1_txt, ImGui.ComboFlags_None|ImGui.ComboFlags_HeightLarge ) then
      if ImGui.Selectable( ctx, 'CC', nil, ImGui.SelectableFlags_None, 0, 0 ) then DATA.addlinkmidi.msg1 = 176 end
      if ImGui.Selectable( ctx, 'Note', nil, ImGui.SelectableFlags_None, 0, 0 ) then DATA.addlinkmidi.msg1 = 144 end
      if ImGui.Selectable( ctx, 'Aftertouch', nil, ImGui.SelectableFlags_None, 0, 0 ) then DATA.addlinkmidi.msg1 = 160 end
      if ImGui.Selectable( ctx, 'Pitch', nil, ImGui.SelectableFlags_None, 0, 0 ) then DATA.addlinkmidi.msg1 = 224 end
      if ImGui.Selectable( ctx, 'Program change', nil, ImGui.SelectableFlags_None, 0, 0 ) then DATA.addlinkmidi.msg1 = 192 end
      if ImGui.Selectable( ctx, 'Channel pressure', nil, ImGui.SelectableFlags_None, 0, 0 ) then DATA.addlinkmidi.msg1 = 208 end
      ImGui.EndCombo( ctx)
    end
    
    
    -- msg2
    if ImGui.BeginCombo( ctx, 'msg2##'..str_id..'linkcombo_msg2', DATA.addlinkmidi.msg2, ImGui.ComboFlags_None|ImGui.ComboFlags_HeightLarge ) then
      for i = 1, 128 do
        if ImGui.Selectable( ctx, i, nil, ImGui.SelectableFlags_None, 0, 0 ) then DATA.addlinkmidi.msg2 = i end
      end
      ImGui.EndCombo( ctx)
    end

    -- msg2
    if ImGui.BeginCombo( ctx, 'Chan##'..str_id..'linkcombo_chan', DATA.addlinkmidi.chan, ImGui.ComboFlags_None|ImGui.ComboFlags_HeightLarge ) then
      for i = 0, 15 do
        if ImGui.Selectable( ctx, i, nil, ImGui.SelectableFlags_None, 0, 0 ) then DATA.addlinkmidi.chan = i end
      end
      ImGui.EndCombo( ctx)
    end
    
    -- msg2
    if ImGui.BeginCombo( ctx, 'Bus##'..str_id..'linkcombo_bus', DATA.addlinkmidi.bus, ImGui.ComboFlags_None|ImGui.ComboFlags_HeightLarge ) then
      for i = 0, 15 do
        if ImGui.Selectable( ctx, i, nil, ImGui.SelectableFlags_None, 0, 0 ) then DATA.addlinkmidi.bus = i end
      end
      ImGui.EndCombo( ctx)
    end
    
    if ImGui.Button( ctx, 'Set MIDI link') then  
      t.PMOD['plink.midi_bus'] = DATA.addlinkmidi.bus-1
      t.PMOD['plink.midi_chan'] = DATA.addlinkmidi.chan
      t.PMOD['plink.midi_msg2'] = DATA.addlinkmidi.msg2
      t.PMOD['plink.midi_msg'] = DATA.addlinkmidi.msg1
      t.PMOD['plink.effect'] = -100
      DATA:ApplyPMOD(t) 
      DATA.upd = true
      
      EXT.recent_add_listMIDI = DATA.PRESET_decBase64(EXT.recent_add_listMIDI)
      EXT.recent_add_listMIDI = '<msg1='..DATA.addlinkmidi.msg1..'|msg2='..DATA.addlinkmidi.msg2..'|chan='..DATA.addlinkmidi.chan..'|bus='..DATA.addlinkmidi.bus..'>;'..EXT.recent_add_listMIDI
      EXT.recent_add_listMIDI = EXT.recent_add_listMIDI:sub(0,1000)
      EXT.recent_add_listMIDI = DATA.PRESET_encBase64(EXT.recent_add_listMIDI)
      EXT:save()
    end
    
    -- recent list
    if ImGui.BeginCombo( ctx, '##'..str_id..'linkcombo_reclistMIDI', 'RecentList', ImGui.ComboFlags_None|ImGui.ComboFlags_HeightLarge ) then
      
      for i = 1, #DATA.recent_listMIDI do
      
        local msg1_txt = tostring(DATA.recent_listMIDI[i].msg1)
          :gsub(176, 'CC')
          :gsub(144, 'Note')
          :gsub(160, 'Aftertouch')
          :gsub(224, 'Pitch')
          :gsub(192, 'Program change')
          :gsub(208, 'Channel pressure')
          
        if ImGui.Selectable( ctx, msg1_txt..' '..DATA.recent_listMIDI[i].msg2..' / Chan '..DATA.recent_listMIDI[i].chan..' Bus '..(DATA.recent_listMIDI[i].bus), nil, ImGui.SelectableFlags_None, 0, 0 ) then 
          t.PMOD['plink.midi_bus'] = DATA.recent_listMIDI[i].bus-1
          t.PMOD['plink.midi_chan'] = DATA.recent_listMIDI[i].chan
          t.PMOD['plink.midi_msg2'] = DATA.recent_listMIDI[i].msg2
          t.PMOD['plink.midi_msg'] = DATA.recent_listMIDI[i].msg1
          t.PMOD['plink.effect'] = -100
          DATA:ApplyPMOD(t) 
          DATA.upd = true
          
          EXT.recent_add_listMIDI = DATA.PRESET_decBase64(EXT.recent_add_listMIDI)
          EXT.recent_add_listMIDI = '<msg1='..DATA.recent_listMIDI[i].msg1..'|msg2='..DATA.recent_listMIDI[i].msg2..'|chan='..DATA.recent_listMIDI[i].chan..'|bus='..DATA.recent_listMIDI[i].bus..'>;'..EXT.recent_add_listMIDI
          EXT.recent_add_listMIDI = EXT.recent_add_listMIDI:sub(0,1000)
          EXT.recent_add_listMIDI = DATA.PRESET_encBase64(EXT.recent_add_listMIDI)
          EXT:save()
        end
      end
      ImGui.EndCombo( ctx)
    end
    
    
    ImGui.EndCombo( ctx)
  end
end
-------------------------------------------------------------------------------- 
function DATA.AddLinkFromLastTouched(ctrl_t)
  
  local retval, trackidx, itemidx, takeidx, fxidx, parm = reaper.GetTouchedOrFocusedFX(0)
  if not retval then return end
  if itemidx>=0 or takeidx>=0 then return end
  
  local track = GetTrack(0,trackidx)
  if trackidx == -1 then track = GetMasterTrack(0) end
  if ctrl_t.trGUID ~=  GetTrackGUID( track ) then return end
  
  Undo_BeginBlock2( -1 )
  ctrl_t.PMOD['plink.effect']=fxidx
  ctrl_t.PMOD['plink.param']=parm
  DATA:ApplyPMOD(ctrl_t)
  Undo_EndBlock2( -1, 'Add link from last touched', 0xFFFFFFFF )
  DATA.upd = true
  
  local retval, fx_ident = reaper.TrackFX_GetNamedConfigParm( track, fxidx, 'fx_ident' )
  local retval, fxname = reaper.TrackFX_GetNamedConfigParm( track, fxidx, 'fx_name' )
  local retval, paramname = reaper.TrackFX_GetParamName( track, fxidx,parm )
  
  EXT.recent_add_list = DATA.PRESET_decBase64(EXT.recent_add_list)
  EXT.recent_add_list = '<fxname='..fxname..'|fx_ident='..fx_ident..'|param='..parm..'|paramname='..paramname..'>;'..EXT.recent_add_list
  EXT.recent_add_list = EXT.recent_add_list:sub(0,1000)
  EXT.recent_add_list = DATA.PRESET_encBase64(EXT.recent_add_list)
  EXT:save()
end
--------------------------------------------------------------------------------  
function UI.draw_mods_lfo(t)  
  local str_id = t.fxGUID..'_'..t.param
  
  ImGui.PushFont(ctx, DATA.font3) 
  -- lfo toggle
    if t.PMOD['lfo.active'] == 1 then 
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, UI.activecol_on<<8|0xFF)
     else
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, UI.activecol_off<<8|0xFF) 
    end
    UI.draw_setbuttonbackgtransparent() 
    if ImGui.Button(ctx, 'LFO##'..str_id..'LFO') then t.PMOD['lfo.active']=t.PMOD['lfo.active']~1 DATA:ApplyPMOD(t) end
    UI.draw_unsetbuttonstyle()
    ImGui.PopStyleColor(ctx)
    ImGui.SameLine(ctx)
  
  local disabled = t.PMOD['lfo.active']~=1
  if disabled==true then ImGui.BeginDisabled(ctx,true) end
    -- strength
      UI.draw_knob(
        {butGUID = t.butGUID,
        param_key = 'lfo.strength',
        srct = t,
        --name = '|',
        knob_col = UI.activecol_on,
        disabled=disabled,
        --tooltip = 'Base value' ,
        formatstr = function(v) return 'Strength: '..math.floor(v*1000)/1000 end}) 
      ImGui.SameLine(ctx)
      
    -- dir
      local txt = 'Positive'
      if t.PMOD['lfo.dir'] == 0 then txt = 'Center' end
      if t.PMOD['lfo.dir'] == -1 then txt = 'Negative' end
      ImGui.SetNextItemWidth( ctx, 80 )
      if ImGui.BeginCombo( ctx, '##'..str_id..'lfoDir', txt, ImGui.ComboFlags_None ) then
        if ImGui.Selectable( ctx, 'Negative', t.PMOD['lfo.dir'] == -1, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['lfo.dir']=-1 DATA:ApplyPMOD(t) end
        if ImGui.Selectable( ctx, 'Centered', t.PMOD['lfo.dir'] == 0, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['lfo.dir']=0 DATA:ApplyPMOD(t) end
        if ImGui.Selectable( ctx, 'Positive', t.PMOD['lfo.dir'] == 1, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['lfo.dir']=1 DATA:ApplyPMOD(t) end
        ImGui.EndCombo( ctx)
      end
      ImGui.SameLine(ctx)
            
    -- speed
      --if t.PMOD['lfo.temposync']==1 then val_min,val_max = 8,0.25 end
      if t.PMOD['lfo.temposync']==0 then 
        local val_min,val_max = 0,8 
        UI.draw_knob(
          {butGUID = t.butGUID,
          param_key = 'lfo.speed',
          srct = t,
          --tooltip = 'Base value' ,
          name = 'Speed',
          disabled=disabled,
          val_min = val_min,
          val_max = val_max,
          formatstr = function(v) return 'Speed: '..math.floor(v*1000)/1000 end,})
       else
        
        local speedstr = t.PMOD['lfo.speed']
        speed_str_map = {
            {str = '2/1',val = 8},
            {str = '1/1',val = 4},
            {str = '1/2',val = 2},
            {str = '1/4',val = 1},
            {str = '1/8',val = 0.5},
            {str = '1/16',val = 0.25},

            {str = '1/1D',val = 6},
            {str = '1/2D',val = 3},
            {str = '1/4D',val = 1.5},
            {str = '1/8D',val = 0.75},
            {str = '1/16D',val = 0.375},
            
            {str = '2/1T',val = 5.3333},
            {str = '1/1T',val = 2.6667},
            {str = '1/2T',val = 1.3333},
            {str = '1/4T',val = 0.6667},
            {str = '1/8T',val = 0.3333},
            
            {str = '1/1Q',val = 3.2},
            {str = '1/2Q',val = 1.6},
            {str = '1/4Q',val = 0.8},
            {str = '1/8Q',val = 0.4},
            
          }
        for i = 1, #speed_str_map do
          if speed_str_map[i].val == t.PMOD['lfo.speed'] then 
            speedstr = speed_str_map[i].str
            break
          end
        end
        ImGui.SetNextItemWidth( ctx, 80 )
        if ImGui.BeginCombo( ctx, '##'..str_id..'lfospeed', speedstr, ImGui.ComboFlags_None ) then
          for i = 1, #speed_str_map do
            if ImGui.Selectable( ctx, speed_str_map[i].str, nil, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['lfo.speed']=speed_str_map[i].val DATA:ApplyPMOD(t) end
          end
          ImGui.EndCombo( ctx)
        end
      end
      ImGui.SameLine(ctx)    
      
    -- phase
      UI.draw_knob(
        {butGUID = t.butGUID,
        param_key = 'lfo.phase',
        srct = t,
        --tooltip = 'Base value' ,
        name = 'Phase',
        disabled=disabled,
        formatstr = function(v) return 'Phase: '..math.floor(v*1000)/1000 end}) 
      ImGui.SameLine(ctx)    
    -- wave
      local txt = 'Sine'
      if t.PMOD['lfo.shape'] == 1 then txt = 'Square' end
      if t.PMOD['lfo.shape'] == 2 then txt = 'Saw L' end
      if t.PMOD['lfo.shape'] == 3 then txt = 'Saw R' end
      if t.PMOD['lfo.shape'] == 4 then txt = 'Triangle' end
      if t.PMOD['lfo.shape'] == 5 then txt = 'Random' end    
      ImGui.SetNextItemWidth( ctx, 90 )
      if ImGui.BeginCombo( ctx, '##'..str_id..'Wave', txt, ImGui.ComboFlags_None ) then
        if ImGui.Selectable( ctx, 'Sine', t.PMOD['lfo.shape'] == 0, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['lfo.shape']=0 DATA:ApplyPMOD(t) end
        if ImGui.Selectable( ctx, 'Square', t.PMOD['lfo.shape'] == 1, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['lfo.shape']=1 DATA:ApplyPMOD(t) end
        if ImGui.Selectable( ctx, 'Saw L', t.PMOD['lfo.shape'] == 2, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['lfo.shape']=2 DATA:ApplyPMOD(t) end
        if ImGui.Selectable( ctx, 'Saw R', t.PMOD['lfo.shape'] == 3, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['lfo.shape']=3 DATA:ApplyPMOD(t) end
        if ImGui.Selectable( ctx, 'Triangle', t.PMOD['lfo.shape'] == 4, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['lfo.shape']=4 DATA:ApplyPMOD(t) end
        if ImGui.Selectable( ctx, 'Random', t.PMOD['lfo.shape'] == 5, ImGui.SelectableFlags_None, 0, 0 ) then t.PMOD['lfo.shape']=5 DATA:ApplyPMOD(t) end
        ImGui.EndCombo( ctx)
      end
      ImGui.SameLine(ctx)    
    -- sync    
      if ImGui.Checkbox( ctx, 'Sync##'..str_id..'Sync', t.PMOD['lfo.temposync']==1 ) then t.PMOD['lfo.temposync']=t.PMOD['lfo.temposync']~1 DATA:ApplyPMOD(t) end
      
  if disabled==true then ImGui.EndDisabled(ctx) end
  ImGui.PopFont(ctx) 
end
--------------------------------------------------------------------------------  
function UI.draw_mods_sub(t)  
  local str_id = t.fxGUID..'_'..t.param
  
  -- collapsed
  local childH = 0
  local flags = ImGui.ChildFlags_None|ImGui.ChildFlags_Border|ImGui.ChildFlags_AutoResizeY
  if DATA.modulationstate_ext[str_id].collapsed_state == 1 then 
    childH = UI.calc_itemH +UI.spacingY*2
    flags = ImGui.ChildFlags_None|ImGui.ChildFlags_Border
  end
  
  -- selection
  if DATA.modulationstate_ext.selected_key == str_id then ImGui.PushStyleColor(ctx, ImGui.Col_Border,UI.main_col<<8|0xF0) else ImGui.PushStyleColor(ctx, ImGui.Col_Border,UI.main_col<<8|0x40) end 
  
  -- child col
  local alphachild = 0x10
  if DATA.modulationstate_ext[str_id].col_rgba then ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg, DATA.modulationstate_ext[str_id].col_rgba) else ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg,UI.main_col<<8|alphachild) end 
  
  if ImGui.BeginChild(ctx, str_id, 0, childH, flags, ImGui.WindowFlags_None|ImGui.WindowFlags_NoScrollbar) then
    -- active indicator
      local actcol = UI.activecol_on if t.PMOD['mod.active'] == 0 then actcol = UI.activecol_off end
      local pin = ''
      if DATA.modulationstate_ext[str_id].pin and DATA.modulationstate_ext[str_id].pin == 1 then pin = '^' end
      UI.draw_setbuttoncolor(actcol)  
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 4, 5)
      if ImGui.Button(ctx, pin..'##active'..str_id,UI.ctrl_w_active) then t.PMOD['mod.active']=t.PMOD['mod.active']~1 DATA:ApplyPMOD(t) end
      ImGui.PopStyleVar(ctx)
      UI.draw_unsetbuttonstyle()
      if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
        if not DATA.modulationstate_ext[str_id].pin then DATA.modulationstate_ext[str_id].pin = 1 else DATA.modulationstate_ext[str_id].pin = DATA.modulationstate_ext[str_id].pin ~1 end
        DATA.upd_projextstate = true
        DATA.upd = true
      end
      ImGui.SameLine(ctx)
      --ImGui.SetItemTooltip( ctx, 'Bypass' )
    -- base
      UI.draw_knob(
        {butGUID = t.butGUID,
        param_key = 'mod.baseline',
        srct = t,
        --tooltip = 'Base value' ,
        formatstr = function(v) return 'Base value: '..math.floor(v*1000)/1000 end}) 
      ImGui.SameLine(ctx)
    -- name .
      local namew = -(UI.calc_itemH+UI.spacingX)*2
      if not t.rename_input_mode then  
        if ImGui.Button(ctx, DATA.modulationstate_ext[str_id].alias or t.UI_name,namew) then t.PMOD['mod.visible']=t.PMOD['mod.visible']~1 DATA:ApplyPMOD(t) end
        if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
          t.rename_input_mode = true
        end
       else
        ImGui.SetKeyboardFocusHere( ctx, 0 )
        ImGui.SetNextItemWidth(ctx,namew)
        
        local retval, buf = reaper.ImGui_InputText( ctx, '##renamemodalias'..str_id, DATA.modulationstate_ext[str_id].alias or t.UI_name, ImGui.InputTextFlags_EnterReturnsTrue|ImGui.InputTextFlags_AutoSelectAll )
        if retval then 
          if buf ~= '' and buf~=t.UI_name then 
            DATA.modulationstate_ext[str_id].alias = buf 
           else 
            DATA.modulationstate_ext[str_id].alias = nil 
          end
          DATA.upd_projextstate = true
          t.rename_input_mode = nil
          DATA.upd = true
        end
      end
      ImGui.SameLine(ctx)
      
    -- color
      
      local retval, col_rgba = reaper.ImGui_ColorEdit4( ctx, '##col', DATA.modulationstate_ext[str_id].col_rgba or 0x7F7F7F0F, ImGui.ColorEditFlags_NoBorder|ImGui.ColorEditFlags_NoInputs|ImGui.ColorEditFlags_NoSidePreview)--ImGui.ColorEditFlags_NoAlpha|
      if retval then  
        DATA.modulationstate_ext[str_id].col_rgba = col_rgba
        DATA.upd_projextstate = true
      end
      if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
        DATA.modulationstate_ext[str_id].col_rgba = 0x7F7F7F0F
        DATA.upd_projextstate = true 
      end
      ImGui.SameLine(ctx)
      
    -- collapse
      if ImGui_ArrowButton( ctx, str_id..'collapse', ImGui.Dir_Down ) then 
        DATA.modulationstate_ext[str_id].collapsed_state = DATA.modulationstate_ext[str_id].collapsed_state~1
        DATA.upd_projextstate = true
      end  
      
    -- controls
      if DATA.modulationstate_ext[str_id].collapsed_state == 0 then 
        UI.draw_mods_lfo(t) 
        UI.draw_mods_audio(t) 
        UI.draw_mods_link(t) 
      end
    
    ImGui.EndChild(ctx)
  end
  
  ImGui.PopStyleColor(ctx,2)
  
  if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then DATA.SetSelection(t) end
  
end
--------------------------------------------------------------------------------  
function DATA.SetSelection(t)
  local str_id = t.fxGUID..'_'..t.param
  DATA.modulationstate_ext.selected_key = str_id
  DATA.upd_projextstate = true
end
--------------------------------------------------------------------------------  
function UI.draw_mods()  
  for ts in spairs(DATA.modulationstate_order) do
    local mainkey = DATA.modulationstate_order[ts]
    
    
    UI.draw_mods_sub(DATA.modulationstate[mainkey]) 
  end
end
---------------------------------------------------------------------
function DATA:Action_ActiveteLastTouchedParam()   
    local retval, trackidx, itemidx, takeidx, fxidx, parm = GetTouchedOrFocusedFX( 0 )
    if not retval then return end
    local track = GetMasterTrack(0)
    if trackidx >=0 then track = GetTrack(0,trackidx) end
    TrackFX_SetNamedConfigParm( track, fxidx, 'param.'..parm..'.mod.active', 1)
    DATA.upd = true
end
--------------------------------------------------------------------------------  
function DATA:LiveLink()
  if not DATA.LiveLinkT.run then return end
  local trig
  local retval, trackidx, itemidx, takeidx, fxidx, parm = GetTouchedOrFocusedFX( 0 )
  if not retval then return end 
  local track = GetMasterTrack(0) if trackidx >=0 then track = GetTrack(0,trackidx) end
  local FXout = trackidx|(fxidx<<8)|(parm<<16)
  if not DATA.upd_lastFXout2 or (DATA.upd_lastFXout2 and DATA.upd_lastFXout2~=FXout ) then  
    trig = true
    DATA.upd_lastFXout2 = FXout
  end
  
  -- ref
    if trig == true and not DATA.LiveLinkT.reference then
      DATA.LiveLinkT.reference = {
        track= track,
        fxidx=fxidx,
        parm=parm,
      }
      return 
    end
  
  -- dub
  if trig == true then  end
    
    if trig == true and DATA.LiveLinkT.reference then
      local retval, param = TrackFX_GetNamedConfigParm( track, fxidx, 'param.'..parm..'.plink.active')
      if not retval then
        if not DATA.LiveLinkT.dub then DATA.LiveLinkT.dub = {} end
        DATA.LiveLinkT.dub[#DATA.LiveLinkT.dub+1] = {
          track= track,
          fxidx=fxidx,
          parm=parm,
        }
        
        if track == DATA.LiveLinkT.reference.track then
          TrackFX_SetNamedConfigParm( track, fxidx, 'param.'..parm..'.mod.active', 1)
          TrackFX_SetNamedConfigParm( track, fxidx, 'param.'..parm..'.plink.active', 1)
          TrackFX_SetNamedConfigParm( track, fxidx, 'param.'..parm..'.plink.effect', DATA.LiveLinkT.reference.fxidx)
          TrackFX_SetNamedConfigParm( track, fxidx, 'param.'..parm..'.plink.param', DATA.LiveLinkT.reference.parm)
          DATA.upd = true
        end
      end
    end   
  
end
--------------------------------------------------------------------------------  
function UI.draw_menu()  
  if ImGui.BeginMenuBar( ctx ) then
    UI.draw_setbuttoncolor(UI.main_col,0.3) 
    if ImGui.Button( ctx, 'Activate for last touched') then DATA:Action_ActiveteLastTouchedParam()   end 
    if DATA.LiveLinkT.run == true then 
      UI.draw_setbuttoncolor(0xFF0000, DATA.alpha) 
     else
      UI.draw_setbuttoncolor(UI.main_col,0.3)
    end
    if ImGui.Button( ctx, 'Link to last touched' ) then  if DATA.LiveLinkT.run == true then DATA.LiveLinkT.run = nil else DATA.LiveLinkT.run = true  end end
    
    if ImGui.BeginMenu( ctx, 'Filter', true ) then
      if ImGui.MenuItem( ctx, 'No filter', nil, EXT.CONF_filtermode==0, true ) then EXT.CONF_filtermode=0 EXT:save() DATA.upd = true end
      if ImGui.MenuItem( ctx, 'Selected track', nil, EXT.CONF_filtermode==1, true ) then EXT.CONF_filtermode=1 EXT:save() DATA.upd = true end
      if ImGui.MenuItem( ctx, 'Focused FX', nil, EXT.CONF_filtermode==2, true ) then EXT.CONF_filtermode=2 EXT:save() DATA.upd = true end
      ImGui.EndMenu( ctx)
    end

    if ImGui.BeginMenu( ctx, 'Actions', true ) then
      if ImGui.MenuItem( ctx, 'Collapse all', nil, nil, true ) then  for str_id in pairs(DATA.modulationstate_ext) do if type(DATA.modulationstate_ext[str_id]) == 'table' then DATA.modulationstate_ext[str_id].collapsed_state = 1 end DATA.upd_projextstate = true end end
      if ImGui.MenuItem( ctx, 'Expand all', nil, nil, true ) then  for str_id in pairs(DATA.modulationstate_ext) do if type(DATA.modulationstate_ext[str_id]) == 'table' then DATA.modulationstate_ext[str_id].collapsed_state = 0 end DATA.upd_projextstate = true end end
      ImGui.SeparatorText(ctx,'Options')
      if ImGui.MenuItem( ctx, 'No Dock', nil, nil, true ) then EXT.CONF_dock = 0 EXT:save() DATA.upd = true end
      if ImGui.MenuItem( ctx, 'Dock -1', nil, nil, true ) then EXT.CONF_dock = -1 EXT:save() end
      if ImGui.MenuItem( ctx, 'Dock -2', nil, nil, true ) then EXT.CONF_dock = -2 EXT:save() end
      if ImGui.MenuItem( ctx, 'Dock -4', nil, nil, true ) then EXT.CONF_dock = -4 EXT:save() end
      if ImGui.MenuItem( ctx, 'Dock -8', nil, nil, true ) then EXT.CONF_dock = -8 EXT:save() end
      
      ImGui.EndMenu( ctx)
    end
    
    UI.draw_unsetbuttonstyle()
    UI.draw_unsetbuttonstyle()
    ImGui.EndMenuBar( ctx )
  end
end
--------------------------------------------------------------------------------  
function UI.draw()  
  UI.draw_menu()
  UI.draw_mods()
  UI.draw_popups()  
end
--------------------------------------------------------------------------------  
function UI.draw_popups()  
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
--------------------------------------------------------------------------------  
function UI.draw_unsetbuttonstyle() UI.MAIN_PopStyle(ctx, nil, 3)end
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
function DATA:handleViewportXYWH()
  if EXT.CONF_dock ~=0 or DATA.display_dock ~= 0  then return end
  if not (DATA.display_x and DATA.display_y) then return end 
  if not DATA.display_x_last then DATA.display_x_last = DATA.display_x end
  if not DATA.display_y_last then DATA.display_y_last = DATA.display_y end
  if not DATA.display_w_last then DATA.display_w_last = DATA.display_w end
  if not DATA.display_h_last then DATA.display_h_last = DATA.display_h end
  if not DATA.display_dock_last then DATA.display_dock_last = DATA.display_dock end
  if  DATA.display_x_last~= DATA.display_x 
    or DATA.display_y_last~= DATA.display_y 
    or DATA.display_w_last~= DATA.display_w 
    or DATA.display_h_last~= DATA.display_h 
    or DATA.display_dock_last~= DATA.display_dock 
    then 
    
    DATA.display_schedule_save = os.clock() 
  end
  if DATA.display_schedule_save and os.clock() - DATA.display_schedule_save > 0.3 then 
    EXT.viewport_posX = DATA.display_x
    EXT.viewport_posY = DATA.display_y
    EXT.viewport_posW = DATA.display_w
    EXT.viewport_posH = DATA.display_h
    EXT.viewport_dock = DATA.display_dock
    EXT:save() 
    DATA.display_schedule_save = nil 
  end
  DATA.display_x_last = DATA.display_x
  DATA.display_y_last = DATA.display_y
  DATA.display_w_last = DATA.display_w
  DATA.display_h_last = DATA.display_h
  DATA.display_dock_last = DATA.display_dock
end
-------------------------------------------------------------------------------- 
function DATA:handleProjUpdates()
  local retval, trackidx, itemidx, takeidx, fxidx, parm = reaper.GetTouchedOrFocusedFX( 1 ) -- query focused fx
  local FXout = trackidx|(fxidx<<16) if (DATA.upd_lastFXout and DATA.upd_lastFXout~=FXout ) then DATA.upd = true end  DATA.upd_lastFXout = FXout
  local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
  local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
  local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
end
---------------------------------------------------------------------  
function DATA:ApplyPMOD(t)
  local param_t = t
  local params = {
    'mod.active',
    'mod.baseline',
    'mod.visible',
    
    'plink.active',
    'plink.scale',
    'plink.offset',
    'plink.effect',
    'plink.param',
    'plink.midi_bus',
    'plink.midi_chan',
    'plink.midi_msg',
    'plink.midi_msg2',
    
    'acs.active',
    'acs.dir',
    'acs.strength',
    'acs.attack',
    'acs.release',
    'acs.dblo',
    'acs.dbhi',
    'acs.chan',
    'acs.stereo',
    'acs.x2',
    'acs.y2',
    
    'lfo.active',
    'lfo.dir',
    'lfo.phase',
    'lfo.speed',
    'lfo.strength',
    'lfo.temposync',
    'lfo.free',
    'lfo.shape',
    
    }
  local ret, track, fx = VF_GetFXByGUID(t.fxGUID)
  local pid = param_t.param
  if ret and pid then 
    for i = 1, #params do 
      local ret, paramval = TrackFX_GetNamedConfigParm( track, fx, 'param.'..pid..params[i] )
      local outval = param_t.PMOD[params[i]] 
      
      if tonumber(paramval)~=outval then TrackFX_SetNamedConfigParm( track, fx, 'param.'..pid..params[i], outval) end
    end
  end
  
end
  ---------------------------------------------------
  function VF_GetFXByGUID(GUID, tr, proj)
    if not GUID then return end
    local pat = '[%p]+'
    if not tr then
      for trid = 1, CountTracks(proj or -1) do
        local tr = GetTrack(0,trid-1)
        local fxcnt_main = TrackFX_GetCount( tr ) 
        local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
        for fx = 1, fxcnt do
          local fx_dest = fx
          if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
          if TrackFX_GetFXGUID( tr, fx-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx-1 end 
        end
      end  
     else
      if not (ValidatePtr2(proj or -1, tr, 'MediaTrack*')) then return end
      local fxcnt_main = TrackFX_GetCount( tr ) 
      local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
      for fx = 1, fxcnt do
        local fx_dest = fx
        if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
        if TrackFX_GetFXGUID( tr, fx_dest-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx_dest-1 end 
      end
    end    
  end
-----------------------------------------------------------------------------------------
main()
  
  
  
  