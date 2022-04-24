-- @description Invert selected tracks solo to mute states
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @changelog
--    +init
  
  function main()
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      local mst = GetMediaTrackInfo_Value( tr, 'B_MUTE' )  
      local sst = GetMediaTrackInfo_Value( tr, 'I_SOLO' )  
      if mst == 1 and sst == 0 then 
        SetMediaTrackInfo_Value( tr, 'B_MUTE', 0 )
        SetMediaTrackInfo_Value( tr, 'I_SOLO', 1 )
       elseif mst == 0 and sst == 1 then 
        SetMediaTrackInfo_Value( tr, 'B_MUTE', 1 )
        SetMediaTrackInfo_Value( tr, 'I_SOLO', 0 )        
      end
    end
    TrackList_AdjustWindows( false )
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.08) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end