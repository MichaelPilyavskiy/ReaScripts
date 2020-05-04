-- @description Adjust arrange grid (mousewheel) 
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # change name
 
 
  function main()
     _,_,_,_,_,_,mouse_scroll  = reaper.get_action_context() 
    if mouse_scroll > 0 then 
      reaper.Main_OnCommand(40783, 0)--Grid: Adjust by 1/2
     elseif mouse_scroll < 0 then 
      reaper.Main_OnCommand(40786, 0)--Grid: Adjust by 2
    end
  end
  
  
  reaper.defer(main)