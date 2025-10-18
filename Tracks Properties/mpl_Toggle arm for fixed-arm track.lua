-- @description Toggle arm for fixed-arm track
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # use per track setting

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
    for i = 1, CountTracks(-1) do
      local tr = GetTrack(-1,i-1)
      ret, str = GetSetMediaTrackInfo_String( tr, 'P_EXT:MPL_FIXEDARM', '',0 )
      if str == '1' then 
        I_RECARM = GetMediaTrackInfo_Value( tr, 'I_RECARM')
        SetMediaTrackInfo_Value( tr, 'I_RECARM', I_RECARM~1 )
        return I_RECARM~1
      end
    end
  end
  ----------------------------------------------------------------------
  function SetButtonState( set )
    local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    reaper.SetToggleCommandState( sec, cmd, set or 0 )
    reaper.RefreshToolbar2( sec, cmd )
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.68,true) then set = main() if set then SetButtonState( set ) end  end
