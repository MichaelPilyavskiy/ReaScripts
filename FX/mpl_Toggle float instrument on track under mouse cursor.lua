-- @description Toggle float instrument on track under mouse cursor
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # check if plugin is instrument by checking pre-aliased name
--    + allow to add plugin name into exception list
  
  
local exceptions_list =
{
"Transpose", 
"m trans", 
"m pc", 
"m chan" 
}
  
  -- NOT gfx NOT reaper
  local scr_title = 'Toggle float instrument on track under mouse cursor'
  function main()
    local tr = VF_GetTrackUnderMouseCursor()
    if tr then 
      FloatInstrument2(tr,true)
      ApplyFunctionToTrackInTree(tr, FloatInstrument2)
    end
  end  
  -------------------------------------------------------------------------------     
  function FloatInstrument2(track, toggle)
    -- find instrument
    for fx = 1,  TrackFX_GetCount( track ) do
      local retval, fxname = reaper.TrackFX_GetNamedConfigParm( track, fx-1, 'fx_name' )
      if fxname:match('.-i%:.*') then
        local ignore
        for i = 1, #exceptions_list do if fxname:lower():match(exceptions_list[i]:lower()) then ignore = true break end end -- check exceptions list
        if not ignore then 
          vsti_id = fx-1 
          break
        end
      end
    end
    
    --local vsti_id = TrackFX_GetInstrument(track)
    if vsti_id and vsti_id >= 0 then 
      if not toggle then 
        TrackFX_Show(track, vsti_id, 3) -- float
       else
        local is_float = TrackFX_GetOpen(track, vsti_id)
        if is_float == false then TrackFX_Show(track, vsti_id, 3) else TrackFX_Show(track, vsti_id, 2) end
      end
      
      return true
    end
  end
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end

--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_GetItemTakeUnderMouseCursor') 
  local ret2 = VF_CheckReaperVrs(6.37,true)    
  if ret and ret2 then 
    script_title = "Toggle float instrument on track under mouse cursor"
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock(script_title, -1)
  end 