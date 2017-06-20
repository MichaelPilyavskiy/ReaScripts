-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description Set parent channels according to index for selected tracks
-- @website http://forum.cockos.com/member.php?u=70694
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  function main()
    for i =1, CountSelectedTracks(0) do
      tr = GetSelectedTrack(0, i-1)
      reaper.SetMediaTrackInfo_Value( tr, 'C_MAINSEND_OFFS', i*2 )
    end
  end
  
Undo_BeginBlock()
main()
Undo_EndBlock("Set parent channels according to index for selected tracks", 0)