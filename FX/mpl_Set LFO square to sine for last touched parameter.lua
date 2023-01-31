-- @description Set LFO square to sine for last touched parameter
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
  
  ----------------------------------------------------------------
  function main()
     local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
     if not retval then return end
     
     local trid = tracknumber&0xFFFF
     local itid = (tracknumber>>16)&0xFFFF
     if itid > 0 then return end -- ignore item FX
     local tr
     if trid==0 then tr = GetMasterTrack(0) else tr = GetTrack(0,trid-1) end
     if not tr then return end
     TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.lfo.shape', 1)
     --param.X.lfo.[active,dir,phase,speed,strength,temposync,free,shape] : parameter moduation LFO state
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.50) if ret then local ret2 = VF_CheckReaperVrs(6.37,true) if ret2 then  
    Undo_BeginBlock2( 0 )
    main()
    Undo_EndBlock2( 0, 'Set LFO shape to square for last touched parameter', 0xFFFFFFFF )
  end end
  