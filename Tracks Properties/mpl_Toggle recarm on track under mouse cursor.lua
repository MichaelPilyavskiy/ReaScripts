-- @description Toggle recarm on track under mouse cursor
-- @version 1.03
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
    local track = VF_GetTrackUnderMouseCursor()
    if track ~= nil then  
      if reaper.GetMediaTrackInfo_Value(track, 'I_RECARM') == 0 then
        --reaper.ClearAllRecArmed()
        reaper.SetMediaTrackInfo_Value(track, 'I_RECARM',1)
       else
        --reaper.ClearAllRecArmed()
        reaper.SetMediaTrackInfo_Value(track, 'I_RECARM',0)
      end  
    end
  end

  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.78,true)then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Toggle recarm on track under mouse cursor', 0xFFFFFFFF )
  end 