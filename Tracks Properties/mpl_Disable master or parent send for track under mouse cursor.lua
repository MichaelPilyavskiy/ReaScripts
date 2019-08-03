-- @description Disable master or parent send for track under mouse cursor
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # update for use with REAPER 5.981+

  function main()
    tr =  VF_GetTrackUnderMouseCursor()
    if tr then 
      reaper.Undo_BeginBlock()
      reaper.SetMediaTrackInfo_Value( tr, 'B_MAINSEND', 0 ) 
      reaper.Undo_EndBlock( 'Disable master or parent send for track under mouse cursor', -1 )
    end
  end

---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end

--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_GetItemTakeUnderMouseCursor') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then 
    script_title = "Disable master or parent send for track under mouse cursor"
    reaper.Undo_BeginBlock()
    main()
    reaper.Undo_EndBlock(script_title, 0)
  end  
