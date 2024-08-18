-- @description AB floating FX parameters, make snapshots equal
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about
--    implementation of "equal" button in Cubase 7+ plugin window
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
    local retval, tracknumber, itemnumber, fxnum = reaper.GetFocusedFX2()
    if retval==0 then return end
    local tr = CSurf_TrackFromID( tracknumber, false )
    if not ValidatePtr2( 0, tr, 'MediaTrack*' ) then return end
    local it = GetTrackMediaItem( tr, itemnumber )
      
    local func_str = 'TrackFX_'
    if retval&1 == 1 then 
      ptr = tr
     elseif retval&2 == 2 then  
      local takeidx = (fxnum>>16)&0xFFFF
      ptr = GetTake( it, takeidx )
      func_str = 'TakeFX_'
     elseif retval == 4 then  
      return 
    end
  
    -- get current config  
    local config_t = {}
    local fx_guid = _G[func_str..'GetFXGUID'](ptr, fxnum&0xFFFF)  
    if not fx_guid then return end
    local count_params = _G[func_str..'GetNumParams'](ptr, fxnum&0xFFFF)
    if count_params ~= nil then        
      for i = 1, count_params do
        local value = _G[func_str..'GetParam'](ptr, fxnum&0xFFFF, i-1) 
        table.insert(config_t, i, tostring(value))
      end  
    end              
    config_t_s = table.concat(config_t,"_")

            
    -- store current config
    reaper.SetProjExtState(0, "mpl_CubaseFloatAB", fx_guid, config_t_s)
    
  end 
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true) then main()  end