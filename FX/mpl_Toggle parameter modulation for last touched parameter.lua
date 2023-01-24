-- @description Toggle parameter modulation for last touched parameter
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--  + init 

  -- [[debug search filter: NOT function NOT reaper NOT gfx NOT VF]]
  
  function main() 
    local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
    if retval ==false then return end
    local track = CSurf_TrackFromID( tracknumber, false )
    if not track then return end
    local ret, pm_active = TrackFX_GetNamedConfigParm( track, fxnumber, 'param.'..paramnumber..'.mod.active' )
    if not ret then return end 
    pm_active=tonumber(pm_active)
    
    pm_active = pm_active~1
    TrackFX_SetNamedConfigParm( track, fxnumber, 'param.'..paramnumber..'.mod.active',pm_active )
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.18) if ret then local ret2 = VF_CheckReaperVrs(6,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Toggle parameter modulation for lat touched parameter', 0xFFFFFFFF )
  end end