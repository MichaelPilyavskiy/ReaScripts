count_stored_guids_s = reaper.GetExtState("Sel_items_guid", "count")
count_stored_guids = tonumber(count_stored_guids_s)
reaper.DeleteExtState("Sel_items_guid", "count", true)

if count_stored_guids ~= nil  then
 if count_stored_guids > 0 then 
  for i = 1, count_stored_guids do
    stored_guid = reaper.GetExtState("Sel_items_guid", i)
    
    stored_track_guid = reaper.GetExtState("Sel_items_tracks_guid", i)
    
    item = reaper.BR_GetMediaItemByGUID(0, stored_guid)    
    item_s = tostring(item)
    if item ~= nil and item_s ~= "userdata: 0000000000000000" then
      track = reaper.GetMediaItem_Track(item)
      track_guid = reaper.GetTrackGUID(track)
      if track_guid == stored_track_guid then
        reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
      end  
    end 
    reaper.DeleteExtState("Sel_items_guid", i, true)
    reaper.DeleteExtState("Sel_items_tracks_guid", i, true)
  end
 end 
end  

reaper.UpdateArrange()
