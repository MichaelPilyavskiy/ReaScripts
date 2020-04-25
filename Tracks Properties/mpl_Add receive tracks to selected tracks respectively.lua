-- @description Add receive tracks to selected tracks respectively
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # change name


  local defsendvol = ({reaper.BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendvol', '0',  reaper.get_ini_file() )})[2]
  local defsendflag = ({reaper.BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendflag', '0',  reaper.get_ini_file() )})[2]
    
  function main()
    local retval, sname = reaper.GetUserInputs( 'Send name', 1, '' ,'')
    if retval or retval1 then 
      for i = 1, reaper.CountSelectedTracks(0) do
        local tr = reaper.GetSelectedTrack(0,i-1)
        if tr then 
          track_col =  reaper.GetTrackColor( tr )
          if i == 1 then 
            reaper.InsertTrackAtIndex( reaper.GetNumTracks(0), true )
            new_dest_tr =  reaper.CSurf_TrackFromID( reaper.GetNumTracks(0), false )
          end
          
          new_send_id = reaper.CreateTrackSend( tr, new_dest_tr)
          if new_send_id >= 0 then
            if new_dest_tr then
              reaper.GetSetMediaTrackInfo_String( new_dest_tr, 'P_NAME', sname ,true)
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
  