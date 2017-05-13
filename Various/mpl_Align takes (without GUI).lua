-- @description Align Takes (without GUI)
-- @version 1.120
-- @author MPL
-- @changelog
--    # Temporary fix for 'id_diff' #796
--    + init no GUI branch
-- @website http://forum.cockos.com/member.php?u=70694

--[[
  * Changelog: 
  ``* v1.120 (2016-08-09)
      # Temporary fix for 'id_diff' #796
      + init no GUI branch      
    * v1.111 (2016-06-23)
      + Presets
      + Parameter to load current script instance with custom preset
      + About window
      + Dedicated thread on Cockos forum: http://forum.cockos.com/showthread.php?p=1709618
      # Edit links/description
      # Brighter knobs
      # Swap points and envelope colors to match related settings
      # ReaPack versioning fix
    * v1.08 (2016-06-11)
      # Fix: error on empty sm table
      # Improved graphics for knob and selector
    * v1.07 (2016-04-01)
      # Set slider to 0 when get takes
    * v1.06 (2016-03-31)
      # Fixed alg=0 error
    * v1.05 (2016-03-08)
      # save/restore window position (Reaper 5.20pre16+)
    * v1.04 (2016-02-17)
      # ReaPack changelog synthax
    * v1.03 (2016-02-16)
      + Algorithm selector, check Menu/Parameters description
    * v1.02 (2016-02-12)
      #OSX font issues
    * v1.01 (2016-02-11)
      # Some settings limits extended
      + Added selector RMS/FFT detection
      + Added RMS window knob
      + Added FFT size knob
      + Added HP/LP FFT filters cutoff knobs
      + Added smooth factor knob
    * v1.00 (2016-02-11)    
      + Public release
    * v0.23 (2016-01-25)  
      # Split from Warping tool
    * v0.01 (2015-09-01) 
      + Alignment / Warping / Tempomatching tool idea
  --]]
-----------------------------------------------------------------------  



 
  local load_preset_on_start = 'current'
  
    -- 'current' - load last config
    -- 'default' - load default config
    -- 3 - load preset #3
  
  
  
  
  
  
----------------------------------------------------------------------- 
----------------------------------------------------------------------- 
-----------------------------------------------------------------------   
  local vrs = '1.12'
----------------------------------------------------------------------- 
  function msg(str)
    if type(str) == 'boolean' then if str then str = 'true' else str = 'false' end end
    if type(str) == 'userdata' then str = str.get_alloc() end
    if str ~= nil then 
      reaper.ShowConsoleMsg(tostring(str)..'\n') 
      if str ==  "" then reaper.ShowConsoleMsg("") end
     else
      reaper.ShowConsoleMsg('nil')
    end    
  end
  
----------------------------------------------------------------------- 
  function fdebug(str) if debug_mode == 1 then msg(os.date()..' '..str) end end  
  
----------------------------------------------------------------------- 
  function MAIN_exit()
    INI_set()
    reaper.atexit()
    gfx.quit()
  end  
-----------------------------------------------------------------------    
  function MAIN_switch_compact_view(obj)
    if compact_view_trig then 
      obj.main_h = obj.main_h + data.current.compact_view*obj.set_wind_h
      gfx.quit()
      gfx.init("mpl Align takes // "..vrs, obj.main_w, obj.main_h, 0, data.current.xpos,data.current.ypos )
      compact_view_trig = false
    end 
  end
-----------------------------------------------------------------------   
  function A2_DEFINE_dynamic_variables()
    if not data2.current_take then data2.current_take = 2 end

    -- green / detection point  
      data2.scaling_pow = F_convert(math.abs(1-data.current.scaling_pow_norm), 0.1, 0.75)
      data2.threshold = F_convert(data.current.threshold_norm, 0.1,0.4)     
      data2.rise_area = F_convert(data.current.rise_area_norm, 0.1,0.5)
      data2.risefall = F_convert(data.current.risefall_norm, 0.1,0.8)
      data2.risefall2 = F_convert(data.current.risefall2_norm, 0.05,0.8)    
      data2.filter_area = F_convert(data.current.filter_area_norm, 0.1,2)
          
    -- blue / envelope
      data2.custom_window = F_convert(data.current.custom_window_norm, 0.005, 0.2)
      data2.fft_size = math.floor(2^math.floor(F_convert(data.current.fft_size_norm,7,10)))
      if data2.fft_LP == nil then data2.fft_LP = data2.fft_size end
      data2.fft_HP = F_limit(math.floor(F_convert(data.current.fft_HP_norm, 1, data2.fft_size)), 1, data2.fft_LP-1)
      data2.fft_LP =  1+F_limit(math.floor(F_convert(data.current.fft_LP_norm, 1, data2.fft_size)), data2.fft_HP+1, data2.fft_size)
      data2.smooth = data.current.smooth_norm
    
    -- red / algo
      data2.search_area = F_convert(data.current.search_area_norm, 0.05, 2) 
      
    --othert
      data2.play_pos = reaper.GetPlayPosition(0)
  end
  
-----------------------------------------------------------------------  
  function F_convert(val, min, max)
    return (max-min) *val + min
  end
  
-----------------------------------------------------------------------
  function F_limit(val,min,max,retnil)
    if val == nil or min == nil or max == nil then return 0 end
    local val_out = val 
    if val == nil then val = 0 end
    if val < min then  val_out = min 
      if retnil then return nil end
    end
    if val > max then val_out = max 
      if retnil then return nil end
    end
    return val_out
  end 
    
-----------------------------------------------------------------------    
  function F_Get_SSV(s)
    local t = {}
    for i in s:gmatch("[%d%.]+") do 
      t[#t+1] = tonumber(i) / 255
    end
    gfx.r, gfx.g, gfx.b = t[1], t[2], t[3]
  end
  
----------------------------------------------------------------------- 
  function ENGINE_get_takes() 
    local take_guid
    local take_name
    local takes_t = {}
    local count_items = reaper.CountSelectedMediaItems()
    if count_items ~= nil then 
      for i =1, count_items do 
        local item = reaper.GetSelectedMediaItem(0, i-1)
        if item ~= nil then
          local item_len  = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH')
          local item_pos  = reaper.GetMediaItemInfo_Value( item, 'D_POSITION')
          
          
          local take = reaper.GetActiveTake(item)
          if not reaper.TakeIsMIDI(take) then    
            take_guid = reaper.BR_GetMediaItemTakeGUID(take)
            _, take_name = reaper.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false)      
            local t_offs = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')            
            local src = reaper.GetMediaItemTake_Source(take)
            local rate = reaper.GetMediaSourceSampleRate(src) 
            local vol  = reaper.GetMediaItemTakeInfo_Value(take, 'D_VOL')
            
            table.insert(takes_t, 
              {['guid']=take_guid,
               ['name']=take_name,
               ['len']=item_len,
               ['pos']=item_pos,
               ['offset']=t_offs,
               ['rate']=rate,
               ['vol']=vol})
          end
        end    
      end        
    end   
    return takes_t 
  end  

-----------------------------------------------------------------------     
  function ENGINE_prepare_takes() local item, take
    local count_items = reaper.CountSelectedMediaItems()
    if count_items == nil or count_items < 1 then return end
    
        reaper.Main_OnCommand(41844,0) -- clear stretch markers
        reaper.Main_OnCommand(40652,0) -- set item rate to 1
        
        -- check for unglued reference item/take
          local ref_item = reaper.GetSelectedMediaItem(0, 0)
          if ref_item == nil then return end
          local ref_track = reaper.GetMediaItemTrack(ref_item)
          local ref_pos = reaper.GetMediaItemInfo_Value(ref_item, 'D_POSITION')
          local ref_len = reaper.GetMediaItemInfo_Value(ref_item, 'D_LENGTH')
          for i = 2, count_items do
            item = reaper.GetSelectedMediaItem(0, i-1)
            track = reaper.GetMediaItemTrack(item)
            if track == ref_track then
              reaper.MB('Reference item/take should be glued','Warping tool', 0)
              return
            end
          end
          
        -- check for edges
          for i = 2, count_items do
            item = reaper.GetSelectedMediaItem(0, i-1)
            local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
            local len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
            if pos < ref_pos then 
              reaper.SetMediaItemInfo_Value(item, 'D_POSITION', ref_pos) 
              local take = reaper.GetActiveTake(item)   
              local take_offs = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
              reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', take_offs + ref_pos - pos)
            end
            
            if ref_pos + ref_len < pos+len then
              reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', len - (pos+len - ref_pos  - ref_len)) 
            end
                        
          end
      
    
    reaper.UpdateArrange()
    return 1 -- successful
  end
  
-----------------------------------------------------------------------   
  function ENGINE_get_take_data(take_id, scaling)
    local st_win_cnt,end_win_cnt
    
    local aa = {}
    local sum_t = {}
    
    if takes_t ~= nil and takes_t[take_id] ~= nil then
      local take = reaper.SNM_GetMediaItemTakeByGUID(0, takes_t[take_id].guid)
      if take ~= nil then
        local item = reaper.GetMediaItemTake_Item(take)
        local item_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
        aa.accessor = reaper.CreateTakeAudioAccessor(take)
        aa.src = reaper.GetMediaItemTake_Source(take)
        aa.numch = reaper.GetMediaSourceNumChannels(aa.src)
        aa.rate = reaper.GetMediaSourceSampleRate(aa.src) 
        
          if data.mode == 0 then
            aa.window_sec = data2.custom_window
           else
            aa.window_sec = data2.fft_size/aa.rate -- ms
          end
          
          data2.global_window_sec = aa.window_sec
          size = math.ceil(aa.window_sec*aa.rate)
          -- get fft_size samples buffer
            for read_pos = 0, item_len, aa.window_sec do 
            
              aa.buffer = reaper.new_array(size*2)
              aa.buffer_com = reaper.new_array(size*2)
               
              reaper.GetAudioAccessorSamples(
                    aa.accessor , --AudioAccessor
                    aa.rate, -- samplerate
                    2,--aa.numch, -- numchannels
                    read_pos, -- starttime_sec
                    size, -- numsamplesperchannel
                    aa.buffer) --samplebuffer
                    
              -- merge buffers dy duplicating sum/2
                for i = 1, size*2 - 1, 2 do
                  aa.buffer_com[i] = (aa.buffer[i] + aa.buffer[i+1])/2
                  aa.buffer_com[i+1] = 0
                end
              
              if data.mode == 1 then  
                -- Get FFT sum of bins in defined range
                  aa.buffer_com.fft(size, true, 1)
                  aa.buffer_com_t = aa.buffer_com.table(1,size, true)
                  sum_com = 0
                  for i = data2.fft_HP, data2.fft_LP do
                    sum_com = sum_com + math.abs(aa.buffer_com_t[i])
                  end    
                  table.insert(sum_t, sum_com /(data2.fft_LP-data2.fft_HP))
                else
                                      
               -- Get RMS sum in defined range
                  aa.buffer_com_t = aa.buffer_com.table(1,size, true)
                  sum_com = 0
                  for i = 1, size do
                    sum_com = sum_com + math.abs(aa.buffer_com_t[i])
                  end    
                  table.insert(sum_t, sum_com)
              end
               
                            
                aa.buffer.clear()
                aa.buffer_com.clear()              
            end
            
        reaper.DestroyAudioAccessor(aa.accessor)
       else return
      end
     else return
    end
    
    local out_t = sum_t
    
    -- normalize table
      local max_com = 0
      for i =1, #out_t do max_com = math.max(max_com, out_t[i]) end
      local com_mult = 1/max_com      
      for i =1, #out_t do out_t[i]= out_t[i]*com_mult  end
    
    -- return scaled table
      --for i =1, #out_t do out_t[i]= out_t[i]^scaling  end
    
    -- smooth table
      for i = 2, #out_t do out_t[i]= out_t[i] - (out_t[i] - out_t[i-1])*0.75   end
      
    -- fill null to reference item
      if take_id > 1 then
        st_win_cnt = math.floor ((takes_t[take_id].pos - takes_t[1].pos) 
        / data2.global_window_sec)
        end_win_cnt = math.floor
          ((takes_t[1].pos + takes_t[1].len - takes_t[take_id].pos - takes_t[take_id].len) 
          / data2.global_window_sec)
        -- fill from start
          if takes_t[take_id].pos > takes_t[1].pos then            
            for i = 1, st_win_cnt do table.insert(out_t, 1, 0) end
          end
        -- fill end
          if takes_t[take_id].pos + takes_t[take_id].len < 
              takes_t[1].pos + takes_t[1].len then
            for i = 1, end_win_cnt do out_t[#out_t+1] = 0 end
          end
      end
    
      if out_t ~= nil and #out_t > 1 then
        local out_array = reaper.new_array(out_t, #out_t)
        return out_array
      end
  end 
        
-----------------------------------------------------------------------  
  function ENGINE_get_take_data_points2(inputarray, window_sec) -- micro mode
    --local arr_size,points
    
    if inputarray == nil then return end
    
    
    arr_size = inputarray.get_alloc()    
    if arr_size <=1 then return end
    
    inputarray_scaled = reaper.new_array(arr_size)
    for i = 1, arr_size do inputarray_scaled[i] = inputarray[i]^data2.scaling_pow end
    
    points = reaper.new_array(arr_size)
    
    --  clear arr val
      for i = 1, arr_size do points[i] = 0 end  
    
    -- parameters
      filter_area_wind = math.floor(data2.filter_area / window_sec)
      risearea_wind = math.floor(data2.rise_area / window_sec)
      
      -------------
      -------------
      
    -- check for rise
      for i = 1, arr_size - risearea_wind do 
        arr_val_i = inputarray_scaled[i]
        max_val = 0
        for k = i, i + risearea_wind do
          arr_val_k = inputarray_scaled[k]
          max_val = math.max(max_val,arr_val_k)
          if last_max_val == nil or last_max_val ~= max_val then max_val_id = k end
          last_max_val = max_val
        end
        if max_val - arr_val_i > data2.risefall then
          
          arr_val_i2 = inputarray[i]
          max_val2 = 0
          for k = i, i + risearea_wind do
            arr_val_k2 = inputarray[k]
            max_val2 = math.max(max_val2,arr_val_k2)
            if last_max_val2 == nil or last_max_val2 ~= max_val2 then 
              max_val_id2 = k end
            last_max_val2 = max_val2
          end
          if max_val2 - arr_val_i2 > data2.risefall2 then          
          
            points[max_val_id] = 1
          end
        end
      end
    
    -- check for fall
      for i = 1, arr_size - risearea_wind do 
        arr_val_i = inputarray_scaled[i]
        min_val = 1
        for k = i, i + risearea_wind do
          arr_val_k = inputarray_scaled[k]
          min_val = math.min(min_val,arr_val_k)
          if last_min_val == nil or last_min_val ~= min_val then min_val_id = k end
          last_min_val = max_val
        end
        if arr_val_i - min_val > data2.risefall then
          arr_val_i2 = inputarray[i]
          min_val2 = 1
          for k = i, i + risearea_wind do
            arr_val_k2 = inputarray[k]
            min_val2 = math.min(min_val2,arr_val_k2)
            if last_min_val2 == nil or last_min_val2 ~= min_val2 then 
              min_val_id2 = k end
            last_min_val2 = max_val2
          end
          if arr_val_i2 - min_val2 > data2.risefall2 then        
            points[min_val_id] = 1
          end
        end
      end 
            
      -------------
      -------------
      
    -- filter points threshhld
      for i = 1, arr_size do
        if inputarray_scaled[i] < data2.threshold 
          then 
          points[i] = 0 end
      end 
            
    -- filter points area
      for i = 1, arr_size-1 do 
        if points[i] == 1 then
          point_i_val = inputarray_scaled[i]
          max_sa = i + 1 + filter_area_wind
          if max_sa > arr_size then max_sa = arr_size end
          for k = i + 1, max_sa do
            if points[k] == 1 then points[k] = 0 end
          end       
        end
      end 

      -------------
      -------------
                        
    -- prepare for output
      for i = 2, filter_area_wind do  points[i] = 0 end
      points[1] = 1
      points[arr_size] = 1
      
    return points    
  end
 
-----------------------------------------------------------------------    
  function F_find_arrays_com_diff(ref_array, ref_array_offset, dub_array, get_ref_block_rms)
    local dub_array_size = dub_array.get_alloc()
    local ref_array_size = ref_array.get_alloc()
    local endpoint,ref_rms
    local com_difference = 0
    if ref_array_offset + dub_array_size > ref_array_size then endpoint = ref_array_size - ref_array_offset
      else endpoint = dub_array_size end
      
    for i = 1, endpoint do
      com_difference = com_difference + math.abs(ref_array[i + ref_array_offset - 1 ]-dub_array[i])
    end
    
    if get_ref_block_rms ~= nil and get_ref_block_rms then
      ref_rms = 0
      for i = 1, endpoint do
        ref_rms = ref_rms + math.abs(ref_array[i + ref_array_offset - 1 ])
      end
      ref_rms = ref_rms / endpoint
    end
    
    return com_difference, ref_rms
  end   
   
-----------------------------------------------------------------------   
  function F_find_min_value(t)
    local min_val_id, min_val, min_val0
    min_val0 = math.huge
    for i = 1, #t do
      min_val = math.min(min_val0, t[i])
      if min_val ~= min_val0 then 
        min_val0 = min_val
        min_val_id = i
      end
    end
    return min_val_id
  end

-----------------------------------------------------------------------   
  function F_find_max_value(t)
    local max_val_id, max_val, max_val0
    max_val0 =0
    for i = 1, #t do
      max_val = math.max(max_val0, t[i])
      if max_val ~= max_val0 then 
        max_val0 = max_val
        max_val_id = i
      end
    end
    return max_val_id
  end
      
-----------------------------------------------------------------------   
    function F_stretch_array(src_array, new_size)
      local src_array_size = src_array.get_alloc()
      local coeff = (src_array_size - 1) / (new_size  - 1)
      local out_array = reaper.new_array(new_size)
      if new_size < src_array_size or new_size > src_array_size then
        for i = 0, new_size - 1 do 
          src_idx = math.floor(i * coeff) + 1
          src_idx = math.floor(F_limit(src_idx, 1, src_array_size))
          out_array[i+1] = 
            src_array[src_idx]
        end
        return out_array
       elseif new_size == src_array_size then 
        out_array = src_array 
        return out_array
      end    
      return out_array    
    end
    
-----------------------------------------------------------------------       
  function F_stretch_array2(src_array, src_mid_point, stretched_point)
    if src_array == nil or src_mid_point == nil or stretched_point == nil 
      then return end      
    local src_array_size = src_array.get_alloc()
    local out_arr = reaper.new_array(src_array_size)    
    local src_arr_pt1_size = src_mid_point - 1
    local src_arr_pt2_size = src_array_size-src_mid_point + 1    
    local out_arr_pt1_size = stretched_point - 1
    local out_arr_pt2_size = src_array_size-stretched_point + 1    
    local src_arr_pt1 = reaper.new_array(src_arr_pt1_size)
    local src_arr_pt2 = reaper.new_array(src_arr_pt2_size)    
    src_arr_pt1.copy(src_array,--src, 
                            1,--srcoffs, 
                            src_arr_pt1_size,--size, 
                            1)--destoffs])  
    src_arr_pt2.copy(src_array,--src, 
                            src_mid_point,--srcoffs, 
                            src_arr_pt2_size,--size, 
                            1)--destoffs])            
    local out_arr_pt1 = F_stretch_array(src_arr_pt1, out_arr_pt1_size)
    local out_arr_pt2 = F_stretch_array(src_arr_pt2, out_arr_pt2_size)    
    out_arr.copy(out_arr_pt1,--src, 
                 1,--srcoffs, 
                 out_arr_pt1_size,--size, 
                 1)--destoffs]) 
    out_arr.copy(out_arr_pt2,--src, 
                 1,--srcoffs, 
                 out_arr_pt2_size,--size, 
                 out_arr_pt1_size + 1)--destoffs]) 
                 
    return   out_arr               
  end  


-----------------------------------------------------------------------          
  function ENGINE_compare_data2_alg1(ref_arr_orig, dub_arr_orig, points, window_sec) 
      local st_search, end_search
      
      if ref_arr_orig == nil then return end
      if dub_arr_orig == nil then return end
      if points == nil then return end
      
      local ref_arr_size = ref_arr_orig.get_alloc()  
      local dub_arr_size = dub_arr_orig.get_alloc() 
      
      ref_arr = reaper.new_array(ref_arr_size)
      for i = 1, ref_arr_size do ref_arr[i] = ref_arr_orig[i]^data2.scaling_pow end
      
      dub_arr = reaper.new_array(dub_arr_size)
      for i = 1, dub_arr_size do dub_arr[i] = dub_arr_orig[i]^data2.scaling_pow end
      
      
      local sm_table = {}    
          
      search_area = math.floor(data2.search_area / window_sec)
              
      -- get blocks
        local block_ids = {}
        for i = 1, dub_arr_size do
          if points[i] == 1 then 
            block_ids[#block_ids+1] = {['orig']=i} end
        end    
        
      -- loop blocks
        for i = 1, #block_ids - 2 do
          -- create fixed block
            
            point1 = block_ids[i].orig
            point2 = block_ids[i+1].orig
            point3 = block_ids[i+2].orig
            
              if i >= 1 then
                P1_diff = 0
                P2_fant = point2-point1+1
                P3_fant = point3 - point1 + 1 -- arr size
                fantom_arr = reaper.new_array(P3_fant)            
                fantom_arr.copy(dub_arr,--src, 
                                point1,--srcoffs, 
                                P3_fant,--size, 
                                1)--destoffs])
              end
         
                            
          -- loop possible positions
            local min_block_len = 3
            search_pos_start = P2_fant - search_area
            if search_pos_start < min_block_len then search_pos_start = min_block_len end
            search_pos_end = P2_fant + search_area
            if search_pos_end > P3_fant - min_block_len then search_pos_end = P3_fant - min_block_len end    
            if (search_pos_end-search_pos_start+1) > min_block_len then
              
              diff = reaper.new_array(search_pos_end-search_pos_start+1)
              for k = search_pos_start, search_pos_end do
                fantom_arr_stretched = F_stretch_array2(fantom_arr, P2_fant, k)
                diff[k - search_pos_start+1] = F_find_arrays_com_diff(ref_arr, point1, fantom_arr_stretched)
              end
              block_ids[i+1].stretched = F_find_min_value(diff) + search_pos_start 
                - 1 - P1_diff + point1
              sm_table[#sm_table+1] =  
                    {block_ids[i+1].stretched *  window_sec,
                     (-1+block_ids[i+1].orig) * window_sec}
            end
            fantom_arr.clear()
        end -- end loop blocks
        
      return sm_table
  end   

----------------------------------------------------------------------- 
  --[[ check by every block with relative diff / k / ref_rms
  function ENGINE_compare_data2_alg3_test(ref_arr_orig, dub_arr_orig, points, window_sec) 
      local st_search, end_search
      
      if ref_arr_orig == nil then return end
      if dub_arr_orig == nil then return end
      if points == nil then return end
      
      local ref_arr_size = ref_arr_orig.get_alloc()  
      local dub_arr_size = dub_arr_orig.get_alloc()       
      ref_arr = reaper.new_array(ref_arr_size)
      for i = 1, ref_arr_size do ref_arr[i] = ref_arr_orig[i]^data2.scaling_pow end      
      dub_arr = reaper.new_array(dub_arr_size)
      for i = 1, dub_arr_size do dub_arr[i] = dub_arr_orig[i]^data2.scaling_pow end
            
      local sm_table = {}    
      search_area = math.floor(data2.search_area / window_sec)
              
      -- get blocks
         block_ids = {}
        for i = 1, dub_arr_size do
          if points[i] == 1 then 
            block_ids[#block_ids+1] = {['orig']= i } end
        end    
      
      -- loop blocks
        block_ids[1].str = 1
        for i = 2, #block_ids - 1 do
          block_start = block_ids[i-1].orig
          block_start_str = block_ids[i-1].str
          block_end = block_ids[i].orig
          block2_end = block_ids[i+1].orig
          fantom_arr_sz = block_end - block_start
        
          fantom_arr = reaper.new_array(fantom_arr_sz)            
          fantom_arr.copy(dub_arr,--src, 
                              block_start,--srcoffs, 
                              fantom_arr_sz,--size, 
                              1)--destoffs])

          min_block_len = 3
          search_start = fantom_arr_sz - search_area
            if search_start < min_block_len then search_start = min_block_len end
          search_end = fantom_arr_sz + (block_start-block_start_str) + search_area
            if search_end + block_start > dub_arr_size - min_block_len then 
              search_end = dub_arr_size - min_block_len - block_start end                              
            
          diff_t = { }
          for k = search_start, search_end do
            fantom_arr_stretched = F_stretch_array(fantom_arr, k)
            diff, ref_rms = F_find_arrays_com_diff(ref_arr, block_start_str, fantom_arr_stretched,true)
            diff_t[#diff_t+1] = diff/k
          end
          
          --msg(table.concat(diff_t, '\n'))
          
          id_diff = F_find_min_value(diff_t)
          
          block_ids[i].str = id_diff + search_start + block_start_str
          sm_table[#sm_table+1] =  {
            block_ids[i].str * window_sec,
            (-1+block_ids[i].orig) * window_sec }
                                       
          fantom_arr.clear()
        end
        
      return sm_table       
      
  end]]
              
----------------------------------------------------------------------- 
  function ENGINE_compare_data2_alg2(ref_arr_orig, dub_arr_orig, points, window_sec) 
      local st_search, end_search
      
      if ref_arr_orig == nil then return end
      if dub_arr_orig == nil then return end
      if points == nil then return end
      
      local ref_arr_size = ref_arr_orig.get_alloc()  
      local dub_arr_size = dub_arr_orig.get_alloc()       
      ref_arr = reaper.new_array(ref_arr_size)
      for i = 1, ref_arr_size do ref_arr[i] = ref_arr_orig[i]^data2.scaling_pow end      
      dub_arr = reaper.new_array(dub_arr_size)
      for i = 1, dub_arr_size do dub_arr[i] = dub_arr_orig[i]^data2.scaling_pow end
            
      local sm_table = {}    
      search_area = math.floor(data2.search_area / window_sec)
              
      -- get blocks
         block_ids = {}
        for i = 1, dub_arr_size do
          if points[i] == 1 then 
            block_ids[#block_ids+1] = {['orig']=i} end
        end    
        
      -- loop blocks
        block_ids[1].str = 1
        for i = 2, #block_ids - 1 do
        -- create fixed block            
          point1 = block_ids[i-1].str
          point1_orig = block_ids[i-1].orig
          point2 = block_ids[i].orig
          point3 = block_ids[i+1].orig
          
          search_point = point2 - point1
          
        -- form fantom array
          fantom_arr_sz = point3 - point1          
          fantom_arr = reaper.new_array(fantom_arr_sz)          
          fantom_arr_pt1 = reaper.new_array(point2 - point1_orig)          
          fantom_arr_pt1.copy(dub_arr,--src,
                              point1_orig,--srcoffs,
                              point2 - point1_orig,--size,
                              1)--destoffs]) 
          fantom_arr_pt1_str = F_stretch_array(fantom_arr_pt1, point2-point1)                        
          fantom_arr.copy(fantom_arr_pt1_str,--src,
                          1,--srcoffs,
                          point2-point1,--size,
                          1)--destoffs])            
          fantom_arr.copy(dub_arr,--src,
                          point2,--srcoffs,
                          point3-point2,--size,
                          point2-point1+1)--destoffs])
          
        -- loop possible positions
          filter_area_wind = math.floor(data2.filter_area / window_sec)
          min_block_len = 20
          if min_block_len > filter_area_wind then min_block_len = filter_area_wind - 3 end
          search_start = search_point - search_area
            if search_start < min_block_len then search_start = min_block_len end
          search_end = search_point + search_area
            if search_end > fantom_arr_sz - min_block_len then search_end = fantom_arr_sz - min_block_len end         
        
          diff_t = {}
          for k = search_start, search_end do
            fantom_arr_stretched = F_stretch_array2(fantom_arr, search_point, k)
            diff_t[#diff_t+1] = F_find_arrays_com_diff(ref_arr, point1, fantom_arr_stretched)
          end 
          id_diff = F_find_min_value(diff_t)
          if not id_diff then id_diff = 0 end -- unknown bug > 1.120
          block_ids[i].str = id_diff + search_start + point1
          sm_table[#sm_table+1] =  {
            block_ids[i].str * window_sec,
            (-1+block_ids[i].orig) * window_sec }
        end -- loop blocks
      return sm_table       
      
  end          
          --[[  
          if i == 1 then
            P2_fant = point2 - point1 + 1
            P3_fant = point3 - point1 + 1 -- arr size
            fantom_arr = reaper.new_array(P3_fant)            
            fantom_arr.copy(dub_arr,--src, 
                                point1,--srcoffs, 
                                P3_fant,--size, 
                                1)--destoffs])
              
              
            -- 
            min_bl_len = 3
            min_search_diff = 3
            search_start = P2_fant - search_area
              if search_start < min_bl_len then search_start = min_bl_len end
            search_end = P2_fant + search_area
              if search_end > P3_fant - min_bl_len then search_end = P3_fant - min_bl_len end    
            if search_end-search_start+1 > min_search_diff then
              diff_t = {}
              for k = search_start, search_end do
                fantom_arr_stretched = F_stretch_array2(fantom_arr, P2_fant, k)
                diff_t[#diff_t+1] = F_find_arrays_com_diff(ref_arr, point1, fantom_arr_stretched)
              end
              id_diff = F_find_min_value(diff_t)
              block_ids[i+1].str = id_diff + search_start - 4 + point1
              sm_table[#sm_table+1] =  {
               block_ids[i+1].str * window_sec,
               (-1+block_ids[i+1].orig) * window_sec }
             else
              sm_table[#sm_table+1] =  {
               block_ids[i+1].orig * window_sec,
               block_ids[i+1].orig * window_sec }
              block_ids[i+1].str = block_ids[i+1].orig
            end
          end -- if first block
          
          if i > 1 and i < #block_ids - 2 then
            last_block_diff = block_ids[i].orig - block_ids[i].str
            
            P2_fant = point2 - point1 + 1
            P3_fant = point3 - point1 + 1 -- arr size
            P2_fant_str = P2_fant + last_block_diff  
            P3_fant_str = P3_fant + last_block_diff  
            
            fantom_arr = reaper.new_array(P3_fant_str)
            fantom_arr_pt1 = reaper.new_array(P2_fant)
            fantom_arr_pt1.copy(dub_arr,--src,
                                point1,--srcoffs,
                                P2_fant,--size,
                                1)--destoffs])    
            if P2_fant_str > 3 then
              fantom_arr_pt1_str = F_stretch_array(fantom_arr_pt1, P2_fant_str)
              
  
              fantom_arr.copy(fantom_arr_pt1_str,--src,
                              1,--srcoffs,
                              P2_fant_str,--size,
                              1)--destoffs])
  
              fantom_arr.copy(dub_arr,--src,
                              point2,--srcoffs,
                              point3-point2+1,--size,
                              P2_fant_str)--destoffs])
              
              
              -- loop possible positions
              min_bl_len = 3
              min_search_diff = 3
              search_start = P2_fant_str - search_area
                if search_start < min_bl_len then search_start = min_bl_len end
              search_end = P2_fant_str + search_area
                if search_end > P3_fant_str - min_bl_len then search_end = P3_fant_str - min_bl_len end    
              if search_end-search_start+1 > min_search_diff then
                diff_t = {}
                if search_end > P3_fant_str - min_bl_len then search_end = P3_fant_str - min_bl_len end
                for k = search_start, search_end do
                  fantom_arr_stretched = F_stretch_array2(fantom_arr, P2_fant, k)  
                  diff_t[#diff_t+1] = F_find_arrays_com_diff(ref_arr, block_ids[i].str, fantom_arr_stretched)
                end
                id_diff = F_find_min_value(diff_t)
                block_ids[i+1].str = id_diff + search_start + point1 -1--block_ids[i].str
                sm_table[#sm_table+1] =  {
                 block_ids[i+1].str * window_sec,
                 block_ids[i+1].orig * window_sec }
               else
                sm_table[#sm_table+1] =  {
                 block_ids[i+1].orig * window_sec,
                 block_ids[i+1].orig * window_sec }
                block_ids[i+1].str = block_ids[i+1].orig           
              end
            else
             sm_table[#sm_table+1] =  {
              block_ids[i+1].orig * window_sec,
              block_ids[i+1].orig * window_sec }
             block_ids[i+1].str = block_ids[i+1].orig  
            end
          end -- other blocks
          ]]
  
                                        
-----------------------------------------------------------------------   
  function ENGINE_set_stretch_markers2(take_id, str_mark_table, val)
    if str_mark_table == nil then return nil end
    if takes_t ~= nil and takes_t[take_id] ~= nil then
      local take = reaper.SNM_GetMediaItemTakeByGUID(0, takes_t[take_id].guid)
      if take ~= nil then       
        
        reaper.DeleteTakeStretchMarkers(take, 0, #str_mark_table + 1)
       
        reaper.SetTakeStretchMarker(take, -1, 0, takes_t[take_id].offset)
        for i = 1, #str_mark_table do
          
          set_pos = str_mark_table[i][1]-(takes_t[take_id].pos-takes_t[1].pos)
          src_pos = str_mark_table[i][2]-(takes_t[take_id].pos-takes_t[1].pos) + takes_t[take_id].offset
          set_pos = src_pos - takes_t[take_id].offset - ((src_pos - takes_t[take_id].offset) - set_pos)*val
          
          
          if last_src_pos ~= nil and last_set_pos ~= nil then
            -- check for negative stretch markers
            if (src_pos - last_src_pos) / (set_pos - last_set_pos ) > 0 then
              reaper.SetTakeStretchMarker(take, -1, set_pos,src_pos)             
              last_src_pos = src_pos
              last_set_pos = set_pos
            end
           else
            reaper.SetTakeStretchMarker(take, -1, set_pos,src_pos)             
            last_src_pos = src_pos
            last_set_pos = set_pos
          end
          
        end
        reaper.SetTakeStretchMarker(take, -1, takes_t[take_id].len)
        
      end
    end
    reaper.UpdateArrange()
  end        
----------------------------------------------------------------------- 
  function GUI_item_display(objects, gui, xywh, reaperarray, is_ref, pointsarray, col_peaks) local arr_size
    
    local x=xywh[1]
    local y=xywh[2]
    local w=xywh[3]
    local h=xywh[4]
    local drawscale = 0.9  
      
      -- draw item back gradient from buf 7
       gfx.a = 0.4
       gfx.blit(7, 1, 0, -- backgr
                0,0,objects.main_w, objects.main_h,
                xywh[1],xywh[2],xywh[3], xywh[4], 0,0)
                
      if reaperarray ~= nil then
        arr_size = reaperarray.get_alloc()
        --
        
      -- draw envelope  
          gfx.a = 0.7
          F_Get_SSV(gui.color.white, true) 
          gfx.x = x
          gfx.y = y
          for i=1, arr_size-1, 1 do
            local data_t_it = reaperarray[i]
            local data_t_it2 = reaperarray[i+1]
            local const = 0
            local st_x = x+i*w/arr_size
            local end_x = x+(i+1)*w/arr_size+const              
            if end_x > x+w then end_x = x+w end
            if end_x < x then end_x = x end
            if is_ref then 
              gfx.a = 0.2
              gfx.triangle(st_x,    y+h-h*data_t_it*drawscale,
                         end_x,y+h-h*data_t_it2*drawscale,
                         end_x,y+h,
                         st_x,    y+h )
             else
              gfx.a = 0.8
              F_Get_SSV(gui.color.white, true) 
              gfx.triangle(st_x,    y+h*data_t_it*drawscale,
                           end_x,y+h*data_t_it2*drawscale,
                           end_x,y,
                           st_x,    y )   
              gfx.a = 0.2
              F_Get_SSV(gui.color[col_peaks])
              gfx.lineto(x+(i+1)*w/arr_size, y-h*data_t_it2^data2.scaling_pow*drawscale)
            end                     
            
            if is_ref then 
              gfx.a = 0.05
              gfx.triangle(st_x,    y+h-h*data_t_it^data2.scaling_pow*drawscale,
                         end_x,y+h-h*data_t_it^data2.scaling_pow*drawscale,
                         end_x,y+h,
                         st_x,    y+h )
             else
              gfx.a = 0.05
              F_Get_SSV(gui.color.white, true) 
              gfx.triangle(st_x,    y+h*data_t_it^data2.scaling_pow*drawscale,
                           end_x,y+h*data_t_it2^data2.scaling_pow*drawscale,
                           end_x,y,
                           st_x,    y )  
            end 
                        
                     
          end -- envelope building
        end
          
          gfx.x,gfx.y = x,y
          gfx.blurto(x+w,y+h)
          gfx.muladdrect(x-1,y,w+2,h,
            1,--mul_r,
            1.0,--mul_g,
            1.0,--mul_b,
            1.5,--mul_a,
            0,--add_r,
            0,--add_g,
            0,--add_b,
            0)--add_a)
             
      if not is_ref then
        -- draw sep points
          if pointsarray ~= nil then
            local pointsarr_size = reaperarray.get_alloc(pointsarray)
            local tri_h = 5
            local tri_w = tri_h
            F_Get_SSV(gui.color.green, true) 
            gfx.a = 0.4
            for i = 1, pointsarr_size-1 do
              if pointsarray[i] == 1 then
                gfx.line(x + i*w/pointsarr_size,
                          y,
                          x + i*w/pointsarr_size,
                          y+h - tri_h - 1)
                gfx.triangle(x + i*w/pointsarr_size, y+h-tri_h,
                             x + i*w/pointsarr_size, y+h,
                             x + i*w/pointsarr_size + tri_w, y+h)
              end
            end 
            
          end --pointsarray ~= nil then
          
        -- draw gate threshold
          F_Get_SSV(gui.color.black, true)
          gfx.a = 0.5
          gfx.line(x, y+h*data2.threshold*drawscale,
                   x+w, y+h*data2.threshold*drawscale)
          F_Get_SSV(gui.color.green_dark, true)
          gfx.a = 0.5
          gfx.rect(x, y, w, h*data2.threshold*drawscale)
      end    
          

      -- back
        gfx.a = 0.4
        gfx.blit(3, 1, 0, --backgr
          0,0,objects.main_w, objects.main_h,
          xywh[1],xywh[2],xywh[3],xywh[4], 0,0) 
                    
        
  end
  
        ----------------------------------------------------------------------- 

        -----------------------------------------------------------------------         
        function GUI_button2(objects, gui, xywh, name, issel, font, text_alpha, color_str) local w1_sl_a
          gfx.y,gfx.x = 0,0         
          -- frame
            gfx.a = 0.1
            F_Get_SSV(gui.color.white, true)
            gfx.rect(xywh[1],xywh[2],xywh[3], xywh[4], 0 , gui.aa)
            
          -- back
            if issel then gfx.a = 0.7 else gfx.a = 0.3 end
            gfx.blit(3, 1, 0, --backgr
              0,0,objects.main_w, objects.main_h,
              xywh[1],xywh[2],xywh[3],xywh[4], 0,0) 
            
          -- txt              
            
            gfx.setfont(1, gui.fontname, font)
            gfx.a = text_alpha
            F_Get_SSV(gui.color[color_str], true)
            local measurestrname = gfx.measurestr(name)
            local x0 = xywh[1] + (xywh[3] - measurestrname)/2
            local y0 = xywh[2] + (xywh[4] - gui.b_sel_fontsize)/2
            gfx.x, gfx.y = x0,y0 
            gfx.drawstr(name)  
        end        

                
        ----------------------------------------------------------------------- 
        function GUI_slider(objects, gui,  xywh, val, alpha, col, takes_t)
          if val == nil then val = 0 end
          gfx.y,gfx.x = 0,0         
          
          -- frame
            gfx.a = 0.1 * alpha
            F_Get_SSV(gui.color.white, true)
            gfx.rect(xywh[1],xywh[2],xywh[3], xywh[4], 1 , gui.aa) 
            
          -- center line
            gfx.a = 0.5 * alpha
            F_Get_SSV(gui.color[col], true)
            local sl_w = 3
            gfx.rect(xywh[1],xywh[2]+ (xywh[4]- sl_w) / 2,xywh[3], sl_w, 1 , gui.aa)  
          
          local handle_w = 20  
          if takes_t ~= nil and takes_t[2] ~= nil then
            -- blit grad   
              local x_offs = xywh[1] + (xywh[3] - handle_w) * val            
              gfx.a = 0.8 * alpha
              gfx.blit(3, 1, math.rad(180), --backgr
                0,0,objects.main_w, objects.main_h,
                x_offs,xywh[2],handle_w/2,xywh[4], 0,0)
              gfx.blit(3, 1, math.rad(0), --backgr
                0,0,objects.main_w, objects.main_h,
                x_offs+handle_w/2,xywh[2],handle_w/2,xywh[4], 0,0) 
            end
              
          -- grid
            local gr_h = 20
            for i = 0, 1, 0.1 do
              gfx.a = 0.3 * alpha
              F_Get_SSV(gui.color.white, true)
              gfx.line(handle_w/2 + xywh[1] + (xywh[3]-handle_w) * i, xywh[2] + xywh[4]/2 - gr_h*i - 1,
                       handle_w/2 + xywh[1] + (xywh[3]-handle_w) * i, xywh[2] + xywh[4]/2 + gr_h*i-1 )
            end            
        end
        
----------------------------------------------------------------------- 
        function GUI_text(xywh, gui, objects, f_name, f_size, name, has_frame)
          gfx.setfont(1, f_name, f_size) 
          local measurestrname = gfx.measurestr(name)
          local x0 = xywh[1] + (xywh[3] - measurestrname)/2
          local y0 = xywh[2]+(xywh[4]-gfx.texth)/2
          
          if has_frame then 
            -- text back
            gfx.a = 0.9
            F_Get_SSV(gui.color.back, true)
            gfx.rect(x0-objects.x_offset,y0,measurestrname+objects.x_offset*2,gfx.texth)  
          end
          
          -- text
          gfx.x, gfx.y = x0,y0 
          gfx.a = 0.9
          F_Get_SSV(gui.color.white, true)
          gfx.drawstr(name)
          
            
        end
----------------------------------------------------------------------- 
  function gfx_rect(x,y,w,h)
    gfx.x, gfx.y = x,y
    gfx.line(x,y, x+w-1, y)
    gfx.line(x+w,y, x+w, y+h-2)
    gfx.line(x+w,y+h-1, x-1, y+h-1)
    gfx.line(x-1,y+h-2, x-1, y)
  end
  
----------------------------------------------------------------------- 
       
            function GUI_selector(xywh,col,val,b1,b2 )     
              if not val then return end        
              F_Get_SSV(col, true)
              gfx.a = 0.3
              
              local x,y,w,h = xywh[1],
                        xywh[2],
                        xywh[3],
                        xywh[4]
              gfx_rect(x,y,w,h)
                       
              gfx.a = 0.4
              gfx.rect(xywh[1] + 2,
                       xywh[2]+2+
                       (xywh[4]/2-2)*val,
                       xywh[3]-4,
                       (xywh[4]-4)/2,1,1)
              
              gfx.a = 1
              gfx.x = xywh[1] + (xywh[3]- gfx.measurestr(b1)) /2
              gfx.y = xywh[2]   +2 
              gfx.drawstr(b1)
              
              gfx.a = 1
              gfx.x = xywh[1] + (xywh[3]- gfx.measurestr(b2)) /2
              gfx.y = xywh[2] + 1+ xywh[4] /2
              gfx.drawstr(b2)              
            end
                    
-----------------------------------------------------------------------          
  function GUI_knob(objects, xywh,gui, val, text,text_val, col, is_active)
    if is_active == 0 then is_active = 0.3 end
    if val == nil then val = 0 end 
    x,y ,w, h = xywh[1],xywh[2],xywh[3],xywh[4]
    arc_r = w/2 * 0.8
    ang_gr = 120
    ang_val = math.rad(-ang_gr+ang_gr*2*val)
    ang = math.rad(ang_gr)
    
    -- back
      gfx.a = 0.01+0.3*is_active
      F_Get_SSV(gui.color[col], true)
      gfx.rect(x,y ,w, h, 1)
      gfx.a = 0.01
      gfx.blit(7, 1, math.rad(180), -- backgr
               0,0,objects.main_w, objects.main_h,
               x,y ,w, h, 0,0)
      
      -- arc back
        for i = 0, 3, 0.4 do
          if is_active then gfx.a = 0.03 else gfx.a = 0.005  end
          F_Get_SSV(gui.color.white)
          
          -- why THE HELL original gfx.arc() looks like SHIT? -- 
          
          gfx.arc(x+w/2-1,y+h/2+1,arc_r-i,    math.rad(-ang_gr),math.rad(-90),    gui.aa)
          gfx.arc(x+w/2-1,y+h/2-1,arc_r-i,    math.rad(-90),math.rad(0),    gui.aa)
          gfx.arc(x+w/2+1,y+h/2-1,arc_r-i,    math.rad(0),math.rad(90),    gui.aa)
          gfx.arc(x+w/2+1,y+h/2+1,arc_r-i,    math.rad(90),math.rad(ang_gr),    gui.aa)
        end
                
      gfx.a = 0.5
      local ang_val = math.rad(-ang_gr+ang_gr*2*val)
      F_Get_SSV(gui.color[col], true)
      if is_active == 1 then --gfx.a = 0.4 else gfx.a = 0.03 end
        for i = 0, 3, 0.4 do
            if ang_val < math.rad(-90) then 
              gfx.arc(x+w/2-1,y+h/2+1,arc_r-i,    math.rad(-ang_gr),ang_val, gui.aa)
             else
              if ang_val < math.rad(0) then 
                gfx.arc(x+w/2-1,y+h/2+1,arc_r-i,    math.rad(-ang_gr),math.rad(-90), gui.aa)
                gfx.arc(x+w/2-1,y+h/2-1,arc_r-i,    math.rad(-90),ang_val,    gui.aa)
               else
                if ang_val < math.rad(90) then 
                  gfx.arc(x+w/2-1,y+h/2+1,arc_r-i,    math.rad(-ang_gr),math.rad(-90), gui.aa)
                  gfx.arc(x+w/2-1,y+h/2-1,arc_r-i,    math.rad(-90),math.rad(0),    gui.aa)
                  gfx.arc(x+w/2+1,y+h/2-1,arc_r-i,    math.rad(0),ang_val,    gui.aa)
                 else
                  if ang_val < math.rad(ang_gr) then 
                    gfx.arc(x+w/2-1,y+h/2+1,arc_r-i,    math.rad(-ang_gr),math.rad(-90), gui.aa)
                    gfx.arc(x+w/2-1,y+h/2-1,arc_r-i,    math.rad(-90),math.rad(0),    gui.aa)
                    gfx.arc(x+w/2+1,y+h/2-1,arc_r-i,    math.rad(0),math.rad(90),    gui.aa)
                    gfx.arc(x+w/2+1,y+h/2+1,arc_r-i,    math.rad(90),ang_val,    gui.aa)
                   else
                    gfx.arc(x+w/2-1,y+h/2+1,arc_r-i,    math.rad(-ang_gr),math.rad(-90),    gui.aa)
                    gfx.arc(x+w/2-1,y+h/2-1,arc_r-i,    math.rad(-90),math.rad(0),    gui.aa)
                    gfx.arc(x+w/2+1,y+h/2-1,arc_r-i,    math.rad(0),math.rad(90),    gui.aa)
                    gfx.arc(x+w/2+1,y+h/2+1,arc_r-i,    math.rad(90),math.rad(ang_gr),    gui.aa)                  
                  end
                end
              end                
            end
          end
        end
               
    -- text
      gfx.a = 0.05+0.95*is_active
      gfx.setfont(1, gui.fontname, gui.knob_txt)
      text_len = gfx.measurestr(text)
      gfx.x, gfx.y = x+(w-text_len)/2,y+h-gfx.texth-2
      gfx.drawstr(text)

    -- text
      gfx.setfont(1, gui.fontname, gui.knob_txt-2)
      text_len = gfx.measurestr(text_val)
      gfx.x, gfx.y = x+(w-text_len)/2,y+(h-gfx.texth)/2
      gfx.drawstr(text_val)    
    
  end
                
-----------------------------------------------------------------------   
  function A4_DEFINE_GUI_buffers(gui, obj)
    local is_sel
    local OS = reaper.GetOS()
    update_gfx_minor = true
    
      ----------------------------------------------------------------------- 
          
    -- buffers
      -- 1 main back
      -- 2 select windows
      -- 3 button back gradient
      -- 4 wind 1
      -- 5 wait window
      -- 6 envelopes
      -- 7 item envelope gradient
      -- 8 about
      -- 9 knobs
        
        
    -- buf1 background   
      if update_gfx then    
        --fdebug('DEFINE_GUI_buffers_1-mainback')  
        gfx.dest = 1
        gfx.setimgdim(1, -1, -1)  
        gfx.setimgdim(1, obj.main_w, obj.main_h+obj.set_wind_h) 
        gfx.a = 0.92
        F_Get_SSV(gui.color.back, true)
        gfx.rect(0,0, obj.main_w, obj.main_h+obj.set_wind_h,1)
      end
    
    
    -- buf3 -- buttons back gradient
      if update_gfx then    
        --fdebug('DEFINE_GUI_buffers_3-buttons back')  
        gfx.dest = 3
        gfx.setimgdim(3, -1, -1)  
        gfx.setimgdim(3, obj.main_w, obj.main_h)  
           gfx.a = 1
           local r,g,b,a = 0.9,0.9,1,0.6
           gfx.x, gfx.y = 0,0
           local drdx = 0.00001
           local drdy = 0
           local dgdx = 0.0001
           local dgdy = 0.0003     
           local dbdx = 0.00002
           local dbdy = 0
           local dadx = 0.0003
           local dady = 0.0004       
           gfx.gradrect(0,0,obj.main_w, obj.main_h, 
                        r,g,b,a, 
                        drdx, dgdx, dbdx, dadx, 
                        drdy, dgdy, dbdy, dady)
      end  
  
  
    -- buf 4 -- general buttons / sliders / info
      if update_gfx_minor then
        gfx.dest = 4
        gfx.setimgdim(4, -1, -1)  
        gfx.setimgdim(4, obj.main_w, obj.main_h+obj.set_wind_h) 
        
        -- compact buttons
          if data.current.compact_view == 0 then mode_name = '+' else mode_name = '-' end
          GUI_button2(obj, gui, obj.b_setup, mode_name, mouse.context == 'w1_settings_b', gui.b_sel_fontsize, 0.7, 'white')
          GUI_button2(obj, gui, obj.b_get, 'Get', mouse.context == 'w1_get_b', gui.b_sel_fontsize, 0.8, 'green') 
              
        -- full view right buttons    
          GUI_button2(obj, gui, obj.pref_b1,'Presets', mouse.context == 'pref1', gui.b_sel_fontsize, 0.8, 'green')
          GUI_button2(obj, gui, obj.pref_b2,'About', mouse.context == 'pref2', gui.b_sel_fontsize, 0.8, 'green')
          GUI_button2(obj, gui, obj.pref_b3,'Donate',mouse.context == 'pref3', gui.b_sel_fontsize, 0.8, 'green')
                          
        -- slider                   
          GUI_slider(obj, gui, obj.b_slider, w1_slider, 1,'green', takes_t)
        
        -- display  
          if takes_t ~= nil and takes_t[2] ~= nil then
            -- take names
              if mouse.context == 'w1_disp' then
                GUI_text(obj.disp_ref_text, gui, obj,gui.fontname, gui.b_takenames_fontsize, 'Reference: '..takes_t[1].name:sub(0,30), true)              
                local d_name = 'Dub: '
                if takes_t[3] ~= nil then d_name = 'Dubs ('..math.floor(data2.current_take-1)..'/'..(#takes_t - 1)..'): ' end
                GUI_text(obj.disp_dub_text, gui, obj, gui.fontname, gui.b_takenames_fontsize, d_name..takes_t[data2.current_take].name:sub(0,30), true)
              end
            -- display cursor position
              gfx.a = 0.9
              F_Get_SSV(gui.color.red, true)
              gfx.line(F_limit(obj.disp[1] + obj.disp[3] / takes_t[1].len * (data2.play_pos - takes_t[1].pos), 
                        obj.disp[1], obj.disp[1] + obj.disp[3]), obj.disp[2],
                       F_limit(obj.disp[1] + obj.disp[3] / takes_t[1].len * (data2.play_pos - takes_t[1].pos), 
                        obj.disp[1], obj.disp[1] + obj.disp[3]), obj.disp[2]+obj.disp[4])
          end
      end


    -- buf 7 -- item envelope gradient
      if update_gfx then 
          gfx.dest = 7  
          gfx.setimgdim(7, -1, -1)
          gfx.setimgdim(7, obj.main_w, obj.main_h)
          gfx.gradrect(0,0, obj.main_w, obj.main_h, 1,1,1,0.9, 0,0,0,0.00001, 0,0,0,-0.005)
      end
      
      
    -- buf 6 -- envelopes 
      if update_gfx then 
          --fdebug('DEFINE_GUI_buffers_6-envelopes')      
          gfx.dest = 6
          gfx.setimgdim(6, -1, -1)  
          gfx.setimgdim(6, obj.main_w, obj.main_h)
          GUI_item_display(obj, gui, obj.disp_ref , takes_arrays[1], true,takes_points[1], 'blue' ) 
          GUI_item_display(obj, gui, obj.disp_dub , takes_arrays[data2.current_take], false , takes_points[data2.current_take], 'blue')
      end
    
    
    -- buf 5 -- wait
      if trig_process ~= nil and trig_process == 1 then
        gfx.dest = 5
        gfx.setimgdim(5, -1, -1)  
        gfx.setimgdim(5, obj.main_w, obj.main_h+obj.set_wind_h) 
        gfx.a = 0.93
        F_Get_SSV(gui.color.back, true)
        gfx.rect(0,0, obj.main_w, obj.main_h+obj.set_wind_h,1)  
        F_Get_SSV(gui.color.white, true)    
        local str = 'Analyzing takes. Please wait...'
        gfx.setfont(1, gui.fontname, gui.fontsize)
        gfx.x = (obj.main_w - gfx.measurestr(str))/2
        gfx.y = (obj.main_h-gfx.texth)/2
        gfx.drawstr(str)
      end
      
  -- buf 9 -- knobs
    if update_gfx then 
      --fdebug('DEFINE_GUI_buffers_9-knobs')      
      gfx.dest = 9
      gfx.setimgdim(9, -1, -1)  
      gfx.setimgdim(9, obj.main_w, obj.main_h+obj.set_wind_h)
          
      -- green knobs
        GUI_knob(obj, obj.knob1,gui, data.current.scaling_pow_norm, 'Scaling', data.current.scaling_pow_norm, 'green',1)
        GUI_knob(obj, obj.knob2,gui, data.current.threshold_norm, 'Threshold',data2.threshold, 'green',1) 
        GUI_knob(obj, obj.knob3,gui, data.current.rise_area_norm, 'Rise Area',math.floor(data2.rise_area * 1000)..'ms', 'green', 1)   
        GUI_knob(obj, obj.knob4,gui, data.current.risefall_norm, 'Rise/Fall',data2.risefall, 'green', 1)     
        GUI_knob(obj, obj.knob5,gui, data.current.risefall2_norm, 'Rise/Fall 2',data2.risefall2, 'green', 1)                                     
        GUI_knob(obj, obj.knob6,gui, data.current.filter_area_norm, 'Filter Area',math.floor(data2.filter_area * 1000)..'ms', 'green', 1)           
        -- frame
        gfx.a = 0.5
        F_Get_SSV(gui.color.green_dark, true)
        gfx_rect(obj.pref_rect1[1],obj.pref_rect1[2],obj.pref_rect1[3],obj.pref_rect1[4],0) 
      -- red knob   
        GUI_knob(obj, obj.knob7, gui, data.current.search_area_norm, 'Search area',math.floor(data2.search_area * 1000)..'ms', 'red', 1)            
        --frame
        gfx.a = 0.5
        F_Get_SSV(gui.color.red, true)
        gfx_rect(obj.pref_rect2[1],obj.pref_rect2[2],obj.pref_rect2[3],obj.pref_rect2[4],0)  
      -- selectors
        GUI_selector(obj.selector,gui.color.blue,data.current.mode,'RMS', 'FFT') 
        GUI_selector(obj.selector2,gui.color.blue,data.current.alg,'Algo 1','Algo 2')
        -- frame 
        gfx.a = 0.5
        F_Get_SSV(gui.color.blue, true)
        gfx_rect(obj.pref_rect3[1],obj.pref_rect3[2],obj.pref_rect3[3],obj.pref_rect3[4],0) 
      -- blue knobs 
        local bin = 22050/data2.fft_size
        GUI_knob(obj, obj.knob9,gui, data.current.custom_window_norm, 'RMS wind.', math.floor(data2.custom_window * 1000)..'ms', 'blue', math.abs(1-data.current.mode))
        GUI_knob(obj, obj.knob10,gui, data.current.fft_size_norm, 'FFT size',data2.fft_size, 'blue', math.abs(data.current.mode))
        GUI_knob(obj, obj.knob11,gui, data.current.fft_HP_norm, 'HP',math.floor((data2.fft_HP-1)*bin)..'Hz', 'blue', math.abs(data.current.mode))            
        GUI_knob(obj, obj.knob12,gui, data.current.fft_LP_norm, 'LP',math.floor((data2.fft_LP-1)*bin)..'Hz', 'blue', math.abs(data.current.mode))                      
        GUI_knob(obj, obj.knob13,gui, data.current.smooth_norm, 'Smooth',(data2.smooth*100)..'%', 'blue', 1)  
    end    
    
      
    gfx.dest = -1   
    gfx.x,gfx.y = 0,0
    gfx.a = 1
    
    gfx.blit(1, 1, 0, -- backgr
          0,0,obj.main_w, obj.main_h+obj.set_wind_h,
          0,0,obj.main_w, obj.main_h+obj.set_wind_h, 0,0)           
    gfx.blit(6, 1, 0, -- main window  static
            0,0,obj.main_w, obj.main_h,
            0,0,obj.main_w, obj.main_h, 0,0) 
    gfx.blit(4, 1, 0, -- main window dynamic
            0,0,obj.main_w, obj.main_h+obj.set_wind_h,
            0,0,obj.main_w, obj.main_h+obj.set_wind_h, 0,0) 
    gfx.blit(9, 1, 0, -- main window dynamic
            0,0,obj.main_w, obj.main_h+obj.set_wind_h,
            0,0,obj.main_w, obj.main_h+obj.set_wind_h, 0,0)                        
        
    if trig_process ~= nil and trig_process == 1 then
        gfx.blit(5, 1, 0, --wait
            0,0,obj.main_w, obj.main_h+obj.set_wind_h,
            0,0,obj.main_w, obj.main_h+obj.set_wind_h, 0,0)   
    end
    
    
    if run_about then
      GUI_run_about(obj, gui)
    end
 
              
    update_gfx = false
    gfx.update()
  end  
-----------------------------------------------------------------------    
  function GUI_run_about(obj, gui)
    
    
    
    gfx.a = 0.88
    F_Get_SSV(gui.color.black, true)
    gfx.rect(       0,--x,
                    0, -- y,
                    obj.main_w, --w,
                    obj.main_h+obj.set_wind_h, --h,
                    1)
                    
    GUI_text(obj.about_b0, gui, obj,'Calibri' , 35, 'MPL Align Takes', false)
    
    GUI_button2(obj, gui, obj.about_b1, 'How to use', mouse.context == 'about_b1', gui.b_sel_fontsize, 0.7, 'white')
    GUI_button2(obj, gui, obj.about_b6, 'Parameters description', mouse.context == 'about_b6', gui.b_sel_fontsize, 0.7, 'white')
    
    GUI_button2(obj, gui, obj.about_b2, 'VK', mouse.context == 'about_b2', gui.b_sel_fontsize, 0.7, 'green')
    GUI_button2(obj, gui, obj.about_b3, 'SoundCloud', mouse.context == 'about_b3', gui.b_sel_fontsize, 0.7, 'green')
    GUI_button2(obj, gui, obj.about_b4, 'CockosForum', mouse.context == 'about_b4', gui.b_sel_fontsize, 0.7, 'green')
    GUI_button2(obj, gui, obj.about_b5, 'RMM thread', mouse.context == 'about_b5', gui.b_sel_fontsize, 0.7, 'green')
    
    GUI_button2(obj, gui, obj.about_b7, 'Close [X]', mouse.context == 'about_b7', gui.b_sel_fontsize, 0.7, 'red')
  end
-----------------------------------------------------------------------     
  function MOUSE_match(b)
    if mouse.mx > b[1] and mouse.mx < b[1]+b[3]
      and mouse.my > b[2] and mouse.my < b[2]+b[4] then
     return true 
    end 
  end 
-----------------------------------------------------------------------    
 function F_open_URL(url)  
  local OS = reaper.GetOS()  
    if OS=="OSX32" or OS=="OSX64" then
      os.execute("open ".. url)
     else
      os.execute("start ".. url)
    end
  end
-----------------------------------------------------------------------   
  function App_def_to_currrent(preset_str, src_preset_str)
    for key in pairs (data[src_preset_str]) do 
      if data[src_preset_str][key] and type(data[src_preset_str][key]) ~= 'table' then
        local temp_t = data[src_preset_str][key]
        data[preset_str][key] = temp_t
      end
    end
  end
  -----------------------------------------------------------------------   
  function GUI_menu1(obj) local menuret  --  presets
    
    local formedstr = '|'
    local formedstr2 = ''
    for i = 1, data.count_presets do
      formedstr = formedstr
        ..'|'..'Preset '..i..' - '..data[i].name
      formedstr2 = formedstr2
        ..'|'..i..': '..data[i].name
    end
    
    local menuret1 = gfx.showmenu(
        'Restore defaults'
      ..'|>Save preset to slot'
      ..formedstr2
      
      ..'|<'..formedstr)
    
    --reset to defaults 
      if menuret1 == 1 then
        local c_view = data.current.compact_view -- preserve reset to compact view save
        App_def_to_currrent('current', 'default')
        data.current.compact_view = c_view -- preserve reset to compact view restore
        update_gfx = true 
      end
      
    -- save new preset
      if menuret1 >=2 and menuret1 <=  data.count_presets + 1 then 
        slot = math.floor(menuret1 - 1)
        local ret1, user_typed_name = reaper.GetUserInputs( 'New preset name', 1, '', data[menuret1 - 1].name )      
        if ret1 then 
          --for key in pairs (data.current) do data[slot].key = data.current.key end
          App_def_to_currrent(slot, 'current')
          data[slot].name = user_typed_name
          update_gfx = true 
        end
      end
      
    -- load
      if menuret1 >=data.count_presets + 2  then 
        for key in pairs (data.current) do data.current = data[menuret1 - data.count_presets - 1] end
        update_gfx = true 
      end      
    end
      
-----------------------------------------------------------------------    
  function GUI_menu_display(takes_t)
  
              local takesstr = ''
              for i = 1, #takes_t do
                if i == 1 then
                  takesstr = takesstr..'Reference: '..takes_t[i].name..'||'
                 else
                  takesstr = takesstr..'Dub #'..(i-1)..': '..takes_t[i].name..'|'
                end
              end
              
              local ret_menu = gfx.showmenu(takesstr)
              if ret_menu >1 then 
                data2.current_take = ret_menu
                update_gfx = true
              end 
  end

-----------------------------------------------------------------------     
  function ENGINE_clear_takes_data() 
        -- clear data
          takes_t = {}
          takes_arrays = {}
          takes_points = {}
          str_markers_t = {}
  end
-----------------------------------------------------------------------      
  function MOUSE_button(object, context)
    if MOUSE_match(object) then mouse.context = context end
    if MOUSE_match(object) and mouse.LMB_state and not mouse.last_LMB_state then return true end  
  end
-----------------------------------------------------------------------
  function MOUSE_slider(obj, context)
    if MOUSE_match(obj) and mouse.LMB_state and not mouse.last_LMB_state then mouse.context = context  end 
    if mouse.context == context then return true end
  end
----------------------------------------------------------------------- 
  function ENGINE_ProcessGet()
    local ret
    if trig_process and trig_process == 1 and not mouse.LMB_state then 
      ret = ENGINE_prepare_takes()
      if ret == 1 then
        takes_t = ENGINE_get_takes()
        if #takes_t ~= 1 and #takes_t >= 2 then
          str_markers_t = {} 
          pos_offsets = {}  
          rates = {}        
          
          for i = 1, #takes_t do 
            takes_arrays[i] = ENGINE_get_take_data(i, data.scaling_pow2) 
            if i > 1 then
              takes_points[i] = ENGINE_get_take_data_points2(takes_arrays[i],data2.global_window_sec)
              alg_num = data.current.alg + 1
              str_markers_t[i] = _G[ 'ENGINE_compare_data2_alg'..alg_num ]
                            (takes_arrays[1], 
                            takes_arrays[i], 
                            takes_points[i],
                            data2.global_window_sec )
            end
          end
        end
      end 
      
      update_gfx = true 
      trig_process = nil
      w1_slider = 0
    end    
  end
-----------------------------------------------------------------------   
  function A5_MOUSE_get(objects)
    mouse.mx = gfx.mouse_x
    mouse.my = gfx.mouse_y
    mouse.LMB_state = gfx.mouse_cap&1 == 1 
    mouse.RMB_state = gfx.mouse_cap&2 == 2 
    mouse.MMB_state = gfx.mouse_cap&64 == 64
    mouse.LMB_state_doubleclick = false
    mouse.Ctrl_LMB_state = gfx.mouse_cap&5 == 5 
    mouse.Ctrl_state = gfx.mouse_cap&4 == 4 
    mouse.Alt_state = gfx.mouse_cap&17 == 17 -- alt + LB
    mouse.wheel = gfx.mouse_wheel
    
    -------------------------------------------------------- mouse vars
    -- get value on click
      if mouse.LMB_state and not mouse.last_LMB_state then    
        mouse.last_mx_onclick = mouse.mx     mouse.last_my_onclick = mouse.my
      end    
    -- get difference is click+holding
      if mouse.last_mx_onclick and mouse.last_my_onclick then
        mouse.dx = mouse.mx - mouse.last_mx_onclick  mouse.dy = mouse.my - mouse.last_my_onclick
       else mouse.dx, mouse.dy = 0,0
      end
    
    -- reset button/knob context    
      if not mouse.LMB_state  then mouse.context = nil end
    -- reset mouseover context
      if not mouse.LMB_state  then mouse.context2 = nil end
    
    
    if not run_about then
    -------------------------------------------------------- main window
    -- items display context menu
      if takes_t and takes_t[2] and MOUSE_button(objects.disp, 'w1_disp') then
        gfx.x = mouse.mx
        gfx.y = mouse.my
        GUI_menu_display(takes_t)
      end    
    -- compact view +/- 
      if MOUSE_button(objects.b_setup, 'w1_settings_b') then            
        compact_view_trig = true
        data.current.compact_view = math.abs(data.current.compact_view-1)
      end
    -- GET button 
      if MOUSE_button(objects.b_get, 'w1_get_b') then 
        if trig_process == nil then trig_process = 1 end
      end
    -- Slider
      if takes_t and MOUSE_slider(objects.b_slider, 'w1_slider') and str_markers_t then
        w1_slider = F_limit((mouse.mx -objects.b_slider[1]) / objects.b_slider[3],0,1 )
        for i = 1, #takes_t do 
          if i == 1 then 
                 ENGINE_set_stretch_markers2(i, str_markers_t[i], 0) 
            else ENGINE_set_stretch_markers2(i, str_markers_t[i], w1_slider) 
          end
        end
      end
    ---------------------------------------------------------  config
    -- selector mode
      if MOUSE_button(objects.selector, 'selector') then
        data.current.mode = math.abs(1 - data.current.mode)
        update_gfx = true
      end 
    -- selector alg
      if MOUSE_button(objects.selector2, 'selector2') then
        data.current.alg = math.abs(1 -data.current.alg)
        update_gfx = true
      end          
          
    -- knobs  
      
    function MOUSE_knob(mouse, obj1, k, var)
      if MOUSE_match(obj1['knob'..k]) and mouse.LMB_state and not mouse.last_LMB_state 
       then 
        mouse.context2 = 'knob'..k 
        abs_var = data.current[var]
      end       
      if mouse.context2 == 'knob'..k then
        data.current[var] = F_limit(abs_var + data.current.knob_coeff * -mouse.dy,0,1)
        update_gfx = true
      end
    end 
       
      MOUSE_knob(mouse, objects, 1, 'scaling_pow_norm')
      MOUSE_knob(mouse, objects, 2, 'threshold_norm')
      MOUSE_knob(mouse, objects, 3, 'rise_area_norm') 
      MOUSE_knob(mouse, objects, 4, 'risefall_norm')  
      MOUSE_knob(mouse, objects, 5, 'risefall2_norm') 
      MOUSE_knob(mouse, objects, 6, 'filter_area_norm') 
      MOUSE_knob(mouse, objects, 7, 'search_area_norm')
      MOUSE_knob(mouse, objects, 9, 'custom_window_norm')    
      MOUSE_knob(mouse, objects, 10, 'fft_size_norm') 
      MOUSE_knob(mouse, objects, 11, 'fft_HP_norm') 
      MOUSE_knob(mouse, objects, 12, 'fft_LP_norm') 
      MOUSE_knob(mouse, objects, 13, 'smooth_norm') 
    
    
    
    -- presets
      if MOUSE_button(objects.pref_b1, 'pref1') then
        gfx.x, gfx.y = mouse.mx, mouse.my    
        GUI_menu1(objects)
      end
      
    -- about
      if MOUSE_button(objects.pref_b2, 'pref2') then
        run_about = true
      end
      
    -- donate
      if MOUSE_button(objects.pref_b3, 'pref3') then
        F_open_URL('http://www.paypal.me/donate2mpl')
      end 
      
      --------------------------------------------------------
     else
     
local info_str = 
[[
Align takes is a Lua script for REAPER written by Michael Pilyavskiy (Russian Federation). Its algorithm based on matching RMS envelopes of dub takes and some reference take using stretch markers.

So how to use it?
- select takes
- press 'Get'
- move slider

You need to have at least 2 items placed on different tracks one under another. The reference item/take is upper take. You can also simultaneously work with any count of takes. The upper take will be also reference item/take for them. "Can I give to this script any audio?" No. You need to prepare item/takes manually OR just click "Get" button and look what special "prepare" function will do.
Perfect situation:
- ref. and dub takes with takerate = 1
- ref. and dub takes without stretch markers
- ref. and dub takes without snap offset
- ref. and dub takes are not loop sourced
- reference take edges over dub takes edges (so every point of dub take is beetween ref.take position and ref.take end)
After you pressed "Get" button, you should see ugly waveforms in script window. If you see vertical lines on syllables/transients, then congratulations - your takes ready to match each other. Move slider and see what happen. If you didn`t see then - try to play with settings, which are explained further. Press "+" button to extend window and change preferences.

Don`t forget it is totally FREE "native" alternative to SyncroArts ( Vocalign / RevoicePro ) $150+ software. So please DONATE if you use it and like it. Donate button open www.paypal.me/donate2mpl in your default browser.

]]

local info_str2 = 
[[
- Green knobs are parameters for detection syllables and transients start/end positions (I call them 'points' further, they represented as vertical lines on the waveform graph). RMS envelope ('envelope' further) of course have some window, so aligning non-macro stuff like drums is not a good example for this tool. Basically points added when envelope rise/fall (envelope always rising/falling so green knobs let you define WHEN exactly to add points, i.e. define conditions for adding).
- Scaling. Let you define how much do you wanna compress signal for detection. It is NOT compress actual take audio. More compression = better detection.
- Threshold is linear "noise floor" for detected points. It is represented on the graph. Lower threshold = more points.
- Rise area. If signal rise/fall by value defined with Rise/Fall and Rise/Fall2 in this area, point will be added. Short time = more points.
- Rise/Fall - linear gain/attenuation factor when checking Rise area for scaled envelope. Lower value = more points.
- Rise/Fall2 - linear gain/attenuation factor when checking Rise area for original envelope. Lower value = more points.
- Filter area - minimal space beetween detected points. Long time = less points.

Red knob is a parameter for main algorithm.
- Search area means how far possible stretch markers can be moved. Short time = tiny alignment.

Blue knobs are parameters for building envelope
- First selector allow to change type envelope beetween RMS envelope and FFT (sum of spectrum bins values) envelope.
- Second selector allow to change algorithm. First algo get every block beetween 3 closest points and find best fit by moving center point. Second algo use same technique, but get blocks one-by one and calculate best fit potential stretch markers position relative to previously stretched blocks.
- RMS window is how much samples taken to calculate average for every envelope point.
- FFT size is number of FFT bins.
- HP and LP control FFT edges.
- Smooth knob control smoothing final envelope.
]]     
      if MOUSE_button(objects.about_b1, 'about_b1') then 
        reaper.MB(info_str,'MPL Align takes',0)
      end
      if MOUSE_button(objects.about_b6, 'about_b6') then 
        reaper.MB(info_str2,'MPL Align takes',0)
      end

      if MOUSE_button(objects.about_b2, 'about_b2') then -- VK
        F_open_URL('http://vk.com/michael_pilyavskiy')
      end           
      if MOUSE_button(objects.about_b3, 'about_b3') then -- soundcloud
        F_open_URL('http://soundcloud.com/mp57')
      end  
      if MOUSE_button(objects.about_b4, 'about_b4') then -- cockos forum
        F_open_URL('http://forum.cockos.com/showthread.php?p=1709618')
      end  
      if MOUSE_button(objects.about_b5, 'about_b5') then 
        F_open_URL('http://rmmedia.ru/threads/121230/')
      end   
      
      if MOUSE_button(objects.about_b7, 'about_b7') then 
        run_about = false
      end      
      
    end -- run_about
      
      
      
    -- for xy position store
      local reaper_vrs = tonumber(reaper.GetAppVersion():match('[%d%.]+'))
      if reaper_vrs >= 5.20 then
        _, xpos, ypos = gfx.dock(0,0,0)
        if (not last_xpos or last_xpos ~= xpos or 
           not last_ypos or not last_ypos ~= ypos)
           and mouse.last_LMB_state and not mouse.LMB_state
          then 
           data.current.xpos, data.current.ypos = xpos, ypos
        end
      end
    
    -- set ini on release
      if  mouse.last_LMB_state and not mouse.LMB_state  then INI_set() end
      
    mouse.last_LMB_state = mouse.LMB_state  
    mouse.last_RMB_state = mouse.RMB_state
    mouse.last_MMB_state = mouse.MMB_state 
    mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
    mouse.last_Ctrl_state = mouse.Ctrl_state
    mouse.last_wheel = mouse.wheel      
  end
-----------------------------------------------------------------------   
  function A3_DEFINE_GUI_vars()
      local gui = {}
      -- global
        gui.aa = 1
        gfx.mode = 0
        gui.fontname = 'Calibri'
        gui.fontsize = 23      
        if OS == "OSX32" or OS == "OSX64" then gui.fontsize = gui.fontsize - 7 end
        
      -- selector buttons
        gui.b_sel_fontsize = gui.fontsize - 1
        gui.b_sel_text_alpha = 1
        gui.b_sel_text_alpha_unset = 0.7
        if OS == "OSX32" or OS == "OSX64" then 
          gui.knob_txt = gui.fontsize - 5
         else 
          gui.knob_txt = gui.fontsize - 8
        end
        
      -- reg buttons
        gui.b_text_alpha = 0.8
        gui.b3_text_alpha = 0.8
        
      -- takenames
        gui.b_takenames_fontsize = gui.fontsize - 3
      
      gui.color = {['back'] = '51 51 51',
                    ['back2'] = '51 63 56',
                    ['black'] = '0 0 0',
                    ['green'] = '102 255 102',
                    ['blue'] = '127 204 255',
                    ['white'] = '255 255 255',
                    ['red'] = '204 76 51',
                    ['green_dark'] = '102 153 102',
                    ['yellow'] = '200 200 0',
                    ['pink'] = '200 150 200',
                  }    
    return gui    
  end
----------------------------------------------------------------------- 
  function A0_MAIN_defer()
  
  
    trig_process = 1
    
    
    
    --local obj = A1_DEFINE_objects() -- define GUI xywh stuff
    --MAIN_switch_compact_view(obj) -- switch beetween compact/full view      
    A2_DEFINE_dynamic_variables() -- from data table to internal data2 table
    
    ENGINE_ProcessGet() -- runs on "Get" button click
    
    --local gui = A3_DEFINE_GUI_vars()
    --A4_DEFINE_GUI_buffers(gui, obj)
    
    --A5_MOUSE_get(obj)
    
    
    if not takes_t or #takes_t < 2 then return end
    for i = 1, #takes_t do 
      if i == 1 then 
             ENGINE_set_stretch_markers2(i, str_markers_t[i], 0) 
        else ENGINE_set_stretch_markers2(i, str_markers_t[i], 1) 
      end
    end
    --[[
    
    local char = gfx.getchar()
    if char == 27 then MAIN_exit() end                               -- escape
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end       -- space -> transport play   
    if char ~= -1 then reaper.defer(A0_MAIN_defer) else MAIN_exit() end -- stop on close 
    ]]
  end 
-----------------------------------------------------------------------   
  function A1_DEFINE_objects()
    -- GUI global
      local objects = {}
      objects.x_offset = 5
      objects.y_offset = 5
      objects.main_h = 237
      objects.main_w_nav = 130 -- width navigation zone
      objects.takes_name_h = 60 -- display H
      objects.takes_name_h2 = 20 -- display names
      objects.disp_item_h = 80
      objects.slider_h = 60
      objects.get_b_h = 70
      objects.get_b_h2 = 50
      objects.get_b_w = 100
      objects.b_setup_h = 20
      objects.tips_w = 100
      objects.knob_count = 7
      objects.knob_w = 65
      objects.main_w = objects.knob_count*objects.knob_w + objects.x_offset*12
      
      objects.knob_h = 90
      objects.pref_actions_w = 400
      
    -- GUI main window
      objects.disp_ref = {objects.x_offset, 
                          objects.y_offset,
                          objects.main_w-(objects.x_offset*2), 
                          objects.disp_item_h}
      objects.disp_dub = {objects.x_offset, 
                          objects.y_offset+objects.disp_item_h,
                          objects.main_w-(objects.x_offset*2), 
                          objects.disp_item_h} 
      objects.disp = {objects.disp_ref[1], 
                      objects.disp_ref[2],
                      objects.disp_ref[3], 
                      objects.disp_ref[4]*2}
                       
      objects.b_get = {objects.x_offset, 
                        objects.disp[2]+objects.disp[4]+objects.y_offset,
                        objects.get_b_w, 
                        objects.slider_h/2-2}                           
      objects.b_setup = {objects.x_offset,
                         objects.b_get[2]+objects.b_get[4]+objects.y_offset,
                         objects.get_b_w,
                         objects.slider_h/2}
      objects.b_slider = {(objects.x_offset*2+objects.get_b_w), 
                           objects.b_get[2]+1,
                           objects.main_w-(objects.x_offset*3+objects.get_b_w), 
                           objects.slider_h}                   
       objects.disp_ref_text = {objects.disp_ref[1],
                                 objects.disp_ref[2]+objects.disp_ref[4]-objects.takes_name_h2,
                                 objects.disp_ref[3],
                                 objects.takes_name_h2} 
       objects.disp_dub_text = {objects.disp_dub[1],
                                 objects.disp_dub[2],
                                 objects.disp_dub[3],
                                 objects.takes_name_h2}  
       
       
    -- about
      about_b_w = 435
      about_b_cnt = 3
      about_b_h = 30
      
      objects.about_b0  = { (objects.main_w - about_b_w)/2,--text
                            objects.main_h /2 - 100,
                            about_b_w,
                            about_b_h} 
                                  
      objects.about_b1  = { (objects.main_w - about_b_w)/2,-- how to use
                            objects.main_h /2,
                            about_b_w,
                            about_b_h} 
      objects.about_b6  = { (objects.main_w - about_b_w)/2,-- params
                            objects.main_h /2 +about_b_h+ objects.y_offset,
                            about_b_w,
                            about_b_h}                                            
                                         
                                                                     
      objects.about_b2  = { (objects.main_w - about_b_w)/2, -- vk
                            objects.main_h /2 + about_b_h*4 + objects.y_offset,
                            60,
                            about_b_h  }     
      objects.about_b3  = { (objects.main_w - about_b_w)/2 + 60 + objects.x_offset, -- soundcloud
                            objects.main_h /2 + about_b_h*4 + objects.y_offset,
                            120,
                            about_b_h  }  
      objects.about_b4  = { (objects.main_w - about_b_w)/2 + 180 + objects.x_offset*2, -- vk
                            objects.main_h /2 + about_b_h*4 + objects.y_offset,
                            120,
                            about_b_h  }  
      objects.about_b5  = { (objects.main_w - about_b_w)/2 + 300 + objects.x_offset*3, -- vk
                            objects.main_h /2 + about_b_h*4 + objects.y_offset,
                            120,
                            about_b_h  }       
                            
                            
      objects.about_b7  = { (objects.main_w - about_b_w)/2, -- close
                            objects.main_h /2 + 220,
                            about_b_w,
                            about_b_h  }                                                                      
                                                  
                          
                          
                          
                                        
      -- GUI settings
        for i = 0, 16 do
          if i == 6 then offs = 2 else  offs = 0 end
          if i > 6 then 
            x_comp = objects.main_w-objects.x_offset*5
            y_offs = objects.knob_h 
           else 
            x_comp = 0
            y_offs = 0 
          end
          objects['knob'..(i+1)] = {objects.x_offset*2 + 
                                    objects.knob_w * i + 
                                    objects.x_offset*i + 
                                    objects.x_offset*offs-x_comp,
                         objects.b_setup[2]+objects.b_setup[4]+objects.y_offset*2+y_offs,
                         objects.knob_w,
                         objects.knob_h-objects.y_offset*3}
        end
        
      -- seleector1
        local selector_w = objects.knob8[3] - objects.x_offset*2
        local selector_h = objects.knob8[4]/2-2
        objects.selector = {objects.knob8[1]+objects.x_offset,
                            objects.knob8[2],
                            selector_w,
                            selector_h  }
        objects.selector2 = {objects.knob8[1]+objects.x_offset,
                            objects.knob8[2]+selector_h+objects.y_offset,
                            selector_w,
                            selector_h  }                            
        
      -- pref rect
        objects.pref_rect1 = {objects.x_offset,
                              objects.b_setup[2]+objects.b_setup[4]+objects.y_offset,
                              objects.knob_w*6+objects.x_offset*7,
                              objects.knob_h-objects.y_offset}
        objects.pref_rect2 = {objects.x_offset*9 + objects.knob_w*6,
                              objects.b_setup[2]+objects.b_setup[4]+objects.y_offset,
                              objects.knob_w+objects.x_offset*2,
                              objects.knob_h-objects.y_offset}    
        objects.pref_rect3 = {objects.x_offset,
                              objects.pref_rect2[2]+objects.pref_rect2[4]+objects.y_offset,
                              objects.knob_w*6+objects.x_offset*7,
                              objects.knob_h-objects.y_offset} 
                                            
        local b_cnt = 3                                   
        local b_h = objects.knob_h/b_cnt -   objects.y_offset
                                     
        objects.pref_b1 = {objects.x_offset*9 + objects.knob_w*6,
                              objects.pref_rect2[2]+objects.pref_rect2[4]+objects.y_offset,
                              objects.knob_w+objects.x_offset*2,
                              b_h}

        objects.pref_b2 = {objects.x_offset*9 + objects.knob_w*6,
                              objects.pref_rect2[2]+objects.pref_rect2[4]+b_h+objects.y_offset*2,
                              objects.knob_w+objects.x_offset*2,
                              b_h}     
                              
        objects.pref_b3 = {objects.x_offset*9 + objects.knob_w*6,
                              objects.pref_rect2[2]+objects.pref_rect2[4]+b_h*2+objects.y_offset*3,
                              objects.knob_w+objects.x_offset*2,
                              b_h}                                                        
        
        objects.set_wind_h = 180              
                                                                         
    return objects
  end
-----------------------------------------------------------------------
  function DEFINE_defaults()    
    local default = 
                  { 
                    name = 'Default',
                    knob_coeff = 0.01, -- knob sensivity
                    xpos = 100,
                    ypos = 100,
                    compact_view = 0, -- default mode
                    mode = 0, -- 0 - RMS / 1 - FFT
                    alg = 0,
                    custom_window_norm = 0, -- rms window    
                    fft_size_norm = 0.5,
                    fft_HP_norm = 0,
                    fft_LP_norm = 1,
                    smooth_norm = 0,
                    filter_area_norm =  0.1, -- filter closer points
                    rise_area_norm =    0.2, -- detect rise on this area
                    risefall_norm =     0.125, -- how much envelope rise/fall in rise area - for scaled env
                    risefall2_norm =    0.3, -- how much envelope rise/fall in rise area - for original env
                    threshold_norm =    0.1, -- noise floor for scaled env
                    scaling_pow_norm =  0.9, -- normalised RMS values scaled via power of this value (after convertion))
                    search_area_norm =  0.1
                  }
    
    local top_t = {    
      count_presets = 8}
      
    return default, top_t
  end
----------------------------------------------------------------------- 
  function F_pairsByKeys (t, f) 
  -- http://stackoverflow.com/questions/1146686/lua-sorting-a-table-alphabetically
      local a = {}
      for n in pairs(t) do
        table.insert(a, n)
      end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then
          return nil
        else
          return a[i], t[a[i]]
        end
      end
      return iter
  end
----------------------------------------------------------------------- 
  function INI_get()
    local def_t, top_t = DEFINE_defaults()
    
    for key in pairs(top_t) do
      if type(top_t[key]) ~= 'table' then
        ret, val = reaper.BR_Win32_GetPrivateProfileString( 'Global', key, top_t[key], config_path )
        data[key] = tonumber(val) and tonumber(val) or val
      end  
    end
    
    data.default = def_t
    
    for i = 1, data.count_presets + 1 do      
      if i == data.count_presets + 1 then i = 'current' end
      data[i] = {}
      if def_t then
        for key in pairs (def_t) do
          ret, val = reaper.BR_Win32_GetPrivateProfileString( 'preset'..i, key, def_t[key], config_path )
          data[i][key] = tonumber(val) and tonumber(val) or val
        end 
      end 
    end
        
  end  
----------------------------------------------------------------------- 
  function INI_set() 
    local val, top_str    
    local def_data, def_top = DEFINE_defaults()    
    -- write top values data.nnn
      fdebug('INI_set')
      for key in pairs (def_top) do
        if type(def_top[key]) ~= 'table' then
          if not data or not data[key] then top_str = def_top[key] else top_str = data[key] end
          reaper.BR_Win32_WritePrivateProfileString( 'Global', key, top_str, config_path )
        end
      end        
    -- write tables   
      for i = 1, data.count_presets + 2 do
        for key in F_pairsByKeys(def_data) do          
          if i == data.count_presets + 1 then i = 'current' end
          if i == data.count_presets + 2 then i = 'default' end          
          if not data[i] or not data[i][key] then val = def_data[key] else val = data[i][key] end
          reaper.BR_Win32_WritePrivateProfileString( 'preset'..i, key, val, config_path )
        end
      end      
    -- write timestamp
      reaper.BR_Win32_WritePrivateProfileString( 'Debug', 'LastSave', os.date(), config_path )
  end
-----------------------------------------------------------------------    
  function INIT_data_t() 
    -- startup, check for ini/create if not exists
    data = {}
    fdebug('MAIN_LoadConfig') 
    local file = io.open(config_path, 'r')
    if not file then 
      local default, top_t = DEFINE_defaults()
      data.current = default
      data.default = default
      for i = 1, top_t.count_presets do data[i] = default end  
      for key in pairs (top_t) do data[key] = top_t[key] end
      INI_set()    
     else 
      file:close()    
      INI_get() 
      INI_set() 
    end    
  end      
-----------------------------------------------------------------------  
  debug_mode =0
  if debug_mode == 1 then msg("") end  
  
  local t = debug.getinfo(1)
  config_path = t.source:gsub('.lua', '-config.ini'):sub(2)
  
  INIT_data_t()
  --local obj = A1_DEFINE_objects()
  --gfx.init("mpl Align takes // "..vrs, obj.main_w, obj.main_h, 0, data.current.xpos, data.current.ypos)
  --update_gfx = true
  --compact_view_trig = true
  
  data2 = {}
  mouse = {}
  takes_arrays = {}
  takes_points = {}
  
  if load_preset_on_start then
    data.current = data[load_preset_on_start]
  end
  A0_MAIN_defer()
