-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description Toggle 64x oversampling for all ReaComp instances
-- @website http://forum.cockos.com/member.php?u=70694


  function main(state) 
    aa = state*64
  
    for i = 1, reaper.CountTracks(0) do
      local tr = reaper.GetTrack(0,i-1)
      for k = 1,  reaper.TrackFX_GetCount( tr ) do
        local fx = reaper.TrackFX_GetByName( tr, 'reacomp', false )
        if fx >= 0 then    
          stage = math.log(aa, 2)
          if stage < 0 then stage = 0 end
          val = stage*0.167
          reaper.TrackFX_SetParamNormalized( tr, fx, 18, val )
        end
      end
    end
    
  end

  _,_,sectionID,cmdID = reaper.get_action_context()
  state = reaper.GetToggleCommandState( cmdID )
  if state == -1 then state = 1 end
  reaper.SetToggleCommandState( sectionID, cmdID, math.abs(1-state) )


  reaper.Undo_BeginBlock()
  main(state)
  reaper.Undo_EndBlock("Toggle 64x oversampling for all ReaComp instances", 0) 