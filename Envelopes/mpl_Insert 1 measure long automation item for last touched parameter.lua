-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Insert 1 measure long automation item for last touched parameter
-- @changelog
--    # support track volume and pan envelopes

  local script_title = 'Insert 1 measure long automation item for last touched parameter'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ----------------------------------------------------------------------------------------------------
  function GetLastTouchedEnv(act_str)
    if not act_str then return str end
    if act_str == 'Adjust track volume' then
      local tr = GetLastTouchedTrack()
      SetOnlyTrackSelected( tr ) -- for perform setting env visible
      Main_OnCommand(40052,0)--Track: Toggle track volume envelope active
      return GetTrackEnvelopeByName( tr, 'Volume' )
     elseif act_str == 'Adjust track pan' then
      local tr = GetLastTouchedTrack()
      SetOnlyTrackSelected( tr ) -- for perform setting env visible
      Main_OnCommand(40053,0)--Track: Toggle track volume envelope active
      return GetTrackEnvelopeByName( tr, 'Pan' )   
     else
      local retval, tracknum, fxnum, paramnum = GetLastTouchedFX()
      if not retval then return end    
      local track =  CSurf_TrackFromID( tracknum, false )
      if not track then return end
      return GetFXEnvelope( track, fxnum, paramnum, true )       
    end
  end
  ----------------------------------------------------------------------------------------------------
  function InsertAI(env) 
    if not env then return end
    local AI_pos = GetCursorPosition()
    local cur_pos_beats, cur_pos_measures =  TimeMap2_timeToBeats( 0, AI_pos )
    local AI_len = TimeMap2_beatsToTime( 0, cur_pos_beats, cur_pos_measures+1 ) - AI_pos
    InsertAutomationItem( env, -1, AI_pos, AI_len ) -- add pool to RPP with negative srclen, not visible in project    
    TrackList_AdjustWindows( false )
    UpdateArrange()    
  end
  ----------------------------------------------------------------------------------------------------
  last_act =  Undo_CanUndo2( 0 )
  env = GetLastTouchedEnv(last_act)   
  InsertAI(env)