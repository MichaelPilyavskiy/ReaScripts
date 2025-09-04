-- @description Check if multichannel item has mono source, convert to mono item if need 
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Use reaper-extstate.ini / MPL_CheckMonoSource / threshold_dB
  
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  
  threshold_dB = -60 
  -- replace with ext state
  local threshold_dBext = GetExtState( 'MPL_CheckMonoSource', 'threshold_dB' )
  if threshold_dBext == '' then 
    SetExtState( 'MPL_CheckMonoSource', 'threshold_dB',threshold_dB, true )
   else
    threshold_dB = tonumber(threshold_dBext)
  end
  
  
  
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
    function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  ---------------------------------------------------
  function main()
    for i = 1, CountMediaItems(0) do
      local item =  GetMediaItem( 0, i-1)
      if IsMediaItemSelected(item) then
        local take = GetActiveTake(item) 
        if take then 
          local ismono,outpan = MonoCheck(item, take)
          if ismono==true then  
            SetMediaItemTakeInfo_Value( take, 'I_CHANMODE' , 2) 
            if outpan then SetMediaItemTakeInfo_Value( take, 'D_PAN' ,outpan)  end
            UpdateItemInProject( item ) 
          end
        end
      end
    end
  end
    ----------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h  
  ----------------------------------------------------------------------
  function MonoCheck_GetTestPoints(item, take, divisions)  
    local accessor = CreateTakeAudioAccessor( take ) 
    local src  = reaper.GetMediaItemTake_Source( take )
    local SR =  reaper.GetMediaSourceSampleRate( src )
    local test_chan = reaper.GetMediaSourceNumChannels( src ) 
    local it_len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
    local test_dist = it_len / (divisions or 10)
    local threshold_lin = WDL_DB2VAL(threshold_dB)--0.0001 -- -80db 
    local test_points = {}
    for pos = 0.01, it_len-test_dist, test_dist do 
      local samplebuffer = new_array(test_chan);
      GetAudioAccessorSamples( accessor, SR, test_chan, pos, 1, samplebuffer )
      for i = 2, test_chan do
        local primary = samplebuffer[1] 
        local secondary = samplebuffer[i]
        if (math.abs(primary) >= threshold_lin or  math.abs(secondary) >= threshold_lin) then
          local diff = (secondary - primary) / (secondary + primary)
          test_points[#test_points+1] = {
              secondary = secondary ,
              primary = primary,
              diff=diff
            } 
        end 
      end
      samplebuffer.clear()
    end 
    DestroyAudioAccessor( accessor ) 
    return test_points
  end
  ----------------------------------------------------------------------
  function MonoCheck(item, take)
    test_points = MonoCheck_GetTestPoints(item, take)
    
    -- try again if not enough points
    if #test_points< 2 then test_points = MonoCheck_GetTestPoints(item, take, 20) end
    
    -- all file is too quiet
    if #test_points< 2 then return end
    
    -- get rms difference
    differenceRMS = 0
    for i = 1, #test_points do differenceRMS = differenceRMS + test_points[i].diff end
    differenceRMS =  differenceRMS / #test_points
    
    -- make sure difference is same along all segments of item
    local stablediff_lin = WDL_DB2VAL(-60)
    for i = 1, #test_points do if math.abs(differenceRMS - test_points[i].diff) > stablediff_lin then return end end
    
    return true, differenceRMS
  end   
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(5.9,true) then 
    Undo_BeginBlock2( 0 )
    main()
    Undo_EndBlock( 'Check is multichannel item mono sourced, convert to mono if need', 0xFFFFFFFF )
  end  
  
  
  