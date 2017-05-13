--[[
   * ReaScript Name: Cut extension from selected item names
   * Lua script for Cockos REAPER
   * Author: MPL
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
  script_title = "Cut extension from selected item names"
   reaper.Undo_BeginBlock()
   
    count_sel_items = reaper.CountSelectedMediaItems(0)
  if count_sel_items ~= nil then
    for i=1, count_sel_items do
      item = reaper.GetSelectedMediaItem(0,i-1)
      if item ~= nil then
        take = reaper.GetActiveTake(item)
        if take ~= nil then
          retval, name = reaper.GetSetMediaItemTakeInfo_String(take, 'P_NAME','', false)       
          if name:find('[.]') ~= nil then
           reaper.GetSetMediaItemTakeInfo_String(take, 'P_NAME', name:sub(0,-name:reverse():find('[.]')-1 ), true)        
          end
        end
      end
      reaper.UpdateItemInProject(item)
    end    
  end
  
  reaper.Undo_EndBlock(script_title, 0)
