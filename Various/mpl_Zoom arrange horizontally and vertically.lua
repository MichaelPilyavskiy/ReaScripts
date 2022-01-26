-- @description Zoom arrange horizontally and vertically
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
  -------------------------------------------------------------------  

  _,_,_,_,mode,resolution,val = reaper.get_action_context() 
  function main()
    val = val / resolution
    if mode == 0 then
      if val > 0.5 then dir = 1 elseif val <0.5 then dir = -1 end
     elseif mode > 0 then 
      if val > 0 then dir = 1 elseif val <0 then dir = -1 end
    end
    --if dir then reaper.CSurf_OnZoom( dir, dir ) end
    reaper.adjustZoom( 0.1, 0, true, -1 )
  end
  
  reaper.defer(main)