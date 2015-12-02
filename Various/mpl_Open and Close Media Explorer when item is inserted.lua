--[[
   * Open and Close Media Explorer when item is inserted
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URL: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
-- mpl_Open_and_Close_Media_Explorer_when_item_is_inserted.lua

function run()
  is_me_open = reaper.GetToggleCommandState(50124)
  count_items0 = reaper.CountMediaItems(0)
  if count_items0 ~= count_items or is_me_open == 0 
    then reaper.Main_OnCommand(50124, 0) reaper.atexit() 
    else reaper.defer(run) 
  end
end

count_items = reaper.CountMediaItems(0)
is_me_open = reaper.GetToggleCommandState(50124)
if is_me_open == 0 then reaper.Main_OnCommand(50124, 0) end -- open MediaExplorer
run()
