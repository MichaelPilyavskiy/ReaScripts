-- @description Enable LFO for last touched parameter
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # use TrackFX_GetParam instead TrackFX_GetParamNormalized

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
  ----------------------------------------------------------------
  function main()
     local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
     if not retval then return end
     
     local trid = tracknumber&0xFFFF
     local itid = (tracknumber>>16)&0xFFFF
     if itid > 0 then return end -- ignore item FX
     local tr
     if trid==0 then tr = GetMasterTrack(0) else tr = GetTrack(0,trid-1) end
     if not tr then return end
     
     baseline = TrackFX_GetParam( tr, fxnumber, paramnumber )
     
     TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.mod.baseline', baseline)
     TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.lfo.active', 1)
     TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.lfo.strength', 0.2)
     TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.lfo.dir', 0)
     --param.X.lfo.[active,dir,phase,speed,strength,temposync,free,shape] : parameter moduation LFO state
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.37) then  
    Undo_BeginBlock2( 0 )
    main()
    Undo_EndBlock2( 0, 'Enable LFO for last touched parameter', 0xFFFFFFFF )
  end
  