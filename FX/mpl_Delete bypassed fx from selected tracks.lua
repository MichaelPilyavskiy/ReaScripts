-- @version 1.14
-- @author MPL
-- @description Delete bypassed fx from selected tracks
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   # ignore bypass envelopes

  
  --------------------------------------------------------------------
  function main()
    reaper.Undo_BeginBlock()
    for i =1, reaper.CountSelectedTracks(0) do 
      local tr = reaper.GetSelectedTrack(0,i-1)
      for fx = reaper.TrackFX_GetCount( tr ), 1, -1 do
        local is_byp = reaper.TrackFX_GetEnabled( tr, fx-1 )
        if not is_byp then 
          local paramId =   reaper.TrackFX_GetParamFromIdent( tr, fx-1,':bypass' )
          local env = reaper.GetFXEnvelope( tr, fx-1, paramId, false )
          if not (env and  reaper.ValidatePtr2( 0, env, 'TrackEnvelope*' ) == true) then
            reaper.TrackFX_Delete(tr, fx-1) 
          end
        end
      end
    end
    reaper.Undo_EndBlock('Delete bypassed fx from selected tracks', 0)
  end
  
  main()