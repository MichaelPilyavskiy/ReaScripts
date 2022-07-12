-- @description Hide all selected tracks FX embedded UI in MCP
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  scr_name_undo_hist = 'Hide all selected tracks FX embedded UI in MCP' 
  
  
  -----------------------------------------------------
  function main()
    Undo_BeginBlock2( 0 )
    for seltrackidx = 1,  CountSelectedTracks( 0 ) do
      local tr = GetSelectedTrack( 0, seltrackidx-1 )
      local fx = -1 -- all fx
      local func = function(flag1,flag2) 
        local WAKflag1 = flag1
        local WAKflag2 = flag2
        if WAKflag2&2==2 then WAKflag2 = WAKflag2~2 end
        return WAKflag1, WAKflag2 
      end
      VF_TrackFX_SetEmbeddedState(tr, fx, func)
    end
    Undo_EndBlock2( 0, scr_name_undo_hist or '', 2 )
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.26) if ret then local ret2 = VF_CheckReaperVrs(6.25,true) if ret2 then  main() end end 
  
  
  