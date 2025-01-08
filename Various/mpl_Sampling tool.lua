-- @description Sampling tool
-- @version 2.0
-- @author MPL
-- @about Sample instrument to a rs5k sampler
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Ported to ReaImGui
--    - Removed schedule mode, not really stable
    
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
          viewport_posX = 10,
          viewport_posY = 10,
          viewport_posW = 640,
          viewport_posH = 480, 
          
          -- genarate midi
          CONF_notelen_beats = 4,
          CONF_notetail_beats = 8,
          CONF_notestart = 60,
          CONF_noteend = 72,
          CONF_itempos_beats = 0,
          
          CONF_schedmode = 1,
          CONF_schedmode_s = 0.5, 
          CONF_showflag = 2,
          CONF_rename = 1,
          CONF_rename_wildcard = '#fxname sampled - #note ',
          CONF_addtestmidiitem = 1,
          CONF_extend_bounds = 1, 
          CONF_renameMEnotes = 1, 
          CONF_setobeynoteoff = 0, 
          
          
        }
  -------------------------------------------------------------------------------- INIT data
  DATA = {
          ES_key = 'SamplingTool',
          UI_name = ' Sampling tool', 
          upd = true, 
          info = '',
          perform_quere = {},
          }

  -------------------------------------------------------------------------------- INIT UI locals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  --local ctx
  -------------------------------------------------------------------------------- UI init variables
    UI = {
            -- font
              font='Arial',
              font1sz=15,
            -- mouse
              hoverdelay = 0.8,
              hoverdelayshort = 0.8,
            -- size / offset
              spacingX = 4,
              spacingY = 3,
            -- colors / alpha
              main_col = 0x7F7F7F, -- grey
              textcol = 0xFFFFFF,
              textcol_a_enabled = 1,
              textcol_a_disabled = 0.5,
              but_hovered = 0x878787,
              windowBg = 0x303030,
          } 
  
  
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  -------------------------------------------------------------------------------- 
  function ImGui.PushStyle(key, value, value2)  
    if not (ctx and key and value) then return end
    local iscol = key:match('Col_')~=nil
    local keyid = ImGui[key]
    if not iscol then 
      ImGui.PushStyleVar(ctx, keyid, value, value2)
      if not UI.pushcnt_var then UI.pushcnt_var = 0 end
      UI.pushcnt_var = UI.pushcnt_var + 1
    else 
      if not value2 then
        ReaScriptError( key ) 
       else
        ImGui.PushStyleColor(ctx, keyid, math.floor(value2*255)|(value<<8) )
        if not UI.pushcnt_col then UI.pushcnt_col = 0 end
        UI.pushcnt_col = UI.pushcnt_col + 1
      end
    end 
  end
  --------------------------------------------------------------------------------  
  function UI.draw_setbuttonbackgtransparent() 
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, 0 )
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0 )
  end
  function UI.draw_unsetbuttonstyle() ImGui.PopStyleColor(ctx,3) end
  -------------------------------------------------------------------------------- 
  function ImGui.PopStyle_var()  
    if not (ctx) then return end
    ImGui.PopStyleVar(ctx, UI.pushcnt_var)
    UI.pushcnt_var = 0
  end
  -------------------------------------------------------------------------------- 
  function ImGui.PopStyle_col()  
    if not (ctx) then return end
    ImGui.PopStyleColor(ctx, UI.pushcnt_col)
    UI.pushcnt_col = 0
  end 
  -------------------------------------------------------------------------------- 
  function UI.MAIN_styledefinition(open)  
    
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
      window_flags = window_flags | ImGui.WindowFlags_TopMost
      window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
      --window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings()
      --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
      --open = false -- disable the close button
    
    
      -- rounding
        ImGui.PushStyle('StyleVar_FrameRounding',5)   
        ImGui.PushStyle('StyleVar_GrabRounding',3)  
        ImGui.PushStyle('StyleVar_WindowRounding',10)  
        ImGui.PushStyle('StyleVar_ChildRounding',5)  
        ImGui.PushStyle('StyleVar_PopupRounding',0)  
        ImGui.PushStyle('StyleVar_ScrollbarRounding',9)  
        ImGui.PushStyle('StyleVar_TabRounding',4)   
      -- Borders
        ImGui.PushStyle('StyleVar_WindowBorderSize',0)  
        ImGui.PushStyle('StyleVar_FrameBorderSize',0) 
      -- spacing
        ImGui.PushStyle('StyleVar_WindowPadding',UI.spacingX,UI.spacingY)  
        ImGui.PushStyle('StyleVar_FramePadding',10,UI.spacingY) 
        ImGui.PushStyle('StyleVar_CellPadding',UI.spacingX, UI.spacingY) 
        ImGui.PushStyle('StyleVar_ItemSpacing',UI.spacingX, UI.spacingY)
        ImGui.PushStyle('StyleVar_ItemInnerSpacing',4,0)
        ImGui.PushStyle('StyleVar_IndentSpacing',20)
        ImGui.PushStyle('StyleVar_ScrollbarSize',10)
      -- size
        ImGui.PushStyle('StyleVar_GrabMinSize',20)
        ImGui.PushStyle('StyleVar_WindowMinSize',w_min,h_min)
      -- align
        ImGui.PushStyle('StyleVar_WindowTitleAlign',0.5,0.5)
        ImGui.PushStyle('StyleVar_ButtonTextAlign',0.5,0.5)
      -- alpha
        ImGui.PushStyle('StyleVar_Alpha',0.98)
        ImGui.PushStyle('Col_Border',UI.main_col, 0.3)
      -- colors
        ImGui.PushStyle('Col_Button',UI.main_col, 0.2) --0.3
        ImGui.PushStyle('Col_ButtonActive',UI.main_col, 1) 
        ImGui.PushStyle('Col_ButtonHovered',UI.but_hovered, 0.8)
        ImGui.PushStyle('Col_DragDropTarget',0xFF1F5F, 0.6)
        ImGui.PushStyle('Col_FrameBg',0x1F1F1F, 0.7)
        ImGui.PushStyle('Col_FrameBgActive',UI.main_col, .6)
        ImGui.PushStyle('Col_FrameBgHovered',UI.main_col, 0.7)
        ImGui.PushStyle('Col_Header',UI.main_col, 0.5) 
        ImGui.PushStyle('Col_HeaderActive',UI.main_col, 1) 
        ImGui.PushStyle('Col_HeaderHovered',UI.main_col, 0.98) 
        ImGui.PushStyle('Col_PopupBg',0x303030, 0.9) 
        ImGui.PushStyle('Col_ResizeGrip',UI.main_col, 1) 
        ImGui.PushStyle('Col_ResizeGripHovered',UI.main_col, 1) 
        ImGui.PushStyle('Col_SliderGrab',UI.butBg_green, 0.4) 
        ImGui.PushStyle('Col_Tab',UI.main_col, 0.37) 
        ImGui.PushStyle('Col_TabHovered',UI.main_col, 0.8) 
        ImGui.PushStyle('Col_Text',UI.textcol, UI.textcol_a_enabled) 
        ImGui.PushStyle('Col_TitleBg',UI.main_col, 0.7) 
        ImGui.PushStyle('Col_TitleBgActive',UI.main_col, 0.95) 
        ImGui.PushStyle('Col_WindowBg',UI.windowBg, 1)
      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
      ImGui.SetNextWindowSize(ctx, 410, h, ImGui.Cond_Appearing)
      
      
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
        UI.calc_itemW = (DATA.display_w-UI.spacingX*3) / 2
        
      -- draw stuff
        UI.draw()
        ImGui.Dummy(ctx,0,0) 
        ImGui.PopStyle_var() 
        ImGui.PopStyle_col() 
        ImGui.End(ctx)
       else
        ImGui.PopStyle_var() 
        ImGui.PopStyle_col() 
      end 
      ImGui.PopFont( ctx ) 
      if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
    
      return open
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_Always()
    --[[
    if not DATA.perform_quere_sheduledTS then DATA.perform_quere_sheduledTS = 0 end
    if not DATA.perform_quere_sheduled or (DATA.perform_quere_sheduled and #DATA.perform_quere_sheduled==0) then return end
    local f= DATA.perform_quere_sheduled[1]
    if f and os.clock()-DATA.perform_quere_sheduledTS > EXT.CONF_schedmode_s then
      f()
      table.remove(DATA.perform_quere_sheduled,1)
      DATA.perform_quere_sheduledTS = os.clock()
    end
    ]]
    DATA:perform()
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_UIloop() 
    DATA.clock = os.clock() 
    DATA:handleProjUpdates()
    DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1))
    DATA:CollectData_Always()
    --if DATA.upd == true then  DATA:CollectData()  end 
    DATA.upd = false
    
    -- draw UI
    UI.open = UI.MAIN_styledefinition(true) 
    
    -- handle xy
    DATA:handleViewportXYWH()
    -- data
    if UI.open then defer(UI.MAIN_UIloop) end
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN_definecontext()
    
    EXT:load() 
    
    -- imgUI init
    ctx = ImGui.CreateContext(DATA.UI_name) 
    -- fonts
    DATA.font1 = ImGui.CreateFont(UI.font, UI.font1sz) ImGui.Attach(ctx, DATA.font1)
    --DATA.font2 = ImGui.CreateFont(UI.font, UI.font2sz) ImGui.Attach(ctx, DATA.font2)
    --DATA.font3 = ImGui.CreateFont(UI.font, UI.font3sz) ImGui.Attach(ctx, DATA.font3)  
    -- config
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
    ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort)
    
    
    -- run loop
    defer(UI.MAIN_UIloop)
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
  ----------------------------------------------------------------------------------------- 
  function main() 
    DATA.SR = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
    UI.MAIN_definecontext() 
  end  
  ----------------------------------------------------------------------
  function DATA:Process_PerformSampling()
    local item = GetSelectedMediaItem(0,0)
    if not item then DATA.info = 'Item is not selected' return end
    
    local take = GetActiveTake(item)
    local source =  GetMediaItemTake_Source( take )
    local srclen = GetMediaSourceLength( source )
    local filename = GetMediaSourceFileName( source )
    
    local par_track = GetMediaItemTrack( item )
    local instr = TrackFX_GetInstrument( par_track )
    local retval, fxname = reaper.TrackFX_GetFXName( par_track, instr )
    local ID = reaper.GetMediaTrackInfo_Value( par_track, 'IP_TRACKNUMBER' )
    -- add sampling track
      reaper.InsertTrackAtIndex( ID, false )
      local tr =  reaper.GetTrack( 0, ID )
      GetSetMediaTrackInfo_String( tr, 'P_NAME' , 'Sampler track', 1 )
      if not tr then return end
      
   -- add rs5k
    local notecnt_start = EXT.CONF_notestart
    local notecnt_end = EXT.CONF_noteend
    local notecnt = notecnt_end-notecnt_start + 1
    
    --if EXT.CONF_schedmode==1 then DATA.perform_quere_sheduled = {} end
    for pitch = notecnt_start, notecnt_end do
    
      local function add_rs5k()
        local sitem = GetSelectedMediaItem(0,pitch-notecnt_start) 
        if not sitem then return end
        local it_len = GetMediaItemInfo_Value( sitem, 'D_LENGTH' )
        local s_take = GetActiveTake(sitem)
        local s_offs =  GetMediaItemTakeInfo_Value( s_take, 'D_STARTOFFS' )
        offset_s = s_offs/srclen
        offset_e = (s_offs+it_len)/srclen
        
        local fx = reaper.TrackFX_AddByName( tr, 'ReaSamplOmatic5000 (Cockos)', false, -1 )
        TrackFX_SetNamedConfigParm( tr, fx, 'FILE0', filename )
        TrackFX_SetParamNormalized( tr, fx, 21, 1 )-- filter played notes
        local rs5k_note_norm = pitch/127+0.001
        local rs5k_offset = (pitch-notecnt_start)/notecnt
        
        TrackFX_SetParamNormalized( tr, fx, 3, rs5k_note_norm )-- start range
        TrackFX_SetParamNormalized( tr, fx, 4, rs5k_note_norm )-- end range
        
        TrackFX_SetParamNormalized( tr, fx, 13, offset_s )-- offset start
        TrackFX_SetParamNormalized( tr, fx, 14, offset_e)-- offset end
        
        if EXT.CONF_setobeynoteoff==1 then TrackFX_SetParamNormalized( tr, fx, 11, 1) end-- offset end
        
        if EXT.CONF_showflag ~= -1 then TrackFX_Show( tr, fx, EXT.CONF_showflag )  else
          TrackFX_Show( tr, fx, 1 )
          TrackFX_Show( tr, fx, 2 )
        end
        
        if EXT.CONF_rename == 1 then
          local new_name = EXT.CONF_rename_wildcard
          new_name = new_name:gsub('#note', pitch)
          new_name = new_name:gsub('#fxname', fxname)
          TrackFX_SetNamedConfigParm(tr, fx, 'renamed_name', new_name )
        end 
        
        if EXT.CONF_extend_bounds == 1 then
          if pitch == notecnt_start then
            TrackFX_SetParamNormalized( tr, fx, 3, 0 )-- start range
            TrackFX_SetParamNormalized( tr, fx, 5, (-pitch +80) / 160 )-- start note
            TrackFX_SetNamedConfigParm(tr, fx, "MODE", 2)
          end 
          if pitch == notecnt_end then
            TrackFX_SetParamNormalized( tr, fx, 4, 1 )-- end range
            TrackFX_SetParamNormalized( tr, fx, 5,0.5 )-- end note
            TrackFX_SetNamedConfigParm(tr, fx, "MODE", 2)
          end 
        end 
      end -- function end
      
      --if EXT.CONF_schedmode==1 then table.insert(DATA.perform_quere_sheduled,add_rs5k) else add_rs5k() end
      add_rs5k()
    end
    
    if EXT.CONF_renameMEnotes == 1 then 
      for pitch = 0, 127 do SetTrackMIDINoteNameEx( 0, tr, pitch, -1, '' ) end
    end
    if EXT.CONF_addtestmidiitem==1 then DATA:Process_GenerateMIDI(tr, false) end
    
  end
  ------------------------------------------------------------------------------------------------------
  function Action(s, sectionID, ME )  
    if sectionID == 32060 and ME then 
      MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
     else
      Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
    end
  end  
  ---------------------------------------------------------------------  
  function DATA:Process_Split() 
    local item = GetSelectedMediaItem(0,0)
    if not item then DATA.info = 'Item is not selected' return end
    
    local notecnt_start = EXT.CONF_notestart
    local notecnt_end = EXT.CONF_noteend
    local notecnt = notecnt_end-notecnt_start
    local noteoff_compensation = 0.01 -- seconds cut
    local len = EXT.CONF_notelen_beats
    local tail = EXT.CONF_notetail_beats
    
    local right_item = item
    for pitch = notecnt_start+1, notecnt_end do
      local init_pos_beats = (len+tail)*(pitch-notecnt_start)
      local pos_sec = TimeMap2_beatsToTime( 0, init_pos_beats, 0 )
      right_item = SplitMediaItem( right_item, pos_sec )
    end
    UpdateArrange()
  end
  -----------------------------------------------------------------------------------------
  function DATA:ExecuteSampling()
    local tr = GetSelectedTrack( 0, 0 )
    if not tr then DATA.info = 'Track with instrument is not selected' return end
    local instr = TrackFX_GetInstrument( tr )
    if instr == -1 then DATA.info = 'Instrument is not found on selected track' return end
    
    Undo_BeginBlock()
    -- gen midi item
      DATA:Process_GenerateMIDI()
    -- apply fx
      Action(40209)--Item: Apply track/take FX to items 
    -- split by note
      DATA:Process_Split()
    -- add to rs5k
      DATA:Process_PerformSampling()
      
    Undo_EndBlock( DATA.UI_name..' - generate MIDI', 4 )
  end
  ----------------------------------------------------------------------
  function DATA:Process_GenerateMIDI(tr, selected) 
    -- preset
      local notecnt_start = EXT.CONF_notestart
      local notecnt_end = EXT.CONF_noteend
      local notecnt = notecnt_end-notecnt_start
      local noteoff_compensation = 0.01 -- seconds cut 
      local len = EXT.CONF_notelen_beats
      local tail = EXT.CONF_notetail_beats
    
    -- form edges
      local item_pos_beats = EXT.CONF_itempos_beats
      local item_len_beats = (len+tail)*(notecnt+1)
      local item_pos_sec = TimeMap2_beatsToTime( 0, item_pos_beats, 0 )
      local item_len_sec = TimeMap2_beatsToTime( 0, item_len_beats, 0 )
      
    -- init
      local track =tr or GetSelectedTrack(0,0)
      if not track then return end
      local it = reaper.CreateNewMIDIItemInProj( track, item_pos_sec, item_pos_sec+item_len_sec, false )
      if not it then return end
      local take = GetActiveTake(it)    
    
    -- add notes
      for pitch = notecnt_start, notecnt_end do
        local chan = 0
        local vel = 120
        local init_pos_beats = (len+tail)*(pitch-notecnt_start)
        local pos_sec = TimeMap2_beatsToTime( 0, init_pos_beats, 0 )
        local pos2_sec = TimeMap2_beatsToTime( 0, init_pos_beats+len, 0 )
        local startppqpos =   MIDI_GetPPQPosFromProjTime( take, pos_sec )
        local endppqpos = MIDI_GetPPQPosFromProjTime( take, pos2_sec-noteoff_compensation )
        reaper.MIDI_InsertNote( take, false, false, startppqpos, endppqpos, chan, pitch, vel, true )
      end
      reaper.MIDI_Sort( take ) 
      
    Action(40289)--  Item: Unselect (clear selection of) all items
    SetMediaItemSelected( it, selected or true )
  end
  -----------------------------------------------------------------------------  
  function DATA:perform()
    if not DATA.perform_quere then return end
    for i = 1, #DATA.perform_quere do if DATA.perform_quere[i] then DATA.perform_quere[i]() end end
    DATA.perform_quere = {} --- clear
  end
  --------------------------------------------------------------------------------  
  function UI.draw()
  local sliderw = 180
    -- MIDI item generator
      ImGui.SeparatorText(ctx,'MIDI item generator') 
      ImGui.SetNextItemWidth(ctx,sliderw) local retval, v = ImGui.SliderInt( ctx, 'Note length, beats', EXT.CONF_notelen_beats, 1, 64, '%d', ImGui.SliderFlags_None ) if retval then EXT.CONF_notelen_beats = v EXT:save() end
      ImGui.SetNextItemWidth(ctx,sliderw) local retval, v = ImGui.SliderInt( ctx, 'Note tail, beats', EXT.CONF_notetail_beats, 1, 64, '%d', ImGui.SliderFlags_None ) if retval then EXT.CONF_notetail_beats = v EXT:save() end
      ImGui.SetNextItemWidth(ctx,sliderw) local retval, v = ImGui.SliderInt( ctx, 'Note start', EXT.CONF_notestart, 0, EXT.CONF_noteend, '%d', ImGui.SliderFlags_None ) if retval then EXT.CONF_notestart = v EXT:save() end
      ImGui.SetNextItemWidth(ctx,sliderw) local retval, v = ImGui.SliderInt( ctx, 'Note start', EXT.CONF_noteend, EXT.CONF_notestart, 127, '%d', ImGui.SliderFlags_None ) if retval then EXT.CONF_noteend = v EXT:save() end
    
    -- Adding RS5k instances
      ImGui.SeparatorText(ctx,'Adding RS5k instances')      
      if ImGui.Checkbox( ctx, 'Clear MIDI editor note names', EXT.CONF_renameMEnotes==1 ) then EXT.CONF_renameMEnotes = EXT.CONF_renameMEnotes~1 EXT:save() end
      if ImGui.Checkbox( ctx, 'Add test MIDI item', EXT.CONF_addtestmidiitem==1 ) then EXT.CONF_addtestmidiitem = EXT.CONF_addtestmidiitem~1 EXT:save() end
      if ImGui.Checkbox( ctx, 'Extend note bounds', EXT.CONF_extend_bounds==1 ) then EXT.CONF_extend_bounds = EXT.CONF_extend_bounds~1 EXT:save() end
      if ImGui.Checkbox( ctx, 'Set obey note-off', EXT.CONF_setobeynoteoff==1 ) then EXT.CONF_setobeynoteoff = EXT.CONF_setobeynoteoff~1 EXT:save() end 
      --[[if ImGui.Checkbox( ctx, 'Schedule mode', EXT.CONF_schedmode==1 ) then EXT.CONF_schedmode = EXT.CONF_schedmode~1 EXT:save() end
      if EXT.CONF_schedmode == 1 then
        ImGui.SetNextItemWidth(ctx,sliderw)
        local retval, v = reaper.ImGui_SliderDouble( ctx, 'Pause between adding new instances', EXT.CONF_schedmode_s, 0.5, 3, '%.1f', ImGui.SliderFlags_None )
        if retval then EXT.CONF_schedmode_s = v EXT:save() end
      end]]
      ImGui.SetNextItemWidth(ctx,sliderw)local retval, current_item = ImGui.Combo( ctx, 'Show FX', EXT.CONF_showflag+1, 'Show chain, hide floating\0Show FX chain\0Hide floating window\0Show floating window\0', 50 )
      if retval then EXT.CONF_showflag = current_item-1 EXT:save() end
      ImGui.SetNextItemWidth(ctx,340)local retval, buf = ImGui.InputText( ctx, 'Wildcards', EXT.CONF_rename_wildcard, ImGui.InputTextFlags_EnterReturnsTrue )
      if retval then EXT.CONF_rename_wildcard = buf  EXT:save() end
      if ImGui.Selectable( ctx, 'Clear', false, reaper.ImGui_SelectableFlags_None(), 40, 0 ) then EXT.CONF_rename_wildcard = '#fxname sampled - #note ' EXT:save() end 
      ImGui.SameLine(ctx) if ImGui.Selectable( ctx, '#note', false, reaper.ImGui_SelectableFlags_None(), 40, 0 ) then EXT.CONF_rename_wildcard = EXT.CONF_rename_wildcard..' #note' EXT:save() end 
      ImGui.SameLine(ctx) if ImGui.Selectable( ctx, '#fxname', false, reaper.ImGui_SelectableFlags_None(),50, 0 ) then EXT.CONF_rename_wildcard = EXT.CONF_rename_wildcard..' #fxname' EXT:save() end 
      
    -- Perform
      ImGui.SeparatorText(ctx,'Perform')  
      if ImGui.Button(ctx, 'Start sampling',UI.calc_itemW) then DATA:ExecuteSampling() end ImGui.SameLine(ctx) 
      if ImGui.Button(ctx, 'Stop sampling',UI.calc_itemW) then DATA.perform_quere_sheduled = nil end
      ImGui.TextColored( ctx, 0xFF0F0FFF, DATA.info )
  end
  -----------------------------------------------------------------------------------------
  main()