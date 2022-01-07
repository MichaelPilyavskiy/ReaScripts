-- @description Dump Retrospective Record log
-- @version 2.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Dump recent MIDI messages log. 
-- @metapackage
-- @provides
--    [main] . > mpl_Dump Retrospective Record log.lua
--    [main] . > mpl_Dump Retrospective Record log (notes only).lua
--    [main] . > mpl_Dump Retrospective Record log (only data at playing).lua
--    [main] . > mpl_Dump Retrospective Record log (only data at stop).lua
--    [main] . > mpl_Dump Retrospective Record log (everything recorded from last REAPER start).lua
--    [main] . > mpl_Dump Retrospective Record log (everything from last 5 minutes).lua
--    [main] . > mpl_Dump Retrospective Record log (everything from last 10 minutes).lua
--    [main] . > mpl_Dump Retrospective Record log (everything from last 30 minutes).lua
--    [main] . > mpl_Dump Retrospective Record log (everything from last hour, obey stored data break).lua
--    [main] . > mpl_Dump Retrospective Record log (clean buffer only).lua
-- @changelog 
--    + add mpl_Dump Retrospective Record log (clean buffer only)
                    
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end  else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0)  if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end    end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.67) if ret then local ret2 = VF_CheckReaperVrs(6.39,true) if ret2 then 
    local filename = ({reaper.get_action_context()})[2]
    local script_title = GetShortSmplName(filename):gsub('%.lua','')
    local settings = VF2_MPL_DumpRetrospectiveLog_Parsing_filename(script_title)
    if settings then 
      Undo_BeginBlock2( 0 )
      VF2_MPL_DumpRetrospectiveLog(settings) 
      Undo_EndBlock2( 0, 'MPL_DumpRetrospectiveLog', 0)
    end
  end end
