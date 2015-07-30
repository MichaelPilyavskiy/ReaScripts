sel_track_guid_t = {}
count_sel_tracks = reaper.CountSelectedTracks(0)
if count_sel_tracks ~= nil then 
  for i = 1, count_sel_tracks do
    sel_track = reaper.GetSelectedTrack(0, i-1)
    sel_track_guid = reaper.BR_GetMediaTrackGUID(sel_track)
    table.insert(sel_track_guid_t, sel_track_guid)
  end
end    

if sel_track_guid_t ~= nil then
  for i = 1, #sel_track_guid_t do
    reaper.Main_OnCommand(40297, 0) -- unselect all tracks
    sel_track_guid = sel_track_guid_t[i]
    sel_track = reaper.BR_GetMediaTrackByGUID(0, sel_track_guid)
    reaper.SetMediaTrackInfo_Value(sel_track, "I_SELECTED", 1)
    count_sends = reaper.GetTrackNumSends(sel_track, 0)
    for j = 1, count_sends do
      send_track = reaper.BR_GetMediaTrackSendInfo_Track(sel_track, 0, j-1, 1)
      reaper.SetMediaTrackInfo_Value(send_track, "I_SELECTED", 1)
    end
    reaper.Main_OnCommand(41823, 0) -- add to render queue
  end  
end

reaper.MB(#sel_track_guid_t.." files added to render queue", "", 0)
reaper.UpdateArrange()
