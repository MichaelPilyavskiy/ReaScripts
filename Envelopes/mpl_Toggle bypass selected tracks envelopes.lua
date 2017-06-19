-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description Toggle bypass selected tracks envelopes
-- @website http://forum.cockos.com/member.php?u=70694

  function main(state) local tr
    for i = 1, reaper.CountSelectedTracks(0) do
      local tr = reaper.GetSelectedTrack(0,i-1)
      for env = 1,  reaper.CountTrackEnvelopes( tr ) do
        local tr_env = reaper.GetTrackEnvelope( tr, env-1 )
        local retval, env_chunk = reaper.GetEnvelopeStateChunk( tr_env, '', false )
        if retval then reaper.SetEnvelopeStateChunk( tr_env, env_chunk:gsub('ACT [%d]', 'ACT '..state), false ) end
      end
    end
  end

  local _,_,sectionID,cmdID = reaper.get_action_context()
  local state = reaper.GetToggleCommandState( cmdID )
  if state == -1 then state = 1 end
  reaper.SetToggleCommandState( sectionID, cmdID, math.abs(1-state) )
  reaper.Undo_BeginBlock()
  main(state)
  reaper.Undo_EndBlock("Toggle bypass selected tracks envelopes", 0)