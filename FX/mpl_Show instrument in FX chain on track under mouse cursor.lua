--[[
   * ReaScript Name: Show instrument in FX chain on track under mouse cursor
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
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
