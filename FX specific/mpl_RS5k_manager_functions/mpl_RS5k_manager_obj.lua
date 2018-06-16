-- @description RS5k_manager_GUI
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  
  
  ---------------------------------------------------
  function OBJ_init(obj)  
    -- size
    obj.reapervrs = tonumber(GetAppVersion():match('[%d%.]+')) 
    obj.offs = 5 
    obj.grad_sz = 200 
    obj.tab_h = 30    
    obj.splbrowse_up = 20 -- pat controls, smaple name
    obj.splbrowse_curfold = 20 -- current pat
    obj.splbrowse_listit = 15 -- also pattern item
    
    obj.item_h = 20   -- splbrowsp    
    obj.item_h2 = 20  -- list header
    obj.item_h3 = 15  -- list items
    obj.item_h4 = 40  -- steseq
    obj.item_w1 = 120 -- steseq name
    obj.scroll_w = 15
    obj.comm_w = 80 -- commit button
    obj.comm_h = 30
    obj.key_h = 250-- keys y/h  
 
    obj.kn_w =42
    obj.kn_h =56  
    obj.WF_h=obj.kn_h 
    obj.samplename_h = 20   
    obj.keycntrlarea_w = 20
    obj.WF_w=gfx.w- obj.keycntrlarea_w  
    obj.fx_rect_side = 15
    
    -- alpha
    obj.it_alpha = 0.45 -- under tab
    obj.it_alpha2 = 0.28 -- navigation
    obj.it_alpha3 = 0.1 -- option tabs
    obj.it_alpha4 = 0.05 -- option items
    obj.it_alpha5 = 0.05-- oct lowhigh
    obj.GUI_a1 = 0.2 -- pat not sel
    obj.GUI_a2 = 0.45 -- pat sel
       
    
    -- font
    obj.GUI_font = 'Calibri'
    obj.GUI_fontsz = 20  -- tab
    obj.GUI_fontsz2 = 15 -- WF back spl name
    obj.GUI_fontsz3 = 13-- spl ctrl
    if GetOS():find("OSX") then 
      obj.GUI_fontsz = obj.GUI_fontsz - 6 
      obj.GUI_fontsz2 = obj.GUI_fontsz2 - 5 
      obj.GUI_fontsz3 = obj.GUI_fontsz3 - 4
    end 
    
    -- colors    
    obj.GUIcol = { grey =    {0.5, 0.5,  0.5 },
                   white =   {1,   1,    1   },
                   red =     {1,   0,    0   },
                   green =   {0.3,   0.9,    0.3   },
                   black =   {0,0,0 }
                   }    
    
    -- other
  end
  ---------------------------------------------------
  function HasWindXYWHChanged(obj)
    local  _, wx,wy,ww,wh = gfx.dock(-1, 0,0,0,0)
    local retval=0
    if wx ~= obj.last_gfxx or wy ~= obj.last_gfxy then retval= 2 end --- minor
    if ww ~= obj.last_gfxw or wh ~= obj.last_gfxh then retval= 1 end --- major
    if not obj.last_gfxx then retval = -1 end
    obj.last_gfxx, obj.last_gfxy, obj.last_gfxw, obj.last_gfxh = wx,wy,ww,wh
    return retval
  end
  ---------------------------------------------------
  function OBJ_GenKeys_splCtrl(conf, obj, data, refresh, mouse, pat)
  
  -- todo
  -- global ctrls [p=1993032]
  -- MIDI controlled globals [p=1993032]
    
    local env_x_shift = 30
    local knob_back = 0
    local knob_y = 0
    local wheel_ratio = 12000
    local wheel_ratio_log = 12000
    local cur_note = obj.current_WFkey
    local cur_spl = 1
    if conf.allow_multiple_spls_per_pad == 1 then 
      cur_spl = obj.current_WFspl
    end
    
    local file_name
    if not (cur_note and data[cur_note] and data[cur_note][cur_spl]) then 
      file_name = '< Drag`n`drop samples to pads >' 
     else
      file_name = data[cur_note][cur_spl].sample
      if conf.allow_multiple_spls_per_pad == 1 then 
        file_name = '('..cur_spl..' of '..#data[cur_note]..') '..file_name..' >'
      end
    end
      local cond_reduce = 0
      if conf.allow_multiple_spls_per_pad == 1 then cond_reduce = obj.fx_rect_side*4 end -- fx, M
      obj.spl_WF_filename = { clear = true,
              x = obj.keycntrlarea_w  ,
              y = obj.kn_h,--gfx.h - obj.WF_h-obj.key_h,
              w = gfx.w -obj.keycntrlarea_w-cond_reduce,
              h = obj.samplename_h,
              col = 'white',
              state = 0,
              txt= file_name,
              aligh_txt = 0,
              show = true,
              is_but = true,
              fontsz = obj.GUI_fontsz2,
              alpha_back =0,
              func =  function()
                        if conf.allow_multiple_spls_per_pad == 1 then
                          local t = {}
                          for i = 1, #data[cur_note] do
                            t[#t+1] = {str = data[cur_note][i].sample,
                                        func = function() obj.current_WFspl = i end,
                                        state = i == obj.current_WFspl }
                          end
                          Menu(mouse, t)
                          data.current_spl_peaks = nil
                          refresh.GUI_WF = true 
                          refresh.GUI = true
                          refresh.data = true
                        end
                      end}  
                      
    if not (cur_note and cur_spl and data[cur_note] and data[cur_note][cur_spl]) then return end            

      ----FX----------------
              if conf.allow_multiple_spls_per_pad == 1 then 
                local  alpha_back = 0.01
                if data[cur_note] 
                  and data[cur_note][cur_spl] 
                  and data[cur_note][cur_spl].src_track ~= data.parent_track then
                  alpha_back = 0.4 
                end
                obj['keys_pFXlayer'] = { clear = true,
                      x = gfx.w - obj.fx_rect_side*2,-- - obj.offs,
                      y = obj.kn_h,--+obj.offs,
                      w = obj.fx_rect_side,
                      h = obj.fx_rect_side,
                      col = 'white',
                      txt= 'FX',
                      --aligh_txt = 16,
                      show = true,
                      is_but = true,
                      fontsz = obj.GUI_fontsz3-2,
                      alpha_back =alpha_back,
                      func =  function() 
                                  ShowRS5kChain(data, conf, cur_note, cur_spl)
                                  refresh.GUI = true
                                  refresh.data = true
                                end}
             
             
      ----mute----------------
                local  alpha_back = 0.01
                if data[cur_note] and data[cur_note][cur_spl] and data[cur_note][cur_spl].bypass_state == false then alpha_back = 0.4 end
                
                obj['keys_pMutelayer'] = { clear = true,
                      x = gfx.w - obj.fx_rect_side*3,-- - obj.offs,
                      y = obj.kn_h,--+obj.offs,
                      w = obj.fx_rect_side,
                      h = obj.fx_rect_side,
                      col = 'red',
                      txt= 'M',
                      --aligh_txt = 16,
                      show = true,
                      is_but = true,
                      fontsz = obj.GUI_fontsz3-2,
                      alpha_back =alpha_back,
                      func =  function() 
                                  data[cur_note][cur_spl].bypass_state = not data[cur_note][cur_spl].bypass_state
                                  SetRS5kData(data, conf, data[cur_note][1].src_track, cur_note, cur_spl)
                                  refresh.GUI = true
                                  refresh.data = true
                                end}
          
            -- solo        
               
                local  alpha_back = 0.01
                if data[cur_note][cur_spl].solo_state then alpha_back = 0.4 end
                obj['keys_pSololayer'] = { clear = true,
                      x = gfx.w - obj.fx_rect_side*4,
                      y = obj.kn_h,--+obj.offs,
                      w = obj.fx_rect_side,
                      h = obj.fx_rect_side,
                      col = 'green',
                      state = 0,
                      txt= 'S',
                      --aligh_txt = 16,
                      show = true,
                      is_but = true,
                      fontsz = obj.GUI_fontsz3-2,
                      alpha_back =alpha_back,
                      func =  function() 
                                  local solo_state = data[cur_note][cur_spl].solo_state == true
                                  for id_spl = 1, #data[cur_note] do
                                    if id_spl == cur_spl then
                                      data[cur_note][id_spl].bypass_state = true
                                     else
                                      data[cur_note][id_spl].bypass_state =  solo_state
                                    end
                                    SetRS5kData(data, conf, data[cur_note][id_spl].src_track, cur_note, id_spl)
                                  end
                                  refresh.GUI = true
                                  refresh.data = true
                                end}
             end -- layer mode
             
             
             
      -- knobs
      --if not (gfx.h - obj.WF_h-obj.key_h > obj.kn_h + obj.offs * 2) then return end
        ---------- gain ----------
        local gain_val = data[cur_note][cur_spl].gain / 2
        local gain_txt
        if (mouse.context_latch and mouse.context_latch == 'splctrl_gain') 
          --or (mouse.context and mouse.context =='splctrl_gain') 
          then 
          gain_txt  = data[cur_note][cur_spl].gain_dB..'dB'   
         else   
          gain_txt = 'Gain'    
        end
        obj.splctrl_gain = { clear = true,
              x = obj.keycntrlarea_w   + obj.offs,
              y = knob_y,
              w = obj.kn_w,
              h = obj.kn_h,
              col = 'white',
              state = 0,
              txt= gain_txt,
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              val = gain_val,
              fontsz = obj.GUI_fontsz3,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].gain 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/200, 0, 2)
                          if not out_val then return end
                          data[cur_note][cur_spl].gain  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.data = true 
                          refresh.GUI = true 
                        end,
              func_wheel = function()
                          local out_val = lim(data[cur_note][cur_spl].gain  + mouse.wheel_trig/wheel_ratio, 0, 2)
                          if not out_val then return end
                          data[cur_note][cur_spl].gain  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
                        
              func_DC = function ()
                          data[cur_note][cur_spl].gain  = 0.5
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }
        ---------- pan ----------                          
        local pan_val = data[cur_note][cur_spl].pan 
        local pan_txt
        if (mouse.context_latch and mouse.context_latch == 'splctrl_pan') 
          --or (mouse.context and mouse.context == 'splctrl_pan')
          then 
          pan_txt  = math.floor((-0.5+data[cur_note][cur_spl].pan)*200)
          if pan_txt < 0 then pan_txt = math.abs(pan_txt)..'%L' elseif pan_txt > 0 then pan_txt = math.abs(pan_txt)..'%R' else pan_txt = 'center' end
         else   pan_txt = 'Pan'    
        end                          
        obj.splctrl_pan = { clear = true,
              x = obj.keycntrlarea_w   + obj.offs + obj.kn_w,
              y = knob_y,
              w = obj.kn_w,
              h = obj.kn_h,
              col = 'white',
              state = 0,
              txt= pan_txt,
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              is_centered_knob = true,
              val = pan_val,
              fontsz = obj.GUI_fontsz3,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].pan 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/200, 0, 1)
                          if not out_val then return end
                          data[cur_note][cur_spl].pan  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)  
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
              func_wheel = function()
                          local out_val = lim(data[cur_note][cur_spl].pan  + mouse.wheel_trig/wheel_ratio, 0, 2)
                          if not out_val then return end
                          data[cur_note][cur_spl].pan  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end,                          
              func_DC = function () 
                          data[cur_note][cur_spl].pan  = 0.5
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end}        
        ---------- ptch ----------                          
        local pitch_val = data[cur_note][cur_spl].pitch_offset 
        local pitch_txt
        if    (mouse.context_latch and (mouse.context_latch == 'splctrl_pitch1' or mouse.context_latch == 'splctrl_pitch2')) 
          --or  (mouse.context       and (mouse.context       == 'splctrl_pitch1' or mouse.context       == 'splctrl_pitch2')) 
          then 
          pitch_txt  = data[cur_note][cur_spl].pitch_semitones else   pitch_txt = 'Pitch'    
        end                          
        obj.splctrl_pitch1 = { clear = true,
              x = obj.keycntrlarea_w   + obj.offs + obj.kn_w*2,
              y = knob_y,
              w = obj.kn_w,
              h = obj.kn_h,
              col = 'white',
              state = 0,
              txt= pitch_txt,
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              is_centered_knob = true,
              val = pitch_val,
              fontsz = obj.GUI_fontsz3,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].pitch_offset 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/400, 0, 1)*160
                          local int, fract = math.modf(mouse.context_latch_val*160 )
                          local out_val = lim(mouse.context_latch_val - mouse.dy/400, 0, 1)
                          if not out_val then return end
                          out_val = (math_q(out_val*160)+fract)/160
                          data[cur_note][cur_spl].pitch_offset  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)   
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
              func_wheel = function()
                          local out_val = lim(data[cur_note][cur_spl].pitch_offset  + mouse.wheel_trig/wheel_ratio, 0, 2)
                          if not out_val then return end
                          data[cur_note][cur_spl].pitch_offset  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)   
                          refresh.GUI = true 
                          refresh.data = true 
                        end,                           
              func_DC = function () 
                          data[cur_note][cur_spl].pitch_offset  = 0.5
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)   
                          refresh.GUI = true 
                          refresh.data = true 
                        end}  
      local int,fract =  math.modf(pitch_val*160-80 ) if not fract then fract = 0 end
      local pitch_val = fract
      obj.splctrl_pitch2 = { clear = true,
              x = obj.keycntrlarea_w   + obj.offs + obj.kn_w*2.25,
              y = knob_y+obj.kn_w/2,
              w = obj.kn_w/2,
              h = obj.kn_h/2,
              col = 'white',
              state = 0,
              txt= '',
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              --is_centered_knob = true,
              knob_a = 0,
              knob_as_point = true,
              val = pitch_val,
              fontsz = obj.GUI_fontsz3,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].pitch_offset 
                      end,
                       
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/100000, 0, 1)
                          if not out_val then return end
                          data[cur_note][cur_spl].pitch_offset  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)  
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
              func_DC = function () 
                          data[cur_note][cur_spl].pitch_offset  = 0.5
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)   
                          refresh.GUI = true 
                          refresh.data = true 
                        end                        }   
        ---------- attack ----------  
        local att_txt
        if mouse.context_latch and mouse.context_latch == 'splctrl_att' then 
          att_txt  = data[cur_note][cur_spl].attack_ms..'ms'   
         else   
          att_txt = 'A'    
        end
        obj.splctrl_att = { clear = true,
              x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*3 + env_x_shift,
              y = knob_y,
              w = obj.kn_w,
              h = obj.kn_h,
              col = 'white',
              state = 0,
              txt= att_txt,
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              val = data[cur_note][cur_spl].attack^0.1666,
              fontsz = obj.GUI_fontsz3,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].attack 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val^0.1666 - mouse.dy/300, 0, 1)
                          if not out_val then return end
                          out_val = out_val^6
                          data[cur_note][cur_spl].attack  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
              func_wheel = function()
                          local out_val = lim(data[cur_note][cur_spl].attack^0.1666  + mouse.wheel_trig/wheel_ratio_log, 0, 2)
                          if not out_val then return end
                          out_val = out_val^6
                          data[cur_note][cur_spl].attack  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end,  
              func_DC = function ()
                          data[cur_note][cur_spl].attack  = 0
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }     
        ---------- decay ----------  
        local dec_txt
        if mouse.context_latch and mouse.context_latch == 'splctrl_dec' then 
          dec_txt  = data[cur_note][cur_spl].decay_ms..'ms'   
         else   
          dec_txt = 'D'    
        end
        obj.splctrl_dec = { clear = true,
              x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*4 + env_x_shift,
              y = knob_y,
              w = obj.kn_w,
              h = obj.kn_h,
              col = 'white',
              state = 0,
              txt= dec_txt,
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              val = data[cur_note][cur_spl].decay^0.1666,
              fontsz = obj.GUI_fontsz3,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].decay 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val^0.1666 - mouse.dy/1000, 0, 1)
                          if not out_val then return end
                          out_val = out_val^6
                          data[cur_note][cur_spl].decay  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true
                          refresh.data = true
                        end,
              func_wheel = function()
                          local out_val = lim(data[cur_note][cur_spl].decay^0.1666  + mouse.wheel_trig/wheel_ratio_log, 0, 2)
                          if not out_val then return end
                          out_val = out_val^6
                          data[cur_note][cur_spl].decay  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end,  
              func_DC = function ()
                          data[cur_note][cur_spl].decay  = 0.016
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)  
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }         
        ---------- sust ----------
        local sust_txt
        if mouse.context_latch and mouse.context_latch == 'splctrl_sust' then 
          sust_txt  = data[cur_note][cur_spl].sust_dB..'dB'   
         else   
          sust_txt = 'S'    
        end
        obj.splctrl_sust = { clear = true,
              x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*5 + env_x_shift,
              y = knob_y,
              w = obj.kn_w,
              h = obj.kn_h,
              col = 'white',
              state = 0,
              txt= sust_txt,
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              val = data[cur_note][cur_spl].sust/2,
              fontsz = obj.GUI_fontsz3,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].sust 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/200, 0, 2)
                          if not out_val then return end
                          data[cur_note][cur_spl].sust  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
              func_wheel = function()
                          local out_val = lim(data[cur_note][cur_spl].sust  + mouse.wheel_trig/wheel_ratio, 0, 2)
                          if not out_val then return end
                          data[cur_note][cur_spl].sust  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end,  
              func_DC = function ()
                          data[cur_note][cur_spl].sust  = 0.5
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }              
        ---------- release ----------  
        local rel_txt
        if mouse.context_latch and mouse.context_latch == 'splctrl_rel' then 
          rel_txt  = data[cur_note][cur_spl].rel_ms..'ms'   
         else   
          rel_txt = 'R'    
        end
        obj.splctrl_rel = { clear = true,
              x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*6 + env_x_shift,
              y = knob_y,
              w = obj.kn_w,
              h = obj.kn_h,
              col = 'white',
              state = 0,
              txt= rel_txt,
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              val = data[cur_note][cur_spl].rel^0.1666,
              fontsz = obj.GUI_fontsz3,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].rel 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val^0.1666 - mouse.dy/300, 0, 1)
                          if not out_val then return end
                          out_val = out_val^6
                          data[cur_note][cur_spl].rel  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
              func_wheel = function()
                          local out_val = lim(data[cur_note][cur_spl].rel^0.1666  + mouse.wheel_trig/wheel_ratio_log, 0, 2)
                          if not out_val then return end
                          out_val = out_val^6
                          data[cur_note][cur_spl].rel  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end, 
              func_DC = function ()
                          data[cur_note][cur_spl].rel  = 0.0004
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }        
        ---------- loop s ----------
        local loops_val = data[cur_note][cur_spl].offset_start
        local loops_val_txt
        if mouse.context_latch and mouse.context_latch == 'splctrl_loops' then 
          loops_val_txt  = math_q_dec(data[cur_note][cur_spl].offset_start, 3)
         else   
          loops_val_txt = 'LoopSt'    
        end              
        obj.splctrl_loops = { clear = true,
              x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*7 + env_x_shift*2,
              y = knob_y,
              w = obj.kn_w,
              h = obj.kn_h,
              col = 'white',
              state = 0,
              txt= loops_val_txt,
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              val = data[cur_note][cur_spl].offset_start,
              fontsz = obj.GUI_fontsz3,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].offset_start 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/2000, 0, 1)
                          if not out_val then return end
                          local diff = data[cur_note][cur_spl].offset_end - data[cur_note][cur_spl].offset_start
                          data[cur_note][cur_spl].offset_start  = out_val
                          data[cur_note][cur_spl].offset_end  = out_val+diff
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true
                          refresh.data = true 
                        end,
              func_wheel = function()
                          local out_val = lim(data[cur_note][cur_spl].offset_start  + mouse.wheel_trig/wheel_ratio, 0, 1)
                          if not out_val then return end
                          local diff = data[cur_note][cur_spl].offset_end - data[cur_note][cur_spl].offset_start
                          data[cur_note][cur_spl].offset_start  = out_val
                          data[cur_note][cur_spl].offset_end  = out_val+diff
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
                        
              func_DC = function ()
                          out_val = 0
                          local diff = data[cur_note][cur_spl].offset_end - data[cur_note][cur_spl].offset_start
                          data[cur_note][cur_spl].offset_start  = out_val
                          data[cur_note][cur_spl].offset_end  = out_val+diff
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              } 
        ---------- loop e ----------
        local loope_val = data[cur_note][cur_spl].offset_end
        local loope_val_txt
        if mouse.context_latch and mouse.context_latch == 'splctrl_loope' then 
          loope_val_txt  = math_q_dec(data[cur_note][cur_spl].offset_end, 3)
         else   
          loope_val_txt = 'LoopEnd'    
        end              
        obj.splctrl_loope = { clear = true,
              x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*8 + env_x_shift*2,
              y = knob_y,
              w = obj.kn_w,
              h = obj.kn_h,
              col = 'white',
              state = 0,
              txt= loope_val_txt,
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              val = data[cur_note][cur_spl].offset_end,
              fontsz = obj.GUI_fontsz3,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].offset_end 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/2000, 0, 1)
                          if not out_val then return end
                          out_val = lim(out_val,data[cur_note][cur_spl].offset_start,1)
                          data[cur_note][cur_spl].offset_end  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)
                          refresh.GUI = true
                          refresh.data = true 
                        end,
              func_wheel = function()
                          local out_val = lim(data[cur_note][cur_spl].offset_end  + mouse.wheel_trig/wheel_ratio, 0, 1)
                          if not out_val then return end
                          out_val = lim(out_val,data[cur_note][cur_spl].offset_start,1)
                          data[cur_note][cur_spl].offset_end  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
                        
              func_DC = function ()
                          data[cur_note][cur_spl].offset_end  = 1
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }                                                                                                                                                                                                   
  end

    ---------------------------------------------------
    function OBJ_GenKeys(conf, obj, data, refresh, mouse, pat)
      local shifts,w_div ,h_div
      if conf.keymode ==0 then 
        w_div = 7
        h_div = 2
        shifts  = {{0,1},
                  {0.5,0},
                  {1,1},
                  {1.5,0},
                  {2,1},
                  {3,1},
                  {3.5,0},
                  {4,1},
                  {4.5,0},
                  {5,1},
                  {5.5,0},
                  {6,1},
                }
      elseif conf.keymode ==1 then 
        w_div = 14
        h_div = 2
        shifts  = {{0,1},
                  {0.5,0},
                  {1,1},
                  {1.5,0},
                  {2,1},
                  {3,1},
                  {3.5,0},
                  {4,1},
                  {4.5,0},
                  {5,1},
                  {5.5,0},
                  {6,1},
                  {7,1},
                  {7.5,0},
                  {8,1},
                  {8.5,0},
                  {9,1},
                  {10,1},
                  {10.5,0},
                  {11,1},
                  {11.5,0},
                  {12,1},
                  {12.5,0},
                  {13,1}                 
                }                
       elseif conf.keymode == 2 then -- korg nano
        w_div = 8
        h_div = 2     
        shifts  = {{0,1},
                  {0,0},
                  {1,1},
                  {1,0},
                  {2,1},
                  {2,0},
                  {3,1},
                  {3,0},
                  {4,1},
                  {4,0},
                  {5,1},
                  {5,0},
                  {6,1},
                  {6,0},      
                  {7,1},
                  {7,0},                              
                }   
       elseif conf.keymode == 3 then -- live dr rack
        w_div = 4
        h_div = 4     
        shifts  = { {0,3},    
                    {1,3}, 
                    {2,3}, 
                    {3,3},
                    {0,2},    
                    {1,2}, 
                    {2,2}, 
                    {3,2},
                    {0,1},    
                    {1,1}, 
                    {2,1}, 
                    {3,1},
                    {0,0},    
                    {1,0}, 
                    {2,0}, 
                    {3,0}                                                               
                }      
       elseif conf.keymode == 4 then -- s1 impact
        w_div = 4
        h_div = 4 
        start_note_shift = -1    
        shifts  = { {0,3},    
                    {1,3}, 
                    {2,3}, 
                    {3,3},
                    {0,2},    
                    {1,2}, 
                    {2,2}, 
                    {3,2},
                    {0,1},    
                    {1,1}, 
                    {2,1}, 
                    {3,1},
                    {0,0},    
                    {1,0}, 
                    {2,0}, 
                    {3,0}                                                               
                }  
       elseif conf.keymode == 5 then -- ableton push
        w_div = 8
        h_div = 8  
        shifts  = { 
                    {0,7},    
                    {1,7}, 
                    {2,7}, 
                    {3,7},
                    {4,7},
                    {5,7},
                    {6,7},
                    {7,7},
                            
                    {0,6},    
                    {1,6}, 
                    {2,6}, 
                    {3,6},
                    {4,6},
                    {5,6},
                    {6,6},
                    {7,6},
                            
                    {0,5},    
                    {1,5}, 
                    {2,5}, 
                    {3,5},
                    {4,5},
                    {5,5},
                    {6,5},
                    {7,5},
                                               
                    {0,4},    
                    {1,4}, 
                    {2,4}, 
                    {3,4},
                    {4,4},
                    {5,4},
                    {6,4},
                    {7,4},
                    
                    {0,3},    
                    {1,3}, 
                    {2,3}, 
                    {3,3},
                    {4,3},
                    {5,3},
                    {6,3},
                    {7,3},
                    
                    {0,2},    
                    {1,2}, 
                    {2,2}, 
                    {3,2},
                    {4,2},    
                    {5,2}, 
                    {6,2}, 
                    {7,2},                    
                    
                    {0,1},    
                    {1,1}, 
                    {2,1}, 
                    {3,1},
                    {4,1},    
                    {5,1}, 
                    {6,1}, 
                    {7,1},                    
                    
                    {0,0},    
                    {1,0}, 
                    {2,0}, 
                    {3,0},
                    {4,0},    
                    {5,0}, 
                    {6,0}, 
                    {7,0},                                                                              
                }                                               
      end
      

      local key_area_h = gfx.h -obj.kn_h-obj.samplename_h
      local key_w = math.ceil((gfx.w-3*obj.offs-obj.keycntrlarea_w)/w_div)
      local key_h = math.ceil((1/h_div)*(key_area_h)) 
      obj.h_div = h_div
      for i = 1, #shifts do
        local id = i-1+conf.oct_shift*12
        local note = (i-1)+12*conf.oct_shift+conf.start_oct_shift*12
        --[[local fn, ret = GetSampleNameByNote(data, note)
        fn = ''
        if data[note] then
          for spl_id = 1, #data[note] do
            fn = fn..data[note][spl_id].sample..'\n'
          end
        end]]
        local col = 'white'
        local colint, colint0
        local alpha_back
        if  data[note] and data[note][1] then 
          alpha_back = 0.49        
          col = 'green'
          if data[note][1].src_track_col then colint = data[note][1].src_track_col  end    
         else
          alpha_back = 0.15 
        end
        local note_str = GetNoteStr(conf, note)
        
        if note_str then
          local txt = note_str..'\n\r'--..fn
          if data[note] and data[note][1] and data[note][1].MIDI_name and conf.key_names ~= 6 then txt = txt..data[note][1].MIDI_name end
          if  key_w < obj.fx_rect_side*2.5 or key_h < obj.fx_rect_side*2 then txt = note end
          if  key_w < obj.fx_rect_side*1.5 or key_h < obj.fx_rect_side*1.5 then txt = '' end
          if note >= 0 and note <= 127 then
            
            OBJ_GenKeys_PadButtons(conf, obj, data, refresh, mouse, key_w, key_h, note,shifts, i, key_area_h)
            -------------------------
            -- keys
            
            obj['keys_p'..i] = 
                      { clear = true,
                        x = obj.keycntrlarea_w+shifts[i][1]*key_w + obj.offs,
                        y = gfx.h-key_area_h+ shifts[i][2]*key_h,
                        w = key_w-1,
                        h = key_h,
                        col = col,
                        colint = colint,
                        state = 0,
                        txt= txt,
                        is_step = true,
                        --vertical_txt = fn,
                        linked_note = note,
                        show = true,
                        is_but = true,
                        alpha_back = alpha_back,
                        a_frame = 0.05,
                        aligh_txt = 5,
                        fontsz = obj.GUI_fontsz2,
                        func =  function() 
                                  data.current_spl_peaks = nil
                                  if conf.keypreview == 1 then  StuffMIDIMessage( 0, '0x9'..string.format("%x", 0), note,100) end                                  
                                  obj.current_WFkey = note
                                  obj.current_WFspl = 1
                                  refresh.GUI_WF = true  
                                  refresh.GUI = true     
                                end,
                        func_R =  function ()
                                    --[[Menu(mouse, {
                                                  { str = 'Remove current opened sample',
                                                    func =  function()
                                                              cur_spl = obj.current_WFspl
                                                              cur_spl = obj.current_WFspl
                                                              SNM_MoveOrRemoveTrackFX( data.parent_track, data[note][spl].rs5k_pos, 0 )
                                                            end
                                                  }
                                                
                                                
                                                })
                                    refresh.GUI_WF = true  
                                    refresh.GUI = true ]]                                   
                                  end
                                } 
            if    note%12 == 1 
              or  note%12 == 3 
              or  note%12 == 6 
              or  note%12 == 8 
              or  note%12 == 10 
              then obj['keys_p'..i].txt_col = 'black' end
              
              
          end
        end
      end
    
      
    end
    -------------------------------------------------------------
  function OBJ_GenKeys_PadButtons(conf, obj, data, refresh, mouse, key_w, key_h, note, shifts, i, key_area_h)
    if not data[note] or not data[note][1] then return end
            ------------ctrl butts
            -- FX  
            local y_shift_butts = -1          
            if key_h > obj.fx_rect_side and key_w > obj.fx_rect_side*3 then               
              if conf.FX_buttons&(1<<2) == (1<<2) and conf.allow_multiple_spls_per_pad == 0 then 
                y_shift_butts = y_shift_butts + 1
                local  alpha_back = 0.01
                if data[note] and data[note][1] and data[note][1].src_track ~= data.parent_track then alpha_back = 0.4 end
                obj['keys_pFX'..i] = { clear = true,
                      x = obj.keycntrlarea_w + shifts[i][1]*key_w + key_w - obj.fx_rect_side,-- - obj.offs,
                      y = gfx.h-key_area_h + shifts[i][2]*key_h + obj.fx_rect_side*y_shift_butts,--+obj.offs,
                      w = obj.fx_rect_side,
                      h = obj.fx_rect_side,
                      col = 'white',
                      txt= 'FX',
                      --aligh_txt = 16,
                      show = true,
                      is_but = true,
                      fontsz = obj.GUI_fontsz3-2,
                      alpha_back =alpha_back,
                      func =  function() 
                                  ShowRS5kChain(data, conf, note)
                                  refresh.GUI = true
                                  refresh.data = true
                                end}
              end
            end

            -- mute            
            if key_h > obj.fx_rect_side*2 and key_w > obj.fx_rect_side*3 then 
              if conf.FX_buttons&(1<<3) == (1<<3) then 
                y_shift_butts = y_shift_butts + 1
                local  alpha_back = 0.01
                if data[note] and data[note][1] and data[note][1].bypass_state == false then alpha_back = 0.4 end
                obj['keys_pMUTE'..i] = { clear = true,
                      x = obj.keycntrlarea_w + shifts[i][1]*key_w + key_w - obj.fx_rect_side,-- - obj.offs,
                      y = gfx.h-key_area_h + shifts[i][2]*key_h + obj.fx_rect_side*y_shift_butts,--+obj.offs,
                      w = obj.fx_rect_side,
                      h = obj.fx_rect_side,
                      col = 'red',
                      state = 0,
                      txt= 'M',
                      --aligh_txt = 16,
                      show = true,
                      is_but = true,
                      fontsz = obj.GUI_fontsz3-2,
                      alpha_back =alpha_back,
                      func =  function() 
                                  data[note][1].bypass_state = not data[note][1].bypass_state
                                  SetRS5kData(data, conf, data[note][1].src_track, note, 1)
                                  refresh.GUI = true
                                  refresh.data = true
                                end}
                  
              end
              
            -- solo            
            if key_h > obj.fx_rect_side*3 and key_w > obj.fx_rect_side*3 then 
              if conf.FX_buttons&(1<<4) == (1<<4) then 
                y_shift_butts = y_shift_butts + 1
                local  alpha_back = 0.01
                if data[note].solo_state then  alpha_back = 0.5 end
                obj['keys_pSolo'..i] = { clear = true,
                      x = obj.keycntrlarea_w + shifts[i][1]*key_w + key_w - obj.fx_rect_side,-- - obj.offs,
                      y = gfx.h-key_area_h + shifts[i][2]*key_h + obj.fx_rect_side*y_shift_butts,--+obj.offs,
                      w = obj.fx_rect_side,
                      h = obj.fx_rect_side,
                      col = 'green',
                      state = 0,
                      txt= 'S',
                      --aligh_txt = 16,
                      show = true,
                      is_but = true,
                      fontsz = obj.GUI_fontsz3-2,
                      alpha_back =alpha_back,
                      func =  function()                                 
                                  local solo_state = data[note].solo_state == true
                                  for id in pairs(data) do
                                    if id and type(id) == 'number' and data[id] and data[id][1] then
                                      if id == note then 
                                        data[id][1].bypass_state = true
                                       else
                                        data[id][1].bypass_state =  solo_state
                                      end
                                      SetRS5kData(data, conf, data[id][1].src_track, id, 1)
                                    end
                                  end
                                  refresh.GUI = true
                                  refresh.data = true
                                end}
                end
              end              
            end


                              
  end
  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse, pat) 
    for key in pairs(obj) do 
      if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
      local fx_per_pad if conf.allow_multiple_spls_per_pad == 1 then fx_per_pad = '#' else fx_per_pad = '' end
        obj.keys_octaveshiftL = { clear = true,
                    x = 0,
                    y = obj.kn_h+obj.samplename_h,
                    w = obj.keycntrlarea_w,
                    h = 0.5*(gfx.h -obj.kn_h-obj.samplename_h),
                    col = 'white',
                    state = fale,
                    txt= '+',
                    show = true,
                    is_but = true,
                    mouse_overlay = true,
                    fontsz = obj.GUI_fontsz,
                    alpha_back = obj.it_alpha5,
                    a_frame = 0,
                    func =  function() 
                              conf.start_oct_shift = lim(conf.start_oct_shift + 1,-conf.oct_shift-1,10-conf.oct_shift)
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.data = true
                            end} 
        obj.keys_octaveshiftR = { clear = true,
                    x = 0,
                    y = 0.5*(obj.kn_h+obj.samplename_h)+0.5*gfx.h,
                    w = obj.keycntrlarea_w,
                    h = 0.5*(gfx.h -obj.kn_h-obj.samplename_h),
                    col = 'white',
                    state = fale,
                    txt= '-',
                    show = true,
                    is_but = true,
                    mouse_overlay = true,
                    fontsz = obj.GUI_fontsz,
                    alpha_back = obj.it_alpha5,
                    a_frame = 0,
                    func =  function() 
                              conf.start_oct_shift = lim(conf.start_oct_shift - 1,-conf.oct_shift-1,10-conf.oct_shift)
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.data = true                           
                            end}  
                            
        obj.menu = { clear = true,
                    x = 0,
                    y = 0,
                    w = obj.keycntrlarea_w,
                    h = obj.kn_h+obj.samplename_h-1,
                    col = 'white',
                    state = fale,
                    txt= '>',
                    show = true,
                    is_but = true,
                    mouse_overlay = true,
                    fontsz = obj.GUI_fontsz,
                    alpha_back = obj.it_alpha5,
                    a_frame = 0,
                    func =  function() 
                              Menu(mouse,               
{
  { str = conf.scr_title..' '..conf.vrs,
    hidden = true
  },
  { str = '|#Links / Info'},
--[[  {str = 'Help',
   func = function()  
            ClearConsole()                 
            msg(
[ [This script maintain RS5k track data. ] ] )  
                 
                        end   
  }  ,                ]]
  { str = 'Donate to MPL',
    func = function() F_open_URL('http://www.paypal.me/donate2mpl') end }  ,
  { str = 'Cockos Forum thread|',
    func = function() F_open_URL('http://forum.cockos.com/showthread.php?t=188335') end  } , 
  { str = '#Options'},    
  { str = '>Key names'},
  
  { str = ({GetNoteStr(conf, 0, 8)})[2],
    state = conf.key_names == 8,
    func = function() conf.key_names = 8 end},
  { str = ({GetNoteStr(conf, 0,7)})[2],
    state = conf.key_names == 7,
    func = function() conf.key_names = 7 end},  
  { str = 'keys + octave',
    state = conf.key_names == 0,
    func = function() conf.key_names = 0 end},      
  { str = ({GetNoteStr(conf, 0,4)})[2],
    state = conf.key_names == 4,
    func = function() conf.key_names = 4 end},  
  { str = ({GetNoteStr(conf, 0,6)})[2]..'|<',
    state = conf.key_names == 6,
    func = function() conf.key_names = 6 end},          
  
  { str = '>Pad controls'},
  { str = fx_per_pad..'FX',  
    state = conf.FX_buttons&(1<<2) == (1<<2),
    func =  function() 
              local ret = BinaryCheck(conf.FX_buttons, 2)
              conf.FX_buttons = ret
            end ,
  },
  { str = 'Mute (bypass)',  
    state = conf.FX_buttons&(1<<3) == (1<<3),
    func =  function() 
              local ret = BinaryCheck(conf.FX_buttons, 3)
              conf.FX_buttons = ret
            end ,
  },
  { str = 'Solo (bypass all except current)|<',  
    state = conf.FX_buttons&(1<<4) == (1<<4),
    func =  function() 
              local ret = BinaryCheck(conf.FX_buttons, 4)
              conf.FX_buttons = ret
            end ,
  },
    
  { str = '>Layouts'},
  { str = 'Chromatic Keys',
    func = function() conf.keymode = 0 end ,
    state = conf.keymode == 0},
  { str = 'Chromatic Keys (2 oct)',
    func = function() conf.keymode = 1 end ,
    state = conf.keymode == 1},
  { str = 'Korg NanoPad (8x2)',
    func = function() conf.keymode = 2 end ,
    state = conf.keymode == 2},
  { str = 'Ableton Live Drum Rack (4x4)',
    func = function() conf.keymode = 3 end ,
    state = conf.keymode == 3},
  { str = 'Studio One Impact (4x4)',
    func = function() conf.keymode = 4 end ,
    state = conf.keymode == 4},
  { str = 'Ableton Push (8x8)|<',
    func = function() conf.keymode = 5 end ,
    state = conf.keymode == 5},  
      
  { str = '>Auto prepare selected track MIDI input on start'},   
  { str = 'Disabled',
    func = function() conf.prepareMIDI2 = 0  end ,
    state = conf.prepareMIDI2 == 0},    
  { str = 'Virtual keyboard',
    func = function() conf.prepareMIDI2 = 1  end ,
    state = conf.prepareMIDI2 == 1},                   
  { str = 'All inputs|<',
    func = function() conf.prepareMIDI2 = 2  end ,
    state = conf.prepareMIDI2 == 2},   
    
  { str = 'Send MIDI by clicking on keys',
    func = function() conf.keypreview = math.abs(1-conf.keypreview)  end ,
    state = conf.keypreview == 1}, 
  { str = 'Visual octave shift: '..conf.oct_shift..'oct',
    func = function() 
              ret = GetInput( conf, 'Visual octave shift', conf.oct_shift,true) 
              if ret then  conf.oct_shift = ret  end end,
  } ,
  { str = 'Allow multiple samples per pad (Layering mode)|',
    func = function() conf.allow_multiple_spls_per_pad = math.abs(1-conf.allow_multiple_spls_per_pad) end,
    state = conf.allow_multiple_spls_per_pad == 1, 
  } ,  
  
  { str = '#Actions'},  
  { str = 'Export selected items to RS5k instances',
    func =  function() 
              reaper.Undo_BeginBlock2( 0 )
              -- track check
                local track = reaper.GetSelectedTrack(0,0)
                if not track then return end        
              -- item check
                local item = reaper.GetSelectedMediaItem(0,0)
                if not item then return true end  
              -- get base pitch
                local ret, base_pitch = reaper.GetUserInputs( conf.scr_title, 1, 'Set base pitch', 60 )
                if not ret 
                  or not tonumber(base_pitch) 
                  or tonumber(base_pitch) < 0 
                  or tonumber(base_pitch) > 127 then
                  return 
                end
                base_pitch = math.floor(tonumber(base_pitch))      
              -- get info for new midi take
                local proceed_MIDI, MIDI = ExportSelItemsToRs5k_FormMIDItake_data()        
              -- export to RS5k
                for i = 1, CountSelectedMediaItems(0) do
                  local item = reaper.GetSelectedMediaItem(0,i-1)
                  local it_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
                  local take = reaper.GetActiveTake(item)
                  if not take or reaper.TakeIsMIDI(take) then goto skip_to_next_item end
                  local tk_src =  GetMediaItemTake_Source( take )
                  local s_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
                  local src_len =GetMediaSourceLength( tk_src )
                  local filepath = reaper.GetMediaSourceFileName( tk_src, '' )
                  msg(s_offs/src_len)
                  ExportItemToRS5K(data,conf,refresh,base_pitch + i-1,filepath, s_offs/src_len, (s_offs+it_len)/src_len)
                  ::skip_to_next_item::
                end
                
                reaper.Main_OnCommand(40006,0)--Item: Remove items      
              -- add MIDI
                if proceed_MIDI then ExportSelItemsToRs5k_AddMIDI(track, MIDI,base_pitch) end        
                reaper.Undo_EndBlock2( 0, 'Export selected items to RS5k instances', -1 )       
            end,
  } ,    
    
    
    



  { str = 'Dock MPL RS5k manager',
    func = function() 
              conf.dock2 = math.abs(1-conf.dock2) 
              gfx.quit() 
              gfx.init('MPL RS5k manager '..conf.vrs,
                        conf.wind_w, 
                        conf.wind_h, 
                        conf.dock2, conf.wind_x, conf.wind_y)
          end ,
    state = conf.dock2 == 1}, 
                                                                           
}
)
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.GUI_onStart = true
                              refresh.data = true
                            end}                            
                            
                            
                            
                            
    OBJ_GenKeys(conf, obj, data, refresh, mouse, pat)
    OBJ_GenKeys_splCtrl(conf, obj, data, refresh, mouse, pat)
    for key in pairs(obj) do if type(obj[key]) == 'table' then obj[key].context = key end end    
  end
