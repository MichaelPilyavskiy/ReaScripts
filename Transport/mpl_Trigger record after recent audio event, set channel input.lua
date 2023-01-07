-- @description Trigger record after recent audio event, set channel input
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  threshold_dB = -60
  function Run() 
    if not channels then channels = GetNumAudioInputs() end
    local tr = GetSelectedTrack(0,0)
    if tr then 
      for input_id = 1, channels do
        local activity_dB = GetInputActivityLevel(input_id-1)
        if activity_dB> threshold_dB then
          local activity_dB2 = GetInputActivityLevel(input_id)
          SetMediaTrackInfo_Value( tr, 'I_RECARM', 1 )
          SetMediaTrackInfo_Value( tr, 'I_RECINPUT', input_id-1 )
          if activity_dB2 and activity_dB2> threshold_dB then SetMediaTrackInfo_Value( tr, 'I_RECINPUT', (input_id-1)|1024 ) end -- stereo if following channel also above threshold
          CSurf_OnRecord()
          return 
        end
      end
    end 
    defer(Run)
  end
   
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.0) if ret then local ret2 = VF_CheckReaperVrs(6.73,true) if ret2 then 
    if APIExists('GetInputActivityLevel') then Run() end
  end end