-- @description Toggle parameter modulation for last touched parameter
-- @version 1.02
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
  function main() 
    local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
    if retval ==false then return end
    local track = CSurf_TrackFromID( tracknumber, false )
    if not track then return end
    local ret, pm_active = TrackFX_GetNamedConfigParm( track, fxnumber, 'param.'..paramnumber..'.mod.active' )
    if not ret then return end 
    pm_active=tonumber(pm_active)
    
    pm_active = pm_active~1
    TrackFX_SetNamedConfigParm( track, fxnumber, 'param.'..paramnumber..'.mod.active',pm_active )
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6,true) then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Toggle parameter modulation for last touched parameter', 0xFFFFFFFF )
  end 