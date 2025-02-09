-- @description CopyPaste plugin data
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @about test
-- @changelog
--    # improve migrating fab filter 2 to 3/4




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
        CONF_namefilter = '[vst name]',
        CONF_transfer_vstchunk = 0,
        CONF_transfer_fx_name = 1,
        CONF_transfer_force_auto_bypass = 1,
        CONF_transfer_parallel = 1,
        CONF_transfer_instance_oversample_shift = 1,
        CONF_transfer_parameters = 1,
        CONF_transfer_envelope = 1|2, --&2 do not overwrite if exist
        CONF_transfer_modlearn = 1,
        
      }
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'MPL_CopyPasteFX',
        UI_name = 'CopyPaste plugin data', 
        upd = true, 
        preset_name = 'untitled', -- for inputtext
        presets_factory = {
          },
        presets = {
          factory= {},
          user= {}, 
          },
          
        fx={},
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
  UI.knob_resY = 120
  






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
  local w_min = 250
  local h_min = 80
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
    local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
    ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
    --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    ImGui.SetNextWindowSize(ctx, 400, 350, ImGui.Cond_Always)
    
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
function DATA:CollectData() 
  --DATA:CollectData_Get() 
end
-------------------------------------------------------------------------------- 
function DATA:CollectData_Get() 
  DATA.fx = {}
  
  local retval, trackidx, itemidx, takeidx, fxidx, parm = reaper.GetTouchedOrFocusedFX(1)
  if retval~= true then return end
  
  local track if trackidx==-1 then track = reaper.GetMasterTrack(-1) else track = GetTrack(-1,trackidx) end
  if not track  then return end 
  
  DATA.fx.focused_exists = true
  DATA.fx.offline = TrackFX_GetOffline( track, fxidx )
  DATA.fx.srctr=track
  _,DATA.fx.srctr_name=reaper.GetTrackName(track)
  DATA.fx.fxidx=fxidx
  if itemidx ~=-1 then 
    local it = GetMediaItem(-1,itemidx)
    DATA.fx.srcit = it
    DATA.fx.srctk = GetTake(it,takeidx)
    DATA.fx.fxGUID = reaper.TakeFX_GetFXGUID(DATA.fx.srctk,fxidx)
    DATA.fx.istakefx = true
   else
    DATA.fx.fxGUID = TrackFX_GetFXGUID(track,fxidx)
  end
  
  if DATA.fx.istakefx ~= true then 
    GetNamedConfigParm = TrackFX_GetNamedConfigParm 
    ptr = DATA.fx.srctr
   else 
    GetNamedConfigParm = TakeFX_GetNamedConfigParm 
    ptr = DATA.fx.srctk
  end
  
  _, DATA.fx.fx_type = GetNamedConfigParm( ptr, fxidx, 'fx_type' )
  _, DATA.fx.fx_name = GetNamedConfigParm( ptr, fxidx, 'fx_name' )
  _, DATA.fx.force_auto_bypass = GetNamedConfigParm( ptr, fxidx, 'force_auto_bypass' )
  _, DATA.fx.parallel = GetNamedConfigParm( ptr, fxidx, 'parallel' )
  _, DATA.fx.instance_oversample_shift = GetNamedConfigParm( ptr, fxidx, 'instance_oversample_shift' )
  
  DATA.fx.fx_name_reduced = VF_ReduceFXname(DATA.fx.fx_name)
  local filt = DATA.fx.fx_name_reduced:gsub('%d+','')
  filt = filt:gsub('%p+','')
  filt = filt:gsub('%s+','')
  EXT.CONF_namefilter = filt
  
  DATA:CollectData_Get_Parameters(ptr,fxidx, GetNamedConfigParm) 
  -- parammod
  -- learn
  -- envelopes
end
-------------------------------------------------------------------------------- 
function DATA:CollectData_Get_Parameters(track, fxidx, GetNamedConfigParm) 
  DATA.fx.PARAMS = {param_data = {}}
  local cnt = reaper.TrackFX_GetNumParams( track, fxidx )
  DATA.fx.PARAMS.cnt=cnt
  
  local duplicates_cnt = 0
  local paramnames = {}
  for paramid = 1, cnt do
    local retval, pname = reaper.TrackFX_GetParamName( track, fxidx, paramid-1 )
    if not paramnames[pname] then
      local val, minval, maxval = reaper.TrackFX_GetParam( track, fxidx,  paramid-1 )
      
      -- envelope
      local fxenv = GetFXEnvelope( track, fxidx, paramid-1, false ) 
      local env = {} 
      if fxenv then 
        local scaling_mode = reaper.GetEnvelopeScalingMode( fxenv )
        local pointscnt = CountEnvelopePoints( fxenv )
        for ptidx = 1, pointscnt do
          local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint( fxenv, ptidx-1 )
          env[ptidx] = {time=time, value = ScaleFromEnvelopeMode( scaling_mode, value ), shape=shape, tension=tension, selected=selected}
        end
      end
      
      -- pmod
      local pmod = {mod={},lfo={},acs={},learn={},plink={}}
      _, pmod.lfo.active = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.active' )
      _, pmod.lfo.dir = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.dir' )
      _, pmod.lfo.phase = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.phase' )
      _, pmod.lfo.speed = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.speed' )
      _, pmod.lfo.strength = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.strength' )
      _, pmod.lfo.temposync = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.temposync' )
      _, pmod.lfo.free = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.free' )
      _, pmod.lfo.shape = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.shape' )
      
      _, pmod.acs.active = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.active' )
      _, pmod.acs.dir = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.dir' )
      _, pmod.acs.strength = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.strength' )
      _, pmod.acs.attack = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.attack' )
      _, pmod.acs.release = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.release' )
      _, pmod.acs.dblo = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.dblo' )
      _, pmod.acs.dbhi = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.dbhi' )
      _, pmod.acs.chan = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.chan' )
      _, pmod.acs.stereo = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.stereo' )
      _, pmod.acs.x2 = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.x2' )
      _, pmod.acs.y2 = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.y2' )
      
      _, pmod.mod.active = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.mod.active' )
      _, pmod.mod.baseline = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.mod.baseline' )
      _, pmod.mod.visible = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.mod.visible' )
      
      _, pmod.learn.midi1 = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.learn.midi1' )
      _, pmod.learn.midi2 = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.learn.midi2' )
      _, pmod.learn.osc = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.learn.osc' )
      _, pmod.learn.mode = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.learn.mode' )
      _, pmod.learn.flags = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.learn.flags' )
      
      _, pmod.plink.active = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.active' )
      _, pmod.plink.scale = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.scale' )
      _, pmod.plink.offset = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.offset' )
      _, pmod.plink.effect = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.effect' )
      if tonumber(pmod.plink.effect) and tonumber(pmod.plink.effect) > fxidx then
        pmod.plink.effect = pmod.plink.effect + 1 -- increase in case of source link effect placed below FX in the chain
      end
      _, pmod.plink.param = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.param' )
      _, pmod.plink.midi_bus = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.midi_bus' )
      _, pmod.plink.midi_chan = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.midi_chan' )
      _, pmod.plink.midi_msg = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.midi_msg' )
      _, pmod.plink.midi_msg2 = GetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.midi_msg2' )
      
      
      DATA.fx.PARAMS.param_data[pname] = 
        {
           val=val, 
           minval=minval, 
           maxval=maxval,
           env = env,
           pmod = pmod,
        }
     else
      duplicates_cnt = duplicates_cnt + 1
    end
    paramnames[pname] = 1
  end
  
  DATA.fx.PARAMS.cnt_duplicates_cnt=duplicates_cnt
  
  
end
  ------------------------------------------------------------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end  
-------------------------------------------------------------------------------- 
function DATA:Transfer_GetSetRawChunk(track, fxGUID, replacechunk) 
  if not (track and fxGUID) then return end
  local _, chunk = reaper.GetTrackStateChunk(track, '')
  local chunk_t = {}
  for vstchunks in chunk:gmatch("(%<VST.-WAK)") do  table.insert(chunk_t, vstchunks)  end      
  local vstchunk
  for vstchunkid=1,#chunk_t do 
    vstchunk=chunk_t[vstchunkid]
    if vstchunk:match(literalize(fxGUID))~=nil then
      vstchunk = vstchunk:match('[\r\n](.-)>')
      
      if replacechunk then
        --[[msg(replacechunk)
        msg('\n\n\n\nVSTCHUNK\n\n\n')
        msg(vstchunk)
        msg('\n\n\n\n')]]
        --msg(chunk) 
        --msg('\n\n\n\n')
        chunk=chunk:gsub(literalize(vstchunk),replacechunk)
        --msg(chunk)
        SetTrackStateChunk(track, chunk, true)
      end
      break
    end
  end     
  
  
  if vstchunk and not replacechunk then
    DATA.fx.vst_chunk = vstchunk
    DATA.fx.vst_chunk_sz = vstchunk:len()
    DATA.fx.has_chunk = true
  end
  
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
--------------------------------------------------- 
function DATA.EnumeratePlugins()
  DATA.plugs_data = {} 
  for i = 1, 10000 do
    local retval, name, ident = reaper.EnumInstalledFX( i-1 )
    if not retval then break end
    --if name:match('VST3%:') or name:match('VST%:') then
      DATA.plugs_data[#DATA.plugs_data+1] = {name = name, 
                                   reduced_name = VF_ReduceFXname(name) ,
                                   ident = ident}
    --end                                   
  end
  return plugs_data
end
  ---------------------------------------------------
  function VF_ReduceFXname(s)
    local s_out = s:match('[%:%/%s]+(.*)')
    if not s_out then return s end
    s_out = s_out:gsub('%(.-%)','') 
    --if s_out:match('%/(.*)') then s_out = s_out:match('%/(.*)') end
    local pat_js = '.*[%/](.*)'
    if s_out:match(pat_js) then s_out = s_out:match(pat_js) end  
    if s_out then
      s_out= s_out:gsub("^%s*(.-)%s*$", "%1")
    end
    if not s_out then return s else 
      if s_out ~= '' then return s_out else return s end
    end
  end
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
  
  DATA.EnumeratePlugins()
  
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
function UI.MAIN_shortcuts()
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then 
    for key in pairs(UI.popups) do UI.popups[key].draw = false end
    ImGui.CloseCurrentPopup( ctx ) 
  end
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_Space,false )  then  reaper.Main_OnCommand(40044,0) end
end
--------------------------------------------------------------------------------  
function DATA:CollectData_GetDestination() 
  DATA.dest_ident = {}
  local sz = #DATA.plugs_data
  local filt = EXT.CONF_namefilter:lower():gsub('%p','')
  for i = 1, sz do
    local checkname = DATA.plugs_data[i].reduced_name:gsub('%p',''):lower()
    if checkname:match('%:(.*)') then checkname = checkname:match('%:(.*)')end
    if checkname:match('%(.-%)') then checkname = checkname:gsub('(%(.-%))','')end
    if checkname:match(filt)~=nil or checkname:match(filt)~=nil then
      DATA.dest_ident[#DATA.dest_ident+1] = DATA.plugs_data[i]
    end
  end
  
  if DATA.dest_ident[1] then DATA.dest_ident[1].selected = true end
end
--------------------------------------------------------------------------------  
function UI.draw()  
  -- search src
  if ImGui.Button(ctx, 'Search for data in focused FX',200) then 
    DATA:CollectData_Get() 
    DATA:Transfer_GetSetRawChunk(DATA.fx.srctr,DATA.fx.fxGUID) 
    DATA:CollectData_GetDestination() 
  end
  
  -- transfer
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Transfer data to focused FX',-1) then  DATA:Transfer() end
  
  -- info
  if ImGui.BeginChild(ctx,'info',0,40,reaper.ImGui_ChildFlags_Border()) then
    if DATA.fx.focused_exists==true then
      ImGui.Text(ctx,DATA.fx.srctr_name)
      ImGui.Text(ctx,DATA.fx.fx_name)
    end 
    ImGui.EndChild(ctx)
  end
  
   
  -- settings
  if ImGui.BeginChild(ctx,'settings',0,-1,reaper.ImGui_ChildFlags_Border()) then
    str = '[no vst data found]'
    if DATA.fx.has_chunk==true then str = 'VST data ('..DATA.fx.vst_chunk_sz..' characters)' end 
    if EXT.CONF_transfer_vstchunk ==1 then str=str..' USE WITH CARE!' end
    UI.draw_flow_CHECK({['key']=str,               ['extstr'] = 'CONF_transfer_vstchunk'}) 
    local paramsstr = 'Parameters [unknown]'
    if DATA.fx.PARAMS and DATA.fx.PARAMS.cnt then 
      paramsstr = 'Parameters ('..DATA.fx.PARAMS.cnt..' found, '..DATA.fx.PARAMS.cnt_duplicates_cnt..' duplicates ignored)'
    end
    if EXT.CONF_transfer_vstchunk~=1 then 
      --UI.draw_flow_CHECK({['key']='FX name',               ['extstr'] = 'CONF_transfer_fx_name'})
      UI.draw_flow_CHECK({['key']=paramsstr,               ['extstr'] = 'CONF_transfer_parameters'})
      if EXT.CONF_transfer_parameters == 1 then
        UI.draw_flow_CHECK({['key']='Envelope',               ['extstr'] = 'CONF_transfer_envelope',confkeybyte = 0})
        if EXT.CONF_transfer_envelope&1==1 then
          ImGui.Indent(ctx,10)
          UI.draw_flow_CHECK({['key']='Do not overwrite if envelope exists',               ['extstr'] = 'CONF_transfer_envelope',confkeybyte = 1})
          ImGui.Unindent(ctx,10)
        end
        UI.draw_flow_CHECK({['key']='Mod/Learn',               ['extstr'] = 'CONF_transfer_modlearn'})
      end
      UI.draw_flow_CHECK({['key']='Options: Force auto bypass',               ['extstr'] = 'CONF_transfer_force_auto_bypass'})
      UI.draw_flow_CHECK({['key']='Options: Parallel',               ['extstr'] = 'CONF_transfer_parallel'})
      UI.draw_flow_CHECK({['key']='Options: Oversample shift',               ['extstr'] = 'CONF_transfer_instance_oversample_shift'})
    end 
    ImGui.EndChild(ctx)
  end
  
  
  --[[ dest fx name
    ImGui.SetNextItemWidth( ctx, -100 )
    local retval, buf = ImGui.InputText( ctx, '##inpfilt', EXT.CONF_namefilter, ImGui.InputTextFlags_EnterReturnsTrue|ImGui.InputTextFlags_AutoSelectAll ) 
    if retval then 
      EXT.CONF_namefilter = buf
      EXT:save()
      DATA:CollectData_GetDestination() 
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx,'Search',-1,0) then
      EXT.CONF_namefilter = buf
      EXT:save()
      DATA:CollectData_GetDestination() 
    end
  
  
  -- destination fx
    if DATA.dest_ident and #DATA.dest_ident>0 then
      ImGui.SetNextItemWidth( ctx, -1 )
      local sel_prev=''
      local sel_id
      for i=1,#DATA.dest_ident do 
        if DATA.dest_ident[i].selected == true then sel_prev = DATA.dest_ident[i].name sel_id = i break end 
      end
      if ImGui.BeginCombo( ctx, '##combsel', sel_prev, flagsIn ) then
        for i=1,#DATA.dest_ident do
          local retval, p_selected = reaper.ImGui_Selectable( ctx, DATA.dest_ident[i].name..'##comb'..i, DATA.dest_ident[i].selected, flagsIn, size_wIn, size_hIn )
          if retval then 
            DATA.dest_ident[i].selected = true 
            if sel_id then DATA.dest_ident[sel_id].selected = false end 
          end
        end
        ImGui.EndCombo( ctx) 
      end
    end
  ]]
  
    
  -- popups
    UI.draw_popups()  
end
-------------------------------------------------------------------------------- 
function DATA:Transfer()
  
  --[[ add fx
  if not (DATA.dest_ident and #DATA.dest_ident>0)  then return end
  for i=1,#DATA.dest_ident do 
    if DATA.dest_ident[i].selected == true then sel_id = i break end 
  end 
  if not sel_id then sel_id = 1 end 
  local dest_ident = DATA.dest_ident[sel_id].ident
  local fxid = TrackFX_AddByName( DATA.fx.srctr, dest_ident, false, -1 )]]
  
  local retval, trackidx, itemidx, takeidx, fxid, parm = reaper.GetTouchedOrFocusedFX(1)
  if retval~= true then return end 
  local desttr if trackidx==-1 then desttr = reaper.GetMasterTrack(-1) else desttr = GetTrack(-1,trackidx) end
  if not desttr  then return end 
  
  -- transfer raw data 
  if EXT.CONF_transfer_vstchunk ==1 and DATA.fx.has_chunk == true then 
    local fxGUID = reaper.TrackFX_GetFXGUID(desttr, fxid)
    DATA:Transfer_GetSetRawChunk(desttr, fxGUID, DATA.fx.vst_chunk)   
    --TrackFX_SetNamedConfigParm(desttr, fxid, 'vst_chunk',DATA.fx.vst_chunk)
    return
  end
  
  -- transfer data via API
  --if EXT.CONF_transfer_fx_name == 1 then TrackFX_SetNamedConfigParm( desttr, fxid, 'renamed_name',DATA.fx.fx_name ) end
  if EXT.CONF_transfer_force_auto_bypass == 1 then TrackFX_SetNamedConfigParm(desttr, fxid, 'force_auto_bypass',DATA.fx.force_auto_bypass ) end
  if EXT.CONF_transfer_parallel == 1 then TrackFX_SetNamedConfigParm( desttr, fxid, 'parallel',DATA.fx.parallel ) end
  if EXT.CONF_transfer_instance_oversample_shift == 1 then TrackFX_SetNamedConfigParm(desttr, fxid, 'instance_oversample_shift',DATA.fx.instance_oversample_shift ) end
  if EXT.CONF_transfer_parameters == 1 then DATA:Transfer_Parameters( desttr, fxid) end
  
end
-------------------------------------------------------------------------------- 
function DATA:Transfer_Parameters_ScaleToDestParam( dest_track, dest_fx, paramid, src_val, minval, maxval,minval_src, maxval_src, src_pname)
  local normalized = (src_val-minval) / (maxval - minval) 
  local outval = minval_src + (maxval_src - minval_src) * normalized
  TrackFX_SetParam( dest_track, dest_fx,  paramid, outval)
  
  
end
-------------------------------------------------------------------------------- 
function DATA:Transfer_Parameters_PortEnvelope( dest_track, dest_fx, paramid, srcenv,minval, maxval,minval_src, maxval_src )
  if EXT.CONF_transfer_envelope == 1 and srcenv and #srcenv > 0  then
    local fxenv_exist = GetFXEnvelope( dest_track, dest_fx, paramid , false )~=nil
    local fxenv = GetFXEnvelope( dest_track, dest_fx, paramid , true ) 
    if EXT.CONF_transfer_envelope&2~=2 or (EXT.CONF_transfer_envelope&2==2 and fxenv_exist == false) then
      DeleteEnvelopePointRange( fxenv, 0, math.huge )
      local pointscnt = #srcenv
      local scaling_mode = reaper.GetEnvelopeScalingMode( fxenv )
      for ptidx = 1, pointscnt do
        local pt = srcenv[ptidx]
        local normalized = (pt.value-minval) / (maxval - minval) 
        local outval = minval_src + (maxval_src - minval_src) * normalized
        InsertEnvelopePoint( fxenv, pt.time, outval, pt.shape, pt.tension, pt.selected, true )
        Envelope_SortPoints(fxenv)
      end
    end 
  end
end
-------------------------------------------------------------------------------- 
function DATA:Transfer_Parameters_sub( dest_track, dest_fx, paramid, srct, overrides, src_pname)
  
  local _,minval_src, maxval_src = TrackFX_GetParam(dest_track, dest_fx,  paramid ) 
  -- param
  local minval = srct.minval
  local maxval = srct.maxval
  local src_val = srct.val 
  if overrides.minval then minval = overrides.minval end
  if overrides.maxval then maxval = overrides.maxval end
  if overrides.minval_src then minval_src = overrides.minval_src end
  if overrides.maxval_src then maxval_src = overrides.maxval_src end
  DATA:Transfer_Parameters_ScaleToDestParam( dest_track, dest_fx , paramid,src_val,minval, maxval,minval_src, maxval_src,src_pname)
  -- envelope
  local srcenv = srct.env
  DATA:Transfer_Parameters_PortEnvelope( dest_track, dest_fx, paramid,srcenv,minval, maxval,minval_src, maxval_src ) 
  -- mod/learn
  if EXT.CONF_transfer_modlearn == 1 then DATA:Transfer_Parameters_ModLearn(dest_track, dest_fx, paramid,srct.pmod) end 
end

-------------------------------------------------------------------------------- 
function DATA:Transfer_Parameters( dest_track, dest_fx)
  if not (DATA.fx.PARAMS and DATA.fx.PARAMS.param_data) then return end
  local _, destfxname = GetNamedConfigParm( dest_track, dest_fx, 'fx_name' )
  local proq3_to_4 = DATA.fx.fx_name:match(literalize('Pro-Q 3')) and destfxname:match(literalize('Pro-Q 4'))
  local proq2_to_3 = DATA.fx.fx_name:match(literalize('Pro-Q 2')) and destfxname:match(literalize('Pro-Q 3'))
  local proq2_to_4 = DATA.fx.fx_name:match(literalize('Pro-Q 2')) and destfxname:match(literalize('Pro-Q 4'))
   
  -- transfer stuff
  local cnt = TrackFX_GetNumParams(  dest_track, dest_fx)
  for paramid = 1, cnt do
    local retval, pname = TrackFX_GetParamName( dest_track, dest_fx, paramid-1 ) 
    local src_pname = pname
    local overrides = {}
    if proq2_to_4 and src_pname:match('Shape') then overrides.maxval_src = 7/9 end
    if proq2_to_3 and src_pname:match('Shape') then overrides.maxval_src = 7/8 end 
    if proq3_to_4 and src_pname:match('Shape') then overrides.maxval_src = 8/9 end -- fix 8 vs 9 shapes but the limits still 0...1 
    
    if proq2_to_3 and pname:match('Used') then src_pname = pname:gsub('Used','State') overrides.minval = 1 overrides.maxval = 0.5  end
    if proq2_to_3 and pname:match('Enabled') then src_pname = pname:gsub('Enabled','State') overrides.minval = 0 overrides.maxval = 0.5 end
    if proq2_to_3 and pname:match('Stereo') then overrides.minval = 0 overrides.maxval_src = 2/4 end
    
    if DATA.fx.PARAMS.param_data[src_pname] then DATA:Transfer_Parameters_sub( dest_track, dest_fx, paramid-1, DATA.fx.PARAMS.param_data[src_pname], overrides, src_pname) end
     
  end
end
--------------------------------------------------------------------------------  
function DATA:Transfer_Parameters_ModLearn( track, fxidx, paramid, pmod)
  local SetNamedConfigParm = TrackFX_SetNamedConfigParm
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.active', pmod.lfo.active )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.dir',pmod.lfo.dir )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.phase', pmod.lfo.phase )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.speed', pmod.lfo.speed )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.strength', pmod.lfo.strength )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.temposync', pmod.lfo.temposync )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.free', pmod.lfo.free )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.lfo.shape', pmod.lfo.shape )
  
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.active', pmod.acs.active )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.dir', pmod.acs.dir )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.strength', pmod.acs.strength )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.attack', pmod.acs.attack )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.release', pmod.acs.release )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.dblo', pmod.acs.dblo )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.dbhi', pmod.acs.dbhi )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.chan', pmod.acs.chan )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.stereo', pmod.acs.stereo )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.x2', pmod.acs.x2 )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.acs.y2', pmod.acs.y2 )
  
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.mod.active', pmod.mod.active )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.mod.baseline', pmod.mod.baseline )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.mod.visible', pmod.mod.visible )
  
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.learn.midi1', pmod.learn.midi1 )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.learn.midi2', pmod.learn.midi2 )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.learn.osc', pmod.learn.osc )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.learn.mode', pmod.learn.mode )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.learn.flags', pmod.learn.flags )
  
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.active', pmod.plink.active )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.scale', pmod.plink.scale )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.offset', pmod.plink.offset )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.effect', pmod.plink.effect )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.param', pmod.plink.param )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.midi_bus', pmod.plink.midi_bus )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.midi_chan', pmod.plink.midi_chan )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.midi_msg', pmod.plink.midi_msg )
  SetNamedConfigParm( ptr, fxidx, 'param.'..(paramid-1)..'.plink.midi_msg2', pmod.plink.midi_msg2 )
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
function UI.draw_unsetbuttonstyle() UI.MAIN_PopStyle(ctx, nil, 3)end
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
-----------------------------------------------------------------------------------------
main()
  