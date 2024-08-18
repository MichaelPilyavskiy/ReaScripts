-- @description Offline all the track FX before focused FX
-- @version 1.02
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
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
    local retval, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX2()
    if not (retval&1==1) then return end
    if tracknumber == 0 then return end
    local track = GetTrack(0,tracknumber-1)
    if not track then return end
    if fxnumber&0x1000000==0x1000000 then return end -- ignore input
    for fx = fxnumber-1,  0, -1 do
      reaper.TrackFX_SetOffline( track, fx, true )
    end 
  end
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.975,true) then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Offline all the track FX before focused FX', 0 )
  end