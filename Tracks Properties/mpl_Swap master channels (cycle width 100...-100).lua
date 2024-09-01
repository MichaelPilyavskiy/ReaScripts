-- @description Swap master channels (cycle width 100...-100)
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
   
------------------------------------------------------------------   
  function main() 
    local tr =  GetMasterTrack( 0 )
    SetMediaTrackInfo_Value( tr, 'I_PANMODE', 5  )
    local D_WIDTH = GetMediaTrackInfo_Value( tr, 'D_WIDTH'  )
    if D_WIDTH > 0 then SetMediaTrackInfo_Value( tr, 'D_WIDTH', -1) else SetMediaTrackInfo_Value( tr, 'D_WIDTH', 1) end
  end
  
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true) then  main() end 
  
  