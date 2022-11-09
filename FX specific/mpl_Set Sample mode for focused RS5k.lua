-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @description Set Sample mode for focused RS5k
-- @noindex
-- @changelog
--    + init


function main()
    local ret, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    local track = reaper.CSurf_TrackFromID( tracknumberOut, false )
    if not track then return end
    reaper.TrackFX_SetNamedConfigParm(track, fxnumberOut, "MODE",1)
  end


  reaper.Undo_BeginBlock()
  main(track)
  reaper.Undo_EndBlock('Set mode for focused RS5k', 2)