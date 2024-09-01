-- @description Set hardware MIDI output to GM
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

device_name = 'GM'
channel = 0



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
  for i =1,  reaper.GetNumMIDIOutputs() do
    local retval, name = reaper.GetMIDIOutputName( i-1, '' )
    if name:match(device_name) then dev_id = i-1 end
  end
  if not dev_id then return end
  for i = 1, reaper.CountSelectedTracks( 0 ) do
    local tr =  reaper.GetSelectedTrack( 0, i-1 )
    reaper.SetMediaTrackInfo_Value( tr, 'I_MIDIHWOUT', channel + (dev_id<<5) )
  end
end


  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true)  then 
        Undo_BeginBlock()
        main() 
        Undo_EndBlock('Set hardware MIDI output to GM',-1)
  end  