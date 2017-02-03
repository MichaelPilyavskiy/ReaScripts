-- @version 1.16
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description SendFader
-- @changelog
--    # not sure it is SendFader bug but hope fix adding/renaming ReaEQ instance for send created before SendFader


  -------------------------------------------------------------------- 
  vrs = '1.16'
  name = 'mpl SendFader'
  --------------------------------------------------------------------           
--[[
  changelog:
    1.16 03.02.2017
      # not sure it is SendFader bug but hope fix adding/renaming ReaEQ instance for send created before SendFader
    1.15 01.02.2017
      + Support for writing envelopes
    1.14 31.01.2017
      + MouseWheel on fader change volume, perform when link also
      + MouseWheel on pan change pan, perform when link also
      + Support for store/load configuration to external file (settings doesn`t resetted after update)
      + Save docked state
    1.12 30.01.2017 
      # fix scaling for external input  
      # fix error on changing track while external control      
    1.11 29.01.2017  
      + Save window width and height on change      
      + doubleclick on pan and vol reset value
      + doubleclick reset vol/pan reflects linking         
      + rightclick on pan and vol set value   
      + rightclick set vol/pan reflects linking
      + support disable track selection following, edit default config
      + support for setting ID before init, use reaper.SetExtState( 'mpl SendFader', 'currentID', ID_val, false )
      + support for setting source TrackGUID before init, use reaper.SetExtState( 'mpl SendFader', 'srcTrack_GUID', ID_val, false )
      + support track colors
      # fix empty send data errors
      # redraw window after xywh change
      # different GUI tweaks (indentation and resize)
      # allow change track/send_ID after external state get
      # rename 'Remove' to 'Delete'
      # fix wrong id from FX context menu
      # fix hardware sends in regular sends list
      # fixed small potential gfx/data issues
    1.0 29.01.2017
      + official release  
    1.0alpha20 29.01.2017
      + Mixer: up to 6 visible peaks
      + Mixer: show fader values
      + Mixer: mark green current fader
      + Mixer: hidden by default, open by mouse or editing default config
      + wide fader with fill, small_man == 1 use small manual
      + Names: subtract 'aux' and 'send' from track name
      + scroll on send track name or mixer change current track fader
      + show scroll bar in track send name
      + reset GUI when change project/tab and when not track selected
      + version and name moved to gfx
    1.0alpha18 28.01.2017
      # hopefully fixed VCA and dB convertion related bugs
      + Save window position
      + Link: VCA-style fader support
      + Link: VCA-style pan support
      + Link: phase support
      + Link: mono support
      + Link: send mode support
      + Link: PreEQ/PostEQ support
    1.0alpha14 27.01.2017
      + FX: float first FX on send track, skip 'PreEQ', skip 'PostEQ'
      + FX: right click open FX list at current send
      + Pre/Post EQ sliders
      + Pre/Post EQ sliders: add ReaEQ to first/end slot of chain on first touch
    1.0alpha10 26.01.2017
      + Send mode
      + Action: add send from tracks match 'aux', 'send' in their names
      + Action: add send from list
      + Prevent accidentally feedback routing
      + Mute
      + Phase
      + Mono
      # GUI tweaks
    1.0alpha5 24.01.2017
      + track/send peak levels
      + pan
      + fader block
    1.0alpha1 24.01.2017
      + basic GUI
]]

  function msg(s) reaper.ShowConsoleMsg(s) reaper.ShowConsoleMsg('\n') end
  --------------------------------------------------------------------    
  function F_cond_button(xywh1, xywh2)                        
    if  xywh1.y + xywh1.h >  xywh2.y + xywh2.h then xywh1  ={}    end  
    return xywh1
  end 
  --------------------------------------------------------------------  
  function DEFINE_Objects()  -- static variables
    if gfx.w < 100 then gfx.w = 100 end
    if gfx.h < 100 then gfx.h = 100 end
    obj = {
                    main_w = gfx.w,
                    main_h = gfx.h,
                    offs = 5,
                    gfx_fontname = 'Lucida Sans Unicode',
                    gfx_mode = 0,
                    gui_color = {['back'] = '20 20 20',
                                  ['back2'] = '51 63 56',
                                  ['black'] = '0 0 0',
                                  ['green'] = '130 255 120',
                                  ['blue2'] = '100 150 255',
                                  ['blue'] = '127 204 255',
                                  ['white'] = '255 255 255',
                                  ['red'] = '255 130 70',
                                  ['green_dark'] = '102 153 102',
                                  ['yellow'] = '200 200 0',
                                  ['pink'] = '200 150 200',
                                } 
                  }
    
    obj.b ={}
    obj.peak_w = 5
    obj.peak_dist = 1
    local but_h = 20
    obj.knob_side = 50 
    obj.glass_side = 300 -- glass w/h buffer   
    local pan_area_h = 70  
    local fader_area_x_shift = 10   
    local params_area_h = 70  
    local fad_b_w = 50  
    local fad_b_h = 15 
    local x_fader = gfx.w/2+fader_area_x_shift
    local shift_b = 20
    obj.global_y_shift = 10
    obj.min_w_peak = 130
    obj.min_pan_h = 260
    obj.min_h_buttons = 180       
    obj.b.tr_name =     { x= obj.offs,
                          y = obj.global_y_shift+obj.offs,
                          w = gfx.w - obj.offs*2,
                          h = but_h
                        }
    obj.b.tr_send_name = {x= obj.offs,
                          y = obj.global_y_shift+obj.offs*2+but_h,
                          w = gfx.w - obj.offs*2,
                          h = but_h
                          }    
    local y_offset_area = obj.b.tr_send_name.y + 
                          obj.b.tr_send_name.h + 
                          obj.offs
    obj.b.next_page =     { x = gfx.w -obj.offs -  shift_b,
                          y = y_offset_area,
                          w = shift_b,
                          h = pan_area_h,
                          name = '>'
                          }
    obj.b.pan_area =      {x= obj.offs,
                          y = y_offset_area,-- + obj.offs,
                          w = gfx.w - obj.offs*3-shift_b,-- - obj.offs*2,
                          h = pan_area_h
                          }  
    if gfx.h < obj.min_pan_h then  
      obj.b.pan_area.h = -obj.offs 
      params_area_h = 0
    end
    obj.b.pre_eq_area =   {x = obj.b.pan_area.x+obj.offs,
                           y = obj.b.pan_area.y + obj.offs,
                           w= obj.b.pan_area.w - obj.offs*2,
                           h = (obj.b.pan_area.h - obj.offs*3) /2,
                           name = 'PreEQ',
                           mouse_id = 'pre_eq_area'
                          }
    obj.b.post_eq_area =   {x = obj.b.pan_area.x+obj.offs,
                           y =obj.b.pan_area.y + obj.offs/2 + obj.b.pan_area.h/2,
                           w= obj.b.pan_area.w - obj.offs*2,
                           h = math.ceil((obj.b.pan_area.h - obj.offs*3) /2),
                           name = 'PostEQ',
                           mouse_id = 'post_eq_area'
                          }                          
    obj.b.params_area =   {x= obj.offs,-- + obj.offs,
                          y = y_offset_area + gfx.h - y_offset_area - obj.offs-params_area_h,---obj.offs,
                          w = gfx.w - obj.offs*2,-- - obj.offs*2,
                          h = params_area_h
                          }    
             
    obj.b.fader_area  =  {x= obj.offs,-- + obj.offs,
                          y = y_offset_area + obj.b.pan_area.h + obj.offs,
                          w = gfx.w - obj.offs*2,-- - obj.offs*2,
                          h = obj.b.params_area.y - obj.b.pan_area.y - obj.b.pan_area.h - obj.offs*2
                          }
    if data.show_mixer == 0 then  obj.b.fader_area.h = gfx.h - obj.b.pan_area.y - obj.b.pan_area.h - obj.offs*2  end  
    
    local fader_w = obj.b.fader_area.w  - obj.peak_w*2 - obj.peak_dist - x_fader-obj.offs
    obj.b.pan_knob  =    {x = obj.b.pan_area.x + (obj.b.pan_area.w-obj.knob_side)/2,--+ fader_area_x_shift + fader_w/2,
                          y = obj.b.pan_area.y + obj.offs,
                          w = obj.knob_side,
                          h = obj.knob_side,
                          mouse_id = 'pan_knob'
                          }                                 
 
    --[[local peakL_ind_x = obj.peak_w + 
                        0.5*obj.peak_dist + 
                        0.5*obj.b.fader_area.x +
                        0.5*obj.offs  + 
                        obj.b.fader.x/2
                        -fad_b_w/2
                        -1]]
    local peakL_ind_x = 2*obj.peak_w + 
                        obj.peak_dist + 
                        3*obj.offs 
      obj.b.fader  =  {x=  peakL_ind_x + fad_b_w + obj.offs ,
                          y = obj.b.fader_area.y + obj.offs*3,
                          w = gfx.w-2*peakL_ind_x-obj.offs*2 - fad_b_w,
                          h = obj.b.fader_area.h - obj.offs*6,
                          mouse_id = 'fader'
                          }                              
    if gfx.w  < obj.min_w_peak then       
      peakL_ind_x = obj.offs*2
      obj.b.fader.w = gfx.w - obj.offs*6 - fad_b_w
      obj.b.fader.x = peakL_ind_x+obj.offs+fad_b_w
      
    end        
    if gfx.h < obj.min_h_buttons  then                   
      obj.b.fader = {x = peakL_ind_x,
                    y = obj.b.fader_area.y+obj.offs,
                     w = gfx.w - peakL_ind_x*2,
                     h = obj.b.fader_area.h -obj.offs*2 }
                      
    end
    
    if gfx.h > obj.min_h_buttons then  
      obj.b.fader.x =  fad_b_w + obj.offs*2 +peakL_ind_x          
      obj.b.mute =         {x = peakL_ind_x,
                            y = obj.b.fader.y,
                            w =  fad_b_w,
                            h = fad_b_h,
                            name = 'M' }
      obj.b.mute = F_cond_button(obj.b.mute, obj.b.fader_area)                            
      obj.b.phase =         {x = peakL_ind_x,
                            y = obj.b.fader.y + obj.offs+fad_b_h,
                            w =  fad_b_w,
                            h = fad_b_h,
                            name = 'Ø' }  
      obj.b.phase = F_cond_button(obj.b.phase, obj.b.fader_area)                            
      obj.b.mono =         {x = peakL_ind_x,
                            y = obj.b.fader.y + obj.offs*2+fad_b_h*2,
                            w =  fad_b_w,
                            h = fad_b_h,
                            name = 'stereo' }
      obj.b.mono = F_cond_button(obj.b.mono, obj.b.fader_area)                            
      obj.b.send_mode =     {x = peakL_ind_x,
                            y = obj.b.fader.y + obj.offs*3+fad_b_h*3,
                            w =  fad_b_w,
                            h = fad_b_h} 
      obj.b.send_mode = F_cond_button(obj.b.send_mode, obj.b.fader_area)                            
      local sep = obj.offs*2
      obj.b.fx =            {x = peakL_ind_x,
                            y = obj.b.fader.y + obj.offs*4+fad_b_h*4+sep,
                            w =  fad_b_w,
                            h = fad_b_h,
                            name = 'FX'}  
      obj.b.fx = F_cond_button(obj.b.fx, obj.b.fader_area)                               
      obj.b.link =            {x = peakL_ind_x,
                            y = obj.b.fader.y + obj.offs*5+fad_b_h*5+sep,
                            w =  fad_b_w,
                            h = fad_b_h,
                            name = 'Link'}
      obj.b.link = F_cond_button(obj.b.link, obj.b.fader_area)  
      obj.b.mixer =            {x = peakL_ind_x,
                            y = obj.b.fader.y + obj.offs*6+fad_b_h*6+sep,
                            w =  fad_b_w,
                            h = fad_b_h,
                            name = 'Mixer'}  
      obj.b.mixer = F_cond_button(obj.b.mixer, obj.b.fader_area)   
      obj.b.remote =            {x = peakL_ind_x,
                            y = obj.b.fader.y + obj.offs*7+fad_b_h*7+sep,
                            w =  fad_b_w,
                            h = fad_b_h,
                            name = 'Remote'}
      obj.b.remote = F_cond_button(obj.b.remote, obj.b.fader_area)                                                       
      obj.b.remove =            {x = peakL_ind_x,
                            y = obj.b.fader.y + obj.offs*8+fad_b_h*8+sep*2,
                            w =  fad_b_w,
                            h = fad_b_h,
                            name = 'Delete'} 
      obj.b.remove = F_cond_button(obj.b.remove, obj.b.fader_area) 
    end
                                     
    -- fix OSX font          
      local gfx_fontsize = 16                
      if OS == "OSX32" or OS == "OSX64" then gfx_fontsize = gfx_fontsize - 5 end
      obj.gfx_fontsize = gfx_fontsize 
      obj.gfx_fontsize_2 = gfx_fontsize - 2
      obj.gfx_fontsize_3 = gfx_fontsize - 1
      obj.gfx_fontsize_textb = gfx_fontsize - 1
    return obj
  end 
  --------------------------------------------------------------------   
  function F_ssv_fromNative(col)
    r1, g1, b1 = reaper.ColorFromNative( col ) 
    local str
    if OS == "OSX32" or OS == "OSX64" then 
      str = b1..' '..g1..' '..r1
     else
      str = r1..' '..g1..' '..b1
    end
    return str
  end
  --------------------------------------------------------------------    
  function GUI_draw()
    gfx.mode = 1 -- additive mode
    
    --[[
    3 gradient glass
    4 peak meter
    10 common static buf
    11 common buf for peaks/reduced gfx updates
    12 text for GUI_mixer
    ]]
    -- update buf on start
      if update_gfx_onstart then  
          -- back
          gfx.dest = 3
          gfx.setimgdim(3, -1, -1)  
          gfx.setimgdim(3, obj.glass_side, obj.glass_side)  
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
          gfx.gradrect(0,0,obj.glass_side, obj.glass_side, 
                          r,g,b,a, 
                          drdx, dgdx, dbdx, dadx, 
                          drdy, dgdy, dbdy, dady)  
          -- peak level
          gfx.dest = 4
          gfx.setimgdim(4, -1, -1)  
          gfx.setimgdim(4, gfx.w, gfx.w)  
          gfx.a = 1
          gfx.x, gfx.y = 0,0
          local alp = 0.5
          local dgdy = 0.008
          local drdy = -0.02      
          gfx.gradrect(0,0,gfx.w, gfx.w, 
                      1,--r,
                      0.1,--g,
                      0.1,--b,
                      alp,--a, 
                      0,--drdx, 
                      0,--dgdx, 
                      0,--dbdx, 
                      0,--dadx, 
                      drdy,--drdy, 
                      dgdy,--dgdy, 
                      0,--dbdy, 
                      0)--dady)  
      end
    
    -- update static buffers
      if update_gfx then
        gfx.dest = 10
        gfx.setimgdim(10, -1, -1)  
        gfx.setimgdim(10, gfx.w, gfx.h)  
        gfx.a = 1
        F_Get_SSV(obj.gui_color.white)
        gfx.a = 0.6
        gfx.rect(0,0,gfx.w, gfx.h, 1)
        
        -- draw version/name
          gfx.setfont(1, obj.gfx_fontname, obj.gfx_fontsize_2)
          local txt = name..' '..vrs
          local text_w = gfx.measurestr(txt)
          local text_h = gfx.texth
          gfx.x = gfx.w -text_w-2
          gfx.y = 0--gfx.h - text_h
          gfx.a = 0.3
          F_Get_SSV(obj.gui_color.white)
          gfx.drawstr(txt)
        
        F_frame(obj.b.tr_name, nil, 0.4, true, data.track_col)         
        GUI_button(obj.b.tr_name, data.cur_tr_src_name,nil,0.8 )
        
        if data.send_t and #data.send_t == 0 then GUI_button(obj.b.tr_send_name, data.cur_tr_dest_name ,nil,0.8 )  end
 
        if data.send_t and #data.send_t >= 1 and data.cur_send_id and data.send_t[data.cur_send_id] then 
          
          -- track send name + col
            local cur_id_w = obj.b.tr_send_name.w / #data.send_t
            F_frame({x = obj.b.tr_send_name.x + cur_id_w*(data.cur_send_id-1) ,
                    y = obj.b.tr_send_name.y,
                    w = cur_id_w+1,
                    h = obj.b.tr_send_name.h,  
                    }, nil, 0.4, true, data.send_t[data.cur_send_id].col) 
            GUI_button(obj.b.tr_send_name, data.cur_tr_dest_name ,nil,0.8 )
            
                   
          if obj.b.pan_area.h>0 then 
            GUI_pan() 
            -- next page
              GUI_button(obj.b.next_page, nil, nil, 0.5)
              gfx.a = 0.1
              F_frame(obj.b.next_page, nil, 0.2)
              F_gfx_rect(F_UnzipTable(obj.b.next_page))
          end
          GUI_fader()
          
          -- frame mixer
            if data.show_mixer == 1 and gfx.h > obj.min_pan_h then 
              F_Get_SSV(obj.gui_color.green)
              gfx.a = 0.1
              F_gfx_rect(x,y,w,h)
              F_frame(obj.b.params_area, nil, 0.2)
            end
            
          if data.send_t and data.cur_send_id and data.send_t[data.cur_send_id] then
            -- mute
              local m_col, m_alp = nil,0.3
              if data.send_t[data.cur_send_id].mute == 1 then m_col = 'red' m_alp = 0.9 end
              GUI_button(obj.b.mute, nil, m_col, m_alp)
            
            -- polarity
              local p_col, p_alp = nil,0.3
              if data.send_t[data.cur_send_id].phase == 1 then p_alp = 0.9 p_col = 'blue'end          
              GUI_button(obj.b.phase, nil, p_col, p_alp)
            
            -- mono
              local mono_col, mono_alp = nil, 0.3
              if data.send_t[data.cur_send_id].mono == 1 then mono_alp = 0.9 end   
              if obj.b.mono and obj.b.mono.name then 
                if data.send_t[data.cur_send_id].mono == 0 then 
                  obj.b.mono.name = 'stereo'--'‹›' 
                 else 
                  obj.b.mono.name = 'mono'--'›' 
                  mono_col = 'blue2'
                end
              end       
              GUI_button(obj.b.mono, nil, mono_col, mono_alp)  
            
            -- send mode\
              if obj.b.send_mode then
                if data.send_t[data.cur_send_id].send_mode == 0 then
                  obj.b.send_mode.name = 'PostPan'
                 elseif data.send_t[data.cur_send_id].send_mode == 1 then
                  obj.b.send_mode.name = 'PreFX'
                 elseif data.send_t[data.cur_send_id].send_mode == 2 or data.send_t[data.cur_send_id].send_mode == 3 then
                  obj.b.send_mode.name = 'PostFX'
                end 
                GUI_button(obj.b.send_mode) 
              end
            
            -- FX
              GUI_button(obj.b.fx)
              
            -- Link
              local link_alpha
              if data.link == 0 then 
                link_alpha = 0.3 
                link_col = 'white'
               else 
                link_alpha = 0.8 
                link_col = 'green'
              end
              GUI_button(obj.b.link , nil, link_col,link_alpha)   
            -- remote
              local remote_alpha
              if data.remote == 0 then 
                remote_alpha = 0.3 
                remote_col = 'white'
               else 
                remote_alpha = 0.8 
                remote_col = 'green'
              end
              GUI_button(obj.b.remote , nil, remote_col,remote_alpha)               
            -- mixer
              GUI_button(obj.b.mixer, nil, nil,0.8)
            -- remove
              GUI_button(obj.b.remove , nil, 'red',0.8)    
          end 
        end 
          
      end
      
      if update_gfx2 then
        gfx.a = 1
        gfx.dest = 11
        gfx.set(1,1,1,1) -- don`t know wtf is going on but it works
        gfx.setimgdim(11, -1, -1)   
        gfx.setimgdim(11, gfx.w, gfx.h)   
        if data.send_t and #data.send_t >= 1 then 
          if gfx.w > obj.min_w_peak then GUI_peaks() end
        end  
      end
    
    -- 
      if data.show_mixer == 1 and gfx.h > obj.min_pan_h then GUI_mixer() end
    
    -- draw common buffer
      gfx.mode = 0
      gfx.dest = -1
      gfx.a = 1
        gfx.blit(10, 1, 0,
            0,0,  obj.main_w,obj.main_h,
            0,0,  obj.main_w,obj.main_h, 0,0)
        gfx.blit(11, 1, 0,
            0,0,  obj.main_w,obj.main_h,
            0,0,  obj.main_w,obj.main_h, 0,0)            
      
    update_gfx_onstart = true
    update_gfx = false
    update_gfx2 = false
    gfx.update()
  end 
  --------------------------------------------------------------------    
  function GUI_peaks()
    if not data.send_t or not data.cur_send_id or not data.send_t[data.cur_send_id] then return end
    -- frame
      F_Get_SSV(obj.gui_color.white)
      gfx.a = 0.5
      --gfx.rect(20,20,20,20,1)
    
    local x0,y0,w0,h0 = F_UnzipTable(obj.b.fader_area)
    local _,y_fad,_, h_fad = F_UnzipTable(obj.b.fader)
    -- SRC peaks
      local a = 1.5
      -- L
      gfx.a = a
      local x_srcL,y_srcL, w_srcL,h_srcL = x0+obj.offs,y_fad,obj.peak_w,h_fad
      gfx.blit(4, 1, math.rad(0),
                0, 0,  obj.main_w,obj.main_w, 
                x_srcL,y_srcL, w_srcL,h_srcL,
                0, 0) 
      F_peak_addrect(x_srcL,y_srcL, w_srcL,h_srcL,  F_Fader_From_ReaVal(data.track_peakL))
      -- R
      gfx.a = a
      local x_srcR,y_srcR, w_srcR,h_srcR = x0+obj.offs+obj.peak_dist+obj.peak_w,y_fad,obj.peak_w,h_fad
      gfx.blit(4, 1, math.rad(0),
                0, 0,  obj.main_w,obj.main_w, 
                x_srcR,y_srcR, w_srcR,h_srcR,
                0, 0) 
      F_peak_addrect( x_srcR,y_srcR, w_srcR,h_srcR,  F_Fader_From_ReaVal(data.track_peakR))  
                
    -- DEST peaks
      -- L
      gfx.a = a
      local x_dstL,y_dstL, w_dstL,h_dstL = x0+w0-obj.offs-obj.peak_w*2-obj.peak_dist,y_fad,obj.peak_w,h_fad
      gfx.blit(4, 1, math.rad(0),
                0, 0,  obj.main_w,obj.main_w, 
                x_dstL,y_dstL, w_dstL,h_dstL,
                0, 0)  
      F_peak_addrect(x_dstL,y_dstL, w_dstL,h_dstL,  F_Fader_From_ReaVal(data.send_t[data.cur_send_id].peakL))
      -- R
      gfx.a = a
      local x_dstR,y_dstR, w_dstR,h_dstR = x0+w0-obj.offs-obj.peak_w,y_fad,obj.peak_w,h_fad
      gfx.blit(4, 1, math.rad(0),
                0, 0,  obj.main_w,obj.main_w, 
                x_dstR,y_dstR, w_dstR,h_dstR,
                0, 0) 
      F_peak_addrect(x_dstR,y_dstR, w_dstR,h_dstR,  F_Fader_From_ReaVal(data.send_t[data.cur_send_id].peakR))
  end
  --------------------------------------------------------------------   
  function F_peak_addrect(x,y,w,h,fader_val, is_hor)
    if not is_hor then
      gfx.muladdrect(x, y+h-h*fader_val, w, h*fader_val,
                   1.2,-- mul_r,
                   1.8,-- mul_g,
                   1.2,-- mul_b,
                   1,-- mul_a,
                   0.55,--add_r,
                   0.5,--add_g,
                   0.5,--add_b,
                   1)--add_a] )
     else
      gfx.muladdrect(x, y, w*fader_val, h,
                   1.2,-- mul_r,
                   1.8,-- mul_g,
                   1.2,-- mul_b,
                   1,-- mul_a,
                   0.55,--add_r,
                   0.5,--add_g,
                   0.5,--add_b,
                   1)--add_a] )
    end      
  end
  --------------------------------------------------------------------     
  function GUI_knob(xywh, val)
    local  x,y,w,h = xywh.x, xywh.y, xywh.w, xywh.h
    if not val then val = 0 end
    --F_gfx_rect(x,y,w,h)
    local ang_lim = 60
    local x0,y0, r = x+w/2, y+h/2, w/2
    gfx.a = 0.3
    for i = 1 , 3, 0.2  do 
      gfx.arc(x0-1,y0, r-i, math.rad(-180+ ang_lim ), math.rad(-90), 1)
      gfx.arc(x0-1,y0-1, r-i, math.rad(-90 ), math.rad(0), 1) 
      gfx.arc(x0+1,y0-1, r-i, math.rad(0), math.rad(90), 1) 
      gfx.arc(x0+1,y0, r-i, math.rad(90), math.rad(180- ang_lim), 1) 
    end
    local ang = -90 + val * (180-ang_lim)
    local side = 1
    r = r -2
    for i = 1 , 25, 0.5  do 
      gfx.a = 0.3*(1-i/20)
      gfx.arc(x0,y0, r-i, math.rad(90+ang-side), math.rad(90+ang+side/2), 1) 
      gfx.arc(x0,y0, r-i,  math.rad(90+ang+side/2), math.rad(90+ang+side), 1) 
    end
    
    --[[local ind_h = 10
    local ind_w = 2
    r = r -5
    for i = -ind_w, ind_w*2, 0.3 do
      gfx.line(x0- (r-ind_h) * math.sin(math.rad(-90+ang-side-i)),
             y0+ (r-ind_h) * math.cos(math.rad(-90+ang-side-i)), 
             x0- r * math.sin(math.rad(-90+ang-side-i)),
             y0+ r * math.cos(math.rad(-90+ang-side-i)))
    end]]
  end
  --------------------------------------------------------------------    
  function GUI_pan() 
    local  x,y,w,h = F_UnzipTable(obj.b.pan_area) 
    if not data.send_t or not data.cur_send_id or not data.send_t[data.cur_send_id] then return end
    local val = data.send_t[data.cur_send_id].pan  
      
    -- frame
      local  x,y,w,h = F_UnzipTable(obj.b.pan_area) 
      F_Get_SSV(obj.gui_color.green)
      gfx.a = 0.1
      F_gfx_rect(x,y,w,h)
      gfx.a = 1
      F_frame(obj.b.pan_area)
      
    -- pan ctrl
      if data.pan_active_page == 1 then
        -- knob
          F_Get_SSV(obj.gui_color.green)
          gfx.a = 0.8
          GUI_knob(obj.b.pan_knob,val)
        -- value
          F_Get_SSV(obj.gui_color.green)
          gfx.a = 0.1
          local x_txt,y_txt,w_txt,h_txt = obj.b.pan_knob.x, y+ obj.knob_side*0.9 + obj.offs,   
                                          obj.b.pan_knob.w-1, h - obj.knob_side*0.9 - obj.offs*2
          local val_txt 
          
          if val > 0 then
            val_txt = math.ceil(val*100)..'% Right'
           elseif val < 0 then
            val_txt = -math.floor(val*100)..'% Left'
           elseif val ==0 then
            val_txt = 'Center'
          end
          local fr_x, fr_y, fr_w, fr_h = F_text(val_txt, x_txt+2,y_txt,w_txt,h_txt, obj.gfx_fontname, obj.gfx_fontsize_2, 'green')
          gfx.a = 0.1
          F_gfx_rect(x_txt-2,y_txt,w_txt+4,h_txt)
      end
      
    -- EQ ctrl
      if data.pan_active_page == 2 then
        gfx.a = 1
        F_Get_SSV(obj.gui_color.white)
        local pre_a, post_a
        if not data.send_t[data.cur_send_id].sendEQ or not data.send_t[data.cur_send_id].sendEQ.pre then pre_a = 0.2 end
        if not data.send_t[data.cur_send_id].sendEQ or not data.send_t[data.cur_send_id].sendEQ.post then post_a = 0.2 end
        GUI_button(obj.b.pre_eq_area,nil,nil,pre_a,false)
        GUI_button(obj.b.post_eq_area,nil,nil,post_a,false)
        if data.send_t[data.cur_send_id].sendEQ then
          if data.send_t[data.cur_send_id].sendEQ.pre then
            local HP = data.send_t[data.cur_send_id].sendEQ.pre.HP
            local LP = data.send_t[data.cur_send_id].sendEQ.pre.LP
            local x1 = obj.b.pre_eq_area.x + obj.b.pre_eq_area.w*HP
            local x2 = obj.b.pre_eq_area.x + obj.b.pre_eq_area.w*LP
            local w = math.ceil(x2-x1)
            local t = {x = x1,
                       y = obj.b.pre_eq_area.y,
                       w = w ,
                       h = obj.b.pre_eq_area.h}
            local col 
            if w < 0 then col = 'red' end
            F_frame(t, col)
          end  
          if data.send_t[data.cur_send_id].sendEQ.post then
            local HP = data.send_t[data.cur_send_id].sendEQ.post.HP
            local LP = data.send_t[data.cur_send_id].sendEQ.post.LP
            local x1 = obj.b.post_eq_area.x + obj.b.post_eq_area.w*HP
            local x2 = obj.b.post_eq_area.x + obj.b.post_eq_area.w*LP
            local w = math.ceil(x2-x1)
            local t = {x = x1,
                       y = obj.b.post_eq_area.y,
                       w = w ,
                       h = obj.b.post_eq_area.h}
            local col 
            if w < 0 then col = 'red' end
            F_frame(t, col)
          end        
        end
      end
    
    --F_frame(obj.b.post_eq_area)
    
    
  end
  --------------------------------------------------------------------      
  function F_UnzipTable(xywh) return xywh.x, xywh.y, xywh.w, xywh.h end
  -------------------------------------------------------------------- 
  function F_ReaVal_from_Fader(fader_val)
    local fader_val = F_limit(fader_val,0,1)
    local gfx_c, coeff = data.fader_scale_lim,data.fader_coeff 
    local val
    if fader_val <=gfx_c then
      local lin2 = fader_val/gfx_c
      local real_dB = coeff*math.log(lin2, 10)
      val = 10^(real_dB/20)
     else
      local real_dB = 12 * (fader_val  / (1 - gfx_c) - gfx_c/ (1 - gfx_c))
      val = 10^(real_dB/20)
    end
    if val > 4 then val = 4 end
    if val < 0 then val = 0 end
    return val
  end
  -------------------------------------------------------------------- 
  function F_Fader_From_ReaVal(rea_val)  
    local rea_val = F_limit(rea_val, 0, 4)
    local val 
    local gfx_c, coeff = data.fader_scale_lim,data.fader_coeff 
    local real_dB = 20*math.log(rea_val, 10)
    local lin2 = 10^(real_dB/coeff)  
    if lin2 <=1 then val = lin2*gfx_c else val = gfx_c + (real_dB/12)*(1-gfx_c) end
    if val > 1 then val = 1 end
    return F_limit(val, 0.0001, 1)
  end
  --------------------------------------------------------------------     
  function F_Val_From_dB(dB_val) return 10^(dB_val/20) end
  function F_dBFromVal(val) return 20*math.log(val, 10) end
  --------------------------------------------------------------------     
  function GUI_fader()   
    if not data.send_t or not data.cur_send_id or not data.send_t[data.cur_send_id] then return end
    local val =  data.send_t[data.cur_send_id].vol    
    local y_man = F_Fader_From_ReaVal(val) 
    local left_shift = 0
    -- fader frame   
    --gfx.a = 1 F_gfx_rect(F_UnzipTable(obj.b.fader))
    
      local x_f,y_f,w_f,h_f = F_UnzipTable(obj.b.fader ) 
      F_Get_SSV(obj.gui_color.green)
      gfx.a = 0.1
      F_gfx_rect(F_UnzipTable(obj.b.fader_area))
      gfx.a = 1
      F_frame(obj.b.fader_area) 
      -- level 
      local t
        if gfx.h > obj.min_h_buttons and obj.b.fader_area.h > 100 then 
          t = { -120,
              -48,
              -24,
              -12,
              -6,
              0,
              '+6',
              '+12'
              }   
         else
          t = {-120,-12,0,'+12'}   
      end
      -- center line
        local manual_h = 10
        local cent_line_w = 2
        F_Get_SSV(obj.gui_color.white)
        gfx.a = 0.49
        gfx.rect(x_f,
                 y_f,
                 cent_line_w,
                 h_f+1)
              
        
      -- manual
        local manual_w = w_f
        gfx.a = 0.5
        
        
        if data.small_man == 1 then
          local y_man_mir = y_f-manual_h/2+h_f-h_f*y_man
          gfx.blit(3, 1, math.rad(180),
                  0, 0,  obj.glass_side,obj.glass_side/2, 
                  x_f, 
                  y_man_mir,
                  manual_w,          
                  manual_h/2,
                  0, 0)   
          gfx.blit(3, 1, math.rad(0),
                  0, 0,  obj.glass_side,obj.glass_side, 
                  x_f+1, 
                  y_man_mir + manual_h/2,
                  manual_w-1,
                  manual_h/2,
                  0, 0)
          gfx.a = 0.5
          F_Get_SSV(obj.gui_color.green)
          gfx.rect(x_f+1,-1+y_man_mir+manual_h/2, line_w/2,3) 
          
         else
          gfx.a = 0.6
          gfx.blit(3, 1, math.rad(0),
                  0, 0,  obj.glass_side,obj.glass_side/2, 
                  x_f, 
                  y_f+h_f-h_f*y_man,
                  manual_w,          
                  h_f*y_man+2,
                  0, 0)     
          if data.send_t[data.cur_send_id].col then 
            F_Get_SSV(F_ssv_fromNative(data.send_t[data.cur_send_id].col), true) 
            gfx.a = 0.2
            gfx.rect(x_f, y_f+h_f-h_f*y_man, manual_w, h_f*y_man+2,1)
          end
      -- level lines
        local line_w = 10
        F_Get_SSV(obj.gui_color.white)
        gfx.a = 1
        for i = 1, #t do
          local t_val = tonumber(t[i])
          local rea_val = F_Val_From_dB(t_val)
          local y1 = F_Fader_From_ReaVal(rea_val)  
          if y1 < 0.004 then y1 = 0 end
          gfx.a = 0.3
          gfx.setfont(1, obj.gfx_fontname, obj.gfx_fontsize_2)
          gfx.line(x_f+2, y_f + h_f - h_f *y1, x_f+line_w/2, y_f + h_f - h_f *y1)
          gfx.x = x_f + w_f - gfx.measurestr(t[i]..'dB')
          gfx.y = y_f + h_f - h_f *y1- gfx.texth/2-1
          gfx.a = 0.6
          gfx.drawstr(t[i]..'dB')
        end
          
      end
      gfx.a = 1           
  end  
  --------------------------------------------------------------------     
  function GUI_mixer()
    if data.send_t and #data.send_t > 0 then
      local x,y,w,h = F_UnzipTable(obj.b.params_area)
      local val = data.send_t[data.cur_send_id].vol
      gfx.a = 1
      local dist = 5
      local x_p = obj.b.params_area.x +obj.offs 
      local y_p = obj.b.params_area.y +obj.offs
      local w_p = obj.peak_w-1
      local h_p =obj.b.params_area.h-obj.offs*2
      for i = 1, #data.send_t do
          local x,y,w,h = F_UnzipTable(obj.b.params_area)
          local x_p = x_p + (i-1)* (obj.offs*3+w_p+1)
          if x_p+w_p+5 > x+w-obj.offs*2 then break end -- 5 is texth
          local x_p2 = x_p + w_p
          local name_w = 100--gfx.measurestr(name)
          local text_x = x_p2 - name_w/2 + 17
          gfx.a = 0.7          
        if update_gfx2 then
          gfx.dest = 11           
          gfx.blit(4, 1, math.rad(0),
                      0, 0,  obj.main_w, obj.main_w, 
                      x_p , y_p, w_p ,h_p,
                      0, 0)
          gfx.blit(4, 1, math.rad(0),
                      0, 0,  obj.main_w, obj.main_w, 
                      x_p2 , y_p, w_p ,h_p,
                      0, 0)                 
          F_peak_addrect( x_p, y_p, w_p, h_p,  F_Fader_From_ReaVal(data.send_t[i].peakL)) 
          F_peak_addrect( x_p2, y_p, w_p, h_p,  F_Fader_From_ReaVal(data.send_t[i].peakR))
        end
        local incr
        if update_gfx then
          
          if i == data.cur_send_id then
            F_Get_SSV(obj.gui_color.green, true)
            incr = 1
           else 
            F_Get_SSV(obj.gui_color.white, true)
            incr = 0
          end
          local name = data.send_t[i].send_name
          name = F_extract_name(name)
          
          -- draw level
            gfx.dest = 10
            gfx.a = 0.49
            --F_Get_SSV(obj.gui_color.white, true)
            local pan = data.send_t[i].pan            
            local rect_h = (h_p*F_Fader_From_ReaVal(data.send_t[i].vol))
            local rect_hL = F_limit(rect_h-rect_h*pan,0,rect_h)
            local rect_hR = F_limit(rect_h+rect_h*pan,0,rect_h)
            gfx.rect(x_p2+obj.offs, y_p + h_p-rect_hL , obj.offs, rect_hL)
            gfx.rect(x_p2+obj.offs*2, y_p + h_p-rect_hR , obj.offs, rect_hR)
          -- graw/blit txt            
            gfx.setfont(1, obj.gfx_fontname,obj.gfx_fontsize_2+incr)
            local measstr = gfx.measurestr(name)
            gfx.dest = 12
              gfx.setimgdim(12, -1, -1)  
              gfx.setimgdim(12, name_w, name_w)  
              gfx.x, gfx.y = (h_p-measstr)/2,0
              gfx.a = 1
              gfx.drawstr(name)
            gfx.dest = 10
              gfx.a = 1
              gfx.blit(12, 1, math.rad(90), 
                        0,0,name_w, name_w, 
                        text_x-50 , y_p  , name_w ,name_w, 0,0)
        end
      end
    end    
  end
  --------------------------------------------------------------------   
  function F_extract_name(name)    -- sub aux/send from name not case sensitive
    local name_find = name:lower():find('aux')
    if name_find then 
      local name0 = name:sub(0,name_find-1)
      local name1 = name:sub(name_find+3) 
      name = name0..name1
    end
    local name_find = name:lower():find('send')
      if name_find then 
        local name0 = name:sub(0,name_find-1)
        local name1 = name:sub(name_find+4) 
        name = name0..name1
      end            
      local name_find = name:find(' ')
      if name_find and name_find == 1 then name = name:sub(2) end  
    return name
  end  
  --------------------------------------------------------------------   
  function F_frame(xywh, color, a, noframe, color_native) 
    local  x,y,w,h = xywh.x, xywh.y, xywh.w, xywh.h
    if not a then gfx.a = 0.35 else gfx.a = a end
    gfx.blit(3, 1, math.rad(180),
              0, 0,  obj.glass_side/2,obj.glass_side, 
              x,y,w,h,
              0, 0)
    gfx.mode =2
    
    if not color then 
      color = 'white' 
      if color_native then 
        if color_native == 0 then 
          gfx.a = 0.2
          F_Get_SSV(obj.gui_color.white, true) 
         else
          gfx.a = 0.4
          F_Get_SSV(F_ssv_fromNative(color_native), true) 
        end
        
        gfx.rect(x,y,w,h,1)
      end  
     else 
      gfx.a = 0.3      
      F_Get_SSV(obj.gui_color[color])
      gfx.rect(x,y,w,h-1,1)
      gfx.a = 0.6
    end
    
    --[[if color then F_Get_SSV(obj.gui_color[color], true) end
    if color_native then 
      F_Get_SSV(F_ssv_fromNative(color_native), true) 
      msg(F_ssv_fromNative(color_native))
    end]]
    
    -- frame
      F_Get_SSV(obj.gui_color.green, true)
      gfx.a = 0.08  
      if not noframe then F_gfx_rect(x,y,w,h)end
    gfx.mode = obj.gfx_mode 
  end  
  -----------------------------------------------------------------------    
  function F_gfx_rect(x,y,w,h)
    if x and y and w and h then 
      gfx.x, gfx.y = x,y
      gfx.line(x, y, x+w, y)
      gfx.line(x+w, y+1, x+w, y+h - 1)
      gfx.line(x+w, y+h,x, y+h)
      gfx.line(x, y+h-1,x, y+1)
    end
  end   
  --------------------------------------------------------------------    
  function F_text(text, x,y,w,h, fontname,fontsize, color, alpha)
    -- calc / set variables
      gfx.setfont(1, fontname, fontsize)
      local measurestrname = gfx.measurestr(text)
      local x0 = x + (w - measurestrname)/2 
      local y0 = y + (h - gfx.texth)/2
    -- text
      if alpha then gfx.a = alpha else gfx.a = 0.7 end
      F_Get_SSV(obj.gui_color[color], true)
      gfx.x, gfx.y = x0,y0 
      gfx.drawstr(text)
    local offs = 5 
    return x0-offs , y, measurestrname+offs*2 -1, h
  end   
  -----------------------------------------------------------------------         
  function GUI_button(obj_t, ext_text, ext_color, cust_alpha, frame)
    if not obj_t then return end
    local color
    local x,y,w,h, name = obj_t.x, obj_t.y, obj_t.w, obj_t.h, obj_t.name
    if not x then return end
    if ext_text then name = ext_text end
    -- frame
      if not frame then
        gfx.a = 0.1
        F_Get_SSV(obj.gui_color.white, true)
        F_gfx_rect(x,y,w,h)
      end      
    -- back
      gfx.a = 0.2
      gfx.blit(3, 1, math.rad(180), 1,1,50,50, x,y+1,w,h, 0,0)                
    --  text
      if obj_t.color then color = obj_t.color 
        elseif ext_color then color = ext_color
        else color = 'white' 
      end
      F_text(name, x+1,y,w,h, obj.gfx_fontname, obj.gfx_fontsize_3, color, cust_alpha) 
      gfx.a = 1   
  end   
  ------------------------------------------------------------------ 
  function MOUSE_match(b, offs)
    if b and b.x then
      local mouse_y_match = b.y
      local mouse_h_match = b.y+b.h
      if offs then 
        mouse_y_match = mouse_y_match - offs 
        mouse_h_match = mouse_y_match+b.h
      end
      if mouse.mx > b.x and mouse.mx < b.x+b.w and mouse.my > mouse_y_match and mouse.my < mouse_h_match then return true end 
    end
  end 
  -----------------------------------------------------------------------     
  function MOUSE_button (xywh, offs, is_right)    
    if is_right then
      if MOUSE_match(xywh, offs) and mouse.RMB_state and not mouse.last_RMB_state then return true end
     else
      if MOUSE_match(xywh, offs) and mouse.LMB_state and not mouse.last_LMB_state then return true end
    end
  end
  -----------------------------------------------------------------------    
  function DEFINE_data() local track
    if data.enable_follow_track_selection == 1 then 
      data.track_pointer =  reaper.GetSelectedTrack(0,0)
     else
      data.track_pointer = data.track_pointer0
    end
    
    if not data.track_pointer then 
      if data.enable_follow_track_selection == 0 then 
        data.cur_tr_src_name = '> Get track'
       else
        data.cur_tr_src_name = '(no track selected)'
      end
      data.cur_tr_dest_name  = '(no track selected)'
      data.send_t = {}
      return 
    end
    
    -- update send ID / id
      data.track_GUID = reaper.GetTrackGUID( data.track_pointer ) 
      if not data.last_track_GUID or data.last_track_GUID ~= data.track_GUID then data.cur_send_id = 1 end
      
      if data.ext_cur_send_id then 
        if f_run then 
          data.cur_send_id = data.ext_cur_send_id 
          f_run = nil 
        end 
      end
      if data.ext_srctrGUID then 
        data.track_pointer =  reaper.BR_GetMediaTrackByGUID( 0,data.ext_srctrGUID )
        data.last_track_GUID = data.ext_srctrGUID 
      end
      
      if not data.track_pointer then return end
      
      data.last_track_GUID = data.track_GUID
      data.track_col = reaper.GetTrackColor( data.track_pointer)
    -- get name
      local _, tr_name = reaper.GetSetMediaTrackInfo_String( data.track_pointer, 'P_NAME', '', 0 )
      local tr_id =  reaper.CSurf_TrackToID( data.track_pointer, false )
      if tr_name == '' then 
        data.cur_tr_src_name = '#'..tr_id..' '..'(untitled) →' 
       else
        data.cur_tr_src_name = '#'..tr_id..' '..tr_name..' →'
      end      
    -- get source peak info
      data.track_peakL = reaper.Track_GetPeakInfo( data.track_pointer, 0 )
      data.track_peakR = reaper.Track_GetPeakInfo( data.track_pointer, 1 )
      --data.track_peakH = reaper.Track_GetPeakHoldDB( track, channel, clear )
      
    -- get send table
      data.send_t = {}
      local cnt_sends = reaper.GetTrackNumSends( data.track_pointer, 0 )
      data.cnt_sendsHW = reaper.GetTrackNumSends( data.track_pointer, 1 )
      for i = 1, cnt_sends do
        local _, send_name = reaper.GetTrackSendName( data.track_pointer, i-1+data.cnt_sendsHW, '' )  
        local dest_tr = reaper.BR_GetMediaTrackSendInfo_Track( data.track_pointer, 0, i-1, 1 )  
        local dest_tr_id =  reaper.CSurf_TrackToID( dest_tr, false )
        
        -- parse sendEQ
          local sendEQ = {}
          local fx_cnt = reaper.TrackFX_GetCount( dest_tr )
          for fx_i = 1,  fx_cnt do
            local _, fx_name = reaper.TrackFX_GetFXName( dest_tr, fx_i-1, '' )
            if fx_i == 1 and fx_name == 'PreEQ' then
              local HP, LP
              for paramidx = 1, reaper.TrackFX_GetNumParams(dest_tr, fx_i-1 ) do
                local _, bandtype, _, paramtype, normval = reaper.TrackFX_GetEQParam( dest_tr, fx_i-1, paramidx-1 )
                if bandtype == 0 and paramtype == 0 then HP = normval end
                if bandtype == 5 and paramtype == 0 then LP = normval end
              end
              sendEQ.pre = {HP =  HP,
                            LP =  LP}
            end
            if fx_i == fx_cnt  and fx_name == 'PostEQ' then
              local HP, LP
              for paramidx = 1, reaper.TrackFX_GetNumParams(dest_tr, fx_i-1 ) do
                local _, bandtype, _, paramtype, normval = reaper.TrackFX_GetEQParam( dest_tr, fx_i-1, paramidx-1 )
                if bandtype == 0 and paramtype == 0 then HP = normval end
                if bandtype == 5 and paramtype == 0 then LP = normval end
              end
              sendEQ.post = {HP =  HP,
                            LP =  LP}
            end
          end
        local col = reaper.GetTrackColor( dest_tr )
        if col == 0 then col = nil end
        local cat =0
        data.send_t[#data.send_t+1] = { send_name = send_name,
                                      send_id = dest_tr_id,
                                      col = col,
                                      pan = reaper.GetTrackSendInfo_Value( data.track_pointer, cat, i-1, 'D_PAN' ) ,
                                      vol = F_limit(reaper.GetTrackSendInfo_Value( data.track_pointer, cat, i-1, 'D_VOL' ),0,4),
                                      mute = reaper.GetTrackSendInfo_Value( data.track_pointer, cat, i-1, 'B_MUTE' ) ,
                                      phase = reaper.GetTrackSendInfo_Value( data.track_pointer, cat, i-1, 'B_PHASE' ),
                                      mono = reaper.GetTrackSendInfo_Value( data.track_pointer, cat, i-1, 'B_MONO'),
                                      send_mode = reaper.GetTrackSendInfo_Value( data.track_pointer, cat, i-1, 'I_SENDMODE'), 
                                      peakL = reaper.Track_GetPeakInfo( dest_tr, 0 ),
                                      peakR = reaper.Track_GetPeakInfo( dest_tr, 1 ),
                                      dest_GUID = reaper.GetTrackGUID( dest_tr ),
                                      sendEQ = sendEQ }
      end
      --if not data.cur_send_id then data.cur_send_id = 1 end
      
      if data.send_t[data.cur_send_id] then
        data.cur_tr_dest_name = '→ #'..data.send_t[data.cur_send_id].send_id..' '..F_extract_name(data.send_t[data.cur_send_id].send_name)
       else data.cur_tr_dest_name = ''
      end
      
      if data.remote == 1 then 
        data.ext_vol = reaper.GetExtState( 'mpl SendFader', 'EXT_vol' )
        if not data.last_ext_vol or data.last_ext_vol ~= data.ext_vol then 
          if data.ext_vol and tonumber(data.ext_vol) 
            and data.cur_send_id 
            and data.send_t[data.cur_send_id] then 
            data.send_t[data.cur_send_id].vol = F_ReaVal_from_Fader(tonumber(data.ext_vol) )
            update_gfx = true 
            ENGINE_app_data()
          end           
        end
        data.last_ext_vol = data.ext_vol 
      end
      
  end
  -----------------------------------------------------------------------      
  function Action_add_all_sends()
  
  end
  -----------------------------------------------------------------------   
  function ENGINE_add_sends_to_list(t)
    local guid_t = {}
    for i = 1, reaper.CountTracks(0) do
      local exist = false
      local tr = reaper.GetTrack(0,i-1)
      local trGUID = reaper.GetTrackGUID( tr )    
      -- check - is there send from dest channel to current track
        for send_id = 1,  reaper.GetTrackNumSends( tr, 0 ) do
          local desttr_check = reaper.BR_GetMediaTrackSendInfo_Track( tr, 0, send_id-1, 1 )
          if desttr_check == data.track_pointer then exist = true break end
        end
      -- check -is there already send
      if trGUID ~= data.track_GUID then
        if data.send_t then
          for send_id = 1, #data.send_t do
            local dest_GUID = data.send_t[send_id].dest_GUID
            if dest_GUID == trGUID then
              exist = true
              break 
            end
          end
         else
          exist = false
        end        
      -- if pass checks
        if not exist then
          local _, tr_name = reaper.GetSetMediaTrackInfo_String( tr, 'P_NAME', '', 0 )
          if tr_name:lower():find('send') or tr_name:lower():find('aux') then
            local tr_id =  reaper.CSurf_TrackToID( tr, false )
            local out_name
            if tr_name == '' then 
              out_name = ' #'..tr_id..' '..'(untitled)' 
             else 
              out_name = ' #'..tr_id..' '..F_extract_name(tr_name )
            end 
            guid_t[#guid_t+1] = {guid = trGUID,name = out_name}
          end
        end
      end
    end
    
    return t, guid_t
  end
  -----------------------------------------------------------------------     
  function F_SetFXName(track, fx, new_name)
    -- get ref guid
      if not track or not tonumber(fx) then return end
      local FX_GUID = reaper.TrackFX_GetFXGUID( track, fx )
      if not FX_GUID then return else FX_GUID = FX_GUID:gsub('-',''):sub(2,-2) end
      plug_type = reaper.TrackFX_GetIOSize( track, fx )
    -- get chunk t
      local _, chunk = reaper.GetTrackStateChunk( track, '', false )
      local t = {} for line in chunk:gmatch("[^\r\n]+") do t[#t+1] = line end
    -- find edit line
      local search
      for i = #t, 1, -1 do
        local t_check = t[i]:gsub('-','')
        if t_check:find(FX_GUID) then search = true  end
        if t[i]:find('<') and search and not t[i]:find('JS_SER') then 
          edited_line = t[i]:sub(2)
          edited_line_id = i
          break
        end
      end
    -- parse line
      if not edited_line then return end
      if not edited_line:find('ReaEQ') then return end
      local t1 = {}
      for word in edited_line:gmatch('[%S]+') do t1[#t1+1] = word end
      t2 = {}
      for i = 1, #t1 do 
        segm = t1[i]
        if not q then t2[#t2+1] = segm else t2[#t2] = t2[#t2]..' '..segm end
        if segm:find('"') and not segm:find('""') then if not q then q = true else q = nil end end
      end
      
      if plug_type == 2 then t2[3] = '"'..new_name..'"' end -- if JS
      if plug_type == 3 then t2[5] = '"'..new_name..'"' end -- if VST
      
      local out_line = table.concat(t2,' ')
      t[edited_line_id] = '<'..out_line
      out_chunk = table.concat(t,'\n')
      --msg(out_chunk)
      reaper.SetTrackStateChunk( track, out_chunk, false )
      reaper.UpdateArrange()
  end 
  -----------------------------------------------------------------------   
  function F_reset_EQ(tr, fx, HP_freq, LP_freq)
    -- 0Hz for LP
      reaper.TrackFX_SetEQParam( tr, fx, 
        0,--bandtype HP, 
        0,--bandidx, 
        0,-- paramtype, freq
        HP_freq, --val, 
        true)--isnorm )
    -- 0dB for HP
      reaper.TrackFX_SetEQParam( tr, fx, 
        0,--bandtype HP, 
        0,--bandidx, 
        1,-- paramtype, gain
        0, --val, 
        true)--isnorm )      
    -- 22.5fHz for LP
      reaper.TrackFX_SetEQParam( tr, fx, 
        5,--bandtype LP,
        0,--bandidx, 
        0,-- paramtype, freq
        LP_freq, --val, 
        true)--isnorm )   
    -- 0dB for LP     
      reaper.TrackFX_SetEQParam( tr, fx, 
        5,--bandtype LP,
        0,--bandidx, 
        1,-- paramtype, gain
        0, --val, 
        true)--isnorm )          
  end
  -----------------------------------------------------------------------
  function MOUSE_DC(xywh)
    if MOUSE_match(xywh) 
      and not mouse.last_LMB_state 
      and mouse.LMB_state
      and mouse.last_click_ts 
      and clock - mouse.last_click_ts < 0.3 then
        return true
    end
    if MOUSE_match(xywh) and not mouse.last_LMB_state and mouse.LMB_state then
      mouse.last_click_ts = clock
    end
  end
  -----------------------------------------------------------------------     
  function MOUSE_get()--notes, 
    mouse.abs_x, mouse.abs_y = reaper.GetMousePosition()
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
    if not mouse.last_mx or not mouse.last_my or (mouse.last_mx ~= mouse.mx and mouse.last_my ~= mouse.my) then
      mouse.move = true else mouse.move = false
    end
    if mouse.last_wheel then mouse.wheel_trig = (mouse.wheel - mouse.last_wheel) end
    if not mouse.wheel_trig then mouse.wheel_trig = 0 end    
    if not mouse.last_LMB_state and mouse.LMB_state then 
      mouse.LMB_stamp_x = mouse.mx
      mouse.LMB_stamp_y = mouse.my
    end    
    if mouse.LMB_state then 
      mouse.dx = mouse.mx - mouse.LMB_stamp_x
      mouse.dy = mouse.my - mouse.LMB_stamp_y
    end
    
    -- click on track name
      if data.enable_follow_track_selection == 0 then 
        if MOUSE_button(obj.b.tr_name) then
          data.track_pointer0 = reaper.GetSelectedTrack(0,0)
          update_gfx = true
        end        
      end
    -- click on send name
      if MOUSE_button(obj.b.tr_send_name) and data.cur_send_id then
        --local send_guids
        t = {}
        -- form existed sends
          for i = 1 , #data.send_t do t[#t+1] = ' #'..data.send_t[i].send_id..' '..data.send_t[i].send_name end
          t, send_guids = ENGINE_add_sends_to_list(t)
          if #t >0 and #t < #data.send_t +1 then t[#t] = t[#t]..'|' end
          if #send_guids > 0 then 
            t[#t+1] = 'Add all listed sends||#Send to...'
            for i = 1, #send_guids do  t[#t+1] = send_guids[i].name  end
          end
          
          if t[#t] and t[#t]:find('|') and t[#t]:find('|')==t[#t]:len() then t[#t] = t[#t]:sub(0,-2) end -- prevent last separator
          local ret = GUI_menu(t, -1 )+ 1
          
          if ret > 0 and ret < #data.send_t+1 then 
            data.cur_send_id = ret update_gfx = true 
            
           elseif ret == #data.send_t+1 then -- add all sends
            for i = 1, #send_guids do
              local dest_tr_guid = send_guids[i].guid
              local dest_tr =  reaper.BR_GetMediaTrackByGUID( 0, dest_tr_guid )
              reaper.CreateTrackSend( data.track_pointer, dest_tr )
            end
            update_gfx = true              
           elseif ret >= #data.send_t+2 then -- add selected send
            --msg(send_guids[ret-#data.send_t-2])
            local new_send_menuid  = ret-#data.send_t-2
            if #send_guids > 0 and send_guids[new_send_menuid] then
              local dest_tr_guid = send_guids[new_send_menuid].guid
              local dest_tr =  reaper.BR_GetMediaTrackByGUID( 0, dest_tr_guid )
              reaper.CreateTrackSend( data.track_pointer, dest_tr )
              update_gfx = true
            end            
          end      
      end
      
      if data.pan_active_page == 2 then
        -- pre EQ
        if MOUSE_match(obj.b.pre_eq_area) and mouse.LMB_state and not mouse.last_LMB_state then 
          if not data.send_t[data.cur_send_id].sendEQ or not data.send_t[data.cur_send_id].sendEQ.pre then
            local dest_tr = reaper.BR_GetMediaTrackByGUID( 0, data.send_t[data.cur_send_id].dest_GUID)
            local new_fx_id = reaper.TrackFX_AddByName( dest_tr, 'ReaEQ (Cockos)', false, -1 )
            F_reset_EQ(dest_tr, new_fx_id, 0, 1)
            for i = new_fx_id, 0, -1 do reaper.SNM_MoveOrRemoveTrackFX( dest_tr, i, -1) end
            F_SetFXName(dest_tr, 0, 'PreEQ')
           else
            mouse.last_obj = obj.b.pre_eq_area.mouse_id
            mouse.last_obj_val = {data.send_t[data.cur_send_id].sendEQ.pre.HP,
                                  data.send_t[data.cur_send_id].sendEQ.pre.LP}
          end          
        end
        if mouse.last_obj == obj.b.pre_eq_area.mouse_id and mouse.LMB_state and mouse.last_obj_val then
          local new_HP = mouse.last_obj_val[1] - mouse.dy/data.fader_mouse_resolution + mouse.dx/data.fader_mouse_resolution
          local new_LP = mouse.last_obj_val[2] + mouse.dy/data.fader_mouse_resolution + mouse.dx/data.fader_mouse_resolution
          local dest_tr = reaper.BR_GetMediaTrackByGUID( 0, data.send_t[data.cur_send_id].dest_GUID)
          if data.link == 1 then
            for send_i = 1, #data.send_t do
              local dest_tr = reaper.BR_GetMediaTrackByGUID( 0, data.send_t[send_i].dest_GUID)
              F_reset_EQ(dest_tr, 0, F_limit(new_HP,0,1), F_limit(new_LP,0,1))
            end
           else
            F_reset_EQ(dest_tr,0, F_limit(new_HP,0,1), F_limit(new_LP,0,1))
          end
          update_gfx = true
        end
        -- post eq
        if MOUSE_match(obj.b.post_eq_area) and mouse.LMB_state and not mouse.last_LMB_state then 
          if not data.send_t[data.cur_send_id].sendEQ or not data.send_t[data.cur_send_id].sendEQ.post then
            local dest_tr = reaper.BR_GetMediaTrackByGUID( 0, data.send_t[data.cur_send_id].dest_GUID)
            local new_fx_id = reaper.TrackFX_AddByName( dest_tr, 'ReaEQ (Cockos)', false, -1 )
            F_reset_EQ(dest_tr, new_fx_id, 0, 1)
            F_SetFXName(dest_tr, new_fx_id, 'PostEQ')
           else
            mouse.last_obj = obj.b.post_eq_area.mouse_id
            mouse.last_obj_val = {data.send_t[data.cur_send_id].sendEQ.post.HP,
                                  data.send_t[data.cur_send_id].sendEQ.post.LP}            
          end
          mouse.last_obj = obj.b.post_eq_area.mouse_id
        end
        if mouse.last_obj == obj.b.post_eq_area.mouse_id and mouse.LMB_state and mouse.last_obj_val then
          local new_HP = mouse.last_obj_val[1] - mouse.dy/data.fader_mouse_resolution + mouse.dx/data.fader_mouse_resolution
          local new_LP = mouse.last_obj_val[2] + mouse.dy/data.fader_mouse_resolution + mouse.dx/data.fader_mouse_resolution
          if data.link == 1 then
            for send_i = 1, #data.send_t do
              local dest_tr = reaper.BR_GetMediaTrackByGUID( 0, data.send_t[send_i].dest_GUID)
              local last_fx = reaper.TrackFX_GetCount( dest_tr )  
              F_reset_EQ( dest_tr,last_fx-1, F_limit(new_HP,0,1), F_limit(new_LP,0,1) )
            end
           else     
            local dest_tr = reaper.BR_GetMediaTrackByGUID( 0, data.send_t[data.cur_send_id].dest_GUID)
            local last_fx = reaper.TrackFX_GetCount( dest_tr )     
            F_reset_EQ( dest_tr,last_fx-1, F_limit(new_HP,0,1), F_limit(new_LP,0,1) )
          end
          update_gfx = true
        end        
      end    
    
    -- pan next page 
      if MOUSE_button(obj.b.next_page)  then
        data.pan_active_page = data.pan_active_page + 1
        if data.pan_active_page == 3 then data.pan_active_page = 1 end
        update_gfx = true
      end 
      
    -- vol fader
      if data.send_t and data.cur_send_id and data.send_t[data.cur_send_id] then 
        -- wheel
          if mouse.wheel_trig~= 0 and MOUSE_match(obj.b.fader) then
            mouse.last_obj =        obj.b.fader.mouse_id 
            mouse.last_obj_value =   F_Fader_From_ReaVal(data.send_t[data.cur_send_id].vol) -- fader
            mouse.last_stored_send_t = data.send_t
            local new_val_fader
            if mouse.wheel_trig > 0 then               
              new_val_fader =  F_limit(mouse.last_obj_value + data.incr_vol_wheel,0,1)
             else
              new_val_fader =  F_limit(mouse.last_obj_value - data.incr_vol_wheel,0,1)
            end            
            if data.link == 1 then
              local diff = new_val_fader - mouse.last_obj_value            
              local diff_coeff = diff   / F_limit(mouse.last_obj_value ,0.00001, 6)              
              for send_i = 1, #data.send_t do
                if send_i ~= data.cur_send_id then   
                  old_val_fader = F_Fader_From_ReaVal(mouse.last_stored_send_t[send_i].vol) 
                  new_val_fader1 = F_limit(old_val_fader * (1 + diff_coeff),0,1)
                  out_val = F_ReaVal_from_Fader(new_val_fader1)                  
                  data.send_t[send_i].vol = out_val
                end
              end               
            end 
            data.send_t[data.cur_send_id].vol = F_ReaVal_from_Fader(new_val_fader)  -- reaval     
            ENGINE_app_data()
          end
        -- rightclick
          if MOUSE_button(obj.b.fader, nil, true) then
            ret, str = reaper.GetUserInputs( 'MPL Sendfader: set volume', 1, 'dB', math.floor(F_dBFromVal(data.send_t[data.cur_send_id].vol )*100)/100)
            if ret and tonumber(str) then
              local dbval = tonumber(str)
              if dbval > -90 and dbval < 12 then
                local out_val = F_Val_From_dB(dbval)
                if data.link == 1 then
                  for send_i = 1, #data.send_t do data.send_t[send_i].vol = out_val end
                 else
                  data.send_t[data.cur_send_id].vol = out_val
                end
                ENGINE_app_data()
              end
            end
          end
        -- doubleclick
          if MOUSE_DC(obj.b.fader) then 
            if data.link == 1 then
              for send_i = 1, #data.send_t do data.send_t[send_i].vol = 1 end
             else
              data.send_t[data.cur_send_id].vol = 1  
            end 
            ENGINE_app_data()
          end
        -- left drag
          if MOUSE_match(obj.b.fader) and mouse.LMB_state and not mouse.last_LMB_state then
            mouse.last_obj =        obj.b.fader.mouse_id 
            mouse.last_obj_value =   F_Fader_From_ReaVal(data.send_t[data.cur_send_id].vol) -- fader
            mouse.last_stored_send_t = data.send_t       
          end
          if mouse.last_obj == obj.b.fader.mouse_id  and mouse.LMB_state and mouse.last_obj_value then     
            local new_val_fader = mouse.last_obj_value  - mouse.dy/data.fader_mouse_resolution -- fader
            if data.link == 1 then          
              local diff = new_val_fader - mouse.last_obj_value            
              if diff ~= 0 and diff < 1  then 
                diff_coeff = diff   / F_limit(mouse.last_obj_value ,0.00001, 6)
                data.send_t[data.cur_send_id].vol = F_ReaVal_from_Fader(new_val_fader)  -- reaval 
                for send_i = 1, #data.send_t do
                  if send_i ~= data.cur_send_id then   
                    old_val_fader = F_Fader_From_ReaVal(mouse.last_stored_send_t[send_i].vol) 
                    new_val_fader1 = F_limit(old_val_fader * (1 + diff_coeff),0,1)
                    out_val = F_ReaVal_from_Fader(new_val_fader1)                  
                    data.send_t[send_i].vol = out_val
                  end
                end
              end            
             else
              data.send_t[data.cur_send_id].vol = F_ReaVal_from_Fader(new_val_fader)            
            end          
          ENGINE_app_data()
        end  
      end   
         
      -- pan
      if data.pan_active_page == 1 then        
        if data.send_t and data.cur_send_id and data.send_t[data.cur_send_id] then 
          -- wheel
          if MOUSE_match(obj.b.pan_knob) and mouse.wheel_trig~= 0  then
            mouse.last_obj =        obj.b.pan_knob.mouse_id 
            mouse.last_obj_value =  (data.send_t[data.cur_send_id].pan + 1 )/2 -- fader
            mouse.last_stored_send_t = data.send_t 
            local new_val_fader
            if mouse.wheel_trig > 0 then               
              new_val_fader =  F_limit(mouse.last_obj_value + data.incr_pan_wheel,0,1) 
             else
              new_val_fader =  F_limit(mouse.last_obj_value - data.incr_pan_wheel,0,1)
            end 
            if data.link == 1 then
              local diff = new_val_fader - mouse.last_obj_value            
              if diff ~= 0 and diff < 1 and new_val_fader ~= 0  then
                diff_coeff = diff   / F_limit(mouse.last_obj_value,0.00001, 6)
                data.send_t[data.cur_send_id].pan = F_limit(new_val_fader*2-1,-1,1)
                for send_i = 1, #data.send_t do
                  if send_i ~= data.cur_send_id then   
                    old_val_fader = (mouse.last_stored_send_t[send_i].pan+1)/2 -- fader
                    new_val_fader1 = F_limit(old_val_fader * (1 + diff_coeff),0,1)
                    data.send_t[send_i].pan = new_val_fader1*2-1
                  end
                end
              end                  
             else
              data.send_t[data.cur_send_id].pan = F_limit(new_val_fader*2-1,-1,1)
            end
            ENGINE_app_data()
          end          
          --right click
            if MOUSE_button(obj.b.pan_knob, nil, true) then
              ret, str = reaper.GetUserInputs( 'MPL Sendfader: set pan', 1, '-1...+1', data.send_t[data.cur_send_id].pan)
              if ret and tonumber(str) then
                local panval = tonumber(str)
                if panval >= -1 and panval <= 1 then
                  if data.link == 1 then
                    for send_i = 1, #data.send_t do data.send_t[send_i].pan = panval end
                   else
                    data.send_t[data.cur_send_id].pan = panval
                  end
                  ENGINE_app_data()
                end
              end
            end   
          -- doubleckick     
            if MOUSE_DC(obj.b.pan_knob) then 
              if data.link == 1 then
                for send_i = 1, #data.send_t do data.send_t[send_i].pan = 0 end
               else
                data.send_t[data.cur_send_id].pan = 0  
              end 
            end
          -- left drag
            if MOUSE_match(obj.b.pan_knob) and mouse.LMB_state and not mouse.last_LMB_state then
              mouse.last_obj =        obj.b.pan_knob.mouse_id 
              mouse.last_obj_value =  (data.send_t[data.cur_send_id].pan + 1 )/2 -- fader
              mouse.last_stored_send_t = data.send_t 
            end
            if mouse.last_obj == obj.b.pan_knob.mouse_id  and mouse.LMB_state then 
              local new_val_fader = mouse.last_obj_value  - mouse.dy/data.knob_mouse_resolution            
              if data.link == 1 then
                local diff = new_val_fader - mouse.last_obj_value            
                if diff ~= 0 and diff < 1 and new_val_fader ~= 0  then
                  diff_coeff = diff   / F_limit(mouse.last_obj_value,0.00001, 6)
                  data.send_t[data.cur_send_id].pan = F_limit(new_val_fader*2-1,-1,1)
                  for send_i = 1, #data.send_t do
                    if send_i ~= data.cur_send_id then   
                      old_val_fader = (mouse.last_stored_send_t[send_i].pan+1)/2 -- fader
                      new_val_fader1 = F_limit(old_val_fader * (1 + diff_coeff),0,1)
                      data.send_t[send_i].pan = new_val_fader1*2-1
                    end
                  end
                end                  
               else
                data.send_t[data.cur_send_id].pan = F_limit(new_val_fader*2-1,-1,1)
              end
              ENGINE_app_data()
            end  
        end
      end 
         
    -- mute 
      if MOUSE_button(obj.b.mute) then 
        data.send_t[data.cur_send_id].mute = math.abs(data.send_t[data.cur_send_id].mute-1)
        ENGINE_app_data()
      end
      
    --  phase
      if MOUSE_button(obj.b.phase) then 
        if data.link == 1 then
          local new_phase_state = math.abs(data.send_t[data.cur_send_id].phase-1)          
          for send_i = 1, #data.send_t do
            data.send_t[send_i].phase = new_phase_state
          end
         else
          data.send_t[data.cur_send_id].phase = math.abs(data.send_t[data.cur_send_id].phase-1)
        end
        ENGINE_app_data()
      end    
    
    --  mono
      if MOUSE_button(obj.b.mono) then 
        if data.link == 1 then
          local new_mono_state = math.abs(data.send_t[data.cur_send_id].mono-1)          
          for send_i = 1, #data.send_t do
            data.send_t[send_i].mono = new_mono_state
          end
         else
          data.send_t[data.cur_send_id].mono = math.abs(data.send_t[data.cur_send_id].mono-1)
        end
        ENGINE_app_data()
      end 
    
    -- send mode
      if MOUSE_button(obj.b.send_mode) then
        local cur_val = data.send_t[data.cur_send_id].send_mode
        
        --[[if cur_val == 3 then cur_val = 2 end
        local ret = GUI_menu( {'Post-Fader (PostPan)', 
                              'Pre-FX', 
                              'Pre-fader (PostFX)'}, cur_val ) 
        if ret == 2 then ret = 3 end
        if ret >= 0 then]]
          cur_val = cur_val + 1 
          if cur_val == 2 then 
            cur_val = 3 
           elseif cur_val == 4 then cur_val = 0
          end
          
          if data.link == 1 then
            for send_i = 1, #data.send_t do data.send_t[send_i].send_mode = cur_val end
           else
            data.send_t[data.cur_send_id].send_mode = cur_val
          end
          ENGINE_app_data()
        --end
      end
      
    -- FX
      if MOUSE_button(obj.b.fx) then
        local dest_tr = reaper.BR_GetMediaTrackByGUID( 0, data.send_t[data.cur_send_id].dest_GUID)
        local fxcnt = reaper.TrackFX_GetCount( dest_tr )
        for fx_id = 1, fxcnt do
          local _, fx_name = reaper.TrackFX_GetFXName( dest_tr, fx_id-1, '')
          if fx_name ~= 'PreEQ' and fx_name ~= 'PostEQ' then
            fx_ex = true
            --reaper.TrackFX_SetOpen( dest_tr, fx_id-1, true )
            reaper.TrackFX_Show( dest_tr, fx_id-1, 3 )
            break
          end
        end
        if not fx_ex then reaper.TrackFX_Show( dest_tr, 0,1 ) end
      end
    -- FX context 
      if MOUSE_button(obj.b.fx, 0, true) then
        local dest_tr = reaper.BR_GetMediaTrackByGUID( 0, data.send_t[data.cur_send_id].dest_GUID)
        local fxcnt = reaper.TrackFX_GetCount( dest_tr )
        t = {}
        if fxcnt > 0 then
          for fx_id = 1, fxcnt do
            local _, fx_name = reaper.TrackFX_GetFXName( dest_tr, fx_id-1, '')
            if fx_name ~= 'PreEQ' and fx_name ~= 'PostEQ' then
              t[#t+1] = {fx_name = fx_name, fx_id = fx_id}
            end
          end
        end
        t_menu = {} for i = 1, #t do t_menu[#t_menu+1] =  t[i].fx_name end
        local ret = GUI_menu(t_menu, -1 )
        if ret >=0 then reaper.TrackFX_Show( dest_tr, ret,3 ) end          
      end
      
    -- Link
      if MOUSE_button(obj.b.link) then
        data.link = math.abs(data.link -1)
        update_gfx = true
      end
      
    -- remote
      if MOUSE_button(obj.b.remote) then
        data.remote = math.abs(data.remote -1)
        update_gfx = true
      end
          
    -- wheel next/prev send
      if MOUSE_match(obj.b.params_area) or MOUSE_match(obj.b.tr_send_name) then
        if mouse.wheel_trig > 0 then 
          local cur_send = data.cur_send_id
          cur_send = cur_send + 1 
          if cur_send > #data.send_t then cur_send = 1 end
          data.cur_send_id = cur_send
         elseif
          mouse.wheel_trig < 0 then 
          local cur_send = data.cur_send_id
          cur_send = cur_send - 1 
          if cur_send <1 then cur_send = #data.send_t end
          data.cur_send_id = cur_send
        end          
        ENGINE_app_data()
      end
    
    -- remove
      if MOUSE_button(obj.b.remove  )   then
        reaper.RemoveTrackSend( data.track_pointer, 0, data.cur_send_id-1 )
        update_gfx = true
      end
      
    -- show mixer
      if MOUSE_button(obj.b.mixer  ) then
        data.show_mixer = math.abs(1-data.show_mixer)
        GUI_init_gfx()
      end
    -- info
      if MOUSE_button({x=0,y=0,w = gfx.w, h = obj.global_y_shift})then
        F_open_URL('http://forum.cockos.com/showthread.php?p=1793588') 
      end
    -- reset mouse context/doundo
      if mouse.last_LMB_state and not mouse.LMB_state then 
        mouse.last_obj = 0 
        mouse.last_obj_val = nil
        mouse.last_stored_send_t = nil
        mouse.dx = 0
        mouse.dy = 0
      end      
    -- mouse release
      mouse.last_LMB_state = mouse.LMB_state  
      mouse.last_RMB_state = mouse.RMB_state
      mouse.last_MMB_state = mouse.MMB_state 
      mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
      mouse.last_Ctrl_state = mouse.Ctrl_state
      mouse.last_Alt_state = mouse.Alt_state
      mouse.last_wheel = mouse.wheel 
      mouse.last_mx = mouse.mx
      mouse.last_my = mouse.my
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
  function ENGINE_app_data()
    if data.send_t and data.track_pointer then
      for i = 1, #data.send_t do
        local vol = data.send_t[i].vol
        if vol < 0.0001 then vol = 0 end
        reaper.SetTrackSendInfo_Value( data.track_pointer, 0, i-1, 'D_PAN', math.floor(data.send_t[i].pan*100)/100 ) 
        reaper.SetTrackSendInfo_Value( data.track_pointer, 0, i-1, 'D_VOL', vol )
        reaper.SetTrackSendInfo_Value( data.track_pointer, 0, i-1, 'B_MUTE', data.send_t[i].mute ) 
        reaper.SetTrackSendInfo_Value( data.track_pointer, 0, i-1, 'B_PHASE', data.send_t[i].phase )
        reaper.SetTrackSendInfo_Value( data.track_pointer, 0, i-1, 'B_MONO', data.send_t[i].mono ) 
        reaper.SetTrackSendInfo_Value( data.track_pointer, 0, i-1, 'I_SENDMODE', data.send_t[i].send_mode )       
        local trackid = reaper.CSurf_TrackToID( data.track_pointer, false )
        reaper.CSurf_OnSendVolumeChange( data.track_pointer, i-1, vol, false )
      end
      update_gfx = true
      reaper.UpdateArrange()
    end
  end
  -----------------------------------------------------------------------    
  function F_Get_SSV(s)
    if not s then return end
    local t = {}
    for i in s:gmatch("[%d%.]+") do t[#t+1] = tonumber(i) / 255 end
    gfx.r, gfx.g, gfx.b = t[1], t[2], t[3]
    return t[1], t[2], t[3]
  end  
  -----------------------------------------------------------------------  
  function GUI_menu(t, check) local name
    local str = ''
    for i = 1, #t do 
      name = t[i]
      if check == i-1 then
        str = str..'!'..name ..'|'
       else
        str = str..name ..'|'
      end
    end
    gfx.x, gfx.y = mouse.mx,mouse.my
    ret = gfx.showmenu(str) - 1
    if ret >= 0 then return ret else return -1 end
  end  
 ----------------------------------------------------------------------- 
  function F_limit(val,min,max)
      if val == nil or min == nil or max == nil then return end
      local val_out = val
      if val < min then val_out = min end
      if val > max then val_out = max end
      return val_out
    end   
  --------------------------------------------------------------------          
  function Run()  
    clock = os.clock ()
    -- save xy state 
      is_docked, wind_x,wind_y = gfx.dock(-1,0,0,0,0)
      wind_w, wind_h = gfx.w, gfx.h
      if 
        not last_wind_x 
        or not last_wind_y 
        or not last_wind_w 
        or not last_wind_h 
        or not last_is_docked
        or last_wind_x~=wind_x 
        or last_wind_y~=wind_y 
        or last_wind_w~=wind_w
        or last_wind_h~=wind_h 
        or last_is_docked ~= is_docked
         then
        reaper.SetExtState( 'mpl SendFader', 'x_pos', math.floor(wind_x), true )
        reaper.SetExtState( 'mpl SendFader', 'y_pos', math.floor(wind_y), true )
        reaper.SetExtState( 'mpl SendFader', 'wind_w', math.floor(wind_w), true )
        reaper.SetExtState( 'mpl SendFader', 'wind_h', math.floor(wind_h), true )
        reaper.SetExtState( 'mpl SendFader', 'is_docked', math.floor(is_docked), true )
        DEFINE_Objects()
        update_gfx = true
      end
      
      last_wind_x = wind_x
      last_wind_y = wind_y
      last_wind_w = wind_w
      last_wind_h = wind_h
      last_is_docked = is_docked
      
    -- upd gfx
      check_cnt =  reaper.GetProjectStateChangeCount( 0 )
      if not last_check_cnt or last_check_cnt ~= check_cnt then update_gfx = true end
      last_check_cnt = check_cnt
    
    -- upd gfx reduced 
      if not defer_cnt then defer_cnt =0 end
      defer_cnt = defer_cnt + 1
      if defer_cnt == 3 then defer_cnt = 0 update_gfx2 = true end
    
    MOUSE_get()
    DEFINE_data()    
    GUI_draw()
    local char = gfx.getchar() 
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end
    if char == 27 then gfx.quit() end     
    if char ~= -1 then reaper.defer(Run) else gfx.quit() end    
  end 
  --------------------------------------------------------------------     
  function GUI_init_gfx()
    local obj = DEFINE_Objects()
    if data.show_mixer == 0 then
      data.wind_h = data.wind_h0 -obj.b.params_area.h 
     else
      data.wind_h = data.wind_h0
    end
    local mouse_x, mouse_y = reaper.GetMousePosition()
    local x_pos = reaper.GetExtState( 'mpl SendFader', 'x_pos' )
    local y_pos = reaper.GetExtState( 'mpl SendFader', 'y_pos' )
    local w = reaper.GetExtState( 'mpl SendFader', 'wind_w' )
    local h = reaper.GetExtState( 'mpl SendFader', 'wind_h' )
    local is_docked = reaper.GetExtState( 'mpl SendFader', 'is_docked' )
    if tonumber(w) then 
      data.wind_w = w
      data.wind_h = h
    end
    gfx.quit()
    if x_pos and x_pos ~= '' then 
      gfx.init('', data.wind_w, data.wind_h, is_docked, x_pos, y_pos)
     else
      gfx.init('', data.wind_w, data.wind_h, is_docked)--mouse_x, mouse_y)    
    end
    DEFINE_Objects()
    update_gfx = true
    update_gfx2 = true
    update_gfx_onstart = true
  end
  --------------------------------------------------------------------   
  function EXT_load()
    --[[ reset
      reaper.SetExtState( 'mpl SendFader', 'currentID', '', true )
      reaper.SetExtState( 'mpl SendFader', 'srcTrack_GUID', '', true )]]
    local ext_id = reaper.GetExtState( 'mpl SendFader', 'currentID' )
    if ext_id then
      ext_id = tonumber(ext_id)
      if ext_id and ext_id > 0 then  data.ext_cur_send_id =ext_id  end
    end

    local ext_guid = reaper.GetExtState( 'mpl SendFader', 'srcTrack_GUID' )
    if ext_guid and ext_guid ~='' then data.ext_srctrGUID =ext_guid end
  end 
  ------------------------------------------------------------------    
  function Data_LoadSection(def_data, data, ext_name, config_path)
      for key in pairs(def_data) do
        local _, stringOut = reaper.BR_Win32_GetPrivateProfileString( ext_name, key, def_data[key], config_path )
        if stringOut ~= ''  then
          if tonumber(stringOut) then stringOut = tonumber(stringOut) end
          data[key] = stringOut
          --data[key] = def_data[key] -- FOR RESET DEBUG
          reaper.BR_Win32_WritePrivateProfileString( ext_name, key, data[key], config_path )
         else 
          data[key] = def_data[key]
          reaper.BR_Win32_WritePrivateProfileString( ext_name, key, def_data[key], config_path )
        end
      end
  end 
  --------------------------------------------------------------------   
  function Data_InitContent()
    return
[[
// configuration for MPL SendFader

[Info]

// Please edit global variables only if you sure what you doing
// You can get values meaning from script itself (below ReaPack header)
[Global_variables]
]]
  end  
  --------------------------------------------------------------------     
  function Data_LoadConfig()
    local def_data = Data_defaults()
    
    -- get config path
      local config_path = debug.getinfo(2, "S").source:sub(2):sub(0,-5)..'_config.ini' 
      
    -- check default file
      file = io.open(config_path, 'r')
      if not file then
        file = io.open(config_path, 'w')
        def_content = Data_InitContent()
        file:write(def_content)
        file.close()
      end
      file:close()
      
    -- Load data section
      Data_LoadSection(def_data, data, 'Global_variables', config_path)
  end
  ------------------------------------------------------------------ 
  function Data_Update()
    local def_data = Data_defaults()
    local config_path = debug.getinfo(2, "S").source:sub(2):sub(0,-5)..'_config.ini' 
    local d_state, win_pos_x,win_pos_y = gfx.dock(-1,0,0)
    data.window_x, data.window_y, data.window_w, data.window_h, data.d_state = win_pos_x,win_pos_y, gfx.w, gfx.h, d_state
    for key in pairs(def_data) do 
      if type(data[key])~= 'table' 
        then 
        reaper.BR_Win32_WritePrivateProfileString( 'Global_variables', key, data[key], config_path )  
      end 
    end
    reaper.BR_Win32_WritePrivateProfileString( 'Info', 'vrs', vrs, config_path )  
  end  
  --------------------------------------------------------------------     
  --  internal defaults
  --  1.13+ Don`t edit values here, edit configuration instead (see script path with mpl_SendFader_config.ini)
  
  function Data_defaults()
    local data_default = {
          fader_coeff = 50, -- scale warp
          fader_scale_lim = 0.8, -- zero height 
          pan_active_page = 1, -- 1: pan, 2: pre/postEQ
          link = 0, -- 0: off , 1: on
          wind_w = 150, -- default GUI width
          wind_h0 = 450, -- default GUI height
          knob_mouse_resolution = 150,
          fader_mouse_resolution = 300,
          show_mixer = 0, -- 0: off , 1: on
          small_man = 0, -- 0: small manual , 1: full width fader
          enable_follow_track_selection = 1, -- 0: track selected/store by click on track name area , 1: on
          remote = 0, -- 0: disable , 1: enable
          incr_vol_wheel = 0.02,  -- wheel resolution for volume fader
          incr_pan_wheel = 0.02   -- wheel resolution for pan knob
          }
    return data_default
  end
  --------------------------------------------------------------------     
  EXT_load()
  mouse = {}
  f_run = true
  data = {}
  Data_LoadConfig()
  Data_Update()
  GUI_init_gfx()
  Run()  
