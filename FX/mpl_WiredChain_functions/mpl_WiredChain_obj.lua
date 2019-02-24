-- @description WiredChain_obj
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  
  
  ---------------------------------------------------
  function OBJ_init(obj)  
    -- globals
    obj.reapervrs = tonumber(GetAppVersion():match('[%d%.]+')) 
    obj.offs = 5 
    obj.grad_sz = 200 
    --obj.module_h = 15 -- pin height
    
    -- module
    obj.module_a_frame = 0.1   
    obj.module_alpha_back = 0.05
    obj.module_alpha_back2= 0.5
        
    -- topline
    obj.menu_w = 50
    
    -- tr IO            --  GLOBAL PIN size
    obj.trIO_x_offset = 10
    obj.trIO_y = 40
    obj.trIO_w = 15
    obj.trIO_h = 16--obj.module_h
    
    -- fx
    obj.fx_x_space = 50 -- defautf offset from IO when generating FX positions
    obj.fx_y_space = 110
    obj.fx_y_shift = 0 -- defautf shoft from IO when generating FX positions
    obj.fxmod_w = 120
    
    obj.fxsearch_item_h = 20
    
    -- wire
    obj.audiowire_col = 'green'
    obj.audiowire_a = 0.3
    
    -- font
    obj.GUI_font = 'Calibri'
    obj.GUI_fontsz = 19  -- 
    obj.GUI_fontsz2 = 15 -- 
    obj.GUI_fontsz3 = 13-- 
    obj.GUI_fontsz_tooltip = 13
    if GetOS():find("OSX") then 
      obj.GUI_fontsz = obj.GUI_fontsz - 6 
      obj.GUI_fontsz2 = obj.GUI_fontsz2 - 5 
      obj.GUI_fontsz3 = obj.GUI_fontsz3 - 4
      obj.GUI_fontsz_tooltip = obj.GUI_fontsz_tooltip - 4
    end 
    
    -- colors    
    obj.GUIcol = { grey =    {0.5, 0.5,  0.5 },
                   white =   {1,   1,    1   },
                   red =     {1,   0.2,    0.2   },
                   green =   {0.3,   0.9,    0.3   },
                   black =   {0,0,0 }
                   }    
    
    -- other
  end
  function IsRectInSelection(obj, obj_test)
    if not obj.selection_rect then return end
    local x1,y1,w1,h1  =obj.selection_rect.x, obj.selection_rect.y,obj.selection_rect.w,obj.selection_rect.h
    local x2,y2,w2,h2  =obj_test.x, obj_test.y,obj_test.w,obj_test.h
    return not (
            x2 > x1+w1 or
            x2+w2 < x1 or 
            y2 > y1+h1 or
            y2+h2 < y1)
  end
  --------------------------------------------------- 
  function ObjSelectRect(conf, obj, data, refresh, mouse) 
    if data.fx then 
      for fxid = 1, #data.fx do
        if obj['fx_'..fxid] and IsRectInSelection(obj, obj['fx_'..fxid]) then obj['fx_'..fxid].is_selected = true end
      end
    end
  end
  --------------------------------------------------- 
  function Obj_EnumeratePlugins(conf, obj, data, refresh, mouse)
    obj.plugs_data = {}
    local res_path = GetResourcePath()
    Obj_EnumeratePlugins_Sub(conf, obj, data, refresh, mouse, res_path, '/reaper-vstplugins.ini',  '%=.*%,(.*)', 0)
    Obj_EnumeratePlugins_Sub(conf, obj, data, refresh, mouse, res_path, '/reaper-vstplugins64.ini',  '%=.*%,(.*)', 0)
    Obj_EnumeratePlugins_Sub(conf, obj, data, refresh, mouse, res_path, '/reaper-dxplugins.ini',  'Name=(.*)', 2)  
    Obj_EnumeratePlugins_Sub(conf, obj, data, refresh, mouse, res_path, '/reaper-dxplugins64.ini',  'Name=(.*)', 2) 
    Obj_EnumeratePlugins_Sub(conf, obj, data, refresh, mouse, res_path, '/reaper-auplugins.ini',  'AU%s%"(.-)%"', 3) 
    Obj_EnumeratePlugins_Sub(conf, obj, data, refresh, mouse, res_path, '/reaper-auplugins64.ini',  'AU%s%"(.-)%"', 3)  
    Obj_EnumeratePlugins_Sub(conf, obj, data, refresh, mouse, res_path, '/reaper-jsfx.ini',  'NAME (.-)%s', 4) 
    Obj_EnumerateChains(conf, obj, data, refresh, mouse, res_path..'/FXChains') 
  end
  --------------------------------------------------------------------
  function Obj_EnumerateChains(conf, obj, data, refresh, mouse, path)
      
    -- create if not exist
      if not obj.plugs_data then obj.plugs_data = {} end
      for i = 0 , 500 do
        local file =  EnumerateFiles( path, i )
        if not file then break end
        obj.plugs_data[#obj.plugs_data+1] = {name = file, 
                                                reduced_name = file ,
                                                plugtype = 1024}
              
      end
  end  
  --------------------------------------------------------------------
  function Obj_EnumeratePlugins_Sub(conf, obj, data, refresh, mouse, res_path, file, pat, plugtype)
    -- validate file
      local fp = res_path..file
      local f = io.open(fp, 'r')
      local content
      if f then 
        content = f:read('a')
        f:close()
       else 
        return 
      end
      if not content then return end
      
    -- create if not exist
      if not obj.plugs_data then obj.plugs_data = {} end
    -- parse
      for line in content:gmatch('[^\r\n]+') do
        local str = line:match(pat)
        if plugtype == 4 and line:match('NAME "') then
          str = line:match('NAME "(.-)"') 
          --str = str:gsub('.jsfx','')
        end
        if str then 
          if str:match('!!!VSTi') and plugtype == 0 then plugtype = 1 end
          str = str:gsub('!!!VSTi','')
          
          -- reduced_name
            reduced_name = str
            if plugtype == 3 then  if reduced_name:match('%:.*') then reduced_name = reduced_name:match('%:(.*)') end    end
            if plugtype == 4 then  
            
              --reduced_name = reduced_name:sub(5)
              local pat_js = '.*[%/](.*)'
              if reduced_name:match(pat_js) then reduced_name = reduced_name:match(pat_js) end    
            end
          obj.plugs_data[#obj.plugs_data+1] = {name = str, 
                                                reduced_name = reduced_name ,
                                                plugtype = plugtype}
        end
      end
  end  
    ---------------------------------------------------
  function Obj_PluginSearch(conf, obj, data, refresh, mouse)
    if not obj.textbox.active_char then obj.textbox.active_char = 0 end
    Obj_PluginSearch_textbox(conf, obj, data, refresh, mouse)
    if #obj.plugs_data>1 then
      obj.textbox.match_t = {}
      if not obj.textbox.matched_id then obj.textbox.matched_id = 1 end
      Obj_PluginSearch_FormResults(conf, obj, data, refresh, mouse)
    end
  end
  function Obj_PluginSearch_FormResults(conf, obj, data, refresh, mouse)
    if not obj.textbox.text 
      or obj.textbox.text == '' 
      or obj.textbox.text:len() < 2
      then return end
    
    local results_lim = math.floor(obj.fxsearch_h / obj.fxsearch_item_h )-3
    local str_text = obj.textbox.text
    local box_wrds = 0 for word_box in str_text:gmatch('[^%s]+') do box_wrds = box_wrds + 1 end
    for i = 1, #obj.plugs_data do
      local plugname = obj.plugs_data[i].name
      local matched_words = {}
      for word in plugname:gmatch('[^%s]+') do
        for word_box in str_text:gmatch('[^%s]+') do
          if word:lower():match(word_box:lower()) then 
            matched_words[word] = true
          end
        end
      end
      local matched_words_cnt = 0
      for key in pairs(matched_words) do matched_words_cnt = matched_words_cnt + 1 end

      if matched_words_cnt >= box_wrds then
        obj.textbox.match_t[#obj.textbox.match_t+1] = obj.plugs_data[i]
      end
      if #obj.textbox.match_t > results_lim then break end
    end
  end
  ---------------------------------------------------
  function Obj_PluginSearch_textbox(conf, obj, data, refresh, mouse)
    local char = mouse.char
    if not obj.textbox.text then obj.textbox.text = '' end
    --if char ==  1919379572 or char == 1818584692 then return end -- Ctrl+ArrLeft/Right  
    --msg(char)
    if  -- regular input
        (
            (char >= 65 -- a
            and char <= 90) --z
            or (char >= 97 -- a
            and char <= 122) --z
            or ( char >= 212 -- A
            and char <= 223) --Z
            or ( char >= 48 -- 0
            and char <= 57) --Z
            or char == 95 -- _
            or char == 44 -- ,
            or char == 32 -- (space)
            or char == 45 -- (-)
        )
        then        
          obj.textbox.text = obj.textbox.text:sub(0,obj.textbox.active_char)..
            string.char(char)..
            obj.textbox.text:sub(obj.textbox.active_char+1)
          obj.textbox.active_char = obj.textbox.active_char + 1
          obj.textbox.matched_id = 1
      end
      
      if char == 8 then -- backspace
        obj.textbox.text = obj.textbox.text:sub(0,obj.textbox.active_char-1)..
          obj.textbox.text:sub(obj.textbox.active_char+1)
        obj.textbox.active_char = obj.textbox.active_char - 1
        obj.textbox.matched_id = 1
      end
  
      if char == 6579564 then -- delete
        obj.textbox.text = obj.textbox.text:sub(0,obj.textbox.active_char)..
          obj.textbox.text:sub(obj.textbox.active_char+2)
        obj.textbox.active_char = obj.textbox.active_char
        obj.textbox.matched_id = 1
      end
            
      if char == 1818584692 then -- left arrow
        obj.textbox.active_char = obj.textbox.active_char - 1
      end
      
      if char == 1919379572 then -- right arrow
        obj.textbox.active_char = obj.textbox.active_char + 1
      end
    
      if char == 30064 then -- up 
        obj.textbox.matched_id = lim(obj.textbox.matched_id - 1, 1, #obj.textbox.match_t)
        refresh.GUI_minor = true
       elseif char == 1685026670 then --down
        obj.textbox.matched_id = lim(obj.textbox.matched_id + 1, 1, #obj.textbox.match_t)
        refresh.GUI_minor = true
      end
      
    if obj.textbox.active_char < 0 then obj.textbox.active_char = 0 end
    if obj.textbox.active_char > obj.textbox.text:len()  then obj.textbox.active_char = obj.textbox.text:len() end
  end
  ---------------------------------------------------
  function Obj_CascadeFX(conf, obj, data, refresh, mouse, shift_x)
    local casc_y = 0
    local x = obj.trIO_x_offset + obj.fxmod_w +  obj.fx_x_space
    local y = obj.trIO_y
    if shift_x then shift_x = 1 else shift_x = 0 end
    
    for i = 1, #data.fx do   
      local cntpins = math.max(data.fx[i].inpins, data.fx[i].outpins)
      if not data.ext_data[data.GUID][data.fx[i].GUID] then data.ext_data[data.GUID][data.fx[i].GUID] =  {} end
      data.ext_data[data.GUID][data.fx[i].GUID].x = x + (obj.fx_x_space * (i-1))*shift_x
      data.ext_data[data.GUID][data.fx[i].GUID].y = y + casc_y
      casc_y = obj.trIO_h * (cntpins+1) + casc_y
    end
  end
  ---------------------------------------------------
  function OBJ_Update(conf, obj, data, refresh, mouse) 
    for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].clear then obj[key] = {} end end  

    obj.fxsearch_w = 0.4*gfx.w
    obj.fxsearch_h = 0.8*gfx.h
    obj.fxsearch_x = math.floor((gfx.w - obj.fxsearch_w ) / 2) 
    obj.fxsearch_y = math.floor((gfx.h - obj.fxsearch_h ) / 2) 
    obj.menu_y = gfx.h - obj.trIO_h
    if conf.show_info_ontop == 0 then  obj.menu_y = 0 end
    
    
    if not data.tr then return end
        
    Obj_MenuMain(conf, obj, data, refresh, mouse)              
    Obj_InfoLine(conf, obj, data, refresh, mouse)                                
    Obj_FormTrackIO(conf, obj, data, refresh, mouse) 
    Obj_FormTrackIOpins(conf, obj, data, refresh, mouse) 
    Obj_FormFX(conf, obj, data, refresh, mouse) 
    Obj_FormWires(conf, obj, data, refresh, mouse) 
    
    if obj.textbox.enable then
      Obj_PluginSearch(conf, obj, data, refresh, mouse)
    end
    
    for key in pairs(obj) do if type(obj[key]) == 'table' then 
      obj[key].context = key 
    end end    
  end
  -----------------------------------------------
  function Obj_MenuMain(conf, obj, data, refresh, mouse)
            obj.menu = { clear = true,
                        x = 0,
                        y = obj.menu_y,
                        w = obj.menu_w,
                        h = obj.trIO_h,
                        col = 'white',
                        state = fale,
                        txt= 'Menu',
                        show = true,
                        fontsz = obj.GUI_fontsz2,
                        a_frame = 0,
                        func =  function() 
                                  Menu(mouse,               
    {
      { str = conf.mb_title..' '..conf.vrs,
        hidden = true
      },
      { str = '|>Donate / Links / Info'},
      { str = 'Donate to MPL',
        func = function() Open_URL('http://www.paypal.me/donate2mpl') end }  ,
      { str = 'Cockos Forum thread',
        func = function() Open_URL('http://forum.cockos.com/showthread.php?t=209768') end  } , 
      { str = 'ShortCuts/MouseModifiers|',
        func = function()
msg(
[[
Main window
  enter: add FX
  space: transport play/stop
  escape: exit

Selected FX
  delete: remove selected FX
  
Drag wires
  ctrl+drag: add link to further channel

]])        
        end  } ,         
      { str = 'MPL on VK',
        func = function() Open_URL('http://vk.com/mpl57') end  } ,     
      { str = 'MPL on SoundCloud|<|',
        func = function() Open_URL('http://soundcloud.com/mpl57') end  } ,     
        
      { str = '#Options'},    
      { str = 'Snap FX on drag',  
        func =  function() conf.snapFX = math.abs(1-conf.snapFX)  end,
        state = conf.snapFX == 1,
      } , 
      { str = 'Auto route further channel',  
        func =  function() conf.autoroutestereo = math.abs(1-conf.autoroutestereo)  end,
        state = conf.autoroutestereo == 1,
      } , 
      { str = 'Not interested in 3+ track channel outs',  
        func =  function() 
                  conf.reducetrackouts = math.abs(1-conf.reducetrackouts)  
                  refresh.GUI = true
                end,
        state = conf.reducetrackouts == 1,
      } , 
  
      { str = 'Show info line on top',  
        func =  function() 
                  conf.show_info_ontop = math.abs(1-conf.show_info_ontop)  
                  refresh.GUI = true
                end,
        state = conf.show_info_ontop == 0,
      } ,         
      { str = 'Clear pins for newly added plugins',  
        func =  function() 
                  conf.clear_pins_on_add = math.abs(1-conf.clear_pins_on_add)  
                  refresh.GUI = true
                end,
        state = conf.clear_pins_on_add == 1,
      } ,        
      { str = 'Show direct track IO links',  
        func =  function() 
                  conf.show_direct_trackIOlinks = math.abs(1-conf.show_direct_trackIOlinks)  
                  refresh.GUI = true
                end,
        state = conf.show_direct_trackIOlinks == 1,
      } ,       
      { str = 'Show FX track IO links for 3+ channels|',  
        func =  function() 
                  conf.show_FX_trackIOlinks = math.abs(1-conf.show_FX_trackIOlinks)  
                  refresh.GUI = true
                end,
        state = conf.show_FX_trackIOlinks == 1,
      } ,           
      
      
      { str = '>Expert settings'},
      { str = 'Data_BuildRouting_Audio: Clear sends to destination channel from all pins of source FX',  
        func =  function() 
                  conf.clearoutpinschan = math.abs(1-conf.clearoutpinschan)  
                  refresh.GUI = true
                end,
        state = conf.clearoutpinschan == 1,
      } ,       
      { str = 'Data_BuildRouting_Audio: Clear source FX source pin',  
        func =  function() 
                  conf.cleasrcpin = math.abs(1-conf.cleasrcpin)  
                  refresh.GUI = true
                end,
        state = conf.cleasrcpin == 1,
      } ,        
      { str = 'Data_BuildRouting_Audio: Clear dest FX dest pin',  
        func =  function() 
                  conf.cleadestpin = math.abs(1-conf.cleadestpin)  
                  refresh.GUI = true
                end,
        state = conf.cleadestpin == 1,
      } ,    
         
      { str = 'Data_BuildRouting_Audio: drop all 4+ track IO linked connections',  
        func =  function() 
                  conf.prevent_connecting_to_channels = math.abs(1-conf.prevent_connecting_to_channels)  
                  refresh.GUI = true
                end,
        state = conf.prevent_connecting_to_channels == 1,
      } ,
      
      { str = 'Data_BuildRouting_Audio: search for free channels for (FX to FX)',  
        func =  function() 
                  conf.use_free_channel_mode = math.abs(1-conf.use_free_channel_mode)  
                  refresh.GUI = true
                end,
        state = conf.use_free_channel_mode == 1,
      } ,              
            
      
      
      { str = 'Use bezier wires|<|',  
        func =  function() 
                  conf.use_bezier_curves = math.abs(1-conf.use_bezier_curves)  
                  refresh.GUI = true
                end,
        state = conf.use_bezier_curves == 1,
      } , 
      
      
      
      
      
      
      { str = 'Dock '..'MPL '..conf.mb_title..' '..conf.vrs,
        func = function() 
                  if conf.dock > 0 then conf.dock = 0 else conf.dock = 1 end
                  gfx.quit() 
                  gfx.init('MPL '..conf.mb_title..' '..conf.vrs,
                            conf.wind_w, 
                            conf.wind_h, 
                            conf.dock, conf.wind_x, conf.wind_y)
              end ,
        state = conf.dock > 0 },                                                                            
    }
    )
                                  refresh.conf = true 
                                  --refresh.GUI = true
                                  --refresh.GUI_onStart = true
                                  refresh.data = true
                                end}  
  end
  ---------------------------------------------------
  function Obj_Actions(conf, obj, data, refresh, mouse) 
    Menu(mouse,               
    {
    { str = 'Add FX|',
      func = function() 
                Obj_EnumeratePlugins(conf, obj, data, refresh, mouse)
                obj.textbox.enable = true
                obj.textbox.is_replace = false
                refresh.GUI = true 
              end  
    } ,     
   
    { str = 'FX positions: reset/initialize ',
      func = function() 
                data.ext_data[data.GUID] = {}
                Data_Update_ExtState_ProjData_Save (conf, obj, data, refresh, mouse)
                refresh.GUI = true 
              end  
    } ,   
    { str = 'FX positions: cascade ',
      func = function() 
                data.ext_data[data.GUID] = {}
                Obj_CascadeFX(conf, obj, data, refresh, mouse, true)
                Data_Update_ExtState_ProjData_Save (conf, obj, data, refresh, mouse)
                refresh.GUI = true 
              end  
    } ,     
    { str = 'FX positions: align vertically|',
      func = function() 
                data.ext_data[data.GUID] = {}
                Obj_CascadeFX(conf, obj, data, refresh, mouse)
                Data_Update_ExtState_ProjData_Save (conf, obj, data, refresh, mouse)
                refresh.GUI = true 
              end  
    } ,  
    
    { str = 'Clear ALL plugins pins',
      func = function() 
                Undo_BeginBlock()
                for fx_id = 1, #data.fx do
                  for chan = 1, data.trchancnt do
                    for pinI = 1, data.fx[fx_id].inpins do SetPin(data.tr, fx_id, 0, pinI, chan, 0)  end
                    for pinO = 1, data.fx[fx_id].outpins do SetPin(data.tr, fx_id, 1, pinO, chan, 0)  end
                  end
                end
                Undo_EndBlock2(0, 'WiredChain - clear ALL pins', -1 )
                refresh.data = true
                refresh.GUI = true
              end  
    } , 
    { str = 'Clear/Reset ALL plugins pins',
      func = function() 
                Undo_BeginBlock()
                for fx_id = 1, #data.fx do
                  for chan = 1, data.trchancnt do
                    for pinI = 1, data.fx[fx_id].inpins do SetPin(data.tr, fx_id, 0, pinI, chan, 0)  end
                    for pinO = 1, data.fx[fx_id].outpins do SetPin(data.tr, fx_id, 1, pinO, chan, 0)  end
                  end
                  for pinI = 1, data.fx[fx_id].inpins do SetPin(data.tr, fx_id, 0, pinI, pinI, 1)  end
                  for pinO = 1, data.fx[fx_id].outpins do SetPin(data.tr, fx_id, 1, pinO, pinO, 1)  end
                end
                Undo_EndBlock2(0, 'WiredChain - Reset ALL pins', -1 )
                refresh.data = true
                refresh.GUI = true
              end  
    } , 
    { str = 'Clear ALL plugins input pins',
      func = function() 
                Undo_BeginBlock()
                for fx_id = 1, #data.fx do
                  for chan = 1, data.trchancnt do
                    for pinO = 1, data.fx[fx_id].inpins do SetPin(data.tr, fx_id, 0, pinO, chan, 0)  end
                  end
                end
                Undo_EndBlock2(0, 'WiredChain - clear ALL pins', -1 )
                refresh.data = true
                refresh.GUI = true
              end  
    } ,    
    { str = 'Clear ALL plugins output pins|',
      func = function() 
                Undo_BeginBlock()
                for fx_id = 1, #data.fx do
                  for chan = 1, data.trchancnt do
                    for pinO = 1, data.fx[fx_id].outpins do SetPin(data.tr, fx_id, 1, pinO, chan, 0)  end
                  end
                end
                Undo_EndBlock2(0, 'WiredChain - clear ALL pins', -1 )
                refresh.data = true
                refresh.GUI = true
              end  
    } , 
    { str = 'Select offline FX',
      func = function() 
                Obj_ResetSelection(conf, obj, data, refresh, mouse) 
                for fx_id = 1, #data.fx do
                  if data.fx[fx_id].offline then obj['fx_'..fx_id].is_selected = true end
                end
                refresh.GUI_minor = true
              end  
    } , 
    { str = 'Select bypassed FX',
      func = function() 
                Obj_ResetSelection(conf, obj, data, refresh, mouse) 
                for fx_id = 1, #data.fx do
                  if not data.fx[fx_id].enabled then obj['fx_'..fx_id].is_selected = true end
                end
                refresh.GUI_minor = true
              end  
    } 
    })
    
                                  refresh.conf = true 
                                  --refresh.GUI = true
                                  --refresh.GUI_onStart = true
                                  refresh.data = true
  end    
  ---------------------------------------------------  
  function Obj_InfoLine(conf, obj, data, refresh, mouse)  
    obj.undo = { clear = true,
                    x = obj.menu_w + 1,
                    y = obj.menu_y,
                    w = obj.menu_w,
                    h = obj.trIO_h,
                    col = 'white',
                    txt= '<Undo',
                    show = true,
                    fontsz = obj.GUI_fontsz2,
                    a_frame = 0,
                    func =  function() 
                              Action(40029)
                            end
                   }
    obj.redo = { clear = true,
                    x = obj.menu_w*2 + 1,
                    y = obj.menu_y,
                    w = obj.menu_w,
                    h = obj.trIO_h,
                    col = 'white',
                    txt= 'Redo>',
                    show = true,
                    fontsz = obj.GUI_fontsz2,
                    a_frame = 0,
                    func =  function() 
                              Action(40030)
                            end
                   }                   
    obj.trackname_w = (gfx.w - obj.menu_w*3 ) *0.8                       
    obj.trackname = { clear = true,
                    x = obj.menu_w*3+2,
                    y = obj.menu_y,
                    w = obj.trackname_w,
                    h = obj.trIO_h,
                    col = 'white',
                    txt= data.trname,
                    show = true,
                    fontsz = obj.GUI_fontsz,
                    a_frame = 0,
                    func =  function() 
                              conf.struct_xshift = 0 
                              conf.struct_yshift = 0
                              refresh.conf = true 
                            end
                   }    
    
    local infoline_xpos = obj.menu_w*3 + obj.trackname_w 
    local txt = 'X:'..math.floor(-conf.struct_xshift)..'    Y:'..math.floor(-conf.struct_yshift)
    obj.XYpos = { clear = true,
                    x = obj.menu_w*3 + obj.trackname_w + 3,
                    y = obj.menu_y,
                    w = gfx.w-infoline_xpos,
                    h = obj.trIO_h,
                    col = 'white',
                    txt= txt,
                    show = true,
                    fontsz = obj.GUI_fontsz2,
                    a_frame = 0,
                    func =  function() 
                              conf.struct_xshift = 0
                              conf.struct_yshift = 0
                              refresh.conf = true
                              refresh.GUI = true
                            end
                   } 
  end
  ---------------------------------------------------  
  function Obj_MarkConnections(conf, obj, data, refresh, mouse, mark_output) 
    do return end
    for key in pairs(obj) do 
      if type(obj[key]) == 'table' then 
        if mark_output then
          if key:match('_I_') then obj[key].is_marked_pin = true end 
         else
          if key:match('_O_') then obj[key].is_marked_pin = true end 
        end
      end 
    end
  end
  --------------------------------------------------- 
  function Obj_FormTrackIO(conf, obj, data, refresh, mouse) 
    -- default position
      local xFX = obj.trIO_x_offset 
      local yFX = obj.trIO_y      
      if data.ext_data 
        and data.ext_data[data.GUID]
        and data.ext_data[data.GUID][data.GUID..'I'] then
        xFX = data.ext_data[data.GUID][data.GUID..'I'].x
        yFX = data.ext_data[data.GUID][data.GUID..'I'].y
      end
      local cntpins = math.min(data.trchancnt, data.chan_lim)
      local hFX = obj.trIO_h*cntpins-1
      obj['trI'] ={ clear = true,
                    x = xFX + conf.struct_xshift,
                    y = yFX + conf.struct_yshift,
                    w = obj.fxmod_w/2,
                    h = hFX,
                    col = 'white',
                    txt= 'Input',
                    show = true,
                    fontsz = obj.GUI_fontsz3,
                    a_frame =obj.module_a_frame,
                    alpha_back = obj.module_alpha_back,
                    func =  function() 
                              Obj_SelectionClick(conf, obj, data, refresh, mouse, 'trI')
                            end,
                    func_trigCtrl =  function() 
                              obj.trI.is_selected = true
                              refresh.GUI_minor = true
                            end, 
                    func_LD2 =  function()
                                  Obj_MouseDrag(conf, obj, data, refresh, mouse)
                                end,
                    onrelease_L = function()
                                    refresh.conf = true
                                  end,
                    func_R = function()
                                  --Menu(mouse, {})
                              end,
                   } 
    -- default position
      local xFX = gfx.w - obj.trIO_x_offset  - obj.fxmod_w/2
      local yFX = obj.trIO_y      
      if data.ext_data 
        and data.ext_data[data.GUID]
        and data.ext_data[data.GUID][data.GUID..'O'] then
        xFX = data.ext_data[data.GUID][data.GUID..'O'].x
        yFX = data.ext_data[data.GUID][data.GUID..'O'].y
      end
      obj['trO'] ={ clear = true,
                    x = xFX + conf.struct_xshift,
                    y = yFX + conf.struct_yshift,
                    w = obj.fxmod_w/2,
                    h = hFX,
                    col = 'white',
                    txt= 'Output',
                    show = true,
                    fontsz = obj.GUI_fontsz3,
                    a_frame =obj.module_a_frame,
                    alpha_back = obj.module_alpha_back,
                    func =  function() 
                              Obj_SelectionClick(conf, obj, data, refresh, mouse, 'trO')
                            end,
                    func_trigCtrl =  function() 
                              obj.trO.is_selected = true
                              refresh.GUI_minor = true
                            end, 
                    func_LD2 =  function()
                                  Obj_MouseDrag(conf, obj, data, refresh, mouse)
                                end,
                    onrelease_L = function()
                                    refresh.conf = true
                                  end,
                    func_R = function()
                                  --Menu(mouse, {})
                              end,
                   }                    
  end  
  ---------------------------------------------------
  function Obj_MouseDrag(conf, obj, data, refresh, mouse)
                                  if not mouse.drag_obj then return end
                                  for i = 1,#mouse.drag_obj do
                                    local key = mouse.drag_obj[i].context
                                    local newpos_x = mouse.drag_obj[i].x + mouse.dx
                                    local newpos_y = mouse.drag_obj[i].y + mouse.dy
                                        
                                    if conf.snapFX == 1 then
                                      
                                      local snap = obj.trIO_h/2--conf.snap_px
                                      
                                      local multx = math.modf(newpos_x/snap)
                                      newpos_x = snap * multx
                                      local multy = math.modf(newpos_y/snap)
                                      newpos_y = snap * multy
                                    end
                                        
                                    --[[ temporary limits before scroll/middle drag implemented
                                      local lim_edge = 10
                                      newpos_x = lim(newpos_x, lim_edge, gfx.w - mouse.drag_obj[i].w-lim_edge)
                                      newpos_y = lim(newpos_y, obj.trIO_y, gfx.h - mouse.drag_obj[i].h  -  conf.struct_yshift)
                                          ]]
                                      obj[key].x = newpos_x
                                      obj[key].y = newpos_y
                                          
                                      
                                      
                                      if not data.ext_data then data.ext_data = {} end
                                      if not data.ext_data[data.GUID] then data.ext_data[data.GUID] = {} end
                                      
                                      local fxid = key:match('fx_(%d+)')
                                      local ext_key
                                      if key:match('fx_%d+') and fxid then ext_key = data.fx[tonumber(fxid)].GUID 
                                        elseif key == 'trI' then ext_key = data.GUID..'I'
                                        elseif key == 'trO' then ext_key = data.GUID..'O'
                                      end
                                      
                                      if ext_key then 
                                        if not data.ext_data[data.GUID][ext_key] then data.ext_data[data.GUID][ext_key] = {} end
                                        data.ext_data[data.GUID][ext_key].x = newpos_x   -  conf.struct_xshift
                                        data.ext_data[data.GUID][ext_key].y = newpos_y   -  conf.struct_yshift
                                        --refresh.data_proj = true
                                      end
                                  end
                                  Obj_FormTrackIOpins(conf, obj, data, refresh, mouse, true)
                                  
                                  for drag_t = 1,#mouse.drag_obj do
                                    local fxid = mouse.drag_obj[drag_t].context:match('fx_(%d+)')
                                    if fxid and tonumber(fxid) then 
                                      Obj_FormFXPins(conf, obj, data, refresh, mouse, tonumber(fxid), true) 
                                      Obj_FormFXButtons(conf, obj, data, refresh, mouse,tonumber(fxid)) 
                                    end
                                  end
                                  refresh.GUI_minor = true
  end  
  ---------------------------------------------------
  function Obj_FormTrackIOpins(conf, obj, data, refresh, mouse, refresh_pos_only) 
    for i = 1, math.min(data.trchancnt, data.chan_lim) do
      local pkey = 'mod_tr_0_O_'..i
      local xpos = obj.trI.x+obj.trI.w+1
      local ypos = obj.trI.y + (i-1)*obj.trIO_h
      if refresh_pos_only then
        obj[pkey].x = xpos
        obj[pkey].y = ypos
       else
        obj[pkey] ={ clear = true,
                    x = xpos,
                    y = ypos,
                    w = obj.trIO_w,
                    h = obj.trIO_h-1,
                    col = 'white',
                    txt= i,
                    show = true,
                    is_pin = true,
                    pin_dir = 1,
                    pin_type = 1,
                    pin_idx = i,
                    fontsz = obj.GUI_fontsz3,
                    a_frame =obj.module_a_frame,
                    alpha_back = obj.module_alpha_back,
                    func_ctrlLD = function() refresh.GUI_minor = true end,
                    func =  function() 
                              Obj_MarkConnections(conf, obj, data, refresh, mouse, true) 
                              if not obj[pkey].wire then obj[pkey].wire = {} end
                              local temp_t = obj[pkey].wire
                              temp_t[#temp_t+1] = { wiretype = 0, src = pkey, dest = 'mouse'}
                            end ,       
                      func_trigCtrl = 
                              function() 
                                if not obj[pkey].wire then obj[pkey].wire = {} end
                                                                local temp_t = obj[pkey].wire
                                                                temp_t[#temp_t+1] = { wiretype = 0, src = pkey, dest = 'mouse'}
                              end,                                         
                    func_LD =  function() 
                              Obj_MarkConnections(conf, obj, data, refresh, mouse, true) 
                              refresh.GUI_minor = true
                            end,
                      onrelease_L = function() 
                                      Undo_BeginBlock()
                                      local add_next
                                      if mouse.Ctrl_state then add_next = 1 end
                                                Data_BuildRouting(conf, obj, data, refresh, mouse, { routingtype = 0,
                                                                                                    dest = mouse.context_latch,
                                                                                                    src = pkey,
                                                                                                    add_next=add_next})  
                                      Undo_EndBlock2( 0, 'WiredChain - rebuild pins', -1 )   
                                    end     ,
                        func_L_Alt = function() 
                                        for fx_id = 1, #data.fx do 
                                          for pinO = 1, data.fx[fx_id].outpins do
                                            SetPin(data.tr, fx_id, 1, pinO, i, 0)
                                          end
                                        end
                                        refresh.data = true
                                        refresh.GUI = true
                                      end,                             
                      func_mouseover =  function()
                                            if obj.selection_rect then return end
                                          if not obj[pkey].wire then return end
                                          local str = ''
                                          for wire = 1, #obj[pkey].wire do
                                            str = str..obj[pkey].wire[wire].dest..'\n'
                                          end
                                          obj.tooltip = str
                                        end                              
                   }  
      end
      if conf.reducetrackouts == 0 or (i<=2 and conf.reducetrackouts == 1) then
        local pkey = 'mod_tr_0_I_'..i
        obj[pkey] ={ clear = true,
                      x = obj.trO.x-obj.trIO_w-1,
                      y = obj.trO.y + (i-1)*obj.trIO_h,
                      w = obj.trIO_w,
                      h = obj.trIO_h-1,
                      col = 'white',
                      txt= i,
                      show = true,
                      is_pin = true,
                      pin_dir = 0,
                      pin_type = 1,
                      pin_idx = i,
                      fontsz = obj.GUI_fontsz3,
                      a_frame =obj.module_a_frame,
                      alpha_back = obj.module_alpha_back,
                      func_LD = function() refresh.GUI_minor = true end,
                      func =  function() 
                                Obj_MarkConnections(conf, obj, data, refresh, mouse, true) 
                                if not obj[pkey].wire then obj[pkey].wire = {} end
                                local temp_t = obj[pkey].wire
                                temp_t[#temp_t+1] = { wiretype = 0, src = pkey, dest = 'mouse'}
                              end ,         
                      func_trigCtrl = 
                              function() 
                                if not obj[pkey].wire then obj[pkey].wire = {} end
                                local temp_t = obj[pkey].wire
                                temp_t[#temp_t+1] = { wiretype = 0, src = pkey, dest = 'mouse'}
                              end,                                          
                      onrelease_L = function() 
                                      Undo_BeginBlock()
                                      local add_next
                                      if mouse.Ctrl_state then add_next = 1 end
                                                Data_BuildRouting(conf, obj, data, refresh, mouse, { routingtype = 0,
                                                                                                    dest = pkey,
                                                                                                    src = mouse.context_latch,
                                                                                                    add_next=add_next})  
                                      Undo_EndBlock2( 0, 'WiredChain - rebuild pins', -1 )   
                                    end     ,
                        func_L_Alt = function() 
                                        for fx_id = 1, #data.fx do 
                                          for pinO = 1, data.fx[fx_id].outpins do
                                            SetPin(data.tr, fx_id, 1, pinO, i, 0)
                                          end
                                        end
                                        refresh.data = true
                                        refresh.GUI = true
                                      end, 
                        func_mouseover =  function()
                                            if obj.selection_rect then return end
                                            local str = ''
                                            for key in pairs(obj) do if type(obj[key]) == 'table' and obj[key].wire then 
                                              for wire = 1, #obj[key].wire do
                                                if obj[key].wire[wire].dest == pkey then
                                                  str = str..key..'\n'
                                                end
                                              end
                                            end end  
                                            obj.tooltip = str
                                          end ,                                                                                                                                                               
                     }  
        end                  
    end
    obj.trIO_setcntup ={ clear = true,
                  x = obj.trI.x,
                  y = obj.trI.y - obj.trIO_h,
                  w = obj.trIO_w,
                  h = obj.trIO_h,
                  col = 'white',
                  txt= '+',
                  show = true,
                  fontsz = obj.GUI_fontsz3,
                  a_frame = 0,
                  func =  function() 
                            SetMediaTrackInfo_Value( data.tr, 'I_NCHAN', lim(data.trchancnt+2,2,data.chan_lim ))
                            refresh.GUI = true
                            refresh.data = true
                          end
                 } 
    obj.trIO_setcntdown ={ clear = true,
                  x = obj.trI.x+obj.trIO_w+1,
                  y = obj.trI.y - obj.trIO_h,
                  w = obj.trIO_w,
                  h = obj.trIO_h,
                  col = 'white',
                  txt= '-',
                  show = true,
                  fontsz = obj.GUI_fontsz3,
                  a_frame = 0,
                  func =  function() 
                            SetMediaTrackInfo_Value( data.tr, 'I_NCHAN', lim(data.trchancnt-2,2,data.chan_lim ))
                            refresh.GUI = true
                            refresh.data = true
                          end
                 }                  
  end
  ---------------------------------------------------
  function Obj_ResetSelection(conf, obj, data, refresh, mouse) 
    for key in spairs(obj,function(t,a,b) return b < a end) do  if type(obj[key]) == 'table' then obj[key].is_selected = false end end
  end
  ---------------------------------------------------
  function Obj_CountSelectedObjects(conf, obj, data, refresh, mouse) 
    local cnt,id_t = 0, {}
    for key in spairs(obj,function(t,a,b) return b < a end) do  
      if type(obj[key]) == 'table' and obj[key].is_selected == true then 
        cnt = cnt + 1  
        id_t [#id_t+1] = key
      end
    end
    return cnt, id_t
  end  
  ---------------------------------------------------
  function Obj_SelectionClick(conf, obj, data, refresh, mouse, trig_key)
    if obj[trig_key].is_selected then 
      mouse.drag_obj = {}
      local cnt, ids_table = Obj_CountSelectedObjects(conf, obj, data, refresh, mouse)
      for sel_fx = 1, cnt do mouse.drag_obj[#mouse.drag_obj+1] = CopyTable(obj[ids_table[sel_fx] ]) end
     else
      mouse.drag_obj = {CopyTable(obj[trig_key])}
      Obj_ResetSelection(conf, obj, data, refresh, mouse) 
      obj[trig_key].is_selected = true
      refresh.GUI_minor = true
    end
  end 
  ---------------------------------------------------
  function Obj_FormFX(conf, obj, data, refresh, mouse) 
    if not data.fx then return end
    
    -- default position
      local x = obj.trIO_x_offset + obj.fxmod_w + obj.fx_x_space
      local y = obj.trIO_y
    local x_shift = 0
    local y_shift = 0
    for i = 1, #data.fx do
      
      local xFX = x + x_shift
      if xFX +  obj.fxmod_w  > gfx.w then        
        xFX = xFX - x_shift
        x_shift = 0
        y_shift = y_shift + obj.fx_y_space 
      end
      x_shift = x_shift + obj.fx_x_space + obj.fxmod_w
      local yFX = y + obj.fx_y_shift*((i-1)%2) + y_shift
      
      if data.ext_data 
        and data.ext_data[data.GUID]
        and data.ext_data[data.GUID][data.fx[i].GUID] then
        xFX = data.ext_data[data.GUID][data.fx[i].GUID].x
        yFX = data.ext_data[data.GUID][data.fx[i].GUID].y
      end
      local cntpins = math.max(data.fx[i].inpins, data.fx[i].outpins)
      cntpins = math.min(cntpins, data.chan_lim)
      if cntpins < 2 then cntpins = 2 end
      local hFX = obj.trIO_h*cntpins
      obj['fx_'..i] ={ clear = true,
                    x = xFX + conf.struct_xshift,
                    y = yFX + conf.struct_yshift,
                    w = obj.fxmod_w,
                    h = hFX-1,
                    col = 'white',
                    txt= i..'. '..data.fx[i].reducedname,
                    txt_wrap = true,
                    show = true,
                    fontsz = obj.GUI_fontsz3,
                    a_frame =obj.module_a_frame,
                    solidrect_a = 1,
                    func =  function() 
                              Obj_SelectionClick(conf, obj, data, refresh, mouse, 'fx_'..i)
                            end,
                    func_trigCtrl =  function() 
                              obj['fx_'..i].is_selected = true
                              refresh.GUI_minor = true
                            end,     
                    func_trigShift =  function() 
                               cnt, ids_table = Obj_CountSelectedObjects(conf, obj, data, refresh, mouse)
                              if cnt == 0 then
                                obj['fx_'..i].is_selected = true
                                refresh.GUI_minor = true
                               else
                                start_fx = tonumber(ids_table[#ids_table]:match('%d+'))
                                end_fx = tonumber(ids_table[1]:match('%d+'))
                                if i< start_fx or i > end_fx then
                                  for idx = math.min(start_fx, i), math.max(end_fx, i) do
                                    obj['fx_'..idx].is_selected = true
                                  end
                                  refresh.GUI_minor = true
                                end
                                
                              end
                            end,                                                     
                            
                    func_LD2 =  function()
                                  Obj_MouseDrag(conf, obj, data, refresh, mouse)
                                end,
                    onrelease_L = function()
                                    refresh.conf = true
                                  end,
                    func_R = function()
                                  Menu(mouse, {  
                                                { str = 'Float FX|',
                                                  func = function() TrackFX_Show( data.tr, i-1, 3 ) end},
                                                { str = 'Replace FX',
                                                  func = function() 
                                                            Obj_EnumeratePlugins(conf, obj, data, refresh, mouse)
                                                            obj.textbox.enable = true
                                                            obj.textbox.is_replace = i-1
                                                            refresh.GUI = true 
                                                          end  
                                                } ,                                                    
                                                { str = 'Duplicate FX',
                                                  func = function() 
                                                            Undo_BeginBlock()
                                                            MPL_HandleFX( data.tr, i, 0) 
                                                            refresh.data = true
                                                            refresh.GUI = true
                                                            Undo_EndBlock2(0, 'WiredChain - duplicate FX', -1 )
                                                          end}  ,                                                
                                                { str = 'Remove FX|',
                                                  func = function()  
                                                            Undo_BeginBlock()
                                                            MPL_HandleFX( data.tr, i, 1) 
                                                            refresh.data = true
                                                            refresh.GUI = true
                                                            Undo_EndBlock2(0, 'WiredChain - remove FX', -1 )
                                                          end},
                                                { str = 'Clear plugin pins',
                                                  func = function()                                                            
                                                            for chan = 1, data.trchancnt do
                                                              for pinI = 1, data.fx[i].inpins do SetPin(data.tr, i, 0, pinI, chan, 0)  end
                                                              for pinO = 1, data.fx[i].outpins do SetPin(data.tr, i, 1, pinO, chan, 0)  end
                                                            end
                                                            Undo_EndBlock2(0, 'WiredChain - clear  pins', -1 ) 
                                                            refresh.data = true
                                                            refresh.GUI = true
                                                          end },   
                                                { str = 'Clear plugin input pins',
                                                  func = function()                                                            
                                                            for chan = 1, data.trchancnt do
                                                              for pinI = 1, data.fx[i].inpins do SetPin(data.tr, i, 0, pinI, chan, 0)  end
                                                              
                                                            end
                                                            Undo_EndBlock2(0, 'WiredChain - clear in pins', -1 ) 
                                                            refresh.data = true
                                                            refresh.GUI = true
                                                          end },     
                                                { str = 'Clear plugin output pins',
                                                  func = function()                                                            
                                                            for chan = 1, data.trchancnt do
                                                              for pinO = 1, data.fx[i].outpins do SetPin(data.tr, i, 1, pinO, chan, 0)  end
                                                            end
                                                            Undo_EndBlock2(0, 'WiredChain - clear out pins', -1 ) 
                                                            refresh.data = true
                                                            refresh.GUI = true
                                                          end },                                                                                                                     
                                                { str = 'Clear and reset plugin pins',
                                                  func = function()                                                            
                                                            for chan = 1, data.trchancnt do
                                                              for pinI = 1, data.fx[i].inpins do SetPin(data.tr, i, 0, pinI, chan, 0)  end
                                                              for pinO = 1, data.fx[i].outpins do SetPin(data.tr, i, 1, pinO, chan, 0)  end
                                                            end
                                                            for pinI = 1, data.fx[i].inpins do SetPin(data.tr, i, 0, pinI, pinI, 1)  end
                                                            for pinO = 1, data.fx[i].outpins do SetPin(data.tr, i, 1, pinO, pinO, 1)  end
                                                            Undo_EndBlock2(0, 'WiredChain - clear and reset pins', -1 ) 
                                                            refresh.data = true
                                                            refresh.GUI = true
                                                          end },                                                                                                              
                                                })
                              end,
                   } 
      Obj_FormFXPins(conf, obj, data, refresh, mouse, i) 
      Obj_FormFXButtons(conf, obj, data, refresh, mouse, i) 
    end
  end
  ---------------------------------------------------
  function Obj_FormFXButtons(conf, obj, data, refresh, mouse, i)
    if not i or not data.fx[i] then return end
    obj['fx_'..i..'_float'] ={ clear = true,
                  x = obj['fx_'..i].x,
                  y = obj['fx_'..i].y - obj.trIO_h,
                  w = obj.trIO_w,
                  h = obj.trIO_h-1,
                  col = 'white',
                  txt= 'F',
                  is_pin = true,
                  show = true,
                  fontsz = obj.GUI_fontsz3,
                  a_frame =obj.module_a_frame,
                  alpha_back = obj.module_alpha_back,
                  func =  function() 
                            local open = TrackFX_GetOpen( data.tr, i-1 )
                            if open then open = 2 else open = 3 end
                            TrackFX_Show( data.tr, i-1, open )
                          end,  }      
    local byp_a = obj.module_alpha_back
    local alpha_txt = 0.2
    if not data.fx[i].enabled then 
      byp_a = obj.module_alpha_back2 
      alpha_txt = 1
    end
    obj['fx_'..i..'_bypass'] ={ clear = true,
                  x = obj['fx_'..i].x + (obj.trIO_w+1)*2,
                  y = obj['fx_'..i].y - obj.trIO_h,
                  w = obj.trIO_w,
                  h = obj.trIO_h-1,
                  col = 'red',
                  txt= 'M',
                  is_pin = true,
                  show = true,
                  fontsz = obj.GUI_fontsz3,
                  a_frame =obj.module_a_frame,
                  alpha_back = byp_a,
                  alpha_txt = alpha_txt,
                  func =  function() 
                            local state = data.fx[i].enabled
                            TrackFX_SetEnabled(data.tr,i-1, not state)
                            Undo_BeginBlock()
                            local t = {}
                            local cnt, ids_table = Obj_CountSelectedObjects(conf, obj, data, refresh, mouse)
                            for sel_fx = 1, cnt do 
                              local key = ids_table[sel_fx] 
                              local fx_id = key:match('fx_(%d+)')
                              local fx_id = tonumber(fx_id)
                              TrackFX_SetEnabled(data.tr,fx_id-1, not state)
                            end
                            Undo_EndBlock2(0, 'WiredChain - bypass FX', -1 )
                            
                            --refresh.data = true
                            --refresh.GUI_minor = true
                          end,  } 
    local off_a = obj.module_alpha_back
    local off_a_txt = 0.2
    if data.fx[i].offline then 
      off_a = obj.module_alpha_back2 
      off_a_txt = 0.8
    end                          
    obj['fx_'..i..'_offline'] ={ clear = true,
                  x = obj['fx_'..i].x + (obj.trIO_w+1),
                  y = obj['fx_'..i].y - obj.trIO_h,
                  w = obj.trIO_w,
                  h = obj.trIO_h-1,
                  col = 'red',
                  txt= 'O',
                  is_pin = true,
                  show = true,
                  fontsz = obj.GUI_fontsz3,
                  a_frame =obj.module_a_frame,
                  alpha_back = off_a,
                  alpha_txt = off_a_txt,
                  func =  function() 
                            TrackFX_SetOffline(data.tr,i-1, not data.fx[i].offline)
                            refresh.data = true
                            refresh.GUI = true
                          end,  } 
    local sol_a = obj.module_alpha_back
    if data.fx[i].is_solo then 
      sol_a = obj.module_alpha_back2 
    end                          
    obj['fx_'..i..'_solo'] ={ clear = true,
                  x = obj['fx_'..i].x + (obj.trIO_w+1)*3,
                  y = obj['fx_'..i].y - obj.trIO_h,
                  w = obj.trIO_w,
                  h = obj.trIO_h-1,
                  col = 'green',
                  txt= 'S',
                  is_pin = true,
                  show = true,
                  fontsz = obj.GUI_fontsz3,
                  a_frame =obj.module_a_frame,
                  alpha_back = sol_a,
                  func =  function() 
                            local state = data.fx[i].is_solo == true
                            
                            if state then 
                              for i_fx = 1, #data.fx do
                                TrackFX_SetEnabled(data.tr,i_fx-1, true)
                              end
                             else
                              for i_fx = 1, #data.fx do
                                if i_fx ~= i then 
                                  TrackFX_SetEnabled(data.tr,i_fx-1, state)
                                 else
                                  TrackFX_SetEnabled(data.tr,i_fx-1, not state)
                                end
                              end
                            end
                            refresh.data = true
                            refresh.GUI = true
                          end,  }                           
                          
                            
                                                
  end 
  ---------------------------------------------------
  function Obj_FormFXPins(conf, obj, data, refresh, mouse, fx_id, refresh_pos_only)
    if not fx_id or not data.fx[fx_id] then return end
    if data.fx[fx_id].offline then return end
      for inpin = 1,  math.min(data.fx[fx_id].inpins, data.chan_lim) do
        local xpos = obj['fx_'..fx_id].x-obj.trIO_w-1
        local ypos = obj['fx_'..fx_id].y + (inpin-1)*obj.trIO_h
        if refresh_pos_only then
          obj['mod_fx_'..fx_id..'_I_'..inpin].x = xpos
          obj['mod_fx_'..fx_id..'_I_'..inpin].y = ypos
         else
          local pkey = 'mod_fx_'..fx_id..'_I_'..inpin
          obj[pkey] ={ clear = true,
                      x = xpos,
                      y = ypos,
                      w = obj.trIO_w,
                      h = obj.trIO_h-1,
                      col = 'white',
                      txt= inpin,
                      is_pin = true,
                      pin_dir = 0,
                      pin_type = 0,
                      pin_idx = inpin,
                      pin_idxFX = fx_id,
                      show = true,
                      fontsz = obj.GUI_fontsz3,
                      a_frame =obj.module_a_frame,
                      alpha_back = obj.module_alpha_back,
                      func_LD = function() refresh.GUI_minor = true end,
                      func_ctrlLD = function() refresh.GUI_minor = true end,
                      func =  function() 
                                Obj_MarkConnections(conf, obj, data, refresh, mouse) 
                                if not obj[pkey].wire then obj[pkey].wire = {} end
                                local temp_t = obj[pkey].wire
                                temp_t[#temp_t+1] = { wiretype = 0, src = pkey, dest = 'mouse'}
                              end,        
                      func_trigCtrl = 
                              function() 
                                if not obj[pkey].wire then obj[pkey].wire = {} end
                                                                local temp_t = obj[pkey].wire
                                                                temp_t[#temp_t+1] = { wiretype = 0,src = pkey,  dest = 'mouse'}
                              end,                                             
                      func_mouseover =  function()
                                          if obj.selection_rect then return end
                                          local str = ''
                                          for key in pairs(obj) do if type(obj[key]) == 'table' then
                                            if obj[key].wire then 
                                              for wire = 1, #obj[key].wire do
                                                if obj[key].wire[wire].dest == pkey then
                                                  str = str..key..'\n'
                                                end
                                              end
                                            end
                                          end end  
                                          obj.tooltip = str
                                        end ,                              
                      func_L_Alt = function() 
                                      Undo_BeginBlock()
                                      for chan = 1, data.trchancnt do SetPin(data.tr, fx_id, 0, inpin, chan, 0) end
                                      Undo_EndBlock2(0, 'WiredChain - clear pin', -1 )
                                      refresh.data = true
                                      refresh.GUI = true
                                    end,
                      onrelease_L = function()
                                      Undo_BeginBlock()
                                      local add_next
                                      if mouse.Ctrl_state then add_next = 1 end
                                      Data_BuildRouting(conf, obj, data, refresh, mouse, {  routingtype = 0,
                                                                                            dest = pkey,
                                                                                            src = mouse.context_latch,
                                                                                            add_next = add_next,
                                                                                            
                                                                                          })  end ,
                                      Undo_EndBlock2( 0, 'WiredChain - rebuild pins', -1 )
                             
                     }  
        end 
      end   
      
      for outpin = 1,  math.min(data.fx[fx_id].outpins, data.chan_lim) do
        if refresh_pos_only then
          obj['mod_fx_'..fx_id..'_O_'..outpin].x = obj['fx_'..fx_id].x+obj['fx_'..fx_id].w+1
          obj['mod_fx_'..fx_id..'_O_'..outpin].y = obj['fx_'..fx_id].y + (outpin-1)*obj.trIO_h
         else
          local pkey = 'mod_fx_'..fx_id..'_O_'..outpin
          obj[pkey] ={ clear = true,
                      x = obj['fx_'..fx_id].x+obj['fx_'..fx_id].w+1,
                      y = obj['fx_'..fx_id].y + (outpin-1)*obj.trIO_h,
                      w = obj.trIO_w,
                      h = obj.trIO_h-1,
                      col = 'white',
                      is_pin = true,
                      pin_dir = 1,
                      pin_type = 0,
                      pin_idx = outpin,
                      pin_idxFX = fx_id,
                      txt= outpin,
                      show = true,
                      fontsz = obj.GUI_fontsz3,
                      a_frame =obj.module_a_frame,
                      alpha_back = obj.module_alpha_back,
                      func_LD = function() refresh.GUI_minor = true end,
                      func_ctrlLD = function() refresh.GUI_minor = true end,
                      func_L_Alt = function() 
                                      for chan = 1, data.trchancnt do SetPin(data.tr, fx_id, 1, outpin, chan, 0) end
                                      refresh.data = true
                                      refresh.GUI = true
                                    end,                      
                      func =  function() 
                                --Obj_MarkConnections(conf, obj, data, refresh, mouse, true) 
                                if not obj[pkey].wire then obj[pkey].wire = {} end
                                local temp_t = obj[pkey].wire
                                temp_t[#temp_t+1] = { wiretype = 0,src = pkey,  dest = 'mouse'}
                              end,
                      func_trigCtrl = 
                              function() 
                                if not obj[pkey].wire then obj[pkey].wire = {} end
                                                                local temp_t = obj[pkey].wire
                                                                temp_t[#temp_t+1] = { wiretype = 0, src = pkey, dest = 'mouse'}
                              end, 
                      func_mouseover =  function()
                                          if obj.selection_rect then return end
                                          if not obj[pkey].wire then return end
                                          local str = ''
                                          for wire = 1, #obj[pkey].wire do
                                            str = str..obj[pkey].wire[wire].dest..'\n'
                                          end
                                          obj.tooltip = str
                                        end ,
                      onrelease_L = function()
                                      Undo_BeginBlock()
                                      local add_next
                                        if mouse.Ctrl_state then add_next = 1 end
                                      Data_BuildRouting(conf, obj, data, refresh, mouse, {  routingtype = 0,
                                                                                            src = pkey,
                                                                                            dest = mouse.context_latch,
                                                                                            add_next = add_next
                                                                                          })  end ,
                                      Undo_EndBlock2( 0, 'WiredChain - rebuild pins', -1 )                                                                     
                     }   
        end
      end    
  end
  
  
  
  ---------------------------------------------------
  function Obj_FormWires(conf, obj, data, refresh, mouse) 
    Obj_FormWires_trO(conf, obj, data, refresh, mouse) 
    Obj_FormWires_FX(conf, obj, data, refresh, mouse) 
    Obj_FormWires_trI(conf, obj, data, refresh, mouse) 
  end  
  ---------------------------------------------------
  function Obj_FormWires_trO(conf, obj, data, refresh, mouse) 
    -- scan channels from output side
      for chan = 1, math.min(data.trchancnt,data.chan_lim) do
        local channel_bit = 2^(chan-1)
        local has_linked_to_fx = false
        for fx = #data.fx, 1, -1 do
          for pin = 1, #data.fx[fx].pins.O do
            if data.fx[fx].pins.O[pin]  & channel_bit == channel_bit 
              and (conf.show_FX_trackIOlinks == 1 or (conf.show_FX_trackIOlinks == 0 and chan < conf.limit_ch+1) )then            
              if not obj['mod_fx_'..fx..'_O_'..pin].wire then obj['mod_fx_'..fx..'_O_'..pin].wire = {} end
              local temp_t = obj['mod_fx_'..fx..'_O_'..pin].wire
              temp_t[#temp_t+1] =  { wiretype = 0, dest = 'mod_tr_0_I_'..chan}
              has_linked_to_fx = true
            end
          end
          if has_linked_to_fx then break  end          
        end
      end     
  end
  ---------------------------------------------------  
  function Obj_FormWires_FX(conf, obj, data, refresh, mouse) 
    -- scan FX
      for fx_id = #data.fx, 1, -1 do
      
        
        if data.fx[fx_id].pins and data.fx[fx_id].pins.I then
          for pinI = 1, #data.fx[fx_id].pins.I do
            local pinmaskI = data.fx[fx_id].pins.I[pinI]
            for channel = 1, math.min(data.trchancnt,data.chan_lim) do
              local channel_bit = 2^(channel-1)
              if pinmaskI&channel_bit==channel_bit then
                
                
                -- seek something goint to _channel_ before current FX
                local has_send_found = false
                for fx_id_seek = fx_id-1, 1, -1 do
                  for pinO = 1, data.fx[fx_id_seek].outpins do
                    local pinmaskO = data.fx[fx_id_seek].pins.O[pinO]
                    if pinmaskO&channel_bit==channel_bit then
                      if not obj['mod_fx_'..fx_id_seek..'_O_'..pinO].wire then obj['mod_fx_'..fx_id_seek..'_O_'..pinO].wire = {} end
                      local temp_t = obj['mod_fx_'..fx_id_seek..'_O_'..pinO].wire
                      temp_t[#temp_t+1] = { wiretype = 0, dest = 'mod_fx_'..fx_id..'_I_'..pinI, channel = channel}
                      has_send_found =  true
                    end
                  end
                  if has_send_found then break end
                end
                
                if not has_send_found  and 
                  (conf.show_FX_trackIOlinks == 1 or (conf.show_FX_trackIOlinks == 0 and channel < conf.limit_ch+1) )  then 
                  if not obj['mod_tr_0_O_'..channel].wire then obj['mod_tr_0_O_'..channel].wire = {} end
                  local temp_t = obj['mod_tr_0_O_'..channel].wire
                  temp_t[#temp_t+1] =  { wiretype = 0, dest = 'mod_fx_'..fx_id..'_I_'..pinI}                
                end
                
              end
            end
          end
        end
      end  
    end
  ---------------------------------------------------
  function Obj_FormWires_trI(conf, obj, data, refresh, mouse)     
    -- scan channels from input side
      for chan = 1, math.min(data.trchancnt,data.chan_lim) do
        local channel_bit = 2^(chan-1)
        
        --[[local has_linked_to_fx = false
        for fx = #data.fx, 1, -1 do
          for pin = 1, #data.fx[fx].pins.I do
            if data.fx[fx].pins.I[pin] & channel_bit == channel_bit then
              if not obj['mod_tr_0_O_'..chan].wire then obj['mod_tr_0_O_'..chan].wire = {} end
              local temp_t = obj['mod_tr_0_O_'..chan].wire
              temp_t[#temp_t+1] =  { wiretype = 0, dest = 'mod_fx_'..fx..'_I_'..pin}
              has_linked_to_fx = true
            end
          end
          --if has_linked_to_fx then break  end         
        end]]
        
        -- check for skipping chan
        local breakbyFX = false
        for fx = 1, #data.fx do 
          for pin = 1, #data.fx[fx].pins.O do
            if data.fx[fx].pins.O[pin] & channel_bit == channel_bit then breakbyFX = true end
          end
        end
        if not breakbyFX and conf.show_direct_trackIOlinks == 1 then 
          if not obj['mod_tr_0_O_'..chan].wire then obj['mod_tr_0_O_'..chan].wire = {} end
          local temp_t = obj['mod_tr_0_O_'..chan].wire 
          temp_t[#temp_t+1] = { wiretype = 0, dest = 'mod_tr_0_I_'..chan}
        end
      end 
  end    
