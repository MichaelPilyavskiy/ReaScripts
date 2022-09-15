-- @description Float Fre(a)koscope on selected track
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--  + init

function main() 
  local tr = reaper.GetSelectedTrack(0,0)
  if not tr then return end
  id_0 =  reaper.TrackFX_GetByName( tr, 'Fre(a)koscope', false )
  id =  reaper.TrackFX_GetByName( tr, 'Fre(a)koscope', true )
  if id_0 ==-1 then return end
  if id >= 0 then
    local state= reaper.TrackFX_GetOpen( tr, id )
    if state == true then state = 0 else state = 1 end
    reaper.TrackFX_SetOpen( tr, id, state)
  end
end

reaper.defer(main)