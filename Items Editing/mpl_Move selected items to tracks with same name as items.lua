  -- ssd trigger
  
 
  ---------------------------------------------------------------------------------------------------------------------  
  function Get_take_data(item)
    if item == nil then return end
    local take = reaper.GetActiveTake(item)
    local item_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    
      local sum_t = {}
      local aa = {}
      aa.accessor = reaper.CreateTakeAudioAccessor(take)
      aa.src = reaper.GetMediaItemTake_Source(take)
      aa.numch = reaper.GetMediaSourceNumChannels(aa.src)
      aa.rate = reaper.GetMediaSourceSampleRate(aa.src) 
      
      aa.window_sec = 0.005
      local size = math.ceil(aa.window_sec*aa.rate)
      
      for read_pos = 0, item_len, aa.window_sec do 
                  
        aa.buffer = reaper.new_array(size*2)
        aa.buffer_com = reaper.new_array(size*2)
                     
        reaper.GetAudioAccessorSamples(
                          aa.accessor , --AudioAccessor
                          aa.rate, -- samplerate
                          aa.numch, -- numchannels
                          read_pos, -- starttime_sec
                          size, -- numsamplesperchannel
                          aa.buffer) --samplebuffer
                          
        -- merge buffers dy duplicating sum/2
          for i = 1, size*aa.numch - 1, aa.numch do
            aa.buffer_com[i] = (aa.buffer[i] + aa.buffer[i+1])/aa.numch
            aa.buffer_com[i+1] = 0
          end
                                            
        -- Get RMS sum in defined range
        aa.buffer_com_t = aa.buffer_com.table(1,size, true)
        local sum_com = 0
        for i = 1, size do sum_com = sum_com + math.abs(aa.buffer_com_t[i]) end    
        table.insert(sum_t, sum_com)
      end
    reaper.DestroyAudioAccessor(aa.accessor)

    -- normalize table
      local max_com = 0
      for i =1, #sum_t do max_com = math.max(max_com, sum_t[i]) end
      local com_mult = 1/max_com      
      for i =1, #sum_t do sum_t[i]= sum_t[i]*com_mult  end
      table.insert(sum_t, 1, 0)
      return sum_t, aa.window_sec
  end
  
  ---------------------------------------------------------------------------------------------------------------------
  
  function GetVelocity(t, id, window)
     num = 10
     
    if id + num > #t then num = #t - id end    
    com = 0
    for i = id, id + num do
      com = com + math.abs(t[i])
    end
    com = com / num
    return com
  end  
  
  ---------------------------------------------------------------------------------------------------------------------
  
  function GetTransients(t, window)
    local threshold = -25 -- db
    local rel_ms = 0.2 -- sec
    
    
    local pos_t = {}
    pos_t2 = {}
    if t == nil then return pos_t end    
    local rel = rel_ms/window
    local last_ind = -rel
    for i = 2, #t do
      pos_t2[#pos_t2+1] = GetVelocity(t, i, window)
      local diff = t[i] - t[i-1]
      local diff_dB = 20*math.log(diff, 10)
      if diff_dB > threshold then 
        if i - last_ind > rel then
          local test = GetVelocity(t, i, window)
          pos_t[#pos_t+1] = {window*(i-2) , test}
          
          last_ind = i
        end
      end
    end
    return pos_t,pos_t2
  end
  
  ---------------------------------------------------------------------------------------------------------------------
  
  function m(pos, name)
    reaper.AddProjectMarker(0, false, pos, 0, math.floor(name*1000)/1000, 0)
  end
  
  ---------------------------------------------------------------------------------------------------------------------
  
  local item = reaper.GetSelectedMediaItem(0,0)
   t,window = Get_take_data(item)
  pos_t, pos_t2 = GetTransients(t, window)
  
  item_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWSMARKERLIST9'),0)
  for i = 1,#pos_t do m(pos_t[i][1] + item_pos,math.floor(pos_t[i][2] * 127)) end
  reaper.UpdateTimeline()
  
  --[[w = 700
  h = 200
  gfx.init('',w,h)
  function draw(t0,x)
    gfx.r = x
    gfx.x = 0
    for i = 1, #t0 do
      gfx.lineto(i*w/#t0, h -t0[i]*700)
    end
  end
  draw(pos_t2, 1)
  draw(t, 0)
  ]]
