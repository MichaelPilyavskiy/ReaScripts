-- @description Swap master channels (cycle width 100...-100)
-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @website http://forum.cockos.com/showthread.php?t=188335
 
   
------------------------------------------------------------------   
  function main() 
    local tr =  GetMasterTrack( 0 )
    SetMediaTrackInfo_Value( tr, 'I_PANMODE', 5  )
    local D_WIDTH = GetMediaTrackInfo_Value( tr, 'D_WIDTH'  )
    if D_WIDTH > 0 then SetMediaTrackInfo_Value( tr, 'D_WIDTH', -1) else SetMediaTrackInfo_Value( tr, 'D_WIDTH', 1) end
  end
  
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end  else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0)  if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end    end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.5) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then  main() end end
  
  