  
  --gate
  window_time = 0.1 -- sec
  threshold = -100 -- db
  attack = 0.2 -- sec
  release = 0.2 -- sec


function create_point (time,val)
  takeenv = reaper.GetTakeEnvelope(take, 0)
  reaper.InsertEnvelopePoint(takeenv, time,val, 2,0,false,false) 
end

function delete_point (time)
  takeenv = reaper.GetTakeEnvelope(take, 0)
  point = reaper.GetEnvelopePointByTime(takeenv, time)  
  if point ~= nil then
    reaper.DeleteEnvelopePointRange(takeenv, time-0.0001, time+0.0001)
  end
end  
  
  item = reaper.GetSelectedMediaItem(0,0)
      if item ~= nil then
        item_pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
        item_len = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
        take = reaper.GetActiveTake(item) 
        takeenv = reaper.GetTakeEnvelope(take, 0)
        if takeenv ~= nil then 
          reaper.DeleteEnvelopePointRange(takeenv, item_pos, item_len)
         else
          reaper.Main_OnCommand(40693,0) -- toggle take env
        end
        track = reaper.GetMediaItem_Track(item)
        retval, trackname = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME','', false)
        if not reaper.TakeIsMIDI(take) then
          
          --get accesor samples values+rms
          audio_accessor = reaper.CreateTakeAudioAccessor(take)
            src = reaper.GetMediaItemTake_Source(take)
            src_num_ch = 1--reaper.GetMediaSourceNumChannels(src)
            src_rate = reaper.GetMediaSourceSampleRate(src)              
             
            --loop through windows
            rms_val_t = {}
            window_samples = math.floor(src_rate * window_time)
            for read_pos = 0, item_len, window_time do        
                audio_accessor_buffer = reaper.new_array(window_samples)
                reaper.GetAudioAccessorSamples(audio_accessor,src_rate,src_num_ch,read_pos,window_samples,audio_accessor_buffer)                
                
                -- read window rms
                  rms = 0
                  audio_accessor_buffer_t = audio_accessor_buffer.table(1, window_samples)
                  for i = 1, window_samples do
                    sample_value = audio_accessor_buffer_t[i]
                    sample_value_abs = math.abs(sample_value)
                    rms = rms + sample_value_abs
                  end
                  rms = rms / window_samples
                  table.insert(rms_val_t, rms)                    
                audio_accessor_buffer_t = {}
                audio_accessor_buffer.clear()                                              
            end -- loop every window
            reaper.DestroyAudioAccessor(audio_accessor)  
            
       --gate     
            
           
            for i = 2, #rms_val_t-1 do
              rms_val_it = rms_val_t[i]
              prev_rms_val_it = rms_val_t[i-1]
              next_rms_val_it = rms_val_t[i+1]
              
              rms_val_it_db = 20*math.log(rms_val_it)
              prev_rms_val_it_db = 20*math.log(prev_rms_val_it)
              next_rms_val_it_db = 20*math.log(next_rms_val_it)
              
              if rms_val_it_db < threshold then
                if prev_rms_val_it_db < threshold then
                 create_point((i-1)*window_time,0)
                end
               else
                if prev_rms_val_it > threshold then
                  create_point((i-1)*window_time,1)
                end
              end              
            end              
                 
           reaper.UpdateItemInProject(item)
            
        end -- if not midi 
                
      end -- if item ~= nil
