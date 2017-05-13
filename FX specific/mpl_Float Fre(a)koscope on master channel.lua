-- @version 1.0
-- @author MPL
-- @description Float Fre(a)koscope on master channel
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init

function main()
  id =  reaper.TrackFX_GetByName( reaper.GetMasterTrack(), 'Fre(a)koscope', true )
  if id >= 0 then reaper.TrackFX_Show( reaper.GetMasterTrack(), id, 3 ) end
end

reaper.defer(main)