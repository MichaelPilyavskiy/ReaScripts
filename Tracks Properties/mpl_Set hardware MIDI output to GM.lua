-- @description Set hardware MIDI output to GM
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

device_name = 'GM'
channel = 0

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
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
    local ret = CheckFunctions('VF_CalibrateFont')  
    if ret  then 
      local ret2 = VF_CheckReaperVrs(5.95,true) 
      if ret2 then 
        Undo_BeginBlock()
        main() 
        Undo_EndBlock('Set hardware MIDI output to GM',-1)
      end
    end  