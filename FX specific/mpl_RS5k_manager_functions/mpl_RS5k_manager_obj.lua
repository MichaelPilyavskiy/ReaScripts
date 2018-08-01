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
    
    obj.item_h = 20   -- splbrowsp    
    obj.item_h2 = 20  -- list header
    obj.item_h3 = 15  -- list items
    obj.item_h4 = 40  -- steseq
    obj.item_w1 = 120 -- steseq name
    obj.scroll_w = 15
    obj.comm_w = 80 -- commit button
    obj.comm_h = 30
    obj.key_h = 250-- keys y/h  
 
 
    obj.samplename_h = 20   
    obj.keycntrlarea_w = 20
    obj.WF_w=gfx.w- obj.keycntrlarea_w  
    obj.fx_rect_side = 15
    
    -- alpha
    obj.it_alpha = 0.45 -- under tab
    obj.it_alpha2 = 0.28 -- navigation
    obj.it_alpha3 = 0.1 -- option tabs
    obj.it_alpha4 = 0.05 -- option items
    obj.it_alpha5 = 0.08-- oct lowhigh
    obj.it_alpha6 = 0.4-- selected
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
  function OBJ_GenKeys_GlobalCtrl_sub(conf, obj, data, refresh, mouse, globctrl_t)
        obj[globctrl_t.key] = { clear = true,
              x = globctrl_t.kn_x,
              y = globctrl_t.kn_y,
              w = obj.kn_w,
              h = obj.kn_h,
              col = 'white',
              state = 0,
              txt= globctrl_t.txt  ,
              aligh_txt = 16,
              show = true,
              is_but = true,
              is_knob = true,
              val = 1,
              fontsz = obj.GUI_fontsz3,
              alpha_back =globctrl_t.knob_back,
              func =  function() 
                        mouse.context_latch_val = 1
                        obj.mixer_curpar_key = globctrl_t.param_key
                        mouse.context_latch_t = {}
                          for note in pairs(data) do
                            if tonumber(note) and type(data[note]) == 'table' then
                              mouse.context_latch_t[note] = {}
                              for spl =1, #data[note] do
                                mouse.context_latch_t[note][spl] = data[note][spl][globctrl_t.param_key]
                              end
                            end
                          end                        
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val or not mouse.context_latch_t then return end
                          local out_val = 1 - mouse.dy/globctrl_t.dragratio
                          if not out_val then return end
                          obj.mixer_curpar_key = globctrl_t.param_key
                          for note in pairs(data) do
                            if tonumber(note) and type(data[note]) == 'table' then
                              for spl =1, #data[note] do
                                data[note][spl][globctrl_t.param_key]  = lim( globctrl_t.funcchange( mouse.context_latch_t[note][spl], out_val), 0, globctrl_t.limmax)
                                SetRS5kData(data, conf, data[note][spl].src_track, note, spl) 
                              end
                            end
                          end
                          refresh.data = true 
                          refresh.GUI = true 
                        end,      
              func_ctrlLD = function ()
                          if not mouse.context_latch_val or not mouse.context_latch_t then return end
                          local out_val = 1 - 0.5*obj.ctrl_ratio*mouse.dy/globctrl_t.dragratio
                          if not out_val then return end
                          for note in pairs(data) do
                            if tonumber(note) and type(data[note]) == 'table' then
                              for spl =1, #data[note] do
                                data[note][spl][globctrl_t.param_key]  = lim( globctrl_t.funcchange( mouse.context_latch_t[note][spl], out_val), 0, globctrl_t.limmax)
                                SetRS5kData(data, conf, data[note][spl].src_track, note, spl) 
                              end
                            end
                          end
                          refresh.data = true 
                          refresh.GUI = true 
                        end,                         
                        
              func_wheel = function()
                          local out_val = 1+mouse.wheel_trig/globctrl_t.wheel_ratio
                          if not out_val then return end
                          for note in pairs(data) do
                            if tonumber(note) and type(data[note]) == 'table' then
                              for spl =1, #data[note] do
                                data[note][spl][globctrl_t.param_key]  = lim( globctrl_t.funcchange( data[note][spl][globctrl_t.param_key], out_val), 0, globctrl_t.limmax)
                                SetRS5kData(data, conf, data[note][spl].src_track, note, spl) 
                              end
                            end
                          end
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
                        
              func_DC = function ()
                          for note in pairs(data) do
                            if tonumber(note) and type(data[note]) == 'table' then
                              for spl =1, #data[note] do
                                data[note][spl][globctrl_t.param_key]  = globctrl_t.default_val
                                SetRS5kData(data, conf, data[note][spl].src_track, note, spl) 
                              end
                            end
                          end 
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }  
  end
  ---------------------------------------------------
  function OBJ_GenKeys_GlobalCtrl(conf, obj, data, refresh, mouse)
    local env_x_shift = 30
    local knob_back = 0
    local knob_y = 0
    local wheel_ratio = 12000
    local loop_mouseres = 100
    local dragratio = 50
    local pitch_mouseres = 400
    local ctrl_ratio = 0.1
    local wheel_ratio_log = 12000
        ---------- gain ----------
    OBJ_GenKeys_GlobalCtrl_sub(conf, obj, data, refresh, mouse, { key = 'GLOBctrl_gain', 
                                                                  kn_x = obj.keycntrlarea_w   + obj.offs,
                                                                  kn_y = knob_y,
                                                                  knob_back = knob_back,
                                                                  txt = 'Global\nGain',
                                                                  dragratio=dragratio,
                                                                  param_key = 'gain',
                                                                  wheel_ratio=wheel_ratio,
                                                                  default_val= 0.5,
                                                                  limmax=2,
                                                                  funcchange = function(a,b) return a*b end})
    OBJ_GenKeys_GlobalCtrl_sub(conf, obj, data, refresh, mouse, { key = 'GLOBctrl_pan', 
                                                                  kn_x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w,
                                                                  kn_y = knob_y,
                                                                  knob_back = knob_back,
                                                                  txt = 'Global\nPan',
                                                                  dragratio=dragratio,
                                                                  param_key = 'pan',
                                                                  wheel_ratio=wheel_ratio,
                                                                  default_val=0.5,
                                                                  limmax = 1,
                                                                  funcchange =  function(a,b) 
                                                                                  if a <= 0.5 then 
                                                                                    local p = lim(a,0.1,1)
                                                                                    return (p*b)
                                                                                   elseif a > 0.5 then
                                                                                    local p = a-0.5
                                                                                    return 0.5+(p*b)
                                                                                   else
                                                                                    return a
                                                                                  end
                                                                                end}) 
    OBJ_GenKeys_GlobalCtrl_sub(conf, obj, data, refresh, mouse, { key = 'GLOBctrl_pitch_offset', 
                                                                  kn_x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*2,
                                                                  kn_y = knob_y,
                                                                  knob_back = knob_back,
                                                                  txt = 'Global\nPitch',
                                                                  dragratio=dragratio,
                                                                  param_key = 'pitch_offset',
                                                                  wheel_ratio=wheel_ratio,
                                                                  default_val=0.5,
                                                                  limmax = 1,
                                                                  funcchange =  function(a,b)return a*b end})     
    OBJ_GenKeys_GlobalCtrl_sub(conf, obj, data, refresh, mouse, { key = 'GLOBctrl_attack', 
                                                                  kn_x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*3 + env_x_shift,
                                                                  kn_y = knob_y,
                                                                  knob_back = knob_back,
                                                                  txt = 'Global\nA',
                                                                  dragratio=dragratio,
                                                                  param_key = 'attack',
                                                                  wheel_ratio=wheel_ratio,
                                                                  default_val=0,
                                                                  limmax = 1,
                                                                  funcchange =  function(a,b)return lim(a,0.001,1)*b end})  
    OBJ_GenKeys_GlobalCtrl_sub(conf, obj, data, refresh, mouse, { key = 'GLOBctrl_decay', 
                                                                  kn_x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*4 + env_x_shift,
                                                                  kn_y = knob_y,
                                                                  knob_back = knob_back,
                                                                  txt = 'Global\nD',
                                                                  dragratio=dragratio,
                                                                  param_key = 'decay',
                                                                  wheel_ratio=wheel_ratio,
                                                                  default_val=0.016,
                                                                  limmax = 1,
                                                                  funcchange =  function(a,b)return lim(a,0.001,1)*b end})   
    OBJ_GenKeys_GlobalCtrl_sub(conf, obj, data, refresh, mouse, { key = 'GLOBctrl_sust', 
                                                                  kn_x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*5 + env_x_shift,
                                                                  kn_y = knob_y,
                                                                  knob_back = knob_back,
                                                                  txt = 'Global\nS',
                                                                  dragratio=dragratio,
                                                                  param_key = 'sust',
                                                                  wheel_ratio=wheel_ratio,
                                                                  default_val=0.5,
                                                                  limmax = 1,
                                                                  funcchange =  function(a,b)return lim(a,0.001,1)*b end})      
    OBJ_GenKeys_GlobalCtrl_sub(conf, obj, data, refresh, mouse, { key = 'GLOBctrl_rel', 
                                                                  kn_x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*6 + env_x_shift,
                                                                  kn_y = knob_y,
                                                                  knob_back = knob_back,
                                                                  txt = 'Global\nR',
                                                                  dragratio=dragratio,
                                                                  param_key = 'rel',
                                                                  wheel_ratio=wheel_ratio,
                                                                  default_val=0.004,
                                                                  limmax = 1,
                                                                  funcchange =  function(a,b)return lim(a,0.001,1)*b end})        
    OBJ_GenKeys_GlobalCtrl_sub(conf, obj, data, refresh, mouse, { key = 'GLOBctrl_offset_start', 
                                                                  kn_x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*7 + env_x_shift*2,
                                                                  kn_y = knob_y,
                                                                  knob_back = knob_back,
                                                                  txt = 'Global\nLoopSt',
                                                                  dragratio=dragratio,
                                                                  param_key = 'offset_start',
                                                                  wheel_ratio=wheel_ratio,
                                                                  default_val=0,
                                                                  limmax = 1,
                                                                  funcchange =  function(a,b)return lim(a,0.001,1)*b end})    
    OBJ_GenKeys_GlobalCtrl_sub(conf, obj, data, refresh, mouse, { key = 'GLOBctrl_offset_end', 
                                                                  kn_x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*8 + env_x_shift*2,
                                                                  kn_y = knob_y,
                                                                  knob_back = knob_back,
                                                                  txt = 'Global\nLoopEnd',
                                                                  dragratio=dragratio,
                                                                  param_key = 'offset_end',
                                                                  wheel_ratio=wheel_ratio,
                                                                  default_val=1,
                                                                  limmax = 1,
                                                                  funcchange =  function(a,b)return lim(a,0.001,1)*b end})                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
    do return end   

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
                        
              func_DC = function ()
                          data[cur_note][cur_spl].offset_end  = 1
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }                                                                                                                                                                                                   
  end  
  ---------------------------------------------------
  function OBJ_GenKeys_splCtrl(conf, obj, data, refresh, mouse, pat)
  
    
    local env_x_shift = 20
    local knob_back = 0
    local knob_y = 0
    local wheel_ratio = 12000
    local loop_mouseres = 100
    local dragratio = 80
    local pitch_mouseres = 400
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
        if (mouse.context_latch and mouse.context_latch == 'splctrl_gain') or (mouse.context == 'splctrl_gain' and mouse.wheel_on_move)
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
              fontsz = conf.GUI_splfontsz,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].gain 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/dragratio, 0, 2)
                          if not out_val then return end
                          data[cur_note][cur_spl].gain  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.data = true 
                          refresh.GUI = true 
                        end,
              func_ctrlLD = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - ctrl_ratio*mouse.dy/dragratio, 0, 2)
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
                        
              func_ResetVal = function ()
                          data[cur_note][cur_spl].gain  = 0.5
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end
              }
        ---------- pan ----------                          
        local pan_val = data[cur_note][cur_spl].pan 
        local pan_txt
        if (mouse.context_latch and mouse.context_latch == 'splctrl_pan') or (mouse.context == 'splctrl_pan' and mouse.wheel_on_move)
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
              fontsz = conf.GUI_splfontsz,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].pan 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/dragratio, 0, 1)
                          if not out_val then return end
                          data[cur_note][cur_spl].pan  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)  
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
              func_ctrlLD = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - ctrl_ratio*mouse.dy/dragratio, 0, 1)
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
              func_ResetVal = function () 
                          data[cur_note][cur_spl].pan  = 0.5
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl) 
                          refresh.GUI = true 
                          refresh.data = true 
                        end}        
        ---------- ptch ----------                          
        local pitch_val = data[cur_note][cur_spl].pitch_offset 
        local pitch_txt
        if    (mouse.context_latch and (mouse.context_latch == 'splctrl_pitch1' or mouse.context_latch == 'splctrl_pitch2'))
               or (mouse.context == 'splctrl_pitch1' and mouse.wheel_on_move) 
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
              fontsz = conf.GUI_splfontsz,
              alpha_back =knob_back,
              func =  function() 
                        mouse.context_latch_val = data[cur_note][cur_spl].pitch_offset 
                      end,
              func_LD2 = function ()
                          if not mouse.context_latch_val then return end
                          local out_val = lim(mouse.context_latch_val - mouse.dy/pitch_mouseres, 0, 1)*160
                          local int, fract = math.modf(mouse.context_latch_val*160 )
                          local out_val = lim(mouse.context_latch_val - mouse.dy/pitch_mouseres, 0, 1)
                          if not out_val then return end
                          out_val = (math_q(out_val*160)+fract)/160
                          data[cur_note][cur_spl].pitch_offset  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)   
                          refresh.GUI = true 
                          refresh.data = true 
                        end,
              func_ctrlLD = function ()
                          if not mouse.context_latch_val then return end
                          --local out_val = lim(mouse.context_latch_val - ctrl_ratio*mouse.dy/pitch_mouseres, 0, 1)*160
                          --local int, fract = math.modf(mouse.context_latch_val*160 )
                          local out_val = lim(mouse.context_latch_val - 0.05*ctrl_ratio*mouse.dy/pitch_mouseres, 0, 1)
                          if not out_val then return end
                          --out_val = (math_q(out_val*160)+fract)/160
                          data[cur_note][cur_spl].pitch_offset  = out_val
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)   
                          refresh.GUI = true 
                          refresh.data = true 
                        end,                        
              func_wheel = function()
                              local wheel_rat = 24000
                              local out_val = lim(data[cur_note][cur_spl].pitch_offset  + mouse.wheel_trig/wheel_rat, 0, 1)*160
                              local int, fract = math.modf(data[cur_note][cur_spl].pitch_offset*160 )
                              local out_val = lim(data[cur_note][cur_spl].pitch_offset + mouse.wheel_trig/wheel_rat, 0, 1)
                              if not out_val then return end
                              out_val = (math_q(out_val*160)+fract)/160
                                            
                              --local out_val = lim(data[cur_note][cur_spl].pitch_offset  + mouse.wheel_trig/wheel_ratio, 0, 2)
                              --if not out_val then return end
                              data[cur_note][cur_spl].pitch_offset  = out_val
                              SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)   
                              refresh.GUI = true 
                              refresh.data = true 
                            end,                           
              func_ResetVal = function () 
                          data[cur_note][cur_spl].pitch_offset  = 0.5
                          SetRS5kData(data, conf, data[cur_note][cur_spl].src_track, cur_note, cur_spl)   
                          refresh.GUI = true 
                          refresh.data = true 
                        end}  

        ---------- attack ----------  
        local att_txt
        if (mouse.context_latch and mouse.context_latch == 'splctrl_att') or (mouse.context == 'splctrl_att' and mouse.wheel_on_move) then 
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
        if (mouse.context_latch and mouse.context_latch == 'splctrl_dec') or (mouse.context== 'splctrl_dec' and mouse.wheel_on_move) then 
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
        if (mouse.context_latch and mouse.context_latch == 'splctrl_sust') or (mouse.context== 'splctrl_sust' and mouse.wheel_on_move) then 
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
        if (mouse.context_latch and mouse.context_latch == 'splctrl_rel') or (mouse.context == 'splctrl_rel' and mouse.wheel_on_move) then 
          rel_txt  = data[cur_note][cur_spl].rel_ms..'ms'   
         else   
          rel_txt = 'R'    
        end
        local val = data[cur_note][cur_spl].rel^0.1666
        local invert_mouse_rel = 1
        if conf.invert_release == 1 then invert_mouse_rel = -1 end
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
        if (mouse.context_latch and mouse.context_latch == 'splctrl_loops') or (mouse.context== 'splctrl_loops' and mouse.wheel_on_move) then 
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
        if (mouse.context_latch and mouse.context_latch == 'splctrl_loope' ) or (mouse.context== 'splctrl_loope' and mouse.wheel_on_move)then 
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
        obj.splctrl_obeynoteoff = { clear = true,
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
                                  
        obj.splctrl_nextspl = { clear = true,
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
                                  
        obj.splctrl_prevspl = { clear = true,
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
        ---------- del ----------  
        local del_txt, del_val
        if (mouse.context_latch and mouse.context_latch == 'splctrl_del') or (mouse.context== 'splctrl_del' and mouse.wheel_on_move)  then 
          if data[cur_note][cur_spl].del then 
            del_txt  = data[cur_note][cur_spl].del_ms 
           else
            del_txt  = 'Delay' 
          end
         else   
          del_txt = 'Delay' 
        end
        obj.splctrl_del = { clear = true,
              x = obj.keycntrlarea_w   + obj.offs+ obj.kn_w*10 + env_x_shift*5,
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
  function BuildKeyName(conf, data, note, ismixer)
    local str = conf.key_names2..' '
    if ismixer then str = conf.key_names_mixer..' ' end
    if not str then return "" end
    --------
    str = str:gsub('#midipitch', note)
    --------
    local ntname = GetNoteStr(conf, note, 0)
    str = str:gsub('#keycsharp ', ntname)
    local ntname = GetNoteStr(conf, note, 7)
    str = str:gsub('#keycsharpRU ', ntname)
    --------
    if data[note] and data[note][1] and data[note][1].MIDI_name and data[note][1].MIDI_name ~= '' then 
      str = str:gsub('#notename ', data[note][1].MIDI_name) else str = str:gsub('#notename', '')
    end
    --------
    if data[note] then 
      str = str:gsub('#samplecount ', '('..#data[note]..')') else str = str:gsub('#samplecount', '')
    end 
    --------
    local spls = ''
    if data[note] and #data[note] >= 1 then
      for spl = 1, #data[note] do
        spls = spls..data[note][spl].sample_short..'\n'
      end
    end
    str = str:gsub('#samplename ', spls)
    --------
    str = str:gsub('|  |', '|')
    str = str:gsub('|', '\n')
    --------
    
    return str

    
  end
    ---------------------------------------------------
    function OBJ_GenKeys(conf, obj, data, refresh, mouse)
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
        local col = 'white'
        local colint, colint0
        local alpha_back
        if  data[note] and data[note][1] then 
          alpha_back = 0.37        
          col = 'green'
          if data[note][1].src_track_col then colint = data[note][1].src_track_col  end    
         else
          alpha_back = 0.15 
        end
          
          local txt = BuildKeyName(conf, data, note)
          
          if  key_w < obj.fx_rect_side*2.5 or key_h < obj.fx_rect_side*2.8 then txt = note end
          if  key_w < obj.fx_rect_side*1.5 or key_h < obj.fx_rect_side*1.5 then txt = '' end
          if note >= 0 and note <= 127 then
            local key_xpos = obj.keycntrlarea_w + shifts[i][1]*key_w  + 2
            local key_ypos = gfx.h-key_area_h+ shifts[i][2]*key_h
            OBJ_GenKeys_PadButtons(conf, obj, data, refresh, mouse, note, key_xpos, key_ypos, key_w, key_h)
            -------------------------
            -- keys
            local draw_drop_line if data.activedroppedpad and data.activedroppedpad == 'keys_p'..note then draw_drop_line = true end
            local a_frame = 0.05
            if obj.current_WFkey and note == obj.current_WFkey then
              a_frame = 0.4
            end
            obj['keys_p'..note] = 
                      { clear = true,
                        draw_drop_line = draw_drop_line,
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
                        a_frame = a_frame,
                        aligh_txt = 5,
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
                                                              if conf.MM_dc_float == 1 and data[note] then
                                                                for spl = 1, #data[note] do
                                                                  -- TrackFX_SetOpen(  data[note][1].src_track, data[note][1].rs5k_pos, true )
                                                                  TrackFX_Show( data[note][spl].src_track, data[note][spl].rs5k_pos,3 )
                                                                end
                                                              end
                                                            end},
                                                  { str =   'Rename linked MIDI note',
                                                    func =  function()
                                                              local MIDI_name = GetTrackMIDINoteNameEx( 0, data[note][1].src_track, note, 1)
                                                              local ret, MIDI_name_ret = reaper.GetUserInputs( conf.scr_title, 1, 'Rename MIDI note,extrawidth=200', MIDI_name )
                                                              if ret then
                                                                SetTrackMIDINoteNameEx( 0, data[note][1].src_track, note, 0, MIDI_name_ret)
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
                                    
                                  end
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
  function OBJ_GenKeys_PadButtons(conf, obj, data, refresh, mouse, note, key_xpos, key_ypos, key_w, key_h, alignformixer)
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
                  x_pos = key_xpos + key_w - obj.fx_rect_side +1
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
                  x_pos = key_xpos + key_w - obj.fx_rect_side+1
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
                  x_pos = key_xpos + key_w - obj.fx_rect_side+1
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
  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse) 
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  
    
    obj.kn_h = math.floor(56 *  lim(conf.GUI_ctrlscale, 0.5,3)) 
    obj.kn_w =  math.floor(42 *  lim(conf.GUI_ctrlscale, 0.5,3))
    obj.splctrl_butw = math.floor(60 *  lim(conf.GUI_ctrlscale, 0.5,3))
    obj.WF_h=obj.kn_h 
    
      local fx_per_pad if conf.allow_multiple_spls_per_pad == 1 then fx_per_pad = '#' else fx_per_pad = '' end
      local keyareabut_h = (gfx.h -obj.kn_h-obj.samplename_h)/3
        obj.keys_octaveshiftL = { clear = true,
                    x = 0,
                    y = obj.kn_h+obj.samplename_h,
                    w = obj.keycntrlarea_w,
                    h = keyareabut_h,
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
                    y = obj.kn_h+obj.samplename_h + keyareabut_h,
                    w = obj.keycntrlarea_w,
                    h = keyareabut_h-1,
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
                            
    -- ask pinned tr
      local ret, trGUID = GetProjExtState( 0, 'MPLRS5KMANAGE', 'PINNEDTR' )
      local pinnedtr = BR_GetMediaTrackByGUID( 0, trGUID )
      local pinnedtr_str = '(none)' 
      if pinnedtr then 
        _, pinnedtr_str = GetTrackName( pinnedtr, '' )
      end
      
    --                         
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
            end},  
  { str = 'Edit keyname hashtags',
    func = function() 
              local ret = GetInput( conf, 'Keyname hashtags', conf.key_names2, _, 400, true) 
              if ret then  
                conf.key_names2 = ret 
              end             
            end},  
  { str = 'Edit mixer keyname hashtags',
    func = function() 
              local ret = GetInput( conf, 'Mixer keyname hashtags', conf.key_names_mixer, _, 400, true) 
              if ret then  
                conf.key_names_mixer = ret 
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
  { str = 'Ableton Push (8x8)|<|',
    func = function() conf.keymode = 5 end ,
    state = conf.keymode == 5},    
    
  { str = 'Send MIDI by clicking on keys|<',
    func = function() conf.keypreview = math.abs(1-conf.keypreview)  end ,
    state = conf.keypreview == 1},   


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
  { str = 'Doubleclick reset value',  
    state = conf.MM_reset_val&(1<<0) == (1<<0),
    func =  function() 
              local ret = BinaryCheck(conf.MM_reset_val, 0)
              conf.MM_reset_val = ret
            end ,},   
  { str = 'Alt+Click reset value|<',  
    state = conf.MM_reset_val&(1<<1) == (1<<1),
    func =  function() 
              local ret = BinaryCheck(conf.MM_reset_val, 1)
              conf.MM_reset_val = ret
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
  
  { str = 'Pad font size|<',
    func =  function() 
              local ret = GetInput( conf, 'Pad font', conf.GUI_padfontsz,true)
              if ret then 
                conf.GUI_padfontsz = ret
                refresh.GUI = true
              end
            end
  } ,

  { str = '>Dragndrop options'},
  { str = 'Always export dragged samples to new tracks',
    func =  function() conf.dragtonewtracks = math.abs(1-conf.dragtonewtracks)  end,
    state = conf.dragtonewtracks == 1,
  } ,     
  { str = 'Don`t ask for creating FX routing',
    func =  function() conf.dontaskforcreatingrouting = math.abs(1-conf.dontaskforcreatingrouting)  end,
    state = conf.dontaskforcreatingrouting == 1,
  } ,                
  { str = 'Use custom FX chain for newly dragged samples '..conf.draggedfile_fxchain..'|<|',
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
  { str = '>Prepare selected track MIDI input'},   
  { str = 'Disabled',
    func = function() conf.prepareMIDI2 = 0  end ,
    state = conf.prepareMIDI2 == 0},    
  { str = 'On script start: Virtual keyboard',
    func = function() conf.prepareMIDI2 = 1  end ,
    state = conf.prepareMIDI2 == 1},                   
  { str = 'On script start: All inputs',
    func = function() conf.prepareMIDI2 = 2  end ,
    state = conf.prepareMIDI2 == 2}, 
  { str = 'Manually: Virtual keyboard',
    func = function() conf.prepareMIDI2 = 3  end ,
    state = conf.prepareMIDI2 == 3},     
  { str = 'Manually: All inputs|<',
    func = function() conf.prepareMIDI2 = 4  end ,
    state = conf.prepareMIDI2 == 4},          
    
  { str = 'Layering mode: allow multiple samples per pad',
    func = function() conf.allow_multiple_spls_per_pad = math.abs(1-conf.allow_multiple_spls_per_pad) end,
    state = conf.allow_multiple_spls_per_pad == 1, 
  } ,  
  { str = 'Toggle pin selected track as a parent track',
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
  { str = 'Select pinned track: '..pinnedtr_str..'|',
    func =  function() 
              if pinnedtr then SetOnlyTrackSelected( pinnedtr ) end
            end
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
                            
                            
        local mix_y_offs =  obj.kn_h+obj.samplename_h + keyareabut_h*2  
        local mix_h = keyareabut_h+1                   
        if conf.prepareMIDI2 == 3 or conf.prepareMIDI2 == 4 then mix_h = keyareabut_h /2 end
        
        local cymb_a = obj.it_alpha5
        if obj.window == 1 then cymb_a = obj.it_alpha6 end
        obj.mixer = { clear = true,
                    x = 0,
                    y = mix_y_offs,
                    w = obj.keycntrlarea_w,
                    h =mix_h,
                    cymb = 0,
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
                              obj.window = math.abs(obj.window-1)
                              obj.current_WFkey = nil
                              obj.current_WFspl = nil
                              refresh.GUI_WF = true  
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.data = true                           
                            end}                             
                            
        if conf.prepareMIDI2 == 3 or conf.prepareMIDI2 == 4 then
          local mode_override = 0
          if  conf.prepareMIDI2 == 4 then mode_override = 1 end
          obj.prepareMIDI = { clear = true,
                    x = 0,
                    y = mix_y_offs + mix_h,
                    w = obj.keycntrlarea_w,
                    h = mix_h,
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
                              MIDI_prepare(data, conf, mode_override)
                              refresh.conf = true 
                              refresh.GUI = true
                              refresh.data = true                           
                            end}         
        end                    
                            
                            
                            
    if obj.window == 0 then                
      OBJ_GenKeys(conf, obj, data, refresh, mouse)
      OBJ_GenKeys_splCtrl(conf, obj, data, refresh, mouse)
     else
      OBJ_GenKeysMixer(conf, obj, data, refresh, mouse)
      OBJ_GenKeys_GlobalCtrl(conf, obj, data, refresh, mouse)
    end
    for key in pairs(obj) do if type(obj[key]) == 'table' then obj[key].context = key end end    
  end
    ---------------------------------------------------
    function OBJ_GenKeysMixer(conf, obj, data, refresh, mouse)
      local cnt = 0
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
      end
      

      local key_area_h = gfx.h -obj.kn_h-obj.samplename_h
      local key_w = math.ceil((gfx.w-3*obj.offs-obj.keycntrlarea_w)/cnt)
      local key_h = math.ceil((1/h_div)*(key_area_h)) +1
      obj.h_div = h_div
      for i = 1, cnt do
        local id = i-1+conf.oct_shift*12
        local note = (i-1)+12*conf.oct_shift+conf.start_oct_shift*12
        local col = 'white'
        local colint, colint0
        local alpha_back
        if  data[note] and data[note][1] then 
          alpha_back = 0.37        
          col = 'green'
          if data[note][1].src_track_col then colint = data[note][1].src_track_col  end    
         else
          alpha_back = 0.15 
        end
        
        local txt = BuildKeyName(conf, data, note, true)
        
        if  key_w < obj.fx_rect_side then txt = '' end
          --
          if note >= 0 and note <= 127 then
            local key_xpos = obj.keycntrlarea_w+(i-1)*key_w +2
            local key_ypos = gfx.h-key_area_h
            local fxctrlcnt = OBJ_GenKeys_PadButtons(conf, obj, data, refresh, mouse, note, key_xpos, key_ypos, key_w, key_h, true)
            if not fxctrlcnt then fxctrlcnt = 0 end
            -------------------------
            -- keys
            local gain_val = 0
            local pan_val = 0.5
            local scaling = 0.2
            if data[note] and data[note][1] then 
              local val = data[note].com_gain
              local zerolev = 0.78
              if val <= 0.5 then 
                val = val*2 * zerolev
               else
                val = zerolev + ((val-0.5)/1.5) * (1-zerolev)
              end
              gain_val = val
              pan_val = data[note].com_pan
            end
            local limtxtw_vert = obj.fx_rect_side*fxctrlcnt
            if key_w < obj.fx_rect_side*2 then txt = note end
            --local verttxt = ''
            --if txt and tostring(txt )then verttxt = tostring(txt ):gsub('\n',' ') end
            obj['keys_p'..i] = 
                      { clear = true,
                        x = key_xpos,
                        y = gfx.h-key_area_h,
                        w = key_w-1,
                        h = key_h,
                        mixer_slider = true,
                        mixer_slider_val = gain_val,
                        mixer_slider_pan = pan_val,
                        col = col,
                        colint = colint,
                        state = 0,
                        txt= txt,
                       -- limtxtw = key_w - obj.fx_rect_side,
                        limtxtw_vert = limtxtw_vert,
                        is_step = true,
                        vertical_txt = verttxt,
                        linked_note = note,
                        show = true,
                        is_but = true,
                        alpha_back = alpha_back,
                        a_frame = 0.05,
                        aligh_txt = 5,
                        fontsz = conf.GUI_padfontsz,
                        func =  function() 
                                  if conf.keypreview == 1 then  StuffMIDIMessage( 0, '0x9'..string.format("%x", 0), note,100) end                                  
                                  if data[note] then 
                                    mouse.context_latch_t = {}
                                    for spl =1, #data[note] do
                                      mouse.context_latch_t[spl] = data[note][spl].gain
                                    end
                                  end
                                end,
                        func_LD2 = function ()
                                    if not mouse.context_latch_t then return end
                                    for cur_spl =1, #mouse.context_latch_t do
                                      local mouseshift = mouse.dy/300
                                      local out_val = lim(mouse.context_latch_t[cur_spl] - mouseshift, 0, 2)
                                      if not out_val then return end
                                      --out_val = ((out_val /2 ) ^ 0.6)*2
                                      data[note][cur_spl].gain  = out_val
                                      SetRS5kData(data, conf, data[note][cur_spl].src_track, note, cur_spl) 
                                    end 
                                    
                                    refresh.data = true 
                                    refresh.GUI = true 
                                  end,
                        func_wheel = function()
                                    if not data[note] then return end
                                    for cur_spl =1, #data[note] do
                                      local out_val = lim(data[note][cur_spl].gain + mouse.wheel_trig/wheel_ratio, 0, 2)
                                      if not out_val then return end
                                      data[note][cur_spl].gain  = out_val
                                      SetRS5kData(data, conf, data[note][cur_spl].src_track, note, cur_spl) 
                                    end 
                                    refresh.GUI = true 
                                    refresh.data = true 
                                  end,
                                  
                        func_ResetVal = function ()
                                    if not data[note] then return end
                                    for cur_spl =1, #data[note] do                                      
                                      data[note][cur_spl].gain  = 0.5
                                      SetRS5kData(data, conf, data[note][cur_spl].src_track, note, cur_spl) 
                                    end 
                                    refresh.GUI = true 
                                    refresh.data = true 
                                  end                                  
                                } 
            if obj.mixer_curpar_key then 
              if data[note] and data[note][1] then 
                local curpar = data[note][1][obj.mixer_curpar_key]
                if curpar and type(curpar) == 'number' then 
                  obj['keys_pmixparam'..i] = 
                            { clear = true,
                              x = key_xpos,
                              y = gfx.h-key_area_h-obj.samplename_h,
                              w = key_w-1,
                              h = obj.samplename_h,
                              --col = col,
                              --colint = colint,
                              state = 0,
                              txt= string.format('%.3f', curpar),
                              is_step = true,
                              linked_note = note,
                              show = true,
                              is_but = true,
                              alpha_back = 0,
                              a_frame = 0,
                              aligh_txt = 5,
                              fontsz = conf.GUI_splfontsz}
                end
              end
            end                             
            if    note%12 == 1 
              or  note%12 == 3 
              or  note%12 == 6 
              or  note%12 == 8 
              or  note%12 == 10 
              then obj['keys_p'..i].txt_col = 'black' end
              
              
        end
      end
    
      
    end
