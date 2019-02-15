-- @description Prepare selected track for RetrospectiveRecord tracker
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Add RetrospectiveRecord tracker, enable record arm, disable record, enable monitoring, set Input to All MIDI all channels.
-- @changelog
--    # enable monitoring
--    + disable parent send


  --NOT gfx NOT reaper
------------------------------------------------------------
  function main(data)
    local tr = GetSelectedTrack(0,0)
    if not tr then return end
    local ret = TrackFX_AddByName( tr, 'RetrospectiveRecord_tracker.jsfx', false, 1 )
    if ret < 0 then MB('Missing RetrospectiveRecord_tracker.jsfx\nPlease install it via ReaPack from MPL repository (Action List/Browse packages)', 'Error', 0) return end
    SetMediaTrackInfo_Value( tr, 'I_RECARM', 1 )
    SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+ (63<<5)) 
    SetMediaTrackInfo_Value( tr, 'I_RECMODE', 2)
    SetMediaTrackInfo_Value( tr, 'I_RECMON', 1) 
    SetMediaTrackInfo_Value( tr, 'B_MAINSEND', 0)  
      
  end
  
 
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.966,true)    
  if ret and ret2 then 
    main()
  end
