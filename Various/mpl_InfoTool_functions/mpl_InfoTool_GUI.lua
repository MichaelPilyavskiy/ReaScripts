-- @description InfoTool_GUI
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  -- GUI functions for mpl_InfoTool 
  -- common objects functions for mpl_InfoTool
  
  
  
  ---------------------------------------------------
  function Obj_init(conf)  
    local obj = {       aa = 1,
                  mode = 0,
                  
                  font = 'Calibri',
                  fontsz = conf.GUI_font1,
                  fontsz_entry = conf.GUI_font2,
                  col = { grey =    {0.5, 0.5,  0.5 },
                          white =   {1,   1,    1   },
                          red =     {1,   0,    0   },
                          green =   {0.3, 0.9,  0.3 },
                          greendark =   {0.2, 0.4,  0.2 },
                          blue  =   {0.5, 0.9,  1}},
                  background_col = conf.GUI_background_col,
                  background_alpha = conf.GUI_background_alpha,
                  
                  txt_a = 0.85,
                  txt_col_header = conf.GUI_colortitle,
                  txt_col_toolbar ='white', 
                  
                  grad_sz = 200,
                  b = {},             -- buttons table
                  
                  mouse_scal_time = 15,
                  mouse_scal_vol = 5,
                  mouse_scal_pitch = 15,
                  mouse_scal_pan = 1,
                  
                  entry_w = 200,      -- name w
                  entry_w2 = 90,     -- controls w / position
                  entry_ratio = 1,    -- toolbar
                  entry_h = 18,
                  menu_b_rect_side = 20,
                  offs = 0,
                  offs2 = 2,
                  frame_a_head = 1.3, -- alpha header frames
                  frame_a_entry = 0.95,   -- alpha entries frames
                  frame_a_state = 0.8 -- active state
          }
    if GetOS():match('OSX') then 
      obj.fontsz = obj.fontsz - 5
      obj.fontsz_entry = obj.fontsz_entry - 5
    end
    return obj             
  end
  
  
  ---------------------------------------------------
  function Obj_UpdateCom(data, mouse, obj, widgets, conf)
    local main_type_frame_a
    if data.obj_type_int and data.obj_type_int >=0 then main_type_frame_a = obj.frame_a_head else main_type_frame_a = 0 end
    obj.b.type_name = { x = obj.menu_b_rect_side + obj.offs,
                        y = obj.offs,
                        w = obj.entry_w,
                        h = obj.entry_h,
                        frame_a = main_type_frame_a,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt =data.obj_type}
    obj.b.menu = { x = obj.offs,
                        y = obj.offs,
                        w = obj.menu_b_rect_side,
                        h = obj.entry_h*2,
                        frame_a = obj.frame_a_head,
                        txt_a = obj.txt_a,
                        txt_col = obj.txt_col_header,
                        txt = '>',
                        func =  function()
                                  Menu2_Settings(mouse, obj, widgets, conf, data)
                                end}                        
  end 
  
  
    
    ---------------------------------------------------
  function GUI_DrawObj(o, obj)
    if not o then return end
    local x,y,w,h = o.x, o.y, o.w, o.h
    if not x or not y or not w or not h then return end
    
    
    -- glass back
      gfx.a = o.frame_a
      gfx.blit( 2, 1, math.rad(180), -- grad back
                0,0,  obj.grad_sz,obj.grad_sz,
                x,y,w,h, 0,0)
                
    -- fr rect
      if o.frame_rect_a then
        gfx.set(1,1,1,o.frame_rect_a)
        gfx.rect(x+1,y+1,w-2,h-2,0)
      end
      
    -- state
      if o.state then
        if o.state_col then GUI_col(o.state_col, obj) end
        gfx.a = 0.49
        gfx.rect(x,y,w,h,1)        
      end
    
    -- text 
      local txt
      if not o.txt then txt = '' else txt = tostring(o.txt) end
      --if not o.txt then txt = '>' else txt = o.txt..'|' end
      ------------------ txt
        if txt and w > 0 then 
          if o.txt_col then GUI_col(o.txt_col, obj)else GUI_col('white', obj) end
          if o.txt_a then gfx.a = o.txt_a else gfx.a = 0.8 end
          gfx.setfont(1, obj.font, o.fontsz or obj.fontsz )
          local shift = 5
          local cnt = 0
          for line in txt:gmatch('[^\r\n]+') do cnt = cnt + 1 end
          local com_texth = gfx.texth*cnt
          local i = 0
          for line in txt:gmatch('[^\r\n]+') do
            if gfx.measurestr(line:sub(2)) > w -2 and w > 20 then 
              repeat line = line:sub(2) until gfx.measurestr(line..'...') < w -2
              line = '...'..line
            end
            gfx.x = x+ math.ceil((w-gfx.measurestr(line))/2)
            gfx.y = y+ h/2 - com_texth/2 + i*gfx.texth
            if o.aligh_txt then
              if o.aligh_txt&1==1 then gfx.x = x + shift  end -- align left
              if o.aligh_txt&2==2 then gfx.y = y + i*gfx.texth end -- align top
              if o.aligh_txt&4==4 then gfx.y = h - com_texth+ i*gfx.texth-shift end -- align bot
              if o.aligh_txt&8==8 then gfx.x = x + w - gfx.measurestr(line) - shift end -- align right
            end
            gfx.drawstr(line)
            --shift = shift + gfx.texth
            i = i + 1
          end
        end                
              
  end
  ---------------------------------------------------
  function GUI_col(col_s, obj) 
    if type(col_s) == 'string' then 
      if obj and obj.col and col_s and obj.col[col_s] then 
        gfx.set( table.unpack(obj.col[col_s]))  
      end   
     else
      local rOut, gOut, bOut = ColorFromNative(col_s)
      gfx.set(rOut/255, gOut/255, bOut/255)
      if GetOS():match('OSX') then gfx.set(bOut/255, gOut/255, rOut/255) end
    end
  end
  ---------------------------------------------------
  function GUI_Main(obj, cycle_cnt, redraw, data)
    gfx.mode = 0
    -- redraw: -1 init, 1 maj changes, 2 minor changes
    -- 1 back
    -- 2 gradient
    
    -- init grad buf on first loop
      if cycle_cnt == 1 then redraw = -1 end
    
    --  init
      if redraw == -1  then
        gfx.dest = 2
        gfx.setimgdim(2, -1, -1)  
        gfx.setimgdim(2, obj.grad_sz,obj.grad_sz)  
        local r,g,b,a = 0.9,0.9,1,0.58
        gfx.x, gfx.y = 0,0
        local c = 1
        local drdx = c*0.00001
        local drdy = c*0.00001
        local dgdx = c*0.00008
        local dgdy = c*0.0001    
        local dbdx = c*0.00008
        local dbdy = c*0.00001
        local dadx = c*0.00003
        local dady = c*0.0004       
        gfx.gradrect(0,0, obj.grad_sz,obj.grad_sz, 
                        r,g,b,a, 
                        drdx, dgdx, dbdx, dadx, 
                        drdy, dgdy, dbdy, dady) 
        redraw = 1 -- force com redraw after init 
      end
      
    -- refresh
      if redraw == 1 then 
        -- refresh backgroung
          gfx.dest = 1
          gfx.setimgdim(1, -1, -1)  
          gfx.setimgdim(1, gfx.w, gfx.h) 
          --gfx.line(gfx.w-obj.menu_w, 0,gfx.w-obj.menu_w, gfx.h )
        -- refresh all buttons
          if obj.b then for key in pairs(obj.b) do GUI_DrawObj(obj.b[key], obj) end end
      end
      
      gfx.dest = -1   
    ----  render    
      
      gfx.a = 1
    --  backgr
      --gfx.set(1,1,1,0.18)
      GUI_col(obj.background_col)
      gfx.a = obj.background_alpha
      gfx.rect(0,0,gfx.w,gfx.h, 1)
      --[[gfx.blit(2, 1, 0, -- backgr
          0,0,obj.grad_sz, obj.grad_sz,
          0,0,gfx.w, gfx.h, 0,0)]]
    -- butts  
      gfx.a  =1 
      gfx.blit(1, 1, 0,
          0,0,gfx.w, gfx.h,
          0,0,gfx.w, gfx.h, 0,0)  
          
    -- draw vrs
      gfx.x, gfx.y = gfx.w-150,0
      gfx.set(0,0,0,1)
      gfx.setfont(1,'Arial', 13)
      gfx.set(1,1,1,0.5)
      gfx.rect(gfx.w-150,0,150, 10)
      gfx.set(0,0,0,1)
      gfx.drawstr('MPL_InfoTool '..data.vrs)
      
    gfx.update()
  end
  
  -----------------------------------------------------------------------
  function Menu2_Settings(mouse, obj, widgets, conf, data)
    -- form t
    local t = { { str = 'MPL InfoTool v'..data.vrs,
                  hidden = true},
                { str = '|>Links / Info|Donate to MPL',
                  func = function() F_open_URL('http://www.paypal.me/donate2mpl') end }  ,
                { str = 'Cockos Forum thread|<',
                  func = function() F_open_URL('http://forum.cockos.com/showthread.php?p=1953498') end  } ,  
                { str = '>Theme|Font size',
                  func = function() 
                            local ret, ftsz = GetUserInputs( conf.scr_title, 2, 'Font 1,Font 2', conf.GUI_font1..','..conf.GUI_font2 )
                            if not ret then return end
                            
                            local f_sz = {}
                            for num in ftsz:gmatch('[^%,]+') do f_sz[#f_sz+1] = tonumber(num) end
                            
                            -- set font1 
                              if f_sz[1] then 
                                conf.GUI_font1 = f_sz[1]
                                ExtState_Save(conf)
                                local temp_t = Obj_init(conf)
                                obj.fontsz = temp_t.fontsz
                                redraw = 2
                              end

                            -- set font2
                              if f_sz[2] then 
                                conf.GUI_font2 = f_sz[2]
                                ExtState_Save(conf)
                                local temp_t = Obj_init(conf)
                                obj.fontsz_entry = temp_t.fontsz_entry
                                redraw = 2
                              end
                                                            
                          end },
                { str = 'Text color (titles)',
                  func = function()                           
                            local retval, colorOut  = GR_SelectColor(  ) 
                            if  retval ~= 0 then
                                if GetOS():match('OSX') then
                                  local r, g, b = ColorFromNative(colorOut)
                                  colorOut = ColorToNative( b, g, r )
                                end
                                
                                conf.GUI_colortitle = colorOut
                                ExtState_Save(conf)
                                local temp_t = Obj_init(conf)
                                obj.txt_col_header = temp_t.txt_col_header
                                redraw = 2                            
                            end
                          end} , 
                { str = 'Background color',
                  func = function()                           
                            local retval, colorOut  = GR_SelectColor(  ) 
                            if  retval ~= 0 then
                                conf.GUI_background_col = colorOut
                                ExtState_Save(conf)
                                local temp_t = Obj_init(conf)
                                obj.background_col = temp_t.background_col
                                redraw = 2                            
                            end
                          end}    ,
                { str = 'Background alpha|<',
                  func = function()                           
                            local ret, ftsz = GetUserInputs( conf.scr_title, 1, 'Background alpha',conf.GUI_background_alpha )
                            if  ret and tonumber(ftsz) then
                                conf.GUI_background_alpha = lim(tonumber(ftsz), 0, 2)
                                ExtState_Save(conf)
                                local temp_t = Obj_init(conf)
                                obj.background_alpha = temp_t.background_alpha
                                redraw = 2                            
                            end
                          end}  ,
                          
                { str = '|#Contexts'}  ,

                { str = '>Empty item|Change order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 1 ) end} ,  
                
                { str = '>MIDI item|Modules order',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 2 ) end} ,
                { str = 'Buttons order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 2, true ) end} ,    
                                
                { str = '>Audio item|Modules order',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 3 ) end} ,
                { str = 'Buttons order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 3, true ) end} ,                      
                  
                { str = '>Multiple items|Modules order',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 4 ) end} ,
                { str = 'Buttons order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 4, true ) end} ,                      
                  
                { str = '>Envelope point|Modules order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 5 ) end} ,                  
                  
                { str = '>Multiple envelope points|Modules order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 6 ) end} ,                      

                { str = '>Selected envelope|Modules order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 7 ) end} , 
                                                                                                                                       
                { str = '>Persistent modules|Modules order|<',
                  func = function() Menu_ChangeOrder(widgets, data, conf, 'Persist' ) end} ,                                                                  
                                                                                                      
                {str = '|#Widget configuration'},
                {str = 'Reset',
                 func = function()  
                          local ret = MB('Are you sure you want to reset widget configuration of MPL InfoTool?',  'MPL InfoTool', 4)
                          if ret == 6 then 
                            Config_Reset(data.conf_path) 
                            MB('Restart script to affect changes', 'MPL InfoTool', 0)
                          end
                        end
                            }  ,                               
                {str = 'Help',
                 func = function()  
ClearConsole()                 
msg(
[[  Here is the default configuration contains all supported widgets tags for MPL`s InfoTool.
  You can edit them via menu (recommended) or in /REAPER/Scripts/mpl_InfoTool_functions/mpl_InfoTool_Config.ini
  Buttons tags are added to the buttons module interleaved.
  After changing configuration, you need to restart script. If you do it from Action List, click 'Terminate Instances' when REAPER will ask for what to do with already running ReaScript.
  
  =================== START HERE ====================
  
  ]]..Config_DefaultStr()..
  
[[  =================== END HERE ====================]] )  
                 
                        end   
                }  ,
                {str = 'Edit manually',
                 func = function()  F_open_URL('"" "'..data.conf_path..'"') end}  , 
                {str = '|Close MPL InfoTool',
                 func = function() force_exit = true end} ,                   
                        
                        
                                                                                                                                                           
              }
    Menu(mouse, t)
  end
  
  function Menu_ChangeOrder(widgets, data, conf, widgtype, is_buttons )
    local cur_str = ''
    local key
    if tonumber(widgtype) and tonumber(widgtype) >= 1 then key = widgets.types_t[widgtype] else key = widgtype end
    
    if is_buttons then 
      if not widgets[key].buttons then return end
      for i = 1, #widgets[key].buttons do cur_str = cur_str..'#'..widgets[key].buttons[i]..' ' end 
     else 
      for i = 1, #widgets[key] do cur_str = cur_str..'#'..widgets[key][i]..' ' end
    end
    
    local key_show
    if is_buttons then key_show = key..' buttons' else  key_show = key   end
    
    local ret, retorder = GetUserInputs( conf.scr_title, 1, key_show..' context,extrawidth=500',cur_str ) 
    if ret then 
      if is_buttons then widgets[key].buttons = {} else widgets[key] = {} end
      for val in retorder:gmatch('#(%a+)') do widgets[key] [#widgets[key] + 1 ] =val end 
      if is_buttons then  for val in retorder:gmatch('#(%a+)') do widgets[key].buttons [#widgets[key].buttons + 1 ] =val end  end
      redraw = 2
      Config_DumpIni(widgets, data.conf_path) 
    end
  end
