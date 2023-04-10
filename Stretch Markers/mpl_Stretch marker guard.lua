-- @description Stretch marker guard
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # remove SWS dependency

--[[  full changelog
--    1.1  // 23.09.2016
--      + Acion: Remove all non-1x stretch markers from selected takes
--    1.0  // 13.09.2016
--     official release
--    0.23 // 04.09.2016
--      # global offset = 0.1s by default (enough?)
--      + alt+click = set 0 value
--      # rename (removed 'symmetric')
--      + independent LR transient zone
--      + 'get' and 'restore' buttons
--      + warning
--    0.1 // 03.09.2016
--      + init alpha
]]
  
  
  
  
  local vrs = 1.02
  local name = 'MPL Stretch marker guard'
  ------------------------------------------------------------------  
  function GetExtState(default, key)
    val = reaper.GetExtState( name, key )
    if val == '' or not tonumber(val )then 
      reaper.SetExtState( name, key, default, true )
      return default
     else 
      return tonumber(val)
    end
  end  
  ------------------------------------------------------------------   
  function SetExtState(val, key)
    if val and key then 
      reaper.SetExtState( name, key, val, true )
    end
  end    
  ------------------------------------------------------------------  
  function math_q(val, pow)
    if val then return  math.floor(val * 10^pow)/ 10^pow end
  end
  ------------------------------------------------------------------  
  function ENGINE_GetSM()
    SM_t = {}
    local cnt_items = reaper.CountSelectedMediaItems(0)
    for i = 1, cnt_items do
      local item = reaper.GetSelectedMediaItem( 0, i-1 )
      if not item then return end
      local take = reaper.GetActiveTake(item)
      local takerate =  reaper.GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )     
      local retval, take_guid = reaper.GetSetMediaItemTakeInfo_String( take, 'GUID', '', false )
      --local take_guid = reaper.BR_GetMediaItemTakeGUID( take )
      local item_len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
      if not reaper.TakeIsMIDI(take) then
        DGO = data_global_offset / takerate
        SM_t[take_guid] = {}
        for i = 1, reaper.GetTakeNumStretchMarkers( take ) do
          local _, sm_pos, sm_srcpos = reaper.GetTakeStretchMarker( take, i -1 )              
          if sm_pos >= 0 and math_q(sm_pos, 5) <= math_q(item_len, 5) then 
              SM_t[take_guid][#SM_t[take_guid]+1] = 
                {pos = sm_pos/takerate, 
                 srcpos = sm_srcpos/takerate, 
                 slope = reaper.GetTakeStretchMarkerSlope( take, i -1  )
              } 
          end
        end
      end
    end
  end
  ------------------------------------------------------------------  
  function ENGINE_RemoveSMExceptEdges(take,takerate)
    if not take then return end
    local item =  reaper.GetMediaItemTake_Item( take )
    local item_len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
    for i = reaper.GetTakeNumStretchMarkers( take ),1,-1 do
      local _, sm_pos = reaper.GetTakeStretchMarker( take, i -1 )  
      if sm_pos > 0 and math_q(sm_pos, 5) < math_q(item_len, 5) then 
        reaper.DeleteTakeStretchMarkers( take, i-1 )
       --else
        --exists_edges = true
      end
    end
    reaper.SetTakeStretchMarker( take, -1, 0)
    reaper.SetTakeStretchMarker( take, -1, item_len)
    ---if not exists_edges then
    --end
  end
  ------------------------------------------------------------------      
  function msg(s) if s then reaper.ShowConsoleMsg(s..'\n') end end
  -------------------------------------------------------------------- 
  function ENGINE_InsertSMFromRawT(raw_t,takerate)  
    if not raw_t and #raw_t < 3 then return end
    for i = 2, #raw_t - 1 do      
      local sm_pos = reaper.SetTakeStretchMarker( take, -1, raw_t[i].pos*takerate, raw_t[i].srcpos*takerate)
      reaper.SetTakeStretchMarkerSlope( take, sm_pos, raw_t[i].slope )             
    end  
  end
  --------------------------------------------------------------------    
  function ENGINE_FormSM_RAW(t, val_t, takerate, item_pos,timesel_st,timesel_end)
    
    local pair
    local global_offs1, global_offs2 = 0,0
    if not t then return end    
    if not val_t then return end      
    local SM_t_raw = {}
    local minSM_distance = (data_safety_distance) / takerate
    for sm_idx = 1, #t do      
      local offs1 = data_global_offset * val_t.L
      local offs2 = data_global_offset * val_t.R
      local srcpos =  t[sm_idx].srcpos
      local pos = t[sm_idx].pos  
      local slope = t[sm_idx].slope      
      if sm_idx == 1 then
        SM_t_raw[#SM_t_raw+1] = {pos = t[sm_idx].pos,srcpos = t[sm_idx].srcpos, slope = t[sm_idx].slope }
        last_src = srcpos
       elseif sm_idx < #t then
       
       
        if data_perform_TS == 1 then 
          if pos + item_pos > timesel_st and pos + item_pos < timesel_end then 
            goto perform 
           else 
            goto skip 
          end
        end
        
        
        ::perform::
        --------------------------------------------------------
        -- LEFT
        if srcpos - last_src > minSM_distance then
          -- check if offset out of min distance
          if srcpos - offs1 / takerate < last_src + minSM_distance then
            offs1 = srcpos - (last_src + minSM_distance)
          end
          -- insert sm
          SM_t_raw[#SM_t_raw+1] = {pos = pos - offs1, 
                                   srcpos = srcpos - offs1 / takerate, 
                                   slope = 0 }
          global_offs1 = math.max (offs1, global_offs1)
        end
        --------------------------------------------------------
        -- CENTER
        SM_t_raw[#SM_t_raw+1] = {pos = pos ,
                                 srcpos = srcpos,
                                 slope = 0 }         
        last_src = srcpos
        --------------------------------------------------------
        -- RIGHT
        local next_srcpos =  t[sm_idx+1].srcpos
        if next_srcpos - srcpos > minSM_distance then
          -- check if offset out of min distance
          if srcpos + offs2 / takerate > next_srcpos - minSM_distance then
            offs2 = next_srcpos - minSM_distance - srcpos
          end
          -- insert sm
          SM_t_raw[#SM_t_raw+1] = { pos = pos + offs2, 
                                    srcpos = srcpos + offs2 / takerate, 
                                    slope = slope }          
          last_src = srcpos + offs2 / takerate    
          global_offs2 = math.max (offs2, global_offs2)
         else
          SM_t_raw[#SM_t_raw].slope = slope
        end
        
        --------------------------------------------------------
       else -- last id
        SM_t_raw[#SM_t_raw+1] = {pos = pos, srcpos = srcpos, slope = 0 }
        last_src = srcpos  
      end
      
      ::skip::
      if data_perform_TS == 1 then
        SM_t_raw[#SM_t_raw+1] = {pos = pos, srcpos = srcpos, slope = 0 }
        last_src = srcpos        
      end
      
      -- neg SM protection
      for i = 2, #SM_t_raw - 1 do
        if SM_t_raw[i].srcpos < SM_t_raw[i-1].srcpos then
          local diff = SM_t_raw[i-1].srcpos - SM_t_raw[i].srcpos
          SM_t_raw[i].srcpos = SM_t_raw[i].srcpos + (diff + data_safety_distance)/takerate
          SM_t_raw[i].pos = SM_t_raw[i].pos + diff + data_safety_distance
        end
      end
    end
    return SM_t_raw, global_offs1, global_offs2
  end          
  --------------------------------------------------------------------   
  function ENGINE_ApplyTransientProtect(val_t)  
    if not SM_t then return end
    for key in pairs(SM_t) do
      take =  reaper.GetMediaItemTakeByGUID( 0, key )
      timesel_st, timesel_end = reaper.GetSet_LoopTimeRange2( 0, false, false, 0, 0, false )
      if take then
        local takerate =  reaper.GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )  
        ENGINE_RemoveSMExceptEdges(take, takerate)
        local item =  reaper.GetMediaItemTake_Item( take )
        local item_len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )    
        local item_pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )     
        raw_t, offs1_max, offs2_max = ENGINE_FormSM_RAW(SM_t[key], val_t, takerate, item_pos,timesel_st, timesel_end)
        ENGINE_InsertSMFromRawT(raw_t, takerate)
        reaper.UpdateItemInProject( item )
      end
    end
    return true
  end
-----------------------------------------------------------------------   
  function DEFINE_GUI_vars()
      local gui = {
                  aa = 1,
                  mode = 3,
                  fontname = 'Calibri',
                  fontsize = 18}
     
        if OS == "OSX32" or OS == "OSX64" then gui.fontsize = gui.fontsize - 7 end
        gui.fontsize_textb = gui.fontsize - 1
      
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
  --------------------------------------------------------------------
  function DEFINE_Objects()
    local offs = 10
    local num_b = 3
--    local
    
    local obj = {}
      obj.main_w = 420
      obj.main_h = 80
      
      -- main ----------------------------------
        obj.get_b = {name = 'Get',
                      x = offs,
                      y = offs,
                      w = 70,
                      h = (obj.main_h - offs*2)/2 - offs/4
                      }
        obj.res_b = {name = 'Reset',
                      x = offs,
                      y = offs + (obj.main_h - offs*2)/2 + offs/4,
                      w = 50,
                      h = (obj.main_h - offs*2)/2 - offs/4
                      }      
        obj.res_b2 = {name = '▼',
                      x = obj.res_b.x+ obj.res_b.w ,
                      y = offs + (obj.main_h - offs*2)/2 + offs/4,
                      w = 20,
                      h = (obj.main_h - offs*2)/2 - offs/4
                      }                                    
        obj.slider = {name = 'slider',
                      x = obj.get_b.x +obj.get_b.w+ offs,
                      y =offs,
                      w = 290,---gfx.w - offs * (num_b+1) - but_w*2,
                      h = obj.main_h - offs*2,
                      manualw = 30,
                      line_h = 3}
      
      nav_b_w = gfx.w - obj.slider.x - obj.slider.w - offs*2              
      -- settings
        text_h = 22
        text_w = obj.main_w - nav_b_w - offs*3
        obj.GO_b = {  name = 'Max offset: '..data_global_offset..'s',
                      x = offs,
                      y = obj.main_h + offs/2 + 1,
                      w = text_w,
                      h = text_h ,
                      val = data_global_offset ,
                      max_val = 0.5   
                    }
        obj.SD_b = {  name = 'Safety distance: '..data_safety_distance..'s',
                      x = offs,
                      y = obj.main_h + offs/2 + text_h + 2,
                      w = text_w,
                      h = text_h,
                      val =     data_safety_distance ,
                      max_val = 0.1  
                    }        
        obj.PTS_b = {  name = 'Perform only SM at time selection',
                      val = data_perform_TS,
                      x = offs,
                      y = obj.main_h + offs/2 + text_h*2 + 3,
                      w = text_w,
                      h = text_h,
                      is_checkbox = true     
                    }    
      --  about
        --[[obj.ab_SC_b = {  name = 'Follow MPL at SoundCloud',
                      x = offs,
                      y = obj.main_h*2 + offs/2 + 1,
                      w = text_w,
                      h = text_h   ,
                      col = 'white'  
                    }   ]]
        obj.ab_VK_b = {  name = 'Follow MPL at VK',
                      x = offs,
                      y = obj.main_h*2 + offs/2 + text_h + 2,
                      w = text_w,
                      h = text_h ,
                      col = 'white'     
                    }    
        --[[obj.ab_PP_b = {  name = 'Donate MPL if you like it ;)',
                      x = offs,
                      y = obj.main_h*2 + offs/2 + text_h*2 + 3,
                      w = text_w,
                      h = text_h  ,
                      col = 'green'    
                    }                                      
                    ]]
                                                             
      -- com ---------------------------------------          
        obj.ch_scr = {name = '▼',
                      x = obj.slider.x+obj.slider.w+ offs,
                      y = offs + (obj.main_h - offs*2)/2 + offs/4,
                      w = nav_b_w,
                      h = (obj.main_h - offs*2)/2 - offs/4
                      }  
        obj.ch_scr2 = {name = '▲',
                      x = obj.slider.x+obj.slider.w+ offs,
                      y = offs,
                      w = nav_b_w,
                      h = (obj.main_h - offs*2)/2 - offs/4
                      }                                       
    return obj
  end
-----------------------------------------------------------------------    
  function F_Get_SSV(s)
    local t = {}
    for i in s:gmatch("[%d%.]+") do 
      t[#t+1] = tonumber(i) / 255
    end
    gfx.r, gfx.g, gfx.b = t[1], t[2], t[3]
    return t[1], t[2], t[3]
  end
  ------------------------------------------------------------------   
  function GUI_slider(obj, obj_t, gui, val_t)
    gfx.mode = 0
    local val1, val2 =val_t.L^2 , val_t.R^2
    if val1 == nil then val1 = 0 end
    if val2 == nil then val2 = 0 end
    local alpha_mult = 1.8
    -- define xywh
      local x,y,w,h = obj_t.x, obj_t.y, obj_t.w, obj_t.h
    -- frame
      gfx.a = 0.05
      F_Get_SSV(gui.color.white, true)
      F_gfx_rect(x,y,w,h)     
    -- center line
      gfx.a = 1
      gfx.blit(5, 1, 0, --backgr
               0,0,w, obj.slider.line_h,
               x+w/2,y+h/2 - 1,w/2, obj.slider.line_h, 0,0   )   
      gfx.blit(5, 1, math.rad(180), --backgr
               0,0,w, obj.slider.line_h,
               x,y+h/2 - 1,w/2, obj.slider.line_h, 0,0   )                       
    --[[ blit grad   
      local handle_w = 30  
      local x_offs = x + (w - handle_w) * val1   
      gfx.a = 1
      man_x = x + w/2 - w/2 * val1 
      man_w = w/2 - man_x + x
      man_w = math.abs(man_w) + w/2 * val2
      gfx.blit(4, 1, 0, --backgr
          0,0,obj.slider.manualw, obj.slider.h,
          man_x,y, man_w, obj.slider.h, 0,0)]]  
    -- manual
      gfx.a = 3
      gfx.blit(4, 1, 0, --backgr
               0,0,obj.slider.manualw, obj.slider.h,
               x + w/2 - val1 * w/2,y, x + w/2 - (x + w/2 - val1 * w/2) + 1, obj.slider.h, 0,0)
      gfx.blit(4, 1, 0, --backgr
               0,0,obj.slider.manualw, obj.slider.h,
               x + w/2, y, val2*w/2, obj.slider.h, 0,0   )            
    -- grid
      local steps = 20
      local cust_h_dif = 4
      F_Get_SSV(gui.color.white, true)
      for i = x, x+w, w/steps  do
        cust_h = (i-x) * steps / w
        if cust_h > steps/2 then cust_h = steps - cust_h end
        gfx.a = cust_h / steps
        if (cust_h / steps) ~= 0.5 then -- ignore center
          if cust_h % 2 == 1 then  cust_h = cust_h - cust_h_dif end
            gfx.line(i, y + h/2 + cust_h,
                   i, y + h/2 - cust_h)
                   --gfx.drawstr(math.floor(cust_h)..' ')
        end
      end      
    -- draw sm
      F_Get_SSV(gui.color.blue, true)
      gfx.a = 0.6
      gfx.line(x+w/2, y+1,x+w/2, y+h-1)
      local pol_side = 5
      gfx.triangle(x+w/2 - pol_side,y + h/2,
                    x+w/2,y + h/2- pol_side,
                    x+w/2 + pol_side,y + h/2,
                    x+w/2,y + h/2 + pol_side)
                    
    --text
      gfx.setfont(1, gui.fontname, font)
      gfx.a = 1
      F_Get_SSV(gui.color.blue, true)
      local txt_offs = 5
      if not offs1_max then offs1_max = 0 end
      if not offs2_max then offs2_max = 0 end
      
    -- text val1
      local val1_txt = math.floor(offs1_max*1000)
      if val1_txt < 10 then
        val1_txt = math.floor(offs1_max*1000000)..'μs'
       else
        val1_txt = val1_txt..'ms'
      end
      local measurestrname = gfx.measurestr(val1_txt)
      local x0 = x + txt_offs
      local y0 = y
      gfx.x, gfx.y = x0,y0 
      gfx.drawstr(val1_txt)      
    -- text val2  
      local val2_txt = math.floor(offs2_max*1000)
      if val2_txt < 10 then
        val2_txt = math.floor(offs2_max*1000000)..'μs'
       else
        val2_txt = val2_txt..'ms'
      end      
      local measurestrname = gfx.measurestr(val2_txt)
      local x0 = x + w - measurestrname - txt_offs
      local y0 = y
      gfx.x, gfx.y = x0,y0 
      gfx.drawstr(val2_txt) 
      
    --[[ txt count    
      if SM_t and #SM_t > 0 then
        gfx.a = 1
        local x0 = 10 --x
        local y0 = 20 --y + h/2 - gfx.h
        gfx.x, gfx.y = x0,y0 
        gfx.drawstr(' stretch markers') 
      end]]
          
  end
  -----------------------------------------------------------------------    
  function F_gfx_rect(x,y,w,h)
    gfx.x, gfx.y = x,y
    gfx.line(x, y, x+w, y)
    gfx.line(x+w, y+1, x+w, y+h - 1)
    gfx.line(x+w, y+h,x, y+h)
    gfx.line(x, y+h-1,x, y+1)
  end
  -----------------------------------------------------------------------         
  function GUI_textbut(obj, gui, obj_t)
    if not obj_t then return end
    local x,y,w,h = obj_t.x, obj_t.y, obj_t.w, obj_t.h
    -- frame
      gfx.a = 0.05
      F_Get_SSV(gui.color.white, true)
      F_gfx_rect(x,y,w,h) 
    -- back
      gfx.a = 0.7 
      gfx.blit(3, 1, 0, --backgr
        0,0,obj.main_w,obj.main_h,
        x,y,w,h, 0,0)
    -- text
      local text = obj_t.name
      if obj_t.is_checkbox then
        if obj_t.val == 1 then text = '☑ '..text else text = '☐ '..text end
      end
      gfx.setfont(1, gui.fontname, gui.fontsize_textb)
      gfx.a = 1
      if  obj_t.max_val and obj_t.val >  obj_t.max_val  then 
        F_Get_SSV(gui.color.red, true)
        text = text..' (whooa that`s too much)'
       else
        F_Get_SSV(gui.color.blue, true)
      end
      if obj_t.col then F_Get_SSV(gui.color[ obj_t.col ] , true) end
      local measurestrname = gfx.measurestr(text)
      local x0 = x + (w - measurestrname)/2
      local y0 = y + (h - gfx.texth)/2 +1
      gfx.x, gfx.y = x0,y0 
      gfx.drawstr(text) 
      
  end  
  -----------------------------------------------------------------------         
  function GUI_button(obj, gui, obj_t, cust_alpha)
    local x,y,w,h = obj_t.x, obj_t.y, obj_t.w, obj_t.h
    -- frame
      gfx.a = 0.1
      F_Get_SSV(gui.color.white, true)
      F_gfx_rect(x,y,w,h)
      
    -- back
      if cust_alpha then gfx.a = cust_alpha else gfx.a = 0.5 end
        gfx.blit(3, 1, math.rad(180), --backgr
        0,0,obj.main_w,obj.main_h/2,
        x,y,w,h+1, 0,0)
        
    -- text
      gfx.setfont(1, gui.fontname, gui.fontsize)
      local measurestrname = gfx.measurestr(obj_t.name)
      local x0 = x + (w - measurestrname)/2 + 1
      local y0 = y + (h - gfx.texth)/2 
      
      gfx.a = 0.9
      F_Get_SSV(gui.color.black, true)
      gfx.x, gfx.y = x0+1,y0 +2
      gfx.drawstr(obj_t.name)
      gfx.a = 1
      F_Get_SSV(gui.color.green, true)
      gfx.x, gfx.y = x0,y0 
      gfx.drawstr(obj_t.name)
      
 
  end   
------------------------------------------------------------------  
  function GUI_draw(obj, gui)         local buf_dest
    gfx.mode = 1 -- additive mode
    local time_flow =1--sec
    local add_pix_per_loop = 10
    
    -- DRAW static buffers
    if update_gfx_onstart then  
      -- buf3 -- buttons back gradient      
      -- buf4 -- slider  
      -- buf5 -- cent line scale
      -- buf3 -- buttons back gradient    
        gfx.dest = 3
        gfx.setimgdim(3, -1, -1)  
        gfx.setimgdim(3, obj.main_w,obj.main_h)  
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
        gfx.gradrect(0,0,obj.main_w,obj.main_h, 
                        r,g,b,a, 
                        drdx, dgdx, dbdx, dadx, 
                        drdy, dgdy, dbdy, dady)     
      -- buf4 -- slider                   
        gfx.dest = 4
        gfx.setimgdim(4, -1, -1)  
        gfx.setimgdim(4, obj.slider.manualw, obj.slider.h)
        gfx.a = 1
        gfx.blit(3, 1, math.rad(180), --backgr
                  0,0,obj.main_w,obj.main_h,
                  -2,0,obj.slider.manualw/2+2, obj.slider.h, 0,0)
        gfx.blit(3, 1, math.rad(0), --backgr
                 0,0,obj.main_w,obj.main_h,
              obj.slider.manualw/2,0,obj.slider.manualw/2, obj.slider.h, 0,0)
      --buf5 -- cent line
        gfx.dest = 5
        gfx.setimgdim(5, -1, -1)  
        gfx.setimgdim(5, obj.slider.w, obj.slider.line_h)      
        local r,g,b = F_Get_SSV(gui.color.green, true)
        gfx.gradrect(0, 0, obj.slider.w, obj.slider.line_h, 
          r,g,b,0.9, 
          0.006,--drdx, 
          0,--dgdx, 
          0,--dbdx, 
          -0.001,--dadx, 
          0,--drdy, 
          0,--dgdy, 
          0,--dbdy, 
          -0.002)--dady )                    
      update_gfx_onstart = nil
    end
    
      
    -- Store Com Buffer
      if update_gfx then  
        if not alpha_change_dir then alpha_change_dir = 1 end
        alpha_change_dir = math.abs(alpha_change_dir - 1)  
        run_change0 = clock       
        if alpha_change_dir == 0 then buf_dest = 10 else buf_dest = 11 end -- if 0 #10 is next
        gfx.dest = buf_dest
        gfx.a = 1
        gfx.setimgdim(buf_dest, -1, -1)  
        gfx.setimgdim(buf_dest, obj.main_w,obj.main_h*3) 
          --===========================================
          -- pg1
          GUI_slider(obj, obj.slider, gui, data.str_val)
          GUI_button(obj, gui, obj.get_b)
          GUI_button(obj, gui, obj.res_b)
          GUI_button(obj, gui, obj.res_b2)
          -- pg2
          GUI_textbut(obj, gui, obj.GO_b, false)
          GUI_textbut(obj, gui, obj.SD_b)
          GUI_textbut(obj, gui, obj.PTS_b, true)  
          -- pg3
          GUI_textbut(obj, gui, obj.ab_SC_b)  
          GUI_textbut(obj, gui, obj.ab_VK_b)   
          GUI_textbut(obj, gui, obj.ab_PP_b)     
          --===========================================
          --[[ debug split       
          F_Get_SSV(gui.color.green, true)
          gfx.a = 1
          gfx.line(0,obj.main_h,obj.main_w, obj.main_h) 
          gfx.x, gfx.y = 5, obj.main_h +5
          gfx.drawstr('1')
          gfx.line(0,obj.main_h*2,obj.main_w, obj.main_h*2)
          gfx.x, gfx.y = 5, obj.main_h *2+5
          gfx.drawstr('2') ]]   
          --===========================================      
        update_gfx = false
      end
      
    --  Define smooth changes 
      if run_change0 then
        if clock - run_change0 < time_flow then 
          alpha_change = F_limit((clock - run_change0)/time_flow  + 0.2, 0,1)
        end
      end
      
    -- Define page offset
      if not H_offs then H_offs = 0  end
      if ch_screen then
        H_offs = H_offs + ch_screen_move * add_pix_per_loop
        if ch_screen_move > 0 and H_offs > obj.main_h * ch_screen_num then 
          ch_screen = nil 
          H_offs =  obj.main_h * ch_screen_num
         elseif ch_screen_move < 0 and H_offs < obj.main_h * ch_screen_num then
          ch_screen = nil 
          H_offs =  obj.main_h * ch_screen_num
        end
      end
      
    -- Draw Common buffer
      gfx.dest = -1
      gfx.x,gfx.y = 0,0
      F_Get_SSV(gui.color.back, true)
      gfx.a = 1
      gfx.rect(0,0,gfx.w,gfx.w, 1)
      gfx.mode = 1
      -- smooth com
        local buf1, buf2
        if alpha_change_dir == 0 then buf1 = 10 buf2 = 11 else buf1 = 11 buf2 = 10  end
        local a1 = alpha_change
        local a2 = math.abs(alpha_change - 1)
        gfx.a = a1
        gfx.blit(buf1, 1, 0,
            0,0,  obj.main_w,obj.main_h*3,
            0,-H_offs,  obj.main_w,obj.main_h*3, 0,0)
        gfx.a = a2
        gfx.blit(buf2, 1, 0, 
            0,0,  obj.main_w,obj.main_h*3,
            0,-H_offs,  obj.main_w,obj.main_h*3, 0,0)           
    
    -- navigation
      
      GUI_button(obj, gui, obj.ch_scr, 0.1)
      GUI_button(obj, gui, obj.ch_scr2, 0.1)
      
    gfx.update()
  end
 ----------------------------------------------------------------------- 
  function F_limit(val,min,max)
      if val == nil or min == nil or max == nil then return end
      local val_out = val
      if val < min then val_out = min end
      if val > max then val_out = max end
      return val_out
    end 
----------------------------------------------------------------------- 
  function MOUSE_match(b, offs)
    if not b then return end
    local mouse_y_match = b.y
    local mouse_h_match = b.y+b.h
    if offs then 
      mouse_y_match = mouse_y_match - offs 
      mouse_h_match = mouse_y_match+b.h
    end
    if mouse.mx > b.x and mouse.mx < b.x+b.w and mouse.my > mouse_y_match and mouse.my < mouse_h_match then return true end 
  end 
-----------------------------------------------------------------------  
  function MOUSE_Click(mouse, xywh_table)
    if MOUSE_match(xywh_table) and mouse.LMB_state and not mouse.last_LMB_state then return true end
  end
  -----------------------------------------------------------------------     
  function MOUSE_button (xywh, offs)
    if MOUSE_match(xywh, offs) and mouse.LMB_state and not mouse.last_LMB_state then return true end
  end  
  -----------------------------------------------------------------------           
  function MOUSE_slider (obj)
    local val
    ret_pow = 1.5
    if MOUSE_match(obj) and (mouse.LMB_state or mouse.RMB_state) then 
      if mouse.mx < obj.x + obj.w/2 then
        if mouse.Alt_state then return true , 1, 0 
         else mouse.last_obj = obj.name end
       else
        if mouse.Alt_state then return true , 2, 0 
         else mouse.last_obj = obj.name..'2' end
      end
    end
    
    if not mouse.Alt_state then 
      if (mouse.last_obj == obj.name or mouse.last_obj == obj.name..'2') and mouse.RMB_state then     
        val = math.abs(F_limit((mouse.mx - obj.x)/obj.w, 0,1) * 2 - 1 )^ret_pow
        return true , 3, math_q(val, 5)
      end
      
      if mouse.last_obj == obj.name then 
        val = math.abs(F_limit((mouse.mx - obj.x)/obj.w, 0,1) * 2 - 1 )^ret_pow
        return true , 1, math_q(val, 5)
       elseif mouse.last_obj == obj.name..'2' then
        val = ((F_limit((mouse.mx - obj.x)/obj.w, 0,1) - 0.5) * 2)^ret_pow
        return true , 2, math_q(val, 5)
      end
    end
    
  end
  -----------------------------------------------------------------------   
  function ENGINE_remove_non1()
    reaper.Undo_BeginBlock() 
    for i = 1, reaper.CountSelectedMediaItems(0) do
      local item = reaper.GetSelectedMediaItem(0,i-1) 
      if not item then return end
      local take = reaper.GetActiveTake(item)
      if not take or reaper.TakeIsMIDI(take) then return end
      local t = {}
      for i = 2, reaper.GetTakeNumStretchMarkers( take ) do
        local _, pos, srcpos = reaper.GetTakeStretchMarker( take, i-1 )
        local _, pos2, srcpos2 = reaper.GetTakeStretchMarker( take, i-2 )      
        local val = math.floor(100*(0.005+(srcpos2 - srcpos ) / (pos2-pos)))/100
        t[#t+1] = val
      end
      
      for i =reaper.GetTakeNumStretchMarkers( take )-1, 1, -1 do
        if (t[i-1] == 1.0 and t[i] == 1.0 and t[i+1] ~= 1.0) then 
          reaper.DeleteTakeStretchMarkers( take, i ) 
         elseif  (t[i-1] ~= 1.0 and t[i] == 1.0 and t[i+1] == 1.0) then 
          reaper.DeleteTakeStretchMarkers( take, i-1 ) 
        end
      end
    end
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Remove all non-1x stretch markers from selected items", 0)
  end
  
  -----------------------------------------------------------------------         
  function MOUSE_get(obj)
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
    if mouse.last_wheel then mouse.wheel_trig = (mouse.wheel - mouse.last_wheel) end
    

    if MOUSE_button (obj.ch_scr) then 
      ch_screen = true
      ch_screen_num = F_limit(ch_screen_num + 1, 0, 2)
      ch_screen_move = 1
    end    

    if MOUSE_button (obj.ch_scr2) then 
      ch_screen = true
      ch_screen_num = F_limit(ch_screen_num - 1, 0, 2)
      ch_screen_move = -1
    end     
    
    -- MAIN W
    if ch_screen_num == 0 then
      -- GET
      if MOUSE_button (obj.get_b) then 
        ENGINE_GetSM() 
        data = {str_val = {L = 0, R = 0}}
        update_gfx = true
      end
      --RES
      if MOUSE_button (obj.res_b) then 
        app = ENGINE_ApplyTransientProtect({L = 0, R = 0})
        update_gfx = true
      end
      --RES2
      if MOUSE_button (obj.res_b2) then
        gfx.x, gfx.y =  mouse.mx, mouse.my
        local ret = gfx.showmenu('mpl_Remove all non-1x stretch markers from selected takes')
        if ret == 1 then ENGINE_remove_non1() end
      end
      -- SLIDE
      local ret, typeval, val = MOUSE_slider (obj.slider)
      if val and val < 0.01 then val = 0 end        
      local key
      if ret then 
        if typeval == 3 then -- sym
          data.str_val = {L = val,R = val} -- for GUI slider
         elseif typeval == 1 then key = 'L'
         elseif typeval == 2 then key = 'R'
        end
        if key then data.str_val[key] = val end  -- for GUI slider
        app = ENGINE_ApplyTransientProtect(data.str_val)
        update_gfx = true
      end
    end
    
    if ch_screen_num == 1 then
      -- GlobOffset
      if MOUSE_button(obj.GO_b, gfx.h * ch_screen_num) then        
        local retval, dgo = reaper.GetUserInputs( name, 1, 'Maximum offset', data_global_offset )
        local dgo = dgo:gsub('%,','.')
        if retval and tonumber(dgo) then
          data_global_offset = tonumber(dgo)
          SetExtState(data_global_offset, 'glof')  
          update_gfx = true
        end
      end
      -- SafeDist
      if MOUSE_button(obj.SD_b, gfx.h * ch_screen_num) then        
        local retval, sdist  = reaper.GetUserInputs( name, 1, 'Safety distance', data_safety_distance )
        local sdist = sdist:gsub('%,','.')
        if retval and tonumber(sdist) then
          data_safety_distance = tonumber(sdist)
          SetExtState(data_safety_distance, 'sadist')  
          update_gfx = true
        end
      end   
      -- perf at TS
      if MOUSE_button(obj.PTS_b, gfx.h * ch_screen_num) then  
        data_perform_TS = math.abs(data_perform_TS - 1)
        SetExtState(data_perform_TS, 'PTS')
        update_gfx = true 
      end          
    end
    
    if ch_screen_num == 2 then
      if MOUSE_button(obj.ab_SC_b, gfx.h * ch_screen_num) then
        F_open_URL('http://soundcloud.com/mp57')  
      end
      if MOUSE_button(obj.ab_VK_b, gfx.h * ch_screen_num) then
        F_open_URL('http://vk.com/mpl57')  
      end
      if MOUSE_button(obj.ab_PP_b, gfx.h * ch_screen_num) then
        F_open_URL('http://www.paypal.me/donate2mpl')  
      end
      
    end
    
    -- reset mouse context/doundo
      if not mouse.last_LMB_state and not mouse.last_RMB_state then app = false mouse.last_obj = 0 end
    
    -- proceed undo state
      if not app and last_app then reaper.Undo_OnStateChange(name )end
      last_app = app
      
    -- mouse release
      mouse.last_LMB_state = mouse.LMB_state  
      mouse.last_RMB_state = mouse.RMB_state
      mouse.last_MMB_state = mouse.MMB_state 
      mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
      mouse.last_Ctrl_state = mouse.Ctrl_state
      mouse.last_Alt_state = mouse.Alt_state
      mouse.last_wheel = mouse.wheel 
  end   
  ------------------------------------------------------------------  
  function F_open_URL(url)  
     if OS=="OSX32" or OS=="OSX64" then
       os.execute("open ".. url)
      else
       os.execute("start ".. url)
     end
   end   
  ------------------------------------------------------------------    
  function Run()    
    clock = os.clock()
    local obj = DEFINE_Objects()
    local gui = DEFINE_GUI_vars()
    GUI_draw(obj, gui)
    MOUSE_get(obj)
    local char = gfx.getchar() 
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end
    if char == 27 then gfx.quit() end     
    if char ~= -1 then reaper.defer(Run) else gfx.quit() end    
  end  
  ------------------------------------------------------------------   
  function Lokasenna_Window_At_Center (w, h)
    -- thanks to Lokasenna 
    -- http://forum.cockos.com/showpost.php?p=1689028&postcount=15    
    local l, t, r, b = 0, 0, w, h    
    local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)    
    local x, y = (screen_w - w) / 2, (screen_h - h) / 2    
    gfx.init(name..' // '..vrs, w, h, 0, x, y)  
  end
  
  data_global_offset = GetExtState(0.2, 'glof')
  data_safety_distance = GetExtState(0.005,'sadist') --second
  data_perform_TS = GetExtState(0,'PTS')
  
  ch_screen = true
  ch_screen_num =0 -- def scr
  ch_screen_move = 1
  
  OS = reaper.GetOS()
  mouse = {}
  data = {str_val = {L = 0, R = 0}}
  update_gfx = true
  update_gfx_onstart = true
  local obj = DEFINE_Objects()
  Lokasenna_Window_At_Center (obj.main_w, obj.main_h)
  obj = nil   
  
  
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    Run()
    Undo_EndBlock2( 0, 'Toggle reverse pan flag and invert color of track under mouse cursor', 0xFFFFFFFF )
  end end    