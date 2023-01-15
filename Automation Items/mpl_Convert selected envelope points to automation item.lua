-- @description Convert selected envelope points to automation item
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init 

  
  function main() 
    local env = GetSelectedEnvelope( 0 )
    if not env then return end
    if CountEnvelopePoints( env ) == 0 then return end
    local position, endpos = GetProjectLength( 0 ), 0
    for ptidx = 1, CountEnvelopePoints( env ) do
      local retval, time, value, shape, tension, selected = reaper.GetEnvelopePointEx( env, -1, ptidx-1 )
      if selected == true then 
        position = math.min(position, time)
        endpos = math.max(endpos, time)
      end
    end
    
    if endpos -  position > 0 then InsertAutomationItem( env, -1, position, endpos -  position) end
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.18) if ret then local ret2 = VF_CheckReaperVrs(6,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Convert selected envelope points to automation item', 0xFFFFFFFF )
  end end