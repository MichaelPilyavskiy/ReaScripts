-- @description Store selected track as fixed-arm track
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

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

  ---------------------------------------------------------------------  
  function main()  
    local tr = GetSelectedTrack(-1,0)
    if not tr then return end
    SetProjExtState( -1, 'MPL_FIXARM', 'TRGUID', reaper.GetTrackGUID(tr) )
  end
  
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.68,true) then main() end 