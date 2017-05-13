-- @description Set solo for random selected track
-- @version 1.0
-- @author MPL
-- @changelog
--    + init
-- @website http://forum.cockos.com/member.php?u=70694

cnt = reaper.CountSelectedTracks(0)
set_rand = math.floor(  math.random() * cnt)
for i = 0, cnt-1 do
  tr = reaper.GetSelectedTrack(0,i)
  if i == set_rand then reaper.CSurf_OnSoloChange( tr, 1 ) else reaper.CSurf_OnSoloChange( tr, 0) end
end
reaper.UpdateArrange()
