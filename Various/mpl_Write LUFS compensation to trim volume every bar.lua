-- @description Write LUFS compensation to trim volume every bar (background)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about 
--	At init - set trim volumes to active, unarmed, set meter mode to lufs. Run - write points at bars. At stop - set meter mode to stereo peaks
-- @changelog
--    + Init


 
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  -- config defaults
  DATA2 = {state = false,
          trigger_mintime= 0.5}
  ---------------------------------------------------------------------  
  function main()  
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = '1.0'
    DATA.extstate.extstatesection = 'mpllufscomp'
    DATA.extstate.mb_title = 'Write LUFS compensation'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  350,
                          wind_h =  50,
                          dock =    0,
                          
                          CONF_NAME = 'default',
                          
                          -- UI
                          UI_appatchange = 0, 
                          UI_enableshortcuts = 0,
                          UI_initatmouse = 0,
                          UI_showtooltips = 1,
                          UI_groupflags = 0, 
                          
                          }
    
    DATA:ExtStateGet()
    DATA:ExtStateGetPresets()  
    if DATA.extstate.UI_initatmouse&1==1 then
      local w = DATA.extstate.wind_w
      local h = DATA.extstate.wind_h 
      local x, y = GetMousePosition()
      DATA.extstate.wind_x = x-w/2
      DATA.extstate.wind_y = y-h/2
    end
    DATA:GUIinit()
    
    RUN()
  end
  ----------------------------------------------------------------------
  function DATA2:PerformStuff(mode)
    for i = 1, CountSelectedTracks(0)do
      local tr = GetSelectedTrack(0,i-1)
      if mode == 1 then DATA2:PerformStuff_atclose(tr)
       elseif mode == 0 then DATA2:PerformStuff_atrun(tr)
       elseif mode == 2 then DATA2:PerformStuff_atstart(tr)
      end
    end
  end
  ----------------------------------------------------------------------
  function DATA2:PerformStuff_atstart(tr)
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
  ----------------------------------------------------------------------
  function DATA2:PerformStuff_atrun(tr)
    
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
    
    local beats, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( 0, DATA2.playpos )
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
  function DATA2:PerformStuff_atclose(tr)
    SetMediaTrackInfo_Value( tr, 'I_VUMODE', 0 )
  end
  ----------------------------------------------------------------------
  function DATA_RESERVED_DYNUPDATE()
    -- stop if not active / playing
      if not DATA2.state then return end
      if GetPlayStateEx( 0 )&1~= 1 then return end
      
    -- handle at beats
      DATA2.playpos = GetPlayPosition2Ex( 0 )
      local beats, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( 0, DATA2.playpos )
      if beats > 0.2 then return end
      
    -- handle minimum time between triggers
      DATA2.trigger = os.clock()
      if DATA2.lasttrigger and DATA2.trigger - DATA2.lasttrigger < DATA2.trigger_mintime then return end
      DATA2.lasttrigger = DATA2.trigger
      
    -- perform stuff
      DATA2:PerformStuff(0)
      
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_init(DATA)
    DATA.GUI.buttons = {}
    local inittxt = '[stopped]'
    if DATA2.state == true then inittxt = '[recording]' end
    DATA.GUI.buttons.scroll = { x=0,
                          y=0,
                          w=gfx.w/DATA.GUI.default_scale-1,
                          h=gfx.h/DATA.GUI.default_scale-1,
                          txt = inittxt,
                          onmouserelease = function() 
                            DATA2.state = not DATA2.state 
                            if DATA2.state == true then 
                              DATA.GUI.buttons.scroll.txt = '[recording]'
                              reaper.Undo_BeginBlock2(0 )
                              DATA2:PerformStuff(2)
                              Undo_EndBlock2( 0, 'LUFS compensation', 0xFFFFFFFF )
                             else
                              DATA.GUI.buttons.scroll.txt = '[stopped]'
                              DATA2:PerformStuff(1)
                            end
                          end
                          }         
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end
  end 
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.42) if ret then local ret2 = VF_CheckReaperVrs(6.68,true) if ret2 then main() end end

