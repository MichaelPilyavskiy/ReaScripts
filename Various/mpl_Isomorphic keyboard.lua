-- @description Isomorphic keyboard
-- @version 1.09
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # fixed B root scale decoding

  vrs = '1.09'
  name = 'MPL Isomorphic keyboard'  
  
  
  --[[ changelog:
  1.09  12.01.2017
    # fixed B root scale decoding
  1.08  08.01.2017
    + reset draw offset when change layout
    + auto set keynames to 'C-C# + cents' if change to microtonal layout
    + support for cents shift in layout(clear config requied)
    # don`t redraw when moving gfx window
  1.07  07.01.2017
    # fixed incorrect key root parsing
    # fix incorrect checks behaviour
    # fixed default color
    + Add microtonal mode (split by channel up to 16 + distribute pitchbends)
    + Add octave shift selector   
    # draw colors for microtonal intervals properly 
  1.0 06.01.2017 
    + init official release    
  1.0rc1 06.01.2017 
    # inverted drag y 
    + add 'prepare track' button
    # notes table now global because of MIDI/GUI different issues
    + add key root menu
    + add option to not to play out of scale notes
    # OSX fonts size
    # OSX colors
  1.0alpha20 05.01.2017
    # limit rox/col count to visible way, decrease CPU perf
    # proper key names draw
    + added support for microtone intervals (MIDI not ready yet)
    + drag view
    + reserved support for palette type
    + added WB color
    + added some scales
  1.0alpha14 04.01.2017
    + generate default config
    + tonic/scal/ouofscale colors
    + key names
    # proper interval calculating for hor/vert hexagons
  1.0alpha11 02.01.2017
    # proper blit background/respond to settings
    # use only external file as config
    # recoded all ExtState values into onedim table
    + related table for notes
  1.0alpha8 01.01.2017
    # proper layout generating from 2 intervals
    + parsing layouts from config
  1.0alpha6 01.01.2017
    + settings page
    + MIDI stuff
    + area chord
    + config parser
    + store docked state and window xywh into config
    + added MIDI behaviour selector
    + scroll changes base note
  1.0alpha5 31.12.2016
    # regular hexagons
    # better notes color+light
  1.0alpha4 30.12.2016
    + added Musix Pro layouts 
    + build logic
    + MIDI Pitch limits
  ]]
  
  
  --[[ to do
      use pitchbend send for microtonal scales
      CC sliders on main page
      velocity slider on main page
      multitouch support
      JI scales support
  ]]
  
  ------------------------------------------------------------------ 
  function Data_defaults()
    local data = {
      window_x = 0,
      window_y = 0,
      window_w = 600, 
      window_h = 300,
      draw_offset_x=0,
      draw_offset_y=0,
      d_state = 0,
      notes_hex_side = 0.5,
      notes_rect_side = 0.5,
      notes_side_ratio = 100,
      magnet_area = 0.1,
      midi_release_behav = 2,
      velocity = 1,
      base_note = 0,
      key_names = 0,
      layout_act = 1,
      color_act = 1,
      scale_act = 1,
      row_cnt = 50,
      col_cnt = 50,
      pitch_low = 24,
      pitch_high = 127,
      rect_ratio = 0.5,
      key_root = 0,
      playoutscale = 1,
      support_PB = 0,
      oct_shift = 1,
      shift_cents = 0
      }        
    return data
  end
  --------------------------------------------------------------------   
  function F_ret_ExtState(str)
    local q_find = str:sub(2):find('"')
    local name = str:sub(2,q_find)
    local val_str = str:sub(q_find+2)
    local t = {}
    for line in val_str:gmatch('[^%s]+') do 
      if tonumber(line) and line:sub(1,1) ~= '0' then t[#t+1] =  tonumber(line) else t[#t+1] = line end
    end
    return {name = name, t}
  end
  --------------------------------------------------------------------  
  function DEFINE_Objects()    
    local offs = 10
    if gfx.w < 100 then gfx.w = 100 end
    if gfx.h < 100 then gfx.h = 100 end
    local obj = {
                  main_w = gfx.w,
                  main_h = gfx.h 
                }
    
    -- settings button
      obj.settings_but_w = 50
      local menu_w = 160
      local menu_h = 22
      local menu_sep = 10
      local vert_shift = 2
      
      obj.but_area = {x = obj.main_w - obj.settings_but_w - offs*2,
                      y = 0,
                      w = obj.settings_but_w+ offs*2,
                      h = gfx.h}  
      obj.preview = {x = obj.main_w - obj.settings_but_w - offs,
                      y = obj.main_h - obj.settings_but_w*3 - offs*3,
                      w = obj.settings_but_w,
                      h = obj.settings_but_w,
                      name = '',
                      id_mouse = 'preview'}                            
      obj.drag = {x = obj.main_w - obj.settings_but_w - offs,
                      y = obj.main_h - obj.settings_but_w*2 - offs*2,
                      w = obj.settings_but_w,
                      h = obj.settings_but_w,
                      name = 'Drag',
                      id_mouse = 'drag'}      
      obj.settings = {x = obj.main_w - obj.settings_but_w - offs,
                      y = obj.main_h - obj.settings_but_w - offs,
                      w = obj.settings_but_w,
                      h = obj.settings_but_w,
                      name = 'Options',
                      id_mouse = 'setting_mv'}
                ----------------------------------  
                
      obj.settings_GUI = {x = offs*2,
                            y = offs*2,
                            w = menu_w,
                            h = menu_h,
                            name = 'GUI'
                            }
      obj.settings_hex_w = {x = offs*2,
                            y = offs*3 + menu_h,
                            w = menu_w,
                            h = menu_h,
                            name = 'Key size: '..math.floor(100*data.notes_hex_side)..'%',
                            id_mouse = 'hex_side',
                            val = data.notes_hex_side
                            }  
      obj.settings_rect_ratio = {x = offs*2,
                            y = offs*3 + menu_h*2+vert_shift,
                            w = menu_w,
                            h = menu_h,
                            name = 'Rectangle ratio',
                            id_mouse = 'rect_ratio',
                            val = data.rect_ratio
                            }                               
                                                    
      obj.settings_layout = {x = offs*2,
                            y = offs*4 + menu_h*3+vert_shift*2,
                            w = menu_w,
                            h = menu_h,
                            name = '● Layout: '..data.layout_t.name,
                            id_mouse = 'Layout'
                            }                                                      
   
      obj.settings_color = {x = offs*2,
                            y = offs*4 + menu_h*4+vert_shift*3,
                            w = menu_w,
                            h = menu_h,
                            name = '● Color: '..data.color_t.name,
                            id_mouse = 'color'
                            }   
      obj.settings_scale = {x = offs*2,
                            y = offs*4 + menu_h*5+vert_shift*4,
                            w = menu_w,
                            h = menu_h,
                            name = '● Scale: '..data.scale_t.name,
                            id_mouse = 'scale'
                            }       
      obj.settings_key_name = {x = offs*2,
                            y = offs*4 + menu_h*6+vert_shift*5,
                            w = menu_w,
                            h = menu_h,
                            name = '● Key name',
                            id_mouse = 'Key_name'
                            }   
      obj.settings_key_root = {x = offs*2,
                            y = offs*4 + menu_h*7+vert_shift*6,
                            w = menu_w,
                            h = menu_h,
                            name = '● Key root',
                            id_mouse = 'key_root'
                            }  
      obj.settings_oct_shift = {x = offs*2,
                            y = offs*4 + menu_h*8+vert_shift*7,
                            w = menu_w,
                            h = menu_h,
                            name = '● Octave shift',
                            id_mouse = 'oct_shift'
                            }                                                         
                                                                            
                 ----------------------------------           
      obj.settings_MIDI = {x = offs*2 + menu_sep + menu_w,
                            y = offs*2,
                            w = menu_w,
                            h = menu_h,
                            name = 'MIDI / Touch'
                            }                                                   
      obj.settings_note_release = {x = offs*2 + menu_sep + menu_w,
                            y = offs*3+menu_h,
                            w = menu_w,
                            h = menu_h,
                            name = '● Release behaviour'
                            }
      obj.settings_magn_area = {x = offs*2+menu_w+menu_sep,
                            y = offs*3 + menu_h*2+vert_shift,
                            w = menu_w,
                            h = menu_h,
                            name = 'Magnet area: '..math.floor(100*data.magnet_area)..'%',
                            id_mouse = 'notes_magnet_area',
                            val = data.magnet_area
                            }    
      local check 
      if data.playoutscale == 1 then check = '☑ ' else check = '☐ ' end
      obj.settings_playoutscale = {x = offs*2+menu_w+menu_sep,
                            y = offs*3 + menu_h*3+vert_shift*2,
                            w = menu_w,
                            h = menu_h,
                            name = check..'Play out of scale keys',
                            id_mouse = 'playoutscale',
                            val = data.playoutscale
                            }  
      local check 
      if data.support_PB == 1 then check = '☑ ' else check = '☐ ' end
      obj.settings_support_PB = {x = offs*2+menu_w+menu_sep,
                            y = offs*3 + menu_h*4+vert_shift*3,
                            w = menu_w,
                            h = menu_h,
                            name = check..'Microtonal mode',
                            id_mouse = 'support_PB',
                            val = data.support_PB
                            }
                                                                                  
      obj.settings_note_vel = {x = offs*2 + menu_sep + menu_w,
                            y = offs*4+menu_h*5+vert_shift*3,
                            w = menu_w,
                            h = menu_h,
                            id_mouse = 'Velocity',
                            name = 'Velocity: '..math.floor(data.velocity*127),
                            val = data.velocity
                            } 
                                                        
                   ----------------------------------             
      obj.settings_INFO = {x = offs*2 + menu_sep*2 + menu_w*2,
                            y = offs*2,
                            w = menu_w,
                            h = menu_h,
                            name = 'Info'
                            }   
      obj.info_conf = {x = offs*2 + menu_sep*2 + menu_w*2,
                            y = offs*3 + menu_h,
                            w = menu_w,
                            h = menu_h,
                            name = 'Open configuration'
                            }                             
                            
      obj.info_cockos = {x = offs*2 + menu_sep*2 + menu_w*2,
                            y = offs*4 + menu_h*2+vert_shift,
                            w = menu_w,
                            h = menu_h,
                            name = 'Cockos forum'
                            }   
      obj.info_rmm = {x = offs*2 + menu_sep*2 + menu_w*2,
                            y = offs*4 + menu_h*3 + vert_shift*2,
                            w = menu_w,
                            h = menu_h,
                            name = 'RMM forum'}
      obj.info_vk = {x = offs*2 + menu_sep*2 + menu_w*2,
                            y = offs*4 + menu_h*4 + vert_shift*3,
                            w = menu_w,
                            h = menu_h,
                            name = 'MPL @ VK'}      
      obj.info_sc = {x = offs*2 + menu_sep*2 + menu_w*2,
                            y = offs*4 + menu_h*5 + vert_shift*4,
                            w = menu_w,
                            h = menu_h,
                            name = 'MPL @ SoundCloud'} 
      obj.info_donate = {x = offs*2 + menu_sep*2 + menu_w*2,
                            y = offs*5 + menu_h*6 + vert_shift*4,
                            w = menu_w,
                            h = menu_h,
                            name = 'Donate to MPL'}                                                                                 
                                                                   
                            
    return obj
  end
  ------------------------------------------------------------------   
  function DEFINE_Notes(obj)
    if update_notes then notes = {} end
    -- GUI vars
      local hex_side,form, col_cnt, row_cnt
      local side = data.notes_hex_side * data.notes_side_ratio
      local form =  tonumber(data.layout_t.form)
      
      local col_cnt = data.col_cnt
      local row_cnt = data.row_cnt
      --rect_ratio
      local add_rect = 50
      local w_side, h_side
      if data.rect_ratio > 0.5 then
        w_side = side + add_rect * (data.rect_ratio - 0.5)*2
        h_side = side
       else
        w_side = side
        h_side = side  + add_rect * math.abs(( data.rect_ratio - 0.5) *2)
      end       
      --[[local w_side = side
      local h_side = side]]
    -- Pitch vars
      local int_1,int_2, low_pitch, high_pitch
      int_1 = data.layout_t.int_1
      int_2 = data.layout_t.int_2
      low_pitch = data.pitch_low
      high_pitch = data.pitch_high     
                    --------------------------------      
    -- form xywh
      local x_offs, y_offs = 0,0
      local x_offs_glob, y_offs_glob = data.draw_offset_x,data.draw_offset_y
      local hex_side_h =  0.5 * side * math.tan(math.rad(30))
      local hex_side = 0.5 * side / math.cos(math.rad(30))
      for col = 1, col_cnt do        
        for row = 1, row_cnt do     
          if form == 0 then
            w = w_side
            h = h_side
          elseif form == 1 then 
            w = side
            h = hex_side + hex_side_h
            if row % 2 ~= 1 then x_offs = x_offs - 0.5 * side else x_offs = 0 end             
           elseif form == 2 then 
            w = hex_side + hex_side_h
            h = side
            if col % 2 ~= 1 then y_offs = - 0.5 * side else y_offs = 0 end 
          end 
          
          if not notes[col] then notes[col] = {} end
          note_x = w* (col - 1) + x_offs+x_offs_glob
          local note_y =gfx.h - h* (row) - y_offs-- +y_offs_glob
          local x_lim = 70
          local y_lim = 60
          if note_x + w > 0 and note_x +w < gfx.w +x_lim and note_y +h > 0 and note_y+h < gfx.h+y_lim then 
            if not notes[col][row] then notes[col][row] = {} end
            if not notes[col][row].x then notes[col][row].x = note_x end
            if not notes[col][row].y then notes[col][row].y = note_y end
            if not notes[col][row].w then notes[col][row].w = w end
            if not notes[col][row].h then notes[col][row].h = h end
            if not notes[col][row].text then notes[col][row].text = '' end
            if not notes[col][row].form then notes[col][row].form = form end
            if update_notes then
              if not notes[col][row].pressed then notes[col][row].pressed = false end
            end
          end
        end
      end
                        --------------------------------   
    -- form pitches
      local note
      --data.base_note = 
      local base_note =-12
      if not data.layout_t.shift_cents then data.layout_t.shift_cents = 0 end
      local shift_cents = data.layout_t.shift_cents
       offs_oct = -math.floor(data.draw_offset_y / 50)
      -- rect
        if form == 0 then
          for col = 1, col_cnt do 
            note = base_note*offs_oct + col * int_1+shift_cents
            for row = 1, row_cnt do
              if notes[col][row] then
                note = note + int_2
                if not (note < low_pitch) and not  (note > high_pitch) then 
                  notes[col][row].midi_pitch = note
                  notes[col][row].text = Convert_Num2Pitch(note) or ''
                 else 
                  notes[col][row] = nil
                end
              end
            end
          end  
        end
      -- hex hor
        if form == 1 then
          int_3 = int_2 - int_1
          for col = 1, col_cnt do 
            note =base_note*offs_oct + col * int_1+shift_cents
            for row = 1, row_cnt do
              if notes[col][row] then
                if row%2 == 1 then note = note + int_2  else note = note + int_3 end 
                if not (note < low_pitch) and not  (note > high_pitch) then
                  notes[col][row].midi_pitch = note
                  notes[col][row].text = Convert_Num2Pitch(note) or ''
                 else 
                  notes[col][row] = nil
                end
              end
            end
          end  
        end
        
      -- hex vert
        if form == 2 then
          local int_3 = int_1 - int_2
          for row = 1, row_cnt do 
            note = base_note*offs_oct + int_2 * row+shift_cents
            for col = 1, col_cnt do 
              if notes[col][row] then
                if col%2 == 0 then note = note + int_3 else note = note +int_1 end
                if not (note < low_pitch) and not  (note > high_pitch) then
                  notes[col][row].midi_pitch = note
                  notes[col][row].text = Convert_Num2Pitch(note) or ''
                 else 
                  notes[col][row] = nil
                end
              end
            end
          end  
        end
                          --------------------------------   
      -- form scale rel
      local pitch, scale_note
      for col = 1, col_cnt do        
        for row = 1, row_cnt do 
          if notes[col][row] then 
            pitch = notes[col][row].midi_pitch            
            if pitch > 0 then 
            
              scale_note = math.fmod(pitch + 1, 12)
              local int, div = math.modf(scale_note)
              if div >= 0.5 then int = int +1  else int = int  end
              if int == data.scale_t.pitch[1] then notes[col][row].scale = 0
               else
                for i = 2, #data.scale_t.pitch do
                  if int == data.scale_t.pitch[i] then notes[col][row].scale = 1 break end
                end
                if not notes[col][row].scale then notes[col][row].scale = 2 end
              end
              
            end            
          end
        end
      end
    
    update_notes = false
    --return notes
  end
-----------------------------------------------------------------------    
  function Convert_Num2Pitch(val) 
    local oct_shift = -3+math.floor(data.oct_shift )
    if data.key_names == 0 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift end
     elseif data.key_names == 1 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B',}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift end  
     elseif data.key_names == 2 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si',}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift end      
     elseif data.key_names == 3 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'Do', 'Re♭', 'Re', 'Mi♭', 'Mi', 'Fa', 'Sol♭', 'Sol', 'La♭', 'La', 'Si♭', 'Si',}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift end       
     elseif data.key_names == 4 then
      if not val then return end
      local cents
      local int, div = math.modf(val)
      if div > 0.5 then 
        val = val + 1 
        cents = - ( (1 - div) * 100 )
       else 
        cents = div * 100 
      end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift..'_'..cents end           
     elseif    
      data.key_names == 5 -- midi pitch
      then return val
     elseif 
      data.key_names == 6 -- freq
      then return math.floor(440 * 2 ^ ( (val - 69) / 12))
     elseif 
      data.key_names == 7 -- empty
      then return ''   
    end
  end
-----------------------------------------------------------------------   
  function DEFINE_GUI_vars()
      local gui = {
                  aa = 1,
                  mode = 3,
                  fontname = 'Lucida Sans Unicode',
                  fontsize = 16}
                  
        if OS == "OSX32" or OS == "OSX64" then gui.fontsize = gui.fontsize - 5 end
        gui.fontsize_textb = gui.fontsize - 1
      
      gui.color = {['back'] = '20 20 20',
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
  -----------------------------------------------------------------------    
    function F_Get_SSV(s)
      local t = {}
      for i in s:gmatch("[%d%.]+") do 
        t[#t+1] = tonumber(i) / 255
      end
      gfx.r, gfx.g, gfx.b = t[1], t[2], t[3]
      return t[1], t[2], t[3]
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
  -----------------------------------------------------------------------         
  function GUI_note(gui, obj_t, ispressed) local t
    
    if not obj_t then return end
    local x,y,w,h,form, text  = obj_t.x, obj_t.y, obj_t.w, obj_t.h, obj_t.form, obj_t.text
    
    if obj_t.scale == 0 then color = data.color_t.ton_col
     elseif obj_t.scale == 1 then color = data.color_t.scale_col
     elseif obj_t.scale == 2 then color = data.color_t.out_scale_col
    end
    
    if not color then return end      
    F_Get_SSV(color, true)
    local text_col
    local check_r,check_g,check_b = gfx.r, gfx.g, gfx.b
    local rgb_test = check_r + check_g + check_b
    if rgb_test < 1.8 then text_col = gui.color.white else text_col = gui.color.black end
    --local color = obj_t.color --gui.color.blue 
 
    -- frame
    
      local  hex_side_h =  0.5 * w * math.tan(math.rad(30)) + 1
      local hex_side = 0.5 * w / math.cos(math.rad(30))
      gfx.mode = 1
      local col_alpha = 0.85
      local frame_alpha = 0.3
      
      if form == 0 then -- rect
        gfx.mode = 1
        gfx.a = col_alpha 
        F_Get_SSV(color, true)
        gfx.rect(x,y,w-1,h,1)   
        gfx.a = frame_alpha
        F_Get_SSV(gui.color.white, true)
        gfx.rect(x,y,w,h,0)   
       elseif form == 1 then  -- hex hor
        local bug_offset =0--h*0.002
        t = {       x,    y+(h-hex_side)/2+bug_offset,                  
                    x+w/2,y+(h-hex_side)/2-hex_side_h +bug_offset,
                    x+w-1,y+(h-hex_side)/2+bug_offset,
                    x+w-1,y +h/2+hex_side/2-bug_offset,
                    x+w/2,y+(h+hex_side)/2+hex_side_h-bug_offset,
                    x,    y +h/2+hex_side/2-bug_offset,
                    x,    y+(h-hex_side)/2-bug_offset }
       elseif form == 2 then  -- hex vert             
        local bug_offset = w*0.115
        t = { x + w/2-hex_side/2-hex_side_h - bug_offset/2 ,y+h/2,
              x + w/2-hex_side/2- bug_offset/2,             y+1,
              x + w/2+hex_side/2 + bug_offset/2,y+1,
              x + w/2+hex_side/2 + bug_offset/2+ hex_side_h  ,y+h/2,
              x + w/2+hex_side/2 + bug_offset/2,y+h,
              x + w/2-hex_side/2 - bug_offset/2 ,y+h,
              x + w/2-hex_side/2 - bug_offset/2 -hex_side_h,y+h/2}
      end
      
      if form == 1 or form == 2 then
        gfx.mode = 3
        gfx.a = col_alpha
        F_Get_SSV(color, true)
        gfx.triangle(t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12])
        gfx.a = frame_alpha
        F_Get_SSV(gui.color.white, true)
        gfx.x, gfx.y = t[1],t[2]              
        gfx.lineto(t[3],t[4])
        gfx.lineto(t[5],t[6])   
        gfx.lineto(t[7],t[8])
        gfx.lineto(t[9],t[10])
        gfx.lineto(t[11],t[12])
      end
      
      
      -- blit light
        gfx.a = 0.25
        gfx.x, gfx.y = x,y
        gfx.blit(5,1,0)
      
      --ispressed = true
        --if ispressed then 
        if obj_t.pressed then
          gfx.a = 0.2
          F_Get_SSV(gui.color.white, true)
          gfx.circle(x+w/2,y+h/2,w/4,1, 1) 
        end
                
      -- text
        if not text then return end
        local oct, note, sharp,space, cents
        --[[
        1-cc#
        2-cdb
        3-dodo#
        4-doreb
        5-pitch
        6-freq
        7-empty
        ]]
        if data.key_names <= 3 then
          text = tostring(text)
          oct = text:match('[%d]+')
          note = text:match('[%a]+')
          sharp = text:match('#') or text:match('♭')
          space = '  '
         elseif data.key_names == 4 then
          note = text:match('.-[%_]')
          if not note then 
            note = text
            space = ''
           else 
            note = note:sub(0,-2)
            cents = math.floor(text:match('[%_].*'):sub(2))
            if cents > 0 then cents = '+'..cents end
            space = ''
          end
         elseif data.key_names > 4 then
          note = text
          space = ''
        end
        
        if not note then return end
        local fnt_sz = math.floor(gui.fontsize - 5 + 0.2*w)
        gfx.setfont(1, gui.fontname, fnt_sz2)
        local fnt_sz1_h = gfx.texth
        local fnt_sz2 = math.floor(fnt_sz*0.8)
        gfx.setfont(1, gui.fontname, fnt_sz2)
        local fnt_sz2_h = gfx.texth
      -- note
        gfx.mode = 2 
        gfx.setfont(1, gui.fontname, fnt_sz)
        local measurestrnote = gfx.measurestr(note..space)
        local x0_note = x + (w - measurestrnote)/2 + 1
        local y0 = y + (h - gfx.texth)/2   
        gfx.a = 0.6
        F_Get_SSV(text_col, true)
        gfx.x, gfx.y = x0_note,y0 
        gfx.drawstr(note)
      -- oct
        local x_oct = x0_note + gfx.measurestr(note)
        if oct then 
          gfx.setfont(1, gui.fontname, fnt_sz2)
          local y0 = y + h/2
          gfx.a = 0.6
          F_Get_SSV(text_col, true)
          gfx.x, gfx.y = x_oct,y0 
          gfx.drawstr(oct)
        end
      -- sharp/flat
        if sharp then
          gfx.setfont(1, gui.fontname, fnt_sz2)
          local y0 = y + h/2 - fnt_sz2_h
          gfx.a = 0.6
          F_Get_SSV(text_col, true)
          gfx.x, gfx.y = x_oct,y0 
          gfx.drawstr(sharp)    
        end   
      -- cents
        if cents then
          gfx.setfont(1, gui.fontname, fnt_sz2)
          local measurestrcents = gfx.measurestr(cents)
          local x0_cents = x + (w - measurestrcents)/2 + 1
          local y0 = y + h/2 + fnt_sz1_h * .25
          gfx.a = 0.6
          F_Get_SSV(text_col, true)
          gfx.x, gfx.y = x0_cents,y0 
          gfx.drawstr(cents) 
        end 
  
  end  
  --------------------------------------------------------------------   
  function GUI_info(gui, obj) 
    local offs = 10
    gfx.a = 0.9
    gfx.mode = 2
    F_Get_SSV(gui.color.back, true)
    gfx.rect(0+offs,offs, gfx.w - offs*2, gfx.h-offs*2, 1)
    gfx.a = 1    
  end
  -------------------------------------------------------------------- 
  function GUI_settings(gui, obj) 
    local offs = 10
    gfx.a = 0.9
    gfx.mode = 2
    F_Get_SSV(gui.color.back, true)
    gfx.rect(0+offs,offs, gfx.w - offs*3 - obj.settings_but_w, gfx.h-offs*2, 1)
    gfx.a = 1
    GUI_button(gui, obj.settings_GUI, 0.01, 1)
      GUI_slider(gui, obj.settings_hex_w, 0.2)
      GUI_slider(gui, obj.settings_rect_ratio, 0.2)           
      GUI_button(gui, obj.settings_layout,0.05)
      GUI_button(gui, obj.settings_color,0.05)
      GUI_button(gui, obj.settings_scale,0.05)
      GUI_button(gui, obj.settings_key_name,0.05)       
      GUI_slider(gui, obj.settings_key_root, 0.2)
      GUI_button(gui, obj.settings_oct_shift,0.05)
      
    GUI_button(gui, obj.settings_MIDI, 0.01, 1)
      GUI_button(gui, obj.settings_note_release, 0.05)
      GUI_slider(gui, obj.settings_magn_area, 0.2)
      GUI_button(gui, obj.settings_playoutscale, 0.05)
      GUI_slider(gui, obj.settings_note_vel, 0) 
      local a_text if data.midi_release_behav == 2 then a_text = 0.15 else a_text = 0.7 end
      GUI_button(gui, obj.settings_support_PB, 0.05, 0, nil, a_text) 
      
    GUI_button(gui, obj.settings_INFO, 0.01, 1)
      GUI_button(gui, obj.info_conf, 0.05)
      GUI_button(gui, obj.info_cockos, 0.05)
      GUI_button(gui, obj.info_rmm, 0.05)
      GUI_button(gui, obj.info_vk, 0.05)
      GUI_button(gui, obj.info_sc, 0.05)
      GUI_button(gui, obj.info_donate, 0.05)
    
    gfx.mode = 1
  end
  --------------------------------------------------------------------   
  function GUI_slider(gui, obj_t)
    gfx.mode = 0
    -- define xywh
      local x,y,w,h,name = obj_t.x, obj_t.y, obj_t.w, obj_t.h,obj_t.name
    -- frame
      gfx.a = 0.1
      F_Get_SSV(gui.color.white, true)
      F_gfx_rect(x,y,w,h)     
      
      if not obj_t.val then val = 0 else val = obj_t.val end           
    -- blit grad   
      local handle_w = 30  
      local x_offs = x + (w - handle_w) * val
      gfx.a = 0.3
      gfx.blit(3, 1, 0, --backgr
          0,0,gfx.w,gfx.h,
          x,y,w*val,h)
    -- text
      gfx.setfont(1, gui.fontname, gui.fontsize)
      local measurestrname = gfx.measurestr(name)
      local x0 = x + (w - measurestrname)/2 + 1
      local y0 = y + (h - gfx.texth)/2 
      
      gfx.a = 0.3
      F_Get_SSV(gui.color.black, true)
      gfx.x, gfx.y = x0,y0 +2
      gfx.drawstr(name)
      gfx.a = 0.7
      F_Get_SSV(gui.color.green, true)
      gfx.x, gfx.y = x0,y0 
      gfx.drawstr(name)
      gfx.mode = 1  
    end
  -----------------------------------------------------------------------         
  function GUI_button(gui, obj, cust_alpha, noframe, use_dyn, a_text)
    gfx.mode = 2
    local x,y,w,h, name = obj.x, obj.y, obj.w, obj.h, obj.name
    -- frame
      if not noframe then
        gfx.a = 0.1
        F_Get_SSV(gui.color.white, true)
        F_gfx_rect(x,y,w,h)
      end
      
    -- back
      if cust_alpha then gfx.a = cust_alpha else gfx.a = 0.5 end
      gfx.blit(3, 1, math.rad(180), 1,1,50,50, x,y+1,w,h, 0,0)
                
    
    -- circle
      if use_dyn then
        local rad = 30
        local def_alpha = 0.55
        gfx.mode = 2
        F_Get_SSV(gui.color.black, true)
        local alpha = math.sin(math.rad(180*(clock % 1) /1))
        if mouse.last_obj == obj.id_mouse then 
          gfx.a = F_limit(def_alpha+0.2 * alpha , 0,1)
          rad = w/2+alpha*5 - 2
         else 
          gfx.a = def_alpha
          rad = rad - 2
        end
        gfx.circle(x+w/2,y+h/2,rad,1,1)
      end
    -- text
      gfx.setfont(1, gui.fontname, gui.fontsize)
      local measurestrname = gfx.measurestr(name)
      local x0 = x + (w - measurestrname)/2 + 1
      local y0 = y + (h - gfx.texth)/2 
      
      if a_text then 
        gfx.a = a_text
       else 
        gfx.a = 0.3
        F_Get_SSV(gui.color.black, true)
        gfx.x, gfx.y = x0,y0 +2
        gfx.drawstr(name)
        gfx.a = 0.7
      end
      F_Get_SSV(gui.color.green, true)
      gfx.x, gfx.y = x0,y0 
      gfx.drawstr(name)
      gfx.mode = 1    
  end 
  --------------------------------------------------------------------    
  function F_preview_sigh(gui, obj)
    local x0,y0,w,h, name = obj.x, obj.y, obj.w, obj.h, obj.name
    local side = 5
    x = x0 + w/2 - side*2
    y = y0 + h/2 - side
    gfx.a = 0.7
    F_Get_SSV(gui.color.green, true)
    local w_t, h_t = side,side*2
    local tr_w,tr_h = w_t, h_t/2
    gfx.rect(x,y,w_t,h_t)
    gfx.triangle(x+w_t, y,
                 x+w_t + tr_w, y - tr_h,
                 x+w_t+ tr_w, y+h_t+tr_h,
                 x+w_t, y+h_t)
    local angle = 40
    for i = 1, 2 do
      gfx.arc(x0+w/2,y0+h/2,5 + i^3, math.rad(angle), math.rad(180-angle), 1)
    end
  end
  --------------------------------------------------------------------  
  function GUI_draw(obj, gui)--, notes)         
    local buf_dest
    gfx.mode = 1 -- additive mode
    local time_flow =0.4--sec
    if alpha_change == 0.2 and alpha_change_dir == 0 and update_gfx_alt then update_gfx = true end
    -- DRAW static buffers
    if update_gfx_onstart then  
      -- buf3 -- buttons back gradient 
      -- buf5 -- cent_point light
      -- buf 6 GUI_note
      
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
                   
                   
      -- buf5 -- cent_point light  
        gfx.dest = 5        
        gfx.mode = 1
        local side = data.notes_hex_side * data.notes_side_ratio
        gfx.setimgdim(5, -1, -1)  
        gfx.setimgdim(5, side*2,side*2) 
        gfx.a = 0.25
        local a = 0.12
        local r = 0.12
        gfx.circle(side*0.5,side*0.5,side*r*4,1,1) 
        gfx.a = a
        gfx.circle(side*0.5,side*0.5,side*r*3,1,1) 
        gfx.a = a
        gfx.circle(side*0.5,side*0.5,side*r*2,1,1)    
        gfx.a = a
        gfx.circle(side*0.5,side*0.5,side*r,1,1)
        for i = 1, 20 do 
          gfx.x, gfx.y = 0,0
          gfx.blurto(side*2,side*2)
        end
    end
    
    -- Store Com Buffer
      if update_gfx then  
        if not alpha_change_dir then alpha_change_dir = 1 end
        alpha_change_dir = math.abs(alpha_change_dir - 1)  
        run_change0 = clock       
        if alpha_change_dir == 0 then buf_dest = 10 else buf_dest = 11 end -- if 0 #10 is next
        gfx.dest = buf_dest
        gfx.setimgdim(buf_dest, -1, -1)  
        gfx.setimgdim(buf_dest, obj.main_w,obj.main_h*3) 
        -- notes
          for row = 1, data.row_cnt do  
            for col = 1, data.col_cnt do 
              GUI_note(gui, notes[row][col] ) 
            end
          end
        -- buttons back
          gfx.a = 0.8
          gfx.blit(3, 1, 0,
                      0,0,  obj.main_w,obj.main_h,
                      obj.but_area.x,obj.but_area.y,  obj.but_area.w,obj.but_area.h, 0,0)
 
      end
      
    --  Define smooth changes 
      if run_change0 then
        if clock - run_change0 < time_flow then 
          alpha_change = F_limit((clock - run_change0)/time_flow  + 0.2, 0,1)
        end
      end
      
    -- Draw Common buffer
      gfx.dest = -1
      gfx.x,gfx.y = 0,0
      F_Get_SSV(gui.color.back, true)
      gfx.a = 1
      gfx.mode = 1
      -- smooth com
        local buf1, buf2
        if alpha_change_dir == 0 then 
          buf1 = 10 buf2 = 11 
         else 
          buf1 = 11 buf2 = 10  
        end
        local a1 = alpha_change
        local a2 = math.abs(alpha_change - 1)
        if (settings_page and settings_page == 1) 
          or (info_page and info_page == 1)  then gfx.a = a1* .6 else gfx.a = a1 end
        local angle = 0--math.rad(0)
        gfx.blit(buf1, 1, angle,
            0,0,  obj.main_w,obj.main_h*3,
            0,0,  obj.main_w,obj.main_h*3, 0,0)
        gfx.a = a2
        gfx.blit(buf2, 1, angle, 
            0,0,  obj.main_w,obj.main_h*3,
            0,0,  obj.main_w,obj.main_h*3, 0,0)  
                     
    --  settings
        if settings_page and settings_page == 1 then GUI_settings(gui, obj) end
        --if info_page and info_page == 1 then GUI_info(gui, obj) end
            
    -- navigation
    
      GUI_button(gui, obj.preview, 0, 0, true)
        F_preview_sigh(gui, obj.preview)
      GUI_button(gui, obj.drag, 0, 0, true)
      GUI_button(gui, obj.settings, 0, 0, true)
      
        
      update_gfx = false
      update_gfx_onstart = false
      --update_gfx_alt = false
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
  ------------------------------------------------------------------ 
  function MOUSE_match(b, offs)
    if b then
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
  function MOUSE_button (xywh, offs)
    if MOUSE_match(xywh, offs) and mouse.LMB_state and not mouse.last_LMB_state then return true end
  end  
  -----------------------------------------------------------------------    
  function MOUSE_slider (obj, limit_1, limit2)
    --if mouse.last_obj ~= 'drag' then return end
    local val, limit_1, limit_2
    if not limit_1 then limit_1 = 0 end
    if not limit_2 then limit_2 = 1 end
    if MOUSE_match(obj) and mouse.LMB_state  then 
      if mouse.mx < obj.x + obj.w then
        mouse.last_obj = obj.id_mouse
      end
    end    
    if mouse.last_obj == obj.id_mouse and  mouse.LMB_state then       
      val = F_limit((mouse.mx - obj.x)/obj.w, limit_1, limit2)
      return val
    end    
  end
  ----------------------------------------------------------------------- 
  function F_dec2hex(num)
    local str = string.format("%x", num)
    return str
  end
  ----------------------------------------------------------------------- 
  function MOUSE_notes(obj)--, notes)
    local area_stat = 40
      for col = 1, data.row_cnt do  
        for row = 1, data.col_cnt do  
          local area = area_stat * data.magnet_area * data.notes_hex_side
          if notes[col][row] then
            local match_t = {x= notes[col][row].x-area/2,
                              y= notes[col][row].y-area/2,
                              w= notes[col][row].w+area,
                              h= notes[col][row].h+area}
            if mouse.LMB_state 
              
              and MOUSE_match({x=0,y=0,w=gfx.w,h=gfx.h})  
              and MOUSE_match(match_t, 0) 
              and not MOUSE_match(obj.but_area) then 
              
              mouse.last_obj = col..' '..row
              
              if data.midi_release_behav == 0 
                or data.midi_release_behav == 2 then
                if notes[col][row].pressed == false then                                    
                  if notes[col][row].midi_pitch then                    
                    if not (data.playoutscale == 0 and notes[col][row].scale == 2 ) then
                      
                      if data.support_PB and data.support_PB == 1 then
                        if not midi_chan then midi_chan = 1 else midi_chan = midi_chan + 1 end
                        local _, pitchbend = math.modf(notes[col][row].midi_pitch)
                        pitchbend = 8192 + math.floor(8192*pitchbend)
                        reaper.StuffMIDIMessage( 0, '0xE'..F_dec2hex(midi_chan),
                                                    pitchbend & 0x7F,
                                                    pitchbend >> 7)                       
                        reaper.StuffMIDIMessage( 0, '0x9'..F_dec2hex(midi_chan),
                                                    math.floor(notes[col][row].midi_pitch),  
                                                    math.floor(data.velocity*127)) 
                        update_gfx = true
                        notes[col][row].pressed = true 
                        notes[col][row].midi_chan = midi_chan                                    
                       else
                        reaper.StuffMIDIMessage( 0, 0x90,
                                                    math.floor(notes[col][row].midi_pitch),  
                                                    math.floor(data.velocity*127))
                        update_gfx = true
                        notes[col][row].pressed = true  
                      end
                      
                    end                     
                  end
                end
              end
              
              if data.midi_release_behav == 1 then
                if not mouse.last_LMB_state then -- note off all on release
                  if notes[col][row].pressed == false then 
                    if notes[col][row].midi_pitch then                      
                      if not (data.playoutscale == 0 and notes[col][row].scale == 2 ) then
                      
                        if data.support_PB and data.support_PB == 1 then
                          if not midi_chan then midi_chan = 1 else midi_chan = midi_chan + 1 end
                          local _, pitchbend = math.modf(notes[col][row].midi_pitch)
                          pitchbend = 8192 + math.floor(8192*pitchbend)
                          reaper.StuffMIDIMessage( 0, '0xE'..F_dec2hex(midi_chan),
                                                      pitchbend & 0x7F,
                                                      pitchbend >> 7)                       
                          reaper.StuffMIDIMessage( 0, '0x9'..F_dec2hex(midi_chan),
                                                      math.floor(notes[col][row].midi_pitch),  
                                                      math.floor(data.velocity*127)) 
                          update_gfx = true
                          notes[col][row].pressed = true 
                          notes[col][row].midi_chan = midi_chan                                    
                         else
                          reaper.StuffMIDIMessage( 0, 0x90,
                                                      math.floor(notes[col][row].midi_pitch),  
                                                      math.floor(data.velocity*127))
                          update_gfx = true
                          notes[col][row].pressed = true  
                        end
  
                      end                      
                    end
                  end                  
                end
              end  
            end
          end
        end
      end
                
          
      if data.midi_release_behav == 2 then -- Note off on note change
        if mouse.last_obj and tostring(mouse.last_obj):match('(%d+) (%d+)') then
          if not mouse.last_note or mouse.last_note ~=  mouse.last_obj then
            mouse.last_note = mouse.last_obj
            local _col, _row = tostring(mouse.last_obj):match('(%d+) (%d+)')
            local _col, _row = tonumber(_col), tonumber(_row)
            if notes[_col] and notes[_col][_row] and notes[_col][_row].midi_pitch then 
              local _last_pitch = notes[_col][_row].midi_pitch
              for i = 1, 127 do  
                if i ~= _last_pitch then  
                  --[[if data.support_PB and data.support_PB == 1 then
                    reaper.StuffMIDIMessage( 0, 
                                            '0xE'..F_dec2hex(notes[_col][_row].midi_chan),
                                             8192 & 0x7F,
                                             8192 >> 7) 
                    reaper.StuffMIDIMessage( 0, --mode, 0=VKB, 
                                           '0x80',--..F_dec2hex(notes[_col][_row].midi_chan), 
                                           i, -- note
                                           0) --vel)
                   else]]
                    reaper.StuffMIDIMessage( 0, --mode, 0=VKB, 
                                           0x80, 
                                           i, -- note
                                           0) --vel)
                    notes[_col][_row].pressed = false
                  --end
                end
              end
              
            end
          end
        end
      end
      
      --if mouse.last_obj then msg(mouse.last_obj) end
      
      -- release + note off
        if mouse.last_LMB_state and not mouse.LMB_state    then
          for midi_chan = 1, 16 do
            reaper.StuffMIDIMessage( 0, 
                                  '0xE'..F_dec2hex(midi_chan),
                                      8192 & 0x7F,
                                      8192 >> 7)  
          end
          for i = 1, 127 do 
            if data.support_PB and data.support_PB == 1 then
              
              for midi_chan = 1, 16 do
                reaper.StuffMIDIMessage( 0, --mode, 0=VKB, 
                                     '0x8'..F_dec2hex(midi_chan), 
                                     i, -- note
                                     0) --vel)
              end
             else      
              reaper.StuffMIDIMessage( 0, --mode, 0=VKB, 
                                     0x80, 
                                     i, -- note
                                     0) --vel)
            end
          end
          midi_chan = nil
          for col = 1, data.row_cnt do  
            for row = 1, data.col_cnt do 
              if notes[col][row] then
                notes[col][row].pressed = false
              end
            end
          end
          update_gfx = true
        end
    return obj
  end  
  -----------------------------------------------------------------------  
  function GUI_menu(t, check, sub_name) local name
    local str = ''
    for i = 1, #t do 
      if sub_name then 
        local t2 = {} for num in t[i]:gmatch('[^%s]+') do t2[#t2+1] = num end
        name = t2[1]
       else
        name = t[i]
      end
      
      if check == i-1 then
        str = str..'!'..name ..'|'
       else
        str = str..name ..'|'
      end
    end
    gfx.x, gfx.y = mouse.mx,mouse.my
    ret = gfx.showmenu(str) - 1
    if ret >= 0 then return ret end
  end
  -----------------------------------------------------------------------  
  function F_Menu_Resp(data, ext_state_key)
    local config_path = debug.getinfo(2, "S").source:sub(2):sub(0,-5)..'_config.ini' 
    local t2 = {}    
    for i = 1, 300 do
      _, stringOut = reaper.BR_Win32_GetPrivateProfileString(ext_state_key, i, '', config_path )
      if stringOut == '' then break end
      local t = F_ret_ExtState(stringOut)
      t2[#t2+1] = t.name
    end
    local ret = GUI_menu( t2, data - 1 )
    if ret then return math.floor(ret) + 1 end
  end
  ----------------------------------------------------------------------- 
  function ENGINE_enable_preview()
    local tr = reaper.GetSelectedTrack(0,0)
    if not tr then return end    
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECARM', 1 )
    local bits_set=tonumber('111110'..'00000',2)
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT', 4096+bits_set )                                                        
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECMON', 1 )     
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
  function MOUSE_get(obj,gui)--notes, 
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
    if mouse.last_wheel then mouse.wheel_trig = (mouse.wheel - mouse.last_wheel) end
    if not mouse.wheel_trig then mouse.wheel_trig = 0 end
    
    if not mouse.last_LMB_state and mouse.LMB_state then 
      mouse.LMB_stamp_x = mouse.mx
      mouse.LMB_stamp_y = mouse.my
      
      offset_stamp_x = data.draw_offset_x
      offset_stamp_y = data.draw_offset_y
    end
    
    if mouse.LMB_state then 
      mouse.dx = mouse.mx - mouse.LMB_stamp_x
      mouse.dy = mouse.my - mouse.LMB_stamp_y
    end
    
    --  scroll vies
      if mouse.wheel_trig ~= 0 then
        base_note_st = data.base_note
        data.base_note = F_limit(base_note_st + 12 * math.floor(mouse.wheel_trig/60), -12, 96)
        Data_Update()
        update_gfx = true
        update_gfx_alt = true
        alpha_change_dir = 1
      end
    
    --  setting/drag page toggle
      if MOUSE_match(obj.drag) then mouse.last_obj = obj.drag.id_mouse 
        elseif
          MOUSE_match(obj.settings) 
          and not mouse.LMB_state
          then  mouse.last_obj = obj.settings.id_mouse 
        elseif
          MOUSE_match(obj.preview) 
          and not mouse.LMB_state
          then  mouse.last_obj = obj.preview.id_mouse           
        elseif (not mouse.LMB_state and MOUSE_match(obj.but_area) ) 
            or not mouse.LMB_state-- and not MOUSE_match({x=0,y=0,w=gfx.w,h=gfx.h})) 
          then mouse.last_obj = 0
      end
      
      
      if MOUSE_button(obj.settings, 0) then settings_page = math.abs(settings_page-1) update_gfx = true end
      if MOUSE_button(obj.preview, 0) then ENGINE_enable_preview() end
      
      
    -- drag
      if mouse.last_obj == 'drag' and mouse.LMB_state then
        data.draw_offset_x = offset_stamp_x + mouse.dx
        data.draw_offset_y = offset_stamp_y + mouse.dy
        Data_Update()
        Data_LoadConfig()
        update_gfx  =true
        update_notes = true
        DEFINE_Notes()
      end
    
    --  main
    if settings_page ~= 1 then
      if not MOUSE_match(obj.but_area) and mouse.last_obj ~= 'drag' then 
        obj = MOUSE_notes(obj, notes) 
      end
     else
      if MOUSE_button(obj.info_conf, 0) then
              local config_path = debug.getinfo(2, "S").source:sub(2):sub(0,-5)..'_config.ini' 
              local cmd = 'start "" "'..config_path..'"'
              os.execute(cmd)
            end
            
            if MOUSE_button(obj.info_cockos, 0) then F_open_URL('http://forum.cockos.com/showthread.php?t=185976') end
            if MOUSE_button(obj.info_rmm, 0) then F_open_URL('http://rmmedia.ru/threads/126388/') end
            if MOUSE_button(obj.info_vk, 0) then F_open_URL('http://vk.com/michael_pilyavskiy') end
            if MOUSE_button(obj.info_sc, 0) then F_open_URL('http://soundcloud.com/mp57') end
            if MOUSE_button(obj.info_donate, 0) then F_open_URL('http://www.paypal.me/donate2mpl') end
            
      -- hex side --
        local val = MOUSE_slider (obj.settings_hex_w, 0.2, 1)      
        if val then 
          data.notes_hex_side = val 
          update_gfx_onstart = true
          Data_Update()
          Data_LoadConfig()
          update_gfx  =true
          update_notes = true
          DEFINE_Notes()
        end
      -- hex side --
        local val = MOUSE_slider (obj.settings_rect_ratio, 0.2, 1)      
        if val then 
          data.rect_ratio = val 
          update_gfx_onstart = true
          Data_Update()
          Data_LoadConfig()
          update_gfx  =true
          update_notes = true
          DEFINE_Notes()
        end 
      -- layout
        if MOUSE_button(obj.settings_layout, 0) then 
          data.layout_act = F_Menu_Resp(data.layout_act, 'Layouts')
          update_gfx_onstart = true
          update_gfx  =true
          update_notes = true
          data.draw_offset_x = 0
          data.draw_offset_y = 0
          Data_Update()
          Data_LoadConfig()
          DEFINE_Notes()
          update_gfx_alt = true
          alpha_change_dir = 1
        end        
      -- color
        if MOUSE_button(obj.settings_color, 0) then          
          data.color_act = F_Menu_Resp(data.color_act, 'Colors')
          update_gfx_onstart = true
          update_gfx  =true
          update_notes = true
          Data_Update()
          Data_LoadConfig()
          DEFINE_Notes()
          update_gfx_alt = true
          alpha_change_dir = 1        end         
      -- scale
        if MOUSE_button(obj.settings_scale, 0) then          
          data.scale_act = F_Menu_Resp(data.scale_act, 'Scales')
          update_gfx_onstart = true
          update_gfx  =true
          update_notes = true
          Data_Update()
          Data_LoadConfig()
          DEFINE_Notes()
          update_gfx_alt = true
          alpha_change_dir = 1        
        end
      -- keyname
        if MOUSE_button(obj.settings_key_name, 0) then          
          local ret = GUI_menu( {'C-C#',
                                  'C-D♭',
                                  'Do-Do#',
                                  'Do-Re♭',
                                  'C-C# + cents',
                                  'MIDI Pitch',
                                  'Frequency',
                                  'Empty'
                                }, data.key_names )
          if ret then 
            data.key_names = math.floor(ret) 
            update_gfx_onstart = true
            update_gfx  =true
            update_notes = true
            Data_Update()
            Data_LoadConfig()
            DEFINE_Notes()
            update_gfx_alt = true
            alpha_change_dir = 1
          end
        end    
             
      -- keyroot
        if MOUSE_button(obj.settings_key_root, 0) then          
          local ret = GUI_menu( {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',}, 
            math.floor(data.key_root) )
            --msg(ret)
          if ret then 
            data.key_root = ret
            update_gfx_onstart = true
            update_gfx  =true
            update_notes = true
            Data_Update()
            Data_LoadConfig()
            DEFINE_Notes()
            update_gfx_alt = true
            alpha_change_dir = 1
          end
        end            
      -- oct_shift
        if MOUSE_button(obj.settings_oct_shift, 0) then          
          local ret = GUI_menu( {'C3 = 48','C3 = 60', 'C3 = 72'}, 
            math.floor(data.oct_shift) )
            --msg(ret)
          if ret then 
            data.oct_shift = ret
            update_gfx_onstart = true
            update_gfx  =true
            update_notes = true
            Data_Update()
            Data_LoadConfig()
            DEFINE_Notes()
            update_gfx_alt = true
            alpha_change_dir = 1
          end
        end            
           
           
                
      -- release MIDI -- 
        if MOUSE_button(obj.settings_note_release, 0) then
          local ret = GUI_menu( { 
                              'Hold/drag multiple notes/chords',
                              'Hold single note/chord only',
                              'Hold/drag single note only'}, data.midi_release_behav )
          if ret then 
            data.midi_release_behav = math.floor(ret) 
            update_gfx_onstart = true
            update_gfx  =true
            update_notes = true
            Data_Update()
            Data_LoadConfig()
            DEFINE_Notes()
            update_gfx_alt = true
            alpha_change_dir = 1
          end
        end
      -- magnet area --
        local val = MOUSE_slider (obj.settings_magn_area, 0, 1)      
        if val then 
          data.magnet_area = val 
          Data_Update()
        end        
      -- playoutscale --
        local val = MOUSE_button (obj.settings_playoutscale, 0, 1)      
        if val then 
          data.playoutscale = math.abs(data.playoutscale  -1)
          Data_Update()
          update_gfx  =true
        end    
      -- support PB/channels     
        local val = MOUSE_button (obj.settings_support_PB, 0, 1)      
        if val then 
          data.support_PB = math.abs(data.support_PB  -1)
          Data_Update()
          update_gfx  =true
        end         
        
        
        
        
      -- note vel --
        local val = MOUSE_slider (obj.settings_note_vel, 0, 1)      
        if val then 
          data.velocity = val 
          Data_Update()
        end 
     --elseif info_page == 1 then
         
    end -- if settings_page == 0
    
    -- reset mouse context/doundo
      if mouse.last_LMB_state and not mouse.LMB_state and not mouse.RMB_state then mouse.last_obj = 0 end
      
    -- mouse release
      mouse.last_LMB_state = mouse.LMB_state  
      mouse.last_RMB_state = mouse.RMB_state
      mouse.last_MMB_state = mouse.MMB_state 
      mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
      mouse.last_Ctrl_state = mouse.Ctrl_state
      mouse.last_Alt_state = mouse.Alt_state
      mouse.last_wheel = mouse.wheel 
      return obj
  end       
  --------------------------------------------------------------------        
  function Run()    
    local d_state, gfxx,gfxy = gfx.dock(-1,0,0)
    if not last_gfxw or 
       not last_gfxh or 
       not last_d_state or 
       last_d_state ~= d_state or
       last_gfxw ~=  gfx.w or 
       last_gfxh ~=  gfx.h then      
      Data_Update()
      update_gfx = true
      update_gfx_onstart = true
    end
    if not last_gfxx or 
       not last_gfxy or 
       last_gfxx ~= gfxx or
       last_gfxy ~= gfxy then      
      Data_Update()
    end    
    
    
    last_d_state, last_gfxx,last_gfxy, last_gfxw, last_gfxh = d_state, gfxx,gfxy,gfx.w,gfx.h
    
    clock = os.clock()
    local obj = DEFINE_Objects()    
    local gui = DEFINE_GUI_vars()
    --local notes = 
    DEFINE_Notes(obj)
    obj = MOUSE_get(obj, gui)--notes, )
    GUI_draw(obj, gui)--, notes)
    
    
    local char = gfx.getchar() 
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end
    if char == 27 then gfx.quit() end     
    if char ~= -1 then reaper.defer(Run) else gfx.quit() end    
  end  
  ------------------------------------------------------------------ 
  function msg(str)
    local str1
     if type(str) == 'boolean' then 
       if str == true then str1 = 'true' else str1 = 'false' end
      else 
       str1 = str
     end
     if str1 then 
       reaper.ShowConsoleMsg(str1..'\n') 
      else
       reaper.ShowConsoleMsg('nil')
     end    
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
  ------------------------------------------------------------------    
  function Data_InitContent()
    return
[[
// configuration for MPL Isomorphic keyboard

[Info]

// Please don`t edit global variables
[Global_VAR]

// Color theme typical synthax is:
// name, type, tonic hex color, scale hex color, out of scale hex color
// type 1 - scale based, type 2 - (reserved for palette type)
[Colors]
1="Piano Isomorphic" 1 #ff6f6f #7dff72 #8b8b8b
2="WB" 1 #ffffff #e1e1e1 #3e3e3e

// Scales use same synthax as .reascale files
[Scales]
1="Default" 101011010101
2="Dorian" 102304050670
3="Phrygian" 120304056070
4="Lydian" 102030450607
5="Mixolydian" 102034050670
6="Minor" 102304056070
7="Locrian" 120304506070
8="Harmonic Minor" 102304056007
9="Harmonic Major" 102034056007
10="Medolic Minor"  102304050607
11="Hungarian Gypsy 1" 102300456007
12="Hungarian Gypsy 2" 102300456070
13="Hungarian Major" 100230450670
14="Enigmatic" 120030405067
15="Persian" 120034506007
16="Composite Blues" 100334450070

//Layouts have synthax like this: name, interval 1, interval 2, form, cents shift
// interval 1: E for rectangles and horizontal hexagons(form 1), NE for vertical hexagons(form 2)
// interval 2: N for rectangles and vertical hexagons (form 2), NE for horizontal hexagons (form 1)
// form is: 0 - rectangles/squares, 1 - horizontal hexagons, 2 - vertical hexagons
// cents shift: 0 - 1 cents
[Layouts]
1="Wicki-Hayden"    2 7 1 0
2="Janko"           2 1 1 0
3="Harmonic"        4 7 2 0
4="Gerhard"         4 1 2 0
5="LinnStrument"    1 5 0 0
6="Microtonal test" 0.5 2 1 0.05]]    
  end
  ------------------------------------------------------------------   
  function Data_LoadConfig()
    local def_data, def_layouts, def_colors, def_scales = Data_defaults()
    local layouts_count = 8
    
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
      Data_LoadSection(def_data, data, 'Global_VAR', config_path)
      
    -- Load color
      local _, stringOut = reaper.BR_Win32_GetPrivateProfileString(
        'Colors', 
        data.color_act, 
        '"Piano Isomorphic" 1 #ff6f6f #7dff72 #8b8b8b', 
        config_path )
      data.color = stringOut
      
    -- Load layout
      local _, stringOut = reaper.BR_Win32_GetPrivateProfileString(
        'Layouts', 
        data.layout_act, 
        '"Wicki-Hayden" 2 7 1 0', 
        config_path )
      data.layout = stringOut 

    -- Load scale
      local _, stringOut = reaper.BR_Win32_GetPrivateProfileString(
        'Scales', 
        data.scale_act, 
        '"Default" 101011010101', 
        config_path )
      data.scale = stringOut  
   
   -- parse data for generating objects
   -- color
     local t = F_ret_ExtState(data.color)
     local type_col = t[1][1]
     if type_col == 1 then
        data.color_t = {name = t.name,
                     ton_col = F_Hex_to_rgb_SSS(t[1][2]),
                     scale_col = F_Hex_to_rgb_SSS(t[1][3]),
                     out_scale_col = F_Hex_to_rgb_SSS(t[1][4])} 
     end  
   -- layout
     local t = F_ret_ExtState(data.layout)
     data.layout_t = {name = t.name,
                     int_1 = tonumber(t[1][1]),
                     int_2 = tonumber(t[1][2]),
                     form = tonumber(t[1][3]),
                     shift_cents =  tonumber(t[1][4])}
      for key in pairs(data.layout_t) do
        if tonumber(data.layout_t[key]) then
          local _, fract = math.modf(data.layout_t[key])
          if fract > 0 then 
            data.key_names = 4
            break 
          end
        end 
      end                      
    -- scale
      local t = F_ret_ExtState(data.scale)
      local scale_pat = tostring(t[1][1])
      local T_pat = {}
      for i = 1, 12 do
        local s = scale_pat:sub(i,i)
        local note = i + math.floor(data.key_root)
        if note >= 12 then note = note - 12 end
        if s ~= '0' then  T_pat[#T_pat+1] = note end
      end      
      data.scale_t = {name = t.name,
                      pitch = T_pat}   
                      
    --
      if data.midi_release_behav == 2 then data.support_PB = 0 end                                  
  end      
 
  ------------------------------------------------------------------
  function  F_Hex_to_rgb_SSS(hex)
    local col = tonumber(hex:gsub('#',''), 16)
    local r, g, b
    if OS == "OSX32" or OS == "OSX64" then 
      r, g, b =  reaper.ColorFromNative( col )
     else 
      b, g, r =  reaper.ColorFromNative( col )
    end
    return r..' '..g..' '..b
  end
  ------------------------------------------------------------------ 
  function Data_Update()
    local config_path = debug.getinfo(2, "S").source:sub(2):sub(0,-5)..'_config.ini' 
    local d_state, win_pos_x,win_pos_y = gfx.dock(-1,0,0)
    data.window_x, data.window_y, data.window_w, data.window_h, data.d_state = win_pos_x,win_pos_y, gfx.w, gfx.h, d_state
    for key in pairs(data) do 
      if type(data[key])~= 'table' 
        and key~= 'layout'
        and key~= 'color'
        and key~= 'scale'
        then 
        reaper.BR_Win32_WritePrivateProfileString( 'Global_VAR', key, data[key], config_path )  
      end 
    end
    reaper.BR_Win32_WritePrivateProfileString( 'Info', 'vrs', vrs, config_path )  
  end
  -----------------------------s------------------------------------- 
  settings_page = 0 
  ch_screen = true
  ch_screen_num =0 -- def scr
  ch_screen_move = 1  
  OS = reaper.GetOS()  
  data = {}
  mouse = {}
  notes = {}
  Data_LoadConfig()  
  local obj = DEFINE_Objects()    
  update_gfx = true
  update_gfx_onstart = true  
  update_notes = true
  ------------------------------------------------------------------ 
  gfx.init(name..' // '..vrs, data.window_w, data.window_h, data.d_state, data.window_x, data.window_y)
  Run()
