-- @description Set stereo as parent channels for selected tracks
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
 
  --NOT gfx NOT reaper
  --------------------------------------------------------------------
  function main()
    local cnttr = CountSelectedTracks(0)
    for tr_id = 1, cnttr do
      local track = GetSelectedTrack( 0,tr_id-1 )
      SetMediaTrackInfo_Value( track, 'C_MAINSEND_NCH', 2 )
      SetMediaTrackInfo_Value( track, 'C_MAINSEND_OFFS', 0 )
    end
  end

  -------------------------------------------------------------------- 
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.51) 
  if ret then 
    local ret2 = VF_CheckReaperVrs(6.72,true) 
    if ret2 then 
      Undo_BeginBlock2( 0 )
      main() 
      reaper.Undo_EndBlock2( 0, 'Set stereo as parent channels for selected tracks', 0xFFFFFFFF )
    end end