--[[
   * ReaScript Name: Sort all tracks by color
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.1
  ]]
 
 -- changelog:
 -- 1.1 - 8.12.2015 - rewrited from native copy paste actions to getset chunks
 
 script_title = "Sort all tracks by color"
 
  reaper.Undo_BeginBlock()
  
function check(tr_col)
  local col_exist = false
  if #tr_colors_t > 0 then
    for j = 1, #tr_colors_t do
      col = tr_colors_t[j]
      if tr_col == col then col_exist = true end
    end
  end  
  return col_exist
end    
  
reaper.PreventUIRefresh(1)
    
if reaper.CountTracks(0) ~= nil then
  tracks_t = {}
  for i = 1,  reaper.CountTracks(0) do
    tr = reaper.GetTrack(0,i-1)
    reaper.SetMediaTrackInfo_Value(tr,'I_FOLDERDEPTH', 0) 
    _, chunk = reaper.GetTrackStateChunk(tr, '', false)
    table.insert(tracks_t, {chunk,reaper.GetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR')})        
  end
  
  table.sort(tracks_t, function(a,b) return a[2]<b[2] end )
  
  for i = 1, #tracks_t do
    track = reaper.GetTrack(0,i-1)
    reaper.SetTrackStateChunk(track, tracks_t[i][1],true)
  end
  
end
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(script_title,0)
