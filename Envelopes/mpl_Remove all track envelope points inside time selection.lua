-- @description Remove all track envelope points inside time selection
-- @version 1.0
-- @author MPL 
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--  + init

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  -----------------------------------------------------------------
  function ClearEnvelope(track,tsstart,tsend)
    local cnt = reaper.CountTrackEnvelopes( track )
    for envidx = 1, cnt do
      local envelope =  reaper.GetTrackEnvelope( track, envidx-1 )
      reaper.DeleteEnvelopePointRange( envelope, tsstart,tsend)
    end
  end
  -----------------------------------------------------------------
  function main()
     tsstart, tsend = GetSet_LoopTimeRange2( 0, 0, 0, -1, -1, false )
    if tsend - tsstart < 0.1 then return end
    for i = 1, CountTracks() do
      local tr = GetTrack(0,i-1)
      if tr then ClearEnvelope(tr,tsstart,tsend) end
    end
  end  

  Undo_BeginBlock2( 0 )
  main() 
  UpdateArrange()
  Undo_EndBlock2( 0, 'Remove all track envelope points inside time selection', -1 )