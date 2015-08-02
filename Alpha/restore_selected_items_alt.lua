count_stored_guids_s = reaper.GetExtState("Sel_items_guid", "count")
count_stored_guids = tonumber(count_stored_guids_s)
reaper.DeleteExtState("Sel_items_guid", "count", true)

if count_stored_guids ~= nil  then
 if count_stored_guids > 0 then 
  for i = 1, count_stored_guids do
    stored_guid = reaper.GetExtState("Sel_items_guid", i)
    reaper.DeleteExtState("Sel_items_guid", i, true)
    stored_track_guid = reaper.GetExtState("Sel_items_tracks_guid", i)
    reaper.DeleteExtState("Sel_items_tracks_guid", i, true)
    item = reaper.BR_GetMediaItemByGUID(0, stored_guid)
    if item ~= nil then
      track = reaper.GetMediaItem_Track(item)
      track_guid = reaper.GetTrackGUID(track)
      if track_guid == stored_track_guid then
        reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
      end  
    end 
  end
 end 
end  

reaper.UpdateArrange()
