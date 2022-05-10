-- @author MPL
-- @description Offline bypassed fx on selected tracks
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @version 1.01
-- @changelog
--   # do not bypass FX with bypass envelope (req Reaper 6.37+)

  
  --------------------------------------------------------------------
  function main()
    Undo_BeginBlock()
    for i =1, CountSelectedTracks(0) do 
      local tr = GetSelectedTrack(0,i-1)
      for fx = TrackFX_GetCount( tr ), 1, -1 do
        local is_byp = TrackFX_GetEnabled( tr, fx-1 )
        if not is_byp then 
          local byp_param =  TrackFX_GetParamFromIdent( tr, fx-1, ':bypass' )
          local byp_envelope = reaper.GetFXEnvelope( tr, fx-1, byp_param, false )
          if not byp_envelope then 
            TrackFX_SetOffline( tr, fx-1, 1 ) 
          end
        end
      end
    end
    Undo_EndBlock('Offline bypassed fx on selected tracks', 0)
  end 
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.08) if ret then local ret2 = VF_CheckReaperVrs(6.37,true) if ret2 then main() end end
  