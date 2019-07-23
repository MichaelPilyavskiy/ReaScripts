-- @description Float instrument on track under mouse cursor
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix checking Various_functions (2)

  -- NOT gfx NOT reaper
  local scr_title = 'Float instrument on track under mouse cursor'
  function main()
    BR_GetMouseCursorContext()
    local tr = BR_GetMouseCursorContext_Track()
    if tr then 
      FloatInstrument(tr)
      ApplyFunctionToTrackInTree(tr, FloatInstrument)
    end
  end  

---------------------------------------------------------------------
  function CheckFunctions(str_func)
    SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
    local f = io.open(SEfunc_path, 'r')
    if f then
      f:close()
      dofile(SEfunc_path)
      
      if not _G[str_func] then 
        reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
       else
        Undo_BeginBlock()
        main()
        Undo_EndBlock( scr_title, -1 )
      end
      
     else
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end  
  end
--------------------------------------------------------------------
  CheckFunctions('FloatInstrument')    
