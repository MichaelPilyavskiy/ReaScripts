-- @description Spectral editing tools - perform
-- @version 1.0
-- @author MPL
-- @about Trigger SETools action while main script GUI is opened
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.13) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then reaper.gmem_attach('MPL_SPEDIT_TOOLS' ) gmem_write(1,1 ) end end