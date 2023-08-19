-- @description SendFader - Mark selected tracks as receives
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @noindex

----------------------------------------------------------------------
  function MarkSelectedTracksAsSend() 
    for i = 1, reaper.CountSelectedTracks(0) do
      local tr = reaper.GetSelectedTrack(0,i-1) 
      if tr then reaper.GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_SENDMIX', 1, true )end
    end
  end
  
  MarkSelectedTracksAsSend() 
