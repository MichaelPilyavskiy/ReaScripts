-- @description Set selected tracks ReaGate threshold to peak hold level
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
 
 
  function MPL_SetReaGateThreshold(tr,reagate)
    local state = TrackFX_GetEnabled( tr, reagate )
    if not state then return end
    local peakh = reaper.Track_GetPeakHoldDB( tr, reagate, false )/0.01
    if peakh <= -149 then return end
    TrackFX_SetParamNormalized( tr, reagate, 0, WDL_DB2VAL(peakh) )
  end
  -------------------------------------------------------------------- 
  function main()
    for i= 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      if tr then 
        local reagate = TrackFX_AddByName( tr, 'reagate', false, 0 )
        if reagate ~= -1 then
          MPL_SetReaGateThreshold(tr,reagate)
          goto nexttrack
        end
      end
      ::nexttrack::
    end
  end
  -------------------------------------------------------------------- 
  if VF_CheckReaperVrs(5.99,true) then main() end 