-- @description Toggle arm for fixed-arm track
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix exit if selecled track not exiusts

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
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or -1) do
      local tr = GetTrack(reaproj or -1,i-1)
      --local GUID = reaper.GetTrackGUID( tr )
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end
  ---------------------------------------------------------------------  
  function main()  
    local ret, giv_guid = GetProjExtState( -1, 'MPL_FIXARM', 'TRGUID')
    if ret and giv_guid ~= '' then 
      tr = VF_GetTrackByGUID(giv_guid)
      if tr then 
        I_RECARM = GetMediaTrackInfo_Value( tr, 'I_RECARM' )
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