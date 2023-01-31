-- @description Remove OSC learn from focused FX
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init 

  script_title_out = 'Remove OSC learn from focused FX'
  
  function main()
    local retval, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX2()
    if retval&1~=1 then return end
    local tr  if tracknumber==0 then tr = GetMasterTrack(0) else tr = GetTrack(0,tracknumber-1)end
    if not tr then return end
    
    for p = 1,  TrackFX_GetNumParams( tr, fxnumber ) do
      --TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..(p-1)..'.learn.midi1','' )
      --TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..(p-1)..'.learn.midi2','' )
      TrackFX_SetNamedConfigParm( tr, fxnumber,  'param.'..(p-1)..'.learn.osc','' )
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