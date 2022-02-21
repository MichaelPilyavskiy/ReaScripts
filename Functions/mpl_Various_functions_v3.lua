-- @description Various_functions_v3
-- @author MPL
-- @noindex  
  DATA  = {}
  GUI   = {}
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
  function DATA:ExtStateRestoreDefaults(key)
    if not key then
      for key in pairs(DATA.extstate) do
        if key:match('CONF_') then
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
      
  end
  ----------------------------------------------------------------------------- 
  function GUI:draw_txt(b)
    local x,y,w,h =         b.x or 0,
                            b.y or 0,
                            b.w or 100,
                            b.h or 100 
    x,y,w,h = 
              x*GUI.default_scale,
              y*GUI.default_scale,           
              w*GUI.default_scale,            
              h*GUI.default_scale    
              
    local txt,txt_col,txt_flags, txt_font, txt_fontsz, txt_fontflags,txtback_col, txt_a,txt_short =
                            b.txt or '',
                            b.txt_col or GUI.default_txt_col,
                            b.txt_flags or GUI.default_txt_flags, -- &1 centered horizontally &4 vertically
                            b.txt_font or GUI.default_txt_font ,
                            b.txt_fontsz or GUI.default_txt_fontsz,
                            b.txt_fontflags or '',
                            b.txtback_col or GUI.default_backgr,
                            b.txt_a or GUI.default_txt_a,
                            b.txt_short or ''
                            
    -- txt
      local txt_fontsz_out = txt_fontsz
      if b.offsetframe then 
        txt_flags = 1 
        txt_fontsz_out = b.txt_fontsz or b.offsetframe*2
      end -- center button horiz / align top verically for frame
      GUI:hex2rgb(txt_col, true)
      local calibrated_txt_fontsz = GUI:draw_txtCalibrateFont(txt_font, txt_fontsz_out, txt_fontflags)--, txt, w) 
      
      gfx.setfont(1,txt_font, calibrated_txt_fontsz, txt_fontflags )
      if txt then 
        if txt and tostring(txt) and tostring(txt):match('\n') then 
          GUI:draw_txt_multiline(x,y,w,h,txt_flags, txt_a, txt) 
         else 
          gfx.x, gfx.y = x,y
          gfx.a = txt_a
          local strw = gfx.measurestr(txt)
          if strw > w and txt_short then 
            txt = txt_short
            strw = gfx.measurestr(txt)
          end
          local strh = gfx.texth
          if txt_flags&1==1 then gfx.x = x+(w-strw)/2+1 end
          if txt_flags&4==4 then gfx.y = y+(h-strh)/2 end
          gfx.drawstr(txt) 
        end
      end
    --
    return strw, strh
  end
  
  ----------------------------------------------------------------------------- 
  function GUI:draw_txt_multiline(x,y0,w,h,txt_flags, txt_a,txt) 
    if not txt then return end
    local cnt = 0 for line in txt:gmatch('[^\r\n]+') do cnt = cnt + 1 end
    local i = 0
    for line in txt:gmatch('[^\r\n]+') do
      gfx.x, gfx.y = x,y0
      gfx.a = txt_a
      local strw = gfx.measurestr(line)
      local strh = gfx.texth
      if txt_flags&1==1 then gfx.x = x+(w-strw)/2+1 end
      y = y0 + i *strh + h/2 - 0.5*cnt*strh
      gfx.y = y
      --if txt_flags&4==4 then gfx.y = y+(h-strh)/2 end
      gfx.drawstr(line)
      i =i +1
    end
  end
  ----------------------------------------------------------------------------- 
  function GUI:draw_txtCalibrateFont(txt_font, txt_fontsz_px, txt_fontflags)--, txtmsg, maxv) 
    if not txt_fontsz_px then return end
    for fontsz = 1, 100 do
      gfx.setfont(1,txt_font, fontsz, txt_fontflags) 
      local strh = gfx.texth
      if strh > txt_fontsz_px 
        --*and  (not (maxv and txtmsg) or (maxv and txtmsg and gfx.measurestr(txtmsg) < maxv))
        then return (fontsz-1)*GUI.default_scale end
    end
  end
  ----------------------------------------------------------------------------- 
  function GUI:handlemousestate_match(b)
    b.mouse_match = false
    if GUI.x > gfx.w*GUI.default_scale or GUI.y > gfx.h*GUI.default_scale then return end
    b.mouse_match = GUI.x > b.x*GUI.default_scale and GUI.x < b.x*GUI.default_scale+b.w*GUI.default_scale and GUI.y > b.y*GUI.default_scale and GUI.y < b.y*GUI.default_scale+b.h*GUI.default_scale -- is mouse under object
    if b.layer then
      local layer = b.layer
      if not (GUI.layers[layer] and GUI.layers[layer].layer_yshift) then return end
      b.mouse_match = 
            GUI.x > (b.x + GUI.layers[layer].layer_x  )*GUI.default_scale 
        and GUI.x < (b.x+ GUI.layers[layer].layer_x  )*GUI.default_scale+b.w*GUI.default_scale 
        and GUI.y > (b.y+ GUI.layers[layer].layer_y  )*GUI.default_scale -GUI.layers[layer].layer_yshift
        and GUI.y < (b.y+ GUI.layers[layer].layer_y)*GUI.default_scale-GUI.layers[layer].layer_yshift  +b.h*GUI.default_scale
    end
  end
  ----------------------------------------------------------------------------- 
  function GUI:handlemousestate()
    DATA.perform_quere = {}
    if not (GUI and GUI.buttons) then return end
    for but in spairs(GUI.buttons ) do 
      local b = GUI.buttons[but] 
      if b.ignoremouse ==true then goto skipb end 
      
      -- hovering mouse
        GUI:handlemousestate_match(b) 
        if b.mouse_match then
          b.mouse_matchparent = b
          if b.onmousematchcont then DATA.perform_quere[#DATA.perform_quere+1] = b.onmousematchcont end 
          if GUI.mouse_ismoving then b.refresh = true end
        end
        if b.mouse_match and (not b.mouse_lastmatch  or ( b.mouse_lastmatch and b.mouse_lastmatch ~=b.mouse_match))  then 
          if b.onmousematch then DATA.perform_quere[#DATA.perform_quere+1] = b.onmousematch end
          b.refresh = true 
        end
        if b.mouse_lastmatch  and not b.mouse_match  then 
          if b.mouse_matchparent and b.mouse_matchparent.onmouselost then DATA.perform_quere[#DATA.perform_quere+1] = b.mouse_matchparent.onmouselost end
          b.refresh = true 
        end
        b.mouse_lastmatch = b.mouse_match
      
      
      
      -- LMB
      -- handle mouse_latch on left click
        if GUI.LMB_trig == true and b.mouse_match == true then 
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmouseclick
          b.mouse_latch = true 
          if b.val then b.latchval = b.val    end
          b.refresh = true
        end 
        
      -- handle mouse_latch on left drag
        if GUI.LMB_state == true and GUI.mouse_ismoving ==true and b.mouse_latch == true then
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmousedrag
          if b.val then 
            local res= b.val_res or 1
            b.val = VF_lim(b.latchval - (GUI.dy*res/GUI.default_scale) / b.h) 
          end
          b.refresh = true
        end
        
      -- handle mouse_latch on left release
        if GUI.LMB_release == true and b.mouse_latch == true then
          b.mouse_latch = false
          b.refresh = true
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmouserelease
        end      
        
      
      
      
      -- RMB
      -- handle mouse_latch on left click
        if GUI.RMB_trig == true and b.mouse_match == true then 
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmouseclickR
          b.mouse_latch = true 
          if b.val then b.latchval = b.val    end
          b.refresh = true
        end 
        
      -- handle mouse_latch on left drag
        if GUI.RMB_state == true and GUI.mouse_ismoving ==true and b.mouse_latch == true then
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmousedragR
          if b.val then 
            local res= b.val_res or 1
            b.val = VF_lim(b.latchval - (GUI.dy*res/GUI.default_scale) / b.h) 
          end
          b.refresh = true
        end
        
      -- handle mouse_latch on left release
        if GUI.RMB_release == true and b.mouse_latch == true then
          b.mouse_latch = false
          b.refresh = true
          DATA.perform_quere[#DATA.perform_quere+1] = b.onmousereleaseR
        end




      -- handle wheel
        if b.mouse_match == true and GUI.wheel_trig then
          b.refresh = true
          DATA.perform_quere[#DATA.perform_quere+1] = b.onwheeltrig
        end
          
      ::skipb::
    end
  end
  ----------------------------------------------------------------------------- 
  function GUI:draw_knob(b)
    local x,y,w,h,val =b.x,b.y,b.w,b.h, b.val
    local knob_col,knob_a, knob_arca, knob_val = 
                            b.knob_col or GUI.default_knob_col,
                            b.knob_a or GUI.default_knob_a,
                            b.knob_arca or GUI.default_knob_arca,
                            b.val or 0
    x,y,w,h = 
              x*GUI.default_scale,
              y*GUI.default_scale,           
              w*GUI.default_scale,            
              h*GUI.default_scale  
              
    local ang_gr = 120
    local min_side = math.min(w,h)
    local arc_r = math.floor(min_side/2 ) -2
    local ang_val = math.rad(-ang_gr+ang_gr*2*knob_val)
    local ang = math.rad(ang_gr)
    local thickness = 1
    local y = y + min_side * 0.08
    -- arc back 
      GUI:hex2rgb(knob_col, true)
      gfx.a = knob_arca
      local halfh = math.floor(h/2)
      local halfw = math.floor(w/2)
      for i = 0, thickness, 0.5 do GUI:draw_arc(x+w/2,y+h/2,arc_r-i, -ang_gr, ang_gr, ang_gr) end
    
    -- value
      GUI:hex2rgb(knob_col, true)
      gfx.a = knob_a
      if not b.knob_iscentered then 
        -- val       
        local ang_val = -ang_gr+ang_gr*2*knob_val
        for i = 0, thickness, 0.5 do
          GUI:draw_arc(x+w/2,y+h/2,arc_r-i, -ang_gr, ang_val, ang_gr)
        end 
       else -- if centered
        for i = 0, thickness, 0.5 do
          if knob_val< 0.5 then
            GUI:draw_arc(x+w/2,y+h/2 ,arc_r-i, -ang_gr+ang_gr*2*knob_val, 0, ang_gr)
           elseif knob_val> 0.5 then
            GUI:draw_arc(x+w/2,y+h/2,arc_r-i, 0, -ang_gr+ang_gr*2*knob_val, ang_gr)
          end
        end
      end 
  end
  ---------------------------------------------------
  function GUI:draw_arc(x,y,r, start_ang, end_ang, lim_ang)
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
  function GUI:draw_Button(b)
    if b.hide then return end
    local x,y,w,h, backgr_col, frame_a, frame_asel, back_sela,val =  
                            b.x or 0,
                            b.y or 0,
                            b.w or 100,
                            b.h or 100,
                            b.backgr_col or '#333333',
                            b.frame_a or GUI.default_framea_normal,
                            b.frame_asel or GUI.default_framea_selected,
                            b.back_sela or GUI.default_back_sela,
                            b.val or 0
                
    x,y,w,h = 
              x*GUI.default_scale,
              y*GUI.default_scale,           
              w*GUI.default_scale,            
              h*GUI.default_scale            

                    
    -- backgr fill
      GUI:hex2rgb(backgr_col, true)
      gfx.a  =1
      gfx.rect(x+1,y+1,w-1,h-1,1)
      
    -- latched by mouse
      if b.mouse_latch == true then 
        gfx.set(1,1,1,back_sela)
        gfx.rect(x+1,y+1,w-1,h-1,1) 
      end 
      
    -- slider
      if b.slider_isslider then 
        gfx.set(1,1,1,1)
        local r = math.floor(w/2)
        gfx.circle(x+r,y+r + (h-r*2)*val,r,1)
      end
      
    -- txt
      b.txt_strw, b.txt_strh = GUI:draw_txt(b)
      
    -- knob
      if b.knob_isknob then GUI:draw_knob(b) end
      
    -- frame
      GUI:hex2rgb(GUI.default_frame_col, true)
      gfx.a = frame_a
      if b.mouse_match == true or b.mouse_latch == true then gfx.a = frame_asel end
      if gfx.a > 0 then
        if not b.offsetframe then 
          GUI:draw_rect(x,y,w,h,0) 
         elseif b.offsetframe and b.txt_strw and b.txt_strh then
          local offsetframe = b.offsetframe*GUI.default_scale
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
      
    -- state 
      if b.state and b.state  == true then 
        local state_offs = 3
        local state_col = b.state_col or GUI.default_state_col
        GUI:hex2rgb(state_col, true)
        gfx.a = GUI.default_state_a
        gfx.rect(x+state_offs+1,y+state_offs+1,w-state_offs*2-1,h-state_offs*2-1,1) 
      end 
      
    -- val_data
      if GUI_RESERVED_draw_data then GUI_RESERVED_draw_data(GUI, b) end
  end
-----------------------------------------------------------------------------  
  function GUI:init()
    local title = DATA.extstate.mb_title or ''
    if DATA.extstate.version then title = title..' '..DATA.extstate.version end
              
    GUI.default_backgr = '#333333' --grey
    GUI.default_back_sela = 0.05 -- pressed button
    
    GUI.default_frame_col = '#FFFFFF'
    GUI.default_framea_normal = 0.4
    GUI.default_framea_selected = 0.6 -- mouse hovered
    GUI.default_state_col = '#FFFFFF'
    GUI.default_state_a = 0.7
    
    GUI.default_data_col = '#FFFFFF'
    GUI.default_data_col_adv = '#00ff00' -- green
    GUI.default_data_col_adv2 = '#e61919 ' -- red
    
    GUI.default_knob_col = '#FFFFFF' -- white
    GUI.default_knob_a = 0.9
    GUI.default_knob_arca = 0.1
    
    GUI.default_txt_col = '#FFFFFF'
    GUI.default_txt_flags = 1|4
    GUI.default_txt_font = 'Arial'
    GUI.default_txt_fontsz = 15 -- settings
    GUI.default_txt_fontsz2 = 20 -- preset names, buttons
    GUI.default_txt_a = 0.9
    GUI.default_txt_a_inactive = 0.3
    
    
    GUI.default_tooltipxoffs = 10
    GUI.default_tooltipyoffs = 0
    
    
    
    -- perform retina scaling -- https://forum.cockos.com/showpost.php?p=2493416&postcount=40
      local OS = reaper.GetOS()
      GUI.default_font_coeff = 1
      GUI.default_scale = 1
      gfx.ext_retina = 1 -- init with 1 
      gfx.init( title,
                DATA.extstate.wind_w or 100,
                DATA.extstate.wind_h or 100,
                DATA.extstate.dock or 0, 
                DATA.extstate.wind_x or 100, 
                DATA.extstate.wind_y or 100)
      
      local retinatest = 0--2
      if GUI.default_scale ~= gfx.ext_retina or retinatest ~= 0 then -- dpi changed (either initially or from the user moving the window or the OS changing
        GUI.default_scale = gfx.ext_retina
              
        if retinatest ~= 0 then GUI.default_scale = retinatest end
        GUI.default_font_coeff = (1+GUI.default_scale)*0.5 
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
    GUI.default_listentryh = 20*GUI.default_scale
    GUI.default_listentryxoffset = 5*GUI.default_scale
    GUI.default_listentryframea = 0.4
    
    GUI:shortcuts_ParseKBINI()
  end
  ---------------------------------------------------
  function GUI:menu(t)
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
    gfx.x = GUI.x
    gfx.y = GUI.y
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
  function GUI:getmousestate()
    GUI.char = math.floor(gfx.getchar())
    GUI.cap = gfx.mouse_cap
    GUI.x = gfx.mouse_x
    GUI.y = gfx.mouse_y
    GUI.ANY_release = false
    
    -- L/M/R button states
    GUI.LMB_state = gfx.mouse_cap&1 == 1 
    GUI.LMB_trig = GUI.LMB_state and not GUI.last_LMB_state
    GUI.LMB_release = GUI.LMB_state == false and GUI.last_LMB_state == true
    GUI.RMB_state = gfx.mouse_cap&2 == 2 
    GUI.RMB_trig = GUI.RMB_state and not GUI.last_RMB_state
    GUI.RMB_release = GUI.RMB_state == false and GUI.last_RMB_state == true
    GUI.MMB_state = gfx.mouse_cap&64 == 64
    GUI.MMB_trig = GUI.MMB_state and not GUI.last_MMB_state 
    GUI.MMB_release = GUI.MMB_state == false and GUI.last_MMB_state == true
    GUI.ANY_state = GUI.LMB_state or GUI.RMB_state or GUI.MMB_state
    GUI.ANY_trig = GUI.LMB_trig or GUI.RMB_trig or GUI.MMB_trig
    
    -- latchx/y 
    if GUI.ANY_trig then
      GUI.latchx = GUI.x
      GUI.latchy = GUI.y
    end
    if GUI.ANY_state then 
      GUI.dx = GUI.x - GUI.latchx
      GUI.dy = GUI.y - GUI.latchy
    end
    if not GUI.ANY_state and GUI.last_ANY_state then
      GUI.dx = 0
      GUI.dy = 0
      GUI.latchx = nil
      GUI.latchy = nil
    end 
    GUI.mouse_ismoving = GUI.last_x and GUI.last_y and (GUI.last_x ~= GUI.x or GUI.last_y ~= GUI.y)
    
    -- wheel
    GUI.wheel = gfx.mouse_wheel
    GUI.wheel_trig = GUI.last_wheel and GUI.last_wheel ~= GUI.wheel
    GUI.wheel_dir = GUI.last_wheel and GUI.last_wheel-GUI.wheel>0
    
    -- ctrl alt shift
    GUI.Ctrl = gfx.mouse_cap&4 == 4 
    GUI.Shift = gfx.mouse_cap&8 == 8 
    GUI.Alt = gfx.mouse_cap&16 == 16  
    GUI.hasAltkeys = not (GUI.Ctrl or GUI.Shift or GUI.Alt)
    
    -- handle states
    GUI.last_x = GUI.x
    GUI.last_y = GUI.y
    GUI.last_pointer = GUI.pointer
    GUI.last_LMB_state = GUI.LMB_state  
    GUI.last_RMB_state = GUI.RMB_state  
    GUI.last_MMB_state = GUI.MMB_state  
    GUI.last_ANY_state = GUI.ANY_state 
    GUI.last_wheel = GUI.wheel 
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
                          
  end
  -----------------------------------------------------------------------------  
  function DATA:perform()
    if DATA.perform_quere then 
      for i = 1, #DATA.perform_quere do
        if DATA.perform_quere[i] then DATA.perform_quere[i]() end
      end
    end
    DATA.perform_quere = {} --- clear
  end
-----------------------------------------------------------------------------  
  function RUN()
    if not DATA.UPD then DATA.UPD = {} end
      
    -- data
      DATA:handleProjUpdates()
      DATA:handleWindowUpdates() 
      DATA:perform()-- perform stuff in queue
    
    -- dynamic handle stuff
      GUI:getmousestate()
      if GUI_RESERVED_shortcuts then GUI_RESERVED_shortcuts(GUI) end
      GUI:handlemousestate() -- create a quere for performing stuff
      GUI:draw() -- draw stuff 
    
      if DATA.UPD.onconfchange == true or DATA.UPD.onXYchange == true or DATA.UPD.onWHchange == true then DATA:ExtStateSet() DATA:ExtStateGet()  end
      if DATA.UPD.onWHchange == true or DATA.UPD.onGUIinit == true then if GUI_RESERVED_initbuttons then GUI_RESERVED_initbuttons(GUI) end GUI.firstloop = 1 end
    
    -- reset triggers
      DATA.UPD.onconfchange = false
      DATA.UPD.onGUIinit = false
      DATA.UPD.onXYchange = false
      DATA.UPD.onWHchange = false
      DATA.UPD.onprojstatechange = false
      DATA.UPD.onprojtabchange = false
      
    -- main loop
      if GUI.char >= 0 and GUI.char ~= 27 then defer(RUN) else atexit(gfx.quit) end -- exit on escape
  end 
  ---------------------------------------------------------------------  
  function GUI:quantizeXYWH(b)
    if not (b  and b.x and b.y and b.w and b.h ) then return end
    b.x = math.floor(b.x)
    b.y = math.floor(b.y)
    b.w = math.floor(b.w)
    b.h = math.floor(b.h)
  end
-----------------------------------------------------------------------------  
  function GUI:draw() 
    if not GUI.firstloop then GUI.firstloop = 1 end
    if not GUI.layers then GUI.layers = {} end
    if not GUI.layers[1] then GUI.layers[1] = {a=1} end -- Main back
    if not GUI.layers[2] then GUI.layers[2] = {a=1} end -- Main buttons
    --if not GUI.layers[3] then GUI.layers[3] = {a=1} end -- Alt back
    --if not GUI.layers[4] then GUI.layers[4] = {a=1} end -- Alt buttons
    -- 10 - 20 reserved
    --if not GUI.layers[21] then GUI.layers[21] = {a=1} end -- Dynamic stuff 1 -- typically settings list
    --if not GUI.layers[22] then GUI.layers[22] = {a=1} end -- Dynamic stuff 2
    
    GUI.layers_refresh = {}
    local upd_customlayers = false
    for but in pairs(GUI.buttons) do 
      local but_t = GUI.buttons[but]
      if but_t.refresh ==true then 
        local layer = but_t.layer or 2
        if layer and layer ~= 2 then 
          upd_customlayers = true 
          GUI.layers_refresh[layer] = true
         elseif layer == 2 then 
          GUI.layers_refresh[2] = true
        end
        but_t.refresh = false
      end
    end
    
    
    if GUI.firstloop == 1 or DATA.UPD.onWHchange == true then GUI:draw_Layer1_MainBack() end
    if GUI.firstloop == 1 or DATA.UPD.onWHchange == true or GUI.layers_refresh[2] then GUI:draw_Layer2_MainButtons() end
    if GUI.firstloop == 1 or DATA.UPD.onWHchange == true or upd_customlayers == true then GUI:draw_LayerCustom() end
    
    gfx.mode = 0
    for layer in spairs(GUI.layers )do
      gfx.set(1,1,1,1)
      gfx.dest = -1   
      gfx.a = GUI.layers[layer].a or 1
      gfx.x,gfx.y = 0,0
      local w,h = gfx.w, gfx.h
      if layer==1 then w= math.min(gfx.h, math.min(gfx.w, 200))h=w end
      local destx,desty,destw,desth = 0, 0, gfx.w, gfx.h
      local srcx,srcy,srcw,srch =  0, 0, w, h
      
      if GUI.layers[layer]  then
        if GUI.layers[layer].layer_x then destx = GUI.layers[layer].layer_x*GUI.default_scale end
        if GUI.layers[layer].layer_y then desty = GUI.layers[layer].layer_y*GUI.default_scale end
        if GUI.layers[layer].layer_w then srcw = GUI.layers[layer].layer_w*GUI.default_scale destw = srcw end
        if GUI.layers[layer].layer_h then srch = GUI.layers[layer].layer_h*GUI.default_scale desth = srch end
        --if GUI.layers[layer].layer_hmeasured then desth = GUI.layers[layer].layer_hmeasured srch =desth end
        if GUI.layers[layer].scrollval and GUI.layers[layer].layer_hmeasured and GUI.layers[layer].layer_h and GUI.layers[layer].layer_hmeasured > GUI.layers[layer].layer_h then 
          local reallayerh = (GUI.layers[layer].layer_hmeasured  - GUI.layers[layer].layer_h)*GUI.default_scale
          srcy = math.floor(srcy + GUI.layers[layer].scrollval*  reallayerh)
          GUI.layers[layer].layer_yshift = srcy
        end
        
      end
      
      --if layer ~= 1 and GUI.layers[layer] and not GUI.layers[layer].hide then
        gfx.blit(layer, 1, 0, 
            srcx,srcy,srcw,srch,
            destx,desty,destw,desth, 0,0) 
      --end
    end
    
    
    gfx.update()
    GUI.firstloop = 0
  end
  -----------------------------------------------------------------------------  
  function GUI:draw_Layer1_MainBack() 
    -- draw grey gradient
      local gradback_sz = GUI.gradback_sz or math.min(gfx.h, math.min(gfx.w, 200))
      if not GUI.gradback_col then GUI.gradback_col = GUI.default_backgr end
      gfx.dest = 1
      gfx.setimgdim(1, -1, -1)  
      gfx.setimgdim(1, gfx.w, gfx.h)  
      gfx.set(0,0,0,1) 
      gfx.rect(0,0,gfx.w,gfx.h)
      local r,g,b = GUI:hex2rgb(GUI.gradback_col)
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
  function GUI:draw_Layer2_MainButtons()
    gfx.dest = 2
    gfx.setimgdim(2, -1, -1)  
    gfx.setimgdim(2, gfx.w, gfx.h) 
    --gfx.set(0,0,0,1)
    --gfx.rect(0,0,gfx.w,gfx.h)
    if not (GUI and GUI.buttons) then return end
    local b
    for but in spairs(GUI.buttons ) do 
      b = GUI.buttons[but]
      if not b.layer then GUI:draw_Button(b) end
    end
  end
  -----------------------------------------------------------------------------  
  function GUI:draw_LayerCustom()
    if not (GUI and GUI.buttons) then return end
    local activelayers = {}
    local b
    for but in spairs(GUI.buttons ) do 
      b = GUI.buttons[but]
      if b.layer and (GUI.layers_refresh[b.layer] or GUI.firstloop == 1 ) then 
        if not activelayers[b.layer] then
          gfx.dest = b.layer
          gfx.setimgdim(b.layer, -1, -1)  
          local layer_hmeasured = GUI.layers[b.layer].layer_hmeasured or GUI.layers[b.layer].layer_h
          gfx.setimgdim(b.layer, GUI.layers[b.layer].layer_w*GUI.default_scale, layer_hmeasured*GUI.default_scale) 
          activelayers[b.layer] = true
        end
        gfx.dest = b.layer
        GUI:draw_Button(b) 
      end
    end
  end  
  
  -----------------------------------------------------------------------------  
  function GUI:draw_rect(x,y,w,h)
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
  function GUI:hex2rgb(s16,set)
    if not s16 then return end
    s16 = s16:gsub('#',''):gsub('0X',''):gsub('0x','')
    local b,g,r = ColorFromNative(tonumber(s16, 16))
    if set then
      if GetOS():match('Win') then gfx.set(r/255,g/255,b/255) else gfx.set(b/255,g/255,r/255) end
    end
    return r/255, g/255, b/255
  end
  ---------------------------------------------------------------------  
  function GUI:generatelisttable(listtable)
    if not listtable then return end
    local frameoffs = 2
    local t,boundaryobject,tablename, layer = listtable.t, listtable.boundaryobj, listtable.tablename, listtable.layer
    local offs = math.floor(GUI.default_scale*GUI.default_txt_fontsz/2)
    local entryh = GUI.default_listentryh
    local last_h = 0
    local valmsg_wratio = 3
    local frame_a = GUI.default_listentryframea
    local layershiftcompensationx,layershiftcompensationy = 0,0
    if GUI.layers[layer] and GUI.layers[layer].layer_x and GUI.layers[layer].layer_y then 
      layershiftcompensationx = GUI.layers[layer].layer_x
      layershiftcompensationy = GUI.layers[layer].layer_y
    end
    local yid = 0
    
    
    for i = 1, 1000 do
      local key = tablename..i..'state'
      GUI.buttons[key] = nil
      key = tablename..i..'val' 
      GUI.buttons[key] = nil
      key = tablename..i..'name'
      GUI.buttons[key] = nil
    end
    
    
    for i = 1, #t do
      local item = t[i]
      if not item or item.hide == true then goto list_skip end
      local level = item.level or 0
      local levelname = level
      local valmsg_wratio0 = valmsg_wratio
      if item.valtxtw_mult then valmsg_wratio0 = item.valtxtw_mult end
      yid = yid+ 1
      local level_reduce = 0.75
      local xoffs = entryh * (item.level or 0) * level_reduce
      local txt_a =GUI.default_txt_a
      if item.active == false then txt_a = GUI.default_txt_a_inactive end
      
      -- is check
        if item.ischeck then 
          local key = item.customkey or tablename..i
          key = key..'state'
          GUI.buttons[key] = 
          {
            x = boundaryobject.x-layershiftcompensationx + xoffs,
            y = boundaryobject.y + entryh * (yid-1)-layershiftcompensationy+frameoffs,
            w = entryh,
            h = entryh-frameoffs*2,
            back_sela = 0,
            state = item.state,
            layer = layer,
            txt_flags = 1|4,
            txt_col = item.txt_col,
            txt_a = txt_a,
            state_col = item.txt_col, 
            frame_a = frame_a,
            onmouseclick = item.onmouseclick,
            onmousedrag = item.onmousedrag,
            onmouserelease = item.onmouserelease,            
            onmouseclickR = item.onmouseclickR,
            onmousedragR = item.onmousedragR,
            onmousereleaseR = item.onmousereleaseR,
            hide = item.hide,
            active = item.active,
            ignoremouse = item.ignoremouse,
          }
          GUI:quantizeXYWH(GUI.buttons[key])
        end
      
      if item.isvalue then -- is value
        local txt = '' if item.valtxt then txt = item.valtxt end
        local key = item.customkey or tablename..i
        key = key..'val' 
        GUI.buttons[key] = 
        {
          x = boundaryobject.x-layershiftcompensationx + xoffs,
          y = boundaryobject.y + entryh * (yid-1)-layershiftcompensationy+frameoffs,
          w = entryh*valmsg_wratio0,
          h = entryh-frameoffs*2,
          back_sela = 0,
          txt = txt,
          txt_col = item.txt_col,
          txt_a = txt_a,
          layer = layer,
          val = item.val,
          val_res = item.val_res,
          frame_a = frame_a,
          txt_flags = 1|4,
          onmouseclick = item.onmouseclick,
          onmousedrag = item.onmousedrag,
          onmouserelease = item.onmouserelease,
          onmouseclickR = item.onmouseclickR,
          onmousedragR = item.onmousedragR,
          onmousereleaseR = item.onmousereleaseR,
          hide = item.hide,
          active = item.active,
          ignoremouse = item.ignoremouse,
        }
        if item.menu then GUI.buttons[key].onmouseclick = function() GUI:menu(item.menu) end end
        GUI:quantizeXYWH(GUI.buttons[key])
      end
      
      
      if item.ischeck then xoffs = xoffs + entryh + offs end
      if item.isvalue then xoffs = xoffs + entryh*valmsg_wratio0 + offs  end
      
      
      -- name
        local key = item.customkey or tablename..i
        key = key..'name'
        GUI.buttons[key] = 
        {
          x = boundaryobject.x-layershiftcompensationx + xoffs ,
          y = boundaryobject.y + entryh * (yid-1)-layershiftcompensationy,
          w = boundaryobject.w-xoffs,
          h = entryh,
          back_sela = 0,
          txt = item.str,
          txt_col = item.txt_col,
          txt_flags=4 or item.txt_flags,
          txt_a = txt_a,
          layer = layer,
          frame_a=0 or item.frame_a,
          frame_asel=0 or item.frame_asel,
          onmouseclick = item.onmouseclick,
          onmousedrag = item.onmousedrag,
          onmouserelease = item.onmouserelease,
          onmouseclickR = item.onmouseclickR,
          onmousedragR = item.onmousedragR,
          onmousereleaseR = item.onmousereleaseR,
          
          onmousematch = item.onmousematch,
          onmouselost = item.onmouselost,
                  
                  
          hide = item.hide,
          active = item.active,
          ignoremouse = item.ignoremouse,
        } 
      GUI:quantizeXYWH(GUI.buttons[key])
      last_h = GUI.buttons[key].y+GUI.buttons[key].h
      ::list_skip::
    end
    return last_h+1
  end
  ---------------------------------------------------------------------    
  function GUI:but_preset(GUI,DATA)
    -- form presets menu    
      local presets_t = {
        {str = 'Reset all settings to default',
          func = function() 
                    DATA.extstate.current_preset = nil
                    GUI.buttons.preset.txt = 'Preset: default'
                    DATA:ExtStateRestoreDefaults() 
                    GUI.firstloop = 1 
                    DATA.UPD.onconfchange = true 
                    GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
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
                  GUI.buttons.preset.refresh = true 
                  GUI.firstloop = 1 
                  DATA.UPD.onconfchange = true 
                  GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
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
                  GUI.buttons.preset.refresh = true 
                  GUI.buttons.preset.txt = 'Preset: '..(DATA.extstate.CONF_NAME or '')
                  GUI.firstloop = 1 
                  DATA.UPD.onconfchange = true 
                  GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
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
                  GUI.buttons.preset.refresh = true 
                  GUI.firstloop = 1 
                  DATA.UPD.onconfchange = true 
                  GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
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
                  GUI.buttons.preset.refresh = true 
                  GUI.firstloop = 1 
                  DATA.UPD.onconfchange = true 
                  GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
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
                                              GUI.buttons.preset.refresh = true 
                                              GUI.buttons.preset.txt = 'Preset: '..(DATA.extstate.CONF_NAME or '')
                                              GUI.firstloop = 1 
                                              DATA.UPD.onconfchange = true 
                                              GUI:generatelisttable( GUI_settingst(GUI, DATA, GUI.buttons.settingslist, GUI.buttons.settings_scroll) ) 
                                            end,
                                    state = state,
        
          
                                    }
      end
    -- form table
      GUI:menu(presets_t)  
    end
  --------------------------------------------------------------------- 
  function GUI:shortcuts_ParseKBINI()
    local kbini = reaper.GetResourcePath()..'/reaper-kb.ini'
    local f = io.open(kbini, 'r')
    local cont = f:read('a')
    if not f then return else  f:close() end
    GUI.parsed_shortcuts = {}
    for line in cont:gmatch('[^\r\n]+') do
      if line:match('KEY%s') then
        local flags, key, action, page = line:match('KEY%s(%d+)%s(%d+)%s([%d%a%_]+)%s(%d+)')
        local char = tonumber(key)
        if char then
          GUI.parsed_shortcuts[char] = { action = tonumber(action) or action,
                      page = tonumber(page),
                      flags =tonumber(flags)}
        end
      end
    end
  end
