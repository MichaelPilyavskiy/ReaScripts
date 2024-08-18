-- @description Show all armed track envelopes, hide unarmed
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # update for use with REAPER 7.19
--    # SWS extension not required

function main()
  for tr = 1, reaper.CountTracks(0) do
    local track = reaper.GetTrack(0,tr-1)
    if track then 
      for i = 1,  reaper.CountTrackEnvelopes( track ) do
        local env = reaper.GetTrackEnvelope( track, i-1 ) 
        local retval, ARMED = reaper.GetSetEnvelopeInfo_String( env, 'ARM', -1, 0 )
        reaper.GetSetEnvelopeInfo_String( env, 'VISIBLE', ARMED, 1 )
      end
    end
  end
  reaper.TrackList_AdjustWindows( false )
end
    


primaryvrs = reaper.GetAppVersion():match('[%d%.]+')
if primaryvrs and tonumber(primaryvrs) and tonumber(primaryvrs) >=7.19 then
  local script_title = "Show all active track envelopes, hide unactive"
  reaper.Undo_BeginBlock() 
  main()
  reaper.Undo_EndBlock(script_title, 0xFFFFFFFF)
 else
  reaper.MB('This script requires REAPER 7.19+','Error',0)
end
