-- @description Select active envelopes tracks
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # update for use with REAPER 7.19
--    # SWS extension not required

function main()
  -- unselect
    local tr = reaper.GetTrack(0,0)
    if not tr then return end 
    reaper.SetOnlyTrackSelected( tr )
    reaper.SetTrackSelected( tr, false )
  -- loop
    for tr = 1, reaper.CountTracks(0) do
      local track = reaper.GetTrack(0,tr-1)
      if track then 
        for i = 1,  reaper.CountTrackEnvelopes( track ) do
          local env = reaper.GetTrackEnvelope( track, i-1 ) 
          local retval, ACTIVE = reaper.GetSetEnvelopeInfo_String( env, 'ACTIVE', -1, 0 )      
          if ACTIVE == '1' then reaper.SetTrackSelected( track, true ) end
        end
      end
    end
end


primaryvrs = reaper.GetAppVersion():match('[%d%.]+')
if primaryvrs and tonumber(primaryvrs) and tonumber(primaryvrs) >=7.19 then
  local script_title = "Select active envelopes tracks"
  reaper.Undo_BeginBlock() 
  main()
  reaper.Undo_EndBlock(script_title, 0xFFFFFFFF)
 else
  reaper.MB('This script requires REAPER 7.19+','Error',0)
end