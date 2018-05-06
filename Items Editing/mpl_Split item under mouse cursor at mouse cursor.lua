-- @description Split item under mouse cursor at mouse cursor
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   + init

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function main()  
    BR_GetMouseCursorContext()
    local item = BR_GetMouseCursorContext_Item()
    if item then 
      local position = BR_GetMouseCursorContext_Position()
      SplitMediaItem( item, position )
      UpdateArrange() 
    end
  end
  
  main()