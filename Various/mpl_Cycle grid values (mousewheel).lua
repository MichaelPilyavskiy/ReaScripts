-- @description Cycle grid values (mousewheel)
-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @website http://forum.cockos.com/showthread.php?t=188335
 
  
  local stages = {0, 1, 1/2, 1/4, 1/8, 1/16, 1/32, 1/64, 1/128, 1/3, 1/6, 1/12, 1/24, 1/48} 
            
------------------------------------------------------------------   
  function msg(s) reaper.ShowConsoleMsg(s..'\n') end
  
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end  else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0)  if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end    end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.5) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then  reaper.defer(function() VF2_CycleGrid(stages) end)  end end