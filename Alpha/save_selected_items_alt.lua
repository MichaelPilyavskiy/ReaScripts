count_sel_items = reaper.CountSelectedMediaItems(0)
if count_sel_items ~= nil then
  for i = 1, count_sel_items do
    sel_item = reaper.GetSelectedMediaItem(0,i-1)
    track = reaper.GetMediaItem_Track(sel_item)
    track_guid = reaper.GetTrackGUID(track)
    sel_item_guid = reaper.BR_GetMediaItemGUID(sel_item)    
    reaper.SetExtState("Sel_items_guid", i, sel_item_guid, false)
    reaper.SetExtState("Sel_items_tracks_guid", i, track_guid, false)
  end
  reaper.SetExtState("Sel_items_guid", "count", count_sel_items, false)
end
