-- @description Mute item under mouse cursor
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
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
     
  --NOT gfx NOT reaper
  ------------------------------------------------------------------------------------------------------
  function VF_GetItemTakeUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local item , take = reaper.GetItemFromPoint( screen_x, screen_y, true )
    return item , take
  end
--------------------------------------------------------------------
  function main()
    local item = VF_GetItemTakeUnderMouseCursor()
    if not item then return end
    SetMediaItemInfo_Value( item, 'B_MUTE' ,1 )
    UpdateItemInProject( item )
  end
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true)   then     
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock("Mute item under mouse cursor", 0xFFFFFFFF)
  end