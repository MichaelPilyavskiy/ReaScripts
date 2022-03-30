-- @description Adjust arrange grid (mousewheel) 
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # limit to [1...1/1024]
 
 
  function main()
     _,_,_,_,_,_,mouse_scroll  = reaper.get_action_context() 
     retval, division, swingmode, swingamt = reaper.GetSetProjectGrid( 0, false, 0, 0, 0 )
    if mouse_scroll > 0  then 
      --reaper.Main_OnCommand(40783, 0)--Grid: Adjust by 1/2
      reaper.GetSetProjectGrid( 0, true, math.max(division/2, 2^-10), swingmode, swingamt )
     elseif mouse_scroll < 0 then 
      --reaper.Main_OnCommand(40786, 0)--Grid: Adjust by 2
      reaper.GetSetProjectGrid( 0, true, math.min(1,division*2), swingmode, swingamt )
    end
  end
  
  
  reaper.defer(main)