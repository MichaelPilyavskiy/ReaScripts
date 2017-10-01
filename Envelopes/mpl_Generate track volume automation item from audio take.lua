-- @version 1.0
-- @author MPL
-- @changelog
--    + init  
-- @description Generate track volume automation item from audio take
-- @website http://forum.cockos.com/showthread.php?t=188335
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  function m(s) reaper.ShowConsoleMsg(s)end
 
  ---------------------------------------------------------------------------------------------------------------------  
  function Get_take_data(take, window,item_len)
    local sum_t = {}
    local accessor = CreateTakeAudioAccessor(take)
    local src = GetMediaItemTake_Source(take)
    local numch = GetMediaSourceNumChannels(src)
    local rate = GetMediaSourceSampleRate(src)       
    local size = math.ceil(window*rate)
      
    for read_pos = 0, item_len, window do
      local buffer = new_array(size*2)
      local buffer_com = new_array(size*2)
      GetAudioAccessorSamples(
                          accessor , --AudioAccessor
                          rate, -- samplerate
                          numch, -- numchannels
                          read_pos, -- starttime_sec
                          size, -- numsamplesperchannel
                          buffer) --samplebuffer
                          
      -- merge buffers dy duplicating sum/2
        for i = 1, size*numch - 1, numch do
          buffer_com[i] = (buffer[i] + buffer[i+1])/numch
          buffer_com[i+1] = 0
        end
                                            
      -- Get RMS sum in defined range
        local buffer_com_t = buffer_com.table(1,size, true)
        local sum_com = 0
        for i = 1, size do sum_com = sum_com + math.abs(buffer_com_t[i]) end    
        table.insert(sum_t, sum_com)
          
      end
    DestroyAudioAccessor(accessor)

    -- normalize table
      local max_com = 0
      for i =1, #sum_t do max_com = math.max(max_com, sum_t[i]) end
      local com_mult = 1/max_com      
      for i =1, #sum_t do sum_t[i]= sum_t[i]*com_mult  end
      table.insert(sum_t, 1, 0)
      return sum_t
  end
  ---------------------------------------------------------------------------------------------------------------------
  function main()
    local item = GetSelectedMediaItem(0,0)
    if not item then return end
    local take =  reaper.GetActiveTake( item )
    if TakeIsMIDI( take ) then return end
        
    local i_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
    local i_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )    
    local _, window_ms =  reaper.GetUserInputs( 'RMS window', 1, '(seconds)', 0.05 )
    window_ms = tonumber(window_ms)
    if not  window_ms then return end 
       
    local t = Get_take_data(take, window_ms, i_len)
    local track = GetMediaItem_Track(item)
    SetOnlyTrackSelected(track)
    env =  GetTrackEnvelopeByName( track, 'Volume' )
    if not env then 
      Main_OnCommand(40406,0) -- show vol envelope
      env =  GetTrackEnvelopeByName( track, 'Volume' )
    end
    local AI_idx = InsertAutomationItem( env, -1, i_pos, i_len )
    for i = 1, #t do InsertEnvelopePointEx( env, AI_idx, (i-1)*window_ms, t[i], 0, 0, 0, true ) end
    Envelope_SortPointsEx( env, AI_idx )
    UpdateArrange()
  end

  main()