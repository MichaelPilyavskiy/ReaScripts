-- @description Toggle MIDI hardware output by name (UMC)
-- @version 1.01
-- @author MPL 
-- @website http://forum.cockos.com/showthread.php?t=188335
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


function main(device_name,channel)
  -- get id
    for i =1,  reaper.GetNumMIDIOutputs() do
      local retval, name = reaper.GetMIDIOutputName( i-1, '' )
      if name:match(device_name) then dev_id = i-1 end
    end
    if not dev_id then return end
    
  -- get first track state
    local tr =  reaper.GetSelectedTrack( 0,0 )
    if not tr then return end
     val = reaper.GetMediaTrackInfo_Value( tr, 'I_MIDIHWOUT')
  
  -- loop sel tracks
    for i = 1, reaper.CountSelectedTracks( 0 ) do
      local tr =  reaper.GetSelectedTrack( 0, i-1 )
      if val >= 0 then 
        reaper.SetMediaTrackInfo_Value( tr, 'I_MIDIHWOUT',-1 )
       else 
        reaper.SetMediaTrackInfo_Value( tr, 'I_MIDIHWOUT', channel + (dev_id<<5))
      end
    end
end


  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true)   then 
      Undo_BeginBlock2( 0 )
      device_name = 'UMC'
      channel=0
      main(device_name,channel)
      UpdateArrange()
      Undo_EndBlock2( 0, 'Toggle MIDI hardware output by name (UMC)', -1 )
  end
  