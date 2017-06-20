-- @version 1.1
-- @author MPL
-- @changelog
--   # perform on master track
-- @description Toggle bypass selected tracks envelopes (reset FX parameters)
-- @website http://forum.cockos.com/member.php?u=70694
 
  function main(state) local tr
    for i = 0, reaper.CountSelectedTracks(0) do
      if i == 0 then tr = reaper.GetMasterTrack(0) if not reaper.IsTrackSelected(tr) then goto skip end else tr = reaper.GetSelectedTrack(0,i-1) end    
      for env = 1,  reaper.CountTrackEnvelopes( tr ) do
        local tr_env = reaper.GetTrackEnvelope( tr, env-1 )
        local retval, env_chunk = reaper.GetEnvelopeStateChunk( tr_env, '', false )
        -- reaper.GetTrackEnvelopeByChunkName( tr, env_chunk:match('[^\n\r]+') )
        if retval then reaper.SetEnvelopeStateChunk( tr_env, env_chunk:gsub('ACT [%d]', 'ACT '..state), false ) end
        
        local _, p_fx, p_param = reaper.Envelope_GetParentTrack( tr_env )
        if state == 0 and p_fx >= 0 and p_param>=0 then
          local _, value = reaper.Envelope_Evaluate( tr_env, 0, 44100, 1 )
          reaper.TrackFX_SetParam( tr, p_fx, p_param, value )
        end        
      end
      ::skip::
    end
  end

  local _,_,sectionID,cmdID = reaper.get_action_context()
  local state = reaper.GetToggleCommandState( cmdID )
  if state == -1 then state = 1 end
  reaper.SetToggleCommandState( sectionID, cmdID, math.abs(1-state) )
  reaper.Undo_BeginBlock()
  main(state)
  reaper.Undo_EndBlock("Toggle bypass selected tracks envelopes (reset FX parameters)", 0)