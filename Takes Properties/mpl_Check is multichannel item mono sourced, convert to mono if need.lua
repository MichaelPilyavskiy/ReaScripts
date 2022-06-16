-- @description Check is multichannel item mono sourced, convert to mono if need 
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  function main()
    for i = 1, CountSelectedMediaItems(0) do
      local item =  reaper.GetSelectedMediaItem( 0, i-1)
      local take = GetActiveTake(item)
      if take then 
        local ismono = MonoCheck(item, take)
        if ismono then SetMediaItemTakeInfo_Value( take, 'I_CHANMODE' , 3) reaper.UpdateItemInProject( item ) end
      end
    end
  end
  ----------------------------------------------------------------------
  function MonoCheck(item, take)
    local accessor = CreateTakeAudioAccessor( take )
    local it_len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
    local src  = reaper.GetMediaItemTake_Source( take )
    local SR =  reaper.GetMediaSourceSampleRate( src )
    local test_chan = reaper.GetMediaSourceNumChannels( src )
    
    local diff_com = 0
    
    local test_dist = it_len / 5
    local threshold_lin = 0.0001 -- -80db
    --threshold_dB = WDL_VAL2DB(threshold_lin)
    
    --local threshold_dB = -80
    for pos = 0, it_len, test_dist do 
      local samplebuffer = new_array(test_chan);
      GetAudioAccessorSamples( accessor, SR, test_chan, pos, 1, samplebuffer )
      for i = 2, test_chan do
        local diff =math.abs(samplebuffer[i]-samplebuffer[1])
        if diff > threshold_lin then diff_com = diff_com + math.abs(diff ) end
      end
      samplebuffer.clear()
    end
    DestroyAudioAccessor( accessor )   
    if diff_com == 0 then return true end
  end   
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.08) if ret then local ret2 = VF_CheckReaperVrs(5.9,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main()
    Undo_EndBlock( 'Check is multichannel item mono sourced, convert to mono if need', 0xFFFFFFFF )
  end end 
  
  
  