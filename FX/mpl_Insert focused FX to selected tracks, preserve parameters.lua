-- @description Insert focused FX to selected tracks, preserve parameters
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
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
  --------------------------------------------------------------------  
  function main()
    local ret, tracknumber, _, src_fx = GetFocusedFX()
    if ret == 0 then return end
    local src_track = CSurf_TrackFromID(tracknumber, false)
    if tracknumber ==0 then src_track =  GetMasterTrack( 0 ) end
    
    for sel_tr = 1,  CountSelectedTracks( 0 ) do
      local dest_track = GetSelectedTrack( 0, sel_tr-1 )
      if dest_track ~= track then 
        TrackFX_CopyToTrack( src_track, src_fx, dest_track, TrackFX_GetCount( dest_track ), false )    
      end
    end  
  end  
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.95,true) then main() end