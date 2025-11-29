-- @description Set solo for random selected track
-- @version 1.01
-- @author MPL
-- @changelog
--    # fix link
-- @website https://forum.cockos.com/showthread.php?t=188335

cnt = reaper.CountSelectedTracks(0)
set_rand = math.floor(  math.random() * cnt)
for i = 0, cnt-1 do
  tr = reaper.GetSelectedTrack(0,i)
  if i == set_rand then reaper.CSurf_OnSoloChange( tr, 1 ) else reaper.CSurf_OnSoloChange( tr, 0) end
end
reaper.UpdateArrange()
