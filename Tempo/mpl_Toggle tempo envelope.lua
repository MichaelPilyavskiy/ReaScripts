-- @version 1.0
-- @author MPL
-- @description Toggle tempo envelope
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  -------------------------------------------------------
  function main_SaveRemoveTempoEnv()  
    local tr = GetMasterTrack( 0 )
    local tempo_env = GetTrackEnvelope(  tr, 0 )
    local retval, te_chunk = GetEnvelopeStateChunk( tempo_env, '', false )
    SetProjExtState(0, 'MPL_TOGGLETEMPOENV', 'temptimesignenv', te_chunk ) 
    -- erase
    local m_cnt = CountTempoTimeSigMarkers( 0 )
    for markerindex =m_cnt, 1, -1 do DeleteTempoTimeSigMarker( 0, markerindex-1 ) end
  end
  ------------------------------------------------------- 
  function main_RestoreTempoEnv()
    -- restore envelope
      local ret, ext_te_chunk = GetProjExtState(0, 'MPL_TOGGLETEMPOENV', 'temptimesignenv') 
      if ret then  
        local tr = GetMasterTrack( 0 )
        local tempo_env = GetTrackEnvelope(  tr, 0 )
        SetEnvelopeStateChunk( tempo_env, ext_te_chunk, false ) 
      end
    -- update grid
      local m_cnt = CountTempoTimeSigMarkers( 0 )
      local retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = GetTempoTimeSigMarker( 0, m_cnt-1 )
      if retval then SetTempoTimeSigMarker( 0, m_cnt-1, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo ) end
  end
  -------------------------------------------------------
  local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
  local state = reaper.GetToggleCommandState( cmdID )
  if state == -1 then state = 0 end
  SetToggleCommandState( sectionID, cmdID, math.abs(1-state) )
  -------------------------------------------------------
  if state == 0 then main_SaveRemoveTempoEnv() else main_RestoreTempoEnv() end  
  UpdateTimeline() -- update ruler