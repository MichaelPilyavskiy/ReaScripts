-- @description Rename audio items as analyzed MIDI note
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init, use 1bit algorithm for pitch definition
  
  
  
  function GetProjectSampleRate() return tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) end -- get sample rate obey project start offset
  ---------------------------------------------------------------------------------
  function FormatMIDIstr(val)  -- conf.key_names
  local val = math.floor(val)
  local oct = math.floor(val / 12)
  local note = math.fmod(val,  12)
  local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',}
  if note and oct and key_names[note+1] then return key_names[note+1]..oct end
  end
  ---------------------------------------------------------------------------------
  function GetTakePitch_FilterACF(ACF_output)
    
    test = ACF_output
    -- do results scoring
       lagscore = {}
      for frame in pairs(ACF_output) do
        local lag = ACF_output[frame] if not lagscore[lag] then lagscore[lag] = 0 end  lagscore[lag] = lagscore[lag] + 1  
        --local lag = ACF_output[frame]*2 if not lagscore[lag] then lagscore[lag] = 0 end  lagscore[lag] = lagscore[lag] + 1  
        --local lag = ACF_output[frame]/2 if not lagscore[lag] then lagscore[lag] = 0 end  lagscore[lag] = lagscore[lag] + 1  
      end
    
    -- find best score
      score_max = 0
      for key in pairs(lagscore) do
        score = lagscore[key]
        if score>score_max then 
          score_max = score
          bestscorelag = key
        end
      end
    
    -- filter ACF / RMS result
      local lag_error = 5 -- spls
      local RMS = 0
      local RMS_cnt = 0
      for frame in pairs(ACF_output) do
        if ACF_output[frame] - bestscorelag < lag_error then
          RMS_cnt = RMS_cnt + 1
          RMS = RMS + ACF_output[frame]
         elseif (ACF_output[frame]/2 - bestscorelag) < lag_error then -- +1 octave shift
          RMS_cnt = RMS_cnt + 1
          RMS = RMS + ACF_output[frame]/2
         elseif (ACF_output[frame]*2 - bestscorelag) < lag_error then -- -1 octave shift
          RMS_cnt = RMS_cnt + 1
          RMS = RMS + ACF_output[frame]*2          
        end
      end
      RMS_lag = (RMS / RMS_cnt)--math.floor
      
    return RMS_lag
  end
  ---------------------------------------------------------------------------------
  function GetTakePitch_ModifiedACF_GetBestLag(data,frame_pos,frame_len,min_lag)
    local bestlag = -1
    local diff
    local min_diff = math.huge
    for lag = min_lag, frame_len do
      diff = 0
      
      for frame = frame_pos, frame_pos+frame_len*1.5-min_lag do
        diff_int = 0
        if data[frame] ~= data[frame+lag] then diff_int = 1 end
        diff = diff + diff_int
      end
      
      if diff < min_diff then
        min_diff = diff
        bestlag = lag
      end 
    end
    
    if bestlag ~= -1 then  return bestlag end
  end
  ---------------------------------------------------------------------------------
  function GetTakePitch_ModifiedACF(data, SR)
    local Fmin = 80 -- hz
    local min_lag_spl = 100 
    
    local sz = #data
    local frame_len = math.floor(SR/Fmin) 
    local ACF_output = {}
    for frame_pos=1, sz-frame_len,frame_len do ACF_output[frame_pos] = GetTakePitch_ModifiedACF_GetBestLag(data,frame_pos,frame_len,min_lag_spl) end
    
    return true, ACF_output
  end
  ---------------------------------------------------------------------------------
  function GetTakePitch_1bitQuantize(data) local sz = #data for i = 1,sz do data[i]=data[i]>=0 end end
  ---------------------------------------------------------------------------------
  function GetTakePitch_GetAudioData(tr, bound_st, bound_end, SR)
  
    -- get data / RMS
    local accessor = CreateTrackAudioAccessor( tr )
    local numchannels = 1
    local splscnt = math.floor((bound_end - bound_st)*SR)
    local samplebuffer = new_array(splscnt)
    GetAudioAccessorSamples( accessor, SR, numchannels, bound_st, splscnt, samplebuffer )
    DestroyAudioAccessor( accessor )
    local data = {}
    local rms = 0 
    for spl=1,splscnt do data[spl] = samplebuffer[spl] rms = rms + math.abs(samplebuffer[spl])end
    rms=rms/splscnt
    samplebuffer.clear()
    
    --[[ ignore attack less-than-0.5x-rms data
    local spl_attack = 0
    for spl=1,splscnt do if math.abs(data[spl]) > rms then spl_attack = spl break end  end 
    local data_out = data
    local i2 = 0
    if spl_attack > 0 then  for i = spl_attack,splscnt do i2=i2+1 data_out[i2] = data[i] end end]]
    
    return true,data--_out
  end
  ---------------------------------------------------------------------------------
  function GetTakePitch_GetBoundaries(take)
    
    local tr = GetMediaItemTake_Track( take )
    local item = GetMediaItemTake_Item( take )
    local itpos = GetMediaItemInfo_Value( item, 'D_POSITION' )
    local itlen = GetMediaItemInfo_Value( item, 'D_LENGTH' )
    
    local audio_len_limitmin = 0.05
    local audio_len_limitmax = 2 
    if itlen<audio_len_limitmin then itlen = audio_len_limitmin end 
    if itlen>audio_len_limitmax then itlen = audio_len_limitmax end
    
    local bound_st = itpos
    local bound_end = itpos+itlen 
    
    return true, tr, bound_st, bound_end
  end
  ---------------------------------------------------------------------------------
  function math_q(num)  if math.abs(num - math.floor(num)) < math.abs(num - math.ceil(num)) then return math.floor(num) else return math.ceil(num) end end
  ---------------------------------------------------------------------------------
  function GetTakePitch(take) 
  
    local ret, tr, bound_st, bound_end = GetTakePitch_GetBoundaries(take) -- we want to get track audioaccessor intead of take`s one to prevent from dealing with take offsets, non1-x playrates, stretch markers etc
    if not ret then return end
    
    
    local SR = GetProjectSampleRate() 
    local ret, data = GetTakePitch_GetAudioData(tr, bound_st, bound_end, SR)
    if not ret then return end 
    GetTakePitch_1bitQuantize(data)
    local ret, ACF_output = GetTakePitch_ModifiedACF(data, SR)
    if not ret then return end 
    local RMS_lag_spl = GetTakePitch_FilterACF(ACF_output) -- out period in samples
    if not RMS_lag_spl then return end 
    
    local RMS_lag_sec = RMS_lag_spl / SR
    local out_f = 1/RMS_lag_sec
    local MIDIpitch = math_q(( 12 * math.log(out_f / 220.0) / math.log(2.0) ) + 57.0 )
    
    return MIDIpitch
  end
  ---------------------------------------------------------------------------------
  function RenameAudioItemsWithMIDInote(take)
    if not (take and ValidatePtr2(0,take, 'MediaItem_Take*')) then return end
    MIDInote = GetTakePitch(take)
    if MIDInote then 
      --MIDInote = MIDInote..' ('..FormatMIDIstr(MIDInote)..')'
      GetSetMediaItemTakeInfo_String( take, 'P_NAME', MIDInote, 1 ) 
    end
  end
  ---------------------------------------------------------------------------------
  function main()
    local ret = MB('CAUTION\nAnalyzing items pitch can FREEZE your project. Make sure you saved data before triggering this script.','Rename audio items to analyzed MIDI note',3)
    if ret ~= 6 then return end
    for i = 1, CountSelectedMediaItems(0) do
      local it = GetSelectedMediaItem(0,i-1)
      RenameAudioItemsWithMIDInote(GetActiveTake(it))
    end
  end
  ---------------------------------------------------------------------------------
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  main()