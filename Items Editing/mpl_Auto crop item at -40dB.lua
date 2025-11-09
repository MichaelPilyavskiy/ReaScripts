-- @description Auto crop item at -40dB
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
  
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  
  threshold_dB = -40 
  
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
          start_pos, end_pos, srclen = GetBoundary(item, take)
          if start_pos ~= 0 then 
            D_STARTOFFS = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
            srcoffs = 0
            if D_STARTOFFS > srclen then srcoffs = math.floor(D_STARTOFFS / srclen) end
            SetMediaItemTakeInfo_Value( take, 'D_STARTOFFS', D_STARTOFFS + start_pos + srcoffs*srclen )
            D_POSITION = GetMediaItemInfo_Value( item, 'D_POSITION' )
            SetMediaItemInfo_Value( item, 'D_POSITION', D_POSITION +  start_pos+ srcoffs*srclen)
          end
          
          if end_pos ~= 0 then 
            D_LENGTH = GetMediaItemInfo_Value( item, 'D_LENGTH' )
            SetMediaItemInfo_Value( item, 'D_LENGTH', D_LENGTH - end_pos - start_pos)
          end
          
          UpdateItemInProject( item ) 
        end
      end
    end
  end
    ----------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h  
  ----------------------------------------------------------------------
  function GetBoundary(item, take)  
    local accessor = CreateTakeAudioAccessor( take ) 
    local src  = reaper.GetMediaItemTake_Source( take )
    local SR =  reaper.GetMediaSourceSampleRate( src )
    local srclen = reaper.GetMediaSourceLength( src )
    local chan = reaper.GetMediaSourceNumChannels( src ) 
    local it_len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
    
    local test_dist = 0.2
    local threshold_lin = WDL_DB2VAL(threshold_dB)
     
    local start_pos = 0
    for pos = 0.01, it_len-test_dist, test_dist do 
      local samplebuffer = new_array(chan);
      GetAudioAccessorSamples( accessor, SR, chan, pos, 1, samplebuffer )
      local spl_max = 0
      for i = 1, chan do
        local spl = samplebuffer[i] 
        spl_max = math.max(spl_max, math.abs(spl))
      end 
      if spl_max > threshold_lin then 
        start_pos = pos-test_dist
        break
      end
      samplebuffer.clear()
    end 
    
    local end_pos = it_len
    for pos = it_len-0.01, start_pos+test_dist, -test_dist do 
      local samplebuffer = new_array(chan);
      GetAudioAccessorSamples( accessor, SR, chan, pos, 1, samplebuffer )
      local spl_max = 0
      for i = 1, chan do
        local spl = samplebuffer[i] 
        spl_max = math.max(spl_max, math.abs(spl))
      end 
      if spl_max > threshold_lin then 
        end_pos = it_len - pos-test_dist+0.01
        break
      end
      
      samplebuffer.clear()
    end 
    
    DestroyAudioAccessor( accessor ) 
    return start_pos, end_pos, srclen
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(7,true) then 
    Undo_BeginBlock2( 0 )
    main()
    Undo_EndBlock( 'Auto crop item', 0xFFFFFFFF )
  end  
  
  
  