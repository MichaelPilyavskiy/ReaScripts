-- @description Random modulated parameters LFO phase on selected tracks 
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init 

  script_title_out = 'Random modulated parameters LFO phase on selected tracks'
  
  function main()
    for i = 1, CountSelectedTracks()do
      local tr =GetSelectedTrack(0,i-1)
      for fxnumber = 1,  TrackFX_GetCount( tr ) do
        for paramnumber = 1,  TrackFX_GetNumParams( tr, fxnumber-1 ) do
          local ret = TrackFX_GetNamedConfigParm( tr, fxnumber-1, 'param.'..(paramnumber-1)..'.lfo.active' ) 
          if ret then TrackFX_SetNamedConfigParm( tr, fxnumber-1,  'param.'..(paramnumber-1)..'.lfo.phase',math.random() ) end  
        end
      end
    end
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.50) if ret then local ret2 = VF_CheckReaperVrs(6.37,true) if ret2 then  
    Undo_BeginBlock2( 0 )
    main()
    Undo_EndBlock2( 0, script_title_out, 0xFFFFFFFF )
  end end