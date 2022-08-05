-- @description Set selected tracks audio input device to Guit
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672

  device_name = 'Guit'
  is_stereo = false

  function main()
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      SetAudioInput( tr, is_stereo, device_name )
    end
  end
  ---------------------------------------------------------------------
  function SetAudioInput(tr, is_stereo, dev_name)
    if is_stereo==true then is_stereo = 1024 else is_stereo = 0 end
    --local tr = reaper.GetSelectedTrack(0,0)
    if not tr then return end
    for i = 1,  reaper.GetNumAudioInputs() do
      nameout =  reaper.GetInputChannelName( i-1 )
      if nameout:lower():match(dev_name:lower()) then dev_id = i-1 end
    end
    if not dev_id then return end
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT',is_stereo + dev_id)
  end
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then 
    Undo_BeginBlock()
    main()
    Undo_EndBlock("Set selected tracks audio input device", 0)  
  end