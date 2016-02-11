--[[
   * ReaScript Name: mpl Align Takes
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]

  local vrs = '1.0'
  local changelog =                           
[===[ Changelog:
11.02.2016  1.0
            Public release
25.01.2016  Split from Warping tool
27.10.2015  0.23 Warping tool Early alpha            
01.09.2015  0.01 Alignment / Warping / Tempomatching tool idea
 ]===]


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
    reaper.atexit()
    gfx.quit()
  end  

-----------------------------------------------------------------------   
  function DEFINE_dynamic_variables()
    data2.filter_area = F_convert(data.filter_area_norm, 0.1,0.5)
    data2.rise_area = F_convert(data.rise_area_norm, 0.1,0.5)
    data2.risefall = F_convert(data.risefall_norm, 0.1,0.8)
    data2.risefall2 = F_convert(data.risefall2_norm, 0.2,0.8)    
    data2.threshold = F_convert(data.threshold_norm, 0.1,0.4)  
    data2.scaling_pow = F_convert(math.abs(1-data.scaling_pow_norm), 0.1, 0.75)
    
    data2.search_area = F_convert(data.search_area_norm, 0.05, 1) 
    
    local objects = DEFINE_objects()
    if compact_view_trig then 
      objects.main_h = objects.main_h + data.compact_view*objects.set_wind_h
      gfx.quit()
      gfx.init("mpl Align takes // "..vrs, objects.main_w, objects.main_h, 0)
      compact_view_trig = false
    end 
    
    char = gfx.getchar()
    play_pos = reaper.GetPlayPosition(0)
    OS = reaper.GetOS()
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
    
    --local HP =  100
    --local LP = fft_size
    
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
        
          aa.window_sec = fft_size/aa.rate -- ms
          data.global_window_sec = aa.window_sec
          
          -- get fft_size samples buffer
            for read_pos = 0, item_len, aa.window_sec do 
            
              aa.buffer = reaper.new_array(fft_size*2)
              aa.buffer_com = reaper.new_array(fft_size*2)
               
              reaper.GetAudioAccessorSamples(
                    aa.accessor , --AudioAccessor
                    aa.rate, -- samplerate
                    2,--aa.numch, -- numchannels
                    read_pos, -- starttime_sec
                    fft_size, -- numsamplesperchannel
                    aa.buffer) --samplebuffer
                    
              -- merge buffers dy duplicating sum/2
                for i = 1, fft_size*2 - 1, 2 do
                  aa.buffer_com[i] = (aa.buffer[i] + aa.buffer[i+1])/2
                  aa.buffer_com[i+1] = 0
                end
                
              --[[ Get FFT sum of bins in defined range
                aa.buffer_com.fft(fft_size, true, 1)
                aa.buffer_com_t = aa.buffer_com.table(1,fft_size, true)
                sum_com = 0
                for i = HP, LP do
                  sum_com = sum_com + math.abs(aa.buffer_com_t[i])
                end    
                table.insert(sum_t, sum_com /(LP-HP))]]
                                      
             -- Get RMS sum in defined range
                aa.buffer_com_t = aa.buffer_com.table(1,fft_size, true)
                sum_com = 0
                for i = 1, fft_size do
                  sum_com = sum_com + math.abs(aa.buffer_com_t[i])
                end    
                table.insert(sum_t, sum_com)    
                            
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
        / data.global_window_sec)
        end_win_cnt = math.floor
          ((takes_t[1].pos + takes_t[1].len - takes_t[take_id].pos - takes_t[take_id].len) 
          / data.global_window_sec)
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
            if points[k] == 1 then 
              points[k] = 0
            end
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
  function F_find_arrays_com_diff(ref_array, ref_array_offset, dub_array)
    local dub_array_size = dub_array.get_alloc()
    local ref_array_size = ref_array.get_alloc()
    local endpoint
    local com_difference = 0
    if ref_array_offset + dub_array_size > ref_array_size then endpoint = ref_array_size - ref_array_offset
      else endpoint = dub_array_size end
      
    for i = 1, endpoint do
      com_difference = com_difference + math.abs(ref_array[i + ref_array_offset - 1 ]-dub_array[i])
    end
    return com_difference
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
    function F_stretch_array(src_array, new_size)
      local src_array_size = src_array.get_alloc()
      local coeff = (src_array_size - 1) / (new_size  - 1)
      local out_array = reaper.new_array(new_size)
      if new_size < src_array_size or new_size > src_array_size then
        for i = 0, new_size - 1 do 
          out_array[i+1] = src_array[math.floor(i * coeff) + 1]
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
  function ENGINE_compare_data2(ref_arr_orig, dub_arr_orig, points, window_sec)
    
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
        if points[i] == 1 then block_ids[#block_ids+1] = i end
      end    
      
    -- loop blocks
      for i = 1, #block_ids - 2 do
        -- create fixed block
          fantom_arr_size = block_ids[i+2] - block_ids[i] + 1
          
          local fantom_arr = reaper.new_array(fantom_arr_size)
          fantom_arr.copy(dub_arr,--src, 
                          block_ids[i],--srcoffs, 
                          fantom_arr_size,--size, 
                          1)--destoffs])
                          
        -- loop possible positions
          local min_block_len = 2
          search_pos_start = block_ids[i+1] - search_area
          if search_pos_start < block_ids[i] + min_block_len then
            search_pos_start = block_ids[i] + min_block_len end
          search_pos_end = block_ids[i+1] + search_area
          if search_pos_end > block_ids[i+2] - min_block_len then
            search_pos_end = block_ids[i+2] - min_block_len end    
          if (search_pos_end-search_pos_start+1) > min_block_len then
            --search_pos_start = block_ids[i] + 2
            --search_pos_end = block_ids[i+2] - 2 
            
            diff = reaper.new_array(search_pos_end-search_pos_start+1)
            
            for k = search_pos_start, search_pos_end do
              local orig_block = block_ids[i+1]-block_ids[i]+ 1
              local str_block = k - block_ids[i] +1
              --msg(orig_block)
              --msg(str_block)
              fantom_arr_stretched = 
                F_stretch_array2(fantom_arr,  orig_block, str_block)
              diff[k - search_pos_start+1] = 
                F_find_arrays_com_diff(ref_arr, block_ids[i], fantom_arr_stretched)
            end
            min_id_diff = F_find_min_value(diff) + search_pos_start - 1
            --[[msg('---------------') 
            msg(min_id_diff)     
            msg(block_ids[i+1])]]
            sm_table[#sm_table+1] =  
                {(min_id_diff) *  window_sec,
                  (block_ids[i+1]) * window_sec}
                  
            --block_ids[i+1] = min_id_diff
          end
      end -- end loop blocks
    --msg('test')
    return sm_table
  end
                                      
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
          src_pos = str_mark_table[i][2]-(takes_t[take_id].pos-takes_t[1].pos)+takes_t[take_id].offset
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
              gfx.a = 0.4
              F_Get_SSV(gui.color[col_peaks])
              gfx.lineto(x+(i+1)*w/arr_size, y-h*data_t_it2*drawscale)
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
            F_Get_SSV(gui.color.blue, true) 
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
        function GUI_button(objects, gui, xywh, name, issel, font) local w1_sl_a
          gfx.y,gfx.x = 0,0         
          -- frame
            gfx.a = 1
            F_Get_SSV(gui.color.white, true)
            --gfx.rect(xywh[1],xywh[2],xywh[3], xywh[4]+1, 0 , gui.aa)
            
          -- back
            if issel then gfx.a = 0.8 else gfx.a = 0.2 end
            gfx.blit(3, 1, 0, --backgr
              0,0,objects.main_w, objects.main_h,
              xywh[1],xywh[2],xywh[3],xywh[4], 0,0) 
            
          -- txt              
            
            gfx.setfont(1, gui.fontname, font)
            if issel then
              gfx.a = gui.b_sel_text_alpha
              F_Get_SSV(gui.color.black, true)
             else
              gfx.a = gui.b_sel_text_alpha_unset
              F_Get_SSV(gui.color.white, true)
            end
            local measurestrname = gfx.measurestr(name)
            local x0 = xywh[1] + (xywh[3] - measurestrname)/2
            local y0 = xywh[2] + (xywh[4] - gui.b_sel_fontsize)/2
            gfx.x, gfx.y = x0,y0 
            gfx.drawstr(name)  
        end

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
  function GUI_knob(objects, xywh,gui, val, text,text_val, col)
    
    if val == nil then val = 0 end 
    x,y ,w, h = xywh[1],xywh[2],xywh[3],xywh[4]
    arc_r = w/2 * 0.8
    ang_gr = 120
    ang_val = math.rad(-ang_gr+ang_gr*2*val)
    ang = math.rad(ang_gr)
    
    -- back
      gfx.a = 0.3
      F_Get_SSV(gui.color[col], true)
      gfx.rect(x,y ,w, h, 1)
      gfx.a = 0.2
      gfx.blit(7, 1, math.rad(180), -- backgr
               0,0,objects.main_w, objects.main_h,
               x,y ,w, h, 0,0)
               
    -- arc full
      
    -- arc val
      for i = 0, 3, 0.5 do
        gfx.a = 0.2
        F_Get_SSV(gui.color.white, true)
        gfx.arc(x+w/2,y+h/2,arc_r-i,ang,-ang,gui.aa)
        
        gfx.a = 1
        F_Get_SSV(gui.color[col], true)
        gfx.arc(x+w/2,y+h/2,arc_r - i,-ang,ang_val,gui.aa)    
      end  
      
    -- text
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
  function DEFINE_GUI_buffers()
    local is_sel
    local objects = DEFINE_objects()
    update_gfx_minor = true
    
    -- GUI variables 
      local gui = {}
      gui.aa = 1
      gfx.mode = 0
      gui.fontname = 'Calibri'
      gui.fontsize = 23      
      if OS == "OSX32" or OS == "OSX64" then gui.fontsize = gui.fontsize - 7 end
      
      -- selector buttons
        gui.b_sel_fontsize = gui.fontsize - 1
        gui.b_sel_text_alpha = 1
        gui.b_sel_text_alpha_unset = 0.7
        gui.knob_txt = gui.fontsize - 8
        
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
      
    
      ----------------------------------------------------------------------- 
          
    -- buffers
      -- 1 main back
      -- 2 select windows
      -- 3 button back gradient
      -- 4 wind 1
      -- 5 wait window
      -- 6 envelopes
      -- 7 buffer back
      -- 8 about
      -- 9 knobs
        
    -- buf1 background   
      if update_gfx then    
        fdebug('DEFINE_GUI_buffers_1-mainback')  
        gfx.dest = 1
        gfx.setimgdim(1, -1, -1)  
        gfx.setimgdim(1, objects.main_w, objects.main_h+objects.set_wind_h) 
        gfx.a = 0.92
        F_Get_SSV(gui.color.back, true)
        gfx.rect(0,0, objects.main_w, objects.main_h+objects.set_wind_h,1)
      end
    
    -- buf3 -- buttons back gradient
      if update_gfx then    
        fdebug('DEFINE_GUI_buffers_3-buttons back')  
        gfx.dest = 3
        gfx.setimgdim(3, -1, -1)  
        gfx.setimgdim(3, objects.main_w, objects.main_h)  
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
           gfx.gradrect(0,0,objects.main_w, objects.main_h, 
                        r,g,b,a, 
                        drdx, dgdx, dbdx, dadx, 
                        drdy, dgdy, dbdy, dady)
      end  
  
    -- buf 4 -- general buttons / sliders / info
      if update_gfx_minor then
          gfx.dest = 4
          gfx.setimgdim(4, -1, -1)  
          gfx.setimgdim(4, objects.main_w, objects.main_h+objects.set_wind_h)
          
          if data.compact_view == 0 then
            mode_name = '+'
           else
            mode_name = '-'
          end
          
          GUI_button2(objects, gui, objects.b_setup,mode_name, mouse.context == 'w1_settings_b', gui.b_sel_fontsize, 0.7, 'white')
          
          GUI_button2(objects, gui, objects.b_get, 'Get', 
            mouse.context == 'w1_get_b',    gui.b_sel_fontsize, 0.8, 'green') 
            
          GUI_button2(objects, gui, objects.pref_actions,'Menu', 
            mouse.context == 'settings_actions', gui.b_sel_fontsize, 0.8, 'green')

          GUI_button2(objects, gui, objects.pref_donate,'Donate', 
            mouse.context == 'pref_donate', gui.b_sel_fontsize, 0.8, 'green')
                                    
          GUI_slider(objects, gui, objects.b_slider, w1_slider, 1,'green', takes_t)
          if data.current_window == 4  then
            GUI_slider(objects, gui, objects.b_slider2, w2_slider, 1,'green', takes_t)
          end
          
          if takes_t ~= nil and takes_t[2] ~= nil then
          -- display navigation
            if mouse.context == 'w1_disp' then
              -- take names
              GUI_text(objects.disp_ref_text, gui, objects, 
                  gui.fontname, gui.b_takenames_fontsize, 'Reference: '..takes_t[1].name:sub(0,30), true)              
                local d_name = 'Dub: '
                if takes_t[3] ~= nil then d_name = 'Dubs ('..math.floor(data.current_take-1)..'/'..(#takes_t - 1)..'): ' end
                GUI_text(objects.disp_dub_text, gui, objects, 
                  gui.fontname, gui.b_takenames_fontsize, d_name..takes_t[data.current_take].name:sub(0,30), true)
              end
            -- display cursor position
              gfx.a = 0.9
              F_Get_SSV(gui.color.red, true)
              gfx.line(F_limit(objects.disp[1] + objects.disp[3] / takes_t[1].len * (play_pos - takes_t[1].pos), 
                        objects.disp[1], objects.disp[1] + objects.disp[3]),
                        objects.disp[2],
                       F_limit(objects.disp[1] + objects.disp[3] / takes_t[1].len * (play_pos - takes_t[1].pos), 
                        objects.disp[1], objects.disp[1] + objects.disp[3]),
                        objects.disp[2]+objects.disp[4])
          end
 
      end

    -- item envelope gradient
      if update_gfx then 
          gfx.dest = 7  
          gfx.setimgdim(7, -1, -1)
          gfx.setimgdim(7, objects.main_w, objects.main_h)
          gfx.gradrect(0,0, objects.main_w, objects.main_h, 1,1,1,0.9, 0,0,0,0.00001, 0,0,0,-0.005)
      end
      
    -- buf 6 static envelopes buttons
      if update_gfx then 
          fdebug('DEFINE_GUI_buffers_6-envelopes')      
          gfx.dest = 6
          gfx.setimgdim(6, -1, -1)  
          gfx.setimgdim(6, objects.main_w, objects.main_h)
          GUI_item_display
            (objects, gui, objects.disp_ref , takes_arrays[1],                 true, 
            takes_points[1], 'green' ) 
          GUI_item_display
            (objects, gui, objects.disp_dub , takes_arrays[data.current_take], false ,
            takes_points[data.current_take], 'green')
      end
    
    
    -- buf 5 wait
      if trig_process ~= nil and trig_process == 1 then
        gfx.dest = 5
        gfx.setimgdim(5, -1, -1)  
        gfx.setimgdim(5, objects.main_w, objects.main_h+objects.set_wind_h) 
        gfx.a = 0.93
        F_Get_SSV(gui.color.back, true)
        gfx.rect(0,0, objects.main_w, objects.main_h+objects.set_wind_h,1)  
        F_Get_SSV(gui.color.white, true)    
        local str = 'Analyzing takes. Please wait...'
        gfx.setfont(1, gui.fontname, gui.fontsize)
        gfx.x = (objects.main_w - gfx.measurestr(str))/2
        gfx.y = (objects.main_h-gfx.texth)/2
        gfx.drawstr(str)
      end
      
    -- buf 9 knobs
      if update_gfx then 
          fdebug('DEFINE_GUI_buffers_9-knobs')      
          gfx.dest = 9
          gfx.setimgdim(9, -1, -1)  
          gfx.setimgdim(9, objects.main_w, objects.main_h+objects.set_wind_h)

          GUI_knob(objects, objects.knob1,gui, data.scaling_pow_norm, 'Scaling',
            data.scaling_pow_norm, 'green')
          GUI_knob(objects, objects.knob2,gui, data.threshold_norm, 'Threshold',
            data2.threshold, 'green') 
          GUI_knob(objects, objects.knob3,gui, data.rise_area_norm, 'Rise Area',
            math.floor(data2.rise_area * 1000)..'ms', 'green')   
          GUI_knob(objects, objects.knob4,gui, data.risefall_norm, 'Rise/Fall',
            data2.risefall, 'green')     
          GUI_knob(objects, objects.knob5,gui, data.risefall2_norm, 'Rise/Fall 2',
            data2.risefall2, 'green')                                     
          GUI_knob(objects, objects.knob6,gui, data.filter_area_norm, 'Filter Area',
            math.floor(data2.filter_area * 1000)..'ms', 'green')           
            
          
          gfx.a = 0.5
          F_Get_SSV(gui.color.green_dark, true)
          gfx.rect(objects.pref_rect1[1],
            objects.pref_rect1[2],
            objects.pref_rect1[3],
            objects.pref_rect1[4],0)  
            
          GUI_knob(objects, objects.knob7, gui, data.search_area_norm, 'Search area',
            math.floor(data2.search_area * 1000)..'ms', 'red')            

          gfx.a = 0.5
          F_Get_SSV(gui.color.red, true)
          gfx.rect(objects.pref_rect2[1],
            objects.pref_rect2[2],
            objects.pref_rect2[3],
            objects.pref_rect2[4],0)  
          
          
                                               
      end    
    
    --[[if debug_mode == 1 then 
      -- buf19 test
        if update_gfx or update_gfx_minor then    
          gfx.dest = 19
          gfx.setimgdim(19, -1, -1)
          gfx.setimgdim(19, objects.main_w, objects.main_h)
        end
      end]]
      
    
    ------------------
    -- common buf20 --
    ------------------
      gfx.dest = 20   
      gfx.setimgdim(20, -1,-1)
      gfx.setimgdim(20, objects.main_w, objects.main_h+objects.set_wind_h)
      
      -- common
        gfx.a = 1
        gfx.blit(1, 1, 0, -- backgr
          0,0,objects.main_w, objects.main_h+objects.set_wind_h,
          0,0,objects.main_w, objects.main_h+objects.set_wind_h, 0,0)           
        gfx.blit(6, 1, 0, -- main window  static
            0,0,objects.main_w, objects.main_h,
            0,0,objects.main_w, objects.main_h, 0,0) 
        gfx.blit(4, 1, 0, -- main window dynamic
            0,0,objects.main_w, objects.main_h+objects.set_wind_h,
            0,0,objects.main_w, objects.main_h+objects.set_wind_h, 0,0) 
        gfx.blit(9, 1, 0, -- main window dynamic
            0,0,objects.main_w, objects.main_h+objects.set_wind_h,
            0,0,objects.main_w, objects.main_h+objects.set_wind_h, 0,0)                        
          if  trig_process ~= nil and trig_process == 1 then
            gfx.blit(5, 1, 0, --wait
            0,0,objects.main_w, objects.main_h+objects.set_wind_h,
            0,0,objects.main_w, objects.main_h+objects.set_wind_h, 0,0)   
          end
        
        gfx.blit(19, 1, 0, --TEST
          0,0,objects.main_w, objects.main_h,
          0,0,objects.main_w, objects.main_h, 0,0)  
              
    update_gfx = false
  end

-----------------------------------------------------------------------    
  function GUI_DRAW()
    local objects = DEFINE_objects()
    --fdebug('GUI_DRAW')
     
    -- common buffer
      gfx.dest = -1   
      gfx.a = 1
      gfx.x,gfx.y = 0,0
      gfx.blit(20, 1, 0, 
        0,0, objects.main_w, objects.main_h+objects.set_wind_h,
        0,0, objects.main_w, objects.main_h+objects.set_wind_h, 0,0)
        
    gfx.update()
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
    if OS=="OSX32" or OS=="OSX64" then
      os.execute("open ".. url)
     else
      os.execute("start ".. url)
    end
  end
  
-----------------------------------------------------------------------   
  function GUI_menu_settings() local menuret 
    local default_data = DEFINE_global_variables()
    
    
    local menuret = gfx.showmenu(
      '#Actions'
      ..'|Restore defaults'
      
      ..'||#Links'
      ..'|MPL on Cockos Forum'
      ..'|MPL on VK'
      ..'|MPL on SoundCloud'
      ..'|Warping tool thread on Cockos forum'
      ..'|Warping tool thread on RMM forum'
      
      ..'||#Info'
      ..'|WTF are these parameters?'
      )
      
      -- actions 
      local act_count = 1
      if menuret == 2 then -- restore defaults
        data = DEFINE_global_variables()
        ENGINE_set_ini(data, config_path)
        updata_gfx = true
      end
            
      -- links 
      
      if menuret == 3+act_count then
        F_open_URL('http://forum.cockos.com/member.php?u=70694')
      end

      if menuret == 4+act_count then
        F_open_URL('http://vk.com/michael_pilyavskiy')
      end      

      if menuret == 5+act_count then
        F_open_URL('http://soundcloud.com/mp57')
      end       
            
      if menuret == 6+act_count then
        F_open_URL('http://forum.cockos.com/showthread.php?t=171658')
      end

      if menuret == 7+act_count then
        F_open_URL('http://rmmedia.ru/threads/121230/')
      end

par_str = 
[[
Algorithm based on the matching RMS envelopes of 2+ takes and use stretch markers to move points of syllables start/end to make them match some reference take.

Green knobs are parameters for detection points. Note, RMS envelope of course have some window, so aligning for example drums with this tool is not a good idea. Basically points added when envelope rise/fall by some value in defined area.

- Scaling. Detection syllables starts/ends easier with scaled envelopes, since scaling actually compress range. When comparing data, script also use scaled envelopes and not original ones. 
- Threshold is linear "noise floor" for detected points. It represented on the graph.
- Rise area. If signal rise/fall by value defined with Rise/Fall and Rise/Fall2 in this area, point (=stretch marker) will be created.
- Rise/Fall is gain/attenuation when checking Rise area for scaled envelope.
- Rise/Fall is gain/attenuation when checking Rise area for original envelope.
- Filter area - is minimal space beetween detected points.

Red knob is parameter of comparing part of this script.

- Search area. This defines searcing area for every found point when finding best RMS fit.
]]
      
      -- info
      if menuret == 9+act_count then
        reaper.MB(par_str, 'Parameters',0)
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
                data.current_take = ret_menu
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
  function MOUSE_get()
    local objects = DEFINE_objects()
    local ret -- ENGINE_prepare_takes response
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
    
    if mouse.LMB_state and not mouse.last_LMB_state then    
      mouse.last_mx_onclick = mouse.mx
      mouse.last_my_onclick = mouse.my
    end
           
    if mouse.last_mx_onclick ~= nil and mouse.last_my_onclick ~= nil then
      mouse.dx = mouse.mx - mouse.last_mx_onclick
      mouse.dy = mouse.my - mouse.last_my_onclick
     else
      mouse.dx, mouse.dy = 0,0
    end
          
    if not mouse.LMB_state  then mouse.context = nil end
    if not mouse.LMB_state  then mouse.context2 = nil end
    
    if mouse.last_LMB_state and not mouse.LMB_state then mouse.last_touched = nil end
    
    mouse.last_mx = 0
    mouse.last_my = 0
        
    -- get takes
     
        -- display
          if MOUSE_match(objects.disp) then mouse.context = 'w1_disp' end
          if takes_t~= nil and takes_t[2] ~= nil then 
            if MOUSE_match(objects.disp) and mouse.LMB_state and not mouse.last_LMB_state then
              gfx.x = mouse.mx
              gfx.y = mouse.my
              GUI_menu_display(takes_t)
            end
          end
          
        -- settings button 
          if MOUSE_match(objects.b_setup) then mouse.context = 'w1_settings_b' end
          if MOUSE_match(objects.b_setup) 
            and mouse.LMB_state 
            and not mouse.last_LMB_state 
            then            
            compact_view_trig = true
            data.compact_view = math.abs(data.compact_view-1)
            ENGINE_set_ini(data, config_path)
          end
  
        -- actions
          if MOUSE_match(objects.pref_actions) then mouse.context = 'settings_actions' end
          if MOUSE_match(objects.pref_actions) 
            and mouse.LMB_state 
            and not mouse.last_LMB_state 
            then
            gfx.x, gfx.y = mouse.mx, mouse.my    
            GUI_menu_settings()
          end

        -- danate
          if MOUSE_match(objects.pref_donate) then mouse.context = 'pref_donate' end
          if MOUSE_match(objects.pref_donate) 
            and mouse.LMB_state 
            and not mouse.last_LMB_state 
            then
            F_open_URL('http://www.paypal.me/donate2mpl')
          end          
          
        -- get button 
          if MOUSE_match(objects.b_get) then mouse.context = 'w1_get_b' end
          if MOUSE_match(objects.b_get) 
            and mouse.LMB_state 
            and not mouse.last_LMB_state 
           then
            if trig_process == nil then trig_process = 1 end
            
          end
          
          if trig_process ~= nil and trig_process == 1 and not mouse.LMB_state then 
            ret = ENGINE_prepare_takes()
            if ret == 1 then
              takes_t = ENGINE_get_takes()
              if #takes_t ~= 1 and #takes_t >= 2 then
                str_markers_t = {} 
                pos_offsets = {}  
                rates = {}        
                for i = 1, #takes_t do 
                    takes_arrays[i] = ENGINE_get_take_data(i, data.scaling_pow2) 
                    --if i > 1 then
                      takes_points[i] = 
                        ENGINE_get_take_data_points2(takes_arrays[i],data.global_window_sec)
                      str_markers_t[i] = 
                        ENGINE_compare_data2(takes_arrays[1], takes_arrays[i], takes_points[i],data.global_window_sec )
                    --end
                end
              end
            end 
            update_gfx = true 
            trig_process = nil
          end
          
          
        -- strength / apply slider 1 
          if takes_t ~= nil then 
            if MOUSE_match(objects.b_slider)
              and mouse.LMB_state 
              and not mouse.last_LMB_state then 
                mouse.context = 'w1_slider' 
            end 
            
            if mouse.context == 'w1_slider' then
              w1_slider = F_limit((mouse.mx - objects.b_slider[1]) / objects.b_slider[3],0,1 )
              for i = 1, #takes_t do 
                ENGINE_set_stretch_markers2(i, str_markers_t[i], w1_slider)
              end
            end
            
          end
          
        -- knobs
          function MOUSE_knob(objects, i, var)
            if MOUSE_match(objects['knob'..i]) and mouse.LMB_state 
              and not mouse.last_LMB_state 
              then 
                mouse.context2 = 'knob'..i 
                abs_var = data[var]
            end 
            
            if mouse.context2 == 'knob'..i then
              data[var] = F_limit(abs_var + knob_coeff * -mouse.dy,0,1)
              ENGINE_set_ini(data, config_path)
            end
          end
          
          MOUSE_knob(objects, 1, 'scaling_pow_norm')
          MOUSE_knob(objects, 2, 'threshold_norm')
          MOUSE_knob(objects, 3, 'rise_area_norm') 
          MOUSE_knob(objects, 4, 'risefall_norm')  
          MOUSE_knob(objects, 5, 'risefall2_norm') 
          MOUSE_knob(objects, 6, 'filter_area_norm')
                              
          MOUSE_knob(objects, 7, 'search_area_norm')   
           
          
    
    mouse.last_LMB_state = mouse.LMB_state  
    mouse.last_RMB_state = mouse.RMB_state
    mouse.last_MMB_state = mouse.MMB_state 
    mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
    mouse.last_Ctrl_state = mouse.Ctrl_state
    mouse.last_wheel = mouse.wheel      
  end
  
----------------------------------------------------------------------- 
  function MAIN_defer()
    DEFINE_dynamic_variables()
    DEFINE_GUI_buffers()
    GUI_DRAW()
    MOUSE_get()
    if char == 27 then MAIN_exit() end  --escape
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end -- space-> transport play   
    if char ~= -1 then reaper.defer(MAIN_defer) else MAIN_exit() end
  end 
  
  function DEFINE_objects()
    -- GUI global
      local objects = {}
      objects.x_offset = 10
      objects.y_offset = 10
      objects.main_h = 250
      objects.main_w_nav = 130 -- width navigation zone
      objects.takes_name_h = 70 -- display H
      objects.takes_name_h2 = 20 -- display names
      objects.slider_h = 60
      objects.get_b_h = 70
      objects.get_b_h2 = 50
      objects.get_b_w = 100
      objects.b_setup_h = 20
      objects.tips_w = 100
      objects.knob_count = 7
      objects.knob_w = 65
      objects.main_w = objects.knob_count*objects.knob_w + objects.x_offset*12
      objects.set_wind_h = 140
      objects.knob_h = 100
      objects.pref_actions_w = 400
      
    -- GUI main window
      objects.disp_ref = {objects.x_offset, 
                          objects.y_offset,
                          objects.main_w-(objects.x_offset*2), 
                          objects.main_h/2-objects.y_offset*1.5-objects.slider_h/2}
      objects.disp_dub = {objects.x_offset, 
                          objects.main_h/2-objects.slider_h/2-objects.y_offset*0.5,
                          objects.main_w-(objects.x_offset*2), 
                          objects.main_h/2-objects.y_offset*1.5-objects.slider_h/2} 
      objects.disp = {objects.disp_ref[1], 
                      objects.disp_ref[2],
                      objects.disp_ref[3], 
                      objects.disp_ref[4]*2}
                       
      objects.b_get = {objects.x_offset, 
                        objects.main_h-objects.y_offset-objects.slider_h,
                        objects.get_b_w, 
                        objects.slider_h/2-2}                           
      objects.b_setup = {objects.x_offset,
                         objects.main_h-objects.y_offset-objects.slider_h/2,
                         objects.get_b_w,
                         objects.slider_h/2}
      objects.b_slider = {(objects.x_offset*2+objects.get_b_w), 
                           objects.main_h-objects.slider_h-objects.y_offset,
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
                                 
      -- GUI settings
        for i = 0, 7 do
          if i >= 6 then offs = 2 else  offs = 0 end
          objects['knob'..(i+1)] = {objects.x_offset*2 + 
                                    objects.knob_w * i + 
                                    objects.x_offset*i + 
                                    objects.x_offset*offs,
                         objects.main_h+objects.y_offset,
                         objects.knob_w,
                         objects.knob_h-objects.y_offset*3}
        end
        
      -- pref rect
        objects.pref_rect1 = {objects.x_offset,
                              objects.main_h+1,
                              objects.knob_w*6+objects.x_offset*7,
                              objects.knob_h-objects.y_offset}
        objects.pref_rect2 = {objects.x_offset*9 + objects.knob_w*6,
                              objects.main_h+1,
                              objects.knob_w+objects.x_offset*2,
                              objects.knob_h-objects.y_offset}    
                              
        objects.pref_actions = {objects.x_offset,
                              objects.main_h+objects.knob_h,
                              objects.pref_actions_w,
                              objects.set_wind_h - objects.knob_h - objects.y_offset}

        objects.pref_donate = {objects.x_offset*2+objects.pref_actions_w,
                              objects.main_h+objects.knob_h,
                              objects.main_w-objects.x_offset*3 - objects.pref_actions_w,
                              objects.set_wind_h - objects.knob_h - objects.y_offset}                              
                              
                                                                                        
    return objects
  end
    
-----------------------------------------------------------------------   
  function F_ret_ini_val2(content, ini_key, var, default_data)  
    local out_str ,str
    for line in content:gmatch("[^\r\n]+") do
      str = line:match(ini_key..'=.*')
      if str ~= nil then
        out_str = str:gsub(ini_key..'=','')
        break
      end
    end
    if out_str == nil or tonumber(out_str) == nil then out_str = default_data[var] end
    data[var] = tonumber(out_str)
  end
  
-----------------------------------------------------------------------  
  function ENGINE_set_ini(data, config_path)
    
    -------- LINK TO INI
    outstr_data = ''
    for i,v in pairs(data) do
      outstr_data = outstr_data..'\n'
        ..i..'='..data[i]
    end
    
    outstr =      
      '[MPL_Align_takes_config]\n'..outstr_data
      
    fdebug('ENGINE_set_ini >>>')    
    fdebug(outstr)
    
    local file = io.open(config_path,'w')
    file:write(outstr)
    file:close()
    
    update_gfx = true
  end   
       
-----------------------------------------------------------------------  
  function ENGINE_get_ini(config_path) --local ret, str
    update_gfx = true
    local file = io.open(config_path, 'r')
    content = file:read('*all')
    file:close()

    fdebug('ENGINE_get_ini <<< ') 
    fdebug(content)
        
    local default_data = DEFINE_global_variables()
    
    for i,v in pairs(data) do
      F_ret_ini_val2(content, i, i, default_data)
    end 
        
  end
  
-----------------------------------------------------------------------
  function DEFINE_global_variables()    
    
    takes_arrays = {}
    takes_points = {}
    
    -------- DEFINE VARS
    local data = {}
    local data2 = {}
    data.current_take = 2 -- show second take as dub
    fft_size = 256 -- deprecated / used for calc RMS size
    knob_coeff = 0.01 -- knob sensivity
              
    -- syl align -- wind 2 settings
      data.filter_area_norm = 0.1 -- filter closer points
      data.rise_area_norm = 0.2 -- detect rise on this area
      data.risefall_norm = 0.125 -- how much envelope rise/fall in rise area - for scaled env
      data.risefall2_norm = 0.3 -- how much envelope rise/fall in rise area - for original env
      data.threshold_norm = 0.1 -- noise floor for scaled env
      data.scaling_pow_norm = 0.9 -- scaling - normalised RMS values scaled via power of this value (after convertion))
      data.search_area_norm = 0.1
      
      data.compact_view = 0 -- default mode
    return data,data2
  end

-----------------------------------------------------------------------    
  function MAIN_search_ini(data)
    fdebug('MAIN_search_ini') 
    local reapath = reaper.GetResourcePath():gsub('\\','/')
    local t = debug.getinfo(1)
    config_path = t.source:gsub('.lua', '.ini'):sub(2)
    local file = io.open(config_path, 'r')
    if file == nil then ENGINE_set_ini(data, config_path) else 
      ENGINE_get_ini(config_path) 
      file:close()
    end    
  end
      
-----------------------------------------------------------------------  
  debug_mode = 0
  if debug_mode == 1 then msg("") end    
  mouse = {}
  data,data2 = DEFINE_global_variables()
  MAIN_search_ini(data)
  objects = DEFINE_objects()
  gfx.init("mpl Align takes // "..vrs, objects.main_w, objects.main_h, 0)
  objects = nil
  update_gfx = true
  compact_view_trig = true
  MAIN_defer()
