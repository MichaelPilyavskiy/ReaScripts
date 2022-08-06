-- @description Remove ReaEQ from selected tracks
-- @version 1.0
-- @author MPL
-- @changelog
--  init 

  function main()
  
    local fxname = 'ReaEQ'
    
    for i =1, CountSelectedTracks(0) do 
      local track = GetSelectedTrack(0,i-1)
      for fx = TrackFX_GetCount( track ), 1, -1 do
        local retval, buf = TrackFX_GetFXName( track, fx-1 )
        match  = buf:lower():match(fxname:lower())~=nil
        if match then TrackFX_Delete(track, fx-1) end
      end
    end
  end    
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.30) if ret then local ret2 = VF_CheckReaperVrs(5.95,true) if ret2 then
      Undo_BeginBlock2( 0 )
      main() 
      Undo_EndBlock2( 0, 'Remove ReaEQ from selected tracks', 2 )
  end end   
