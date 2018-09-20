-- @version 1.01
-- @author MPL
-- @description Generate DC offset envelope from asymmetric waveform
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # hardcoded buffer limit = 2^21 (approximately 48 seconds for 44100 SR)
    
  window = 0.02
  scale = 1
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end
  function m(s) if s then ShowConsoleMsg(s..'\n')end end 
  ---------------------------------------------------------------------------------------------------------------------  
  function GetSamples(item)
    local take = GetActiveTake( item )
    if TakeIsMIDI( take ) then return end 
    local src = GetMediaItemTake_Source(take)
    local len = GetMediaItemInfo_Value(item, "D_LENGTH")
    local samplerate =  GetMediaSourceSampleRate( src )
    local buf_samples = math.ceil(len*samplerate)
    local numchannels = 1
    local buf = new_array(math.min(buf_samples * numchannels, 2^21))
    local accessor = CreateTakeAudioAccessor( take )
    GetAudioAccessorSamples( accessor, 
                              samplerate, 
                              numchannels, 
                              0,--starttime_sec, 
                              buf_samples,--numsamplesperchannel, 
                              buf)--samplebuffer )
    local t = buf.table()
    buf.clear()
    DestroyAudioAccessor( accessor )
    return t,samplerate
  end 
  ---------------------------------------------------------------------------------------------------------------------
  function Normalize(t)
    local m = 0 for i = 1, #t do m = math.max(math.abs(t[i]),m) end
    for i = 1, #t do t[i] = t[i]/m end
    return t
  end
  ---------------------------------------------------------------------------------------------------------------------  
  function GetDCEnv(t0, step)
    local t = {}
    for i = 1, #t0, step do
      local com = 0
      for j = i, i + step-1 do
        if t0[j] then com = com + t0[j] end
      end
      t[#t+1] = com/1000
    end
    return t
  end 
  ---------------------------------------------------------------------------------------------------------------------
  function Scale(t,x)
    for i = 1, #t do t[i] = t[i]*x end
    return t
  end
  --------------------------------------------------------------------------------------------------------------------- 
  function CheckDCJSFX(tr)
    local ret = TrackFX_AddByName( tr, 'DC offset.jsfx', false, 1 )
    if ret == -1 then 
      MB('Please install MPL DC offset JSFX first','',0)
      ReaPack_BrowsePackages('MPL DC offset')
     else
      return ret
    end
  end
  --------------------------------------------------------------------------------------------------------------------- 
  function AddPoints(track,fxnum,paramnum, pos,len, t, wind) 
     fx_env = GetFXEnvelope( track, fxnum, paramnum, true )
    --local AI_poolid = InsertAutomationItem( fx_env, -1, AI_pos, AI_len )
    DeleteEnvelopePointRange( fx_env, pos, pos+len )
    for i = 1, #t do
      InsertEnvelopePointEx( fx_env, -1, pos+i*wind, t[i], 0, 0, 0, true )
    end
    Envelope_SortPointsEx( fx_env, -1)
  end
  ---------------------------------------------------------------------------------------------------------------------  
  function main()
    local item = reaper.GetSelectedMediaItem(0,0)
    if not item then return end
    local it_pos = GetMediaItemInfo_Value( item, 'D_POSITION' ) 
    local it_len = GetMediaItemInfo_Value( item, 'D_LENGTH' ) 
    local tr =  GetMediaItem_Track( item )
    fx_id = CheckDCJSFX(tr)
    if not fx_id or fx_id < 0 then return end
    local ret, retvals = GetUserInputs('Generate DC Offset envelope', 2,'window,scale', window..','..scale)
    if ret then 
      num_t = {} for num in retvals:gmatch('[^%,]+') do if tonumber(num) then num_t[#num_t+1] = num end end
      if #num_t<2 then return end
      local t,samplerate = GetSamples(item)
      local step = math.floor(samplerate*num_t[1])
      local t0 = GetDCEnv(t, step)
      t0 = Scale(t0,-num_t[2])
      AddPoints(tr,fx_id,0,it_pos,it_len,t0,num_t[1]) 
    end
    
    TrackList_AdjustWindows( false )
    UpdateArrange()  
    --    InsertEnvelopePointEx( envelope, autoitem_idx, time, value, shape, tension, selected, noSortIn )
  end
  ---------------------------------------------------------------------------------------------------------------------   
  
  main()