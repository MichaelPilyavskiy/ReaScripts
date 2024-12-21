-- @description Write LUFS compensation to trim volume every bar (background)
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # ReaImGui based UI
--    # VF independent

--------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end
  app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
  if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end
  local ImGui
  
  if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
  package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  ImGui = require 'imgui' '0.9.2'
  
  
  
  DATA = {  state = false,
            ES_key = 'mpllufscomp',
            UI_name = 'Write LUFS compensation',
            trigger_mintime = 0.5,
          }
  EXT = {
            viewport_posX = 100,
            viewport_posY = 100,
            viewport_posW_fixed = 200,
            viewport_posH_fixed = 100, 
          
        }
          
  UI =  {
  -- font  
            font='Arial',
            font1sz=15,
            
        }
          
          

          
  ----------------------------------------------------------------------
  function DATA.PerformStuff_atstart(tr)
    if not tr then return end
    local vu = GetMediaTrackInfo_Value( tr, 'I_VUMODE' )
    if vu ~= 16 then SetMediaTrackInfo_Value( tr, 'I_VUMODE', 16 ) end
    
    -- initialize Trim Volume / set unarmed
    local env = GetTrackEnvelopeByName( tr, 'Trim Volume' )
    if not env then 
      -- init trim envelope
      local init_chunk = [[
      <VOLENV3
      EGUID ]]..genGuid()..'\n'..[[
      ACT 0 -1
      VIS 1 1 1
      LANEHEIGHT 0 0
      ARM 1
      DEFSHAPE 0 -1 -1
      VOLTYPE 1
      PT 0 1 0
      >
      ]]  
      local retval, trchunk = GetTrackStateChunk( tr, '', false )
      local outchunk = trchunk:gsub('<TRACK','<TRACK\n'..init_chunk)
      SetTrackStateChunk( tr, outchunk, false )
      TrackList_AdjustWindows( false )
     else
      -- unarm trim envelope
      local retval, envchunk = GetEnvelopeStateChunk( env, '', true )
      local arm = envchunk:match('ACT (%d)')
      if arm and tonumber(arm) and tonumber(arm) ~= 0 then
        local retval, envchunk = GetEnvelopeStateChunk( env, '', false )
        SetEnvelopeStateChunk( env, envchunk:gsub('ACT (%d)','ACT 0'),false )
      end
    end
    
  end
  function DATA:handleProjUpdates()
    local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
    local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
    local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
  end
  -------------------------------------------------------------------------------- 
  function UI.MAIN()
    
    EXT:load() 
    EXT.presetview = 0
    
    -- imgUI init
    ctx = ImGui.CreateContext(DATA.UI_name) 
    -- fonts
    DATA.font1 = ImGui.CreateFont(UI.font, UI.font1sz) ImGui.Attach(ctx, DATA.font1)
    -- config
    --ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
    --ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort)
    
    
    -- run loop
    defer(UI.MAINloop)
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
  function UI.MAIN_draw(open) 
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
      --if UI.disable_save_window_pos == true then window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings() end
      --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
      --open = false -- disable the close button
    
    

      
    -- We specify a default position/size in case there's no data in the .ini file.
      local main_viewport = ImGui.GetMainViewport(ctx)
      local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
      ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
      ImGui.SetNextWindowSize(ctx, EXT.viewport_posW_fixed,EXT.viewport_posH_fixed, ImGui.Cond_Always)
      --ImGui.SetNextWindowSize(ctx, w_min, h_min, ImGui.Cond_Always)
      
      
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
        UI.calc_itemH_small = math.floor(UI.calc_itemH*0.8)
        
      -- draw stuff
        UI.draw()
        ImGui.Dummy(ctx,0,0) 
        ImGui.End(ctx)
      end 
      ImGui.PopFont( ctx ) 
      if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
    
      return open
  end
  
  --------------------------------------------------------------------------------  
  function UI.draw()  
    local inittxt = '[stopped]'
    if DATA.state == true then inittxt = '[recording]' end
    if ImGui.Button(ctx, inittxt,DATA.display_w_region-UI.calc_xoffset*2,DATA.display_h_region-UI.calc_yoffset*2-UI.calc_itemH) then   
      DATA.state = not DATA.state 
      if DATA.state == true then 
        reaper.Undo_BeginBlock2(0 )
        DATA.PerformStuff(2)
        Undo_EndBlock2( 0, 'LUFS compensation', 0xFFFFFFFF )
       else
        DATA.PerformStuff(1)
      end 
    end 
  end
  ----------------------------------------------------------------------------------------- 
  function main() 
    UI.MAIN() 
  end  
  ----------------------------------------------------------------------
  function DATA.DYNUPDATE()
    -- stop if not active / playing
      if not DATA.state then return end
      if GetPlayStateEx( 0 )&1~= 1 then return end
      
    -- handle at beats
      DATA.playpos = GetPlayPosition2Ex( 0 )
      local beats, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( 0, DATA.playpos )
      if beats > 0.2 then return end
      
    -- handle minimum time between triggers
      DATA.trigger = os.clock()
      if DATA.lasttrigger and DATA.trigger - DATA.lasttrigger < DATA.trigger_mintime then return end
      DATA.lasttrigger = DATA.trigger
      
    -- perform stuff
      DATA.PerformStuff(0)
      
  end
    -------------------------------------------------------------------------------- 
  function DATA.PerformStuff(mode)
  
    for i = 1, CountSelectedTracks(0)do
      local tr = GetSelectedTrack(0,i-1)
      if tr and reaper.ValidatePtr2(0,tr,'MediaTrack*') then 
        if mode == 1 then DATA.PerformStuff_atclose(tr)
         elseif mode == 0 then DATA.PerformStuff_atrun(tr)
         elseif mode == 2 then DATA.PerformStuff_atstart(tr)
        end
      end
    end
  end
    ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
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
  ----
  ----------------------------------------------------------------------
  function DATA.PerformStuff_atrun(tr)
  
  
  
    local env = GetTrackEnvelopeByName( tr, 'Trim Volume' )
    if not env then return end
    local scaling_mode = GetEnvelopeScalingMode( env )
    
    
    local lufs_dest = -18
    local time_diff_allowed = 0.1 -- points approximation
    local lufsout_max = 2 -- 2==6dB
    
    local lufs = Track_GetPeakInfo( tr, 1024 )
    local lufsdB = WDL_VAL2DB(lufs)
    local vol = 1
    local vol_DB = WDL_VAL2DB(vol)
    local diff_DB = lufs_dest-lufsdB
    local out_db = vol_DB + diff_DB
    local lufsout =WDL_DB2VAL(out_db)
    lufsout = math.min(lufsout, lufsout_max)
    lufsout = ScaleToEnvelopeMode( scaling_mode, lufsout )
    
    local beats, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( 0, DATA.playpos )
    local outpos =  TimeMap2_beatsToTime( 0, math.floor(fullbeats))
    local closepointID = GetEnvelopePointByTime( env, outpos+time_diff_allowed )
    local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint( env, closepointID )
    if math.abs(outpos-time) > time_diff_allowed then 
      InsertEnvelopePointEx( env, -1, outpos, lufsout, 0, 0, 0, false )
     else
      SetEnvelopePointEx( env, -1, closepointID, outpos, lufsout, 0, 0, 0, true )
    end
    
  end  
  ----------------------------------------------------------------------
  function DATA.PerformStuff_atclose(tr) 
    SetMediaTrackInfo_Value( tr, 'I_VUMODE', 0 ) 
  end
  -------------------------------------------------------------------------------- 
  function UI.MAINloop() 
    DATA.clock = os.clock() 
    DATA:handleProjUpdates()
    DATA.flicker = math.abs(-1+(math.cos(math.pi*(DATA.clock%2)) + 1))
    
    DATA.DYNUPDATE()
    --if DATA.upd == true then  DATA:CollectData()  end 
    DATA.upd = false
    
    -- draw UI
    UI.open = UI.MAIN_draw(true) 
    
    -- handle xy
    DATA:handleViewportXYWH()
    -- data
    if UI.open then defer(UI.MAINloop) end
  end
  
  -----------------------------------------------------------------------------------------
  main()

