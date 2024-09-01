-- @description Set stereo as parent channels for selected tracks
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
  ----
 
  --NOT gfx NOT reaper
  --------------------------------------------------------------------
  function main()
    local cnttr = CountSelectedTracks(0)
    for tr_id = 1, cnttr do
      local track = GetSelectedTrack( 0,tr_id-1 )
      SetMediaTrackInfo_Value( track, 'C_MAINSEND_NCH', 2 )
      SetMediaTrackInfo_Value( track, 'C_MAINSEND_OFFS', 0 )
    end
  end

  -------------------------------------------------------------------- 
  if VF_CheckReaperVrs(6.72,true) then 
      Undo_BeginBlock2( 0 )
      main() 
      reaper.Undo_EndBlock2( 0, 'Set stereo as parent channels for selected tracks', 0xFFFFFFFF )
    end 