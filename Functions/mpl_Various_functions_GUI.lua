-- @description Various_functions_GUI
-- @author MPL
-- @noindex
  
---------------------------------------------------
  function VF_GUI_draw(MOUSEt,OBJ,DATA)
    -- 1 Back main
    -- 2 Back button
    -- 3 Buttons
    -- 4 Dynamic stuff major 
    -- 5 Dynamic stuff minor
    
    -- major GUI update
      if DATA.refresh.GUI&1==1 then 
        VF_GUI_DrawBackground(MOUSEt,OBJ,DATA) 
        VF_GUI_DrawBackgroundButton(MOUSEt,OBJ,DATA)
      end 
    
    -- redraw buttons
      if   DATA.refresh.GUI&1==1 
        or DATA.refresh.GUI&2==2 
        or DATA.refresh.GUI&4==4 
        then 
        gfx.dest = 3
        gfx.setimgdim(3, -1, -1)  
        gfx.setimgdim(3, gfx.w,gfx.h)  
        for key in pairs(OBJ) do VF_GUI_DrawButton(MOUSEt,OBJ,DATA, OBJ[key]) end
      end
    
    -- render layers 
      gfx.mode = 1
      gfx.set(1,1,1,1)
      gfx.dest = -1   
      gfx.a = 1
      gfx.x,gfx.y = 0,0
      gfx.blit(1, 1, 0, 
            0,0,DATA.GUIvars.grad_sz, DATA.GUIvars.grad_sz,
            0,0,gfx.w, gfx.h, 0,0) 
      --[[gfx.blit(2, 1, 0,
            0,0,OBJ.grad_sz, OBJ.grad_sz,
            0,0,gfx.w, gfx.h, 0,0)  ]]         
      gfx.blit(3, 1, 0,
            0,0,gfx.w, gfx.h,
            0,0,gfx.w, gfx.h, 0,0)   
      gfx.blit(4, 1, 0,
            0,0,gfx.w, gfx.h,
            0,0,gfx.w, gfx.h, 0,0)   
      gfx.blit(5, 1, 0,
            0,0,gfx.w, gfx.h,
            0,0,gfx.w, gfx.h, 0,0)   
      
    gfx.update()
  end
  ----------------------------------------------
  function VF_GUI_DrawBackground(MOUSEt,OBJ,DATA)
    local col_back = '#3f484d'
    if DATA.GUIvars.colors and DATA.GUIvars.colors.backgr then col_back = DATA.GUIvars.colors.backgr  end
    local grad_sz = DATA.GUIvars.grad_sz or 200
    gfx.dest = 1
    gfx.setimgdim(1, -1, -1)  
    gfx.setimgdim(1, grad_sz,grad_sz)  
    local r,g,b = VF_hex2rgb(col_back)
    gfx.x, gfx.y = 0,0
    local c = 0.8
    local a=0.9
    local drdx = c*0.00001
    local drdy = c*0.00001
    local dgdx = c*0.00002
    local dgdy = c*0.0001    
    local dbdx = c*0.00008
    local dbdy = c*0.00001
    local dadx = c*0.00001
    local dady = c*0.00001      
    gfx.gradrect(0,0, grad_sz,grad_sz, 
                    r,g,b,a, 
                    drdx, dgdx, dbdx, dadx, 
                    drdy, dgdy, dbdy, dady) 
  end 
  ---------------------------------------------------  
  function VF_GUI_DrawBackgroundButton(MOUSEt,OBJ,DATA)
    local grad_sz = DATA.GUIvars.grad_sz
    gfx.dest = 2
    gfx.setimgdim(2, -1, -1)
    gfx.setimgdim(2, grad_sz,grad_sz)
    local r,g,b,a = 1,1,1,0.6
    gfx.x, gfx.y = 0,0
    local c = 1
    local drdx = 0--c*0.001
    local drdy = 0--c*0.01
    local dgdx = 0--c*0.001
    local dgdy = 0--c*0.001    
    local dbdx = 0--c*0.00003
    local dbdy = 0--c*0.001
    local dadx = c*0.00015
    local dady = c*0.0001
    gfx.gradrect(0,0, grad_sz,grad_sz,
                    r,g,b,a,
                    drdx, dgdx, dbdx, dadx,
                    drdy, dgdy, dbdy, dady)
  end 
 ---------------------------------------------------
  function VF_GUI_DrawButton(MOUSEt,OBJ,DATA, o) 
    if not o.is_button then return end
    gfx.set(0,0,0,1)
    
    -- defaults
      local x = o.x or 0
      local y = o.y or 0
      local w = o.w or 100
      local h = o.h or 100
      local grad_back_a = o.grad_back_a or 1
      local highlight = o.highlight if highlight == nil then highlight = true end
      local undermouse_frame_a = o.undermouse_frame_a or 0.4
      local undermouse_frame_col = o.undermouse_frame_col or '#FFFFFF'
      local undermouse = o.undermouse or false
      local selected = o.selected or false
      local selection_a = o.selection_a or 0.2
      local selection_col = o.selection_col or '#FFFFFF'
      local backfill_a = o.backfill_a or 0
      local check = o.check
      local check_state_cnt = o.check_state_cnt or 1
      
    -- reset
      gfx.set(1,1,1,1) 
    
    -- gradient background 
      if grad_back_a > 0 then
        gfx.a = grad_back_a
        gfx.blit(2, 1, 0, -- buttons
            0,0,DATA.GUIvars.grad_sz,DATA.GUIvars.grad_sz,
            x,y,w,h, 0,0) 
        --[[gfx.blit(2, 1, math.rad(180), -- buttons
            0,DATA.GUIvars.grad_sz/2,DATA.GUIvars.grad_sz,DATA.GUIvars.grad_sz/2,
            x-1,y+h/2,w+1,h/2, 0,0) ]]            
      end
    
    -- rect under mouse
      if highlight ==true and undermouse and undermouse_frame_a > 0 then
        VF_hex2rgb(undermouse_frame_col, true)
        gfx.a = undermouse_frame_a
        VF_GUI_rect(x-1,y-1,w,h+1)
      end
    
    -- selection
      if selected then
        VF_hex2rgb(selection_col, true)
        gfx.a = selection_a
        gfx.rect(x,y,w,h)
      end  
      
    -- backfill
      if backfill_a > 0  then
        VF_hex2rgb(selection_col, true)
        gfx.a = backfill_a
        gfx.rect(x,y,w,h)
      end    
      
    -- check
    if check==true or check== false or tonumber(check) then
      gfx.a = 0.7
      if type(check)=='boolean' then
        local xr = x+2
        local yr = y+2
        local wr = h-6
        local hr = h-5
        if check==true then gfx.rect(xr,yr,wr,hr,1) end
        VF_GUI_rect(x,y,h-3,h-2,0)
        o.checkxshift = h
       elseif type(o.check)=='number' then
        local xr = x+2
        local yr = y+2
        local wr = h-6
        local wr_single = math.ceil(wr / check_state_cnt)
        wr = wr_single*check_state_cnt
        o.checkxshift =wr +6 
        local hr = h-5        
        VF_GUI_rect(x,y,wr+3,h-2,0)
        for i = 1, check_state_cnt do
          local testval = 2^(i-1)
          if check&testval==testval then 
            gfx.rect(xr + wr_single*(i-1),yr,wr_single,hr,1)
          end
        end
      end   
    end
    
    VF_GUI_DrawTxt(MOUSEt,OBJ,DATA, o) 
  end
  
 --------------------------------------------------- 
    function VF_GUI_rect(x,y,w,h)
      gfx.x,gfx.y = x,y
      gfx.lineto(x,y+h)
      gfx.x,gfx.y = x+1,y+h
      gfx.lineto(x+w,y+h)
      gfx.x,gfx.y = x+w,y+h-1
      gfx.lineto(x+w,y)
      gfx.x,gfx.y = x+w-1,y
      gfx.lineto(x+1,y)
    end 
 ---------------------------------------------------     
  function VF_GUI_DrawTxt(MOUSEt,OBJ,DATA, o) 
    local txt = o.txt
    if not txt then return end
    txt = tostring(txt)
    
    -- defaults
      local txt_a = o.txt_a or 0.8
      local x= o.x or 0
      local x = o.x or 0
      local y = o.y or 0
      local w = o.w or 100
      local h = o.h or 100
      local font = o.font or 'Calibri'
      local fontsz = o.fontsz or 12
      local font_flags = o.font_flags or ''
      local txt_col = o.txt_col or '#FFFFFF'
      local txt_a = o.txt_a or 1
      local drawstr_flags = o.drawstr_flags or 1|4
      local txt_dontwrap = o.txt_dontwrap or false
      
      if o.checkxshift then 
        x = x + o.checkxshift
        w = w - o.checkxshift
      end
      
    gfx.set(1,1,1)
    gfx.x,gfx.y = x,y 
    VF_hex2rgb(txt_col, true)
    gfx.setfont(1,font, fontsz, font_flags )
    
    
    if txt_dontwrap or (gfx.measurestr(txt) <= w and not txt:match('[\r\n]+')) then
      gfx.a = txt_a
      gfx.drawstr(txt,drawstr_flags,x+w,y+h )
     else
      if drawstr_flags&8==8 then drawstr_flags=drawstr_flags-8 end -- ignore vertical flags
      if drawstr_flags&4==4 then 
        drawstr_flags=drawstr_flags-4
        gfx.a = txt_a
        local texth = VF_GUI_DrawTxt_WrapTxt(txt,x,y,w,h,drawstr_flags, true) 
        VF_GUI_DrawTxt_WrapTxt(txt,x,y+h/2-texth/2,w,h,drawstr_flags, false) 
       else
        gfx.a = txt_a
        VF_GUI_DrawTxt_WrapTxt(txt,x,y,w,h,drawstr_flags, false) 
      end
    end
    --[[If flags, right ,bottom passed in:
    flags&1: center horizontally
    flags&2: right justify
    flags&4: center vertically
    flags&8: bottom justify
    flags&256: ignore right/bottom, otherwise text is clipped to (gfx.x, gfx.y, right, bottom)]]  
  end
  ---------------------------------------------------  
  function VF_GUI_DrawTxt_WrapTxt(txt, x,y,w,h, drawstr_flags,simulate) 
    local indent_replace = 'indent_custom'
    local y0 =y
    local ystep = gfx.texth
    for stroke in txt:gmatch('[^\r\n]+') do 
      local t = {}
      if stroke:find('%s') == 1 then
        local first_nonindent = stroke:find('[^%s]')
        if first_nonindent then
          str1 = stroke:sub(0,first_nonindent)
          str2 = stroke:sub(first_nonindent+1)
          stroke = str1:gsub('%s',indent_replace)..str2
        end
      end
      for word in stroke:gmatch('[^%s]+') do t[#t+1] = word end
      local s = ''
      for i = 1, #t do
        local s0 = s
        s = s..t[i]..' '
        s=s:gsub(indent_replace,' ')
        if gfx.measurestr( s) > w  then  
          gfx.y=y
          if not simulate then gfx.drawstr(s0,drawstr_flags,x+w,y+h) end
          s=t[i]..' '
          gfx.x=x
          y=y+ystep
        end 
        if i==#t then
         gfx.x=x
         gfx.y=y
         if not simulate then gfx.drawstr(s,drawstr_flags,x+w,y+h) end
        end
      end
      gfx.x=x
      y=y+ystep
      gfx.y=y
    end
    return gfx.y-y0
  end
  
  -----------------------------------------------   
  function OBJ_Strategy_Build(MOUSE,OBJ,DATA, ref_strtUI,x,y,w,h) 
    local name = 'strat'
    for key in pairs(OBJ)do if key:match(name) then OBJ[key] = nil end end -- reset all existed entries
    local strat_xind = 7
    local strat_itemh = 14
    local y_offs = 0
    local y_offs0 = 0
    local x_offs = 0  
    OBJ.strframe = { x=x,
                      y=y,
                      w=w,
                      h=h,
                      ignore_mouse = true
                    }   
    for i = 1, #ref_strtUI do
      if ref_strtUI[i].show then
        local level = ref_strtUI[i].level or 0
        --[[local disable_blitback if not ref_strtUI[i].has_blit then disable_blitback = true end
        local col_str 
        if ref_strtUI[i].col_str then col_str = ref_strtUI[i].col_str end
        local txt_a,ignore_mouse=0.9
        if ref_strtUI[i].hidden then txt_a = 0.35 end
        
        --if y_str + y_offs+obj.strategy_itemh > gfx.h- obj.bottom_line_h then return end
        if y + y_offs+DATA.customGUI.strat_itemh > gfx.h then return end
        --local backfill_a =0.5 if disable_blitback then backfill_a = 0.3 end]]
        OBJ[name..i] =  { is_button = true,
                        x = x_offs+x + level *strat_xind ,
                        y = y + y_offs0 + y_offs,
                        w = w - level *strat_xind ,
                        h = strat_itemh,
                        check = ref_strtUI[i].state,
                        check_state_cnt = ref_strtUI[i].state_cnt,
                        txt= ref_strtUI[i].name,
                        fontsz = 15,
                        ignore_mouse = ignore_mouse,
                        grad_back_a =0.9,
                        backfill_a=backfill_a,
                        drawstr_flags=0,
                        txt_dontwrap = true,
                        func_Ltrig = function()  
                                if ref_strtUI[i].func then ref_strtUI[i].func() end
                                DATA.refresh.conf = DATA.refresh.conf|1
                                DATA.refresh.GUI = DATA.refresh.GUI|2
                              end,
                        func_Rtrig = function()  
                                if ref_strtUI[i].func_R then ref_strtUI[i].func_R() end
                                DATA.refresh.conf = DATA.refresh.conf|1
                                DATA.refresh.GUI = DATA.refresh.GUI|2
                              end,                              
                        } 
        y_offs = y_offs + strat_itemh
      end 
      
    end
    return y_offs - y -- return height of table
  end    
