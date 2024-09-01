-- @description Invert selected tracks solo to mute states
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @changelog
--    # VF independent
--    # handle solo flag instead of boolean
--    # fix using selected tracks instead all tracks

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
  
  function main()
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      local mst = GetMediaTrackInfo_Value( tr, 'B_MUTE' )  
      local sst = GetMediaTrackInfo_Value( tr, 'I_SOLO' )  
      if mst == 1 and sst == 0 then 
        SetMediaTrackInfo_Value( tr, 'B_MUTE', 0 )
        SetMediaTrackInfo_Value( tr, 'I_SOLO', 1 )
       elseif mst == 0 and sst>0 then 
        SetMediaTrackInfo_Value( tr, 'B_MUTE', 1 )
        SetMediaTrackInfo_Value( tr, 'I_SOLO', 0 )        
      end
    end
    TrackList_AdjustWindows( false )
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true)  then main() end