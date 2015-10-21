  ------  Michael Pilyavskiy ------
  ---------- Warping tool ---------
  
fontsize = 16
get_selected_items_on_start = 1




-- warping if 2 or more items
  -- (check for rms matching (currently have no idea how to implement this))
  -- get rms envelope
  -- get fft rise envelope
  -- get stretch markers in selected items 
  -- quantize stretch markers of lower items to stretch markers of first item

-- tempo warp if one item
  -- get stretch markers in selected item (settings)
  -- calculate true beat markers
  -- average tempo
  -- delete wrong markers
  -- add approximately markers on every potential area  
  
-- actions
  -- add tempo envelope from bar/beat markers
  -- stretch beats to grid by markers index


  vrs = "0.21"
 
  ---------------------------------------------------------------------------------------------------------------              
  changelog =                              
[===[ Changelog:
21.10.2015  0.21
            action: match items positions by RMS
            code: HP/LP FFT filters
            gui: fixed display relative item positions
            gui: action related knobs
            gui: show action info 
            gui: slider       
20.10.2015  0.20
            code: structure improvements
            code: optionally get items on start
            gui: structure improvements
            gui: action selector(hidden)
            performance: blitting graphics - saves cpu A LOT, thanks James HE!
17.10.2015  0.18
            code: search markers algorithm test2
            code: fft tables sesrch for coincidence test
            gui: rise percent
16.10.2015  0.15
            code: another search markers algorithm test
            gui: mirror env views
14.10.2015  0.14
            code: area2 search 2 directions
            gui: potential marker points on top
13.10.2015  0.13
            code: fft rise envelope instead rms envelope
            code: fft size is 128bins as optimal for good detection / performance
            code: fft range is full range (for now)
            code: area1 search max peak around searching window
            code: area2 define searching max peak marker within area of current searching marker       
            code: tempo average
            gui: window size knob hidden
            gui: window size fixed to 20ms as optimal for basic detection envelope            
12.10.2015  0.11
            gui: area knob
11.10.2015  0.1
            gui, displays, get item data, get potential stretch markers
01.09.2015  0.01 
            alignment/warping/tempomatching tool idea 
    
 ]===]
----------------------------------------------------------------------- 
   function F_JUMP() end
-----------------------------------------------------------------------
   function F_test(test)  
      if test ~= nil then  reaper.ShowConsoleMsg("") reaper.ShowConsoleMsg(test) end
   end

-----------------------------------------------------------------------
   function F_limit(var,lim_min,lim_max)  
    if var < lim_min then var = lim_min end
    if var > lim_max then var = lim_max end
    return var
  end
-----------------------------------------------------------------------
  function F_conv_val2norm(v,v_min,v_max,inv)
    if inv then v_ret = ((v-v_max)/math.abs(v_min-v_max))+1 
     else   v_ret = (v - v_min) / (v_max-v_min)   end
    return v_ret
  end

-----------------------------------------------------------------------
  function F_conv_norm2val(v_norm,v_min,v_max, inv)
    if inv then v = ((v_norm-1)*math.abs(v_min-v_max))+v_max
     else  v = v_norm*(v_max-v_min)+v_min   end
    return v
  end
  
-----------------------------------------------------------------------
  function F_extract_table(table,use)
    if table ~= nil then
      a = table[1]
      b = table[2]
      c = table[3]
      d = table[4]
    end  
    if use == 'rgb' then gfx.r,gfx.g,gfx.b = a,b,c end
    if use == 'xywh' then x,y,w,h = a,b,c,d end
    return a,b,c,d
  end 
  
-----------------------------------------------------------------------  
  function F_round(num, mult)
     local mult = 10^(idp or 0)
     return math.floor(num * mult + 0.5) / mult
  end
  
-----------------------------------------------------------------------
  function DEFINE_default_variables()
    sel_items_t ={}
    ------------------------- 
    window_time = 0.02 -- sec
    ------------------------- 
    fft_size = 256 -- bins
    ------------------------- 
    fft_start_min = 1
    fft_start = 1 -- hp
    fft_start_max = 10
    ------------------------- 
    fft_end_min =  11
    fft_end = 256 -- lp
    fft_end_max = 256
    ------------------------- 
    env_t_smooth_ratio = 0.1
    ------------------------- 
    mouse_res = 100 -- for knobs resolution
    mouse_res2 = 200 -- for sliders
    ------------------------- 
    strenght = 0
    -------------------------
    s_area1_min = 5 -- for RMS matching
    s_area1 = 20 --windows
    s_area1_max = 200
    
  end 
  
-----------------------------------------------------------------------  
  function ENGINE1_get_items()
    sel_items_t = {}
    item_data_t = {}
    count_items = reaper.CountSelectedMediaItems()
    if count_items ~= nil then 
      ref_item = reaper.GetSelectedMediaItem(0, 0)
      if ref_item ~= nil then
        ref_item_pos = reaper.GetMediaItemInfo_Value(ref_item,"D_POSITION")
        ref_item_len = reaper.GetMediaItemInfo_Value(ref_item,"D_LENGTH")
      end  
      for i =1, count_items do 
        item = reaper.GetSelectedMediaItem(0, i-1)
        if item ~= nil then
          take = reaper.GetActiveTake(item)
          if not reaper.TakeIsMIDI(take) then
            item_guid = reaper.BR_GetMediaItemGUID(item)
            item_pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
            item_len = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
            table.insert(sel_items_t, {item_guid,item_pos,reaper.GetTakeName(take)})
          end
        end    
      end        
    end    
  end

-----------------------------------------------------------------------
  function ENGINE1_get_item_data(guid, is_ref1)
    if #sel_items_t > 0 then
      item = reaper.BR_GetMediaItemByGUID(0, guid[1])
      if item ~= nil then
        item_pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
        item_len = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")                
        take = reaper.GetActiveTake(item) 
        track = reaper.GetMediaItem_Track(item)        
        if not reaper.TakeIsMIDI(take) then
          fft_val_t = {}
          audio_accessor = reaper.CreateTakeAudioAccessor(take)
            src = reaper.GetMediaItemTake_Source(take)
            src_num_ch = 1--reaper.GetMediaSourceNumChannels(src)
            src_rate = reaper.GetMediaSourceSampleRate(src)              

            window_samples = math.floor(src_rate * window_time)
    --loop through windows
            for read_pos = 0, item_len, window_time do              
              if read_pos+item_pos > ref_item_pos and read_pos+item_pos < ref_item_pos+ref_item_len then
                audio_accessor_buffer = reaper.new_array(window_samples)
                reaper.GetAudioAccessorSamples(audio_accessor,src_rate,src_num_ch,read_pos,window_samples,audio_accessor_buffer)
                
    -- fft aa buffer                  
                  audio_accessor_buffer.fft(fft_size, true, 1)
                  fft_sum = 0
                  audio_accessor_buffer_fft_t = audio_accessor_buffer.table(1, fft_size)
                  for i = fft_start, fft_end  do
                    value = audio_accessor_buffer_fft_t[i]
                    value_abs = math.abs(value)
                    fft_sum = fft_sum + value_abs
                  end
                  fft_sum = fft_sum / fft_size
                  table.insert(fft_val_t, fft_sum)
                 
                audio_accessor_buffer_t = {}
                audio_accessor_buffer.clear()                              
              end -- check if inside ref_item  
            end -- loop every window                    
          reaper.DestroyAudioAccessor(audio_accessor)  
          
    -- full edges
            if not is_ref1 then 
              -- fill table beginning
              offset1 = (item_pos - ref_item_pos)
              if offset1 > 0 then 
                for i = 1, math.floor(offset1/window_time) do
                  table.insert(fft_val_t, 1, 0)
                end
              end 
              -- fill table end
              offset2 = (item_pos + item_len - ref_item_pos - ref_item_len)
              if offset2 < 0 then 
                for i = 1, math.floor(math.abs(offset2)/window_time) do
                  table.insert(fft_val_t, 0)
                end
              end                           
            end
          
          
          _, trackname = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME','', false)
          if trackname == '' then trackname = '(no name)' end
          ret_name = trackname..'   /   '..reaper.GetTakeName(take)
        end -- if not midi  
      end -- if item ~= nil
      
      
     
      -- smooth fft table  
      for i =2, #fft_val_t do
        if fft_val_t[i]>fft_val_t[i-1] then fft_val_t[i] = fft_val_t[i]*(1-env_t_smooth_ratio) end
        if fft_val_t[i]<fft_val_t[i-1] then fft_val_t[i] = fft_val_t[i]*(1+env_t_smooth_ratio) end
      end  
      
      -- normalize fft table
        local max_com = 0
        for i =1, #fft_val_t-1 do max_com = math.max(max_com, fft_val_t[i]) end
        com_mult = 1/max_com      
        for i =1, #fft_val_t-1 do fft_val_t[i]= fft_val_t[i]*com_mult  end
        fft_val_t[1], fft_val_t[#fft_val_t] = 0,0
        
         
      return fft_val_t, ret_name, item_pos, item_len
    end -- sel_items_t ~= nil            
  end

-----------------------------------------------------------------------
  function ENGINE1_update_gui_data(cur_item)
    gui_ref_item_data_t, ref_item_name = 
      ENGINE1_get_item_data(sel_items_t[1],true)
    gui_cur_item_data_t, cur_item_name = 
      ENGINE1_get_item_data(sel_items_t[cur_item],false)
    update_gui_disp1 = true
    update_gui_disp2 = true
    gfx.setimgdim(1,-1,-1)
    gfx.setimgdim(2,-1,-1)
  end
  
-----------------------------------------------------------------------
  function ENGINE2_action_list(gui_params_set)
    if #sel_items_t < 2 then act='#'else act='' end
    actions_table = {'#Actions:|',
                    act..'Match item positions by fitting RMS',
                    }
    ret = gfx.showmenu(table.concat(actions_table, '|'))    
    if ret == 0 then 
      action_name = action_b_name 
      ret=gui_params_set
     else action_name = actions_table[ret] 
    end
    return action_name, ret
  end
  
-----------------------------------------------------------------------  
  function ENGINE3_find_offsets_by_RMS(set)
    
    offset_l = -s_area1 -- windows
    offset_r = s_area1
    if not set then
      if #sel_items_t > 1 then
        ref_RMS_t, _, ref_pos, ref_len = ENGINE1_get_item_data(sel_items_t[1], true)
        offsets_t = {0}
        for i = 2, #sel_items_t do
          cur_RMS_t, _, cur_pos = ENGINE1_get_item_data(sel_items_t[i], false)
          
          --create diff table
          diff_t = {}
          for offset = offset_l, offset_r, 1 do
            diff_com = 0
            for i = 1, #ref_RMS_t do
              if i+offset < 1 or i+offset > #cur_RMS_t then
               t2_val = 0 else t2_val = cur_RMS_t[i+offset] end
              diff = math.abs(ref_RMS_t[i] - t2_val)
              diff_com = diff + diff_com
            end
            table.insert(diff_t, diff_com)
          end
          
          -- find min diff id
          diff_t_min = math.huge
          for i = 1, #diff_t do
            diff_t_min0 = diff_t_min
            diff_t_it = diff_t[i]
            diff_t_min = math.min(diff_t_it, diff_t_min)
            if diff_t_min0 ~= diff_t_min then diff_t_min_id = i end
          end
          test1 = -(offset_l + diff_t_min_id)*window_time
          --create offset table
          table.insert(offsets_t, -(offset_l + diff_t_min_id)*window_time)
        end
      end
      
     else -- apply matching
      for i = 2, #sel_items_t do
        item = reaper.BR_GetMediaItemByGUID(0, sel_items_t[i][1])
        if item ~= nil then
          reaper.SetMediaItemInfo_Value(item,"D_POSITION",sel_items_t[i][2]+(offsets_t[i]*strenght))
          reaper.UpdateItemInProject(item)
        end
      end
    end
  end
  
-----------------------------------------------------------------------
  function DEFINE_default_variables_GUI()
    -- gfx buf1 - item env 1
    -- gfx buf2 - item env 2
    -- gfx buf3 - gradient back
    
    main_w = 440
    main_h = 340
    offset = 5
    offset2 = 2
    main_buttons_h = 22
    display_h = 40
    nav_button_h = 30
    max_display_time = 30 -- seconds    
    fontsize_b = fontsize   -- button
    fontsize_k = fontsize-2   -- knob
    
    get_b_name = 'Get selected items'
    action_b_name = 'Select action'
    info_b_name = 'Show action info'
    
    update_gui_disp1 = true 
    update_gui_disp2 = true -- fill blit buffer on start
    
    
    -- colors
      color5_t = {0.2, 0.2, 0.2} -- back1
      color6_t = {0.2, 0.25, 0.22} -- back2
      
      color1_t = {0.4, 1, 0.4} -- green
      color2_t = {0.5, 0.8, 1} -- blue      
      color3_t = {1, 1, 1}-- white
      color4_t = {0.8, 0.5, 0.2} -- red
      color7_t = {0.4, 0.6, 0.4} -- green dark
    --coordinates
      --get items button
        get_b_xywh_t = {offset, offset, main_w-offset*2, main_buttons_h}
      --peak display1
        peak_display1_xywh_t = {offset, 
          offset*2 + main_buttons_h, 
          main_w-offset*2, 
          display_h}
      --peak display2
        peak_display2_xywh_t = {offset, 
          offset*2 + main_buttons_h+display_h-1, 
          main_w-offset*2, 
          display_h} 
      -- navigation buttons       
        nav_buttons_xywh_t = {main_w - 180, 
          peak_display2_xywh_t[2]+ peak_display2_xywh_t[4]/2-nav_button_h/2+2,
          170,
          nav_button_h}
      -- nav1
        nav1_b_xywh_t= {nav_buttons_xywh_t[1]+offset,
          nav_buttons_xywh_t[2]+offset,
          (nav_buttons_xywh_t[3]-4*offset)/3,
          nav_buttons_xywh_t[4]-offset*2}
      -- nav2
        nav2_b_xywh_t= {nav_buttons_xywh_t[1]+offset*3+((nav_buttons_xywh_t[3]-4*offset)/3)*2,
          nav_buttons_xywh_t[2]+offset,
          (nav_buttons_xywh_t[3]-4*offset)/3,
          nav_buttons_xywh_t[4]-offset*2}    
      -- nav3
        nav3_b_xywh_t= {nav_buttons_xywh_t[1]+offset*2+(nav_buttons_xywh_t[3]-4*offset)/3,
          nav_buttons_xywh_t[2]+offset,
          (nav_buttons_xywh_t[3]-4*offset)/3,
          nav_buttons_xywh_t[4]-offset*2} 
      -- select action button
        action_b_xywh_t = {offset,
          peak_display2_xywh_t[2]+peak_display2_xywh_t[4]+offset,
          main_w-offset*2,
          main_buttons_h}
      -- knobs frame
        knobs_frame_xywh_t = {offset,   
          action_b_xywh_t[2]+action_b_xywh_t[4]+offset,
          main_w-offset*2,
          display_h*2}
          
           k_w =  (knobs_frame_xywh_t[3]-2*offset2)/7
           k_h = knobs_frame_xywh_t[4]-offset2*2
           knob_r = k_w/2-4
        -- knob 1
          k1_xywh_t = {offset+offset2,
           knobs_frame_xywh_t[2]+offset2,
           k_w,
           k_h }
        -- knob 2
          k2_xywh_t = {offset+offset2+k_w,
           knobs_frame_xywh_t[2]+offset2,
           k_w,k_h }
        -- knob 3
          k3_xywh_t = {offset+offset2+2*k_w,
           knobs_frame_xywh_t[2]+offset2,
           k_w,k_h }
        -- knob 4
          k4_xywh_t = {offset+offset2+3*k_w,
           knobs_frame_xywh_t[2]+offset2,
           k_w,k_h }
        -- knob 5
          k5_xywh_t = {offset+offset2+4*k_w,
           knobs_frame_xywh_t[2]+offset2,
           k_w,k_h }
        -- knob 6
          k6_xywh_t = {offset+offset2+5*k_w,
           knobs_frame_xywh_t[2]+offset2,
           k_w,k_h }
        -- knob 7
          k7_xywh_t = {offset+offset2+6*k_w,
           knobs_frame_xywh_t[2]+offset2,
           k_w,k_h }
           
      -- info button
        info_b_xywh_t = {offset,
          knobs_frame_xywh_t[2]+knobs_frame_xywh_t[4]+offset,
          main_w-offset*2,
          main_buttons_h}
          
      -- apply slider
        slider_xywh_t = {offset,
          info_b_xywh_t[2]+info_b_xywh_t[4]+offset,
          main_w-offset*2,
          display_h*2}
  end
  
-----------------------------------------------------------------------  
  function DEFINE_dynamic_variables_GUI()
    
  end

-----------------------------------------------------------------------
  function GUI_item_display(data_t, xywh_t, color_t, is_ref,update_gui_disp)
    -- draw item back gradient to buffer#3
    if is_1_time == nil then
       gfx.dest = 3
       F_extract_table(peak_display1_xywh_t, 'xywh')
       F_extract_table(color3_t, 'rgb')
       gfx.x,gfx.y, gfx.a = x,y, 1      
       gfx.setimgdim(3,w+x,h+y)
       gfx.gradrect(x,y,w,h, 1,1,1,0.4, 0,0,0,0.0001, 0,0,0,-0.01)
       is_1_time = 1
    end
     
    if data_t ~= nil then
      -- gradient
        if is_ref then 
          F_extract_table(peak_display1_xywh_t, 'xywh') 
          gfx.x,gfx.y, gfx.a = x,y, 1   
          gfx.blit(3,1,0,x,y,w,h)
         else
          x1,y1,w1,h1 = F_extract_table(peak_display1_xywh_t) 
          F_extract_table(peak_display2_xywh_t,'xywh') 
          gfx.x,gfx.y, gfx.a = x,y, 1   
          rad = math.rad(-180)
          gfx.blit(3,1,rad)
        end 
         
      -- draw frame    
        F_extract_table(xywh_t, 'xywh')  
        gfx.a = 0.05
        if is_ref then h = h-1 end 
        gfx.roundrect(x,y,w,h,0.1, true)        
       
      -- draw envelope        
        F_extract_table(xywh_t, 'xywh') 
        x=x+1
        w=w-1
        if is_ref then blit_buf = 1 else blit_buf = 2 end
        if update_gui_disp == true then  
          gfx.dest = blit_buf   
          gfx.setimgdim(blit_buf, w+x, h+y)
          F_extract_table(color_t, 'rgb') gfx.a = 1
          if is_ref then h=h-2 else h=h-1 end
          for i=1, #data_t-1 do
            data_t_it = data_t[i]
            data_t_it2 = data_t[i+1]
            if is_ref then            
              gfx.triangle(x+i*w/#data_t,    y+h-h*data_t_it,
                         x+(i+1)*w/#data_t-1,y+h-h*data_t_it2,
                         x+(i+1)*w/#data_t-1,y+h,
                         x+i*w/#data_t,    y+h )
             else
              gfx.triangle(x+i*w/#data_t,    y+h*data_t_it,
                         x+(i+1)*w/#data_t-1,y+h*data_t_it2,
                         x+(i+1)*w/#data_t-1,y,
                         x+i*w/#data_t,    y )   
            end                    
          end -- envelope building
          gfx.x,gfx.y = x,y
          gfx.blurto(x+w,y+h)
          update_gui_disp = false
         else
          gfx.x,gfx.y,gfx.a = x,y,0.7
          gfx.dest = -1
          gfx.blit(blit_buf, 1, 0, 
                     x, y, w, h,
                     x, y, w, h)
        end
        gfx.dest = -1 
     end 
   return update_gui_disp
  end
  
-----------------------------------------------------------------------
  function GUI_button(xywh_t, name, b_mouse_state, font_color_t)      
      --fill background
        F_extract_table(color3_t, 'rgb')
        F_extract_table(xywh_t, 'xywh')
        if b_mouse_state == 2 then gfx.a = 0.5 else gfx.a = 0.04 end
        gfx.rect(x,y,w,h)
           
      -- draw name -- 
        gfx.setfont(1, font, fontsize_b)
        measurestrname = gfx.measurestr(name)  
        x0 = x + (w - measurestrname)/2
        y0 = y + (h - fontsize)/2
        gfx.x, gfx.y = x0,y0
        F_extract_table(font_color_t, 'rgb')
        gfx.a = 1
        gfx.drawstr(name)
      
      --b_mouse_state 
        -- 0 - not active
        -- 1 - under cursor
        -- 2 - pressed
        if b_mouse_state == 1 then  
          F_extract_table(color3_t, 'rgb')
          gfx.a = 0.2
          gfx.roundrect(x,y,w,h,0.1, true) end
        if b_mouse_state == 2 then  
          F_extract_table(color1_t, 'rgb')
          gfx.a = 0.2
          gfx.roundrect(x,y,w,h,0.1, true) end          
  end

-----------------------------------------------------------------------
  function GUI_knob(xywh_t,val,knob_val,knob_name)
      
    -- frame -- 
      F_extract_table(xywh_t,'xywh')
      F_extract_table(color3_t, 'rgb')
      gfx.a = 0.0
      gfx.rect(x,y,w,h, false)
      
    -- out arc
      F_extract_table(color3_t, 'rgb')
      gfx.a = 0.5
      gfx.x,gfx.y = x,y
      gfx.arc(x+w/2-1,y+knob_r+offset,knob_r,math.rad(-135),math.rad(135),0.9)
      
    -- circ
      F_extract_table(color1_t, 'rgb')
      gfx.a = 1
      if val ~= nil then
        val_grad = val*240-30
        circ_x = x+w/2 - knob_r*math.cos(math.rad(val_grad))-1
        circ_y = y+knob_r+offset - knob_r*math.sin(math.rad(val_grad))
        gfx.circle(circ_x,circ_y,3,1,2)
      end 
      
    --[[ pointer
      gfx.dest = -1
      gfx.a = 1
      x1,y1,w1,h1 = F_extract_table(k1_xywh_t)
      F_extract_table(xywh_t,'xywh')
      gfx.x,gfx.y = x,y
      gfx.blit(5,1,0,x,y,w,h)]]
      
    -- val
      gfx.setfont(1, font, fontsize_k)
      local measurestrname = gfx.measurestr(knob_val)  
      gfx.x, gfx.y = x+w/2-measurestrname/2, y+knob_r-2
      F_extract_table(color3_t, 'rgb')
      gfx.a = 1
      gfx.drawstr(knob_val)
      
    -- name
      gfx.setfont(1, font, fontsize_k)
      F_extract_table(color3_t, 'rgb')
      gfx.a = 1
      if gfx.measurestr(knob_name) > w then
        for word,word2 in string.gmatch(knob_name, "(%w+) (%w+)") do w1= word w2= word2  end
        gfx.x, gfx.y = x+w/2-gfx.measurestr(w1)/2+1, y+h-fontsize_k*2+2
        gfx.drawstr(w1)
        gfx.x, gfx.y = x+w/2-gfx.measurestr(w2)/2+1, y+h-fontsize_k
        gfx.drawstr(w2)
       else
        gfx.x, gfx.y = x+w/2-gfx.measurestr(knob_name)/2+1, y+h-fontsize_k*1.5
        gfx.drawstr(knob_name)
      end
  end
  
-----------------------------------------------------------------------  
  function GUI_params(gui_params_set)
    if gui_params_set ~= nil then
      -- draw frame    
        F_extract_table(knobs_frame_xywh_t, 'xywh') 
        F_extract_table(color3_t,'rgb') 
        gfx.a = 0.05
        gfx.roundrect(x,y,w,h,0.1, true)    
                    
      -- match positions by rms    
        if gui_params_set == 2 then        
          -- k1
            k1_val = math.floor((fft_start-1)*22050/fft_size)..'Hz'
              GUI_knob(k1_xywh_t, k1_val_norm, k1_val, "HP")
          -- k2  
            k2_val =   fft_end*22050/fft_size
              if k2_val > 1000 then k2_val = math.floor(k2_val/1000)..'kHz'
              else k2_val = math.floor(k2_val)..'Hz' end
              GUI_knob(k2_xywh_t, k2_val_norm, k2_val, "LP")
          -- k3
            k3_val = math.floor(s_area1*window_time*1000)..'ms'
              GUI_knob(k3_xywh_t, k3_val_norm, k3_val, "Search Area")  
            
          -- show action info  
              GUI_button(info_b_xywh_t, info_b_name, info_b_mouse_state,color3_t)
              
          -- s1
            s1_val = 'Apply matching: '..math.floor(strenght*100)..' %'
            GUI_slider(slider_xywh_t, s1_val_norm, s1_val)  
            
        end   
          
                 
    end -- draw knobs
  end
  
-----------------------------------------------------------------------  
  function GUI_slider (xywh_t,val_norm, s1_val)
    -- draw slider gradient to buffer#4
    if is_1_time2 == nil then
      gfx.dest = 4
      F_extract_table(slider_xywh_t, 'xywh')
      r,g,b = F_extract_table(color3_t,'rgb')
      gfx.setimgdim(4,w+x,h+y)
      gfx.a, a = 1, 0  
      gfx.gradrect(x,y,w,h, r,g,b,a, 
      0, 0.002, 0, 0.001, 
      0, 0.002, 0, 0.005) 
      is_1_time2 = 1
    end 
    
    gfx.dest = -1
    --draw frame
      -- draw frame    
        F_extract_table(xywh_t, 'xywh') 
        F_extract_table(color3_t,'rgb') 
        gfx.a = 0.05
        gfx.roundrect(x,y,w,h,0.1, true) 
        
      --  blit from buffer 4
        gfx.x,gfx.y,gfx.a = x,y,0.7
        gfx.dest = -1
        gfx.blit(4,1,0, x,y,w*val_norm,h,x,y,w*val_norm,h)
     
      -- draw name -- 
        gfx.setfont(1, font, fontsize_b)
        measurestrname = gfx.measurestr(s1_val)  
        x0 = x + (w - measurestrname)/2
        y0 = y + (h - fontsize)/2
        gfx.x, gfx.y = x0,y0
        F_extract_table(font_color_t, 'rgb')
        gfx.a = 1
        gfx.drawstr(s1_val)    
      
  end 
  
                
-----------------------------------------------------------------------
  function GUI_DRAW()
    --[[ dest
    1 - item1wave // update_gui_disp1
    2 - item2 wave // update_gui_disp2
    3 - backgr item display // is_1_time
    4 - slider backgr // is_1_time2
    -- rotation trouble 5 - knob pointer // is_1_time3]]
    
    --[[ pointer to buffer
      if is_1_time3 == nil then
        gfx.dest = 5
        F_extract_table(k1_xywh_t,'xywh')
        gfx.setimgdim(5,w+x,h+y)        
        F_extract_table(color3_t, 'rgb')
        
        gfx.a = 1
        gfx.rect(x+5,y+5,w-10,h-10)
        --gfx.triangle(x+w/2, y+8,  x+w/2+1,y+4,  x+w/2-1,y+4)
        is_1_time3 = 1 
      end      ]]
    
    gfx.dest = -1
    -- background
      F_extract_table(color5_t,'rgb')
      gfx.a = 1
      gfx.rect(0,0,main_w,main_h)
      
    -- get items
      GUI_button(get_b_xywh_t, get_b_name, get_b_mouse_state,get_b_name_col) 
       
         
    -- items display
      if #sel_items_t > 0  then 
        -- first display
        update_gui_disp1 = 
          GUI_item_display(gui_ref_item_data_t,peak_display1_xywh_t,color1_t,true,update_gui_disp1)
        if #sel_items_t == 1 then  
          update_gui_disp2 = GUI_item_display(gui_ref_item_data_t,peak_display2_xywh_t,color7_t,false,update_gui_disp2) end
        if #sel_items_t > 1 then
          -- second display
          update_gui_disp2 = 
            GUI_item_display(gui_cur_item_data_t,peak_display2_xywh_t,color2_t,false,update_gui_disp2)
          if show_item_nav then
            -- draw nav back
              F_extract_table(color5_t,'rgb')
              F_extract_table(nav_buttons_xywh_t,'xywh')
              gfx.a = 0.7
              gfx.rect(x,y,w,h)
            -- buttons
              GUI_button(nav1_b_xywh_t, '<', nav1_b_mouse_state ,color2_t)
              GUI_button(nav2_b_xywh_t, '>', nav2_b_mouse_state ,color2_t)
              GUI_button(nav3_b_xywh_t, cur_item..' / '..#sel_items_t, nav3_b_mouse_state ,color2_t)
          end
        end --if sel item > 1
        
      -- select action button
        GUI_button(action_b_xywh_t, action_b_name, action_b_mouse_state,color3_t)
        
      -- parameters set
        GUI_params(gui_params_set)
          
          
      end --  if sel item > 0
      
    gfx.update()    
  end
  
-----------------------------------------------------------------------
  function MOUSE_knob(xywh_t,last_mouse_obj_name,knob_val_norm0 , knob_val_norm)
    if MOUSE_gate(1, xywh_t) and not last_LMB_state then
      knob_val_norm0 = knob_val_norm
      last_mouse_obj = last_mouse_obj_name
    end
    
    if LMB_state and last_mouse_obj == last_mouse_obj_name and knob_val_norm0 ~= nil then
      knob_val_norm = my_rel/mouse_res + knob_val_norm0
      knob_val_norm = F_limit(knob_val_norm, 0, 1) 
    end
    
    return last_mouse_obj, knob_val_norm0, knob_val_norm  
  end
  
-----------------------------------------------------------------------
  function MOUSE_slider(xywh_t,last_mouse_obj_name,s_val_norm0 , s_val_norm)
    if MOUSE_gate(1, xywh_t) and not last_LMB_state then
      s_val_norm0 = s_val_norm
      last_mouse_obj = last_mouse_obj_name
    end
    
    if LMB_state and last_mouse_obj == last_mouse_obj_name and s_val_norm0 ~= nil then
      s_val_norm =  s_val_norm0 - mx_rel/mouse_res2
      s_val_norm = F_limit(s_val_norm, 0, 1) 
    end
    
    return last_mouse_obj, s_val_norm0, s_val_norm  
  end
  
-----------------------------------------------------------------------
  function MOUSE_gate2(mb, b)
    local state    
    if MOUSE_match_xy(b) then       
     if mb == 1 then if LMB_state then state = true else state = false end end
     if mb == 2 then if RMB_state then state = true else state = false end end 
     if mb == 64 then if MMB_state then state = true else state = false end end        
    end   
    return state
  end

-----------------------------------------------------------------------
  function MOUSE_gate(mb, b)
    local state    
    if MOUSE_match_xy(b) then       
     if mb == 1 then if LMB_state and not last_LMB_state then state = true else state = false end end
     if mb == 2 then if RMB_state and not last_RMB_state then state = true else state = false end end 
     if mb == 64 then if MMB_state and not last_MMB_state then state = true else state = false end end        
    end   
    return state
  end
  
-----------------------------------------------------------------------
  function MOUSE_match_xy(b)
    if    mx > b[1] 
      and mx < b[1]+b[3]
      and my > b[2]
      and my < b[2]+b[4] then
     return true 
    end 
  end
  
-----------------------------------------------------------------------  
  function MOUSE_param_set()
    if gui_params_set ~= nil then
    
      -- Match by RMS
        if gui_params_set == 2 then       
          -- HP
            k1_val_norm = F_conv_val2norm(fft_start, fft_start_min, fft_start_max,false)
            last_mouse_obj, k1_val_norm0, k1_val_norm = 
              MOUSE_knob(k1_xywh_t, 'k1',k1_val_norm0, k1_val_norm)
            fft_start = math.floor(F_conv_norm2val(k1_val_norm,fft_start_min, fft_start_max,false))
          -- LP
            k2_val_norm = F_conv_val2norm(fft_end, fft_end_min, fft_end_max,false)
            last_mouse_obj, k2_val_norm0, k2_val_norm = 
              MOUSE_knob(k2_xywh_t, 'k2',k2_val_norm0, k2_val_norm)
            fft_end = math.floor(F_conv_norm2val(k2_val_norm,fft_end_min, fft_end_max,false))  
          -- search area
            k3_val_norm = F_conv_val2norm(s_area1, s_area1_min, s_area1_max,false)
            last_mouse_obj, k3_val_norm0, k3_val_norm = 
              MOUSE_knob(k3_xywh_t, 'k3',k3_val_norm0, k3_val_norm)
            s_area1 = math.floor(F_conv_norm2val(k3_val_norm,s_area1_min, s_area1_max,false))              
          -- APPLY
            s1_val_norm = strenght
            last_mouse_obj, s1_val_norm0, s1_val_norm = 
              MOUSE_slider(slider_xywh_t, 's1',s1_val_norm0, s1_val_norm)
            strenght = s1_val_norm
            if last_mouse_obj == 's1' and LMB_state then
              ENGINE3_find_offsets_by_RMS(true) end
          -- analize when selecting action
            if last_gui_params_set == nil then ENGINE3_find_offsets_by_RMS(false) end
        end
      
    end
    
    
    -- info button     
      if MOUSE_gate2(1, info_b_xywh_t) then -- gui state
        info_b_mouse_state = 2          
        elseif MOUSE_match_xy(info_b_xywh_t) then 
        info_b_mouse_state = 1 
        else info_b_mouse_state = 0 end
      if MOUSE_gate(1, info_b_xywh_t) then
        -- Match by RMS
        if gui_params_set == 2 then
          reaper.ShowConsoleMsg('')
          str_info = 
[===[
  Match item positions by RMS
  
  Find "best fit" beetween windowed RMS envelopes of selected slave items and reference (topmost) item.
  Measured signal is FFT filtered via HP and LP cutoff knobs.
  Search area means area for searching "best fit", so if search area is 400 ms and slave item position is 2seconds from project start, script will searching for "best fit" beetween 1.6sec and 2.4seconds possible item position. 
          
  Current offsets:
  
]===]
          for i = 2, #sel_items_t do
            str_info = str_info ..'  '..sel_items_t[i][3]..'\n'..
                 '              Offset '..offsets_t[i]..'ms'..'\n'
          end
          reaper.ShowConsoleMsg(str_info)
        end
      end 
    
  end  
  
----------------------------------------------------------------------- 
  function MOUSE_param_set_on_release()
  -- release actions
    if last_LMB_state and not MB_state then
    
      if gui_params_set == 2 then -- if match RMS
        if last_mouse_obj == 'k1' or  -- HP
           last_mouse_obj == 'k2' or -- LP
           last_mouse_obj == 'k3' then -- search
          ENGINE1_update_gui_data(cur_item)
          ENGINE3_find_offsets_by_RMS(false)
        end
      end
      
    end -- release actions   
  end
  
-----------------------------------------------------------------------
  function MOUSE_get()
    cur_time = os.clock()
    timer = 0.5
    LMB_state = gfx.mouse_cap&1 == 1 
    RMB_state = gfx.mouse_cap&2 == 2 
    MMB_state = gfx.mouse_cap&64 == 64         
    if LMB_state or RMB_state or MMB_state then MB_state = true else MB_state = false end
    if last_LMB_state or last_RMB_state or last_MMB_state then last_MB_state = true else last_MB_state = false end    
    mx, my = gfx.mouse_x, gfx.mouse_y
    if LMB_state and not last_LMB_state then mx0,my0 = mx,my else  end
    if mx0 ~= nil and my0 ~= nil then    mx_rel,my_rel = mx0-mx, my0-my end
    
    MOUSE_param_set_on_release()
    
    if not last_LMB_state then last_mouse_obj = nil end
    
    -- get items button     
      if MOUSE_gate2(1, get_b_xywh_t) then -- gui state
        get_b_mouse_state = 2          
        elseif MOUSE_match_xy(get_b_xywh_t) then 
        get_b_mouse_state = 1 
        else get_b_mouse_state = 0 end
      if MOUSE_gate(1, get_b_xywh_t) then --action
        ENGINE1_get_items()
        ENGINE1_update_gui_data(cur_item)
        gui_params_set = nil
        action_b_name = 'Select action'
      end  
      
    -- show item names
      if MOUSE_match_xy(peak_display1_xywh_t) and #sel_items_t > 0 then
        get_b_name = ref_item_name get_b_name_col = color1_t 
       elseif MOUSE_match_xy(peak_display2_xywh_t) and #sel_items_t > 1 then
        get_b_name = cur_item_name get_b_name_col = color2_t
        show_item_nav = true
       else get_b_name = 'Get selected items' get_b_name_col = color3_t show_item_nav = false end
    
    -- navigation buttons
      -- prev nav button
        if MOUSE_gate2(1, nav1_b_xywh_t) then -- gui state
          nav1_b_mouse_state = 2          
          elseif MOUSE_match_xy(nav1_b_xywh_t) then 
          nav1_b_mouse_state = 1 
          else nav1_b_mouse_state = 0 end
        if MOUSE_gate(1, nav1_b_xywh_t) then --action
          cur_item = cur_item - 1 
          if cur_item <2 then cur_item = 2 end
          ENGINE1_update_gui_data(cur_item)
        end       
      -- next nav button
        if MOUSE_gate2(1, nav2_b_xywh_t) then -- gui state
          nav2_b_mouse_state = 2          
          elseif MOUSE_match_xy(nav2_b_xywh_t) then 
          nav2_b_mouse_state = 1 
          else nav2_b_mouse_state = 0 end
        if MOUSE_gate(1, nav2_b_xywh_t) then --action
          cur_item = cur_item + 1 
          if cur_item > #sel_items_t then cur_item = #sel_items_t end 
          ENGINE1_update_gui_data(cur_item)
        end         
        
      -- select item button
        if MOUSE_gate2(1, nav3_b_xywh_t) then -- gui state
          nav3_b_mouse_state = 2          
          elseif MOUSE_match_xy(nav3_b_xywh_t) then 
          nav3_b_mouse_state = 1 
          else nav3_b_mouse_state = 0 end
        if MOUSE_gate(1, nav3_b_xywh_t) then --action
          menustring = ""             
          for i = 1, #sel_items_t do 
            item = reaper.BR_GetMediaItemByGUID(0, sel_items_t[i][1])
            track = reaper.GetMediaItem_Track(item)
            retval, trackname = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME','', false)
            take = reaper.GetActiveTake(item) 
            take_name = reaper.GetTakeName(take)
            menustring = menustring..trackname..' / '..take_name..'|' 
            if i == 1 then menustring = menustring .."|" end end  
            menu_ret = gfx.showmenu(menustring) 
            if menu_ret ~= 0 and menu_ret ~= 1 then cur_item = math.floor(menu_ret) end          
          ENGINE1_update_gui_data(cur_item)
        end  
        
      -- select action button
        if MOUSE_gate2(1, action_b_xywh_t) then -- gui state
        action_b_mouse_state = 2          
        elseif MOUSE_match_xy(action_b_xywh_t) then 
        action_b_mouse_state = 1 
        else action_b_mouse_state = 0 end
        if MOUSE_gate(1, action_b_xywh_t) then --action
          gfx.x,gfx.y = mx,my
          action_b_name, gui_params_set = ENGINE2_action_list(gui_params_set)        
        end         
      
      MOUSE_param_set()
        
    last_LMB_state = LMB_state    
    last_RMB_state = RMB_state
    last_MMB_state = MMB_state 
    last_gui_params_set = gui_params_set   
  end        
  
-----------------------------------------------------------------------
  function MAIN_exit() gfx.quit() end  
  
-----------------------------------------------------------------------
  function MAIN_run()
    DEFINE_dynamic_variables_GUI()
    GUI_DRAW()
    MOUSE_get()
    char = gfx.getchar()
    if char == 27 then MAIN_exit() end     
    if char ~= -1 then reaper.defer(MAIN_run) else MAIN_exit() end
  end 
  
----------------------------------------------------------------------- 
  DEFINE_default_variables_GUI()
  DEFINE_default_variables()
  gfx.init("mpl Warping tool // "..vrs..' DEVELOPER PREVIEW', main_w, main_h)
  reaper.atexit(MAIN_exit)  
  
  
  if get_selected_items_on_start == 1 then
    ENGINE1_get_items()
    cur_item=2
    ENGINE1_update_gui_data(cur_item)
  end
  
  MAIN_run()   
  
  
  
  
  
  
  
  
  
  
  
  
  br = [===[---------------------------------------------------------------------------------------------------------------  
 

  
  ---------------------------------------------------------------------------------------------------------------       
  
  ---------------------------------------------------------------------------------------------------------------         

  ---------------------------------------------------------------------------------------------------------------       
  unction ENGINE2_get_stretch_markers(data_t)
    sm_data_t = {}
    --if rise more than % of min point in prev search area then >
    -- > search further area for max point
      for i = 1, s_area do
        table.insert(sm_data_t,0)
      end
      for i = 2+s_area, #data_t-1 do
        if sm_data_t[i] == nil then
          data_t_item = data_t[i]
          data_t_item_area_min = math.huge
          for j = i-s_area-1, i-1 do
            data_t_item_area = data_t[j]
            data_t_item_area_min = math.min(data_t_item_area,data_t_item_area_min)
          end
          if (data_t_item/data_t_item_area_min)*100 > rise_percent then
            -- check further area max point
            data_t_item_area_max = 0
            for k = i, i + s_area2 do
              if k < #data_t then
                data_t_item_area_max0 = data_t_item_area_max
                data_t_item_area = data_t[k]
                data_t_item_area_max = math.max(data_t_item_area_max,data_t_item_area)
                data_t_item_area_max1 = data_t_item_area_max
                if data_t_item_area_max0 ~= data_t_item_area_max1 then                
                  current_max_id = k
                end
              end
            end
            rise_percent2 = 150
            if (data_t[current_max_id]/data_t[i])*100 > rise_percent2 then
              current_max_id = i 
            end
             
            if current_max_id ~= i then  
              for m = 1, current_max_id-i do
                table.insert(sm_data_t,0)
              end
              table.insert(sm_data_t,1)
             else
              --table.insert(sm_data_t,1)
            end
           else
            table.insert(sm_data_t,0)
          end
        end
      end
    --[[if rise more than % of min point in search area
      for i = 1, s_area do
        table.insert(sm_data_t,0)
      end
      for i = 2+s_area, #data_t-1 do
        if sm_data_t[i] == nil then
          data_t_item = data_t[i]
          data_t_item_area_min = math.huge
          for j = i-s_area-1, i-1 do
            data_t_item_area = data_t[j]            
            data_t_item_area_min = math.min(data_t_item_area,data_t_item_area_min)
          end
          --test = data_t_item/data_t_item_area_min
          if (data_t_item/data_t_item_area_min)*100 > rise_percent then
           --if sm_data_t[#sm_data_t] == 0 then
             table.insert(sm_data_t,1)
            else
             table.remove(sm_data_t,#sm_data_t)
             table.insert(sm_data_t,0)
             if data_t[i] > data_t[i+1] then
               table.insert(sm_data_t,1)
              else
               table.insert(sm_data_t,0)
               table.insert(sm_data_t,#sm_data_t, 1)
             end
           else
            table.insert(sm_data_t,0)
          end
        end
      end]]
    -- filt 1
    --[[search max point around couple of windows + add to table
      for i = 1, #data_t, s_area do
        if i+s_area-1 < #data_t then
          -- 2 search max point value in window
          local max_point = 0
          for j =0, s_area-1 do
            data_t_item = data_t[i+j]
            max_point = math.max(max_point, data_t_item)
          end           
          for j =0, s_area-1 do
            data_t_item = data_t[i+j]
            -- check if max point around couple of windows more than thresold
            if data_t_item == max_point and 20*math.log(max_point) > threshold then
              table.insert(sm_data_t,i+j,1)              
             else table.insert(sm_data_t,i+j,0)
            end
          end            
        end
      end   ]]
    -- filt 2    
    --[[area2 search closer sm, delete lower
    for i = 1, #sm_data_t do
      sm_it = sm_data_t[i]
      if sm_it == 1 then
        data_t_it = data_t[i]
        -- search further area
          data_t_area2_max = 0
          for j = i + 1, i + s_area2 do
            if j > #sm_data_t then j = #sm_data_t end
            if sm_data_t[j] == 1 then
              data_t_area2 = data_t[j]
              data_t_area2_max = math.max(data_t_area2_max , data_t_area2 )
            end  
          end 
          if data_t_it < data_t_area2_max  then 
            table.insert(sm_data_t,i,0)
            table.remove(sm_data_t,i+1)
          end
        -- search prev area
          data_t_area2_max = 0
          for j = i-s_area2 , i -1 do
            if j < 1 then j = 1 end
            if sm_data_t[j] == 1 then
              data_t_area2 = data_t[j]
              data_t_area2_max = math.max(data_t_area2_max , data_t_area2 )
            end  
          end 
          if data_t_it < data_t_area2_max  then 
            table.insert(sm_data_t,i,0)
            table.remove(sm_data_t,i+1)
          end        
      end      
    end]]
    -- threshold filter
    for i = 1, #sm_data_t do
      sm_data_it = sm_data_t[i]
      if sm_data_it == 1 then
        if 20*math.log(data_t[i]) < threshold then
          sm_data_t[i] = 0
        end
      end
    end
    
        
 
  
  
  
  
  
  -- calculate tempo average
    -- get tempo for each marker
      tempo_t0 = {}
      for i =1, #sm_t do
        sm_it = sm_t[i]
        if sm_it == 1 then 
          if last_sm_id ~= nil then
            tempo_v = 60/((i - last_sm_id)*window_time)
            table.insert(tempo_t0, tempo_v)
          end              
          last_sm_id = i                
        end
      end
      tempo_t0_sum = 0
      count0 = 1
      last_id0 = 1
      last_id = 1
      for i = 2, #sm_t do
        sm_it = sm_t[i]
        if sm_it == 1 then last_id = i end
        tempo_v = 60/(last_id - last_id0)
        if tempo_v > 0 then 
          tempo_t0_sum = (tempo_t0_sum+tempo_v)
          table.insert(tempo_t0, tempo_v)
          count0 = count0 +1
        end            
        last_id0 = last_id
      end      
      tempo_average0 = tempo_t0_sum / count0      
      average_lim_per = 5
      average_lim =average_lim_per /100 -- %      
    -- filter from 10% average0    
      tempo_average_sum = 0   
      count = 1
      for i = 1, #tempo_t0 do
        tempo_t0_it = tempo_t0[i]
        diff = tempo_average0 / tempo_t0_it
        if diff > (1-average_lim) and diff <(1+average_lim) then
          tempo_average_sum = tempo_average_sum+tempo_t0_it
          count = count +1
        end
      end
      tempo_average_calc = 60/((tempo_average_sum/count)*window_time)
  
  
  
  
         
                
               --[[ cur_item = 1 
                -------------------------                     
                window_time_min = 0.01
                window_time_max = 0.3                
                -------------------------                     
                threshold = -25
                threshold_min = -70
                threshold_max = -10    
                ------------------------- 
                s_area = 1 -- windows
                s_area_min = 1
                s_area_max = 30
                ------------------------- 
                s_area2 = 30 -- windows
                s_area2_min = 3
                s_area2_max = 100
                ------------------------- 
                rise_percent = 140 -- percent
                rise_percent_min = 101
                rise_percent_max = 500    
                ------------------------- 
                
       
      -- draw sm
        local sm_t = data_t[7]
        extract_table(color4_t,true)
        gfx.a = 0.9
        for i=1,#sm_t do
          sm_t_item = sm_t[i]
          if sm_t_item == 1 then
            if is_ref then
              gfx.line(   X+W/#com_val_t*(i-1),  Y+H,    X+W/#com_val_t*(i-1),   Y+H-H*0.15,1)
             else gfx.line(   X+W/#com_val_t*(i-1),  Y,    X+W/#com_val_t*(i-1),   Y+H*0.15,1)
            end
          end
        end--end draw sm
        
        
      
      --[[ draw tempo
        --fill background
        extract_table(color6_t, true)
        gfx.a = 0.92
        gfx.rect(15,20,50,20)
        gfx.x,gfx.y = 20,20
        --draw val
        extract_table(color4_t, true)
        gfx.a = 0.92
        tempo = data_t[8]
        gfx.drawstr(tostring(tempo))
          
 
 --[[if MOUSE_gate(2, xywh_t) then
   local knob_retval, knob_return_s = reaper.GetUserInputs(inputname1, 1, inputname2, "") 
   if knob_retval ~= nil then
     knob_return = tonumber(knob_return_s)
     if knob_return ~= nil then
       knob_user_return = limit(knob_return,lim1,lim2)
       last_mouse_obj = last_mouse_obj_name
       LMB_state = true
       return last_mouse_obj, knob_val_norm, knob_user_return
     end
   end
 end
 ]]
               
 ]===]
 
   
