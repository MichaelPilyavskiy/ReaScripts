-- @description Go to next marker id
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  local t = {} for i = 1, ({reaper.CountProjectMarkers( 0 )})[2] do t[#t+1] = {({reaper.EnumProjectMarkers( i-1 )})[3],({reaper.EnumProjectMarkers( i-1 )})[6]} end  
  table.sort(t, function (a,b) return a[1]>b[1] end)
  for i =1,#t do if reaper.GetCursorPosition()+0.001 > t[i][1] then  cur = t[i] break end end
  if not cur then cur = {0,0} end
  table.sort(t, function (a,b) return a[2]<b[2] end)
  for i =1, #t do if cur[2] < t[i][2] then reaper.SetEditCurPos( t[i][1],true,true) break end end