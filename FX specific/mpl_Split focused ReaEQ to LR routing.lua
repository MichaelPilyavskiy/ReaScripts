-- @description Split focused ReaEQ to LR routing
-- @version 2.01
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
  
  -----------------------------------------------------------------------------
  function MPL_SplitReaEq()
    local  retval, tracknumber, itemnumber, fx = GetFocusedFX()
    if not (retval ==1 and fx >= 0) then return end 
    local tr = CSurf_TrackFromID( tracknumber, false )
    
    
    local isReaEQ = TrackFX_GetEQParam( tr, fx, 0 )
    if not isReaEQ then return end
    
    TrackFX_CopyToTrack( tr, fx, tr, fx, false )
    local ret, fx_name = TrackFX_GetNamedConfigParm( tr, fx, 'fx_name')
    TrackFX_SetNamedConfigParm( tr, fx, 'renamed_name', fx_name..' L' )
    TrackFX_SetNamedConfigParm( tr, fx+1, 'renamed_name', fx_name..' R' )
    
    -- link params
    for pid = 1,  TrackFX_GetNumParams( tr, fx )-1 do
      TrackFX_SetNamedConfigParm( tr, fx+1, 'param.'..(pid-1)..'.plink.active', 1 )
      TrackFX_SetNamedConfigParm( tr, fx+1, 'param.'..(pid-1)..'.plink.effect',fx )
      TrackFX_SetNamedConfigParm( tr, fx+1, 'param.'..(pid-1)..'.plink.param',pid-1)
      
      TrackFX_SetNamedConfigParm( tr, fx+1, 'param.'..(pid-1)..'.lfo.active',0)
      local retval, paramname = TrackFX_GetParamName( tr, fx, pid-1 )
      if paramname:match('Gain') then  TrackFX_SetNamedConfigParm( tr, fx+1, 'param.'..(pid-1)..'.mod.baseline',0) end
    end
    

      
      
    -- set IO pins 
      -- fx 1 in
      TrackFX_SetPinMappings( tr, fx, 0, 0, 1, 0 )
      TrackFX_SetPinMappings( tr, fx, 0, 1, 0, 0 )
      -- fx 1 out
      TrackFX_SetPinMappings( tr, fx, 1, 0, 1, 0 )
      TrackFX_SetPinMappings( tr, fx, 1, 1, 0, 0 )
      -- fx 2 in
      TrackFX_SetPinMappings( tr, fx+1, 0, 0, 0, 0 )
      TrackFX_SetPinMappings( tr, fx+1, 0, 1, 2, 0 )
      -- fx 2 out
      TrackFX_SetPinMappings( tr, fx+1, 1, 0, 0, 0 )
      TrackFX_SetPinMappings( tr, fx+1, 1, 1, 2, 0 )     
      
  end
  ----------------------------------------------------------------------------- 
  if VF_CheckReaperVrs(6.79,true)  then 
    Undo_BeginBlock2( 0 )
    MPL_SplitReaEq()
    Undo_EndBlock2( 0, 'Split focused ReaEQ to LR routing', 0xFFFFFFFF )
  end 