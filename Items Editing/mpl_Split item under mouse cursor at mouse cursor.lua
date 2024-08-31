-- @description Split item under mouse cursor at mouse cursor
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent
--    # SWS independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  --------------------------------------------------------------------  
  function VF_GetPositionUnderMouseCursor()
    local x,y = reaper.GetMousePosition()
    local mouse_pos = reaper.GetSet_ArrangeView2(0, false, x, x+1) -- get
    
    local arr_start, arr_end = reaper.GetSet_ArrangeView2(0, false, 0, 0) -- get
    if mouse_pos >= arr_start and mouse_pos <= arr_end then
      return mouse_pos
    
    end
  end
  --------------------------------------------------------------------  
  function main()  
    local item = VF_GetItemTakeUnderMouseCursor()
    if item then  
      local position = VF_GetPositionUnderMouseCursor()
      if position then 
        SplitMediaItem( item, position )
        UpdateArrange() 
      end
    end
  end
    --------------------------------------------------------------------  
  function VF_GetItemTakeUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local item , take = reaper.GetItemFromPoint( screen_x, screen_y, true )
    return item , take
  end
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true) then 
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock("Split item under mouse cursor at mouse cursor", 0)
  end    

