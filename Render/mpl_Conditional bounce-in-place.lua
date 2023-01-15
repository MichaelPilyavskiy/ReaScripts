-- @version 1.03
-- @author MPL
-- @description Conditional bounce-in-place
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # crop to active take on source item

  
  function Act(id) reaper.Main_OnCommand(id, 0) end
  
  function main()
    local item = reaper.GetSelectedMediaItem(0,0)
    if not item then return end
    Act(40289) -- unselect all items 
    reaper.SetMediaItemSelected( item, true )   
    reaper.Main_OnCommand(40209,0) -- apply take fx 
    local _, it_chunk = reaper.GetItemStateChunk( item, '', true )
    local item_track = reaper.GetMediaItemTrack(item)      
    local cur_tr_id =  reaper.CSurf_TrackToID(item_track, false)
    
    local new_track = reaper.GetSelectedTrack(0,0)
    if not new_track or item_track == new_track then
      reaper.InsertTrackAtIndex(cur_tr_id, false )
      new_track = reaper.CSurf_TrackFromID(cur_tr_id+1, false)
      reaper.TrackList_AdjustWindows( false )
    end
    local new_item = reaper.AddMediaItemToTrack( new_track )
    reaper.SetItemStateChunk( new_item, it_chunk, true )
    local take = reaper.GetActiveTake(new_item)    
    Act(40289) -- unselect all items 
    reaper.SetMediaItemSelected( new_item, true ) 
    Act(40131) -- Take: Crop to active take in items
    Act(40289) -- unselect all items 
    reaper.SetMediaItemSelected( item, true ) 
    take = reaper.GetTake( item, 0 )
    reaper.SetActiveTake( take )
    Act(40131) -- Take: Crop to active take in items
    reaper.UpdateArrange()
  end    

  reaper.Undo_BeginBlock() 
  reaper.PreventUIRefresh(1)  
  main()
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Conditional bounce in place',0)