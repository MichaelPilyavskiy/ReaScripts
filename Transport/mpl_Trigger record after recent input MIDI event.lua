-- @description Trigger record after recent input MIDI event
-- @version 2.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # stuff into stream chord notes (performed 1 second just before the recent MIDI event come)


  function Run()
    RIE,midimsg0,tsval0, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(0) 
    if RIE0 ~= RIE then  
      Action(1013) -- record  
      StuffMIDIMessage( 2, midimsg0:byte(1),midimsg0:byte(2),midimsg0:byte(3) )
      chord_evts = {}
      for i = 1, 12 do
        local RIE,midimsg,tsval, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(i) 
        if math.abs(tsval - tsval0 ) > 44100 then break end
        chord_evts[#chord_evts+1] = {tsval1=tsval,midimsg=midimsg}
      end 
      
      for i = 1 , #chord_evts do
        local midimsg = chord_evts[i].midimsg 
        StuffMIDIMessage( 2, midimsg:byte(1),midimsg:byte(2),midimsg:byte(3) )
      end
      
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