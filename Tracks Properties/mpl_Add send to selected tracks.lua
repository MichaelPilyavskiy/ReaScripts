-- @description Add send to selected tracks
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # respect default send parameters
--    # forum link
--    - don`t set same color
  local defsendvol = ({reaper.BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendvol', '0',  reaper.get_ini_file() )})[2]
  local defsendflag = ({reaper.BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendflag', '0',  reaper.get_ini_file() )})[2]
    
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
          
          new_send_id = reaper.CreateTrackSend( tr, new_dest_tr)
          if new_send_id >= 0 then
            new_name = pref..' '..src_name..' '..suff
            if new_dest_tr then
              reaper.GetSetMediaTrackInfo_String( new_dest_tr, 'P_NAME', new_name ,true)
              reaper.SetTrackSendInfo_Value( tr, 0, new_send_id, 'D_VOL', defsendvol)
              reaper.SetTrackSendInfo_Value( tr, 0, new_send_id, 'I_SENDMODE', defsendflag)
            end
          end
        end
      end
      reaper.TrackList_AdjustWindows( false )
    end
  end
  
  main()
  