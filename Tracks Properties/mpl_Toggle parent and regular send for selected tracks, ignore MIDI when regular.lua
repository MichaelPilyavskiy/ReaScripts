-- @version 1.0
-- @author MPL
-- @changelog
--    + init  
-- @description Toggle parent and regular send for selected tracks, ignore MIDI when regular
-- @website http://forum.cockos.com/showthread.php?t=188335
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  function main(tr)
    if not tr then return end
    local mast_send = GetMediaTrackInfo_Value( tr, 'B_MAINSEND' )
    local parent_tr = GetParentTrack( tr ) 
    if mast_send == 1 then 
      SetMediaTrackInfo_Value( tr, 'B_MAINSEND',0 )
      local s_id = CreateTrackSend( tr,  parent_tr)
      SetTrackSendInfo_Value( tr, 0, s_id, 'I_MIDIFLAGS',-1 )
     else
      SetMediaTrackInfo_Value( tr, 'B_MAINSEND',1)
      for i = 1, GetTrackNumSends( tr, 0 ) do
        local dest_tr = BR_GetMediaTrackSendInfo_Track( tr, 0, i-1, 1 )
        if dest_tr == parent_tr then
          RemoveTrackSend( tr, 0, i-1 )
          break
        end
      end
    end
  end
  
  for trid = 1, CountSelectedTracks(0) do
    tr= GetSelectedTrack(0,trid-1)
    main(tr)
  end