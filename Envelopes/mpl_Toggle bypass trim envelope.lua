-- @description Toggle bypass trim envelope
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Init

 
  -- NOT gfx NOT reaper NOT VF NOT GUI NOT DATA NOT MAIN 
  
  ----------------------------------------------------------------------
  function main()
    for i = 1, CountSelectedTracks(0)do
      local tr = GetSelectedTrack(0,i-1)
      -- initialize Trim Volume / set unarmed
      local env = GetTrackEnvelopeByName( tr, 'Trim Volume' )
      if env then
        local retval, envchunk = GetEnvelopeStateChunk( env, '', true )
        local arm = envchunk:match('ACT (%d)')
        if arm and tonumber(arm) then
          local retval, envchunk = GetEnvelopeStateChunk( env, '', false )
          arm= tonumber(arm)~1
          SetEnvelopeStateChunk( env, envchunk:gsub('ACT (%d)','ACT '..arm),false )
        end
      end
    end
  end

  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.42) if ret then local ret2 = VF_CheckReaperVrs(6.68,true) if ret2 then main() end end

