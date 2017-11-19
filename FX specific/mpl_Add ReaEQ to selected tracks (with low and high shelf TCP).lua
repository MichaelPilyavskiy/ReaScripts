-- @description Add ReaEQ to selected tracks (with low and high shelf TCP)
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  local scr_title = 'Add ReaEQ to selected tracks (with low and high shelf TCP)'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  --NOT gfx NOT reaper
  ---------------------------------------------------  
  function main(tr)    
  
      fxId_EQ  = TrackFX_AddByName( tr, 'ReaEQ', false, 1 )
      TrackFX_SetParamNormalized( tr, fxId_EQ, 1, 0 ) -- ls gain
      TrackFX_SetParamNormalized( tr, fxId_EQ, 10, 0 ) -- hs gain
      SNM_AddTCPFXParm( tr, fxId_EQ, 0 ) -- low shelf
      SNM_AddTCPFXParm( tr, fxId_EQ, 9 ) -- high shelf
  end
  ---------------------------------------------------
  Undo_BeginBlock()
  for i = 1, CountSelectedTracks(0) do
    tr = GetSelectedTrack(0,i-1)
    main(tr)
  end
  TrackList_AdjustWindows( false )
  Undo_EndBlock(scr_title, 1)