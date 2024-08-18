-- @description Hide all track envelopes except envelope under mouse cursor
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # update for use with REAPER 7.19
--    # SWS extension not required


function main()
  reaper.Main_OnCommandEx(0,41150)
  local track, info = reaper.GetThingFromPoint(reaper.GetMousePosition())
  if not (track and reaper.ValidatePtr2(0,track, 'MediaTrack*')) then return end
  local envidx = info:match('(%d+)') 
  if not (envidx and tonumber(envidx)) then return end
  
  local env0 = reaper.GetTrackEnvelope( track, tonumber(envidx) )
  if not env0 then return end
  
  for tr = 1, reaper.CountTracks(0) do
    local track = reaper.GetTrack(0,tr-1)
    if track then 
      for i = 1,  reaper.CountTrackEnvelopes( track ) do
        local env = reaper.GetTrackEnvelope( track, i-1 ) 
        if env == env0 then visible = '1' else visible = '0' end 
        reaper.GetSetEnvelopeInfo_String( env, 'VISIBLE', visible, 1 )
      end
    end
  end  
  
  reaper.TrackList_AdjustWindows( false )
  
  
  
end

primaryvrs = reaper.GetAppVersion():match('[%d%.]+')
if primaryvrs and tonumber(primaryvrs) and tonumber(primaryvrs) >=7.19 then
  local script_title = "Hide all track envelopes except envelope under mouse cursor"
  reaper.Undo_BeginBlock() 
  main()
  reaper.Undo_EndBlock(script_title, 0xFFFFFFFF)
 else
  reaper.MB('This script requires REAPER 7.19+','Error',0)
end