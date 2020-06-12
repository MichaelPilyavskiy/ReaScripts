-- @description RS5k_manager_GUI
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  
  
  ---------------------------------------------------
  function OBJ_init(obj)  
    -- size
    obj.window = 0 -- init from main wind
    obj.reapervrs = tonumber(GetAppVersion():match('[%d%.]+')) 
    obj.offs = 5 
    obj.grad_sz = 200 
    obj.tab_h = 30    
    obj.splbrowse_up = 20 -- pat controls, smaple name
    obj.splbrowse_curfold = 20 -- current pat
    obj.splbrowse_listit = 15 -- also pattern item
    obj.ctrl_ratio = 0.1
    obj.selector_w = 10
    obj.selector_h = 28
    
    
    obj.item_h = 20   -- splbrowsp    
    obj.item_h2 = 20  -- list header
    obj.item_h3 = 15  -- list items
    obj.item_h4 = 40  -- steseq
    obj.item_w1 = 120 -- steseq name
    obj.scroll_w = 15
    obj.comm_w = 80 -- commit button
    obj.comm_h = 30
    obj.key_h = 250-- keys y/h  
    obj.scroll_w = 15
    obj.scroll_val = 0
    obj.mixslot_w = 200
    obj.mixslot_h = 20
    
    obj.samplename_h = 20   
    obj.keycntrlarea_w = 25
    obj.WF_w=gfx.w- obj.keycntrlarea_w  
    obj.fx_rect_side = 15
    obj.sel_key_frame = 0.5
    
    -- alpha
    obj.it_alpha = 0.45 -- under tab
    obj.it_alpha2 = 0.28 -- navigation
    obj.it_alpha3 = 0.1 -- option tabs
    obj.it_alpha4 = 0.05 -- option items
    obj.it_alpha5 = 0.08-- but left
    obj.it_alpha6 = 0.4-- selected
    obj.GUI_a1 = 0.2 -- pat not sel
    obj.GUI_a2 = 0.45 -- pat sel
       
    
    -- font
    obj.GUI_font = 'Calibri'
    obj.GUI_fontsz = 20  -- tab
    obj.GUI_fontsz2 = 15 -- WF back spl name/FXslot
    obj.GUI_fontsz3 = 13-- spl ctrl
    obj.GUI_fontsz4 = 12-- spl ctrl
    if GetOS():find("OSX") then 
      obj.GUI_fontsz = obj.GUI_fontsz - 6 
      obj.GUI_fontsz2 = obj.GUI_fontsz2 - 5 
      obj.GUI_fontsz3 = obj.GUI_fontsz3 - 4
      obj.GUI_fontsz4 = obj.GUI_fontsz4 - 2
    end 
    
    -- colors    
    obj.GUIcol = { grey =    {0.5, 0.5,  0.5 },
                   white =   {1,   1,    1   },
                   red =     {1,   0,    0   },
                   blue =     {0,   0.5,    1   },
                   green =   {0.3,   0.9,    0.3   },
                   black =   {0,0,0 },
                   yellow =   {1,0.8,0.3 }
                   } 
  end  
  ---------------------------------------------------
  function OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl)
    local dragratio = 80
    local ctrl_ratio = 0.1
    local wheel_ratio = 12000
    return {  func =  function() 
                        local cur_spl0 = cur_spl
                        if cur_spl == -1 then cur_spl0 = 1 end
                        mouse.context_latch_val = data[cur_note][cur_spl0].gain 
                      end,
              --[[ondrag_LCAS = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/dragratio, 0, 2)
                          if not out_val then return end
                          
                          for cur_note in pairs(data) do
                            if tonumber(cur_note) then
                              for spl = 1, #data[cur_note] do
                                  data[cur_note][spl].gain  = out_val
                                  SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl) 
                                    if obj['mix_splctrl_gain'..cur_note] and conf.tab == 1 then 
                                      obj['mix_splctrl_gain'..cur_note].val = data[cur_note][1].gain / 2
                                      obj.info_line_mixer.txt =  
                                        cur_note..' '..data[cur_note][1].sample_short..' Gain '..
                                        ({TrackFX_GetFormattedParamValue( data[cur_note][1].tr_ptr, data[cur_note][1].rs5k_pos, 0, '' )})[2]..'dB'
                                      refresh.data = true 
                                      refresh.GUI_minor = true 
                                     else
                                      --refresh.data = true 
                                      --refresh.GUI_minor = true 
                                    end
                                  end
                                end                        
                              end
                        end,                                 
                                   ]] 
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/dragratio, 0, 2)
                          if not out_val then return end
                          
                          if cur_spl == -1 then 
                            for spl = 1, #data[cur_note] do
                              data[cur_note][spl].gain  = out_val
                              SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl) 
                                if obj['mix_splctrl_gain'..cur_note] and conf.tab == 1 then 
                                  obj['mix_splctrl_gain'..cur_note].val = data[cur_note][spl].gain / 2
                                  obj.info_line_mixer.txt =  
                                    cur_note..' '..data[cur_note][1].sample_short..' Gain '..
                                    ({TrackFX_GetFormattedParamValue( data[cur_note][1].tr_ptr, data[cur_note][1].rs5k_pos, 0, '' )})[2]..'dB'
                                  refresh.data = true 
                                  refresh.GUI_minor = true 
                                 else
                                  refresh.data = true 
                                  refresh.GUI = true 
                                end
                              end
                           else

                            data[cur_note][cur_spl].gain  = out_val
                            SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                              if obj['mix_splctrl_gain'..cur_note] and conf.tab == 1 then 
                                obj['mix_splctrl_gain'..cur_note].val = data[cur_note][cur_spl].gain / 2
                                obj.info_line_mixer.txt =  
                                  cur_note..' '..data[cur_note][cur_spl].sample_short..' Gain '..
                                  ({TrackFX_GetFormattedParamValue( data[cur_note][cur_spl].tr_ptr, data[cur_note][cur_spl].rs5k_pos, 0, '' )})[2]..'dB'
                                refresh.data = true 
                                refresh.GUI_minor = true 
                               else
                                refresh.data = true 
                                refresh.GUI = true 
                              end
                                                          
                          end
                        end,
              func_ctrlLD = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - ctrl_ratio*mouse.dy/dragratio, 0, 2)
                          if not out_val then return end
                          
                          if cur_spl == -1 then 
                            for spl = 1, #data[cur_note] do
                              data[cur_note][spl].gain  = out_val
                              SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl) 
                            end
                           else
                            data[cur_note][cur_spl].gain  = out_val
                            SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          end
                          refresh.data = true 
                          refresh.GUI = true 
                        end,                        
                        
              func_wheel = function()
                          local cur_spl0 = cur_spl
                          if cur_spl == -1 then cur_spl0 = 1 end
                          local out_val = lim(data[cur_note][cur_spl0].gain  + mouse.wheel_trig/wheel_ratio, 0, 2)
                          if not out_val then return end
                          
                          if cur_spl == -1 then 
                            for spl = 1, #data[cur_note] do
                              data[cur_note][spl].gain  = out_val
                              SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl) 
                            end
                           else
                            data[cur_note][cur_spl].gain  = out_val
                            SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          end
                           
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
                        
              func_ResetVal = function ()
                          if cur_spl == -1 then 
                            for spl = 1, #data[cur_note] do
                              data[cur_note][spl].gain  = 0.5
                              SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl) 
                            end                          
                           else 
                            data[cur_note][cur_spl].gain  = 0.5
                            SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          end
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
              func_mouseover = function()
                                if cur_spl == -1 then cur_spl = 1 end
                                if obj['mix_splctrl_gain'..cur_note] then 
                                  obj.info_line_mixer.txt =  
                                    cur_note..' '..data[cur_note][cur_spl].sample_short..' Gain '..
                                    ({TrackFX_GetFormattedParamValue( data[cur_note][cur_spl].tr_ptr, data[cur_note][cur_spl].rs5k_pos, 0, '' )})[2]..'dB'
                                  refresh.GUI_minor = true 
                                end
                              end
                          }                      
  
  end
  ---------------------------------------------------
  function OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl)
    local dragratio = 150
    local ctrl_ratio = 0.1
    local wheel_ratio = 12000
    return {  func =  function() 
                        local cur_spl0 = cur_spl
                        if cur_spl == -1 then cur_spl0 = 1 end
                        mouse.context_latch_val = data[cur_note][cur_spl0].pan 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/dragratio, 0, 1)
                          if not out_val then return end
                          
                          if cur_spl == -1 then 
                            for spl = 1, #data[cur_note] do
                              data[cur_note][spl].pan  = out_val
                              SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl)  
                              if obj['mix_splctrl_pan'..cur_note] and conf.tab == 1 then 
                                obj['mix_splctrl_pan'..cur_note].val = data[cur_note][spl].pan
                                local pan_txt  = math.floor((-0.5+data[cur_note][spl].pan)*200)
                                if pan_txt < 0 then pan_txt = math.abs(pan_txt)..'%L' elseif pan_txt > 0 then pan_txt = math.abs(pan_txt)..'%R' else pan_txt = 'center' end
                                obj.info_line_mixer.txt =  cur_note..' '..data[cur_note][spl].sample_short..' Pan '..pan_txt
                                refresh.data = true 
                                refresh.GUI_minor = true 
                               else
                                refresh.data = true 
                                refresh.GUI = true 
                              end  
                            end                                                 
                           else
                            data[cur_note][cur_spl].pan  = out_val
                            SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)  
                            if obj['mix_splctrl_pan'..cur_note] and conf.tab == 1 then 
                              obj['mix_splctrl_pan'..cur_note].val = data[cur_note][cur_spl].pan
                              local pan_txt  = math.floor((-0.5+data[cur_note][cur_spl].pan)*200)
                              if pan_txt < 0 then pan_txt = math.abs(pan_txt)..'%L' elseif pan_txt > 0 then pan_txt = math.abs(pan_txt)..'%R' else pan_txt = 'center' end
                              obj.info_line_mixer.txt =  cur_note..' '..data[cur_note][cur_spl].sample_short..' Pan '..pan_txt
                              refresh.data = true 
                              refresh.GUI_minor = true 
                             else
                              refresh.data = true 
                              refresh.GUI = true 
                            end                            
                          end
                        end,
              func_ctrlLD = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - ctrl_ratio*mouse.dy/dragratio, 0, 1)
                          if not out_val then return end
                          
                          if cur_spl == -1 then 
                            for spl = 1, #data[cur_note] do          
                              data[cur_note][spl].pan  = out_val
                              SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl)  
                            end
                           else                
                            data[cur_note][cur_spl].pan  = out_val
                            SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)  
                          end
                          refresh.GUI = true 
                          refresh.data = true 
                        end,                        
              func_wheel = function()
                          local cur_spl0 = cur_spl
                          if cur_spl == -1 then cur_spl0 = 1 end
                          local out_val = lim(data[cur_note][cur_spl0].pan  + mouse.wheel_trig/wheel_ratio, 0, 2)
                          if not out_val then return end
                          
                          if cur_spl == -1 then 
                            for spl = 1, #data[cur_note] do          
                              data[cur_note][spl].pan  = out_val
                              SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl)  
                            end
                           else                
                            data[cur_note][cur_spl].pan  = out_val
                            SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)  
                          end
                          
                          refresh.GUI = true 
                          refresh.data = true 
                        end,                          
              func_ResetVal = function () 
              
                          if cur_spl == -1 then 
                            for spl = 1, #data[cur_note] do          
                              data[cur_note][spl].pan  = 0.5
                              SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl)  
                            end
                           else                
                            data[cur_note][cur_spl].pan  = 0.5
                            SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)  
                          end              
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
              func_mouseover = function()
                                if cur_spl == -1 then cur_spl = 1 end
                                if obj['mix_splctrl_pan'..cur_note] then 
                                  local pan_txt  = math.floor((-0.5+data[cur_note][cur_spl].pan)*200)
                                  if pan_txt < 0 then pan_txt = math.abs(pan_txt)..'%L' elseif pan_txt > 0 then pan_txt = math.abs(pan_txt)..'%R' else pan_txt = 'center' end
                                  obj.info_line_mixer.txt =  
                                    cur_note..' '..data[cur_note][cur_spl].sample_short..' Pan '..pan_txt
                                  refresh.GUI_minor = true 
                                end
                              end                        }        
  end    
  ---------------------------------------------------
  function OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl)
    local dragratio = 80
    local ctrl_ratio = 0.1
    local wheel_ratio = 12000  
    local pitch_mouseres = 400
    return  {
          func =  function() 
                        local cur_spl0 = cur_spl
                        if cur_spl == -1 then cur_spl0 = 1 end          
                    mouse.context_latch_val = data[cur_note][cur_spl0].pitch_offset 
                  end,
          func_LD2 = function ()
                      if not mouse.context_latch_val then return end
                      local out_val = lim(mouse.context_latch_val - mouse.dy/pitch_mouseres, 0, 1)*160
                      local int, fract = math.modf(mouse.context_latch_val*160 )
                      local out_val = lim(mouse.context_latch_val - mouse.dy/pitch_mouseres, 0, 1)
                      if not out_val then return end
                      out_val = (math_q(out_val*160)+fract)/160
                      
                      if cur_spl == -1 then 
                        for spl = 1, #data[cur_note] do
                          data[cur_note][spl].pitch_offset  = out_val
                          SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl)   
                        end
                         obj.info_line_mixer.txt =  cur_note..' '..data[cur_note][1].sample_short..' Pitch '..math_q_dec(math.floor((data[cur_note][1].pitch_offset-0.5)*160000)/1000, 2)
                         obj['mix_splctrl_pitch'..cur_note].val = out_val
                         refresh.data = true 
                         refresh.GUI_minor = true 
                       else 
                        data[cur_note][cur_spl].pitch_offset  = out_val
                        SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                        refresh.GUI = true 
                        refresh.data = true   
                      end 
                      
                    end,
          func_ctrlLD = function ()
                      if not mouse.context_latch_val then return end
                      --local out_val = lim(mouse.context_latch_val - ctrl_ratio*mouse.dy/pitch_mouseres, 0, 1)*160
                      --local int, fract = math.modf(mouse.context_latch_val*160 )
                      local out_val = lim(mouse.context_latch_val - 0.05*ctrl_ratio*mouse.dy/pitch_mouseres, 0, 1)
                      if not out_val then return end
                      --out_val = (math_q(out_val*160)+fract)/160
                      if cur_spl == -1 then 
                        for spl = 1, #data[cur_note] do
                          data[cur_note][spl].pitch_offset  = out_val
                          SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl)   
                        end
                       obj.info_line_mixer.txt =  cur_note..' '..data[cur_note][1].sample_short..' Pitch '..math_q_dec(math.floor((data[cur_note][1].pitch_offset-0.5)*160000)/1000, 2)
                       obj['mix_splctrl_pitch'..cur_note].val = out_val
                       refresh.data = true 
                       refresh.GUI_minor = true 
                       else 
                        data[cur_note][cur_spl].pitch_offset  = out_val
                        SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                        refresh.GUI = true 
                        refresh.data = true   
                      end 
                      
                    end,                        
          func_wheel = function()
                          local wheel_rat = 24000
                          local cur_spl0 = cur_spl
                          if cur_spl == -1 then cur_spl0 = 1 end
                          local out_val = lim(data[cur_note][cur_spl0].pitch_offset  + mouse.wheel_trig/wheel_rat, 0, 1)*160
                          local int, fract = math.modf(data[cur_note][cur_spl0].pitch_offset*160 )
                          local out_val = lim(data[cur_note][cur_spl0].pitch_offset + mouse.wheel_trig/wheel_rat, 0, 1)
                          if not out_val then return end
                          out_val = (math_q(out_val*160)+fract)/160
                                        
                          --local out_val = lim(data[cur_note][cur_spl].pitch_offset  + mouse.wheel_trig/wheel_ratio, 0, 2)
                          --if not out_val then return end
                      if cur_spl == -1 then 
                        for spl = 1, #data[cur_note] do
                          data[cur_note][spl].pitch_offset  = out_val
                          SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl)   
                        end
                       obj.info_line_mixer.txt =  cur_note..' '..data[cur_note][cur_spl0].sample_short..' Pitch '..math_q_dec(math.floor((data[cur_note][1].pitch_offset-0.5)*160000)/1000, 2)
                       obj['mix_splctrl_pitch'..cur_note].val = out_val
                       refresh.data = true 
                       refresh.GUI_minor = true 
                       else 
                        data[cur_note][cur_spl].pitch_offset  = out_val
                        SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                        refresh.GUI = true 
                        refresh.data = true   
                      end 
                        end,                           
          func_ResetVal = function () 
                      if cur_spl == -1 then 
                        for spl = 1, #data[cur_note] do
                          data[cur_note][spl].pitch_offset  = 0.5
                          SetRS5kData(data, conf, data[cur_note][spl].src_track, cur_note, spl)   
                        end
                       obj.info_line_mixer.txt =  cur_note..' '..data[cur_note][1].sample_short..' Pitch '..math_q_dec(math.floor((data[cur_note][1].pitch_offset-0.5)*160000)/1000, 2)
                       obj['mix_splctrl_pitch'..cur_note].val = 0.5
                       refresh.data = true 
                       refresh.GUI_minor = true 
                       else 
                        data[cur_note][cur_spl].pitch_offset  = 0.5
                        SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                        refresh.GUI = true 
                        refresh.data = true   
                      end 
                    end,
              func_mouseover = function()
                                if cur_spl == -1 then cur_spl = 1  end
                                obj.info_line_mixer.txt =  cur_note..' '..data[cur_note][cur_spl].sample_short..' Pitch '..math_q_dec(math.floor((data[cur_note][1].pitch_offset-0.5)*160000)/1000, 2)
                                refresh.GUI_minor = true 
                              end                    }  
  end
  
  
  ---------------------------------------------------
  function OBJ_GenKeys_splCtrl(conf, obj, data, refresh, mouse, pat)
  
    
    local env_x_shift = 20
    local knob_back = 0
    local knob_y = 0
    local wheel_ratio = 12000
    local loop_mouseres = 100
    local dragratio = 80
    local ctrl_ratio = 0.1
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
      obj._spl_WF_filename = { clear = true,
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
              fontsz = conf.GUI_padfontsz,
              alpha_back =0,
              func =  function()
                        if conf.allow_multiple_spls_per_pad == 1 and cur_note and data[cur_note] then
                          local t = {}
                          for i = 1, #data[cur_note] do
                            t[#t+1] = {str = data[cur_note][i].sample,
                                        func = function() obj.current_WFspl = i end,
                                        state = i == obj.current_WFspl }
                          end
                          t[#t+1] = { str = '|Remove current sample RS5k instance',
                                      func = function() 
                                                SNM_MoveOrRemoveTrackFX( data[cur_note][obj.current_WFspl].src_track, data[cur_note][obj.current_WFspl].rs5k_pos, 0 )
                                                if #data[cur_note] > 1 then
                                                  obj.current_WFspl = 2
                                                 else
                                                  obj.current_WFkey = nil
                                                  obj.current_WFspl = nil
                                                end
                                                refresh.GUI_WF = true  
                                            end}
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
                      fontsz = conf.GUI_splfontsz,
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
                      fontsz = conf.GUI_splfontsz,
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
                      fontsz = conf.GUI_splfontsz,
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
        if (mouse.context_latch and mouse.context_latch == '_splctrl_gain') or (mouse.context == '_splctrl_gain' and mouse.wheel_on_move) then 
          gain_txt  = data[cur_note][cur_spl].gain_dB..'dB'   
         else   
          gain_txt = 'Gain'    
        end
        obj._splctrl_gain = { clear = true,
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
              fontsz = conf.GUI_splfontsz,
              alpha_back =knob_back,
              func =  function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func() end,
              func_trigCtrl =  function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func() end,
              func_LD2 = function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func_LD2() end,
              func_ctrlLD = function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func_ctrlLD() end,
              func_wheel = function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func_wheel() end,
              func_ResetVal = function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func_ResetVal() end,
              --ondrag_LCAS =  function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat,cur_note, cur_spl):ondrag_LCAS() end,
              --onclick_LCAS =  function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func() end,
              }
        ---------- pan ----------                          
        local pan_val = data[cur_note][cur_spl].pan 
        local pan_txt
        if (mouse.context_latch and mouse.context_latch == '_splctrl_pan') or (mouse.context == '_splctrl_pan' and mouse.wheel_on_move)
          --or (mouse.context and mouse.context == 'splctrl_pan')
          then 
          pan_txt  = math.floor((-0.5+data[cur_note][cur_spl].pan)*200)
          if pan_txt < 0 then pan_txt = math.abs(pan_txt)..'%L' elseif pan_txt > 0 then pan_txt = math.abs(pan_txt)..'%R' else pan_txt = 'center' end
         else   pan_txt = 'Pan'    
        end                          
        obj._splctrl_pan = { clear = true,
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
              fontsz = conf.GUI_splfontsz,
              alpha_back =knob_back,
              func =  function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func() end,
              func_trigCtrl =  function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func() end,
              func_LD2 = function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func_LD2() end,
              func_ctrlLD = function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func_ctrlLD() end,               
              func_wheel = function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func_wheel() end,                   
              func_ResetVal = function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func_ResetVal() end,}        
        ---------- ptch ----------                          
        local pitch_val = data[cur_note][cur_spl].pitch_offset 
        local pitch_txt
        if    (mouse.context_latch and (mouse.context_latch == '_splctrl_pitch1' or mouse.context_latch == '_splctrl_pitch2'))
               or (mouse.context == '_splctrl_pitch1' and mouse.wheel_on_move) 
          --or  (mouse.context       and (mouse.context       == 'splctrl_pitch1' or mouse.context       == 'splctrl_pitch2')) 
          then 
          pitch_txt  = data[cur_note][cur_spl].pitch_semitones else   pitch_txt = 'Pitch'    
        end                          
        obj._splctrl_pitch1 = { clear = true,
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
              fontsz = conf.GUI_splfontsz,
              alpha_back =knob_back,
              func =  function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func() end,
              func_trigCtrl =  function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func() end,
              func_LD2 = function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func_LD2() end,
              func_ctrlLD = function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func_ctrlLD() end,
              func_wheel = function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func_wheel() end,
              func_ResetVal = function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, cur_spl):func_ResetVal() end
              }

        ---------- attack ----------  
        local att_txt
        if (mouse.context_latch and mouse.context_latch == '_splctrl_att') or (mouse.context == '_splctrl_att' and mouse.wheel_on_move) then 
          att_txt  = data[cur_note][cur_spl].attack_ms..'ms'   
         else   
          att_txt = 'A'    
        end
        obj._splctrl_att = { clear = true,
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
              fontsz = conf.GUI_splfontsz,
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
              func_ResetVal = function ()
                          data[cur_note][cur_spl].attack  = 0
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }     
        ---------- decay ----------  
        local dec_txt
        if (mouse.context_latch and mouse.context_latch == '_splctrl_dec') or (mouse.context== '_splctrl_dec' and mouse.wheel_on_move) then 
          dec_txt  = data[cur_note][cur_spl].decay_ms..'ms'   
         else   
          dec_txt = 'D'    
        end
        obj._splctrl_dec = { clear = true,
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
              fontsz = conf.GUI_splfontsz,
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
              func_ResetVal = function ()
                          data[cur_note][cur_spl].decay  = 0.016
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)  
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }         
        ---------- sust ----------
        local sust_txt
        if (mouse.context_latch and mouse.context_latch == '_splctrl_sust') or (mouse.context== '_splctrl_sust' and mouse.wheel_on_move) then 
          sust_txt  = data[cur_note][cur_spl].sust_dB..'dB'   
         else   
          sust_txt = 'S'    
        end
        obj._splctrl_sust = { clear = true,
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
              fontsz = conf.GUI_splfontsz,
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
              func_ResetVal = function ()
                          data[cur_note][cur_spl].sust  = 0.5
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }              
        ---------- release ----------  
        local rel_txt
        if (mouse.context_latch and mouse.context_latch == '_splctrl_rel') or (mouse.context == '_splctrl_rel' and mouse.wheel_on_move) then 
          rel_txt  = data[cur_note][cur_spl].rel_ms..'ms'   
         else   
          rel_txt = 'R'    
        end
        local val = data[cur_note][cur_spl].rel^0.1666
        local invert_mouse_rel = 1
        if conf.invert_release == 1 then invert_mouse_rel = -1 end
        obj._splctrl_rel = { clear = true,
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
              val = val,
              fontsz = conf.GUI_splfontsz,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].rel 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val^0.1666 - (invert_mouse_rel * mouse.dy/300), 0, 1)
                          if not out_val then return end
                          out_val = out_val^6
                          data[cur_note][cur_spl].rel  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
              func_wheel = function()
                          local out_val = lim(data[cur_note][cur_spl].rel^0.1666  + (invert_mouse_rel*mouse.wheel_trig/wheel_ratio_log), 0, 2)
                          if not out_val then return end
                          out_val = out_val^6
                          data[cur_note][cur_spl].rel  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end, 
              func_ResetVal = function ()
                          data[cur_note][cur_spl].rel  = 0.0004
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }        
        ---------- loop s ----------
        local loops_val = data[cur_note][cur_spl].offset_start
        local loops_val_txt
        if (mouse.context_latch and mouse.context_latch == '_splctrl_loops') or (mouse.context== '_splctrl_loops' and mouse.wheel_on_move) then 
          loops_val_txt  = math_q_dec(data[cur_note][cur_spl].offset_start, 3)
         else   
          loops_val_txt = 'LoopSt'    
        end              
        obj._splctrl_loops = { clear = true,
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
              fontsz = conf.GUI_splfontsz,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].offset_start 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/loop_mouseres, 0, 1)
                          if not out_val then return end
                          local diff = data[cur_note][cur_spl].offset_end - data[cur_note][cur_spl].offset_start
                          data[cur_note][cur_spl].offset_start  = out_val
                          data[cur_note][cur_spl].offset_end  = out_val+diff
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true
                          refresh.data = true 
                        end,
              func_ctrlLD = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - 0.1*ctrl_ratio*mouse.dy/loop_mouseres, 0, 1)
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
                        
              func_ResetVal = function ()
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
        if (mouse.context_latch and mouse.context_latch == '_splctrl_loope' ) or (mouse.context== '_splctrl_loope' and mouse.wheel_on_move)then 
          loope_val_txt  = math_q_dec(data[cur_note][cur_spl].offset_end, 3)
         else   
          loope_val_txt = 'LoopEnd'    
        end              
        obj._splctrl_loope = { clear = true,
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
              fontsz = conf.GUI_splfontsz,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].offset_end 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/loop_mouseres, 0, 1)
                          if not out_val then return end
                          out_val = lim(out_val,data[cur_note][cur_spl].offset_start,1)
                          data[cur_note][cur_spl].offset_end  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)
                          refresh.GUI = true
                          refresh.data = true 
                        end,
              func_ctrlLD = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - 0.1*ctrl_ratio*mouse.dy/loop_mouseres, 0, 1)
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
                        
              func_ResetVal = function ()
                          data[cur_note][cur_spl].offset_end  = 1
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }     
              
        local obNOstate = data[cur_note][cur_spl].obeynoteoff
        local alpha_back = obj.it_alpha5
        if obNOstate ~= 0 then alpha_back = obj.it_alpha6 end
        local b_h = math.floor(obj.kn_h/3)
        obj._splctrl_obeynoteoff = { clear = true,
                                  x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*9 + env_x_shift*3,
                                  y = knob_y,
                                  w = obj.splctrl_butw,
                                  h = b_h-1,
                                  col = 'white',
                                  state = fale,
                                  txt= 'ObNoteOff',
                                  show = true,
                                  is_but = true,
                                  mouse_overlay = true,
                                  fontsz = conf.GUI_splfontsz,
                                  alpha_back = alpha_back,
                                  a_frame = 0,
                                  func =  function() 
                                            data[cur_note][cur_spl].obeynoteoff  = math.abs(1-data[cur_note][cur_spl].obeynoteoff)
                                            SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)
                                            refresh.conf = true 
                                            refresh.GUI = true
                                            refresh.data = true
                                          end
                                  }
                                  
        obj._splctrl_nextspl = { clear = true,
                                  x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*9 + env_x_shift*3,
                                  y = knob_y+b_h,
                                  w = obj.splctrl_butw,
                                  h = b_h-1,
                                  col = 'white',
                                  state = fale,
                                  txt= 'Next >',
                                  show = true,
                                  is_but = true,
                                  mouse_overlay = true,
                                  fontsz = conf.GUI_splfontsz,
                                  alpha_back = obj.it_alpha5,
                                  a_frame = 0,
                                  func =  function() 
                                            local spl = SearchSample(data[cur_note][cur_spl].sample,true )
                                            if spl then 
                                              Undo_BeginBlock()  
                                                data[cur_note][cur_spl].sample  = spl
                                                SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)
                                                refresh.conf = true 
                                                refresh.GUI = true
                                                refresh.GUI_WF = true
                                                refresh.data = true
                                              Undo_EndBlock( 'RS5k change sample for note '..cur_note, 0 )
                                            end
                                          end
                                  }  
                                  
        obj._splctrl_prevspl = { clear = true,
                                  x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*9 + env_x_shift*3,
                                  y = knob_y+2*b_h,
                                  w = obj.splctrl_butw,
                                  h = b_h-1,
                                  col = 'white',
                                  state = fale,
                                  txt= '< Prev',
                                  show = true,
                                  is_but = true,
                                  mouse_overlay = true,
                                  fontsz = conf.GUI_splfontsz,
                                  alpha_back = obj.it_alpha5,
                                  a_frame = 0,
                                  func =  function() 
                                            local spl = SearchSample(data[cur_note][cur_spl].sample,false )
                                            if spl then 
                                              data[cur_note][cur_spl].sample  = spl
                                              SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)
                                              refresh.conf = true 
                                              refresh.GUI = true
                                              refresh.GUI_WF = true
                                              refresh.data = true
                                            end
                                          end
                                  }  
                                  
        
        local alpha_back = obj.it_alpha5
        if gmem_read(99)==1 and data.choke_t[cur_note] and data.choke_t[cur_note]>0 then alpha_back = obj.it_alpha6 end
        local txt = 'Cut'
        if data.choke_t[cur_note] and data.choke_t[cur_note]>0 then txt = txt..' '..math.floor(data.choke_t[cur_note]) end
        obj._splctrl_choke = { clear = true,
                                  x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*10 + env_x_shift*4,
                                  y = knob_y,
                                  w = obj.splctrl_butw,
                                  h = b_h-1,
                                  col = 'white',
                                  txt= txt,
                                  show = true,
                                  is_but = true,
                                  mouse_overlay = true,
                                  fontsz = conf.GUI_splfontsz,
                                  alpha_back = alpha_back,
                                  a_frame = 0,
                                  func =  function() 
                                            local t = {
                                                        { str = 'Refresh JSFX using current choke configuration',
                                                          func = function() Choke_Apply(conf, obj, data, refresh, mouse, pat)  end
                                                        },
                                                        { str = 'Show choke configuration in console',
                                                          func = function() 
                                                                    local str = ''
                                                                    for i =1, 127 do
                                                                      if data.choke_t[i]> 0 then 
                                                                        local cutname = '' if data[i][1].MIDI_name then cutname =  data[i][1].MIDI_name end
                                                                        local cutbyname  = '' if data[data.choke_t[i]][1].MIDI_name then cutbyname =  data[data.choke_t[i]][1].MIDI_name end
                                                                        str = str..'\n'..'Note '..i..' '..cutname..' CUT >> '..'Note '..data.choke_t[i]..' '..cutbyname 
                                                                      end
                                                                    end
                                                                    msg(str)
                                                                  end
                                                        },  
                                                      { str = 'Show choke configuration in console (inversed)|',
                                                          func = function() 
                                                                    local str = ''
                                                                    for i_recv =1, 127 do
                                                                      local cutbyname  = '' if data[i_recv] and data[i_recv][1].MIDI_name then cutbyname =  data[i_recv][1].MIDI_name end
                                                                      local exist = false
                                                                      str_send = ''
                                                                      for i =1, 127 do
                                                                        if data.choke_t[i] == i_recv then 
                                                                          exist = true
                                                                          local cutname = '' if data[i][1].MIDI_name then cutname =  data[i][1].MIDI_name end
                                                                          str_send = str_send..'    Note '..i..' '..cutname..'\n'
                                                                        end
                                                                      end
                                                                      if exist == true then
                                                                        str = str..'\n'..'Note '..i_recv..' '..cutbyname..' CUTBY >> \n'..str_send
                                                                      end
                                                                    end
                                                                    msg(str)
                                                                  end
                                                        },                                                                                                               
                                                      }
                                                        
                                            for key in pairs(data, function(t,a,b) return t[b] < t[a] end)  do
                                              if tonumber(key) then 
                                                local str = key..': '..data[key][1].MIDI_name
                                                if key == cur_note then str = str..' (self)' end
                                                t[#t+1] = {str = str,
                                                          func = function() 
                                                                    local val = 0
                                                                    if data.choke_t[cur_note] ~= key then val = key end
                                                                    data.choke_t[cur_note]= val
                                                                    Choke_Save(conf, data)
                                                                    Choke_Apply(conf, obj, data, refresh, mouse, pat)
                                                                  end,
                                                          state = data.choke_t[cur_note] == key }
                                              end
                                            end
                                            Menu(mouse, t)
                                          end
                                  }                                                                                                                                             
        ---------- del ----------  
        local del_txt, del_val
        if (mouse.context_latch and mouse.context_latch == '_splctrl_del') or (mouse.context== '_splctrl_del' and mouse.wheel_on_move)  then 
          if data[cur_note][cur_spl].del then 
            del_txt  = data[cur_note][cur_spl].del_ms 
           else
            del_txt  = 'Delay' 
          end
         else   
          del_txt = 'Delay' 
        end
        obj._splctrl_del = { clear = true,
              x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*11 + env_x_shift*5,
              y = knob_y,
              w = obj.kn_w,
              h = obj.kn_h,
              col = 'white',
              state = 0,
              txt= del_txt,
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              is_centered_knob = true,
              val = data[cur_note][cur_spl].del,
              fontsz = conf.GUI_splfontsz,
              alpha_back =knob_back,
              func =  function() 
                        if data[cur_note][cur_spl].src_track == data.parent_track then
                          ShowRS5kChain(data, conf, cur_note, cur_spl) 
                         else
                          --SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl, false, true)
                          if data[cur_note][cur_spl].del  then mouse.context_latch_val = data[cur_note][cur_spl].del  else  mouse.context_latch_val =0.5 end
                        end
                        
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/300, 0, 1)
                          if not out_val then return end
                          out_val = out_val
                          data[cur_note][cur_spl].del  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl, false, true) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
              func_ctrlLD = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - 0.1*ctrl_ratio*mouse.dy/300, 0, 1)
                          if not out_val then return end
                          out_val = out_val
                          data[cur_note][cur_spl].del  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl, false, true) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
                                                
              func_wheel = function()
                          local out_val = lim(data[cur_note][cur_spl].del  + mouse.wheel_trig/24000, 0, 1)
                          if not out_val then return end
                          out_val = out_val
                          data[cur_note][cur_spl].del  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl, false, true) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end,  
              func_ResetVal = function ()
                          data[cur_note][cur_spl].del  = 0.5
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl, false, true) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }      
              
                                                                                                                                                                                                            
  end

  ---------------------------------------------------
  function BuildKeyName(conf, data, note, str)
    if not str then return "" end
    --------
    str = str:gsub('#midipitch', note)
    --------
    local ntname = GetNoteStr(conf, note, 0)
    if not ntname then ntname = '' end
    str = str:gsub('#keycsharp ', ntname)
    local ntname2 = GetNoteStr(conf, note, 7)
    if not ntname2 then ntname2 = '' end
    str = str:gsub('#keycsharpRU ', ntname2)
    --------
    if data[note] and data[note][1] and data[note][1].MIDI_name and data[note][1].MIDI_name ~= '' then 
      str = str:gsub('#notename', data[note][1].MIDI_name) 
     else 
      str = str:gsub('#notename', '')
    end
    --------
    if data[note] then 
      str = str:gsub('#samplecount', '('..#data[note]..')') else str = str:gsub('#samplecount', '')
    end 
    --------
    local spls = ''
    if data[note] and #data[note] >= 1 then
      for spl = 1, #data[note] do
        spls = spls..data[note][spl].sample_short..'\n'
      end
    end
    str = str:gsub('#samplename', spls)
    --------
    str = str:gsub('|  |', '|')
    str = str:gsub('|', '\n')
    --------

    
    return str

    
  end
    -------------------------------------------------------------
    function OBJ_Layouts(conf, obj, data, refresh, mouse)
        local shifts,w_div ,h_div
        if conf.keymode ==0 then 
          w_div = 7
          h_div = 2
          shifts  = {{0,1},{0.5,0},{1,1},{1.5,0},{2,1},{3,1},{3.5,0},{4,1},{4.5,0},{5,1},{5.5,0},{6,1},}
        elseif conf.keymode ==1 then 
          w_div = 14
          h_div = 2
          shifts  = {{0,1},{0.5,0},{1,1},{1.5,0},{2,1},{3,1},{3.5,0},{4,1},{4.5,0},{5,1},{5.5,0},{6,1},{7,1},{7.5,0},{8,1},{8.5,0},{9,1},{10,1},{10.5,0},{11,1},{11.5,0},{12,1},{12.5,0},{13,1}                 
                  }                
         elseif conf.keymode == 2 then -- korg nano
          w_div = 8
          h_div = 2     
          shifts  = {{0,1},{0,0},{1,1},{1,0},{2,1},{2,0},{3,1},{3,0},{4,1},{4,0},{5,1},{5,0},{6,1},{6,0},{7,1},{7,0},}   
         elseif conf.keymode == 3 then -- live dr rack
          w_div = 4
          h_div = 4     
          shifts  = { {0,3},{1,3},{2,3},{3,3},{0,2},{1,2},{2,2},{3,2},{0,1},{1,1},{2,1},{3,1},{0,0},{1,0},{2,0},{3,0}                                                               
                  }      
         elseif conf.keymode == 4 then -- s1 impact
          w_div = 4
          h_div = 4 
          start_note_shift = -1    
          shifts  = { {0,3},{1,3},{2,3},{3,3},{0,2},{1,2},{2,2},{3,2},{0,1},{1,1},{2,1},{3,1},{0,0},{1,0},{2,0},{3,0}                                                               
                  }  
         elseif conf.keymode == 5 then -- ableton push
          w_div = 8
          h_div = 8  
          shifts  = { 
                      {0,7},{1,7},{2,7},{3,7},{4,7},{5,7},{6,7},{7,7},{0,6},{1,6},{2,6},{3,6},{4,6},{5,6},{6,6},{7,6},{0,5},{1,5},{2,5},{3,5},{4,5},{5,5},{6,5},{7,5},{0,4},{1,4},{2,4},{3,4},{4,4},{5,4},{6,4},{7,4},{0,3},{1,3},{2,3},{3,3},{4,3},{5,3},{6,3},{7,3},{0,2},{1,2},{2,2},{3,2},{4,2},{5,2},{6,2},{7,2},{0,1},{1,1},{2,1},{3,1},{4,1},{5,1},{6,1},{7,1},{0,0},{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},}        
         elseif conf.keymode == 6 then -- 8x8 segmented
          w_div = 8
          h_div = 8  
          shifts  = { 
                      {0,7},{1,7},{2,7},{3,7},{0,6},{1,6},{2,6},{3,6},{0,5},{1,5},{2,5},{3,5},{0,4},{1,4},{2,4},{3,4},{0,3},{1,3},{2,3},{3,3},{0,2},{1,2},{2,2},{3,2},{0,1},{1,1},{2,1},{3,1},{0,0},{1,0},{2,0},{3,0},{4,7},{5,7},{6,7},{7,7},{4,6},{5,6},{6,6},{7,6},{4,5},{5,5},{6,5},{7,5},{4,4},{5,4},{6,4},{7,4},{4,3},{5,3},{6,3},{7,3},{4,2},{5,2},{6,2},{7,2},{4,1},{5,1},{6,1},{7,1},{4,0},{5,0},{6,0},{7,0},}      
  elseif conf.keymode == 7 then -- 8x8, vertical columns
          w_div = 8
          h_div = 8  
          shifts  = { 
                      {0,7},{0,6},{0,5},{0,4},{0,3},{0,2},{0,1},{0,0},{1,7},{1,6},{1,5},{1,4},{1,3},{1,2},{1,1},{1,0},{2,7},{2,6},{2,5},{2,4},{2,3},{2,2},{2,1},{2,0},{3,7},{3,6},{3,5},{3,4},{3,3},{3,2},{3,1},{3,0},{4,7},{4,6},{4,5},{4,4},{4,3},{4,2},{4,1},{4,0},{5,7},{5,6},{5,5},{5,4},{5,3},{5,2},{5,1},{5,0},{6,7},{6,6},{6,5},{6,4},{6,3},{6,2},{6,1},{6,0},{7,7},{7,6},{7,5},{7,4},{7,3},{7,2},{7,1},{7,0},}  
  elseif conf.keymode == 8 then -- allkeys
          w_div = 12
          h_div = 12 
          shifts  = { 
                      {0,0},{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{0,1},{1,1},{2,1},{3,1},{4,1},{5,1},{6,1},{7,1},{8,1},{9,1},{10,1},{11,1},{0,2},{1,2},{2,2},{3,2},{4,2},{5,2},{6,2},{7,2},{8,2},{9,2},{10,2},{11,2},{0,3},{1,3},{2,3},{3,3},{4,3},{5,3},{6,3},{7,3},{8,3},{9,3},{10,3},{11,3},{0,4},{1,4},{2,4},{3,4},{4,4},{5,4},{6,4},{7,4},{8,4},{9,4},{10,4},{11,4},{0,5},{1,5},{2,5},{3,5},{4,5},{5,5},{6,5},{7,5},{8,5},{9,5},{10,5},{11,5},{0,6},{1,6},{2,6},{3,6},{4,6},{5,6},{6,6},{7,6},{8,6},{9,6},{10,6},{11,6},{0,7},{1,7},{2,7},{3,7},{4,7},{5,7},{6,7},{7,7},{8,7},{9,7},{10,7},{11,7},{0,8},{1,8},{2,8},{3,8},{4,8},{5,8},{6,8},{7,8},{8,8},{9,8},{10,8},{11,8},{0,9},{1,9},{2,9},{3,9},{4,9},{5,9},{6,9},{7,9},{8,9},{9,9},{10,9},{11,9},{0,10},{1,10},{2,10},{3,10},{4,10},{5,10},{6,10},{7,10},{8,10},{9,10},{10,10},{11,10},{0,11},{1,11},{2,11},{3,11},{4,11},{5,11},{6,11},{7,11},{8,11},{9,11},{10,11},{11,11},}
  elseif conf.keymode == 9 then -- allkeys bot to top
          w_div = 12
          h_div = 12 
          shifts  = {                      
                       
  {0,11},{1,11},{2,11},{3,11},{4,11},{5,11},{6,11},{7,11},{8,11},{9,11},{10,11},{11,11},{0,10},{1,10},{2,10},{3,10},{4,10},{5,10},{6,10},{7,10},{8,10},{9,10},{10,10},{11,10},{0,9},{1,9},{2,9},{3,9},{4,9},{5,9},{6,9},{7,9},{8,9},{9,9},{10,9},{11,9},{0,8},{1,8},{2,8},{3,8},{4,8},{5,8},{6,8},{7,8},{8,8},{9,8},{10,8},{11,8},{0,7},{1,7},{2,7},{3,7},{4,7},{5,7},{6,7},{7,7},{8,7},{9,7},{10,7},{11,7},{0,6},{1,6},{2,6},{3,6},{4,6},{5,6},{6,6},{7,6},{8,6},{9,6},{10,6},{11,6},{0,5},{1,5},{2,5},{3,5},{4,5},{5,5},{6,5},{7,5},{8,5},{9,5},{10,5},{11,5},{0,4},{1,4},{2,4},{3,4},{4,4},{5,4},{6,4},{7,4},{8,4},{9,4},{10,4},{11,4},{0,3},{1,3},{2,3},{3,3},{4,3},{5,3},{6,3},{7,3},{8,3},{9,3},{10,3},{11,3},{0,2},{1,2},{2,2},{3,2},{4,2},{5,2},{6,2},{7,2},{8,2},{9,2},{10,2},{11,2},{0,1},{1,1},{2,1},{3,1},{4,1},{5,1},{6,1},{7,1},{8,1},{9,1},{10,1},{11,1},{0,0},{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0}}
                       
        end
        return  shifts,w_div ,h_div
    end
    ---------------------------------------------------
    function OBJ_GenKeys(conf, obj, data, refresh, mouse) 
      local shifts,w_div ,h_div = OBJ_Layouts(conf, obj, data, refresh, mouse)
      local WF_shift = 0
      if conf.show_wf == 1 and conf.separate_spl_peak == 1 then WF_shift = obj.WF_h end
      local key_area_h = gfx.h -obj.kn_h-obj.samplename_h-WF_shift
      local key_w = math.ceil((gfx.w-3*obj.offs-obj.keycntrlarea_w)/w_div)
      local key_h = math.ceil((1/h_div)*(key_area_h)) 
      obj.h_div = h_div
      for i = 1, #shifts do
        local id = i-1+conf.oct_shift*12
        local start_oct_shift = conf.start_oct_shift
        if conf.keymode == 8 or conf.keymode == 9 then start_oct_shift = 0 end
        local note = (i-1)+12*conf.oct_shift+start_oct_shift*12
        local col = 'white'
        local colint, colint0
        
        local alpha_back
        if  data[note] and data[note][1] then 
          alpha_back = 0.6       
          col = 'green'
          if data[note][1].src_track_col then colint = data[note][1].src_track_col  end    
         else
          alpha_back = 0.15 
        end

          local txt = BuildKeyName(conf, data, note, conf.key_names2)
          
          if  key_w < obj.fx_rect_side*2.5 or key_h < obj.fx_rect_side*2.8 then txt = note end
          if  key_w < obj.fx_rect_side*1.5 or key_h < obj.fx_rect_side*1.5 then txt = '' end
          if note >= 0 and note <= 127 then
            local key_xpos = obj.keycntrlarea_w + shifts[i][1]*key_w  + 2
            local key_ypos = gfx.h-key_area_h+ shifts[i][2]*key_h
            OBJ_GenKeys_PadButtons(conf, obj, data, refresh, mouse, note, key_xpos, key_ypos, key_w, key_h )
            -------------------------
            -- keys
            local draw_drop_line if data.activedroppedpad and data.activedroppedpad == 'keys_p'..note then draw_drop_line = true end
            local a_frame,selection_tri = 0.05 
            if obj.current_WFkey and note == obj.current_WFkey then
              a_frame =obj.sel_key_frame
              selection_tri = true
            end
            obj['keys_p'..note] = 
                      { clear = true,
                        draw_drop_line = draw_drop_line,
                        drop_line_text = data.activedroppedpad_action,
                        x = key_xpos,
                        y = key_ypos,
                        w = key_w-1,
                        h = key_h,
                        col = col,
                        colint = colint,
                        state = 0,
                        txt= txt,
                        limtxtw = obj.fx_rect_side,
                        is_step = true,
                        --vertical_txt = fn,
                        linked_note = note,
                        show = true,
                        is_but = true,
                        alpha_back = alpha_back,
                        selection_tri=selection_tri,
                        a_frame = a_frame,
                        aligh_txt = 5,
                        fontsz = conf.GUI_padfontsz,--obj.GUI_fontsz2,
                        func =  function() 
                                  SetProjExtState( 0, 'MPLRS5KMANAGEFUNC', 'LASTNOTERS5KMAN', note )
                                  if not data.hasanydata then return end
                                  data.current_spl_peaks = nil
                                  if conf.keypreview == 1 then  StuffMIDIMessage( 0, '0x9'..string.format("%x", 0), note,100) end                                  
                                  if obj.current_WFkey ~= note then 
                                    obj.current_WFspl = 1                                   
                                    obj.current_WFkey = note
                                  end
                                  
                                  refresh.GUI_WF = true  
                                  refresh.GUI = true     
                                end,
                        func_R =  function ()
                                    if not data[note] then return end
                                    Menu(mouse, { { str =   'Float linked FX',
                                                    func =  function()
                                                              if data[note] then
                                                                for spl = 1, #data[note] do
                                                                  -- TrackFX_SetOpen(  data[note][1].src_track, data[note][1].rs5k_pos, true )
                                                                  TrackFX_Show( data[note][spl].src_track, data[note][spl].rs5k_pos,3 )
                                                                end
                                                              end
                                                            end},
                                                    { str =   'Show linked FX chain',
                                                    func =  function()
                                                              if data[note] then
                                                                for spl = 1, #data[note] do
                                                                  -- TrackFX_SetOpen(  data[note][1].src_track, data[note][1].rs5k_pos, true )
                                                                  TrackFX_Show( data[note][spl].src_track, data[note][spl].rs5k_pos,1 )
                                                                end
                                                              end
                                                            end},                                                            
                                                  { str =   'Rename linked MIDI note',
                                                    func =  function()
                                                              local MIDI_name = GetTrackMIDINoteNameEx( 0, data[note][1].src_track, note, 1)
                                                              local ret, MIDI_name_ret = reaper.GetUserInputs( conf.scr_title, 1, 'Rename MIDI note,extrawidth=200', MIDI_name )
                                                              if ret then
                                                                SetTrackMIDINoteNameEx( 0, data[note][1].src_track, note, 0, MIDI_name_ret)
                                                                SetTrackMIDINoteNameEx( 0, data.parent_track, note, 0, MIDI_name_ret)
                                                              end
                                                            end},
                                                  { str =   'Remove pad content',
                                                    func =  function()
                                                              for spl = #data[note], 1, -1 do
                                                                SNM_MoveOrRemoveTrackFX( data[note][spl].src_track, data[note][spl].rs5k_pos, 0 )
                                                              end
                                                            end},                                                            
                                                
                                                })
                                    obj.current_WFkey = nil
                                    obj.current_WFspl = nil
                                    refresh.GUI_WF = true  
                                    refresh.GUI = true  
                                    refresh.data = true                                  
                                  end,
                        func_DC = function()
                                    
                                  end,
                                 
                                } 
            if    note%12 == 1 
              or  note%12 == 3 
              or  note%12 == 6 
              or  note%12 == 8 
              or  note%12 == 10 
              then obj['keys_p'..note].txt_col = 'black' 
            end
              
              
        end
      end
    
      
    end
    -------------------------------------------------------------
  function OBJ_GenKeys_PadButtons(conf, obj, data, refresh, mouse, note, key_xpos, key_ypos, key_w, key_h, alignformixer) local x_pos,y_pos
    if not data[note] or not data[note][1] then return end
    local i = note
    local cnt = 0
    local key_xpos = key_xpos -2
            ------------ctrl butts
            local y_shift_butts = 0 
            if alignformixer then y_shift_butts = -1 end   
            -- mute            
            if key_h > obj.fx_rect_side*3 and key_w > obj.fx_rect_side then 
              if conf.FX_buttons&(1<<3) == (1<<3) then 
                y_shift_butts = y_shift_butts + 1
                local  alpha_back = 0.01
                if data[note] and data[note][1] and data[note][1].bypass_state == false then alpha_back = 0.4 end
                local x_pos, y_pos = 0,0
                if alignformixer then 
                  x_pos = key_xpos + (key_w - obj.fx_rect_side)/2 +1
                  y_pos = key_ypos + key_h - obj.fx_rect_side*(3-y_shift_butts)
                 else
                  x_pos = key_xpos + key_w - obj.fx_rect_side
                  y_pos = key_ypos + key_h - obj.fx_rect_side*y_shift_butts
                end
                cnt=cnt+1
                obj['keys_pMUTE'..i] = { clear = true,
                      x = x_pos,
                      y = y_pos,
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
            if key_h > obj.fx_rect_side*2 and key_w > obj.fx_rect_side then 
              if conf.FX_buttons&(1<<4) == (1<<4) then 
                y_shift_butts = y_shift_butts + 1
                local  alpha_back = 0.01
                if data[note].solo_state then  alpha_back = 0.5 end
                local x_pos, y_pos = 0,0
                if alignformixer then 
                  x_pos = key_xpos + (key_w - obj.fx_rect_side)/2 +1
                  y_pos = key_ypos + key_h - obj.fx_rect_side*(3-y_shift_butts)
                 else
                  x_pos = key_xpos + key_w - obj.fx_rect_side
                  y_pos = key_ypos + key_h - obj.fx_rect_side*y_shift_butts
                end                
                cnt=cnt+1
                obj['keys_pSolo'..i] = { clear = true,
                      x = x_pos,
                      y = y_pos,
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

            -- FX                    
            if key_h > obj.fx_rect_side and key_w > obj.fx_rect_side then               
              if conf.FX_buttons&(1<<2) == (1<<2) then --and conf.allow_multiple_spls_per_pad == 0 then 
                y_shift_butts = y_shift_butts + 1
                local  alpha_back = 0.01
                if data[note] and data[note][1] and data[note][1].src_track ~= data.parent_track then alpha_back = 0.4 end
                if alignformixer then 
                  x_pos = key_xpos + (key_w - obj.fx_rect_side)/2 +1
                  y_pos = key_ypos + key_h - obj.fx_rect_side*(3-y_shift_butts)
                 else
                  x_pos = key_xpos + key_w - obj.fx_rect_side
                  y_pos = key_ypos + key_h - obj.fx_rect_side*y_shift_butts
                end     
                cnt=cnt+1               
                obj['keys_pFX'..i] = { clear = true,
                      x = x_pos,
                      y = y_pos,
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
    return cnt              
  end
  ---------------------------------------------------------
  function OBJ_Menu(conf, obj, data, refresh, mouse)
    local fx_per_pad if conf.allow_multiple_spls_per_pad == 1 then fx_per_pad = '#' else fx_per_pad = '' end
    -- ask pinned tr
      local ret, trGUID = GetProjExtState( 0, 'MPLRS5KMANAGE', 'PINNEDTR' )
      local pinnedtr = BR_GetMediaTrackByGUID( 0, trGUID )
      local pinnedtr_str = '(none)' 
      if pinnedtr then 
        _, pinnedtr_str = GetTrackName( pinnedtr, '' )
      end
      
    -- 
      local wf_active = conf.show_wf == 0  
      if wf_active then wf_active = '#' else wf_active = '' end
      
      local note_active = gmem_attach
      if note_active then note_active = '' else note_active = '#' end
      
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
    func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
  { str = 'Cockos Forum thread',
    func = function() Open_URL('http://forum.cockos.com/showthread.php?t=207971') end  } , 
  { str = 'YouTube overview by Jon Tidey (REAPER Blog)|',
    func = function() Open_URL('http://www.youtube.com/watch?v=clucnX0WWXc') end  } ,     
    
  { str = '#Options'},    
  
  
    
  { str = '>Key options',  
    menu_inc = true},
  { str = '>Key controls', menu_inc = true},
  { str = fx_per_pad..'FX',  
    state = conf.FX_buttons&(1<<2) == (1<<2),
    func =  function() 
              local ret = BinaryCheck(conf.FX_buttons, 2)
              conf.FX_buttons = ret
            end ,
  },
  { str = 'Solo (bypass all except current)',  
    state = conf.FX_buttons&(1<<4) == (1<<4),
    func =  function() 
              local ret = BinaryCheck(conf.FX_buttons, 4)
              conf.FX_buttons = ret
            end ,
  },
  { str = 'Mute (bypass)|<',  
    state = conf.FX_buttons&(1<<3) == (1<<3),
    func =  function() 
              local ret = BinaryCheck(conf.FX_buttons, 3)
              conf.FX_buttons = ret
            end ,
  },
  { str = '>Key names'},  
  { str = 'Reset to defaults',
    func = function() 
              conf.key_names2 = '#midipitch #keycsharp |#notename #samplecount |#samplename'  
              conf.key_names_mixer = '#midipitch #keycsharp |#notename '  
              conf.key_names_pat   = '#midipitch #keycsharp  #notename '      
            end},  
  { str = 'Edit keyname hashtags (pads)',
    func = function() 
              local ret = GetInput( conf, 'Keyname hashtags', conf.key_names2, _, 400, true) 
              if ret then  
                conf.key_names2 = ret 
              end             
            end},  
  { str = 'Edit keyname hashtags (mixer)',
    func = function() 
              local ret = GetInput( conf, 'Mixer keyname hashtags', conf.key_names_mixer, _, 400, true) 
              if ret then  
                conf.key_names_mixer = ret 
              end             
            end},  
  { str = 'Edit keyname hashtags (pattern)',
    func = function() 
              local ret = GetInput( conf, 'Pattern keyname hashtags', conf.key_names_pat, _, 400, true) 
              if ret then  
                conf.key_names_pat = ret 
              end             
            end},             
                        
  { str = 'Keyname hashtag reference',
    func = function() 
              msg([[
List of available hashtags:

#midipitch
#keycsharp - formatted as C#5
#keycsharpRU
#notename - note name in MIDI Editor
#samplecount - return count of samples linked to current note in parentheses
#samplename - return sample names linked to current note, separated by new line
| - new line
]]
 )       
            end},                       
  { str = '|Visual octave shift: '..conf.oct_shift..'oct|<',
    func = function() 
              ret = GetInput( conf, 'Visual octave shift', conf.oct_shift,true) 
              if ret then  conf.oct_shift = ret  end end,
  } ,
  
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
  { str = 'Ableton Live Drum Rack / S1 Impact (4x4)',
    func = function() conf.keymode = 3 end ,
    state = conf.keymode == 3 or conf.keymode == 4},
  { str = 'Ableton Push (8x8)',
    func = function() conf.keymode = 5 end ,
    state = conf.keymode == 5},    
    { str = '8x8 segmented',
      func = function() conf.keymode = 6 end ,
      state = conf.keymode == 6}, 
    { str = '8x8 vertical',
      func = function() conf.keymode = 7 end ,
      state = conf.keymode == 7},   
    { str = 'All keys from bottom to the top',
      func = function() conf.keymode = 9 end ,
      state = conf.keymode == 9},           
    { str = 'All keys from top to the bottom|<|',
      func = function() conf.keymode = 8 end ,
      state = conf.keymode == 8},       
        
  { str = 'Send MIDI by clicking on keys',
    func = function() conf.keypreview = math.abs(1-conf.keypreview)  end ,
    state = conf.keypreview == 1},  
  { str = 'Send MIDI noteoff on mouse release (leave notes unclosed!)|<',
    func = function() conf.sendnoteoffonrelease = math.abs(1-conf.sendnoteoffonrelease)  end ,
    state = conf.sendnoteoffonrelease == 1},      
     


  { str = '>RS5k controls'},
  { str = 'Invert mouse for release',  
    state = conf.invert_release == 1,
    func =  function() conf.invert_release = math.abs(1-conf.invert_release)  end ,
  },  
  { str = 'Obey noteOff enabled by default|<',  
    state = conf.obeynoteoff_default == 1,
    func =  function() conf.obeynoteoff_default = math.abs(1-conf.obeynoteoff_default)  end ,
  },    
  
  

  { str = '>Mouse Modifiers'},
  { str = 'Doubleclick reset value (Pad and Mixer tabs only)',  
    state = conf.MM_reset_val&(1<<0) == (1<<0),
    func =  function() 
              local ret = BinaryCheck(conf.MM_reset_val, 0)
              conf.MM_reset_val = ret
            end ,},   
  { str = 'Alt+Click reset value',  
    state = conf.MM_reset_val&(1<<1) == (1<<1),
    func =  function() 
              local ret = BinaryCheck(conf.MM_reset_val, 1)
              conf.MM_reset_val = ret
            end }, 
  { str = 'Allow pads drag to copy/move|<',  
    state = conf.allow_dragpads&1==1,
    func =  function() 
              conf.allow_dragpads = math.abs(1-conf.allow_dragpads)
            end },             
            
            
--[[  { str = 'Doubleclick on pads float related RS5k instances|',  
    state = conf.MM_dc_float == 1,
    func =  function() conf.MM_dc_float = math.abs(1-conf.MM_dc_float)  end }  ,  ]]        

  { str = '>GUI options'},
  { str = 'Controls size scaling',
    func =  function() 
              local ret = GetInput( conf, 'Pad font', conf.GUI_ctrlscale)
              if ret then 
                conf.GUI_ctrlscale = ret
                refresh.GUI = true
              end
            end
  } ,   
  { str = 'Sample controls font size',
    func =  function() 
              local ret = GetInput( conf, 'Pad font', conf.GUI_splfontsz,true)
              if ret then 
                conf.GUI_splfontsz = ret
                refresh.GUI = true
              end
            end
  } ,  
  
  { str = 'Pad font size',
    func =  function() 
              local ret = GetInput( conf, 'Pad font', conf.GUI_padfontsz,true)
              if ret then 
                conf.GUI_padfontsz = ret
                refresh.GUI = true
              end
            end
  } ,
  
  { str = 'Show waveform',
    func =  function() conf.show_wf = math.abs(1-conf.show_wf)  end,
    state = conf.show_wf == 1,
  } , 
  { str = wf_active..'Separate waveform from knobs',
    func =  function() conf.separate_spl_peak = math.abs(1-conf.separate_spl_peak)  end,
    state = conf.separate_spl_peak == 1,
  } ,   
  { str = note_active..'Show input notes',
    func = function() 
              conf.allow_track_notes = math.abs(1-conf.allow_track_notes)  
              if conf.allow_track_notes == 1 then                 
                MB('This function require REAPER 5.961+dev1031 and RS5K_Manager_tracker JSFX installed and inserted at 1st slot of parent RS5k Manager track', 'Attention', 0)
              end
              
            end ,
    state = conf.allow_track_notes == 1},  
    
  { str = 'Override pattern key width (0=auto)',
    func = function() 
              local retval, retvals_csv = reaper.GetUserInputs( conf.mb_title, 1, 'Override pattern key width', conf.key_width_override )
              if retval then
                retvals_csv  = tonumber(retvals_csv)
                if not retvals_csv then return end
                retvals_csv = math.floor(retvals_csv)
                if retvals_csv >=0 and retvals_csv <=300 then
                  conf.key_width_override = retvals_csv
                end
              end
              
            end   } ,   
  { str = 'Set background RGBA|<',
    func = function() 
              local retval, retvals_csv = reaper.GetUserInputs( conf.mb_title, 4, 'Set background RGBA', 
                math.floor(conf.GUIback_R*255)..','..math.floor(conf.GUIback_G*255)..','..math.floor(conf.GUIback_B*255)..','..conf.GUIback_A )
              if retval then
                local t = {}
                for val in retvals_csv:gmatch('[%d%.]+') do 
                  if not tonumber(val) then MB('Entered data not valid, RGB support [0...255], alpha [0...1]', conf.mb_title, 0) return end
                  t[#t+1]=tonumber(val)
                end
                if #t ~= 4 then MB('Entered data not valid, RGB support [0...255], alpha [0...1]', conf.mb_title, 0) return end
                conf.GUIback_R = lim(t[1]/255)
                conf.GUIback_G = lim(t[2]/255)
                conf.GUIback_B = lim(t[3]/255)
                conf.GUIback_A = lim(t[4])
                
              end
              
            end   } ,    

  { str = '>Dragndrop options'},
  { str = 'Always export dragged samples to new tracks',
    func =  function() conf.dragtonewtracks = math.abs(1-conf.dragtonewtracks)  end,
    state = conf.dragtonewtracks == 1,
  } ,     
  { str = 'Don`t ask for creating FX routing',
    func =  function() conf.dontaskforcreatingrouting = math.abs(1-conf.dontaskforcreatingrouting)  end,
    state = conf.dontaskforcreatingrouting == 1,
  } ,       
 --[[ { str = 'Copy samples to project folder (render path otherwise) on drop',
    func =  function() conf.copy_src_media = math.abs(1-conf.copy_src_media)  end,
    state = conf.copy_src_media == 1,
  } ,             
  ]]
  { str = 'Auto close floating window',
    func =  function() conf.closefloat = math.abs(1-conf.closefloat)  end,
    state = conf.closefloat == 1,
  } ,    
  
  { str = 'Use custom FX chain for newly dragged samples '..conf.draggedfile_fxchain..'|<',
    func =  function() 
              if conf.draggedfile_fxchain ~= '' then conf.draggedfile_fxchain = '' return end
              local retval, fp = GetUserFileNameForRead('', 'FX chain for newly dragged samples', 'RfxChain')
              if retval then 
                conf.draggedfile_fxchain =  fp
              end
            end,
    state = conf.draggedfile_fxchain ~= '',
  } ,   
  -- 
  { str = '>Global',  
    menu_inc = true},    
  { str = '>Prepare selected track MIDI input',  
    menu_inc = true}, 

  { str = 'Virtual keyboard',
    func = function() conf.prepareMIDI3 =0  end ,
    state = conf.prepareMIDI3 == 0},     
  { str = 'All inputs|<',
    func = function() conf.prepareMIDI3 = 1  end ,
    state = conf.prepareMIDI3 == 1},          
    
  { str = 'Layering mode: allow multiple samples per pad|<|',
    func = function() conf.allow_multiple_spls_per_pad = math.abs(1-conf.allow_multiple_spls_per_pad) end,
    state = conf.allow_multiple_spls_per_pad == 1, 
  } ,  
  
  { str = '>Project-related options',    
    menu_inc = true},
       
  { str = 'Set pin selected track as a parent track',
    func =  function() 
              if conf.pintrack == 0 then 
                local tr = GetSelectedTrack(0,0)
                local GUID =  GetTrackGUID( tr )
                SetProjExtState( 0, 'MPLRS5KMANAGE', 'PINNEDTR', GUID )
                conf.pintrack = math.abs(1-conf.pintrack) 
               else
                SetProjExtState( 0, 'MPLRS5KMANAGE', 'PINNEDTR', '' )
                conf.pintrack = math.abs(1-conf.pintrack)                 
              end
            end,
    state = conf.pintrack == 1,
  } ,  
  { str = 'Select pinned track: '..pinnedtr_str,
    func =  function() 
              if pinnedtr then SetOnlyTrackSelected( pinnedtr ) end
            end
  } , 
  { str = 'Clear/disable pinned track|<|',
    func =  function() 
              SetProjExtState( 0, 'MPLRS5KMANAGE', 'PINNEDTR', '' )
              conf.pintrack = 0
            end
  } ,    
  
  { str = '#Actions'
    },  --menu_inc = true
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
                  --msg(s_offs/src_len)
                  ExportItemToRS5K(data,conf,refresh,base_pitch + i-1,filepath, s_offs/src_len, (s_offs+it_len)/src_len)
                  ::skip_to_next_item::
                end
                
                reaper.Main_OnCommand(40006,0)--Item: Remove items      
              -- add MIDI
                if proceed_MIDI then ExportSelItemsToRs5k_AddMIDI(track, MIDI,base_pitch) end        
                reaper.Undo_EndBlock2( 0, 'Export selected items to RS5k instances', -1 )       
            end,
  } , 
  { str = 'Add RS5K_Manager_tracker.jsfx to first slot of parent track',
    func =  function()    
              if gmem_read then 
                local out_id = TrackFX_AddByName( data.parent_track, 'RS5K_Manager_tracker.jsfx', false, 1 )
                TrackFX_CopyToTrack(  data.parent_track, out_id,  data.parent_track, 0, true )
              end
            end
  },
    
    
    



  { str = 'Dock MPL RS5k manager',
    func = function() 
              if conf.dock > 0 then conf.dock = 0 else 
                if conf.lastdockID and conf.lastdockID > 0 then conf.dock = conf.lastdockID else conf.dock = 1  end
              end
              gfx.quit() 
              gfx.init('MPL RS5k manager '..conf.vrs,
                        conf.wind_w, 
                        conf.wind_h, 
                        conf.dock, conf.wind_x, conf.wind_y)
          end ,
    state = conf.dock > 0 }, 
                                                                           
}
)
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.GUI_onStart = true
                              refresh.data = true
                            end}  

  end  
  ----------------------------------------------------------------------------
  function  OBJ_GenMainControl(conf, obj, data, refresh, mouse)
      local keyareabut_h = (gfx.h -obj.kn_h-obj.samplename_h)/6
      
        obj._mode_fr = { clear = true,
                    x = 0,
                    y = obj.kn_h+obj.samplename_h,
                    w = obj.keycntrlarea_w,
                    h = keyareabut_h*2,
                    col = 'blue',
                    state = fale,
                    txt= '',
                    show = true,
                    is_but = true,
                    ignore_mouse = true,
                    fontsz = obj.GUI_fontsz2,
                    a_frame = 0.01} 
                          
        obj._mode_fr2 = { clear = true,
                    x = 0,
                    y = obj.kn_h+obj.samplename_h+keyareabut_h*2,
                    w = obj.keycntrlarea_w,
                    h = keyareabut_h*3,
                    col = 'green',
                    state = fale,
                    txt= '',
                    show = true,
                    is_but = true,
                    ignore_mouse = true,
                    fontsz = obj.GUI_fontsz2,
                    a_frame = 0.01}  

        obj._mode_fr3 = { clear = true,
                    x = 0,
                    y = obj.kn_h+obj.samplename_h+keyareabut_h*5,
                    w = obj.keycntrlarea_w,
                    h = keyareabut_h,
                    col = 'red',
                    state = fale,
                    txt= '',
                    show = true,
                    is_but = true,
                    ignore_mouse = true,
                    fontsz = obj.GUI_fontsz2,
                    a_frame = 0.01}  
                                          
       if conf.tab ==0 or conf.tab==1 then                
        obj.keys_octaveshiftL = { clear = true,
                    x = 0,
                    y = obj.kn_h+obj.samplename_h,
                    w = obj.keycntrlarea_w,
                    h = keyareabut_h,
                    col = 'white',
                    state = fale,
                    txt= '+1\noct',
                    show = true,
                    is_but = true,
                    mouse_overlay = true,
                    fontsz = obj.GUI_fontsz2,
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
                    y = obj.kn_h+obj.samplename_h + keyareabut_h,
                    w = obj.keycntrlarea_w,
                    h = keyareabut_h-1,
                    col = 'white',
                    state = fale,
                    txt= '-1\noct',
                    show = true,
                    is_but = true,
                    mouse_overlay = true,
                    fontsz = obj.GUI_fontsz2,
                    alpha_back = obj.it_alpha5,
                    a_frame = 0,
                    func =  function() 
                              conf.start_oct_shift = lim(conf.start_oct_shift - 1,-conf.oct_shift-1,10-conf.oct_shift)
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.data = true                           
                            end}  
        end           
        OBJ_Menu(conf, obj, data, refresh, mouse)

        local cymb_a = 0.2
        if conf.tab == 0 then cymb_a = 0.7 end        
        obj.pad_wind = { clear = true,
                    x = 0,
                    y = obj.kn_h+obj.samplename_h + keyareabut_h*2,
                    w = obj.keycntrlarea_w,
                    h =keyareabut_h,
                    cymb = 2,
                    cymb_a = cymb_a,
                    col = 'white',
                    txt= '',
                    show = true,
                    is_but = true,
                    mouse_overlay = true,
                    fontsz = obj.GUI_fontsz,
                    alpha_back = obj.it_alpha5 ,
                    a_frame = 0,
                    func =  function() 
                              conf.tab = 0
                              obj.window = 0
                              obj.current_WFkey = nil
                              obj.current_WFspl = nil
                              refresh.GUI_WF = true  
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.data = true                           
                            end,
                    --[[func_DC = function() 
                              conf.tab = 0
                              obj.window = 0
                              obj.current_WFkey = nil
                              obj.current_WFspl = nil
                              refresh.GUI_WF = true  
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.data = true                           
                            end]]}         
        
        local cymb_a = 0.2
        if conf.tab == 1 then cymb_a = 0.7 end
        obj.mixer = { clear = true,
                    x = 0,
                    y = obj.kn_h+obj.samplename_h + keyareabut_h*3,
                    w = obj.keycntrlarea_w,
                    h =keyareabut_h,
                    cymb = 0,
                    cymb_a = cymb_a,
                    col = 'white',
                    --txt= 'MIX',
                    show = true,
                    is_but = true,
                    mouse_overlay = true,
                    fontsz = obj.GUI_fontsz,
                    alpha_back = obj.it_alpha5 ,
                    a_frame = 0,
                    func =  function() 
                              conf.tab = 1
                              obj.window = 1
                              obj.current_WFkey = nil
                              obj.current_WFspl = nil
                              refresh.GUI_WF = true  
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.data = true                           
                            end,
                    func_DC = function() 
                              conf.tab = 1
                              obj.window = 1
                              obj.current_WFkey = nil
                              obj.current_WFspl = nil
                              refresh.GUI_WF = true  
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.data = true                           
                            end}

 
                            
         local cymb_a = 0.2
         if conf.tab == 2 then cymb_a = 0.7 end  
        obj.pat_wind = { clear = true,
                    x = 0,
                    y = obj.kn_h+obj.samplename_h + keyareabut_h*4,
                    w = obj.keycntrlarea_w,
                    h =keyareabut_h,
                    col = 'white',
                    cymb = 3,
                    cymb_a = cymb_a,                    
                    txt= '',
                    show = true,
                    is_but = true,
                    mouse_overlay = true,
                    fontsz = obj.GUI_fontsz,
                    alpha_back = obj.it_alpha5 ,
                    a_frame = 0,
                    func =  function() 
                              conf.tab = 2 
                              obj.window = 2
                              obj.current_WFkey = nil
                              obj.current_WFspl = nil
                              refresh.GUI_WF = true  
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.data = true                           
                            end,
                    func_DC = function() 
                              conf.tab = 2 
                              obj.window = 2
                              obj.current_WFkey = nil
                              obj.current_WFspl = nil
                              refresh.GUI_WF = true  
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.data = true                           
                            end,}                                
          obj.prepareMIDI = { clear = true,
                    x = 0,
                    y = obj.kn_h+obj.samplename_h + keyareabut_h*5,
                    w = obj.keycntrlarea_w,
                    h =keyareabut_h,
                    col = 'white',
                    cymb = 1,
                    cymb_a = obj.it_alpha6,
                    txt= '',
                    show = true,
                    is_but = true,
                    mouse_overlay = true,
                    fontsz = obj.GUI_fontsz,
                    alpha_back = obj.it_alpha5 ,
                    a_frame = 0,
                    func =  function() 
                              MIDI_prepare(data, conf, conf.prepareMIDI3)
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.data = true                           
                            end}  
                            
    if conf.tab ==2 then
      --[[obj.keys_octaveshiftL = { clear = true,
                  x = 0,
                  y = obj.kn_h+obj.samplename_h,
                  w = obj.keycntrlarea_w,
                  h = keyareabut_h*2-2,
                  col = 'white',
                  state = fale,
                  txt= 'PAT\n>',
                  show = true,
                  is_but = true,
                  mouse_overlay = true,
                  fontsz = obj.GUI_fontsz2,
                  alpha_back = obj.it_alpha5,
                  a_frame = 0,
                  func =  function() 
                            
                            refresh.conf = true 
                            refresh.GUI = true
                            refresh.data = true
                          end} ]]
  end                           
  end  
  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse, pat) 
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
    
    local min_w = 400
    local min_h = 200
    local reduced_view = gfx.h  <= min_h
    gfx.w  = math.max(min_w,gfx.w)
    gfx.h  = math.max(min_h,gfx.h)
    
    obj.kn_h = math.floor(56 *  lim(conf.GUI_ctrlscale, 0.5,3)) 
    obj.kn_w =  math.floor(42 *  lim(conf.GUI_ctrlscale, 0.5,3))
    obj.splctrl_butw = math.floor(60 *  lim(conf.GUI_ctrlscale, 0.5,3))
    obj.WF_h=obj.kn_h 
    obj.pat_area_w = gfx.w - obj.keycntrlarea_w   - obj.offs*2 - obj.scroll_w
    obj.pat_area_h = 25 -- ALL small KNOBS
    obj.key_w = math.max(100,math.floor(obj.pat_area_w * 0.2))
    obj.step_cnt_w = obj.pat_area_h
    
    OBJ_GenMainControl(conf, obj, data, refresh, mouse)
               
                                     
    if conf.tab == 0 then                
      OBJ_GenKeys(conf, obj, data, refresh, mouse)
      OBJ_GenKeys_splCtrl(conf, obj, data, refresh, mouse)
     elseif conf.tab == 1 then -- mixer
     
     
     obj.info_line_mixer = { clear = true,
           x = obj.keycntrlarea_w +1 ,
           y = gfx.h - obj.samplename_h + obj.offs ,
           w = gfx.w- obj.keycntrlarea_w -2,
           h = obj.samplename_h,
           col = 'white',
           txt = '',
           aligh_txt = 1,
           show = true,
           fontsz = obj.GUI_fontsz3,
           alpha_back = 0 ,
           }
           
      local x_out = OBJ_GenKeysMixer(conf, obj, data, refresh, mouse)
      OBJ_GenMixer_FX(conf, obj, data, refresh, mouse, x_out)
      --OBJ_GenKeys_GlobalCtrl(conf, obj, data, refresh, mouse)
      
     elseif conf.tab == 2 then
            
      OBJ_GenPat_Ctrl(conf, obj, data, refresh, mouse, pat)
      OBJ_GenPat_Keys(conf, obj, data, refresh, mouse, pat)
      local ret = OBJ_GenPatCheck(conf, obj, data, refresh, mouse, pat) 
      if ret then OBJ_GenPat_Steps(conf, obj, data, refresh, mouse, pat)  end
      OBJ_GenPat_Scroll(conf, obj, data, refresh, mouse, pat)
    end
    for key in pairs(obj) do if type(obj[key]) == 'table' then obj[key].context = key end end    
  end
        
  --------------------------------------------------- 
  function OBJ_GenMixer_FX(conf, obj, data, refresh, mouse, x_out)
    if obj.current_WFkey and data[obj.current_WFkey] and data[obj.current_WFkey].FXChaindata then
      
      local t = data[obj.current_WFkey].FXChaindata
      for i = 1, #t do
        local alpha_txt = 0.3
        if t[i].bypass == true then alpha_txt = 0.8 end
        obj['mixerfx_'..i] = 
                      { clear = true,
                        x = x_out+2,
                        y = obj.mixslot_h * (i-1)+obj.offs,
                        w = obj.mixslot_w,
                        h = obj.mixslot_h,
                        --col = col,
                        --colint = colint,
                        --state = 0,
                        txt= MPL_ReduceFXname(t[i].fxname),
                        alpha_txt=alpha_txt,
                       -- limtxtw = key_w - obj.fx_rect_side,
                        --limtxtw_vert = limtxtw_vert,
                        --vertical_txt = verttxt,
                        show = true,
                        is_but = true,
                        alpha_back = obj.it_alpha1,
                        aligh_txt = 1,
                        fontsz = obj.GUI_fontsz2,
                        func =  function() 
                                  TrackFX_Show( t[i].tr_ptr, t[i].id, 3 )
                                end,
                        func_trigCtrl =  function() 
                                  TrackFX_Show( t[i].tr_ptr, t[i].id, 1 )
                                end,
                        func_shiftL = function() 
                                        local state_byp = TrackFX_GetEnabled( t[i].tr_ptr, t[i].id )
                                        reaper.TrackFX_SetEnabled( t[i].tr_ptr, t[i].id, not state_byp )
                                        refresh.data = true
                                        refresh.GUI = true
                                      end,
                        func_trigAlt = function() 
                                        TrackFX_Delete( t[i].tr_ptr, t[i].id )
                                        refresh.data = true
                                        refresh.GUI = true
                                      end,}       
      end
    end
  end
  --------------------------------------------------- 
  function OBJ_GenPat_Scroll(conf, obj, data, refresh, mouse, pat)
    local pat_scroll_h = gfx.h - (obj.samplename_h + obj.kn_h)
        obj.scroll_pat = 
                      { clear = true,
                        x = gfx.w -obj.scroll_w -1,
                        y = obj.samplename_h + obj.kn_h,
                        w = obj.scroll_w,
                        h = pat_scroll_h,
                        txt = '',
                        state = 1,
                        show = true,
                        is_but = true,
                        ignore_mouse = true,
                        alpha_back = 0.05,
                        fontsz = conf.GUI_padfontsz,--obj.GUI_fontsz2,  
                      }
        obj.scroll_pat_handle = 
                      { clear = true,
                        x = gfx.w -obj.scroll_w -1,
                        y = obj.samplename_h + obj.kn_h + obj.scroll_val * (pat_scroll_h -obj.scroll_w) ,
                        w = obj.scroll_w,
                        h = obj.scroll_w,
                        txt = '',
                        col = 'green',
                        show = true,
                        is_but = true,
                        alpha_back = 0.4,
                        fontsz = conf.GUI_padfontsz,--obj.GUI_fontsz2, 
                      func =  function() 
                        mouse.context_latch_val = obj.scroll_val
                      end,
              func_LD2 = function ()
                
                          if not mouse.context_latch_val then return end
                          local dragratio = 1
                          local out_val = lim(mouse.context_latch_val + (mouse.dy/(pat_scroll_h -obj.scroll_w))*dragratio, 0, 1)
                          if not out_val then return end
                          obj.scroll_val = out_val
                          refresh.GUI = true 
                        end,             
                         
                      }                      
  end
  ---------------------------------------------------  
  function OBJ_GenPatCheck(conf, obj, data, refresh, mouse, pat) 
    local ret, poolGUID, take_name, take, item = Pattern_GetSrcData(obj)
    pat.name = '(take not selected)'
    for key in pairs(pat) do if tonumber(key) then pat[key] = nil end end
    if ret then 
      pat.poolGUID=poolGUID
      pat.name = take_name
      local item_pos =  reaper.GetMediaItemInfo_Value( item, 'D_POSITION'  )
      local item_len =  reaper.GetMediaItemInfo_Value( item, 'D_LENGTH'  )       
      obj.pat_item_pos_sec = item_pos
      obj.pat_item_len_sec = item_len
      obj._patname.txt = pat.name
      Pattern_Parse(conf, pat, poolGUID, take_name) 
      return true
    end
  end
  ---------------------------------------------------        
  function OBJ_GenPat_Steps(conf, obj, data, refresh, mouse, pat) 
  
    local key_w0 = obj.key_w
    if conf.key_width_override > 0 then key_w0 = conf.key_width_override end
    
    local back_w = (obj.pat_area_w-obj.step_cnt_w*2-obj.offs*2-key_w0)/4
    local back_w_line = 1
    local alpha_back = 0.3
    
        
    for i = 1, 5 do
        obj['steps_back_beat'..i] = 
                      { clear = true,
                        x = obj.keycntrlarea_w + obj.offs*2 + key_w0 + back_w*(i-1)-1,
                        y = obj.samplename_h + obj.kn_h,
                        w = back_w_line,
                        h = gfx.h - obj.samplename_h + obj.kn_h,
                        txt = '',
                        show = true,
                        is_but = true,
                        ignore_mouse = true,
                        alpha_back = alpha_back,
                      }  
    end
                                              
    local key_ypos = obj.samplename_h + obj.kn_h- obj.scroll_val * obj.pattern_com_h
    local key_w = key_w0--math.max(100,math.floor(obj.pat_area_w * 0.2))
    local pat_w = gfx.w - key_w - obj.keycntrlarea_w - obj.offs*4 - obj.step_cnt_w*2 - obj.scroll_w
    for note = 0, 127 do
      if data[note] or pat[note] then
        local col
        local colint
        if data[note] then 
          col = 'green'
          if data[note][1].src_track_col then  colint = data[note][1].src_track_col   end  
         else
          col = 'grey'
        end
        
        local step = conf.def_steps
        if pat[note] and pat[note].cnt_steps then
          step = pat[note].cnt_steps
        end
        if key_ypos >= obj.samplename_h + obj.kn_h - 1  then
          obj['keys_p'..note..'patcntstep'] = 
                        { clear = true,
                          x = obj.keycntrlarea_w + obj.offs*3 + key_w + pat_w -1 ,
                          y = key_ypos,
                          w = obj.step_cnt_w,
                          h = obj.pat_area_h,
                          txt = step,
                          col = col,
                          colint = colint,
                          state = 1,
                          show = true,
                          is_but = true,
                          alpha_back = 0.2,
                          fontsz = conf.GUI_padfontsz,--obj.GUI_fontsz2,
                          func =  function() 
                                    mouse.context_latch_val = step
                                  end,
                          func_LD2 = function ()
                            if not mouse.context_latch_val then return end
                            local dragratio = 10
                            local out_val = lim(mouse.context_latch_val - mouse.dy/dragratio, 1, 32)
                            if not out_val then return end
                            if not pat[note] then pat[note] = {} end
                            pat[note].cnt_steps  = math.floor(out_val)
                            local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                            Pattern_Commit(conf, pat, poolGUID, take_ptr)
                            Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                            refresh.data = true
                            refresh.GUI = true 
                          end,  
              func_ResetVal = function ()
                          if not pat[note] then pat[note] = {} end
                          pat[note].cnt_steps  = conf.def_steps
                          local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                            Pattern_Commit(conf, pat, poolGUID, take_ptr)
                            Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)                          
                          refresh.GUI = true 
                          refresh.data = true 
                        end ,
              func_R =       function()
                                local def_cnt
                                if not pat or not pat[note] or not pat[note].cnt_steps then def_cnt = 16 else def_cnt = pat[note].cnt_steps end
                                local retval, retvals_csv = GetUserInputs( conf.mb_title, 1, 'Steps count', def_cnt )
                                if not retval or not tonumber(retvals_csv) then return end
                                local out_cnt = lim(tonumber(retvals_csv), 1, 32)
                                if not pat[note] then pat[note] = {} end
                                pat[note].cnt_steps  = out_cnt
                                local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                Pattern_Commit(conf, pat, poolGUID, take_ptr)
                                Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)                          
                                refresh.GUI = true 
                                refresh.data = true                                 
                              end} 
        local swing = conf.def_swing
        if pat[note] and pat[note].swing then swing = pat[note].swing  end                          
          obj['keys_p'..note..'patsw'] = 
                        { clear = true,
                          x = obj.keycntrlarea_w + obj.offs*3 + key_w + pat_w -1 +obj.step_cnt_w,
                          y = key_ypos,
                          w = obj.step_cnt_w,
                          h = obj.pat_area_h,
                          --txt = math.floor(swing*100)..'%',
                          is_knob = true,
                          is_centered_knob = true,
                          knob_y_shift = 4,
                          val = (swing+1)/2,
                          col = col,
                          colint = colint,
                          state = 1,
                          show = true,
                          alpha_back = 0.2,
                          fontsz = obj.GUI_fontsz4,--conf.GUI_padfontsz,
                          func =  function() 
                                    mouse.context_latch_val = swing
                                  end,
                          func_LD2 = function ()
                            if not mouse.context_latch_val then return end
                            local dragratio = 100
                            local out_val = lim(mouse.context_latch_val - mouse.dy/dragratio, -0.8, 0.8)
                            if not out_val then return end
                            if not pat[note] then pat[note] = {} end
                            pat[note].swing  = math.floor(out_val*100)/100
                            local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                            Pattern_Commit(conf, pat, poolGUID, take_ptr)
                            Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                            refresh.data = true
                            refresh.GUI = true 
                          end, 
                          func_ResetVal = function ()
                            if not pat[note] then pat[note] = {} end
                            pat[note].swing  = 0
                            local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                            Pattern_Commit(conf, pat, poolGUID, take_ptr)
                            Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                            refresh.data = true
                            refresh.GUI = true 
                          end,  }              
        
          local pat_w_step = pat_w / step--math.floor(pat_w / step)
          for i_step = 1, step do
            local step_exist = false 
            local vel = 0       
            if pat[note] and pat[note].steps and pat[note].steps[i_step] and pat[note].steps[i_step].active and pat[note].steps[i_step].active ==1  then 
              vel = pat[note].steps[i_step].vel
              step_exist = true
            end
            local x_st = obj.keycntrlarea_w + obj.offs*2 + key_w0 + pat_w_step * (i_step-1)
            local w_st = pat_w_step
            if pat[note] and pat[note].swing and  pat[note].swing ~= 0 then
              local x_shift = math.floor(pat_w_step * pat[note].swing * 0.5 )
              if i_step%2 ==0 then 
                x_st = x_st + x_shift
                w_st = pat_w_step - x_shift
               else
                w_st = pat_w_step + x_shift
              end
            end
            if x_st+ w_st > obj.keycntrlarea_w + obj.offs*3 + key_w + pat_w then w_st = obj.keycntrlarea_w + obj.offs*2 + key_w + pat_w- x_st end
            obj['keys_p'..note..'pat'..i_step] = 
                          { clear = true,
                            x = x_st,
                            y = key_ypos,
                            w = w_st-1,
                            h = obj.pat_area_h,
                            col = col,
                            colint = colint,
                            state = 1,
                            limtxtw = obj.fx_rect_side,
                            is_step = true,
                            val = vel/127,
                            --vertical_txt = fn,
                            linked_note = note,
                            show = true,
                            is_but = true,
                            alpha_back = 0.4,
                            aligh_txt = 5,
                            fontsz = conf.GUI_padfontsz,--obj.GUI_fontsz2,
                            
                            func =  function() 
                                      local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                      if ret then 
                                        if not (pat[note] and pat[note].steps and pat[note].steps[i_step]) then 
                                          Pattern_Change(conf, pat, poolGUID, note, i_step, 120, 1)
                                         else
                                          local act_state = pat[note].steps[i_step].active
                                          pat[note].steps[i_step].active = math.abs(1-act_state)
                                          local vel = nil
                                          if act_state == 0 and pat[note].steps[i_step].vel == 0 then vel = 120 end 
                                          Pattern_Change(conf, pat, poolGUID, note, i_step, vel, pat[note].steps[i_step].active)
                                        end
                                        Pattern_Commit(conf, pat, poolGUID, take_ptr)
                                        Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                                        refresh.GUI = true  
                                      end   
                                    end,
                                    
                            func_shiftL =  function() 
                                      local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                      if ret then 
                                        if not (pat[note] and pat[note].steps and pat[note].steps[i_step]) then 
                                          G_act_state = 1
                                         else
                                          --G_act_state = math.abs(1-pat[note].steps[i_step].active)
                                          if pat[note].steps[i_step].active == 0 or pat[note].steps[i_step].vel == 0 then G_act_state = 1 else G_act_state = 0 end
                                        end
                                      end   
                                    end,
                            func_context_shift = function() 
                                      if not G_act_state then return end
                                      local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                      if ret then 
                                        if not (pat[note] and pat[note].steps and pat[note].steps[i_step]) then 
                                          Pattern_Change(conf, pat, poolGUID, note, i_step, 120, G_act_state)
                                         else
                                          pat[note].steps[i_step].active = G_act_state
                                          local vel = nil
                                          if act_state == 0 and pat[note].steps[i_step].vel == 0 then vel = 120 end 
                                          Pattern_Change(conf, pat, poolGUID, note, i_step, vel, pat[note].steps[i_step].active)
                                        end
                                        Pattern_Commit(conf, pat, poolGUID, take_ptr)
                                        Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                                        refresh.GUI = true  
                                      end   
                                    end,                                                              
                            funcLD2 =  function() 
                                      local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                      if ret then 
                                        if not (pat[note] and pat[note].steps and pat[note].steps[i_step]) then 
                                          Pattern_Change(conf, pat, poolGUID, note, i_step, 120, 1)
                                         else
                                          local act_state = pat[note].steps[i_step].active
                                          pat[note].steps[i_step].active = math.abs(1-act_state)
                                          local vel = nil
                                          if act_state == 0 and pat[note].steps[i_step].vel == 0 then vel = 120 end 
                                          Pattern_Change(conf, pat, poolGUID, note, i_step, vel, pat[note].steps[i_step].active)
                                        end
                                        Pattern_Commit(conf, pat, poolGUID, take_ptr)
                                        Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                                        refresh.GUI = true  
                                      end   
                                    end,
                                    
                                                                        
                          func_trigCtrl = function() 
                                            local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                            if ret and (pat[note] and pat[note].steps and pat[note].steps[i_step] and pat[note].steps[i_step].vel) then 
                                              mouse.context_latch_val = pat[note].steps[i_step].vel end
                                          end,
                          func_ctrlLD = function ()
                            local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                            if not ret or not mouse.context_latch_val then return end
                            local dragratio = 1
                            local out_val = lim(mouse.context_latch_val - mouse.dy/dragratio, 5, 120)
                            if not out_val then return end
                            if not pat[note] then pat[note] = {} end
                            Pattern_Change(conf, pat, poolGUID, note, i_step, math.floor(out_val))
                            Pattern_Commit(conf, pat, poolGUID, take_ptr)
                            Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                            refresh.GUI = true   
                          end,                                     }
          end           
          
        end
        key_ypos = key_ypos + 1 +obj.pat_area_h
      end
    end  
  end
  ---------------------------------------------------
  function OBJ_GenPat_Keys(conf, obj, data, refresh, mouse,pat) 
    local pattern_h = 0
    local scroll_y_offs = 0
    if obj.pattern_com_h then scroll_y_offs =  obj.scroll_val * obj.pattern_com_h end
    local key_ypos = obj.samplename_h + obj.kn_h
    local key_w0 = obj.key_w
    if conf.key_width_override > 0 then key_w0 = conf.key_width_override end
    
    for note = 0, 127 do
      if data[note] or pat[note] then
      
        local col
        local colint
        if data[note] then 
          col = 'green'
          if data[note][1].src_track_col then  colint = data[note][1].src_track_col   end  
         else
          col = 'grey'
        end
        
        local a_frame,selection_tri = 0
        if obj.current_WFkey and note == obj.current_WFkey then
          a_frame = obj.sel_key_frame
          selection_tri = true
        end
      
        local txt = BuildKeyName(conf, data, note, conf.key_names_pat)
        if key_ypos-scroll_y_offs >= obj.samplename_h + obj.kn_h - 1  then
            obj['keys_p'..note] = 
                      { clear = true,
                        x = obj.keycntrlarea_w + obj.offs,
                        y = key_ypos-scroll_y_offs,
                        w = key_w0,
                        h = obj.pat_area_h,
                        col = col,
                        colint = colint,
                        txt= txt,
                        limtxtw = obj.fx_rect_side,
                        --vertical_txt = fn,
                        linked_note = note,
                        show = true,
                        is_but = true,
                        alpha_back = 0.6,
                        aligh_txt = 5,
                        a_frame=a_frame,
                        selection_tri = selection_tri,
                        selection_tri_vertpos = true,
                        fontsz = conf.GUI_padfontsz,--obj.GUI_fontsz2,
                        func =  function() 
                                  if not data.hasanydata then return end
                                  data.current_spl_peaks = nil
                                  if conf.keypreview == 1 then  StuffMIDIMessage( 0, '0x9'..string.format("%x", 0), note,100) end                                  
                                  if obj.current_WFkey ~= note then 
                                    obj.current_WFspl = 1                                   
                                    obj.current_WFkey = note
                                  end
                                  
                                  refresh.GUI_WF = true  
                                  refresh.GUI = true     
                                end,
                        func_R =  function ()
                                    if not data[note] then return end
                                    Menu(mouse, { { str =   'Float linked FX',
                                                    func =  function()
                                                              if data[note] then
                                                                for spl = 1, #data[note] do
                                                                  -- TrackFX_SetOpen(  data[note][1].src_track, data[note][1].rs5k_pos, true )
                                                                  TrackFX_Show( data[note][spl].src_track, data[note][spl].rs5k_pos,3 )
                                                                end
                                                              end
                                                            end},
                                                    { str =   'Show linked FX chain',
                                                    func =  function()
                                                              if data[note] then
                                                                for spl = 1, #data[note] do
                                                                  -- TrackFX_SetOpen(  data[note][1].src_track, data[note][1].rs5k_pos, true )
                                                                  TrackFX_Show( data[note][spl].src_track, data[note][spl].rs5k_pos,1 )
                                                                end
                                                              end
                                                            end},                                                            
                                                  { str =   'Rename linked MIDI note',
                                                    func =  function()
                                                              local MIDI_name = GetTrackMIDINoteNameEx( 0, data[note][1].src_track, note, 1)
                                                              if not MIDI_name then MIDI_name = '' end
                                                              local ret, MIDI_name_ret = reaper.GetUserInputs( conf.scr_title, 1, 'Rename MIDI note,extrawidth=200', MIDI_name )
                                                              if ret then
                                                                SetTrackMIDINoteNameEx( 0, data[note][1].src_track, note, 0, MIDI_name_ret)
                                                                SetTrackMIDINoteNameEx( 0, data.parent_track, note, 0, MIDI_name_ret)
                                                              end
                                                            end},
                                                  { str =   'Remove pad content',
                                                    func =  function()
                                                              for spl = #data[note], 1, -1 do
                                                                SNM_MoveOrRemoveTrackFX( data[note][spl].src_track, data[note][spl].rs5k_pos, 0 )
                                                              end
                                                            end},        
                                                                                                                
                     
                                                })
                                    obj.current_WFkey = nil
                                    obj.current_WFspl = nil
                                    refresh.GUI_WF = true  
                                    refresh.GUI = true  
                                    refresh.data = true                                  
                                  end,  }
          end                        
        key_ypos = key_ypos + 1 +obj.pat_area_h
      end
    end
    obj.pattern_com_h =        key_ypos-obj.pat_area_h - obj.samplename_h - obj.kn_h
  end
  ---------------------------------------------------  
  function OBJ_GenPat_Ctrl(conf, obj, data, refresh, mouse,pat)

      obj._patname = { clear = true,
              x = obj.keycntrlarea_w  ,
              y = obj.kn_h,--gfx.h - obj.WF_h-obj.key_h,
              w = gfx.w -obj.keycntrlarea_w,
              h = obj.samplename_h,
              col = 'white',
              state = 0,
              txt= pat.name,
              aligh_txt = 0,
              show = true,
              is_but = true,
              fontsz = conf.GUI_padfontsz,
              alpha_back =0,
              func = function()
                        Pattern_EnumList(conf, obj, data, refresh, mouse, pat)
                      end}
                      
      local mode = 'Selected'
      if conf.patctrl_mode == 1 then mode = 'All' end
      local ctrl_offsy = 2
      obj.pat_editmode = { clear = true,
                    x = obj.keycntrlarea_w   + obj.offs*2,
                    y = ctrl_offsy,
                    w = obj.kn_w,
                    h =obj.kn_h,
                    col = 'white',
                    txt= mode,
                    aligh_txt = 16,
                    show = true,
                    is_selector = true,
                    val = conf.patctrl_mode,
                    val_cnt = 2,
                    --mouse_overlay = true,
                    --ignore_mouse = true,
                    fontsz = obj.GUI_fontsz4,
                    alpha_back = obj.it_alpha5 ,
                    a_frame = 0.1,
                    func = function()
                              conf.patctrl_mode = math.abs(1-conf.patctrl_mode)
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.GUI_onStart = true
                              refresh.data = true
                            end }         
      obj.pat_randgate = { clear = true,
                    x = obj.keycntrlarea_w   + obj.offs*4+obj.kn_w,
                    y = ctrl_offsy,
                    w = obj.kn_w*1.5,
                    h =obj.kn_h/2-1,
                    col = 'white',
                    txt= 'rand. Gate',
                    aligh_txt = 0,
                    show = true,
                    --mouse_overlay = true,
                    --ignore_mouse = true,
                    fontsz = obj.GUI_fontsz4,
                    alpha_back = obj.it_alpha5 ,
                    a_frame = 0.1,
                    func = function() 
                              if (conf.patctrl_mode ==0 and obj.current_WFkey) or conf.patctrl_mode ==1 then
                                local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                if ret then 
                                  if conf.patctrl_mode ==0 and obj.current_WFkey then
                                    if not pat[obj.current_WFkey] then Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, 0, 0) end
                                    for i = 1, pat[obj.current_WFkey].cnt_steps do
                                      --msg(math.floor(math.random()*127))
                                      local gate = math_q(math.random()*(conf.randgateprob+0.5))
                                      Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, i, _, gate)
                                    end
                                  
                                   else
                                    for note in pairs(pat) do
                                      if tonumber(note) then
                                        for i = 1, pat[note].cnt_steps do
                                          local gate = math_q(math.random()*(conf.randgateprob+0.5))
                                          Pattern_Change(conf, pat, poolGUID, note, i, _, gate)
                                        end
                                      end   
                                    end                                 
                                  end
                                  Pattern_Commit(conf, pat, poolGUID, take_ptr)
                                  Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                                  refresh.GUI = true  
                                  refresh.data = true
                                end   
                              end
                            end                    }   
          obj.pat_randgateprob = 
                        { clear = true,
                          x = obj.keycntrlarea_w   + obj.offs*4+obj.kn_w*2.5,
                          y = ctrl_offsy,
                          w = obj.kn_w*0.7,
                          h =obj.kn_h/2-1,
                          --txt = math.floor(swing*100)..'%',
                          is_knob = true,
                          col = 'white',
                          knob_y_shift = 5,
                          val = conf.randgateprob,
                          state = 1,
                          show = true,
                          alpha_back = 0.2,
                          fontsz = obj.GUI_fontsz4,--conf.GUI_padfontsz,
                          func =  function() 
                                    mouse.context_latch_val = conf.randgateprob
                                  end,
                          func_LD2 = function ()
                            if not mouse.context_latch_val then return end
                            local dragratio = 100
                            local out_val = lim(mouse.context_latch_val - mouse.dy/dragratio, 0, 1)
                            conf.randgateprob = out_val
                            refresh.GUI = true 
                          end, 
                          func_trigAlt = function ()
                            conf.randgateprob = 0.5
                            refresh.GUI = true 
                          end,  
                          func_onrelease = function()
                                            refresh.conf = true
                                          end}                                          
      obj.pat_randvel = { clear = true,
                    x =obj.keycntrlarea_w   + obj.offs*4+obj.kn_w,
                    y = ctrl_offsy+obj.kn_h/2,
                    w = obj.kn_w*1.5,
                    h =obj.kn_h/2,
                    col = 'white',
                    txt= 'rand. Vel',
                    aligh_txt = 0,
                    show = true,
                    --mouse_overlay = true,
                    --ignore_mouse = true,
                    fontsz = obj.GUI_fontsz4,
                    alpha_back = obj.it_alpha5 ,
                    a_frame = 0.1,
                    func = function() 
                              if (conf.patctrl_mode ==0 and obj.current_WFkey) or conf.patctrl_mode ==1 then
                                local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                if ret then 
                                  if conf.patctrl_mode ==0 and obj.current_WFkey then
                                    if not pat[obj.current_WFkey] then Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, 0, 0) end
                                    for i = 1, pat[obj.current_WFkey].cnt_steps do
                                      if pat[obj.current_WFkey].steps[i] and pat[obj.current_WFkey].steps[i].active and pat[obj.current_WFkey].steps[i].active ==1 then 
                                        local val = math.random()*(conf.randvel2-conf.randvel1) + conf.randvel1
                                        Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, i, lim(math.floor(val*127), 1, 127))
                                      end
                                    end
                                   else
                                    for note in pairs(pat) do
                                      if tonumber(note) then
                                        for i = 1, pat[note].cnt_steps do
                                          if pat[note].steps and pat[note].steps[i] and pat[note].steps[i].active and pat[note].steps[i].active == 1  then 
                                            local val = math.random()*(conf.randvel2-conf.randvel1) + conf.randvel1
                                            Pattern_Change(conf, pat, poolGUID, note, i, lim(math.floor(val*127), 1, 127))
                                          end
                                        end
                                      end   
                                    end                                 
                                  end
                                  Pattern_Commit(conf, pat, poolGUID, take_ptr)
                                  Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                                  refresh.GUI = true 
                                  refresh.data = true 
                                end   
                              end
                            end                    }    
      local rvctrlx = obj.keycntrlarea_w   + obj.offs*4+obj.kn_w*2.5
      local rvctrly = ctrl_offsy+obj.kn_h/2
      local rvctrlw = obj.kn_w*0.7
      local rvctrlh = obj.kn_h/2
      obj.pat_randvelctrl = { clear = true,
                    x = rvctrlx,
                    y = rvctrly,
                    w = rvctrlw,
                    h = rvctrlh,
                    col = 'white',
                    txt= '',
                    aligh_txt = 0,
                    show = true,
                    --mouse_overlay = true,
                    --ignore_mouse = true,
                    fontsz = obj.GUI_fontsz4,
                    alpha_back = obj.it_alpha5 ,
                    func = function() 
                              mouse.context_latch_t = {conf.randvel1, conf.randvel2}
                            end,
                          func_LD2 = function ()
                            if not mouse.context_latch_t then return end
                            local dragratio = 100
                            local out_val1 = lim(mouse.context_latch_t[1] + mouse.dx/dragratio)
                            local out_val2 = lim(mouse.context_latch_t[2] - mouse.dy/dragratio)
                            conf.randvel1 = math.min(out_val1, out_val2)
                            conf.randvel2 = math.max(out_val1, out_val2)
                            refresh.GUI = true 
                          end, 
                          func_trigAlt = function ()
                            conf.randvel1 = 0
                            conf.randvel2 = 1
                            refresh.GUI = true 
                          end,  
                          func_onrelease = function()
                                            refresh.conf = true
                                          end}                              
      obj.pat_randvelrect = { clear = true,
                    x = rvctrlx + rvctrlw*conf.randvel1,
                    y = rvctrly,
                    w = rvctrlw*(conf.randvel2 - conf.randvel1),
                    h = rvctrlh,
                    col = 'white',
                    txt= '',
                    aligh_txt = 0,
                    show = true,
                    --mouse_overlay = true,
                    --ignore_mouse = true,
                    fontsz = obj.GUI_fontsz4,
                    alpha_back = 0.7 }   
      obj.pat_shiftl = { clear = true,
                    x = obj.keycntrlarea_w   + obj.offs*8+obj.kn_w*3,
                    y = ctrl_offsy,
                    w = obj.kn_w,
                    h =obj.kn_h/2-1,
                    col = 'white',
                    txt= '<- Shift',
                    aligh_txt = 0,
                    show = true,
                    --mouse_overlay = true,
                    --ignore_mouse = true,
                    fontsz = obj.GUI_fontsz4,
                    alpha_back = obj.it_alpha5 ,
                    a_frame = 0.1,
                    func = function() 
                              if (conf.patctrl_mode ==0 and obj.current_WFkey) or conf.patctrl_mode ==1 then
                                local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                if ret then 
                                  if conf.patctrl_mode ==0 and obj.current_WFkey then
                                    if not pat[obj.current_WFkey] then Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, 0, 0) end
                                    local t = {}
                                    for i = 1, pat[obj.current_WFkey].cnt_steps do 
                                      t[i] = CopyTable(pat[obj.current_WFkey].steps[i]) 
                                      if not t[i] then t[i] = Pattern_StepDefaults() end
                                    end
                                    for i = 1, pat[obj.current_WFkey].cnt_steps-1 do Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, i, t[i+1].vel, t[i+1].active) end
                                    Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, pat[obj.current_WFkey].cnt_steps, t[1].vel, t[1].active)
                                   else
                                    for note in pairs(pat) do
                                      if tonumber(note) then
                                        local t = {}
                                        for i = 1, pat[note].cnt_steps do 
                                          t[i] = CopyTable(pat[note].steps[i]) 
                                          if not t[i] then t[i] = Pattern_StepDefaults() end
                                        end  
                                        for i = 1, pat[note].cnt_steps-1 do Pattern_Change(conf, pat, poolGUID, note, i,  t[i+1].vel, t[i+1].active) end                                        
                                        Pattern_Change(conf, pat, poolGUID, note, pat[note].cnt_steps, t[1].vel, t[1].active)
                                      end   
                                    end                                 
                                  end
                                  Pattern_Commit(conf, pat, poolGUID, take_ptr)
                                  Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                                  refresh.GUI = true  
                                  refresh.data = true
                                end   
                              end
                            end                    }  
      obj.pat_shiftr = { clear = true,
                    x = obj.keycntrlarea_w   + obj.offs*8+obj.kn_w*4+1,
                    y =ctrl_offsy,
                    w = obj.kn_w,
                    h =obj.kn_h/2-1,
                    col = 'white',
                    txt= 'Shift ->',
                    aligh_txt = 0,
                    show = true,
                    --mouse_overlay = true,
                    --ignore_mouse = true,
                    fontsz = obj.GUI_fontsz4,
                    alpha_back = obj.it_alpha5 ,
                    a_frame = 0.1,
                    func = function() 
                              if (conf.patctrl_mode ==0 and obj.current_WFkey) or conf.patctrl_mode ==1 then
                                local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                if ret then 
                                  if conf.patctrl_mode ==0 and obj.current_WFkey then
                                    if not pat[obj.current_WFkey] then Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, 0, 0) end
                                     t = {}
                                    for i = 1, pat[obj.current_WFkey].cnt_steps do 
                                      t[i] = CopyTable(pat[obj.current_WFkey].steps[i]) 
                                      if not t[i] then t[i] = Pattern_StepDefaults() end
                                    end  
                                    for i = 2, pat[obj.current_WFkey].cnt_steps do Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, i,  t[i-1].vel, t[i-1].active) end 
                                    Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, 1, t[pat[obj.current_WFkey].cnt_steps].vel, t[pat[obj.current_WFkey].cnt_steps].active)
                                   else
                                    for note in pairs(pat) do
                                      if tonumber(note) then
                                        local t = {}
                                        for i = 1, pat[note].cnt_steps do 
                                          t[i] = CopyTable(pat[note].steps[i]) 
                                          if not t[i] then t[i] = Pattern_StepDefaults() end
                                        end  
                                        for i = 2, pat[note].cnt_steps do Pattern_Change(conf, pat, poolGUID, note, i,  t[i-1].vel, t[i-1].active) end                                        
                                        Pattern_Change(conf, pat, poolGUID, note, 1, t[pat[note].cnt_steps].vel, t[pat[note].cnt_steps].active)                                        
                                      end   
                                    end                                 
                                  end
                                  Pattern_Commit(conf, pat, poolGUID, take_ptr)
                                  Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                                  refresh.GUI = true  
                                  refresh.data = true
                                end   
                              end
                            end                    }  
      obj.pat_clear = { clear = true,
                    x = obj.keycntrlarea_w   + obj.offs*8+obj.kn_w*3,
                    y = ctrl_offsy + obj.kn_h/2,
                    w = obj.kn_w*2+1,
                    h =obj.kn_h/2,
                    col = 'white',
                    txt= 'Clear',
                    aligh_txt = 0,
                    show = true,
                    --mouse_overlay = true,
                    --ignore_mouse = true,
                    fontsz = obj.GUI_fontsz4,
                    alpha_back = obj.it_alpha5 ,
                    a_frame = 0.1,
                    func = function() 
                              if (conf.patctrl_mode ==0 and obj.current_WFkey) or conf.patctrl_mode ==1 then
                                local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                if ret then 
                                  if conf.patctrl_mode ==0 and obj.current_WFkey then
                                    if not pat[obj.current_WFkey] then Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, 0, 0) end
                                    local t = {}
                                    for i = 1, pat[obj.current_WFkey].cnt_steps do
                                      Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, i, nil, 0)
                                    end
                                  
                                   else
                                    for note in pairs(pat) do
                                      if tonumber(note) then
                                        local t = {}
                                        for i = 1, pat[note].cnt_steps do
                                          Pattern_Change(conf, pat, poolGUID, note, i, nil, 0)
                                        end                                        
                                      end   
                                    end                                 
                                  end
                                  Pattern_Commit(conf, pat, poolGUID, take_ptr)
                                  Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                                  
                                  refresh.GUI = true  
                                  
                                  refresh.data = true
                                end   
                              end
                            end                    }  
      obj.pat_fill2 = { clear = true,
                    x = obj.keycntrlarea_w   + obj.offs*11+obj.kn_w*5,
                    y =ctrl_offsy,
                    w = obj.kn_w*2,
                    h =obj.kn_h/2-1,
                    col = 'white',
                    txt= 'Fill every 2nd',
                    aligh_txt = 0,
                    show = true,
                    --mouse_overlay = true,
                    --ignore_mouse = true,
                    fontsz = obj.GUI_fontsz4,
                    alpha_back = obj.it_alpha5 ,
                    a_frame = 0.1,
                    func = function() 
                              if (conf.patctrl_mode ==0 and obj.current_WFkey) or conf.patctrl_mode ==1 then
                                local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                local vel = conf.def_velocity
                                if ret then 
                                  if conf.patctrl_mode ==0 and obj.current_WFkey then
                                    if not pat[obj.current_WFkey] then Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, 0, 0) end
                                    
                                    for i = 1, pat[obj.current_WFkey].cnt_steps do 
                                      local active = 0
                                      if i%2 == 1 then active = 1  end
                                      Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, i,  vel, active)
                                    end 
                                   else
                                    
                                    for note in pairs(data) do
                                      if tonumber(note) then 
                                        if not pat[note] then Pattern_Change(conf, pat, poolGUID, note, 0, 0) end 
                                        for i = 1, pat[note].cnt_steps do 
                                          local active = 0
                                          if i%2 == 1 then active = 1 end
                                          Pattern_Change(conf, pat, poolGUID, note, i,  vel, active)
                                        end                                        
                                      end   
                                    end                                 
                                  end
                                  Pattern_Commit(conf, pat, poolGUID, take_ptr)
                                  Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                                  refresh.GUI = true  
                                  refresh.data = true
                                end   
                              end
                            end                    }      
      obj.pat_fill4 = { clear = true,
                    x = obj.keycntrlarea_w   + obj.offs*11+obj.kn_w*5,
                    y =ctrl_offsy+obj.kn_h/2,
                    w = obj.kn_w*2,
                    h =obj.kn_h/2-1,
                    col = 'white',
                    txt= 'Fill every 4th',
                    aligh_txt = 0,
                    show = true,
                    --mouse_overlay = true,
                    --ignore_mouse = true,
                    fontsz = obj.GUI_fontsz4,
                    alpha_back = obj.it_alpha5 ,
                    a_frame = 0.1,
                    func = function() 
                              if (conf.patctrl_mode ==0 and obj.current_WFkey) or conf.patctrl_mode ==1 then
                                local vel = conf.def_velocity
                                local ret, poolGUID, take_name, take_ptr = Pattern_GetSrcData(obj)
                                if ret then 
                                  if conf.patctrl_mode ==0 and obj.current_WFkey then
                                    if not pat[obj.current_WFkey] then Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, 0, 0) end 
                                    for i = 1, pat[obj.current_WFkey].cnt_steps do 
                                      local active = 0
                                      if i%4 == 1 then active = 1 end
                                      Pattern_Change(conf, pat, poolGUID, obj.current_WFkey, i,  vel, active)
                                    end 
                                   else
                                    for note in pairs(data) do
                                      if tonumber(note) then 
                                        if not pat[note] then Pattern_Change(conf, pat, poolGUID, note, 0, 0) end 
                                        for i = 1, pat[note].cnt_steps do 
                                          local active = 0
                                          if i%4 == 1 then active = 1 end
                                          Pattern_Change(conf, pat, poolGUID, note, i,  vel, active)
                                        end                                        
                                      end   
                                    end                                 
                                  end
                                  Pattern_Commit(conf, pat, poolGUID, take_ptr)
                                  Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
                                  refresh.GUI = true  
                                  refresh.data = true
                                end   
                              end
                            end                    }                                                                                                                                                                                                                                                                                      
              
  end
  ---------------------------------------------------
  function OBJ_GenKeysMixer_Ctrl(conf, obj, data, refresh, mouse, cur_note, cur_spl, key_x, key_y, key_w, key_h)
        if (mouse.context_latch and mouse.context_latch == 'mix_splctrl_gain'..cur_note) or (mouse.context == 'mix_splctrl_gain'..cur_note and mouse.wheel_on_move) then 
          gain_txt  = data[cur_note][cur_spl].gain_dB..'dB' 
          is_knob = false  
         else   
          gain_txt = ''  
          is_knob = true
        end  
        obj['mix_splctrl_gain'..cur_note] = { clear = true,
              x = key_x + (key_w  - obj.pat_area_h) /2 -1,
              y = key_y + obj.pat_area_h,
              w = obj.pat_area_h,
              h = obj.pat_area_h,
              col = 'white',
              txt = '',
              aligh_txt = 16,
              show = true,
              is_knob = true,
              val = data[cur_note][1].gain / 2,
              fontsz = conf.GUI_splfontsz,
              alpha_back =0,
              func =  function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, -1):func() end,
              func_trigCtrl =   function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, -1):func() end,
              func_LD2 = function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_LD2() end,
              func_ctrlLD = function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_ctrlLD() end,
              func_wheel = function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_wheel() end,
              func_ResetVal = function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_ResetVal() end,
              func_mouseover = function() OBJ_KnobF_Gain(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_mouseover() end,
              }                      
        obj['mix_splctrl_pan'..cur_note] = { clear = true,
              x = key_x + (key_w  - obj.pat_area_h) /2-1 ,
              y = key_y + obj.pat_area_h*2,
              w = obj.pat_area_h,
              h = obj.pat_area_h,
              col = 'white',
              state = 0,
              txt= '',
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              is_centered_knob = true,
              val = data[cur_note][cur_spl].pan,
              fontsz = conf.GUI_splfontsz,
              alpha_back =0,
              func =  function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, -1):func() end,
              func_trigCtrl =   function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, -1):func() end,
              func_LD2 = function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_LD2() end,
              func_ctrlLD = function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_ctrlLD() end,             
              func_wheel = function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_wheel() end,               
              func_ResetVal = function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_ResetVal() end,
              func_mouseover = function() OBJ_KnobF_Pan(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_mouseover() end} 
              
        local pitch_val = data[cur_note][cur_spl].pitch_offset  
        obj['mix_splctrl_pitch'..cur_note] = { clear = true,
              x = key_x + (key_w  - obj.pat_area_h) /2-1 ,
              y = key_y + obj.pat_area_h*3,
              w = obj.pat_area_h,
              h = obj.pat_area_h,
              col = 'white',
              state = 1,
              txt= '',
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              is_centered_knob = true,
              val = pitch_val,
              fontsz = conf.GUI_splfontsz,
              alpha_back =0,
              func =  function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, -1):func() end,
              func_trigCtrl =   function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, -1):func() end,
              func_LD2 = function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_LD2() end,
              func_ctrlLD = function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_ctrlLD() end,             
              func_wheel = function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_wheel() end,               
              func_ResetVal = function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_ResetVal() end,
              func_mouseover = function() OBJ_KnobF_Pitch(conf, obj, data, refresh, mouse, pat, cur_note, -1):func_mouseover() end}               
    end  
    ---------------------------------------------------
    function OBJ_GenKeysMixer(conf, obj, data, refresh, mouse)
      local cnt = 0
      local x_out = 0
      local h_div = 1
      local wheel_ratio = 12000
      if conf.keymode ==0 then 
        cnt = 12
      elseif conf.keymode ==1 then 
        cnt = 24  
       elseif conf.keymode == 2 then -- korg nano
        cnt = 16 
       elseif conf.keymode == 3 then -- live dr rack
        cnt= 16
       elseif conf.keymode == 4 then -- s1 impact
        cnt = 16 
       elseif conf.keymode == 5 then -- ableton push
        cnt = 64    
       elseif conf.keymode == 6 then -- 8x8
        cnt = 64                              
      end
      
      
      local key_area_h = gfx.h  - obj.samplename_h --obj.kn_h-obj.samplename_h
      local key_w = math.max(math.ceil((gfx.w-3*obj.offs-obj.keycntrlarea_w-obj.mixslot_w)/cnt),  30)
      local key_h = math.ceil((1/h_div)*(key_area_h))
      obj.h_div = h_div
      for i = 1, cnt do
        local id = i-1+conf.oct_shift*12
        local note = (i-1)+12*conf.oct_shift+conf.start_oct_shift*12
        local col = 'white'
        local colint, colint0
        local alpha_back
        if  data[note] and data[note][1] then 
          alpha_back = 0.6      
          col = 'green'
          if data[note][1].src_track_col then colint = data[note][1].src_track_col  end    
         else
          alpha_back = 0.15 
        end
        
        local txt = BuildKeyName(conf, data, note, conf.key_names_mixer)
        if  key_w < obj.fx_rect_side then txt = '' end
          --
          if note >= 0 and note <= 127 then
            local key_xpos = obj.keycntrlarea_w+(i-1)*key_w +obj.offs
            local key_ypos = gfx.h-key_area_h- obj.samplename_h
            local fxctrlcnt = OBJ_GenKeys_PadButtons(conf, obj, data, refresh, mouse, note, key_xpos, key_ypos-obj.offs, key_w, key_h, true)
            if not fxctrlcnt then fxctrlcnt = 0 end
            -------------------------
            -- keys
            local gain_val = 0
            local pan_val = 0.5
            local scaling = 0.2
            if data[note] and data[note][1] then 
              OBJ_GenKeysMixer_Ctrl(conf, obj, data, refresh, mouse, note, 1, key_xpos, gfx.h-key_area_h-obj.samplename_h+20, key_w, key_h)
            end
            
            local a_frame,selection_tri = 0
            if obj.current_WFkey and note == obj.current_WFkey then
              a_frame = obj.sel_key_frame
              selection_tri = true
            end
            x_out = key_xpos + key_w
            obj['keys_p'..note] = 
                      { clear = true,
                        x = key_xpos,
                        y = gfx.h-key_area_h-obj.samplename_h + obj.offs,
                        w = key_w-1,
                        h = key_h,
                        --[[mixer_slider = true,
                        mixer_slider_val = gain_val,
                        mixer_slider_pan = pan_val,]]
                        col = col,
                        colint = colint,
                        state = 0,
                        txt= txt,--note,
                       -- limtxtw = key_w - obj.fx_rect_side,
                        limtxtw_vert = limtxtw_vert,
                        --vertical_txt = verttxt,
                        linked_note = note,
                        show = true,
                        is_but = true,
                        alpha_back = alpha_back,
                        a_frame = a_frame,
                        selection_tri=selection_tri,
                        aligh_txt = 4,
                        fontsz = conf.GUI_padfontsz,
                        func =  function()  obj.current_WFkey = note end}
            if    note%12 == 1 
              or  note%12 == 3 
              or  note%12 == 6 
              or  note%12 == 8 
              or  note%12 == 10 
              then obj['keys_p'..note].txt_col = 'black' end
              
              
        end
      end
    
      return x_out
    end
