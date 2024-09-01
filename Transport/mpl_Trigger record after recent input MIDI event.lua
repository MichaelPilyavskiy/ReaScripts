-- @description Trigger record after recent input MIDI event
-- @version 2.02
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
    ---------------------------------------------------
  function Action(s, sectionID, ME )  
    if sectionID == 32060 and ME then 
      MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
     else
      Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
    end
  end 

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
  if VF_CheckReaperVrs(6.39,true) then 
    trig= 0 
    RIE0 = MIDI_GetRecentInputEvent(0)
    Run() 
  end