-- @description Add send to selected tracks
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + init release
  
  function main()
    local retval, pref = reaper.GetUserInputs( 'Set send prefix', 1, '' ,'')
    local retval1, suff = reaper.GetUserInputs( 'Set send suffix', 1, '' ,'')
    if retval or retval1 then 
      for i = 1, reaper.CountSelectedTracks(0) do
        local tr = reaper.GetSelectedTrack(0,i-1)
        if tr then 
          track_col =  reaper.GetTrackColor( tr )
          _, src_name = reaper.GetSetMediaTrackInfo_String( tr, 'P_NAME', '',false )
          reaper.InsertTrackAtIndex( reaper.GetNumTracks(0), true )
          new_dest_tr =  reaper.CSurf_TrackFromID( reaper.GetNumTracks(0), false )
          reaper.SetTrackColor( new_dest_tr, track_col )
          new_send_id = reaper.CreateTrackSend( tr, new_dest_tr)
          if new_send_id >= 0 then
            new_name = pref..' '..src_name..' '..suff
            if new_dest_tr then
              reaper.GetSetMediaTrackInfo_String( new_dest_tr, 'P_NAME', new_name ,true)
            end
          end
        end
      end
      reaper.TrackList_AdjustWindows( false )
    end
  end
  
  main()
  
