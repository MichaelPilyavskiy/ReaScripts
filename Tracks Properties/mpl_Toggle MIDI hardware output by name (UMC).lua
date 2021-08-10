-- @description Toggle MIDI hardware output by name (UMC)
-- @version 1.0
-- @author MPL 
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--  + init


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
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing. Install it via Reapack (Action: browse packages)', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF2_LoadVFv2') 
  if ret then 
    local ret2 = VF_CheckReaperVrs(5.975,true)    
    if ret2 then 
      Undo_BeginBlock2( 0 )
      device_name = 'UMC'
      channel=0
      main(device_name,channel)
      UpdateArrange()
      Undo_EndBlock2( 0, 'Toggle MIDI hardware output by name (UMC)', -1 )
    end
  end
  