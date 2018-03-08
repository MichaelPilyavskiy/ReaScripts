-- @description Show instrument in FX chain on track under mouse cursor
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # ReaPack header
  
  function main()
    _ = reaper.BR_GetMouseCursorContext()
    track = reaper.BR_GetMouseCursorContext_Track()
    if track ~= nil then
      vsti_id = reaper.TrackFX_GetInstrument(track)
      if vsti_id ~= nil then
        reaper.TrackFX_Show(track, vsti_id, 1) -- select in fx chain      
      end 
    end -- if track ~= nil then
  end
  
  script_title = "Show instrument in FX chain on track under mouse cursor"
  reaper.Undo_BeginBlock() 
  main()
  reaper.Undo_EndBlock(script_title, 0)