-- @version 1.01
-- @author mpl
-- @changelog
--   # limit parameters count to first 200 (ex. Spire with 754 params crash Reaper)

--[[
   * ReaScript Name: Randomize Track FX parameters
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
  ]]
  
  
  --------------------------------------------
  --------------------------------------------
  protected_table = {
    "gain", 
    "vol", 
    "on" ,
    "off",
    "wet",
    "dry",
    "oversampling",
    "aliasing",
    "input",
    "power",
    "solo",
    "mute",
    "feed",
    
    "attack",
    "decay",
    "sustain",
    "release",
    
    "bypass",
    "dest",
    "mix",
    "out",
    "make",
    "auto",
    "level",
    "peak",
    "limit",
    "velocity",
    "active",
    "master"
    }
        
        
  ------------------------------------------------------------
  
  function GetObjects()
    local obj = {}
      
      obj.sections = {}
      local num = 5
      for i  =1, num do
        obj.sections[i] = {x = 0 ,
                           y = gfx1.main_h / num * (i-1),
                           w = gfx1.main_w,
                           h = gfx1.main_h / num}
      end
    return obj
  end
  
  -----------------------------------------------------------------------     
  
  function GetGUI_vars()
    gfx.mode = 0
    
    local gui = {}
      gui.aa = 1
      gui.fontname = 'Calibri'
      gui.fontsize_tab = 20    
      gui.fontsz_knob = 18
      if OS == "OSX32" or OS == "OSX64" then gui.fontsize_tab = gui.fontsize_tab - 5 end
      if OS == "OSX32" or OS == "OSX64" then gui.fontsz_knob = gui.fontsz_knob - 5 end
      if OS == "OSX32" or OS == "OSX64" then gui.fontsz_get = gui.fontsz_get - 5 end
      
      gui.color = {['back'] = '71 71 71 ',
                      ['back2'] = '51 63 56',
                      ['black'] = '0 0 0',
                      ['green'] = '102 255 102',
                      ['blue'] = '127 204 255',
                      ['white'] = '255 255 255',
                      ['red'] = '255 70 50',
                      ['green_dark'] = '102 153 102',
                      ['yellow'] = '200 200 0',
                      ['pink'] = '200 150 200',
                    }
    return gui
  end  
  ------------------------------------------------------------
      
  function f_Get_SSV(s)
    if not s then return end
    local t = {}
    for i in s:gmatch("[%d%.]+") do 
      t[#t+1] = tonumber(i) / 255
    end
    gfx.r, gfx.g, gfx.b = t[1], t[2], t[3]
  end
  
  ------------------------------------------------------------
    
  function GUI_text(gui, xywh, text)
        f_Get_SSV(gui.color.white)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob)
        local text_len = gfx.measurestr(text)
        gfx.x, gfx.y = xywh.x+(xywh.w-text_len)/2,xywh.y+(xywh.h-gfx.texth)/2 + 1
        gfx.drawstr(text)
  end
  
  ------------------------------------------------------------
  
  function GUI_draw(obj, gui)
    gfx.mode =4
    if update_gfx then    
      gfx.dest = 1
      gfx.setimgdim(1, -1, -1)  
      gfx.setimgdim(1, gfx1.main_w,gfx1.main_h)  
      -- gradient
        gfx.gradrect(0,0, gfx1.main_w,gfx1.main_h, 1,1,1,0.5, 0,0.001,0,0.0001, 0,0,0,-0.0005)
      -- rects
        gfx.a = 0.05
        f_Get_SSV(gui.color.white) 
        for i = 1, #obj.sections do
          local x,y,w,h = obj.sections[i].x,
                    obj.sections[i].y,
                    obj.sections[i].w,
                    obj.sections[i].h
          gfx.rect (x,y,w,h,0, 1)
        end
        GUI_text(gui, obj.sections[1], '1. Get parameters')
        
      -- gfx defaults
        if def_params ~= nil then
          for i = 1, #def_params do
            gfx.a = 0.4
            f_Get_SSV(gui.color.blue)  
            gfx.rect((i-1)*obj.sections[2].w / #def_params,
             obj.sections[2].y + obj.sections[2].h * (1 - def_params[i]) + 1, 
             obj.sections[2].w / #def_params,
             obj.sections[2].h * def_params[i] -2 )
          end
          GUI_text(gui, obj.sections[2], def_params.fx_name)
        end
      
      -- generate pattern
        GUI_text(gui, obj.sections[3], '2. Generate random pattern')
        
      -- gfx rand
        if rand_params ~= nil then
          for i = 1, #rand_params do
            gfx.a = 0.4
            f_Get_SSV(gui.color.green)  
            gfx.rect((i-1)*obj.sections[4].w / #rand_params,
             obj.sections[4].y + obj.sections[4].h * (1 - rand_params[i]) + 1, 
             obj.sections[4].w / #rand_params,
             obj.sections[4].h * rand_params[i] -2 )
          end
        end      
      
      -- val
       if morph_val ~= nil then 
        GUI_text(gui, obj.sections[5], '3. Morph: '.. math.floor(morph_val*100)..'%' ) 
        f_Get_SSV(gui.color.red) 
        gfx.a = 0.5
        gfx.rect(obj.sections[5].x,
                  obj.sections[5].y,
                  obj.sections[5].w *morph_val ,
                  obj.sections[5].h, 1)
       end
       
    end 
    
    gfx.dest = -1
    gfx.a = 1
    gfx.blit(1, 1, 0, 
      0,0, gfx1.main_w,gfx1.main_h,
      0,0, gfx1.main_w,gfx1.main_h, 0,0)
      
    update_gfx = false
    
  end
  
  ------------------------------------------------------------
  
  function Lokasenna_Window_At_Center (w, h)
    -- thanks to Lokasenna 
    -- http://forum.cockos.com/showpost.php?p=1689028&postcount=15    
    local l, t, r, b = 0, 0, w, h    
    local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)    
    local x, y = (screen_w - w) / 2, (screen_h - h) / 2    
    gfx.init("mpl Randomize Track FX parameters", w, h, 0, x, y)  
  end

 -------------------------------------------------------------     
      
  function F_limit(val,min,max)
      if val == nil or min == nil or max == nil then return end
      local val_out = val
      if val < min then val_out = min end
      if val > max then val_out = max end
      return val_out
    end   
  ------------------------------------------------------------
  
  function MOUSE_slider(b)
    if mouse.mx > b.x and mouse.mx < b.x+b.w
      --and mouse.my > b.y and mouse.my < b.y+b.h 
      and mouse.LB then
     return math.floor(100*(mouse.mx-40) / (b.w-80))/100
    end 
  end
    
  function MOUSE_click(b)
    if mouse.mx > b.x and mouse.mx < b.x+b.w
      and mouse.my > b.y and mouse.my < b.y+b.h 
      and mouse.LB 
      and not mouse.last_LB then
     return true 
    end 
  end
  
  ------------------------------------------------------------
    
  function ENGINE_GetParams()
    local params = {}
     
    local retval, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    local track = reaper.GetTrack(0, tracknumberOut-1)
    if track == nil then return end
    params.fxnumberOut = fxnumberOut
    params.guid =   reaper.TrackFX_GetFXGUID( track, params.fxnumberOut )
    params.tracknumberOut = tracknumberOut
    _, params.fx_name =  reaper.TrackFX_GetFXName( track, params.fxnumberOut, '' )
    if retval ~= 1 or tracknumberOut <= 0 or params.fxnumberOut == nil then return end    
    local num_params = reaper.TrackFX_GetNumParams( track, params.fxnumberOut )
    if not num_params or num_params == 0 then return end    
    for i = 1, num_params do 
      params[i] =  reaper.TrackFX_GetParam( track, params.fxnumberOut, i ) 
    end
    return params
  end
  
  ------------------------------------------------------------
  
  function ENGINE_SetParams()
    if def_params == nil then return end
    if rand_params == nil then return end
    if morph_val == nil then return end
    
    local retval, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    track = reaper.GetTrack(0,tracknumberOut-1)
    _, fx_name =  reaper.TrackFX_GetFXName( track, fxnumberOut, '' )
    guid =    reaper.TrackFX_GetFXGUID( track, fxnumberOut )
    if def_params.tracknumberOut == tracknumberOut
      and def_params.guid == guid
      and def_params.fx_name == fx_name 
      and tracknumberOut > 0 
      and track ~= nil then
        
       max_params_count = 200
        for i = 1, math.min(#def_params, max_params_count) do
          _, par_name = reaper.TrackFX_GetParamName( track, fxnumberOut, i, '' )
          protect = false
          for j = 1, #protected_table do
            if par_name:lower():find(protected_table[j])~=nil then
              protect = true
            end
          end
          if not protect then
            reaper.TrackFX_SetParamNormalized( track, fxnumberOut, i, 
            def_params[i] + (rand_params[i] - def_params[i]) * morph_val
            )
          end
        end
        
    end
  end 
  
  ------------------------------------------------------------
  
  function ENGINE_GenerateRandPatt()
    if def_params ~= nil then 
      local rand = {}
      for i = 1, #def_params do
        rand[i] = math.random()
      end
      return rand
    end
  end
  
  ------------------------------------------------------------
    
  function run()  
    local obj = GetObjects()
    local gui = GetGUI_vars()
    GUI_draw(obj, gui)
    
    mouse.mx, mouse.my = gfx.mouse_x, gfx.mouse_y  
    mouse.LB = gfx.mouse_cap&1==1 
    
    -- get params
      if MOUSE_click(obj.sections[1]) then 
        def_params = ENGINE_GetParams() 
        update_gfx = true 
      end
    
    -- gen pattern
      if MOUSE_click(obj.sections[3]) then 
        rand_params = ENGINE_GenerateRandPatt() 
        update_gfx = true 
      end
      
    -- morph
      if MOUSE_click(obj.sections[5]) then mouse.context = 'slider' end
      if mouse.context and mouse.context == 'slider' then
         morph_val = F_limit(MOUSE_slider(obj.sections[5]),0,1)
         ENGINE_SetParams()
         update_gfx = true 
      end      
    
    if not mouse.LB then mouse.context = nil end
    local char = gfx.getchar() 
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end
    if char == 27 then gfx.quit() end     
    if char ~= -1 then reaper.defer(run) else gfx.quit() end
    gfx.update()
    mouse.last_LB = mouse.LB
    
    if morph_val ~= nil then
      last_morph_val = morph_val
     else
      morph_val = last_morph_val
    end
    
    
  end
  
  ------------------------------------------------------------
  update_gfx = true
  gfx1 = {main_w = 500, main_h = 200}  
  Lokasenna_Window_At_Center(gfx1.main_w,gfx1.main_h) 
  mouse = {}
  run()
  reaper.atexit(gfx.quit)
  
  ------------------------------------------------------------
