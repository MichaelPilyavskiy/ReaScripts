-- @description Show selected envelope FX
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
  -------------------------------------------------------------------- 
  if VF_CheckReaperVrs(6.72,true) then  
    env = reaper.GetSelectedEnvelope( 0 )
    if env then
      tr, fx, index2 = reaper.Envelope_GetParentTrack( env ) 
      reaper.TrackFX_Show( tr, fx, 3 ) 
    end 
  end