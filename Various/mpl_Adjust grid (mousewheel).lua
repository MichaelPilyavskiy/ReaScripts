-- @description Adjust grid (mousewheel) 
-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @website http://forum.cockos.com/member.php?u=70694
 
 
  function main()
     _,_,_,_,_,_,mouse_scroll  = reaper.get_action_context() 
    if mouse_scroll > 0 then 
      reaper.Main_OnCommand(40783, 0)--Grid: Adjust by 1/2
     elseif mouse_scroll < 0 then 
      reaper.Main_OnCommand(40786, 0)--Grid: Adjust by 2
    end
  end
  
  
  reaper.defer(main)