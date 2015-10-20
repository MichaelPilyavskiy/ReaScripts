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


  vrs = "0.2"
 
  ---------------------------------------------------------------------------------------------------------------              
  changelog =                              
[===[ Changelog:
20.10.2015  0.20
            code: structure improvements
            code: optionally get items on start
            gui: structure improvements
            gui: action selector(hidden)
            gui: gfxblit graphics - saves cpu A LOT, thanks James HE!
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
  function DEFINE_default_variables()
    sel_items_t ={}
    ------------------------- 
    window_time = 0.01 -- sec
    ------------------------- 
    fft_size = 128 -- bins
    fft_start = 1 -- hp
    fft_end = 128 -- lp
    ------------------------- 
    env_t_smooth_ratio = 0.1
    ------------------------- 
    
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
            table.insert(sel_items_t, item_guid)
          end
        end    
      end        
    end    
  end

-----------------------------------------------------------------------
  function ENGINE1_get_item_data(guid, is_ref1, for_gui)
    if #sel_items_t > 0 then
      item = reaper.BR_GetMediaItemByGUID(0, guid)
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
          
          if for_gui then
            if not is_ref1 then 
              offset1 = (item_pos - ref_item_pos)
              if offset1 > 0 then 
                -- fill table beginning
                for i = 1, math.floor(offset1/window_time) do
                  table.insert(fft_val_t, 1, 0)
                end
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
        
         
      return fft_val_t,ret_name, item_pos, item_len
    end -- sel_items_t ~= nil            
  end

-----------------------------------------------------------------------
  function ENGINE1_update_gui_data()
    gui_ref_item_data_t, ref_item_name = 
      ENGINE1_get_item_data(sel_items_t[1],true,true)
    if #sel_items_t < 2 then cur_item = 1 else cur_item = 2 end
    gui_cur_item_data_t, cur_item_name = 
      ENGINE1_get_item_data(sel_items_t[cur_item],false,true)
    update_gui_disp1 = true
    update_gui_disp2 = true
    gfx.setimgdim(1,-1,-1)
    gfx.setimgdim(2,-1,-1)
  end
  
-----------------------------------------------------------------------
  function ENGINE2_action_list()
    if #sel_items_t < 2 then act='#'else act='' end
    actions_table = {act..'Match item positions by fitting RMS',
                    }
    ret = gfx.showmenu(table.concat(actions_table, '|'))    
    if ret == 0 then action_name = action_b_name 
      else action_name = actions_table[ret] end
    return action_name, ret
  end
  
-----------------------------------------------------------------------
  function DEFINE_default_variables_GUI()
    -- gfx buf1 - item env 1
    -- gfx buf2 - item env 2
    -- gfx buf3 - gradient back
    
    main_w = 440
    main_h = 355
    offset = 5
    main_buttons_h = 22
    display_h = 40
    nav_button_h = 30
    max_display_time = 30 -- seconds    
    fontsize_b = fontsize        
    get_b_name = 'Get selected items'
    action_b_name = 'Select action'
    update_gui_disp1 = true 
    update_gui_disp2 = true -- fill blit buffer on start
    -- colors
      color5_t = {0.2, 0.2, 0.2} -- back1
      color6_t = {0.2, 0.25, 0.22} -- back2
      
      color1_t = {0.4, 1, 0.4} -- green
      color2_t = {0.5, 0.8, 1} -- blue      
      color3_t = {1, 1, 1}-- white
      color4_t = {0.8, 0.5, 0.2} -- red

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
              
                                
  end
  
-----------------------------------------------------------------------  
  function DEFINE_dynamic_variables_GUI()
    
  end

-----------------------------------------------------------------------
  function GUI_item_display(data_t, xywh_t, color_t, is_ref,update_gui_disp)
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
    local x,y,w,h = extract_table(xywh_t)
    
    -- frame -- 
      extract_table(color3_t, true)
      gfx.a = frame_knob
      gfx.roundrect(x,y,w,h,0.1, true)
    -- out arc
      extract_table(color3_t, true)
      gfx.a = frame_knob_outarc
      gfx.x,gfx.y = x,y
      gfx.arc(x+w/2,y+knob_r+offset,knob_r,math.rad(-130),math.rad(130),1)
    -- circ
      extract_table(color1_t, true)
      gfx.a = 1
      if val ~= nil then
        val_grad = val*240-30
        circ_x = x+w/2 - knob_r*math.cos(math.rad(val_grad))
        circ_y = y+knob_r+offset - knob_r*math.sin(math.rad(val_grad))
        gfx.circle(circ_x,circ_y,3,1,2)
      end 
    -- val
      gfx.setfont(1, font, fontsize3)
      local measurestrname = gfx.measurestr(knob_val)  
      gfx.x, gfx.y = x+w/2-measurestrname/2, y+knob_r-2
      extract_table(color3_t, true)
      gfx.a = 1
      gfx.drawstr(knob_val)
    -- name
      gfx.setfont(1, font, fontsize3)
      local measurestrname = gfx.measurestr(knob_name)  
      gfx.x, gfx.y = x+w/2-measurestrname/2, y+h-fontsize3
      extract_table(color3_t, true)
      gfx.a = 1
      gfx.drawstr(knob_name)
  end
      
-----------------------------------------------------------------------
  function GUI_DRAW()
    gfx.dest = -1
    -- background
      F_extract_table(color5_t,'rgb')
      gfx.a = 1
      gfx.rect(0,0,main_w,main_h)
      
    -- get items
      GUI_button(get_b_xywh_t, get_b_name, get_b_mouse_state,get_b_name_col) 
       
      -- gradient
      if is_1_time == nil then
         gfx.dest = 3
         F_extract_table(peak_display1_xywh_t, 'xywh')
         F_extract_table(color3_t, 'rgb')
         gfx.x,gfx.y, gfx.a = x,y, 1      
         gfx.setimgdim(3,w+x,h+y)
         gfx.gradrect(x,y,w,h, 1,1,1,0.4, 0,0,0,0.0001, 0,0,0,-0.01)
         is_1_time = 1
      end
      
      
             
    -- items display
      if #sel_items_t > 0  then 
        -- first display
        update_gui_disp1 = 
          GUI_item_display(gui_ref_item_data_t,peak_display1_xywh_t,color1_t,true,update_gui_disp1)
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
        --GUI_button(action_b_xywh_t, action_b_name, action_b_mouse_state,color3_t)
        
      -- param set
        -- match positions by rms    
          if gui_params_set == 1 then
            
          end
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
      knob_val_norm = limit(knob_val_norm, 0, 1) 
    end
    
    return last_mouse_obj, knob_val_norm0, knob_val_norm  
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
    
    --[[release behaviour
      if last_LMB_state and not MB_state then
        if last_mouse_obj == 'k1_windowsize' or 
          last_mouse_obj == 'k2_threshold' or 
          last_mouse_obj == 'k3_search_area' or 
          last_mouse_obj == 'k4_search_area2' or
          last_mouse_obj == 'k5_rise_percent' then
          ref_item_data_t = ENGINE1_get_item_data(1)
          item_data_t = ENGINE1_get_item_data(cur_item)
        end
      end -- release actions]]    
  
    if not last_LMB_state then last_mouse_obj = nil end
    
    -- get items button     
      if MOUSE_gate2(1, get_b_xywh_t) then -- gui state
        get_b_mouse_state = 2          
        elseif MOUSE_match_xy(get_b_xywh_t) then 
        get_b_mouse_state = 1 
        else get_b_mouse_state = 0 end
      if MOUSE_gate(1, get_b_xywh_t) then --action
        ENGINE1_get_items()
        ENGINE1_update_gui_data()
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
          gui_cur_item_data_t, cur_item_name = ENGINE1_get_item_data(sel_items_t[cur_item])
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
          gui_cur_item_data_t, cur_item_name = ENGINE1_get_item_data(sel_items_t[cur_item])
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
            item = reaper.BR_GetMediaItemByGUID(0, sel_items_t[i])
            track = reaper.GetMediaItem_Track(item)
            retval, trackname = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME','', false)
            take = reaper.GetActiveTake(item) 
            take_name = reaper.GetTakeName(take)
            menustring = menustring..trackname..' / '..take_name..'|' 
            if i == 1 then menustring = menustring .."|" end end  
            menu_ret = gfx.showmenu(menustring) 
            if menu_ret ~= 0 and menu_ret ~= 1 then cur_item = math.floor(menu_ret) end          
          gui_cur_item_data_t, cur_item_name = ENGINE1_get_item_data(sel_items_t[cur_item])
        end  
      -- select action button
        if MOUSE_gate2(1, action_b_xywh_t) then -- gui state
        action_b_mouse_state = 2          
        elseif MOUSE_match_xy(action_b_xywh_t) then 
        action_b_mouse_state = 1 
        else action_b_mouse_state = 0 end
      if MOUSE_gate(1, action_b_xywh_t) then --action
        action_b_name, gui_params_set = ENGINE2_action_list()        
      end         
      
            
    last_LMB_state = LMB_state    
    last_RMB_state = RMB_state
    last_MMB_state = MMB_state    
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
    ENGINE1_update_gui_data()
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
    
    
    
    return sm_data_t
  end

  ---------------------------------------------------------------------------------------------------------------         
  unction ENGINE2_test()
    data_t_temp1 = ENGINE1_get_item_data(1)
    data_t_temp1 = data_t_temp1[6]
      
    data_t_temp2 = ENGINE1_get_item_data(2)
    data_t_temp2 = data_t_temp2[6]
    --search table coincidence
    diff_t = {}
    for offset = 100, -100,-1 do
      diff_com = 0
      for i = 1, #data_t_temp1 do
        if i+offset < 0 or i+offset > #data_t_temp2 then
         t2_val = 0 else t2_val = data_t_temp2[i+offset] end
        if t2_val == nil then t2_val = 0 end
        diff = math.abs(data_t_temp1[i] - t2_val)
        diff_com = diff + diff_com
      end
      table.insert(diff_t, diff_com)
    end
    
    diff_t_min = math.huge
    for i = 1, #diff_t do
      diff_t_min0 = diff_t_min
      diff_t_it = diff_t[i]
      diff_t_min = math.min(diff_t_it, diff_t_min)
      
      if diff_t_min0 ~= diff_t_min then diff_t_min_id = i end
    end
    item = reaper.BR_GetMediaItemByGUID(0, sel_items_t[2])
    item_pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
    reaper.SetMediaItemInfo_Value(item,"D_POSITION", 
      item_pos + (diff_t_min_id - 100)*window_time)
      reaper.UpdateArrange()
  end
        
   
    
  --[[ generate stretch markers  
    sm_t = ENGINE2_get_stretch_markers(fft_val_t)
  
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
      
      -- filter by average
      for i = 1, 3 do
        
      end
    --[[
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
  tempo = 120
  
  data_t = {displayed_item_name, --1
            displayed_item_name2, --2
            item_pos, --3
            item_pos, --4
            read_pos0, --5
            fft_val_t, --6
            sm_t, --7
            tempo}  --8 ]]

         
         
         
         
         --[[x_offset = 5
         y_offset = 5
         
         knob_w = 55
         knob_h = 65
         knob_r = knob_w/2-2
         nav_button_w = 50
         displ_h = 57
         
         frame = 0.15
         frame_knob = 0.02
         frame_knob_outarc = 0.7
         fontsize2 = fontsize+1
         fontsize3 = fontsize -2
         
         
           -- middle window
             --detection params
         
             window_m2_xywh_t = {window1_xywh_t[1], window1_xywh_t[2]+window1_xywh_t[4]+offset,
               window0_xywh_t[3],window1_xywh_t[4]-20}
               
               --[[ window size knob
                 w2_knob1_xywh_t = {window_m2_xywh_t[1] + offset,
                                    window_m2_xywh_t[2] + offset,
                                    knob_w, knob_h}
               -- threshold knob
                 w2_knob2_xywh_t = {window_m2_xywh_t[1] + offset,
                                    window_m2_xywh_t[2] + offset,
                                    knob_w, knob_h}
               --[[ search area knob
                 knob_x_offset_m = 2
                 w2_knob3_xywh_t = {window_m2_xywh_t[1] +  offset*knob_x_offset_m + knob_w*(knob_x_offset_m-1),
                                    window_m2_xywh_t[2] + offset,
                                    knob_w, knob_h}
         
               -- percent knob
                 knob_x_offset_m = 2
                 w2_knob5_xywh_t = {window_m2_xywh_t[1] + offset*knob_x_offset_m + knob_w*(knob_x_offset_m-1),
                                    window_m2_xywh_t[2] + offset,
                                    knob_w, knob_h}  
                                               
               -- search area2 knob
                 knob_x_offset_m = 3 
                 w2_knob4_xywh_t = {window_m2_xywh_t[1] + offset*knob_x_offset_m + knob_w*(knob_x_offset_m-1),
                                    window_m2_xywh_t[2] + offset,
                                    knob_w, knob_h}
                                    
                                  
                                                                             
             --get2 button
             window_m1_xywh_t = {window0_xywh_t [1]+window0_xywh_t [3]+offset, window1_xywh_t[2]+window1_xywh_t[4]+offset, 
               nav_button_w, window_m2_xywh_t[4]}   ]]              
               
                
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
                
                mouse_res = 200 -- for knobs resolution]]
                
                
                
    
    --[[ one or two displays on top
    if #sel_items_t <2 then 
      window1_xywh_t = {x_offset-1, y_offset, main_w-x_offset*2, displ_h*2+offset}
      window0_xywh_t = {x_offset, y_offset, main_w-x_offset*2, displ_h*2 + offset}
      text1_xywh_t = {x_offset, y_offset+100, main_w-nav_button_w-x_offset*3, 20}
     else
      window1_xywh_t = {x_offset-1, y_offset, main_w-x_offset*3-nav_button_w, displ_h*2+offset}
      window0_xywh_t = {x_offset, y_offset, main_w-nav_button_w-x_offset*3, displ_h}
      text1_xywh_t = {x_offset, y_offset+40, main_w-nav_button_w-x_offset*3, 20}
    end 
    
    if show_get_button == true then get_button_name = '[ Store selected items ]' else get_button_name = 'Store selected items' end
    if show_get_button2 == true then get_button_name2 = '[ test ]' else get_button_name2 = 'test' end
    ]]
    
    
      
    
    --[[displayed_item_name
    -- 2 displayed_item_name2
    -- 3 item_pos
    -- 4 item_len
    -- 5 offset rel to ref item pos
    -- 6 com_val_t
    -- 7 sm table
    -- 8 tempo
    local X0,Y,W0,H0 = extract_table(xywh_t0)
    X=X0
    W = W0-1
    H = H0-20 -- displae gradient
    if is_ref then Y = Y +20 end  
    Y1 = Y
    if not is_ref then Y1 = Y + 0.2*H end
    H1 = (H0-20)*0.8
    
    if data_t ~= nil then
        
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
        
    end--if data~= nil
    
    -- frame -- 
      x,y,w,h = extract_table(xywh_t0)
      extract_table(color_t,true)
      gfx.a = frame
      --gfx.roundrect(x-1,y,w,h,0.1, true)]]
      
 
 
 
   
 --[[ top window            
   -- show item peaks
     if enable_display_graph == 1 then 
       GUI_item_display(ref_item_data_t,window0_xywh_t,true,color1_t,text1_xywh_t,true)
       if #sel_items_t > 1 then GUI_item_display(item_data_t,window2_xywh_t,true,color2_t,text2_xywh_t,false) end
      else
       if #sel_items_t > 0 then 
         x,y,w,h = extract_table(window1_xywh_t)
         gfx.setfont(1, font, fontsize)
         measurestrname = gfx.measurestr('Item RMS / FFT graphs are disabled')  
         gfx.x, gfx.y = x+(w-measurestrname)/2,y+offset
         extract_table(color3_t, true)
         gfx.a = 1
         gfx.drawstr('Item RMS / FFT graphs are disabled')
       end  
     end
   -- nav buttons                  
     if #sel_items_t > 1 then  
       GUI_button(nav_button3_xywh_t, '<', frame, color2_t, fontsize)
       GUI_button(nav_button4_xywh_t, '>', frame, color2_t, fontsize)
       GUI_button(nav_button2_xywh_t, math.floor(cur_item)..' / '..#sel_items_t, 0.1, color2_t,fontsize) end      
   -- get button
     if #sel_items_t == 0 then show_get_button=true end
     if show_get_button then 
       GUI_button(window1_xywh_t, get_button_name , 0.8, color3_t,fontsize2)  end     
        
 -- middle window
   -- get button
     if #sel_items_t > 0 then GUI_button(window_m1_xywh_t, get_button_name2, 0.8, color3_t,fontsize2) end
   -- detection settings 
     if #sel_items_t > 0 then 
       -- settings com frame -- 
       x,y,w,h = extract_table(window_m2_xywh_t)
       extract_table(color3_t, true)
       gfx.a = frame
       gfx.roundrect(x,y,w,h,0.1, true)
       -- settings gradrect
       gfx.gradrect(x,y,w,h-20, 1,1,1,0.0005, 0,0,0,0.00005, 0,0,0,0.00009) 
       -- name
       gfx.setfont(1, font, fontsize)
       measurestrname = gfx.measurestr('Stretch markers detection settings')  
       gfx.x, gfx.y = x+(w-measurestrname)/2,y+h-fontsize-2
       extract_table(color3_t, true)
       gfx.a = 1
       gfx.drawstr('Stretch markers detection settings')
       
       --knobs
       
       --[[k1_val = math.floor(window_time*1000)..' ms'          
         GUI_knob(w2_knob1_xywh_t, k1_val_norm, k1_val, "Window")                  
       k2_val = math.floor(threshold)..' dB'
         GUI_knob(w2_knob2_xywh_t, k2_val_norm, k2_val, "Threshold")
       --[[k3_val = math.floor(s_area*window_time*1000)..' ms'
         GUI_knob(w2_knob3_xywh_t, k3_val_norm, k3_val, "Area1")           
       k4_val = math.floor(s_area2*window_time*1000)..' ms'
         GUI_knob(w2_knob4_xywh_t, k4_val_norm, k4_val, "Area2")       
       k5_val = math.floor(rise_percent)..' %'
         GUI_knob(w2_knob5_xywh_t, k5_val_norm, k5_val, "Rise")                  
     end -- if sel items table size > 0  ]]
          
                   
 
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
 
 
 --[[ 
     --[[ knob1 window size
       k1_val_norm = conv_val2norm(window_time, window_time_min, window_time_max,false)
       last_mouse_obj, k1_val_norm0, k1_val_norm = 
         MOUSE_knob(w2_knob1_xywh_t, 'k1_windowsize',k1_val_norm0, k1_val_norm)
       window_time = conv_norm2val(k1_val_norm,window_time_min, window_time_max,false)
      
     -- knob2 threshold
       k2_val_norm = conv_val2norm(threshold,threshold_min,threshold_max, true)
       last_mouse_obj, k2_val_norm0, k2_val_norm = 
         MOUSE_knob(w2_knob2_xywh_t, 'k2_threshold', k2_val_norm0, k2_val_norm)
       threshold = conv_norm2val(k2_val_norm,threshold_min,threshold_max, true)
               
     --[[ knob3 search area
       k3_val_norm = conv_val2norm(s_area,s_area_min,s_area_max, false)
       last_mouse_obj, k3_val_norm0, k3_val_norm = 
         MOUSE_knob(w2_knob3_xywh_t, 'k3_search_area', k3_val_norm0, k3_val_norm)
       s_area = math.floor(conv_norm2val(k3_val_norm,s_area_min,s_area_max, false))
 
     -- knob4 search area2
       k4_val_norm = conv_val2norm(s_area2,s_area2_min,s_area2_max, false)
       last_mouse_obj, k4_val_norm0, k4_val_norm = 
         MOUSE_knob(w2_knob4_xywh_t, 'k4_search_area2', k4_val_norm0, k4_val_norm)
       s_area2 = math.floor(conv_norm2val(k4_val_norm,s_area2_min,s_area2_max, false))
 
     -- knob5 percent
       k5_val_norm = conv_val2norm(rise_percent,rise_percent_min,rise_percent_max, false)
       last_mouse_obj, k5_val_norm0, k5_val_norm = 
         MOUSE_knob(w2_knob5_xywh_t, 'k5_rise_percent', k5_val_norm0, k5_val_norm)
       rise_percent = math.floor(conv_norm2val(k5_val_norm,rise_percent_min,rise_percent_max, false))           
     
     -- apply
       if MOUSE_gate(1, window_m1_xywh_t) then   
         ENGINE2_test()
       end
       
   end -- end MID window        ]]
   
   
               
 ]===]
 
 
