-- @description Toggle parent and regular send for selected tracks, ignore MIDI when regular
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Hardcode send level to 0dB
--    # remove SWS dependency
--    # ignore track if parent is master
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  function main(tr)
    if not tr then return end
    local mast_send = GetMediaTrackInfo_Value( tr, 'B_MAINSEND' )
    local parent_tr = GetParentTrack( tr )   
    local parent_trID = CSurf_TrackToID(parent_tr, false) 
    if not parent_trID then return end
    
    if mast_send == 1 then 
      SetMediaTrackInfo_Value( tr, 'B_MAINSEND',0 ) 
      local s_id = CreateTrackSend( tr,  parent_tr)
      SetTrackSendInfo_Value( tr, 0, s_id, 'I_MIDIFLAGS',-1 )
      SetTrackSendInfo_Value( tr, 0, s_id, 'I_SENDMODE',0 )
      SetTrackSendInfo_Value( tr, 0, s_id, 'D_VOL',1 ) -- overwrite send level to 0 dB
     else
      SetMediaTrackInfo_Value( tr, 'B_MAINSEND',1)
      for i = 1, GetTrackNumSends( tr, 0 ) do
        local dest_tr = GetTrackSendInfo_Value(tr, 0, i-1, 'P_DESTTRACK')
        if dest_tr == parent_tr then
          RemoveTrackSend( tr, 0, i-1 )
          break
        end
      end
    end
    
    
  end
  
  reaper.Undo_BeginBlock2( 0 )
  for trid = 1, CountSelectedTracks(0) do
    tr= GetSelectedTrack(0,trid-1)
    main(tr)
  end
  reaper.Undo_EndBlock2( 0, 'Toggle parent and regular send for selected tracks', 0xFFFFFFFF )