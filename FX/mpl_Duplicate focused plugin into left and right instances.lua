-- @description Duplicate focused plugin into left and right instances
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent
--    # use API instead chunking

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
  function VF_ReduceFXname(s)
    local s_out = s:match('[%:%/%s]+(.*)')
    if not s_out then return s end
    s_out = s_out:gsub('%(.-%)','') 
    --if s_out:match('%/(.*)') then s_out = s_out:match('%/(.*)') end
    local pat_js = '.*[%/](.*)'
    if s_out:match(pat_js) then s_out = s_out:match(pat_js) end  
    if not s_out then return s else 
      if s_out ~= '' then return s_out else return s end
    end
  end
    ---------------------------------------------------
  function main()
    
    local retval, tracknumber, _, fx = GetFocusedFX()
    if retval ~= 1 then return end
    local tr if tracknumber == 0 then tr = GetMasterTrack(0) else tr = GetTrack(0, tracknumber-1) end
    
    -- duplicate vst
      local retval1, fxname = reaper.TrackFX_GetFXName( tr, fx, '' )
      local retval, renamed_name = reaper.TrackFX_GetNamedConfigParm( tr, fx, 'renamed_name' )
      if renamed_name~= '' then fxname = renamed_name end
      if fxname:match('%- Left') or fxname:match('%- Right') then return end
      
        TrackFX_CopyToTrack( tr, fx, tr, fx, false )
            
      reaper.TrackFX_SetNamedConfigParm( tr, fx, 'renamed_name', fxname..' - Left' )
      reaper.TrackFX_SetNamedConfigParm( tr, fx+1, 'renamed_name', fxname..' - Right' )
      
    -- set IO
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
        
    -- link params
      local num_params = TrackFX_GetNumParams( tr, fx )
      for param_id = 0,  num_params-3 do
        reaper.TrackFX_SetNamedConfigParm( tr, fx+1, 'param.'..param_id..'.mod.active', 1)
        reaper.TrackFX_SetNamedConfigParm( tr, fx+1, 'param.'..param_id..'.plink.active', 1)
        reaper.TrackFX_SetNamedConfigParm( tr, fx+1, 'param.'..param_id..'.plink.effect', fx)
        reaper.TrackFX_SetNamedConfigParm( tr, fx+1, 'param.'..param_id..'.plink.param', param_id)
      end
  end
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(6.71,true)  then 
    reaper.Undo_BeginBlock()
    main()
    reaper.Undo_EndBlock('Duplicate focused plugin into left and right instances', -1)
  end  