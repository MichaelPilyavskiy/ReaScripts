-- @description Move sample selection for focused RS5k (MIDI, OSC, Mousewheel)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
-- @changelog
--    #header


  
function main()
    local _,_,_,_,mode,res,val = reaper.get_action_context()
    local ret, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    local track = reaper.CSurf_TrackFromID( tracknumberOut, false )
    if not track then return end
    local c = 0
    if val < 0 then c = -1 else c = 1 end
    local step = 0.01
    local param = 13
    local p0 = reaper.TrackFX_GetParamNormalized( track, fxnumberOut, param )
    local p1 = reaper.TrackFX_GetParamNormalized( track, fxnumberOut, param+1 )
    reaper.TrackFX_SetParamNormalized( track, fxnumberOut, param, p0 +  step*c)
    reaper.TrackFX_SetParamNormalized( track, fxnumberOut, param+1, p1 +  step*c)
  end
  
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.07) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end