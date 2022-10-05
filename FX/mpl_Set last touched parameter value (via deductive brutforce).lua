-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Set last touched parameter value (via deductive brutforce)
-- @changelog
--    # use more straigh approach

  
  -------------------------------------------------------
  function main() local ReaperVal
    local retval, tracknum, fx, param = GetLastTouchedFX()
    if not retval then return end
    local tr = CSurf_TrackFromID( tracknum, false )    
    local retval, find = reaper.GetUserInputs( '', 1, 'value', ({TrackFX_GetFormattedParamValue( tr , fx, param, '' )})[2] )
    if not retval then return end
    ReaperVal =  VF_BFpluginparam(find, tr, fx, param)   
    if ReaperVal then TrackFX_SetParamNormalized( tr, fx, param, ReaperVal ) end
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.42) if ret then local ret2 = VF_CheckReaperVrs(6.68,true) if ret2 then main() end end
  