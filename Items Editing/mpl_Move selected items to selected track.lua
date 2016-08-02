-- @version 1.0
-- @author mpl
-- @changelog
--   + init alpha
-- @description Move selected items to selected track 
-- @website http://forum.cockos.com/member.php?u=70694

  function main()
    cnt_items = reaper.CountSelectedMediaItems(0)
    if cnt_items == 0 then return end
    
    new_track = reaper.GetSelectedTrack(0,0)
    if not new_track then return end
    
    local items = {}
    for i = 1, cnt_items do
      item = reaper.GetSelectedMediaItem(0,i-1)  
      items[i] =  reaper.BR_GetMediaItemGUID( item )
    end
    
    for i = 1, #items do
      item = reaper.BR_GetMediaItemByGUID( 0, items[i] )
      if item == nil then return end
      item_track = reaper.GetMediaItem_Track(item)
    
      if new_track ~= item_track then 
        local _, item_chunk =  reaper.GetItemStateChunk(item, '')
        reaper.DeleteTrackMediaItem(item_track, item)
        new_item = reaper.AddMediaItemToTrack(new_track)
        reaper.SetItemStateChunk(new_item, item_chunk)
      end
    end
    reaper.UpdateArrange()
  end
  
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock('Move selected items to selected track ', 0)
