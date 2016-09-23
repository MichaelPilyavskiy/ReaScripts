-- @description Remove all non-1x stretch markers from selected items
-- @version 1.0
-- @author mpl
-- @website http://forum.cockos.com/member.php?u=70694 
-- @changelog
--    + init 
  
  local r = reaper
  function  msg(s) r.ShowConsoleMsg(s..'\n') end
  function main(item)
    if not item then return end
    take = r.GetActiveTake(item)
    if not take or r.TakeIsMIDI(take) then return end
    t = {}
    for i = 2, reaper.GetTakeNumStretchMarkers( take ) do
      local _, pos, srcpos = reaper.GetTakeStretchMarker( take, i-1 )
      local _, pos2, srcpos2 = reaper.GetTakeStretchMarker( take, i-2 )      
      local val = math.floor(100*(0.005+(srcpos2 - srcpos ) / (pos2-pos)))/100
      t[#t+1] = val
    end
    
    for i =reaper.GetTakeNumStretchMarkers( take )-1, 1, -1 do
      if (t[i-1] == 1.0 and t[i] == 1.0 and t[i+1] ~= 1.0) then 
        reaper.DeleteTakeStretchMarkers( take, i ) 
       elseif  (t[i-1] ~= 1.0 and t[i] == 1.0 and t[i+1] == 1.0) then 
        reaper.DeleteTakeStretchMarkers( take, i-1 ) 
      end
    end
  end
-----------------------------------------------------------------------------  
  reaper.Undo_BeginBlock() 
  for i = 1, r.CountSelectedMediaItems(0) do
    item = r.GetSelectedMediaItem(0,i-1) 
    main(item)
  end
  r.UpdateArrange()
  reaper.Undo_EndBlock("Remove all non-1x stretch markers from selected items", 0)
