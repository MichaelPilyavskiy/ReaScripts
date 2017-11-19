-- @description Add time adjustment JSFX (delay) to selected tracks TCP
-- @about
--    Adds JS Delay to the end of FX chain and put delay control to TCP/MCP
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  local scr_title = 'Add time adjustment JSFX (delay) to selected tracks TCP'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  --NOT gfx NOT reaper
  ---------------------------------------------------  
  function main(tr)    
  
    -- delay
      local fxId_del = TrackFX_AddByName( tr, 'time_adjustment', false, 0 )
      if fxId_del < 0 then
        fxId_del  = TrackFX_AddByName( tr, 'time_adjustment', false, -1 )
        SNM_AddTCPFXParm( tr, fxId_del, 0 ) -- low shelf
      end           
  end
  ---------------------------------------------------
  Undo_BeginBlock()
  for i = 1, CountSelectedTracks(0) do
    tr = GetSelectedTrack(0,i-1)
    main(tr)
  end
  TrackList_AdjustWindows( false )
  Undo_EndBlock(scr_title, 1)