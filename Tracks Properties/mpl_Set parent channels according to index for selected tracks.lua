-- @version 1.01
-- @author MPL
-- @description Set parent channels according to index for selected tracks
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # fix index offset
--   + extend master channel count if need
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  function main()
    if CountSelectedTracks(0) ==0 then return end
    local master =  GetMasterTrack( 0 ) 
    local mastch = reaper.GetMediaTrackInfo_Value( master, 'I_NCHAN')
    local ch = CountSelectedTracks(0)*2
    if mastch < ch then  reaper.SetMediaTrackInfo_Value( master, 'I_NCHAN', ch) end
    for i =1, CountSelectedTracks(0) do
      tr = GetSelectedTrack(0, i-1)
      reaper.SetMediaTrackInfo_Value( tr, 'C_MAINSEND_OFFS', (i- 1)*2)
      reaper.SetMediaTrackInfo_Value( tr, 'C_MAINSEND_NCH', 2)
    end
  end
  
Undo_BeginBlock()
main()
Undo_EndBlock("Set parent channels according to index for selected tracks", 0)