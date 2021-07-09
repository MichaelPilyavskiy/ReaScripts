-- @description Shift regions and markers to edit cursor
-- @version 1.0
-- @author MPL
-- @about Shift all project regions and markers. Edit cursor is going to be a start of the first region. All others shifted respectively.
-- @changelog
--  init 
    
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing. Install it via Reapack (Action: browse packages)', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF2_ShiftRegions') 
  if ret then 
    local ret2 = VF_CheckReaperVrs(5.975,true)    
    if ret2 then 
      Undo_BeginBlock2( 0 )
      local  retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, 0 )
      local curpos = reaper.GetCursorPositionEx( 0 ) 
      local offset = curpos - pos
      VF2_ShiftRegions(offset) 
      Undo_EndBlock2( 0, 'Shift first region to edit cursor, others follow', -1 )
    end
  end