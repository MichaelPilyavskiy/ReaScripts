-- @description Set selected tracks MIDI input device to TouchOSC bridge
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
  
  channel = 0-- 0 all channels
  device_name = 'touchosc'
  
  
  function main()
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      SetMidiInput( tr, channel, device_name ) 
    end
  end
---------------------------------------------------------------------  
  function SetMidiInput(tr, chan, dev_name)
    if not tr then return end
    for i = 0, 64 do
      local retval, nameout = GetMIDIInputName( i, '' )
      if nameout:lower():match(dev_name:lower()) then dev_id = i end
    end
    if not dev_id then return end
    val = 4096+ chan + ( dev_id << 5  )
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT',val)
  end 
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end

--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then 
    Undo_BeginBlock()
    main()
    Undo_EndBlock("Set selected tracks MIDI input device", 0)  
  end