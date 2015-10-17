window_time = 0.005
fft_size = 64

item = reaper.GetMediaItem(0,0)    
      if item ~= nil then
        item_pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
        item_len = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
        take = reaper.GetActiveTake(item) 
        track = reaper.GetMediaItem_Track(item)
        retval, trackname = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME','', false)
        if not reaper.TakeIsMIDI(take) then
          if trackname == '' then trackname = '(no name)' end
                              
          --get accesor samples values+rms
          rms_val_t = {}
          fft_val_t = {}
          audio_accessor = reaper.CreateTakeAudioAccessor(take)
            src = reaper.GetMediaItemTake_Source(take)
            src_num_ch = 1--reaper.GetMediaSourceNumChannels(src)
            src_rate = reaper.GetMediaSourceSampleRate(src)              
            window_samples = math.floor(src_rate * window_time)
            
            
            --loop through windows
            for read_pos = 0, item_len, window_time do              
                audio_accessor_buffer = reaper.new_array(window_samples)
                reaper.GetAudioAccessorSamples(audio_accessor,src_rate,src_num_ch,read_pos,window_samples,audio_accessor_buffer)
                
                -- fft aa buffer                  
                  audio_accessor_buffer.fft(fft_size, true, 1)
                  fft_max_val = 0
                  audio_accessor_buffer_fft_t = audio_accessor_buffer.table(1, fft_size)
                  for i = 1, fft_size  do
                    value = audio_accessor_buffer_fft_t[i]
                    fft_max_val = math.max(fft_max_val, value)
                  end
                  for i = 1, fft_size  do
                    value = audio_accessor_buffer_fft_t[i]
                    if value == fft_max_val then fft_max_val_id = i break end
                  end 
                  table.insert(fft_val_t, fft_max_val_id)
                 
                audio_accessor_buffer_t = {}
                audio_accessor_buffer.clear()                              
            end -- loop every window
                    
          reaper.DestroyAudioAccessor(audio_accessor)     
        end -- if not midi  
        w = 700
        h = 100
        gfx.init('', w,h)
        gfx.x = 0
        gfx.y = h
        for i = 1, #fft_val_t do
          fft_val_t_it = fft_val_t[i]
          gfx.lineto((i/#fft_val_t) * w, 
                    h- (fft_val_t_it/(fft_size/6))*h ,1)
        end
        
        
        
      end -- if item ~= nil
      
