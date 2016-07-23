-- @version 1.0
-- @author mpl
-- @changelog
--   + init
-- @description Setup gain/pan/pitch for selected items and item under mouse pointer
-- @website http://forum.cockos.com/member.php?u=70694

  --[[
     * ReaScript Name: Samplitude object mini
     * Lua script for Cockos REAPER
     * Author: Michael Pilyavskiy (mpl)
     * Author URI: http://forum.cockos.com/member.php?u=70694
     * Licence: GPL v3
    ]]
    
    vrs = '1.0'
  --------------------------------------------------
  function msg(s) reaper.ShowConsoleMsg(s) end
  --------------------------------------------------
  
  function DEFINE_val(item)
    local val = {}
    if item ~= nil then
      local take= reaper.GetActiveTake(item)
      val.vol = reaper.GetMediaItemTakeInfo_Value( take, 'D_VOL' )
      val.pan = reaper.GetMediaItemTakeInfo_Value( take, 'D_PAN' )
      val.pitch = reaper.GetMediaItemTakeInfo_Value( take, 'D_PITCH' )
    end
    update_gfx = true
    return val                
        --[[local fx_id = reaper.TakeFX_AddByName( take, 'StereoField' , 1 )        
        val[2] = reaper.TakeFX_GetParamNormalized( take, fx_id, 3 ) 
        val[4] = reaper.TakeFX_GetParamNormalized( take, fx_id, 1 ) ]] 
        --[[  
        D_PLAYRATE 
        B_PPITCH]]
  end
  
  --------------------------------------------------
     
  function SetValues(val, it)
    countselitems =  reaper.CountSelectedMediaItems( 0 )
    for i = 1, countselitems do          
      local sel_item =  reaper.GetSelectedMediaItem( 0, i-1 )
      if sel_item ~= nil then
        local take= reaper.GetActiveTake(sel_item)
        reaper.SetMediaItemTakeInfo_Value( take, 'D_VOL', val.vol )
        reaper.SetMediaItemTakeInfo_Value( take, 'D_PAN', val.pan )
        reaper.SetMediaItemTakeInfo_Value( take, 'D_PITCH', val.pitch )
        reaper.UpdateItemInProject( sel_item )
      end
    end
    update_gfx = true 
  end             
      --[[local fx_id = reaper.TakeFX_AddByName( take, 'StereoField' , 1 )      
      reaper.TakeFX_SetParamNormalized( take, fx_id, 3 , val[2] )   -- pan    
      reaper.TakeFX_SetParamNormalized( take, fx_id, 1 , val[4] )    -- w]]
           --[[  
            D_PLAYRATE 
            B_PPITCH
            ]]
  
  --------------------------------------------------
    
  function Get_Objects()
    local obj = {}
      local w_com = gfx.w
      local h_com = gfx.h
      
      obj.count = 4
      for i  =0, obj.count-1 do
        obj[i+1] = {x = i * w_com  / obj.count,
                          y = 0,
                          w = w_com  / obj.count,
                          h = h_com}
      end
    return obj
  end
  
  --------------------------------------------------
  
  function GUI_knob(obj_t, value, name, trueval, typeknob)
    if not name then name = "" end
    if value == nil then return end
    gfx.set(1,1,1,0.2)
    local offs = 5
    gfx.rect(obj_t.x + offs, 
      obj_t.y + offs,
      obj_t.w - offs*2,
      obj_t.h - offs*2, 0)
    
    local fontsz = 15
    
    
    -- name
      gfx.a = 1
      gfx.setfont(1,"Arial", fontsz)
      gfx.x = obj_t.x + (obj_t.w - gfx.measurestr(name)) / 2
      gfx.y = obj_t.y + obj_t.h - offs* 2-  gfx.texth
      gfx.drawstr(name)

    -- value
      gfx.a = 1
      gfx.setfont(1,"Arial", fontsz)
      gfx.x = obj_t.x + (obj_t.w - gfx.measurestr(value)) / 2
      gfx.y = obj_t.y + (obj_t.h  - gfx.texth)/2
      gfx.drawstr(value)      
      
      
      gr_offs = 60
    -- arc       
      gfx.a = 0.5
      gfx.arc(obj_t.x+ obj_t.w / 2 - 1,
              obj_t.y+ obj_t.h / 2,
              28,
              math.rad(-180 + gr_offs), 
              math.rad(180-gr_offs), 1)
              
    -- val
      if tonumber(trueval) ~= nil then 
        -- 0 - 1
        if typeknob and typeknob == 1 then
          gfx.set(0.8,1,0.8,0.8)      
          gfx.arc(obj_t.x+ obj_t.w / 2 - 1,
                obj_t.y+ obj_t.h / 2,
                24,
                math.rad(-180+gr_offs), 
                math.rad(-180+gr_offs + (360 - gr_offs*2)*trueval ), 1)
        end
        
        -- - 1 +1
        if typeknob and typeknob == 2 then
          gfx.set(0.8,1,0.8,0.8)      
          gfx.arc(obj_t.x+ obj_t.w / 2 - 1,
                obj_t.y+ obj_t.h / 2,
                24,
                math.rad(0), 
                math.rad(180 - gr_offs)*trueval, 1)
        end
      end
  end
  
  --------------------------------------------------  
    
  
  function GUI_butt(obj_t, name)
    if not name then name = "" end
    gfx.set(1,1,1,0.2)
    local offs = 5
    gfx.rect(obj_t.x + offs, 
      obj_t.y + offs,
      obj_t.w - offs*2,
      obj_t.h - offs*2, 0)
    
    gfx.a = 1
    gfx.setfont(1,"Arial", 15)
    gfx.x = obj_t.x + (obj_t.w - gfx.measurestr(name)) / 2
    gfx.y = obj_t.y + ((obj_t.h - offs)- gfx.texth) / 2
    gfx.drawstr(name)
  end
  
  --------------------------------------------------  
  
  function GUI_Draw(obj)
    if update_gfx then    
         --  msg('=============\nDEFINE_GUI_buffers_1-buttons back')  
      gfx.dest = 1
      gfx.setimgdim(1, -1, -1)  
      gfx.setimgdim(1, gfx.w, gfx.h) 
      gfx.set(1,1,1,0.7)
      gfx.rect(0,0,gfx.w, gfx.h, 1)
      
      if item_values and item_values.vol then
        local g_val = (math.floor(20*math.log(item_values.vol, 10) * 100) / 100)..'dB'
        GUI_knob(obj[1], g_val, 'gain', item_values.vol/2, 1)
      end      
      
      -- pan
        local v_pan = "C"
        if item_values.pan < 0 then v_pan = math.floor(item_values.pan*100).."%L" end
        if item_values.pan > 0 then v_pan = math.floor(item_values.pan*100).."%R" end
        GUI_knob(obj[2], v_pan , 'pan', item_values.pan, 2)
        
      -- pitch 
        GUI_knob(obj[3], item_values.pitch, 'pitch')
        
      -- menu 
        GUI_butt(obj[4], 'Menu') 
    end
      --[[ width
        GUI_knob(obj[4], math.floor(values[4] * 200)..'%' , 'width', values[4]*2, 1)      

      --[[ reaeq
        GUI_butt(obj[5], 'ReaEQ')   
      
      
    end ]]
    
    gfx.dest = -1   
    gfx.a = 1
    gfx.x,gfx.y = 0,0
    gfx.blit(1, 1, 0, 
        0,0, gfx.w, gfx.h,
        0,0, gfx.w, gfx.h, 0,0)
        
    update_gfx = false
  end
  
  --------------------------------------------------
  
  function MOUSE_match(b)
    if mouse.mx > b.x and mouse.mx < b.x+b.w
      and mouse.my > b.y and mouse.my < b.y+b.h then
     return true 
    end 
  end 
  
  --------------------------------------------------
  
  function F_limit(val,min,max)
      if val == nil or min == nil or max == nil then return end
      local val_out = val
      if val < min then val_out = min end
      if val > max then val_out = max end
      return val_out
    end 
    
  --------------------------------------------------
    
  function MOUSE_Get(obj)
    local values = DEFINE_val() 
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
    mouse.wheel_res = 4800
    mouse.d_res = 80
    
    if mouse.Ctrl_state then mouse.d_res = 4000 end
    
    if mouse.last_wheel and mouse.last_wheel ~= mouse.wheel then 
      mouse.wheel_diff = mouse.wheel - mouse.last_wheel
      update_gfx = true 
     else
      mouse.wheel_diff = 0 
    end
        
    if mouse.LMB_state and not mouse.last_LMB_state then    
      mouse.last_mx_onclick = mouse.mx
      mouse.last_my_onclick = mouse.my
    end
           
    if mouse.last_mx_onclick ~= nil and mouse.last_my_onclick ~= nil then
      mouse.dx = mouse.mx - mouse.last_mx_onclick
      mouse.dy = mouse.my - mouse.last_my_onclick
     else
      mouse.dx, mouse.dy = 0,0
    end
    
                  
    if not mouse.LMB_state  then mouse.context = nil end    
    if mouse.last_LMB_state and not mouse.LMB_state then 
      update_gfx = true 
      mouse.context  = nil 
    end
    
    mouse.last_mx = 0
    mouse.last_my = 0
    
    
    -- check context on trigger
    
    for i = 1, obj.count do
      if MOUSE_match(obj[i]) 
        and not mouse.last_LMB_state 
        and mouse.LMB_state
       then 
        mouse.context = 'k'..i
      end
    end
    
    -- knobs
      for i = 1, 4 do
        if MOUSE_match(obj[i]) 
          and mouse.LMB_state 
          and not mouse.last_LMB_state 
         then
          mouse.context = 'k'..i
          if i == 1 then mouse.val_on_click = item_values.vol end
          if i == 2 then mouse.val_on_click = item_values.pan end  
          if i == 3 then mouse.val_on_click = item_values.pitch end         
        end
      end
      
      -- gain
        if mouse.LMB_state  and mouse.context == 'k1' then
          item_values.vol = 
            math.floor(F_limit( mouse.val_on_click - mouse.dy/mouse.d_res, 0,2) * 100)/100
          if mouse.Alt_state then item_values.vol = 1 end
          SetValues(item_values)
        end

      -- pan
        if mouse.LMB_state  and mouse.context == 'k2' then
          item_values.pan = 
            math.floor(F_limit( mouse.val_on_click - mouse.dy/mouse.d_res, -1,1) * 100)/100
          if mouse.Alt_state then item_values.pan = 0 end
          SetValues(item_values)
        end

      --pitch
        if mouse.LMB_state  and mouse.context == 'k3' then
          if mouse.Ctrl_LMB_state then
            item_values.pitch = 
              math.floor(F_limit( mouse.val_on_click - mouse.dy/(mouse.d_res*0.2), -24,24) * 100)/100
           else
            _, temp_fr = math.modf(mouse.val_on_click)
            item_values.pitch = 
              --mouse.val_on_click +  math.floor(mouse.val_on_click - mouse.dy/mouse.d_res / 20)
              temp_fr + math.floor(F_limit( mouse.val_on_click - mouse.dy/(mouse.d_res*0.2), -24,24))
          end
          if mouse.Alt_state then item_values.pitch = 0 end
          SetValues(item_values)
        end
      --[[ width
        if mouse.LMB_state  and mouse.context == 'k4' then
          values[4] = 0.5 * math.floor(F_limit( mouse.val_on_click - mouse.dy/mouse.d_res, 0,1) * 100)/100
          if mouse.Alt_state then values[4] = 0.5 end
          SetValues(values, item)
          countselitems =  reaper.CountSelectedMediaItems( 0 )
          for i = 1, countselitems do          
            local sel_item =  reaper.GetSelectedMediaItem( 0, i-1 )
            SetValues(values, sel_item)
          end
        end
    
    -- reaeq
      if MOUSE_match(obj[5])
        and mouse.LMB_state 
        and not mouse.last_LMB_state then
        if item ~= nil then
          local take= reaper.GetActiveTake(item)
          local reaeq_id = reaper.TakeFX_AddByName( take, 'ReaEQ', 1 )
          reaper.TakeFX_Show( take, reaeq_id, 3 )   
        end
      end]]

    -- menu
      if MOUSE_match(obj[4])
        and mouse.LMB_state 
        and not mouse.last_LMB_state then
        GUI_menu()
      end    
      
            
    -- out values
    
    mouse.last_LMB_state = mouse.LMB_state  
    mouse.last_RMB_state = mouse.RMB_state
    mouse.last_MMB_state = mouse.MMB_state 
    mouse.last_Ctrl_LMB_state = mouse.Ctrl_LMB_state
    mouse.last_Ctrl_state = mouse.Ctrl_state
    mouse.last_wheel = mouse.wheel 
  end
 
 --------------------------------------------------
  
 function GetRecFXList() 
   local t = {}
   local file_path = reaper.GetResourcePath()..'/reaper-recentfx.ini'
   local file = io.open(file_path, 'r')
   if file ~= nil then
     local content = file:read('a')
     
     for line in content:gmatch('[^%\r\n]+') do
       local endname_pre = line:find("=")
       if not endname_pre then endname_pre = 0 end
       local out = line:sub(endname_pre+1)
       
       if out:find('[%\\/]') then out = out:sub(1-out:reverse():find('[%\\/]')) end
       if line:find('Name') then 
        t[#t+1] = out:gsub('.dll','')
      end
     end
     file:close()
   end
   return t
 end
 
 --------------------------------------------------
  
  function GUI_menu()local take
    
  -- recent fx
    
    local  recent_t = GetRecFXList() 
    local item_ref = reaper.GetSelectedMediaItem(0,0)
  -----------------------
    if item_ref == nil then return end  
      take= reaper.GetActiveTake(item_ref)
      local fx_count = reaper.TakeFX_GetCount( take )
      if fx_count > 0 then fx_str = "|" else fx_str = "" end
      for i = 1, fx_count do
        local _,  fx_name =  reaper.TakeFX_GetFXName( take, i-1, '' )
        fx_str = fx_str..fx_name..'|'
      end
      
      fx_str = fx_str.."|>RecentFX"
      
      for i = 1, #recent_t do
        fx_str = fx_str..'|'..recent_t[i]
      end
    local is_preserve = reaper.GetMediaItemTakeInfo_Value( take, 'B_PPITCH' )
    if is_preserve ==1 then 
      check = '!' else check = '' end
    
    actions_c = 1
    local  menustr = 
'Render selected items as new take|'
--..check..'Preserve pitch'
..fx_str


    local menuret  = gfx.showmenu(menustr)
    
    if menuret == 1 then
      reaper.Main_OnCommand(41999, 0) -- Render items as new take
    end
    
    --[[if menuret == 2 then
      reaper.SetMediaItemInfo_Value( item, 'B_PPITCH', 1 )
      
    end    ]]
    
    if menuret >= actions_c
+1 and menuret <= fx_count+actions_c then
      reaper.TakeFX_Show( take, menuret - actions_c- 1, 3 )
    end
    
    if menuret >= actions_c
+fx_count and menuret <= fx_count+actions_c + #recent_t 
      then
       local new_id =  reaper.TakeFX_AddByName( take, recent_t[menuret - fx_count+actions_c-actions_c*2], 1 )
       reaper.TakeFX_Show( take, new_id, 3 )
    end
  end
  
  --------------------------------------------------
  
  function run()
    -- check for add to selection 
      cur_selection = reaper.CountSelectedMediaItems( 0 )
      if cur_selection ~= 0 then
      
          exist_in_selection = false
          for i = 1, cur_selection do
            it = reaper.GetSelectedMediaItem(0,i-1)
            it_guid = reaper.BR_GetMediaItemGUID( it )  
            if it_guid == item_ref_guid then exist_in_selection = true break end
          end
          
          if not exist_in_selection then   
            cur_sel_item = reaper.GetSelectedMediaItem(0,0)
            cur_sel_item_guid = reaper.BR_GetMediaItemGUID( cur_sel_item ) 
            item_values = DEFINE_val(cur_sel_item)    
            item_ref_guid = cur_sel_item_guid
           else
            SetValues(item_values)
          end
          
          
          -- check for change single selection 
          cur_sel_item = reaper.GetSelectedMediaItem(0,0)
          cur_sel_item_guid = reaper.BR_GetMediaItemGUID( cur_sel_item )    
          if cur_sel_item_guid ~= item_ref_guid then 
            
            item_values = DEFINE_val(cur_sel_item) 
            item_ref_guid = cur_sel_item_guid
          end
          
      end
    
    
    local obj = Get_Objects()
    GUI_Draw(obj)
    MOUSE_Get(obj)
    
    gfx.update()
    local char = gfx.getchar() 
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end
    if char == 27 then gfx.quit() end     
    if char ~= -1 then reaper.defer(run) else gfx.quit() end
  end
  
  --------------------------------------------------
  
  function main()
    update_gfx = true
    mouse = {}
    reaper.BR_GetMouseCursorContext()
    local item_ref = reaper.GetSelectedMediaItem(0,0)
    sel_items_count_start =  reaper.CountSelectedMediaItems( 0 )
    if item_ref  == nil then return  end
    item_values = DEFINE_val(item_ref)
    item_ref_guid = reaper.BR_GetMediaItemGUID( item_ref )
    mouse_x_pos, mouse_y_pos = reaper.GetMousePosition()
    gfx.init("mpl Samplitude Object mini // vrs "..vrs, 350, 80, 0,mouse_x_pos, mouse_y_pos) --0,0)
    run()
  end
  
  main()
