-- @description Disable master or parent send for track under mouse cursor
-- @version 1.02
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
  ---------------------------------------------------
  function VF_GetTrackUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local retval, info = reaper.GetTrackFromPoint( screen_x, screen_y )
    return retval
  end
    ---------------------------------------------------
  function main()
    tr =  VF_GetTrackUnderMouseCursor()
    if tr then 
      reaper.Undo_BeginBlock()
      reaper.SetMediaTrackInfo_Value( tr, 'B_MAINSEND', 0 ) 
      reaper.Undo_EndBlock( 'Disable master or parent send for track under mouse cursor', -1 )
    end
  end

---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true)    then 
    script_title = "Disable master or parent send for track under mouse cursor"
    reaper.Undo_BeginBlock()
    main()
    reaper.Undo_EndBlock(script_title, 0)
  end  
