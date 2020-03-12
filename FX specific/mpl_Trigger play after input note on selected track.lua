-- @description Trigger play after input note on selected track
-- @version 1.0
-- @author MPL
-- @changelog
--    + init


  function Run()
    test_val = gmem_read(1)
    if test_val > 0 then 
      gmem_write(1, 0) 
      Perform_Clear()
      Action(1007) -- play
     elseif test_val == 0 then 
      defer(Run)
    end
  end
  --------------------------------------------------------------------
  function Perform_Clear()
    if not last_tr then return end
    local fxid = TrackFX_AddByName( last_tr, 'WaitInput_tracker.jsfx', false, 0 )
    TrackFX_Delete( last_tr, fxid )
  end
--------------------------------------------------------------------
  function main()
    local tr = GetSelectedTrack(0,0)
    last_tr = tr
    if not tr then return end
    local ret = TrackFX_AddByName( tr, 'WaitInput_tracker.jsfx', false, 1 )
    if ret < 0 then MB('Missing WaitInput_tracker.jsfx\nPlease install it via ReaPack from MPL repository (Action List/Browse packages)', 'Error', 0) return end
    test_val0 = gmem_read(1)
    Run()
  end     
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then ret2 = VF_CheckReaperVrs(5.966,true)    end
  if ret2 then 
    gmem_attach('mpl_WaitInput') 
    gmem_write(1, 0)
    main() 
  end
