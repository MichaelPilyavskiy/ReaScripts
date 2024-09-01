-- @description Go to first receive track (send source)
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
  function main()
    local receive_id = 1 
    local tr = GetSelectedTrack(0,0)
    if not tr then  return end
    local receive_tr = GetTrackSendInfo_Value( tr, -1, receive_id-1, 'P_SRCTRACK' )
    if not (receive_tr and ValidatePtr(receive_tr, 'MediaTrack*'))then return end
    
    reaper.Main_OnCommand(40297,0) -- unselect all
    reaper.SetTrackSelected(receive_tr, true) 
    reaper.SetMixerScroll(receive_tr)
    reaper.Main_OnCommand(40913,0) -- arrange view to selected send  

  end

  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.78,true) then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, "Go to first receive track", 0xFFFFFFFF )
  end 