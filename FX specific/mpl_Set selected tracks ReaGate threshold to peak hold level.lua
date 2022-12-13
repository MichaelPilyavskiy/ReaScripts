-- @description Set selected tracks ReaGate threshold to peak hold level
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
 
 
  function MPL_SetReaGateThreshold(tr,reagate)
    local state = TrackFX_GetEnabled( tr, reagate )
    if not state then return end
    local peakh = reaper.Track_GetPeakHoldDB( tr, reagate, false )/0.01
    if peakh <= -149 then return end
    TrackFX_SetParamNormalized( tr, reagate, 0, WDL_DB2VAL(peakh) )
  end
  -------------------------------------------------------------------- 
  function main()
    for i= 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      if tr then 
        local reagate = TrackFX_AddByName( tr, 'reagate', false, 0 )
        if reagate ~= -1 then
          MPL_SetReaGateThreshold(tr,reagate)
          goto nexttrack
        end
      end
      ::nexttrack::
    end
  end
  -------------------------------------------------------------------- 
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.51) 
  if ret then local ret2 = VF_CheckReaperVrs(5.99,true) if ret2 then main() end end