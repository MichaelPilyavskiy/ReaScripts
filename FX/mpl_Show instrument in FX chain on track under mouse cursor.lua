-- @description Show instrument in FX chain on track under mouse cursor
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
    track = VF_GetTrackUnderMouseCursor()
    if track then
      vsti_id = reaper.TrackFX_GetInstrument(track)
      if vsti_id ~= nil then
        reaper.TrackFX_Show(track, vsti_id, 1) -- select in fx chain      
      end 
    end -- if track ~= nil then
  end
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.981,true)  then
    script_title = "Show instrument in FX chain on track under mouse cursor"
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock(script_title, 0)
  end  
