-- @description Add time signature
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--    [main] . > mpl_Add 1 to 4 time signature.lua
--    [main] . > mpl_Add 2 to 4 time signature.lua
--    [main] . > mpl_Add 3 to 4 time signature.lua
--    [main] . > mpl_Add 4 to 4 time signature.lua
--    [main] . > mpl_Add 5 to 4 time signature.lua
--    [main] . > mpl_Add 6 to 4 time signature.lua
--    [main] . > mpl_Add 7 to 4 time signature.lua
--    [main] . > mpl_Add 3 to 8 time signature.lua
--    [main] . > mpl_Add 5 to 8 time signature.lua
--    [main] . > mpl_Add 6 to 8 time signature.lua
--    [main] . > mpl_Add 7 to 8 time signature.lua
--    [main] . > mpl_Add 9 to 8 time signature.lua
--    [main] . > mpl_Add 10 to 8 time signature.lua
--    [main] . > mpl_Add 11 to 8 time signature.lua
--    [main] . > mpl_Add 12 to 8 time signature.lua
--    [main] . > mpl_Add 13 to 8 time signature.lua
--    [main] . > mpl_Add 14 to 8 time signature.lua
--    [main] . > mpl_Add 15 to 8 time signature.lua
--    [main] . > mpl_Add 3 to 16 time signature.lua
--    [main] . > mpl_Add 5 to 16 time signature.lua
--    [main] . > mpl_Add 7 to 16 time signature.lua
--    [main] . > mpl_Add 9 to 16 time signature.lua
--    [main] . > mpl_Add 10 to 16 time signature.lua
--    [main] . > mpl_Add 11 to 16 time signature.lua
--    [main] . > mpl_Add 12 to 16 time signature.lua
--    [main] . > mpl_Add 13 to 16 time signature.lua
--    [main] . > mpl_Add 14 to 16 time signature.lua
--    [main] . > mpl_Add 15 to 16 time signature.lua
-- @changelog
--    + init
 
  --NOT gfx NOT reaper
  function main(num, denom)
    if not (num and denom) then return end
    num= tonumber(num)
    denom= tonumber(denom)
    if not (num and denom) then return end 
    local curpos = GetCursorPositionEx(0 )
    SetTempoTimeSigMarker( 0, -1, curpos, -1, -1, -1, num, denom, false )
    UpdateTimeline()
  end  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
-------------------------------------------------------------------- 
  local scr_name = ({reaper.get_action_context()})[2]
  local num, denom = scr_name:match('Add (%d+) to (%d+) time signature')
  local ret = CheckFunctions('VF_CheckReaperVrs') 
  if ret then 
    if VF_CheckReaperVrs(5.95) then main(num, denom) end
  end