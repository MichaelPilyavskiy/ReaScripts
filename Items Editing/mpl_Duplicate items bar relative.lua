--[[
   * ReaScript Name: Duplicate items bar relative
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]

script_title = "Duplicate items bar relative"
  
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  
  count_sel_items = reaper.CountSelectedMediaItems(0)
       
  if  count_sel_items ~= nil then
    item0 = reaper.GetSelectedMediaItem(0, 0)
    item_fin = reaper.GetSelectedMediaItem(0, count_sel_items-1) 
    if item_fin == nil or item0 == nil then return end
    
    item0_st = reaper.GetMediaItemInfo_Value(item0, "D_POSITION")
    itemfin_end = reaper.GetMediaItemInfo_Value(item_fin, "D_POSITION")
      +reaper.GetMediaItemInfo_Value(item_fin, "D_LENGTH") - 0.0001
    
    _, measures1 = reaper.TimeMap2_timeToBeats(0, item0_st)
    _, measures2 = reaper.TimeMap2_timeToBeats(0, itemfin_end)
    
    offs = item0_st - reaper.TimeMap2_beatsToTime(0, 0, measures1)
    
    diff = reaper.TimeMap2_beatsToTime(0, 0, measures2+1)
      - reaper.TimeMap2_beatsToTime(0, 0, measures1)
    reaper.ApplyNudge(2, 0, 5, 1, diff, 0, 1)
  end     
      
      
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(script_title, 0)
