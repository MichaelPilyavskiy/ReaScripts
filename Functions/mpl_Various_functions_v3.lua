-- @description Various_functions_v3
-- @author MPL
-- @noindex  
  DATA  = {
            GUI ={
              layers  = {} ,
              shortcuts = {},
                }
            }
-----------------------------------------------------------------------------
  function DATA:ExtStateGet()
    if not DATA.extstate.default then return end
    local default = DATA.extstate.default
    for key in pairs(default) do 
      if key ~= '' then
        local val = GetExtState(DATA.extstate.extstatesection, key)
        local defval = default[key]
        if val == '' then DATA.extstate[key] = defval else DATA.extstate[key] = tonumber(val) or val end
      end
    end
  end
  --------------------------------------------------------------------- 
  function DATA:ExtStateRestoreDefaults(key, UI)
    if not key then
      for key in pairs(DATA.extstate) do
        if key:match('CONF_') or (UI and UI == true and key:match('UI_'))then
          local val = DATA.extstate.default[key]
          if val then DATA.extstate[key] = val end
        end
      end
     else
      local val = DATA.extstate.default[key]
      if val then DATA.extstate[key] = val end
    end
  end
  --------------------------------------------------------------------- 
  function DATA:ExtStateStorePreset(id_out0)
    local str = ''
    for key in spairs(DATA.extstate) do  if key:match('CONF_') then str = str..'\n'..key..'='..DATA.extstate[key] end end
    
    local id_out = id_out0 
    if not id_out then 
      for id = 1, 32 do  
        if HasExtState( DATA.extstate.extstatesection, 'PRESET'..id ) ==false then 
          id_out = id 
          break 
        end 
      end
    end-- search last available slot end
    SetExtState(DATA.extstate.extstatesection, 'PRESET'..id_out, VF_encBase64(str), true)
  end 
  -----------------------------------------------------------------------------
  function DATA:ExtStatePresetRemove(id)
    if HasExtState(DATA.extstate.extstatesection, 'PRESET'..id) then DeleteExtState(DATA.extstate.extstatesection, 'PRESET'..id, true ) end
  end
-----------------------------------------------------------------------------
  function DATA:ExtStateSet()
    if not DATA.extstate then return end
    for key in spairs(DATA.extstate.default) do if DATA.extstate[key] then SetExtState(DATA.extstate.extstatesection, key, DATA.extstate[key], true) end end
  end  
  --------------------------------------------------------------------- 
  function DATA:ExtStateApplyPreset(preset_t) 
    if not preset_t then return end
    for key in pairs(preset_t) do
      if key:match('CONF_') then 
        local presval = preset_t[key]
        DATA.extstate[key] = tonumber(presval) or presval
      end
    end
  end
  --------------------------------------------------------------------- 
  function DATA:ExtStateGetPresets()
    DATA.extstate.presets = {}
    for id_out=1, 32 do
      local str = GetExtState( DATA.extstate.extstatesection, 'PRESET'..id_out)
      local str_dec = VF_decBase64(str)
      if str_dec~= '' then 
        local tid = #DATA.extstate.presets+1
        DATA.extstate.presets[tid] = {str=str}
        for line in str_dec:gmatch('[^\r\n]+') do
          local key,value = line:gsub('[%{}]',''):match('(.-)=(.*)') 
          if key and value then
            DATA.extstate.presets[tid][key]= tonumber(value) or value
          end
        end   
      end
    end
    
    for extkey in pairs(DATA.extstate) do
      if extkey:match('FPRESET%d+')then
        local str = DATA.extstate[extkey]
        local str_dec = VF_decBase64(str)
        if str_dec~= '' then 
          local tid = #DATA.extstate.presets+1
          DATA.extstate.presets[tid] = {str=str}
          for line in str_dec:gmatch('[^\r\n]+') do
            local key,value = line:gsub('[%{}]',''):match('(.-)=(.*)') 
            if key and value then
              DATA.extstate.presets[tid][key]= tonumber(value) or value
            end
          end  
          if DATA.extstate.presets[tid].CONF_NAME then
            DATA.extstate.presets[tid].CONF_NAME = '*'..DATA.extstate.presets[tid].CONF_NAME
          end
        end
      end
    end
    
    --FPRESET1
     DATA.extstate.current_preset = 0
  end
  ----------------------------------------------------------------------------- 
  function DATA:GUIdraw_txt(b)
    local x,y,w,h =         b.x or 0,
                            b.y or 0,
                            b.w or 100,
                            b.h or 100 
    x,y,w,h = 
              x*DATA.GUI.default_scale,
              y*DATA.GUI.default_scale,           
              w*DATA.GUI.default_scale,            
              h*DATA.GUI.default_scale    
              
    local txt,txt_col,txt_flags, txt_font, txt_fontsz, txt_fontflags,txtback_col, txt_a,txt_short =
                            b.txt or '',
                            b.txt_col or DATA.GUI.default_txt_col,
                            b.txt_flags or DATA.GUI.default_txt_flags, -- &1 centered horizontally &4 vertically
                            b.txt_font or DATA.GUI.default_txt_font ,
                            b.txt_fontsz or DATA.GUI.default_txt_fontsz,
                            b.txt_fontflags or '',
                            b.txtback_col or DATA.GUI.default_backgr,
                            b.txt_a or DATA.GUI.default_txt_a,
                            b.txt_short or ''
    local txt_allowreduce = b.txt_allowreduce or '' -- allow reduce to [...minimumtexzt] in multiline mode
                            
    -- txt
      local txt_fontsz_out = txt_fontsz
      if b.offsetframe then 
        txt_flags = 1 
        txt_fontsz_out = b.txt_fontsz or b.offsetframe*2/DATA.GUI.default_scale
      end -- center button horiz / align top verically for frame
      DATA:GUIhex2rgb(txt_col, true)
      local calibrated_txt_fontsz = DATA:GUIdraw_txtCalibrateFont(txt_font, txt_fontsz_out, txt_fontflags)--, txt, w) 
      
      local strw, strh
      gfx.setfont(1,txt_font, calibrated_txt_fontsz, txt_fontflags )
      local drawstr_flags,right, bottom = 0
      if txt then 
        if txt and tostring(txt) and tostring(txt):match('\n') then 
          strw, strh = DATA:GUIdraw_txt_multiline(x,y,w,h,txt_flags, txt_a, txt,txt_allowreduce) 
         else 
          gfx.x, gfx.y = x+2,y
          gfx.a = txt_a
          strw = gfx.measurestr(txt)
          if strw > w and txt_short~= ''  then 
            txt = txt_short
            strw = gfx.measurestr(txt)
           elseif strw > w and txt_short== ''  then 
            txt = tostring(txt) or ''
            local len = txt:len()
            for i = len, 1,-1 do
              local test_str = txt:sub(0,i)
              if gfx.measurestr(test_str) < w then 
                txt = test_str 
                strw = gfx.measurestr(txt) 
                break 
              end
            end
          end
          strh = gfx.texth
          if txt_flags&1==1 then gfx.x = x+(w-strw)/2 end
          if txt_flags&4==4 then gfx.y = y+(h-strh)/2 end
          if txt_flags&2==2 then gfx.x = x + w - strw end
          if b.knob_isknob and b.knob_showvalueright and strw then gfx.x = x+w/2-(b.knob_arcR*2+strw)/2+ b.knob_arcR*2 end
          if b.offsetframe then 
            gfx.y = y+b.offsetframe*DATA.GUI.default_scale-calibrated_txt_fontsz/2
          end
          gfx.drawstr(txt) 
        end
      end
    --
    return strw, strh
  end
  -----------------------------------------------------------------------------
  function DATA:GUIdraw_txt_reduce(line,x,w)
    local symbcnt = line:len()
    if symbcnt < 4 then gfx.drawstr(line) else
      for symb = symbcnt, 1, -1 do
        if gfx.measurestr(line:sub(-symb) ) < w then 
          local out_str = '...'..line:sub(-symb+3) 
          gfx.x = x + (w- gfx.measurestr(out_str))/2
          gfx.drawstr(out_str)
          break
        end
      end
    end
  end
  ----------------------------------------------------------------------------- 
  function DATA:GUIdraw_txt_multiline(x,y0,w,h,txt_flags, txt_a,txt, txt_allowreduce) 
    if not txt then return end
    local cnt = 0 for line in txt:gmatch('[^\r\n]+') do cnt = cnt + 1 end
    local i = 0
    local strwmax = 0
    local strh = 0
    for line in txt:gmatch('[^\r\n]+') do
      gfx.x, gfx.y = x,y0
      gfx.a = txt_a
      local strw = gfx.measurestr(line)
      strwmax = math.max(strwmax,strw )
      strh = gfx.texth
      if txt_flags&1==1 then gfx.x = x+(w-strw)/2+1 end
      y = y0 + i *strh + h/2 - 0.5*cnt*strh
      gfx.y = y
      --if txt_flags&4==4 then gfx.y = y+(h-strh)/2 end
      if txt_allowreduce and strw > w then 
        DATA:GUIdraw_txt_reduce(line,x,w)
       else
        gfx.drawstr(line)
      end
      i =i +1
    end
    return strwmax, cnt*strh
  end
  ----------------------------------------------------------------------------- 
  function DATA:GUIdraw_txtCalibrateFont(txt_font, txt_fontsz_px, txt_fontflags)--, txtmsg, maxv) 
    if not txt_fontsz_px then return end
    for fontsz = 1, 100 do
      gfx.setfont(1,txt_font, fontsz, txt_fontflags or 0) 
      local strh = gfx.texth
      if strh > txt_fontsz_px 
        --*and  (not (maxv and txtmsg) or (maxv and txtmsg and gfx.measurestr(txtmsg) < maxv))
        then return (fontsz-1)*DATA.GUI.default_scale end
    end
  end
  ----------------------------------------------------------------------------- 
  function DATA:GUIhandlemousestate_match(b)
    if not b.x and b.y and b.w and b.h then return end
    b.mouse_match = false
    if DATA.GUI.x > gfx.w*DATA.GUI.default_scale or DATA.GUI.y > gfx.h*DATA.GUI.default_scale then return end
    b.mouse_match = DATA.GUI.x > b.x*DATA.GUI.default_scale and DATA.GUI.x < b.x*DATA.GUI.default_scale+b.w*DATA.GUI.default_scale and DATA.GUI.y > b.y*DATA.GUI.default_scale and DATA.GUI.y < b.y*DATA.GUI.default_scale+b.h*DATA.GUI.default_scale -- is mouse under object
    if b.layer then
      local layer = b.layer
      if not (DATA.GUI.layers[layer] and DATA.GUI.layers[layer].layer_yshift) then return end
      b.mouse_match = 
            DATA.GUI.x > (b.x + DATA.GUI.layers[layer].layer_x  )*DATA.GUI.default_scale 
        and DATA.GUI.x < (b.x+ DATA.GUI.layers[layer].layer_x  )*DATA.GUI.default_scale+b.w*DATA.GUI.default_scale 
        and DATA.GUI.y > (b.y+ DATA.GUI.layers[layer].layer_y  )*DATA.GUI.default_scale -DATA.GUI.layers[layer].layer_yshift
        and DATA.GUI.y < (b.y+ DATA.GUI.layers[layer].layer_y)*DATA.GUI.default_scale-DATA.GUI.layers[layer].layer_yshift  +b.h*DATA.GUI.default_scale
    end
  end
  ----------------------------------------------------------------------------- 
  function DATA:GUIhandlemousestate_is_offlayer(b)
    local layer= b.layer
    if not (layer and DATA.GUI.layers[layer] and DATA.GUI.layers[layer].layer_yshift) then return end
    local real_y = (b.y+ DATA.GUI.layers[layer].layer_y  ) *DATA.GUI.default_scale -DATA.GUI.layers[layer].layer_yshift--*DATA.GUI.default_scale
    if real_y+b.h < DATA.GUI.layers[layer].layer_y*DATA.GUI.default_scale or real_y+b.h > (DATA.GUI.layers[layer].layer_y + DATA.GUI.layers[layer].layer_h)*DATA.GUI.default_scale then return true end
  end
  ----------------------------------------------------------------------------- 
  function DATA:GUIhandlemousestate()
    DATA.perform_quere = {}
    if not (DATA.GUI and DATA.GUI.buttons) then return end
    DATA.GUI.mouse_match = {}
    for but in spairs(DATA.GUI.buttons ) do 
      local b = DATA.GUI.buttons[but] 
      if DATA:GUIhandlemousestate_is_offlayer(b) then goto skipb end 
      if b.ignoremouse ==true then goto skipb end 
      
      -- hovering mouse
        local refresh = true
        --if not b.ignoremouse_refresh then refresh = false end
      
        DATA:GUIhandlemousestate_match(b)
        if b.mouse_match then
          DATA.GUI.mouse_match[#DATA.GUI.mouse_match+1] = but
          b.mouse_matchparent = b
          if b.onmousematchcont then DATA.perform_quere[#DATA.perform_quere+1] = b.onmousematchcont end                                                     -- arrow above pointer coninioulsy
          if DATA.GUI.mouse_ismoving then b.refresh = refresh end                                                                                           -- refresh object is arrow above (handle context rectangle selection)
          if DATA.GUI.droppedfiles.exist == true and b.onmousefiledrop then DATA.perform_quere[#DATA.perform_quere+1] = b.onmousefiledrop end               -- handle file drop
        end
        if b.mouse_match and (not b.mouse_lastmatch  or ( b.mouse_lastmatch and b.mouse_lastmatch ~=b.mouse_match))  then                                   -- arrow is above AND [first loop OR arrow was nt above this object previously
          if b.onmousematch then DATA.perform_quere[#DATA.perform_quere+1] = b.onmousematch end
          if not b.prevent_matchrefresh then b.refresh = refresh end
         elseif b.mouse_lastmatch and not b.mouse_match  then                                                                                                -- arrow is not above object but it was previously
          if b.mouse_matchparent and b.mouse_matchparent.onmouselost then DATA.perform_quere[#DATA.perform_quere+1] = b.mouse_matchparent.onmouselost end
          if not b.prevent_matchrefresh then b.refresh = refresh end
        end
        b.mouse_lastmatch = b.mouse_match
      
      
      -- LMB
      -- handle mouse_latch on left click
        if DATA.GUI.LMB_trig == true and b.mouse_match == true then 
          --msg(b.key)
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmouseclick
          b.mouse_latch = true 
          if b.mouse_latchTS and os.clock()  - b.mouse_latchTS < DATA.GUI.doubleclicktime and b.onmousedoubleclick then
            --msg(os.clock()  - b.mouse_latchTS)
            DATA.perform_quere[#DATA.perform_quere+1] = b.onmousedoubleclick
          end
          local tslatch = os.clock()
          DATA.GUI.buttons[but].mouse_latchTS =  tslatch
          -- handle relative val slider
          if b.val then   b.latchval = b.val    if b.val_min and b.val_max then b.latchval = (b.val - b.val_min) / (b.val_max - b.val_min) end end
          -- handle absolute val slider
          local res = b.val_res or 1 b.val_abs = ((DATA.GUI.y*res/DATA.GUI.default_scale)-b.y) / b.h 
          b.refresh = true
        end 
        
      -- handle mouse_latch on left drag
        if DATA.GUI.LMB_state == true and b.mouse_latch == true then--and DATA.GUI.mouse_ismoving ==true 
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmousedrag 
          -- handle relative val slider
          if b.val and b.latchval and type(b.latchval) == 'number' then 
            local res= b.val_res or 1
            if DATA.GUI.Ctrl then res = res /10 end 
            
            local sourcediff = DATA.GUI.dy
            local comdim = b.h
            if b.val_xaxis then 
              sourcediff = DATA.GUI.dx
              comdim = b.w
            end
            local outval = 0
            outval = VF_lim(b.latchval - (sourcediff*res/DATA.GUI.default_scale) / comdim)
            local pow = 3
            if b.val_ispow then 
              outval = (VF_lim(b.latchval^(1/pow) - (sourcediff*res/DATA.GUI.default_scale) / comdim))^pow
            end
            if b.val_min and b.val_max then outval = b.val_min + (b.val_max - b.val_min) * outval end
            b.val = outval
            --val_islog
          end
          -- handle absolute val slider
          local res = b.val_res or 1
          b.val_abs = ((DATA.GUI.y*res/DATA.GUI.default_scale)-b.y) / b.h
          
          
          b.refresh = true
        end
        
     -- handle mouse_latch on left release
        local mouse_latch = b.mouse_latch
        if DATA.GUI.LMB_release == true and b.mouse_latch == true then
          b.mouse_latch = false
          b.refresh = true
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmouserelease
        elseif DATA.GUI.LMB_release == true and b.mouse_match == true and mouse_latch ~= true then -- handle mouse_latch on left release --
         DATA.perform_quere[#DATA.perform_quere+1] = b.onmousedrop
       end 
         
      -- RMB
      -- handle mouse_latch on left click
        if DATA.GUI.RMB_trig == true and b.mouse_match == true then 
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmouseclickR
          b.mouse_latch = true 
          if b.val then b.latchval = b.val    end
          b.refresh = true
        end 
        
      -- handle mouse_latch on right drag 
        if DATA.GUI.RMB_state == true and DATA.GUI.mouse_ismoving ==true and b.mouse_latch == true then 
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmousedragR 
          if  b.latchval  and type(b.latchval) == 'number' and b.val then 
            local res= b.val_res or 1
            b.val = VF_lim(b.latchval - (DATA.GUI.dy*res/DATA.GUI.default_scale) / b.h) 
          end
          b.refresh = true
        end
        
      -- handle mouse_latch on left release
        if DATA.GUI.RMB_release == true and b.mouse_latch == true then
          b.mouse_latch = false
          b.refresh = true
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmousereleaseR
        end




      -- handle wheel
        if b.mouse_match == true and DATA.GUI.wheel_trig then
          b.refresh = true
          DATA.perform_quere[#DATA.perform_quere+1] = b.onwheeltrig
        end
      
      -- handle mouse_latch on left drag
        if DATA.GUI.MMB_state == true and b.mouse_latch == true then--and DATA.GUI.mouse_ismoving ==true 
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmousedragM
          -- handle relative val slider
          if b.val and b.latchval and type(b.latchval) == 'number' then 
            local res= b.val_res or 1
            if DATA.GUI.Ctrl then res = res /10 end 
            
            local sourcediff = DATA.GUI.dy
            local comdim = b.h
            if b.val_xaxis then 
              sourcediff = DATA.GUI.dx
              comdim = b.w
            end
            local outval = 0
            outval = VF_lim(b.latchval - (sourcediff*res/DATA.GUI.default_scale) / comdim)
            local pow = 3
            if b.val_ispow then 
              outval = (VF_lim(b.latchval^(1/pow) - (sourcediff*res/DATA.GUI.default_scale) / comdim))^pow
            end
            if b.val_min and b.val_max then outval = b.val_min + (b.val_max - b.val_min) * outval end
            b.val = outval
            --val_islog
          end
          -- handle absolute val slider
          local res = b.val_res or 1
          b.val_abs = ((DATA.GUI.y*res/DATA.GUI.default_scale)-b.y) / b.h 
          b.refresh = true
        end
        
      --
      if DATA.GUI.LMB_state == true and DATA.GUI.mouse_ismoving ==true and b.mouse_latch == true and b.onmousedrag_skipotherobjects then return end
      --if b.refresh then msg(1) end
      ::skipb::
    end
    
  end
  ----------------------------------------------------------------------------- 
  function DATA:GUIdraw_knob(b)
    local x,y,w,h,val =b.x,b.y,b.w,b.h, b.val
    local knob_col,knob_a, knob_arca, knob_val = 
                            b.knob_col or DATA.GUI.default_knob_col,
                            b.knob_a or DATA.GUI.default_knob_a,
                            b.knob_arca or DATA.GUI.default_knob_arca,
                            b.val or 0
                            
    if b.val_min and b.val_max then 
      knob_val = (knob_val - b.val_min) / (b.val_max-b.val_min)
    end
    local arc_r = b.knob_arcR
    local knob_minside = b.knob_minside
    x,y,w,h = 
              x*DATA.GUI.default_scale,
              y*DATA.GUI.default_scale,           
              w*DATA.GUI.default_scale,            
              h*DATA.GUI.default_scale  
     
    local x_shift = w/2
    local ang_gr = 120
    if b.knob_showvalueright and b.txt_strw then x_shift = math.max(arc_r+2,w/2-(arc_r*2+b.txt_strw)/2) end
    local ang_val = math.rad(-ang_gr+ang_gr*2*knob_val)
    local ang = math.rad(ang_gr)
    local thickness = 1
    local y = y + b.knob_minside * 0.08
    -- arc back 
      DATA:GUIhex2rgb(knob_col, true)
      gfx.a = knob_arca
      local halfh = math.floor(h/2)
      local halfw = math.floor(w/2)
      for i = 0, thickness, 0.5 do DATA:GUIdraw_arc(x+x_shift,y+h/2,arc_r-i, -ang_gr, ang_gr, ang_gr) end
    
    -- value
      DATA:GUIhex2rgb(knob_col, true)
      gfx.a = knob_a
      if not b.knob_iscentered then 
        -- val       
        local ang_val = -ang_gr+ang_gr*2*knob_val
        for i = 0, thickness, 0.5 do
          DATA:GUIdraw_arc(x+x_shift,y+h/2,arc_r-i, -ang_gr, ang_val, ang_gr)
        end 
       else -- if centered
        for i = 0, thickness, 0.5 do
          if knob_val< 0.5 then
            DATA:GUIdraw_arc(x+x_shift,y+h/2 ,arc_r-i, -ang_gr+ang_gr*2*knob_val, 0, ang_gr)
           elseif knob_val> 0.5 then
            DATA:GUIdraw_arc(x+x_shift,y+h/2,arc_r-i, 0, -ang_gr+ang_gr*2*knob_val, ang_gr)
          end
        end
      end 
  end
  ---------------------------------------------------
  function DATA:GUIdraw_arc(x,y,r, start_ang, end_ang, lim_ang)
    local x = math.floor(x)
    local y = math.floor(y)
    local y_shift = 0
    local has_1st_segm = (start_ang <= -90) or (end_ang <= -90)
    local has_2nd_segm = (start_ang > -90 and start_ang <= 0) or (end_ang > -90 and end_ang <= 0) or (start_ang<=-90 and end_ang >= 0 )
    local has_3rd_segm = (start_ang >= 0 and start_ang <= 90) or (end_ang > 0 and end_ang <= 90) or (start_ang<=0 and end_ang >= 90 )
    local has_4th_segm = (start_ang > 90) or (end_ang > 90)
    
    if has_1st_segm then  gfx.arc(x,y+1 +y_shift,r, math.rad(math.max(start_ang,-lim_ang)), math.rad(math.min(end_ang, -90)),    1) end
    if has_2nd_segm then  gfx.arc(x,y+y_shift,r, math.rad(math.max(start_ang,-90)), math.rad(math.min(end_ang, 0)),    1) end
    if has_3rd_segm then gfx.arc(x+1,y+y_shift,r, math.rad(math.max(start_ang,0)), math.rad(math.min(end_ang, 90)),    1) end
    if has_4th_segm then  gfx.arc(x+1,y+1+y_shift,r, math.rad(math.max(start_ang,90)), math.rad(math.min(end_ang, lim_ang)),    1)  end
  end
  -----------------------------------------------------------------------------    
  function DATA:GUIdraw_Button(b)
    if b.list_islistparent then DATA:GUIdraw_List(b) return end
    
    if b.hide then return end
    local x,y,w,h, frame_a, frame_asel, back_sela,val =  
                            b.x or 0,
                            b.y or 0,
                            b.w or 100,
                            b.h or 100,
                            b.frame_a or DATA.GUI.default_framea_normal,
                            b.frame_asel or DATA.GUI.default_framea_selected,
                            b.back_sela or DATA.GUI.default_back_sela,
                            b.val or 0
                            
    local offsetframe = b.offsetframe or 0
    local offsetframe_a = b.offsetframe_a or 0
    local backgr_col = b.backgr_col or DATA.GUI.default_backgr
    local backgr_col2 = b.backgr_col2 or DATA.GUI.default_backgr
    local backgr_fill = b.backgr_fill or 1
    local backgr_fill2 = b.backgr_fill2 or 0
    local frame_col = b.frame_col
    local back_sel_recta = b.back_sel_recta
    local png = b.png
    
    x,y,w,h = 
              math.floor(x*DATA.GUI.default_scale),
              math.floor(y*DATA.GUI.default_scale),           
              math.ceil(w*DATA.GUI.default_scale),            
              math.ceil(h*DATA.GUI.default_scale)            
    b.knob_minside = math.min(w,h)
    b.knob_arcR = math.floor(b.knob_minside/2 ) -2 
    
    if not b.list_islistchild then
      local layer, layer_yshift= gfx.dest,0
      if DATA.GUI.layers[layer] and DATA.GUI.layers[layer].layer_yshift then layer_yshift = -DATA.GUI.layers[layer].layer_yshift end 
      if y+layer_yshift<-h or y+h+layer_yshift>gfx.h and not b.ignoreboundarylimit then return end 
    end
    
    -- backgr fill
      if backgr_fill ~= 0 then
        DATA:GUIhex2rgb(backgr_col, true)
        gfx.a =backgr_fill
        gfx.rect(x+1,y+1,w-1,h-1,1)
      end
      
    -- backgr fill 2
      if backgr_fill2 ~= 0 and backgr_col2 then
        DATA:GUIhex2rgb(backgr_col2, true)
        gfx.a =backgr_fill2
        if b.backgr_usevalue and b.val then 
          if not b.val_centered then 
            gfx.rect(x+1,y+1,math.floor(w*VF_lim(b.val))-1,h-1,1)
           else
            local rectw = math.floor( w*math.abs( b.val*0.5 )  )
            if b.val < 0 then 
              gfx.rect(x+1+w/2-rectw,y+1,rectw-1,h-1,1)
             else
              gfx.rect(x+1+w/2,y+1,rectw-1,h-1,1)
            end
          end
         else
          gfx.rect(x+1,y+1,w-1,h-1,1)
        end
      end
        
    -- latched by mouse
      if b.mouse_latch == true or (b.sel_allow and b.sel_isselected == true) then 
        gfx.set(1,1,1,back_sela)
        gfx.rect(x+1,y+1,w-1,h-1,1) 
        if back_sel_recta then 
          gfx.set(1,1,1,back_sel_recta)
          gfx.rect(x+1,y+1,w-1,h-1,0) 
        end
      end 
    
    -- png
      if png then 
        local img_temp = 512
        gfx.setimgdim(img_temp, -1, -1)  
        gfx.setpixel(1,1,1)
        img_temp = gfx.loadimg(img_temp,png )
        local iw,ih = gfx.getimgdim(img_temp )
        gfx.setimgdim(img_temp, iw,ih)  
        gfx.blit(img_temp, 1, 0, 0, 0, iw, ih, x, y, w, h, 0, 0 )
      end
      
    -- slider
      if b.slider_isslider then 
        gfx.set(1,1,1,1)
        local r = math.floor(w/2)
        gfx.circle(x+r,y+r + (h-r*2)*val,r,1)
      end
    
    -- val_data
      if GUI_RESERVED_draw_data2 then GUI_RESERVED_draw_data2(DATA, b) end -- before text
      
    -- txt
      b.txt_strw, b.txt_strh = DATA:GUIdraw_txt(b)
      
    -- knob
      if b.knob_isknob then DATA:GUIdraw_knob(b) end
    -- state 
      if b.state and b.state  == true then 
        local state_offs = 2
        local state_col = b.state_col or DATA.GUI.default_state_col
        DATA:GUIhex2rgb(state_col, true)
        gfx.a = DATA.GUI.default_state_a
        gfx.rect(x+state_offs+1,y+state_offs+1,w-state_offs*2-1,h-state_offs*2-1,1) 
      end 
      
    -- frame
      DATA:GUIhex2rgb(frame_col or DATA.GUI.default_frame_col, true)
      gfx.a = frame_a
      if b.mouse_match == true or b.mouse_latch == true then gfx.a = frame_asel end
      if gfx.a > 0 then 
        if b.frame_arcborder then 
          DATA:GUIdraw_rectarcborder(x,y,w,h,b.frame_arcborder, b.frame_arcborderflags, b.frame_arcborderr) 
         else
          DATA:GUIdraw_rect(x,y,w,h,0)  
        end
      end
    -- offsetframe
      if offsetframe > 0 and b.txt_strw and b.txt_strh then
        DATA:GUIhex2rgb(DATA.GUI.default_frame_col, true)
        gfx.a = offsetframe_a
        if gfx.a > 0 then 
          local offsetframe = offsetframe*DATA.GUI.default_scale
          gfx.x,gfx.y = x+offsetframe,y+offsetframe
          gfx.lineto(x+offsetframe,y+h-offsetframe)
          gfx.x,gfx.y = x+1+offsetframe,y+h-offsetframe
          gfx.lineto(x+w-offsetframe,y+h-offsetframe)
          gfx.x,gfx.y = x+w-offsetframe,y+h-1-offsetframe
          gfx.lineto(x+w-offsetframe,y+offsetframe)
          gfx.x,gfx.y = x+w-1-offsetframe,y+offsetframe
          gfx.lineto(x+w/2 + b.txt_strw/2+offsetframe,y+offsetframe)
          gfx.x,gfx.y = x+w/2-b.txt_strw/2-1-offsetframe,y+offsetframe
          gfx.lineto(x+ offsetframe,y + offsetframe)
        end
      end
      
      
    -- val_data
      if GUI_RESERVED_draw_data then GUI_RESERVED_draw_data(DATA, b) end
  end
  ---------------------------------------------------
  function DATA:GUImenu(t)
    local str, check ,hidden,submenu,submenu_end,subsubmenu_endmenu= '', '','','',''
    local remapped_functionsID = 0
    local inc = 0
    for i = 1, #t do
      remapped_functionsID = remapped_functionsID + 1
      local map0 = remapped_functionsID
      if t[i].state==true then check = '!' else check = '' end
      if t[i].hidden then hidden = '#' else hidden = '' end
      if t[i].submenu_end then submenu_end = '|<' else subsubmenu_endmenu = '' end
      if t[i].str == '' then map0 = -1 remapped_functionsID = remapped_functionsID -1 end--remapped_functionsID = 1 inc = inc + 1
      if t[i].submenu then submenu = '>'  map0 = -1 remapped_functionsID = remapped_functionsID -1 else submenu = '' end--remapped_functionsID = 0 inc = inc + 1
      t[i].map = map0
      str = str..submenu..check..hidden..t[i].str..submenu_end
      str = str..'|' 
    end
    gfx.x = DATA.GUI.x
    gfx.y = DATA.GUI.y
    local ret = gfx.showmenu(str) 
    for i = 1, #t do 
      --if t[i].map == ret then msg(t[i].str) end
      if t[i].map == ret and t[i].func then  
        t[i].func()
        break 
      end 
    end 
  end
-----------------------------------------------------------------------------  
  function DATA:GUIgetmousestate()
    DATA.GUI.char = math.floor(gfx.getchar())
    DATA.GUI.cap = gfx.mouse_cap
    DATA.GUI.x = gfx.mouse_x
    DATA.GUI.y = gfx.mouse_y
    DATA.GUI.ANY_release = false
    
    -- L/M/R button states
    DATA.GUI.LMB_state = gfx.mouse_cap&1 == 1 
    DATA.GUI.LMB_trig = DATA.GUI.LMB_state and not DATA.GUI.last_LMB_state
    DATA.GUI.LMB_release = DATA.GUI.LMB_state == false and DATA.GUI.last_LMB_state == true
    DATA.GUI.RMB_state = gfx.mouse_cap&2 == 2 
    DATA.GUI.RMB_trig = DATA.GUI.RMB_state and not DATA.GUI.last_RMB_state
    DATA.GUI.RMB_release = DATA.GUI.RMB_state == false and DATA.GUI.last_RMB_state == true
    DATA.GUI.MMB_state = gfx.mouse_cap&64 == 64
    DATA.GUI.MMB_trig = DATA.GUI.MMB_state and not DATA.GUI.last_MMB_state 
    DATA.GUI.MMB_release = DATA.GUI.MMB_state == false and DATA.GUI.last_MMB_state == true
    DATA.GUI.ANY_state = DATA.GUI.LMB_state or DATA.GUI.RMB_state or DATA.GUI.MMB_state
    DATA.GUI.ANY_trig = DATA.GUI.LMB_trig or DATA.GUI.RMB_trig or DATA.GUI.MMB_trig
    
    -- latchx/y 
    if DATA.GUI.ANY_trig then
      DATA.GUI.latchx = DATA.GUI.x
      DATA.GUI.latchy = DATA.GUI.y
    end
    if DATA.GUI.ANY_state then 
      DATA.GUI.dx = DATA.GUI.x - DATA.GUI.latchx
      DATA.GUI.dy = DATA.GUI.y - DATA.GUI.latchy
    end
    if not DATA.GUI.ANY_state and DATA.GUI.last_ANY_state then
      DATA.GUI.dx = 0
      DATA.GUI.dy = 0
      DATA.GUI.latchx = nil
      DATA.GUI.latchy = nil
    end 
    DATA.GUI.mouse_ismoving = DATA.GUI.last_x and DATA.GUI.last_y and (DATA.GUI.last_x ~= DATA.GUI.x or DATA.GUI.last_y ~= DATA.GUI.y)
    
    -- wheel
    DATA.GUI.wheel = gfx.mouse_wheel
    DATA.GUI.wheel_trig = DATA.GUI.last_wheel and DATA.GUI.last_wheel ~= DATA.GUI.wheel
    DATA.GUI.wheel_dir = DATA.GUI.last_wheel and DATA.GUI.last_wheel-DATA.GUI.wheel>0
    
    -- ctrl alt shift
    DATA.GUI.Ctrl = gfx.mouse_cap&4 == 4 
    DATA.GUI.Shift = gfx.mouse_cap&8 == 8 
    DATA.GUI.Alt = gfx.mouse_cap&16 == 16  
    DATA.GUI.hasAltkeys = not (DATA.GUI.Ctrl or DATA.GUI.Shift or DATA.GUI.Alt)
    
    -- handle states
    DATA.GUI.last_x = DATA.GUI.x
    DATA.GUI.last_y = DATA.GUI.y
    DATA.GUI.last_pointer = DATA.GUI.pointer
    DATA.GUI.last_LMB_state = DATA.GUI.LMB_state  
    DATA.GUI.last_RMB_state = DATA.GUI.RMB_state  
    DATA.GUI.last_MMB_state = DATA.GUI.MMB_state  
    DATA.GUI.last_ANY_state = DATA.GUI.ANY_state 
    DATA.GUI.last_wheel = DATA.GUI.wheel 
    
    -- handle drop stuff
    DATA.GUI.droppedfiles = {files = {}, exist = false}
    for i = 0, 1000 do
      local DRret, DRstr = gfx.getdropfile(i)
      if DRret == 0 then break end
      DATA.GUI.droppedfiles.files[i] = DRstr
      DATA.GUI.droppedfiles.exist = true
    end
    gfx.getdropfile(-1)
  end
-----------------------------------------------------------------------------  
  function DATA:handleProjUpdates()
    local SCC =  GetProjectStateChangeCount( 0 )
    if (DATA.UPD.lastSCC and DATA.UPD.lastSCC~=SCC ) then DATA.UPD.onprojstatechange = true end
    DATA.UPD.lastSCC = SCC
    
    local editcurpos =  GetCursorPosition() 
    if (DATA.UPD.last_editcurpos and DATA.UPD.last_editcurpos~=editcurpos ) then DATA.UPD.onprojstatechange = true end
    DATA.UPD.last_editcurpos=editcurpos 
    
    local reaproj = tostring(EnumProjects( -1 ))
    DATA.UPD.reaproj = reaproj
    if DATA.UPD.last_reaproj and DATA.UPD.last_reaproj ~= DATA.UPD.reaproj then DATA.UPD.onprojtabchange = true end
    DATA.UPD.last_reaproj = reaproj
  end
-----------------------------------------------------------------------------  
  function DATA:handleWindowUpdates()
    local  dock, wx,wy,ww,wh = gfx.dock(-1, 0,0,0,0)
    if not DATA.UPD.last_gfxx 
      or not DATA.UPD.last_gfxy 
      or not DATA.UPD.last_gfxw 
      or not DATA.UPD.last_gfxh 
      or not DATA.UPD.last_dock 
      then 
      DATA.UPD.last_gfxx, 
      DATA.UPD.last_gfxy, 
      DATA.UPD.last_gfxw, 
      DATA.UPD.last_gfxh, 
      DATA.UPD.last_dock = wx,wy,ww,wh, dock
    end
    if wx ~= DATA.UPD.last_gfxx or wy ~= DATA.UPD.last_gfxy then DATA.UPD.onXYchange = true  end -- XY position change
    if ww ~= DATA.UPD.last_gfxw or wh ~= DATA.UPD.last_gfxh or dock ~= DATA.UPD.last_dock then DATA.UPD.onWHchange = true end -- WH and dock change
    DATA.UPD.last_gfxx, DATA.UPD.last_gfxy, DATA.UPD.last_gfxw, DATA.UPD.last_gfxh, DATA.UPD.last_dock = wx,wy,ww,wh,dock 
    
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.wind_x =  wx
    DATA.extstate.wind_y =  wy
    DATA.extstate.wind_w =  ww
    DATA.extstate.wind_h =  wh
    DATA.extstate.dock =    dock
                          
    -- handle real gfx w/h change
    DATA.UPD.test_gfxw = gfx.w                      
    DATA.UPD.test_gfxh = gfx.h 
    if DATA.UPD.test_lastgfxw and (DATA.UPD.test_lastgfxw~= DATA.UPD.test_gfxw or DATA.UPD.test_lastgfxh~= DATA.UPD.test_gfxh) then DATA.UPD.onWHchange = true  end
    DATA.UPD.test_lastgfxw = DATA.UPD.test_gfxw                   
    DATA.UPD.test_lastgfxh = DATA.UPD.test_gfxh  
  end
  -----------------------------------------------------------------------------  
  function DATA:perform()
    if not DATA.perform_quere then return end
    for i = 1, #DATA.perform_quere do if DATA.perform_quere[i] then DATA.perform_quere[i]() end end
    DATA.perform_quere = {} --- clear
  end
    -----------------------------------------------------------------------------  
  function DATA:GUIhandleshortcuts2_BuildShortcutCache(section_id)-- https://forum.cockos.com/showpost.php?p=2620873&postcount=10
    local special_chars = {}
    special_chars[8] = 'Backspace'
    special_chars[9] = 'Tab'
    special_chars[13] = 'Enter'
    special_chars[27] = 'ESC'
    special_chars[32] = 'Space'
    special_chars[176] = '°'
    special_chars[26161] = 'F1'
    special_chars[26162] = 'F2'
    special_chars[26163] = 'F3'
    special_chars[26164] = 'F4'
    special_chars[26165] = 'F5'
    special_chars[26166] = 'F6'
    special_chars[26167] = 'F7'
    special_chars[26168] = 'F8'
    special_chars[26169] = 'F9'
    special_chars[6697264] = 'F10'
    special_chars[6697265] = 'F11'
    special_chars[6697266] = 'F12'
    special_chars[65105] = '﹑'
    special_chars[65106] = '﹒'
    special_chars[6579564] = 'Delete'
    special_chars[6909555] = 'Insert'
    special_chars[1752132965] = 'Home'
    special_chars[6647396] = 'End'
    special_chars[1885828464] = 'Page Up'
    special_chars[1885824110] = 'Page Down'
    
    DATA.GUI.shortcuts2[section_id] = {}
    -- Go through all actions of the section
      local sec = reaper.SectionFromUniqueID(section_id)
      for i = 0, 100000 do
        local cmd = reaper.kbd_enumerateActions(sec, i)
        if cmd == 0 then break end
        for n = 0, reaper.CountActionShortcuts(sec, cmd) - 1 do
          local _, desc = reaper.GetActionShortcutDesc(sec, cmd, n, '')
          DATA.GUI.shortcuts2[desc] = cmd
        end
      end
      
    DATA.GUI.shortcuts2.special_chars = special_chars
    
    DATA.GUI.shortcuts2.cached = true
  end
      -----------------------------------------------------------------------------  
  function DATA:GUIhandleshortcuts2_ConvertCharToShortcut(char)-- https://forum.cockos.com/showpost.php?p=2620873&postcount=10
      local is_ctrl = gfx.mouse_cap & 4 == 4
      local is_shift = gfx.mouse_cap & 8 == 8
      local is_alt = gfx.mouse_cap & 16 == 16
  
      local key
  
      -- Check for special characters, avoid 1..26 (Ctrl+A..Z)
      if not (is_ctrl and char <= 26) then key = DATA.GUI.shortcuts2.special_chars[char] end
  
      if not key then
          -- Add offset for 1..26 (Ctrl+A..Z)
          if char >= 1 and char <= 26 then char = char + 64 end
          -- Add offset for 257..282 (Ctrl+Alt+A..Z)
          if char >= 257 and char <= 282 then char = char - 192 end
          -- Convert char to key string
          key = string.char(char & 0xFF):upper()
      end
  
      -- Add keyboard modifiers in text form
      if is_shift and key ~= key:lower() then key = 'Shift+' .. key end
      if is_alt then key = 'Alt+' .. key end
      if is_ctrl then key = 'Ctrl+' .. key end
  
      return key
  end
  -----------------------------------------------------------------------------
  function DATA:GUIhandleshortcuts2() 
    local char = DATA.GUI.char
    if char == 0 then return end
    local shortcut = DATA:GUIhandleshortcuts2_ConvertCharToShortcut(char)-- https://forum.cockos.com/showpost.php?p=2620873&postcount=10
    if DATA.GUI.shortcuts2 then 
      if DATA.GUI.shortcuts2.custom and DATA.GUI.shortcuts2.custom[shortcut] then VF_Action(DATA.GUI.shortcuts2.custom[shortcut], 0) return end
      if DATA.GUI.shortcuts2[shortcut] then VF_Action(DATA.GUI.shortcuts2[shortcut]) end
    end
  end
  -----------------------------------------------------------------------------  
  function DATA:GUIhandleshortcuts() 
    if DATA.GUI.shortcuts2 then 
      if not DATA.GUI.shortcuts2.cached then
        DATA:GUIhandleshortcuts2_BuildShortcutCache(0)
       else 
        DATA:GUIhandleshortcuts2() 
      end
      return
    end
    
    for key in pairs(DATA.GUI.shortcuts) do
      if key == DATA.GUI.char and DATA.GUI.shortcuts[key] then
        DATA.GUI.shortcuts[key]()
      end
    end
  end
-----------------------------------------------------------------------------  
  function RUN()
    DATA.cnt = (DATA.cnt  or 0 )+ 1
    if not DATA.UPD then DATA.UPD = {onGUIinit = true } end
      
    -- data
      DATA:handleProjUpdates()
      DATA:handleWindowUpdates() 
      DATA:perform()-- perform stuff in queue
    
    -- dynamic handle stuff
      DATA:GUIgetmousestate()
      DATA:GUIhandleshortcuts()
      DATA:GUIhandlemousestate() -- create a quere for performing stuff
      DATA:GUIdraw() -- draw stuff 
      
      if DATA.UPD.onconfchange == true or DATA.UPD.onXYchange == true or DATA.UPD.onWHchange == true then DATA:ExtStateSet() DATA:ExtStateGet()  end
      if DATA.UPD.onWHchange == true or DATA.UPD.onGUIinit == true then if GUI_RESERVED_init then GUI_RESERVED_init(DATA) end DATA.GUI.firstloop = 1 end
    
      if DATA.UPD.onprojstatechange == true and DATA_RESERVED_ONPROJCHANGE then DATA_RESERVED_ONPROJCHANGE(DATA) end
      if DATA.UPD.oncustomstatechange == true and DATA_RESERVED_ONCUSTSTATECHANGE then DATA_RESERVED_ONCUSTSTATECHANGE(DATA) end
      if DATA_RESERVED_DYNUPDATE then DATA_RESERVED_DYNUPDATE(DATA) end
      
    -- reset triggers
      DATA.UPD.onconfchange = false
      DATA.UPD.onGUIinit = false
      DATA.UPD.onXYchange = false
      DATA.UPD.onWHchange = false
      DATA.UPD.onprojstatechange = false
      DATA.UPD.onprojtabchange = false
      
    -- main loop
      if DATA.GUI.char >= 0 and DATA.GUI.char ~= 27 then defer(RUN) else atexit(gfx.quit) end -- exit on escape
  end 
  ---------------------------------------------------------------------  
  function DATA:GUIquantizeXYWH(b)
    if not (b  and b.x and b.y and b.w and b.h ) then return end
    b.x = math.floor(b.x)
    b.y = math.floor(b.y)
    b.w = math.floor(b.w)
    b.h = math.floor(b.h)
  end
-----------------------------------------------------------------------------  
  function DATA:GUIdraw() 
    if not DATA.GUI.firstloop then DATA.GUI.firstloop = 1 end
    if not DATA.GUI.layers then DATA.GUI.layers = {} end
    if not DATA.GUI.layers[1] then DATA.GUI.layers[1] = {a=1} end -- Main back
    if not DATA.GUI.layers[2] then DATA.GUI.layers[2] = {a=1} end -- Main buttons
    --if not DATA.GUI.layers[3] then DATA.GUI.layers[3] = {a=1} end -- Alt back
    --if not DATA.GUI.layers[4] then DATA.GUI.layers[4] = {a=1} end -- Alt buttons
    -- 10 - 20 reserved
    --if not DATA.GUI.layers[21] then DATA.GUI.layers[21] = {a=1} end -- Dynamic stuff 1 -- typically settings list
    --if not DATA.GUI.layers[22] then DATA.GUI.layers[22] = {a=1} end -- Dynamic stuff 2 -- typically scrollable list
    -- 32 reserved fo PNG blit option
    
    
    if not DATA.GUI.layers_refresh  then DATA.GUI.layers_refresh = {} end
    local upd_customlayers = false
    if DATA.GUI.buttons then
      for but in pairs(DATA.GUI.buttons) do 
        local but_t = DATA.GUI.buttons[but]
        if but_t.refresh ==true then 
          local layer = but_t.layer or 2
          if layer and layer ~= 2 then 
            upd_customlayers = true 
            DATA.GUI.layers_refresh[layer] = true
           elseif layer == 2 then 
            DATA.GUI.layers_refresh[2] = true
          end
          but_t.refresh = false
        end
      end
    end
    
    if DATA.GUI.firstloop == 1 or DATA.UPD.onWHchange == true then DATA:GUIdraw_Layer1_MainBack() end
    if DATA.GUI.firstloop == 1 or DATA.UPD.onWHchange == true or DATA.GUI.layers_refresh[2] then DATA:GUIdraw_Layer2_MainButtons() end--msg(os.clock())
    if DATA.GUI.firstloop == 1 or DATA.UPD.onWHchange == true or upd_customlayers == true then DATA:GUIdraw_LayerCustom() end
    
    gfx.mode = 0
    for layer in spairs(DATA.GUI.layers )do
      gfx.set(1,1,1,1)
      gfx.dest = -1   
      if DATA.GUI.layers[layer].a and DATA.GUI.layers[layer].a == 0 then goto skip_layerdraw end
      gfx.a = DATA.GUI.layers[layer].a or 1
      gfx.x,gfx.y = 0,0
      local w,h = gfx.w, gfx.h
      if layer==1 then w= math.min(gfx.h, math.min(gfx.w, 200))h=w end
      local destx,desty,destw,desth = 0, 0, gfx.w, gfx.h
      local srcx,srcy,srcw,srch =  0, 0, w, h
      
      if DATA.GUI.layers[layer]  then
        if DATA.GUI.layers[layer].layer_x then destx = DATA.GUI.layers[layer].layer_x*DATA.GUI.default_scale end
        if DATA.GUI.layers[layer].layer_y then desty = DATA.GUI.layers[layer].layer_y*DATA.GUI.default_scale end
        if DATA.GUI.layers[layer].layer_w then srcw = DATA.GUI.layers[layer].layer_w*DATA.GUI.default_scale destw = srcw end
        if DATA.GUI.layers[layer].layer_h then srch = DATA.GUI.layers[layer].layer_h*DATA.GUI.default_scale desth = srch end
        if DATA.GUI.layers[layer].scrollval and DATA.GUI.layers[layer].layer_hmeasured and DATA.GUI.layers[layer].layer_h and DATA.GUI.layers[layer].layer_hmeasured > DATA.GUI.layers[layer].layer_h then 
          local reallayerh = (DATA.GUI.layers[layer].layer_hmeasured  - DATA.GUI.layers[layer].layer_h)*DATA.GUI.default_scale
          srcy = math.floor(srcy + DATA.GUI.layers[layer].scrollval*  reallayerh)
          DATA.GUI.layers[layer].layer_yshift = srcy
        end
        
      end
      gfx.blit(layer, 1, 0, 
          srcx,srcy,srcw,srch,
          destx,desty,destw,desth, 0,0) 
      ::skip_layerdraw::
    end
    
    if GUI_RESERVED_drawDYN then GUI_RESERVED_drawDYN(DATA) end -- draw dynamic stuff if any
    
    DATA.GUI.layers_refresh  = {} -- clear
    
    gfx.update()
    DATA.GUI.firstloop = 0
  end
  -----------------------------------------------------------------------------  
  function DATA:GUIdraw_Layer1_MainBack() 
    -- draw grey gradient
      local gradback_sz = DATA.GUI.gradback_sz or math.min(gfx.h, math.min(gfx.w, 200))
      if not DATA.GUI.gradback_col then DATA.GUI.gradback_col = DATA.GUI.default_backgr end
      gfx.dest = 1
      gfx.setimgdim(1, -1, -1)  
      gfx.setimgdim(1, gfx.w, gfx.h)  
      gfx.set(0,0,0,1) 
      gfx.rect(0,0,gfx.w,gfx.h)
      local r,g,b = DATA:GUIhex2rgb(DATA.GUI.gradback_col)
      gfx.x, gfx.y = 0,0
      local cx =1
      local cy =1
      local a=1
      local drdx = cx*0.00001
      local drdy = cy*0.00001
      local dgdx = cx*0.00001
      local dgdy = cy*0.00001    
      local dbdx = cx*0.00001
      local dbdy = cy*0.00001
      local dadx = 0--c*0.00001
      local dady = 0--c*0.00001      
      gfx.gradrect(0,0, gradback_sz,gradback_sz, 
                      r,g,b,a, 
                      drdx, dgdx, dbdx, dadx, 
                      drdy, dgdy, dbdy, dady)
  end
  -----------------------------------------------------------------------------  
  function DATA:GUIdraw_Layer2_MainButtons()
    gfx.dest = 2
    gfx.setimgdim(2, -1, -1)  
    gfx.setimgdim(2, gfx.w, gfx.h) 
    --gfx.set(0,0,0,1)
    --gfx.rect(0,0,gfx.w,gfx.h)
    if not (DATA.GUI and DATA.GUI.buttons) then return end
    local b
    for but in spairs(DATA.GUI.buttons ) do 
      b = DATA.GUI.buttons[but]
      if b and not b.layer then DATA:GUIdraw_Button(b) end
    end
  end
  -----------------------------------------------------------------------------  
  function DATA:GUIdraw_LayerCustom()
    if not (DATA.GUI and DATA.GUI.buttons) then return end
    local activelayers = {}
    local b
    for but in spairs(DATA.GUI.buttons ) do 
      b = DATA.GUI.buttons[but]
      if b.layer and (DATA.GUI.layers_refresh[b.layer] or DATA.GUI.firstloop == 1 ) then 
        if not activelayers[b.layer]and DATA.GUI.layers[b.layer] then
          gfx.dest = b.layer
          gfx.setimgdim(b.layer, -1, -1)  
          local layer_hmeasured = 0
          if DATA.GUI.layers[b.layer].layer_h then layer_hmeasured = DATA.GUI.layers[b.layer].layer_hmeasured or DATA.GUI.layers[b.layer].layer_h end
          gfx.setimgdim(b.layer, DATA.GUI.layers[b.layer].layer_w*DATA.GUI.default_scale, layer_hmeasured*DATA.GUI.default_scale) 
          activelayers[b.layer] = true
        end
        gfx.dest = b.layer
        gfx.a = 1 
        b.y= b.y
        DATA:GUIdraw_Button(b) 
      end
    end
  end  
  
  -----------------------------------------------------------------------------  
  function DATA:GUIdraw_rect(x,y,w,h)
    gfx.x,gfx.y = x,y
    gfx.lineto(x,y+h)
    gfx.x,gfx.y = x+1,y+h
    gfx.lineto(x+w,y+h)
    gfx.x,gfx.y = x+w,y+h-1
    gfx.lineto(x+w,y)
    gfx.x,gfx.y = x+w-1,y
    gfx.lineto(x+1,y)
  end 
  ----------------------------------------------------------------------------- 
  function DATA:GUIdraw_rectarcborder(x,y,w,h,arcborder0, arcborderflags, arcborderr) 
    local arcborder = arcborderr or math.floor(w*DATA.GUI.default_button_framew_arcratio)
    if type(arcborder0)== 'number' then arcborder = arcborder0 end 
    local aa =1
    if not arcborderflags then arcborderflags = 1|2|4|8 end
    
      
    -- draw lines
    gfx.x,gfx.y = x+w-1-arcborder,y
    gfx.lineto(x+1+arcborder,y) -- top 
    
    gfx.x,gfx.y = x+1+arcborder,y+h 
    gfx.lineto(x+w-arcborder-1,y+h) -- bottom
    
    gfx.x,gfx.y = x+w,y+h-1-arcborder
    gfx.lineto(x+w,y+arcborder+1) -- side right 
    
    gfx.x,gfx.y = x,y+arcborder+1
    gfx.lineto(x,y+h-arcborder-1) -- side left 
    
    -- draw arcs
    
    if arcborderflags&1==1 then  
      gfx.arc(x+arcborder,y+arcborder,arcborder,math.rad(0),math.rad(-90),aa ) -- top left
     else
      gfx.line(x+arcborder,y,x,y) 
      gfx.line(x,y,x,y+arcborder)
    end
    if arcborderflags&2==2 then  
      gfx.arc(x+w-arcborder,y+arcborder,arcborder,math.rad(0),math.rad(90),aa )-- top right
     else
      gfx.line(x+w-arcborder,y,x+w,y) 
      gfx.line(x+w,y,x+w,y+arcborder)
    end
    if arcborderflags&4==4 then  
      gfx.arc(x+w-arcborder,y+h-arcborder,arcborder,math.rad(180),math.rad(90),aa ) -- bot right
     else
      gfx.line(x+w,y+h-arcborder,x+w,y+h)
      gfx.line(x+w,y+h,x+w-arcborder,y+h) 
    end
    if arcborderflags&8==8 then 
      gfx.arc(x+arcborder,y+h-arcborder,arcborder,math.rad(180),math.rad(270),aa ) -- bot left
     else
      gfx.line(x+arcborder,y+h,x,y+h) 
      gfx.line(x,y+h,x,y+h-arcborder)
    end
  end
  ----------------------------------------------------------------------------- 
  function DATA:GUIhex2rgb(s16,set)
    if not s16 then return end
    if type(s16) =='string' then 
      s16 = s16:gsub('#',''):gsub('0X',''):gsub('0x','')
      int = tonumber(s16, 16)
      else return
    end
    local b,g,r = ColorFromNative(int)
    if set then
      if GetOS():match('Win') then gfx.set(r/255,g/255,b/255) else gfx.set(b/255,g/255,r/255) end
    end
    return r/255, g/255, b/255
  end
  ---------------------------------------------------------------------    
  function DATA:GUIbut_preset(preset_dontchangebutton)
    -- form presets menu    
      local presets_t = {
        {str = 'Reset all settings to default',
          func = function() 
                    DATA.extstate.current_preset = nil
                    if DATA.GUI.buttons.preset then DATA.GUI.buttons.preset.txt = 'Preset: default' end
                    DATA:ExtStateRestoreDefaults() 
                    DATA.GUI.firstloop = 1 
                    DATA.UPD.onconfchange = true 
                    DATA:GUIBuildSettings()
                    --DATA:GUIgeneratelisttable( GUI_settingst(DATA2,DATA, DATA.GUI.buttons.settingslist, DATA.GUI.buttons.settings_scroll) ) 
                  end},
        {str = 'Save current preset',
        func = function() 
                  local id 
                  if DATA.extstate.current_preset then id = DATA.extstate.current_preset end
                  local retval, retvals_csv = reaper.GetUserInputs( 'Save current preset', 1, 'preset name', DATA.extstate.CONF_NAME )
                  if not retval then return end
                  if retvals_csv~= '' then DATA.extstate.CONF_NAME = retvals_csv end
                  DATA:ExtStateStorePreset(id) 
                  DATA:ExtStateGetPresets()
                  if DATA.GUI.buttons.preset then DATA.GUI.buttons.preset.refresh = true  end
                  DATA.GUI.firstloop = 1 
                  DATA.UPD.onconfchange = true 
                  DATA:GUIBuildSettings()
                  --DATA:GUIgeneratelisttable( GUI_settingst(DATA2,DATA, DATA.GUI.buttons.settingslist, DATA.GUI.buttons.settings_scroll) ) 
                end
        }, 
        {str = 'Rename current preset',
        func = function() 
                  local id 
                  if not DATA.extstate.current_preset then return else id = DATA.extstate.current_preset end
                  local retval, retvals_csv = reaper.GetUserInputs( 'Save current preset', 1, 'preset name', DATA.extstate.CONF_NAME )
                  if not retval then return end
                  if retvals_csv~= '' then DATA.extstate.CONF_NAME = retvals_csv end
                  DATA:ExtStateStorePreset(id) 
                  DATA:ExtStateGetPresets()
                  if DATA.GUI.buttons.preset then DATA.GUI.buttons.preset.refresh = true end
                  if DATA.GUI.buttons.preset then DATA.GUI.buttons.preset.txt = 'Preset: '..(DATA.extstate.CONF_NAME or '') end
                  DATA.GUI.firstloop = 1 
                  DATA.UPD.onconfchange = true 
                  DATA:GUIBuildSettings()
                  --DATA:GUIgeneratelisttable( GUI_settingst(DATA2,DATA, DATA.GUI.buttons.settingslist, DATA.GUI.buttons.settings_scroll) ) 
                end
        },                                                   
        {str = 'Save current preset as new',
        func = function() 
                  local id 
                  local retval, retvals_csv = reaper.GetUserInputs( 'Save current preset', 1, 'preset name', DATA.extstate.CONF_NAME )
                  if not retval then return end
                  if retvals_csv~= '' then DATA.extstate.CONF_NAME = retvals_csv end
                  DATA:ExtStateStorePreset() 
                  DATA:ExtStateGetPresets()
                  if DATA.GUI.buttons.preset then DATA.GUI.buttons.preset.refresh = true end
                  DATA.GUI.firstloop = 1 
                  DATA.UPD.onconfchange = true 
                  DATA:GUIBuildSettings()
                  --DATA:GUIgeneratelisttable( GUI_settingst(DATA2, DATA, DATA.GUI.buttons.settingslist, DATA.GUI.buttons.settings_scroll) ) 
                end
        },     
        {str = 'Remove current preset',
        func = function()
                  if DATA.extstate.current_preset then 
                    DATA:ExtStatePresetRemove(DATA.extstate.current_preset)
                    DATA.extstate.presets[DATA.extstate.current_preset] = nil
                    DATA.extstate.current_preset = nil
                  end
                  local id 
                  DATA:ExtStateGetPresets()
                  if DATA.GUI.buttons.preset then DATA.GUI.buttons.preset.refresh = true end
                  DATA.GUI.firstloop = 1 
                  DATA.UPD.onconfchange = true 
                  DATA:GUIBuildSettings()
                  --DATA:GUIgeneratelisttable( GUI_settingst(DATA2, DATA, DATA.GUI.buttons.settingslist, DATA.GUI.buttons.settings_scroll) ) 
                end
        },                                                    
        {str = ''},
        {str = '#Preset list'},
                        }
    -- add preset list    
      for i = 1, #DATA.extstate.presets do
        local state = DATA.extstate.current_preset and DATA.extstate.current_preset == i
        
        presets_t[#presets_t+1] = { str = DATA.extstate.presets[i].CONF_NAME or '[no name]',
                                    func = function()  
                                              DATA:ExtStateApplyPreset(DATA.extstate.presets[i]) 
                                              DATA.extstate.current_preset = i
                                              if not (preset_dontchangebutton and type(preset_dontchangebutton) == 'boolean' and preset_dontchangebutton == true) then
                                                if DATA.GUI.buttons.preset then DATA.GUI.buttons.preset.refresh = true end
                                                if DATA.GUI.buttons.preset then DATA.GUI.buttons.preset.txt = 'Preset: '..(DATA.extstate.CONF_NAME or '') end
                                                DATA.GUI.firstloop = 1 
                                                DATA.UPD.onconfchange = true 
                                                DATA:GUIBuildSettings()
                                              end
                                            end,
                                    state = state,
        
          
                                    }
      end
    -- form table
      DATA:GUImenu(presets_t)  
    end
-----------------------------------------------------------------------------  
  function DATA:GUIinit()
    DATA.GUI.custom_layerset= 21 -- settings layer idx
    DATA.GUI.custom_layerset2= 22 -- scrollable list layer idx
    DATA.GUI.doubleclicktime = 0.4 -- s
    
    
    local title = DATA.extstate.mb_title or ''
    if DATA.extstate.version then title = title..' '..DATA.extstate.version end
              
    DATA.GUI.default_backgr = '#333333' --grey
    DATA.GUI.default_back_sela = 0.1 -- pressed button
    
    DATA.GUI.default_frame_col = '#FFFFFF'
    DATA.GUI.default_framea_normal = 0.4
    DATA.GUI.default_framea_selected = 0.6 -- mouse hovered
    DATA.GUI.default_state_col = '#FFFFFF'
    DATA.GUI.default_state_a = 0.7
    
    DATA.GUI.default_data_col = '#FFFFFF'
    DATA.GUI.default_data_col_adv = '#00ff00' -- green
    DATA.GUI.default_data_col_adv2 = '#e61919 ' -- red
    
    DATA.GUI.default_knob_col = '#FFFFFF' -- white
    DATA.GUI.default_knob_a = 0.9
    DATA.GUI.default_knob_arca = 0.1
    
    DATA.GUI.default_txt_col = '#FFFFFF'
    DATA.GUI.default_txt_flags = 1|4
    DATA.GUI.default_txt_font = 'Arial'
    DATA.GUI.default_txt_fontsz = 15 -- settings
    DATA.GUI.default_txt_fontsz2 = 20 -- preset names, buttons
    DATA.GUI.default_txt_a = 0.9
    DATA.GUI.default_txt_a_inactive = 0.3
    
    
    DATA.GUI.default_tooltipxoffs = 10
    DATA.GUI.default_tooltipyoffs = 0
    
    DATA.GUI.default_button_framew_arcratio = 0.1
    
    
    
    -- perform retina scaling -- https://forum.cockos.com/showpost.php?p=2493416&postcount=40
      local OS = reaper.GetOS()
      DATA.GUI.default_font_coeff = 1
      DATA.GUI.default_scale = 1
      gfx.ext_retina = 1 -- init with 1 
      gfx.init( title,
                DATA.extstate.wind_w or 100,
                DATA.extstate.wind_h or 100,
                DATA.extstate.dock or 0, 
                DATA.extstate.wind_x or 100, 
                DATA.extstate.wind_y or 100)
      
      local retinatest =0
      if DATA.GUI.default_scale ~= gfx.ext_retina or retinatest ~= 0 then -- dpi changed (either initially or from the user moving the window or the OS changing
        DATA.GUI.default_scale = gfx.ext_retina
        if retinatest ~= 0 then DATA.GUI.default_scale = retinatest end
        DATA.GUI.default_font_coeff = (1+DATA.GUI.default_scale)*0.5 
        -- Resize manually gfx window, if not MacOS
        if (OS ~= "OSX64" and OS ~= "OSX32" and OS ~= "macOS-arm64") or retinatest ~= 0 then
          gfx.quit()
          gfx.init( title,
                  DATA.extstate.wind_w or 100,
                  DATA.extstate.wind_h or 100,
                  DATA.extstate.dock or 0, 
                  DATA.extstate.wind_x or 100, 
                  DATA.extstate.wind_y or 100)
            
        end
      end
      
    DATA.GUI.default_listentryh = 20--*DATA.GUI.default_scale
    DATA.GUI.default_listentryxoffset = 5--*DATA.GUI.default_scale
    DATA.GUI.default_listentryframea = 0.4
    DATA.GUI.default_offset =10--*DATA.GUI.default_scale
  end
  ----------------------------------------------------------------------------------------------------------------
  function DATA:GUIdraw_List(b_parent)
    if not b_parent.list_islistparent then return end
    local parentlistID = b_parent.list_islistparent or 0
    local x,y,w,h =  
                            b_parent.x or 0,
                            b_parent.y or 0,
                            b_parent.w or 100,
                            b_parent.h or 100
    x,y,w,h = 
              math.floor(x*DATA.GUI.default_scale),
              math.floor(y*DATA.GUI.default_scale),           
              math.ceil(w*DATA.GUI.default_scale),            
              math.ceil(h*DATA.GUI.default_scale)  
    
    gfx.set(1,1,1,0.2)
    gfx.rect(x,y,w,h,1)
    
    -- calc common dimensions
    b_parent.childrendata  = {}
    for but in spairs(DATA.GUI.buttons ) do 
      b = DATA.GUI.buttons[but]
      if b and b.list_islistchild then 
        local childlistID = b.list_islistchild or 0
        if childlistID and childlistID == parentlistID then 
          local x,y,w,h =  
                                  b.x or 0,
                                  b.y or 0,
                                  b.w or 100,
                                  b.h or 100
          b_parent.childrendata.minx = math.min(b_parent.childrendata.minx or gfx.w, x)
          b_parent.childrendata.maxx = math.min(b_parent.childrendata.minx or 0, x)
        end--DATA:GUIdraw_Button(b) 
      end
    end
    
    
    -- draw
    for but in spairs(DATA.GUI.buttons ) do 
      b = DATA.GUI.buttons[but]
      if b and b.list_islistchild then DATA:GUIdraw_Button(b) end
    end
    
  end
  ----------------------------------------------------------------------------------------------------------------
  function DATA:GUIBuildLayer()
    if not DATA.GUI.buttons.Rlayer then return end
    local custom_scrollw = DATA.GUI.custom_scrollw or 10
    local custom_offset = DATA.GUI.custom_offset or  math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
    local custom_frameascroll = 0.3
    DATA.GUI.buttons.Rlayerlist_mouse = { x=DATA.GUI.buttons.Rlayer.x +custom_offset*2, -- for scrolling
                          y=DATA.GUI.buttons.Rlayer.y+custom_offset*2,
                          w=DATA.GUI.buttons.Rlayer.w-custom_offset*5-custom_scrollw,
                          h=DATA.GUI.buttons.Rlayer.h-custom_offset*4  , 
                          txt = 'list',
                          frame_a = 1,
                          --layer = DATA.GUI.custom_layerset2,
                          hide = true,
                          --ignoremouse = true,
                          onwheeltrig = function() 
                                          local dir = 1
                                          local layer= DATA.GUI.custom_layerset2
                                          if DATA.GUI.wheel_dir then dir = -1 end
                                          DATA.GUI.layers[layer].scrollval = VF_lim(DATA.GUI.layers[layer].scrollval - 0.1 * dir)
                                          --DATA.GUI.buttons[key].refresh = true
                                          if DATA.GUI.buttons.Rlayer_scroll then 
                                            DATA.GUI.buttons.Rlayer_scroll.refresh = true
                                            DATA.GUI.buttons.Rlayer_scroll.val = DATA.GUI.layers[layer].scrollval
                                          end
                                        end,}                               
    DATA:GUIquantizeXYWH(DATA.GUI.buttons.Rlayerlist)
    
    if not DATA.GUI.layers[DATA.GUI.custom_layerset2] then DATA.GUI.layers[DATA.GUI.custom_layerset2] = {} end
    if not DATA.GUI.layers[DATA.GUI.custom_layerset2].scrollval then DATA.GUI.layers[DATA.GUI.custom_layerset2].scrollval=0 end
    
    if not DATA.GUI.buttons.Rlayer_scroll then 
      DATA.GUI.buttons.Rlayer_scroll = { x=DATA.GUI.buttons.Rlayer.x+DATA.GUI.buttons.Rlayer.w-custom_scrollw,---custom_offset*2,
                          y=DATA.GUI.buttons.Rlayer.y,
                          w=custom_scrollw,
                          h=DATA.GUI.buttons.Rlayer.h,
                          frame_a = custom_frameascroll,
                          frame_asel = custom_frameascroll,
                          val = 0,
                          val_res = -1,
                          slider_isslider = true,
                          hide = DATA.GUI.compactmode==1,
                          ignoremouse = DATA.GUI.compactmode==1,
                          onmousedrag = function() 
                            DATA.GUI.layers[DATA.GUI.custom_layerset2].scrollval = DATA.GUI.buttons.Rlayer_scroll.val 
                            DATA.GUI.buttons.Rlayer.refresh = true
                          end
                          }
    end                     
    DATA.GUI.layers[DATA.GUI.custom_layerset2].a=1
    DATA.GUI.layers[DATA.GUI.custom_layerset2].hide = DATA.GUI.compactmode==1
    DATA.GUI.layers[DATA.GUI.custom_layerset2].layer_x = 0--DATA.GUI.buttons.Rlayerlist.x
    DATA.GUI.layers[DATA.GUI.custom_layerset2].layer_y = DATA.GUI.buttons.Rlayer.y
    DATA.GUI.layers[DATA.GUI.custom_layerset2].layer_yshift = 0
    DATA.GUI.layers[DATA.GUI.custom_layerset2].layer_w = DATA.GUI.buttons.Rlayer.w-custom_scrollw
    if DATA.GUI.buttons.Rlayer.noscroll == true then DATA.GUI.layers[DATA.GUI.custom_layerset2].layer_w = DATA.GUI.buttons.Rlayer.w end
    DATA.GUI.layers[DATA.GUI.custom_layerset2].layer_h = DATA.GUI.buttons.Rlayer.h
    local layer_h = 0
    if GUI_RESERVED_BuildLayer then layer_h  = GUI_RESERVED_BuildLayer(DATA) end
    DATA.GUI.layers[DATA.GUI.custom_layerset2].layer_hmeasured = layer_h 
  end
  ----------------------------------------------------------------------------------------------------------------
  function DATA:GUIBuildSettings()
    if not DATA.GUI.buttons.Rsettings then return end
    local custom_scrollw = DATA.GUI.custom_scrollw or 10
    local custom_offset = DATA.GUI.custom_offset or  math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
    DATA.GUI.buttons.Rsettingslist = { x=DATA.GUI.buttons.Rsettings.x +custom_offset*2,
                          y=DATA.GUI.buttons.Rsettings.y+custom_offset*2,
                          w=DATA.GUI.buttons.Rsettings.w-custom_offset*5-custom_scrollw,
                          h=DATA.GUI.buttons.Rsettings.h-custom_offset*4  , 
                          txt = 'list',
                          frame_a = 0,
                          layer = DATA.GUI.custom_layerset,
                          hide = true,
                          ignoremouse = true,}  
    DATA.GUI.buttons.Rsettingslist_mouse = { x=DATA.GUI.buttons.Rsettings.x +custom_offset*2, -- for scrolling
                          y=DATA.GUI.buttons.Rsettings.y+custom_offset*2,
                          w=DATA.GUI.buttons.Rsettings.w-custom_offset*5-custom_scrollw,
                          h=DATA.GUI.buttons.Rsettings.h-custom_offset*4  , 
                          txt = 'list',
                          frame_a = 1,
                          --layer = DATA.GUI.custom_layerset,
                          hide = true,
                          --ignoremouse = true,
                          onwheeltrig = function() 
                                          local dir = 1
                                          local layer= DATA.GUI.custom_layerset
                                          if DATA.GUI.wheel_dir then dir = -1 end
                                          DATA.GUI.layers[layer].scrollval = VF_lim(DATA.GUI.layers[layer].scrollval - 0.1 * dir)
                                          --DATA.GUI.buttons[key].refresh = true
                                          if DATA.GUI.buttons.Rsettings_scroll then 
                                            DATA.GUI.buttons.Rsettings_scroll.refresh = true
                                            DATA.GUI.buttons.Rsettings_scroll.val = DATA.GUI.layers[layer].scrollval
                                          end
                                        end,}                               
    DATA:GUIquantizeXYWH(DATA.GUI.buttons.Rsettingslist)
    
    if not DATA.GUI.layers[DATA.GUI.custom_layerset] then DATA.GUI.layers[DATA.GUI.custom_layerset] = {} end
    if not DATA.GUI.layers[DATA.GUI.custom_layerset].scrollval then DATA.GUI.layers[DATA.GUI.custom_layerset].scrollval=0 end
    
    if not DATA.GUI.buttons.Rsettings_scroll then 
      DATA.GUI.buttons.Rsettings_scroll = { x=DATA.GUI.buttons.Rsettings.x+DATA.GUI.buttons.Rsettings.w-custom_scrollw-custom_offset*2,
                          y=DATA.GUI.buttons.Rsettings.y+custom_offset*2,
                          w=custom_scrollw,
                          h=DATA.GUI.buttons.Rsettings.h-custom_offset*4,
                          frame_a = DATA.GUI.custom_frameascroll or 0.05,
                          frame_asel = DATA.GUI.custom_frameascroll or 0.05,
                          val = 0,
                          val_res = -1,
                          slider_isslider = true,
                          hide = DATA.GUI.compactmode==1,
                          ignoremouse = DATA.GUI.compactmode==1,
                          onmousedrag = function() 
                            DATA.GUI.layers[DATA.GUI.custom_layerset].scrollval = DATA.GUI.buttons.Rsettings_scroll.val 
                            DATA.GUI.buttons.Rsettingslist.refresh = true
                          end,
                          onmouserelease = function() 
                            DATA.GUI.buttons.Rsettingslist.refresh = true
                          end
                          }
    end                     
    DATA.GUI.layers[DATA.GUI.custom_layerset].a=1
    DATA.GUI.layers[DATA.GUI.custom_layerset].hide = DATA.GUI.compactmode==1
    DATA.GUI.layers[DATA.GUI.custom_layerset].layer_x = DATA.GUI.buttons.Rsettingslist.x
    DATA.GUI.layers[DATA.GUI.custom_layerset].layer_y = DATA.GUI.buttons.Rsettingslist.y
    DATA.GUI.layers[DATA.GUI.custom_layerset].layer_yshift = 0
    DATA.GUI.layers[DATA.GUI.custom_layerset].layer_w = DATA.GUI.buttons.Rsettingslist.w+1
    DATA.GUI.layers[DATA.GUI.custom_layerset].layer_h = DATA.GUI.buttons.Rsettingslist.h
    local settings_t 
    if GUI_RESERVED_BuildSettings then settings_t  = GUI_RESERVED_BuildSettings(DATA) end
    local settings_h = DATA:GUIBuildSettings_BuildTable(settings_t) 
    DATA.GUI.layers[DATA.GUI.custom_layerset].layer_hmeasured = settings_h 
  end
  --------------------------------------------------------------------- 
  
  function DATA:GUIBuildSettings_BuildTable_Button(t, settingsyoffs) 
      local key = t.key
      if not key then return end
      
      local group = t.group or 0
      if DATA.extstate.UI_groupflags&(1<<group)==(1<<group) or (t.group_inv and t.group_inv == true and DATA.extstate.UI_groupflags&(1<<group)~=(1<<group)) then return settingsyoffs end
      
      local level = t.level or 0
      local settingsit_offs = t.settingsit_offs
      local settingsxoffs = t.settingsxoffs
      --local settingsyoffs = t.settingsyoffs
      local settingsit_w = t.settingsit_w
      local settingsit_h = t.settingsit_h
      local settingsit_offs = t.settingsit_offs
      local settingsit_layer = t.settingsit_layer
      local group = t.group or 0
      local state = '?'
      local readouth = settingsit_h-2
      if t.readouthlev then readouth = settingsit_h * t.readouthlev -2 end
      
      
      DATA.GUI.buttons[key] = 
      {
        x = settingsxoffs+level*settingsit_offs,
        y = settingsyoffs,--settingsyoffs + settingsit_h * (idx-1),
        w = settingsit_w-level*settingsit_offs,
        h = settingsit_h-3,
        layer = settingsit_layer,
        txt = t.str,
        txt_flags=4 ,
        frame_a=0,
        ignoremouse = t.func_onrelease==nil and t.func==nil,
        --frame_asel=0,
        onmouserelease = function()   
                            if t.func then t.func() end 
                            DATA.UPD.onconfchange = true 
                            DATA:GUIBuildSettings()
                            if t.func_onrelease then t.func_onrelease() end
                          end
      }
      return DATA.GUI.buttons[key].y+DATA.GUI.buttons[key].h+2
    end
  --------------------------------------------------------------------- 
  function DATA:GUIBuildSettings_BuildTable_Sep(t, settingsyoffs) 
    local key = t.key
    if not key then return end
    local settingsxoffs = t.settingsxoffs
    --local settingsyoffs = t.settingsyoffs
    local settingsit_w = t.settingsit_w
    local settingsit_h = t.settingsit_h
    local settingsit_offs = t.settingsit_offs
    local settingsit_layer = t.settingsit_layer
    local group = t.group or 0
    
    local state_check = false 
    if not DATA.extstate.UI_groupflags then DATA.extstate.UI_groupflags = 0 end
    if DATA.extstate.UI_groupflags&(1<<group)==(1<<group) then state_check = true end 
    if t.group_inv and t.group_inv == true then state_check = not state_check end 
    local state ='-'
    if state_check == true then state = '+' end
    
    DATA.GUI.buttons[key] = 
    {
      x = settingsxoffs,
      y = settingsyoffs,--settingsyoffs + settingsit_h * (idx-1),
      w = settingsit_w,
      h = settingsit_h-2,
      layer = settingsit_layer,
      txt = state..' '..t.str,
      txt_flags=4 ,
      frame_a=0,
      frame_asel=0,
      onmouserelease = function() 
                          DATA.extstate.UI_groupflags = DATA.extstate.UI_groupflags~(1<<group) 
                          DATA.UPD.onconfchange = true 
                          DATA:GUIBuildSettings()  
                          --DATA.GUI.buttons[key].refresh = true
                        end
    }
    return DATA.GUI.buttons[key].y+DATA.GUI.buttons[key].h
  end
  --------------------------------------------------------------------- 
  function DATA:GUIBuildSettings_BuildTable_Check(t, settingsyoffs) 
    local key = t.key
    
    local group = t.group or 0
    if DATA.extstate.UI_groupflags&(1<<group)==(1<<group) or (t.group_inv and t.group_inv == true and DATA.extstate.UI_groupflags&(1<<group)~=(1<<group)) then return settingsyoffs end
    
    local settingsit_offs = t.settingsit_offs
    local level = t.level or 0
    local settingsxoffs = t.settingsxoffs
    --local settingsyoffs = t.settingsyoffs
    local settingsit_w = t.settingsit_w
    local settingsit_h = t.settingsit_h
    local check_w = settingsit_h -- also check w
    local settingsit_layer = t.settingsit_layer
    
    
    DATA.GUI.buttons[key] = 
    {
      x = settingsxoffs+check_w+DATA.GUI.default_offset/2+ level*settingsit_offs,
      y = settingsyoffs,--settingsyoffs + settingsit_h * (idx-1),
      w = settingsit_w -(settingsxoffs+check_w+DATA.GUI.default_offset/2+ level*settingsit_offs)-1,
      h = settingsit_h-2,
      layer = settingsit_layer,
      txt = t.str,
      txt_flags=4 ,
      frame_a=0,
      ignoremouse = not t.func_onreleaseNAME,
      onmouserelease = function()   if t.func_onreleaseNAME then t.func_onreleaseNAME() end end
      
    } 
    
    local isset = t.isset
    local confkey = t.confkey 
    if not DATA.extstate[confkey] then return DATA.GUI.buttons[key].y+settingsit_h end
    local state = false
    local byte = t.confkeybyte or 0
    if confkey then
      state =  DATA.extstate[confkey]&(1<<byte)==(1<<byte)
      if isset then
        state =  DATA.extstate[confkey]==(t.isset or 0)
      end
    end
    
    -- handle tooltip
      local onmousematch
      if t.tooltip then
        onmousematch = 
          function() 
            if not (DATA.extstate.UI_showtooltips and DATA.extstate.UI_showtooltips == 1) then return end 
            local x, y = reaper.GetMousePosition() 
            reaper.TrackCtl_SetToolTip( t.tooltip,x+DATA.GUI.default_tooltipxoffs, y+DATA.GUI.default_tooltipyoffs, false ) 
          end
      end
      
    DATA.GUI.buttons[key..'state'] = 
    {
      x = settingsxoffs+ level*settingsit_offs,
      y = settingsyoffs,--settingsyoffs + settingsit_h * (idx-1),
      w = check_w,
      h = check_w-2,
      layer = settingsit_layer,
      --txt = t.str,
      txt_flags=4 ,
      frame_a=DATA.GUI.default_framea_normal,
      onmousematch=onmousematch,
      onmouserelease = function()   
                          if confkey then
                            if isset then 
                              DATA.extstate[confkey] = t.isset or 0
                             else
                              DATA.extstate[confkey] = DATA.extstate[confkey]~(1<<byte)
                            end
                            DATA.UPD.onconfchange = true 
                            DATA:GUIBuildSettings()
                          end
                          if t.func_onrelease then t.func_onrelease() end
                        end,
      --[[onmousedoubleclick =   function() 
                            DATA:ExtStateRestoreDefaults(confkey)
                            DATA.UPD.onconfchange = true 
                            DATA:GUIBuildSettings()
                            if t.func_onrelease then t.func_onrelease() end
                          end,  ]]                 
      state = state,
    }     
    
    return DATA.GUI.buttons[key].y+settingsit_h
  end
  --------------------------------------------------------------------- 
  function DATA:GUIBuildSettings_BuildTable_Readout(t, settingsyoffs) 
    local key = t.key
    
    local readoutw = 70*DATA.GUI.default_scale
    if t.readoutw_extw then 
      readoutw = t.readoutw_extw 
      if readoutw < 0 then readoutw = t.settingsit_w-t.settingsxoffs-t.settingsit_offs  end
    end
    local level = t.level or 0
    local settingsit_offs = t.settingsit_offs
    local settingsxoffs = t.settingsxoffs 
    --local settingsyoffs = t.settingsyoffs
    local settingsit_w = t.settingsit_w
    local settingsit_h = t.settingsit_h
    local settingsit_layer = t.settingsit_layer
    local readouth = settingsit_h-2
    if t.readouthlev then readouth = settingsit_h * t.readouthlev -2 end
    
    local group = t.group or 0
    if DATA.extstate.UI_groupflags&(1<<group)==(1<<group) or (t.group_inv and t.group_inv == true and DATA.extstate.UI_groupflags&(1<<group)~=(1<<group)) then return settingsyoffs end
    
    -- init format functions
      local val_format=t.val_format or function(x) return tonumber(x) end 
      local val_format_rev=t.val_format_rev or function(x) return tonumber(x) end  
      if t.val_isstring then
        val_format=t.val_format or function(x) return x end 
        val_format_rev=t.val_format_rev or function(x) return x end 
      end
    --handle percent check
      if t.ispercentvalue then
        val_format = function(x) return math.floor(x*100)..'%' end
        val_format_rev = function(x)  local ret = tonumber(x:match('[%d%.]+')) if ret then return ret/100  end end
      end   
      
    -- get val and formatted val
      local confkey = t.confkey
      local val_formatted, val = ''
      if confkey and DATA.extstate[confkey] then
        val = DATA.extstate[confkey]
        val_formatted = DATA.extstate[confkey]
        if val_format then
          val_formatted = val_format(val_formatted)
        end
      end
    
    -- handle use menu
      if t.menu then
        local keyval = val
        if t.menu[keyval] then
          val_formatted=t.menu[keyval]
        end
      end
      
    -- handle tooltip
      local onmousematch
      if t.tooltip then
        onmousematch = 
          function() 
            if not (DATA.extstate.UI_showtooltips and DATA.extstate.UI_showtooltips == 1) then return end 
            local x, y = reaper.GetMousePosition() 
            reaper.TrackCtl_SetToolTip( t.tooltip,x+DATA.GUI.default_tooltipxoffs, y+DATA.GUI.default_tooltipyoffs, false ) 
          end
      end
      
    -- font size
      local txt_fontsz = DATA.GUI.default_txt_fontsz-1
      
    DATA.GUI.buttons[key..'rout'] = 
    {
      x = settingsxoffs + level*settingsit_offs,
      y = settingsyoffs,--settingsyoffs + settingsit_h * (idx-1),
      w = readoutw,
      h = readouth,
      layer = settingsit_layer,
      txt = val_formatted,
      txt_flags=1|4 ,
      val_res = t.val_res,
      val=val,
      val_min=t.val_min,
      val_max=t.val_max,
      txt_fontsz=txt_fontsz,
      --frame_a=0,
      --frame_asel=0,
      onmousematch = onmousematch,
      onmouseclick =      function() 
                            if t.func_onmouseclick then t.func_onmouseclick() end
                          end,
      onmousedrag =       function() 
                            if t.menu then return end
                            if t.val_isstring then return end
                            if not val_format then return end
                            if not (DATA.GUI.buttons[key..'rout'] and DATA.GUI.buttons[key..'rout'].val) then return end
                            local new_val = VF_lim(DATA.GUI.buttons[key..'rout'].val,t.val_min or 0, t.val_max or 1)
                            if t.val_isinteger then new_val = math.floor(new_val) end
                            DATA.extstate[confkey] = new_val
                            DATA.GUI.buttons[key..'rout'].txt = val_format(new_val) 
                            DATA.GUI.buttons[key..'rout'].refresh = true
                            if t.func_onmousedrag then t.func_onmousedrag() end
                          end,
      onmouserelease =    function() 
                            if t.val_isstring then return end
                            -- menu
                              if t.menu then
                                local tm={}
                                for keym in spairs(t.menu) do
                                  tm[#tm+1] = {str= t.menu[keym], func = function() 
                                    DATA.extstate[confkey] = keym
                                    DATA.GUI.buttons[key..'rout'].txt=t.menu[keym]
                                    DATA.GUI.buttons[key..'rout'].refresh = true
                                    DATA.UPD.onconfchange = true 
                                    DATA:GUIBuildSettings()
                                    if t.func_onrelease then t.func_onrelease() end
                                  end}
                                end
                                DATA:GUImenu(tm)
                                return
                              end
                            -- standart readout confirm
                              if not val_format then return end
                              local new_val = VF_lim(DATA.GUI.buttons[key..'rout'].val,t.val_min or 0, t.val_max or 1)
                              if t.val_isinteger then new_val = math.floor(new_val) end
                              DATA.extstate[confkey] = new_val
                              DATA.GUI.buttons[key..'rout'].txt = val_format(new_val)
                              DATA.UPD.onconfchange = true 
                              --DATA:GUIBuildSettings()
                              if t.func_onrelease then t.func_onrelease() end
                          end,
      onmousereleaseR =    function() 
                            local new_val
                            if not val_format_rev then return end
                            if t.menu then return end
                            local valf = val_format(DATA.extstate[confkey])
                            if t.val_isstring then valf = DATA.extstate[confkey] end
                            local retval, retvals_csv = GetUserInputs( 'Set '..(t.str or ''), 1, ',extrawidth='..tonumber(t.val_input_extrawidth or 200), valf )
                            if not retval then return end
                            if not t.val_isstring then 
                              new_val = val_format_rev(retvals_csv)
                              if not new_val then return end
                              new_val = VF_lim(new_val,t.val_min or 0, t.val_max or 1)
                              if t.val_isinteger then new_val = math.floor(new_val) end
                              DATA.extstate[confkey] = new_val
                             else
                              DATA.extstate[confkey] = retvals_csv
                            end
                            DATA.GUI.buttons[key..'rout'].txt = val_format(new_val)
                            DATA.GUI.buttons[key..'rout'].refresh = true
                            DATA.UPD.onconfchange = true 
                            DATA:GUIBuildSettings()
                            if t.func_onrelease then t.func_onrelease() end
                          end,                          
      onmousedoubleclick =   function() 
                            if not val_format_rev then return end
                            if t.menu then return end
                            DATA:ExtStateRestoreDefaults(confkey)
                            DATA.GUI.buttons[key..'rout'].val = DATA.extstate[confkey]
                            DATA.GUI.buttons[key..'rout'].txt = val_format(DATA.extstate[confkey])
                            DATA.UPD.onconfchange = true 
                            DATA:GUIBuildSettings()
                            if t.func_onrelease then t.func_onrelease() end
                          end
    } 
    
    
    DATA.GUI.buttons[key] = 
    {
      x = settingsxoffs+ readoutw+DATA.GUI.default_offset/2 + level*settingsit_offs,
      y = settingsyoffs,--settingsyoffs + settingsit_h * (idx-1),
      w = settingsit_w -(settingsxoffs+ readoutw+DATA.GUI.default_offset/2 + level*settingsit_offs),
      h = settingsit_h,
      layer = settingsit_layer,
      txt = t.str,
      txt_flags=4 ,
      frame_a=0,
      frame_asel=0,
      onmouserelease = function()  end
    }     
    --[[val_min = 0.005, val_max = 0.4, val_step
    onmousedrag = function() GUI_settingst_confirmval(DATA, 'settings_windval',VF_NormToFormatValue(DATA.GUI.buttons['settings_windval'].val, 0.002, 0.4, 3)..'s' , 'CONF_window', VF_NormToFormatValue(DATA.GUI.buttons['settings_windval'].val, 0.002, 0.4, 3), nil, nil  ) end,
            onmouserelease = function() GUI_settingst_confirmval(DATA, nil,nil,nil,nil,true, nil ) end,
            onmousereleaseR = function() DATA:ExtStateRestoreDefaults('CONF_window') GUI_settingst_confirmval(DATA, nil,nil,nil,nil,true, nil ) end,
            ]]
    
    return DATA.GUI.buttons[key].y+math.max(DATA.GUI.buttons[key].h,DATA.GUI.buttons[key..'rout'].h)--+settingsit_h
  end   
  ---------------------------------------------------------------------  
   function DATA:GUIBuildSettings_BuildTable(t)
     if not DATA.GUI.buttons.Rsettingslist then return end
     if not t then return end
     
     
     local layershiftcompensationx,layershiftcompensationy = 0,0
     local layer = DATA.GUI.custom_layerset 
     if DATA.GUI.layers[layer] and DATA.GUI.layers[layer].layer_x and DATA.GUI.layers[layer].layer_y then 
       layershiftcompensationx = DATA.GUI.layers[layer].layer_x
       layershiftcompensationy = DATA.GUI.layers[layer].layer_y
     end
     
     local boundaryobject = DATA.GUI.buttons.Rsettingslist 
     local frameoffs = 0
     local tablename = 'Rsettings'
     local entryh = DATA.GUI.default_listentryh
     local offs = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz)
     
     -- cleanup setting entries table
     for key in pairs(DATA.GUI.buttons) do 
        if key:match(tablename..'it') then DATA.GUI.buttons[key] = nil end
     end
     
    -- loop table
    local last_y = boundaryobject.y-layershiftcompensationy
    for i = 1, #t do
      local item = t[i]
      if not item.hide then
        item.key = item.str
        item.settingsxoffs =      boundaryobject.x-layershiftcompensationx
        item.settingsit_w =       boundaryobject.w
        item.settingsit_h =       entryh
        item.settingsit_offs =    offs
        item.settingsit_layer =   layer
        item.key = tablename..'it_'..item.key..genGuid()
        if item.itype == 'sep'      then last_y = DATA:GUIBuildSettings_BuildTable_Sep(item, last_y) end
        if item.itype == 'check'    then last_y = DATA:GUIBuildSettings_BuildTable_Check(item, last_y) end
        if item.itype == 'readout'    then last_y = DATA:GUIBuildSettings_BuildTable_Readout(item, last_y) end
        if item.itype == 'button'    then last_y = DATA:GUIBuildSettings_BuildTable_Button(item, last_y) end
      end
    end

     return last_y+1
   end
