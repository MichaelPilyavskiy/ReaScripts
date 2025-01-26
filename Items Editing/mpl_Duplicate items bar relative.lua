-- @description Duplicate items bar relative
-- @version 2.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # overall cleanup
--    # remove SWS dependency
--    # handle bar correctly
--    # handle time signatures and tempo variations

    ----------------------------------------------------------------------
  function main() 
    local it = reaper.GetSelectedMediaItem(0, 0)
    if not it then return end
    local it_last = reaper.GetSelectedMediaItem(0, reaper.CountSelectedMediaItems(0)-1) 
    
    local bound_st = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
    local bound_end = reaper.GetMediaItemInfo_Value(it_last, "D_POSITION") +reaper.GetMediaItemInfo_Value(it_last, "D_LENGTH")
    
    local retval, measures, cml, fullbeats_st, cdenom = reaper.TimeMap2_timeToBeats( 0, bound_st )
    local retval, measures, cml, fullbeats_end, cdenom = reaper.TimeMap2_timeToBeats( 0, bound_end ) 
    
    local tsmarker = reaper.FindTempoTimeSigMarker( 0, bound_st )
    local retval1, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker( 0, tsmarker )
    if retval1 == false then
      local test_time = reaper.TimeMap2_beatsToTime( 0, 0, 1 )
       _, _, _, _, timesig_denom = reaper.TimeMap2_timeToBeats( 0, test_time )
    end
    local barshift = math.max(math.ceil((fullbeats_end-fullbeats_st) / timesig_denom),1)
    
    reaper.ApplyNudge( 0,--project, 
                0,--nudgeflag, 
                5,--nudgewhat, 
                16,--nudgeunits, 
                barshift,--value, 
                false,--reverse, 
                0)--copies )
  end
      
  reaper.Undo_BeginBlock2( 0 )
    main() 
  reaper.Undo_EndBlock2( 0, "Duplicate items bar relative", 0xFFFFFFFF )