-- @description Remove item under mouse cursor
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
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
  -------------------------------------------------------------------- 
  function main()  
    item = VF_GetItemTakeUnderMouseCursor()
    if item then reaper.DeleteTrackMediaItem( GetMediaItem_Track( item ), item) reaper.UpdateArrange() end
  end
  ------------------------------------------------------------------------------------------------------
  function VF_GetItemTakeUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local item , take = reaper.GetItemFromPoint( screen_x, screen_y, true )
    return item , take
  end
--------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.981,true)    then 
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock("Remove item under mouse cursor", 0xFFFFFFFF)
  end    

