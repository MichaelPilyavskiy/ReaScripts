-- @version 1.01
-- @author MPL
-- @description Delete offline fx from selected tracks
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
  --------------------------------------------------------------------
  function main()
    Undo_BeginBlock()
    for i =1, CountSelectedTracks(0) do 
      local tr = GetSelectedTrack(0,i-1)
      for fx = TrackFX_GetCount( tr ), 1, -1 do
        local isoff = TrackFX_GetOffline( tr, fx-1 )
        if isoff then TrackFX_Delete(tr, fx-1) end
      end
    end
    Undo_EndBlock('Delete offline fx from selected tracks', 0xFFFFFFFF)
  end
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.95, true) then main() end
    