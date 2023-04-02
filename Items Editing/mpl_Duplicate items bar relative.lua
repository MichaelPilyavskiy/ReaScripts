-- @description Duplicate items bar relative
-- @version 2.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # overall cleanup
--    # remove SWS dependency
--    # handle bar correctly
--    # handle time signatures and tempo variations

    ----------------------------------------------------------------------
  function main() 
    local it = GetSelectedMediaItem(0, 0)
    if not it then return end
    local it_last = GetSelectedMediaItem(0, CountSelectedMediaItems(0)-1) 
    
    local bound_st = GetMediaItemInfo_Value(it, "D_POSITION")
    local bound_end = GetMediaItemInfo_Value(it_last, "D_POSITION") +GetMediaItemInfo_Value(it_last, "D_LENGTH")
    
    local retval, measures, cml, fullbeats_st, cdenom = TimeMap2_timeToBeats( 0, bound_st )
    local retval, measures, cml, fullbeats_end, cdenom = TimeMap2_timeToBeats( 0, bound_end ) 
    
    local tsmarker = FindTempoTimeSigMarker( 0, bound_st )
    local retval1, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = GetTempoTimeSigMarker( 0, tsmarker )
    if retval1 == false then
      local test_time = TimeMap2_beatsToTime( 0, 0, 1 )
       _, _, _, _, timesig_denom = TimeMap2_timeToBeats( 0, test_time )
    end
    local barshift = math.max(math.ceil((fullbeats_end-fullbeats_st) / timesig_denom),1)
    
    ApplyNudge( 0,--project, 
                0,--nudgeflag, 
                5,--nudgewhat, 
                16,--nudgeunits, 
                barshift,--value, 
                false,--reverse, 
                0)--copies )
  end
      
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, "Duplicate items bar relative", 0xFFFFFFFF )
  end end