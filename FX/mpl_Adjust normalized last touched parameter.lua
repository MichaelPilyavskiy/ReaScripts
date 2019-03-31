-- @description Adjust normalized last touched parameter
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--    [main] . > mpl_Add 0.01 to normalized last touched parameter.lua
--    [main] . > mpl_Add 0.001 to normalized last touched parameter.lua
--    [main] . > mpl_Add 0.0001 to normalized last touched parameter.lua
--    [main] . > mpl_Subtract 0.01 from normalized last touched parameter.lua
--    [main] . > mpl_Subtract 0.001 from normalized last touched parameter.lua
--    [main] . > mpl_Subtract 0.0001 from normalized last touched parameter.lua
-- @changelog
--    + init
 
  --NOT gfx NOT reaper
  function main(val, dir)
    local dir_str if dir == 1 then dir_str = 'Add X to' else dir_str = 'Subtract X from' end
    local scr_title = dir_str:gsub('X', val).." last touched FX parameter"
     retval, trackid, fxid, paramid = GetLastTouchedFX()
    if retval then
      local track = GetTrack(0, trackid-1)
      if trackid == 0 then track = GetMasterTrack( 0 ) end
      if track then
        Undo_BeginBlock()
        local value0 = TrackFX_GetParamNormalized(track, fxid, paramid)
        local newval = math.max(0,math.min(value0 + val*dir,math.huge))
        TrackFX_SetParamNormalized(track, fxid, paramid, newval) 
        Undo_EndBlock(scr_title, 1)
      end  
    end
  end  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
-------------------------------------------------------------------- 
   val = ({reaper.get_action_context()})[2]:match('([%d%p]+)')
  if not (val and tonumber(val)) then val = 0.01 else val = tonumber(val) end
   dir = ({reaper.get_action_context()})[2]:match('Add')
  if dir then dir = 1 else dir = -1 end
  
  local ret = CheckFunctions('VF_CheckReaperVrs') 
  local ret2 = VF_CheckReaperVrs(5.95)    
  if ret and ret2 then main(val, dir) end