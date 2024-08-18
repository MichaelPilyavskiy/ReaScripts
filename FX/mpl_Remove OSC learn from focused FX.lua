-- @description Remove OSC learn from focused FX
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
  ---------------------------------------------------
  script_title_out = 'Remove OSC learn from focused FX'
  
  function main()
    local retval, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX2()
    if retval&1~=1 then return end
    local tr  if tracknumber==0 then tr = GetMasterTrack(0) else tr = GetTrack(0,tracknumber-1)end
    if not tr then return end
    
    for p = 1,  TrackFX_GetNumParams( tr, fxnumber ) do
      --TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..(p-1)..'.learn.midi1','' )
      --TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..(p-1)..'.learn.midi2','' )
      TrackFX_SetNamedConfigParm( tr, fxnumber,  'param.'..(p-1)..'.learn.osc','' )
    end
  end
  --------------------------------------------------------------------  
  if VF_CheckReaperVrs(6.37,true) then  
    Undo_BeginBlock2( 0 )
    main()
    Undo_EndBlock2( 0, script_title_out, 0xFFFFFFFF )
  end 