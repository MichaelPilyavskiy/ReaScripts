-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Explode selected track RS5k instances to new tracks
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end

 ------------------------------------------------------------------------  
  function RenameTrAsFirstInstance(track)
    local fx_count =  TrackFX_GetCount(track)
    if fx_count >= 1 then
      local retval, fx_name =  TrackFX_GetFXName(track, 0, '')
      reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', MPL_ReduceFXname(fx_name), true)
    end
  end
  ------------------------------------------------------------------------
  function main()
    local src_track = GetSelectedTrack(0,0)
    if not src_track then  return end
    local tr_id = CSurf_TrackToID( src_track,false )
    for src_fx = TrackFX_GetCount( src_track ), 1, -1 do 
      InsertTrackAtIndex( tr_id, false )
      local dest_track = GetTrack(0,tr_id)
      TrackFX_CopyToTrack( src_track, src_fx-1, dest_track, 0, true )
      s_id = CreateTrackSend( src_track, dest_track ) 
      SetTrackSendInfo_Value( src_track, 0, s_id, 'I_SRCCHAN', -1 )
      SetTrackSendInfo_Value( src_track, 0, s_id, 'I_MIDIFLAGS', 0 )
      RenameTrAsFirstInstance(dest_track)
    end
  end
  
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true) then 
    Undo_BeginBlock2( 0 ) 
    main() 
    reaper.Undo_EndBlock2( 0, 'Explode selected track RS5k instances to new tracks', 0xFFFFFF )
  end
