-- @description Float Fre(a)koscope on master channel
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # toggle FX window show

function main() 
  local master = reaper.GetMasterTrack()
  id =  reaper.TrackFX_GetByName( master, 'Fre(a)koscope', true )
  if id >= 0 then 
    local state= reaper.TrackFX_GetOpen( master, id )
    if state == true then state = 0 else state = 1 end
    reaper.TrackFX_SetOpen( master, id, state)
  end
end

reaper.defer(main)