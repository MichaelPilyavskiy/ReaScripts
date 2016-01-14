--[[
   * ReaScript Name: Conditional bounce-in-place
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
  reaper.Undo_BeginBlock() 
  reaper.PreventUIRefresh(1)  

  function main()
    sel_item = reaper.GetSelectedMediaItem(0,0)
    if sel_item ~= nil then
      it_track = reaper.GetMediaItemTrack(sel_item)
      reaper.Main_OnCommand(40289, 0) -- unselect all items
      reaper.SetMediaItemInfo_Value(sel_item, 'B_UISEL', 1)
      reaper.Main_OnCommand(40209,0) -- apply take fx
      
     else
      
      track = reaper.GetSelectedTrack(0,0)
      if track == nil then return end
      track_id = reaper.CSurf_TrackToID(track,0) 
      reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_AWRENDERSTEREOSMART'), 0)
      stem_track = reaper.CSurf_TrackFromID(track_id, 0)
      orig_track = reaper.CSurf_TrackFromID(track_id+1, 0)
      reaper.SetMediaTrackInfo_Value(stem_track, 'I_SELECTED', 0)
      reaper.SetMediaTrackInfo_Value(orig_track, 'I_SELECTED', 1)
      
      rend_item = reaper.GetTrackMediaItem(stem_track, 0)
      reaper.MoveMediaItemToTrack(rend_item, orig_track)
      reaper.DeleteTrack(stem_track)
      reaper.SetMediaTrackInfo_Value(orig_track, 'B_MUTE', 0)
    end
  end
  


  main()
reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Conditional bounce in place',0)
