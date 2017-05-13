-- @version 1.0
-- @author mpl
-- @changelog
--   init release

--[[
   * ReaScript Name: Randomize stretch markers
   * Lua script for Cockos REAPER
   * Author: MPL
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
  ]]
  
  
--[[ changelog
    - 1.0 / 28.07.2016
      + init release
]]
  
        
  ------------------------------------------------------------
  
  function GetObjects()
    local obj = {}
      
      obj.sections = {}
      local num = 3
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
    --gfx.rect(xywh.x,xywh.y, xywh.w, xywh.h)
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
      if takes and #takes > 0 then
        GUI_text(gui, obj.sections[1], 'Get take ('..#takes..' stored)')
       else
        GUI_text(gui, obj.sections[1], 'Get take')
      end
      
      -- val      
       if morph_val2 ~= nil then 
        GUI_text(gui, obj.sections[2], 'Add stretch markers' ) 
        f_Get_SSV(gui.color.green) 
        gfx.a = 0.5
        gfx.rect(obj.sections[2].x,
                  obj.sections[2].y,
                  obj.sections[2].w *morph_val2 ,
                  obj.sections[2].h, 1)
        else 
         GUI_text(gui, obj.sections[2], 'Add stretch markers')
       end
        
      -- val      
       if morph_val ~= nil then 
        GUI_text(gui, obj.sections[3], 'Randomize positions: '.. math.floor(morph_val*100)..'%' ) 
        f_Get_SSV(gui.color.red) 
        gfx.a = 0.5
        gfx.rect(obj.sections[3].x,
                  obj.sections[3].y,
                  obj.sections[3].w *morph_val ,
                  obj.sections[3].h, 1)
        else 
         GUI_text(gui, obj.sections[3], 'Randomize positions')
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
    gfx.init("mpl Randomize stretch markers", w, h, 0, x, y) 
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
  function ENGINE_GetTakeTable()
    takes = {}
    for i = 1,  reaper.CountSelectedMediaItems( 0 ) do
      item =  reaper.GetSelectedMediaItem( 0, i-1 )
      if item then
        take =  reaper.GetActiveTake( item )
        if take and not reaper.TakeIsMIDI( take ) then
          takes[#takes+1] = { guid = reaper.BR_GetMediaItemTakeGUID( take ),  str_m = {} }            
          for j = 1, reaper.GetTakeNumStretchMarkers( take ) do
            retval, posOut, srcpos = reaper.GetTakeStretchMarker( take, j -1 )
            if retval then table.insert(takes[#takes].str_m, {posOut = posOut, srcpos = srcpos}) end
          end
        end
      end
    end
  end
  ------------------------------------------------------------
  function ENGINE_AddMarkers()
    if not takes or #takes == 0 then return end
    if not morph_val2 then return end
    for i = 1, #takes do
      local take_g =  reaper.GetMediaItemTakeByGUID( 0, takes[i].guid )
      local tk_item =  reaper.GetMediaItemTake_Item( take_g )
      local it_len =  reaper.GetMediaItemInfo_Value( tk_item, 'D_LENGTH' )
      max_cnt = 100
      reaper.DeleteTakeStretchMarkers( take_g, 0,  reaper.GetTakeNumStretchMarkers( take_g ) )
      for j = 1, math.floor(morph_val2 * max_cnt) do
        reaper.SetTakeStretchMarker( take_g, -1, math.random() * it_len)
      end
    end
    reaper.UpdateArrange()
  end
  ------------------------------------------------------------
  function ENGINE_RandPos()
    if not takes or #takes == 0 then return end
    for i = 1, #takes do
      local take_g =  reaper.GetMediaItemTakeByGUID( 0, takes[i].guid )
      if take_g and morph_val ~= nil then
        for j = 1, #takes[i].str_m do
          rand_num = ((math.random() - 0.5) * 1)    *    morph_val*0.3
          reaper.SetTakeStretchMarker( take_g, j, takes[i].str_m[j].posOut + rand_num, takes[i].str_m[j].srcpos )
        end
      end
      reaper.UpdateArrange()
    end
  end
  ------------------------------------------------------------  
  function run()  
    local obj = GetObjects()
    local gui = GetGUI_vars()
    
    GUI_draw(obj, gui)
    
    mouse.mx, mouse.my = gfx.mouse_x, gfx.mouse_y  
    mouse.LB = gfx.mouse_cap&1==1 
    
    if MOUSE_click(obj.sections[1]) then ENGINE_GetTakeTable() update_gfx = true end
      
    
    -- add slider
      if MOUSE_click(obj.sections[2]) then mouse.context = 'slider1' end
      if mouse.context and mouse.context == 'slider1' and mouse.LB then
         morph_val2 = F_limit(MOUSE_slider(obj.sections[2]),0,1)
         ENGINE_AddMarkers()
         update_gfx = true 
      end 
            
    -- rand slider
      if MOUSE_click(obj.sections[3]) then mouse.context = 'slider2' end
      if mouse.context and mouse.context == 'slider2' and mouse.LB then
         morph_val = F_limit(MOUSE_slider(obj.sections[3]),0,1)
         ENGINE_RandPos()
         update_gfx = true 
      end      
    
    if not mouse.LB then mouse.context = nil end
    local char = gfx.getchar() 
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end
    if char == 27 then gfx.quit() end     
    if char ~= -1 then reaper.defer(run) else gfx.quit() end
    gfx.update()
    mouse.last_LB = mouse.LB
    
  end
  
  ------------------------------------------------------------
  update_gfx = true
  pick_state = false
  gfx1 = {main_w = 300, main_h = 100}  
  Lokasenna_Window_At_Center(gfx1.main_w,gfx1.main_h) 
  mouse = {}
  run()
  reaper.atexit(gfx.quit)
  
  ------------------------------------------------------------
