-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Set fadeout of item under cursor to mouse position
-- @changelog
--    # VF independent

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
  ------------------------------------------------------------------------------------------------------
  function VF_GetItemTakeUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local item , take = reaper.GetItemFromPoint( screen_x, screen_y, true )
    return item , take
  end
    ---------------------------------------------------
  function VF_GetPositionUnderMouseCursor()
    
    local x,y = reaper.GetMousePosition()
    local mouse_pos = reaper.GetSet_ArrangeView2(0, false, x, x+1) -- get
    
    local arr_start, arr_end = reaper.GetSet_ArrangeView2(0, false, 0, 0) -- get
    if mouse_pos >= arr_start and mouse_pos <= arr_end then
      return mouse_pos
    
    end
  end
    ---------------------------------------------------
  function main()
    local item = VF_GetItemTakeUnderMouseCursor()
    pos_cur = VF_GetPositionUnderMouseCursor()
    if item then
      local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      local len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH' )   
      reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN_AUTO', -1)
      reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', pos + len-pos_cur)
      reaper.UpdateItemInProject(item)
    end
  end
--------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.95,true)    then 
    reaper.Undo_BeginBlock()
    main()
    reaper.Undo_EndBlock("Set fadeout of item under cursor to mouse position", 0)
  end     

