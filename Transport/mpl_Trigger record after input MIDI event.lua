-- @description Trigger record after input MIDI event
-- @version 2.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Remove JSFX tracker dependency, use native retrospective log instead (REAPER 6.39+)


  function Run()
    RIE,midimsg = MIDI_GetRecentInputEvent(0) 
    if RIE0 ~= RIE then  
      Action(1013) -- record 
      StuffMIDIMessage( 2, midimsg:byte(1),midimsg:byte(2),midimsg:byte(3) )
     else
      defer(Run)
    end
  end
   
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.0) if ret then local ret2 = VF_CheckReaperVrs(6.39,true) if ret2 then 
    trig= 0 
    RIE0 = MIDI_GetRecentInputEvent(0)
    Run() 
  end end