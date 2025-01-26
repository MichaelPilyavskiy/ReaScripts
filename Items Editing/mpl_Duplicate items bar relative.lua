-- @description Duplicate items bar relative
-- @version 2.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  
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
      
  --------------------------------------------------------------------  
 if VF_CheckReaperVrs(6.78,true) then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, "Duplicate items bar relative", 0xFFFFFFFF )
  end