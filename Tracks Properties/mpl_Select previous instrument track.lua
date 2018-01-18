-- @description Select previous instrument track
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   + init

  
  tr = reaper.GetSelectedTrack(0,0)
  if tr then 
    tr_ID =  reaper.CSurf_TrackToID( tr, false )
    for i = tr_ID-1,1,-1 do
      tr0 = reaper.GetTrack(0,i-1)
      if  reaper.TrackFX_GetInstrument( tr0 ) >= 0 then
        reaper.SetOnlyTrackSelected( tr0 )
        break
      end
    end
  end