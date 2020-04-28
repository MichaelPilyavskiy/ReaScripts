-- @description Set selected items pitch shift mode to elastique 2.2.8 pro
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

------------------------------------------------------------------------------
  function main()
    for i = 1, CountSelectedMediaItems(0) do
      local item = reaper.GetSelectedMediaItem(0,i-1)
      pshift_mode =  6<<16
      --timestr_mode = 4 -- transient optimized (val = 4 )
      --stretchfadesz = 0.0025
      VF_SetTimeShiftPitchChange(item, false, pshift_mode, timestr_mode, stretchfadesz)
    end
    reaper.UpdateArrange()
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
    local ret, ret2 = CheckFunctions('VF_SetTimeShiftPitchChange') 
    if ret then ret2 = VF_CheckReaperVrs(5.95,true) end   
    if ret and ret2 then 
      reaper.Undo_BeginBlock()
      main()
      reaper.Undo_EndBlock('Set selected items timestretch/pitchshift mode', -1)
    end  