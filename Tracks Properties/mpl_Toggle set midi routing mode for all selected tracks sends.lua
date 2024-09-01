-- @description Toggle set midi routing mode for all selected tracks sends
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent



mode = 0
-- mode = 0 toggle
-- mode = 1 turn on
-- mode = 2 turn off


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
 

 function main()
    for i = 1, reaper.CountSelectedTracks(0) do SetMIDIFlags(reaper.GetSelectedTrack(0,i-1)) end
  end
---------------------------------------------------------------------  
  function SetMIDIFlags(tr)
    for i = 1, reaper.GetTrackNumSends( tr, 0 ) do
      if i == 1 then def_flag = GetTrackSendInfo_Value( tr, 0, i-1, 'I_MIDIFLAGS' )&1024 end
      if def_flag == 0 then
        val = GetTrackSendInfo_Value( tr, 0, i-1, 'I_MIDIFLAGS' ) 
        if val&1024 == 0 then SetTrackSendInfo_Value( tr, 0, i-1, 'I_MIDIFLAGS', val + 1024) end
       else
        val = GetTrackSendInfo_Value( tr, 0, i-1, 'I_MIDIFLAGS' ) 
        if val&1024 == 1024 then SetTrackSendInfo_Value( tr, 0, i-1, 'I_MIDIFLAGS', val - 1024)     end  
      end
    end
    return 
  end
  
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.0)then main() end