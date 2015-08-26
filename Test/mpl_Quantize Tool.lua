------  Michael Pilyavskiy Quantize tool  ----
 vrs = "0.62 (beta)"

 --------------------
 ---- To Do list ----
 --------------------
 
 -- bar / beat grid on gui display 
 -- lmb click on grid add groove point
 -- rmb click on grid delete groove point
 -- quantize/get groove tempo envelope
 -- presets store/recall
 -- prevent transients stretch markers quantize
 -- create objects
 -- font size option
 -- hold MMB move grid / scroll zoom grid
 -- about button
 -- getset ref pitch/pan from itemtakes notes and env points
 -- popup start/end time in display
 -- load/save pattern
 
 
 
 --------------------
 ------- Bugs -------
 --------------------
 
 -- stretch markers bug: http://forum.cockos.com/project.php?issueid=5647
 -- stretch markers quantize DOES NOT work when Item Loop Source is ON 
 
 
 --------------------
 ------- About ------
 -------------------- 
 
 about = "Quantize tool by Michael Pilyavskiy ".."\n"..
         "Version "..vrs.."\n"..
         "\n"..
         " -- Soundcloud -- http://soundcloud.com/mp57".."\n"..
         " -- PromoDJ --  http://pdj.com/michaelpilyavskiy".."\n"..
         " -- VK --  http://vk.com/michael_pilyavskiy".."\n"..         
         " -- GitHub --  http://github.com/MichaelPilyavskiy/ReaScripts".."\n"
         .."\n"
         
         
    .."Changelog:".."\n"
    .."  26.08.2015 - 0.62 generate pattern grid engine, pattern length, gui improvements".."\n"    
    .."  26.08.2015 - 0.56 quantize stretchmarkers func new build".."\n"
    .."  25.08.2015 - 0.55 quantize notes/selected notes improvements".."\n"
    .."  17.08.2015 - 0.542 gravity improvements, main quantize engine updates".."\n" 
    .."  17.08.2015 - 0.5 a lot of structure, GUI and logic improvements".."\n" 
    .."  15.07.2015 - 0.152 info message when snap > 1 to prevent reaper crash".."\n" 
    .."            ESC to close".."\n"   
    .."  13.07.2015 - 0.141 stretch markers quantize when takerate not equal 1".."\n" 
    .."            get groove from stretch markers when takerate not equal 1".."\n" 
    .."            envelope points quantize engine, gui improvements".."\n"
    .."  11.07.2015 - 0.13 swing follow bug, markers quantize engine rebuilded again...".."\n" 
    .."  09.07.2015 - 0.12 empty type swing window, project grid option,".."\n" 
    .."            swing linked to grid, bypass, toggle state 0.5s for mouse click".."\n" 
    .."            str_markers quantize improvements".."\n"          
    .."  07.07.2015 - 0.113 restore exit button, right click on swing to type swing,".."\n" 
    .."            swing 100% is half grid, info, quantize items bug,".."\n" 
    .."            user cancelled swing dialog, get stretch markers via srcpos,".."\n"
    .."            centered swing".."\n"
    .."  06.07.2015 - 0.092 gui, groove points compare bug,".."\n" 
    .."            stretch markers get/quantize bugfixes,".."\n" 
    .."            draw grid bug, gravity function building ".."\n"
    .."  04.07.2015 - 0.081 swing always 1/4 bug , custom grid, fontsize = 16".."\n"        
    .."            quantize engine improvements".."\n"
    .."  02.07.2015 - 0.07 new gui, performance improvements...".."\n"
    .."  01.07.2015 - 0.06 menu count numbers, strength slider, point gravity slider,".."\n"
    .."            quantize engine basics".."\n"
    .."  30.06.2015 - 0.05 about,get project grid".."\n"
    .."  28.06.2015 - 0.04 get_groove function building".."\n"
    .."  27.06.2015 - 0.03 font, back, menus".."\n"
    .."  25.06.2015 - 0.02 gui, snap direction, swing gui fill gradient, swing engine".."\n"
    .."  23.06.2015 - 0.01 idea".."\n"



 --------------------
 ------- Code -------
 --------------------
   
 function test_var(test, test2)  
   if test ~= nil then  reaper.ShowConsoleMsg("") reaper.ShowConsoleMsg(test) end
   if test2 ~= nil then reaper.ShowConsoleMsg("\n") reaper.ShowConsoleMsg(test2) end
 end
 
 --------------------------------------------------------------------------------------------------------------- 
 
 function math.round(num, idp)
   local mult = 10^(idp or 0)
   return math.floor(num * mult + 0.5) / mult
 end 
 
 --------------------------------------------------------------------------------------------------------------- 
  
 function DEFINE_default_variables() 
   
     -- preset area --
   snap_mode_values_t = {0,1} 
   pat_len_values_t = {1,0,0}
   pat_edge_values_t = {0,1}
   use_vel_values_t = {1,0} 
   sel_notes_mode_values_t = {0,1}
   
   snap_area_values_t = {0,1}
   snap_dir_values_t = {0,1,0}
   swing_scale_values_t = {0,1}
   sel_notes_mode2_values_t = {0,1}
   
 
     -- end preset area --
  
   
   
   
   restore_button_state = false
   options_button_state = false
   if snap_mode_values_t[2] == 1 then  quantize_ref_values_t = {0, 0, 0, 0, 0, 1} else quantize_ref_values_t = {0, 0, 0, 0} end
   quantize_dest_values_t = {0, 0, 0, 0}
    
   count_reference_item_positions = 0
   count_reference_sm_positions = 0
   count_reference_ep_positions = 0
   count_reference_notes_positions = 0
   
   count_dest_item_positions = 0
   count_dest_sm_positions = 0
   count_dest_ep_positions = 0
   count_dest_notes_positions = 0
   
   grid_value = 0
   swing_value = 0
   strenght_value = 1
   gravity_value = 0.2
   gravity_mult_value = 1 -- second
   use_vel_value = 0
   swing_scale = 0.5
   
   
   
 end
 
 --------------------------------------------------------------------------------------------------------------- 
  
 function DEFINE_dynamic_variables() 
     
   playpos = reaper.GetPlayPosition() 
   editpos = reaper.GetCursorPosition()   
   
   grid_beats, grid_string, project_grid_measures, project_grid_cml = GET_grid()
   
   if pat_len_values_t[1] == 1 then  pattern_len = 1 end -- bar  
   if pat_len_values_t[2] == 1 then  pattern_len = 2 end 
   if pat_len_values_t[3] == 1 then  pattern_len = 4 end 
   
   -- default states for menus --
   snap_mode_menu_names_t = {"Snap reference mode:", "Global (timeline)","Local (pattern)"}
   pat_len_menu_names_t = {"Pattern length:", "1 bar","2 bars", "4 bars"}
   pat_edge_menu_names_t = {"Pattern edges:", "On","Off"}
   use_vel_menu_names_t = {"Ref. velocity:", "<   Use velocity / gain / point value ("..(math.ceil(math.round(use_vel_value*100,1))).."%)   >", "Don`t use"}
   sel_notes_mode_menu_names_t = {"Ref. notes:", "Get selected only","Get all notes in selected item"}
   
   snap_area_menu_names_t = {"Snap area:","< Use gravity ("..(math.round(gravity_value*gravity_mult_value,2)).." sec) >","Snap everything"}
   snap_dir_menu_names_t =  {"Snap direction:","To previous point","To closest point","To next point"} 
   swing_scale_menu_names_t =  {"Swing scaling:","1x (100% is next grid)","0.5x (REAPER behaviour)"}
   sel_notes_mode2_menu_names_t = {"Quantize notes:", "Selected only","All notes in selected item"}
   
   ---------------------
   -- count reference --
   ---------------------
   quantize_ref_menu_item_name = "Items ("..count_reference_item_positions..")" 
   quantize_ref_menu_sm_name = "Stretch markers ("..count_reference_sm_positions..")" 
   quantize_ref_menu_ep_name = "Envelope points ("..count_reference_ep_positions..")" 
   quantize_ref_menu_notes_name = "Notes ("..count_reference_notes_positions..")" 
   
   if custom_grid_beats_i == 0 or custom_grid_beats_i == nil then  quantize_ref_menu_grid_name = "project grid: "..grid_string 
                        else quantize_ref_menu_grid_name = "custom grid: "..grid_string end
   quantize_ref_menu_swing_name = "swing grid "..math.ceil(swing_value*100).."%"
   
   if snap_mode_values_t[2] == 1 then        
     quantize_ref_menu_names_t = {"Reference (groove points):", quantize_ref_menu_item_name, quantize_ref_menu_sm_name,
                                quantize_ref_menu_ep_name, quantize_ref_menu_notes_name,
                                quantize_ref_menu_grid_name,
                                quantize_ref_menu_swing_name}
    else
     quantize_ref_menu_names_t = {"Reference (groove points):", quantize_ref_menu_item_name, quantize_ref_menu_sm_name,
                                quantize_ref_menu_ep_name, quantize_ref_menu_notes_name}
   end
   -----------------------                             
   -- count destination --                             
   -----------------------
   quantize_dest_menu_item_name = "Items ("..count_dest_item_positions..")" 
   quantize_dest_menu_sm_name = "Stretch markers ("..count_dest_sm_positions..")" 
   quantize_dest_menu_ep_name = "Envelope points ("..count_dest_ep_positions..")" 
   quantize_dest_menu_notes_name = "Notes ("..count_dest_notes_positions..")" 
   
   quantize_dest_menu_names_t = {"Select objects to quantize:",quantize_dest_menu_item_name, quantize_dest_menu_sm_name,
                                quantize_dest_menu_ep_name, quantize_dest_menu_notes_name} 
   
   if quantize_ref_values_t[5] == 1 or quantize_ref_values_t[6] == 1 then
     pattern_len = 1 
   end  
   
   if restore_button_state == false then 
     apply_bypass_slider_name = "Apply (LMB) / Quantize strength slider / Restore (RMB)"end
 end 
   
 --------------------------------------------------------------------------------------------------------------- 
 
 function DEFINE_default_variables_GUI()
  gui_offset = 5
  x_offset = 5
  y_offset = 5
  y_offset1 = 240
  width1 =  400
  heigth1 = 100
  heigth2 = 20  
  heigth3= 100
  heigth4= 80
  beetween_menus1 = 5 -- hor
  beetween_items1 = 10 -- hor
  beetween_menus2 = 5 -- vert
  beetween_items2 = 5 -- vert
  
  -- gfx.vars --
  gui_help = 0.0  
  font = "Arial"
  fontsize_menu_name  = 16
  fontsize_menu_item = 15
  itemcolor1_t = {0.4, 1, 0.4}
  itemcolor2_t = {0.5, 0.8, 1}
  frame_alpha_default = 0.05  
  frame_alpha_selected = 0.1
  
  editpos_rgba_t = {0.5, 0, 0, 0.6}
  playpos_rgba_t = {0.5, 0.5, 0, 0.8}
  ref_points_rgba_t = {0, 1, 0, 0.5}
  dest_points_rgba_t = {0.1, 0.6, 1, 1}
  
  display_end = 1 -- 0..1
  display_start = 0 -- 0..1
  
  -- menus -- 
  snap_mode_menu_xywh_t = {x_offset, y_offset, width1, heigth2}
  pat_len_menu_xywh_t = {x_offset, y_offset+20, width1, heigth2}
  pat_edge_menu_xywh_t = {x_offset, y_offset+40, width1, heigth2}
  use_vel_menu_xywh_t = {x_offset, y_offset+60, width1, heigth2}
  sel_notes_mode_menu_xywh_t = {x_offset, y_offset+80, width1, heigth2}
  
  snap_area_menu_xywh_t = {x_offset, 150, width1, heigth2}
  snap_dir_menu_xywh_t = {x_offset, snap_area_menu_xywh_t[2]+snap_area_menu_xywh_t[4]+beetween_menus2, width1, heigth2}  
  swing_scale_menu_xywh_t = {x_offset,  snap_dir_menu_xywh_t[2]+snap_dir_menu_xywh_t[4]+beetween_menus2, width1, heigth2}
  sel_notes_mode2_menu_xywh_t = {x_offset, swing_scale_menu_xywh_t[2]+swing_scale_menu_xywh_t[4]+beetween_menus2, width1, heigth2}
  
  quantize_ref_menu_xywh_t = {x_offset, y_offset, width1/2, y_offset1-y_offset}
  quantize_dest_menu_xywh_t = {x_offset+width1/2+gui_offset, y_offset, width1/2-gui_offset , y_offset1-y_offset}

  -- options areas --
  ref_options_area_xywh_t = {x_offset, snap_mode_menu_xywh_t[2],width1, 100}
  quantize_options_area_xywh_t = {x_offset, snap_area_menu_xywh_t[2],width1, 100}  
  
  -- frames --
  display_rect_xywh_t = {x_offset, y_offset1+gui_offset, width1, heigth3}  
  
  -- static slider --
  apply_slider_xywh_t = {x_offset, display_rect_xywh_t[2]+display_rect_xywh_t[4]+beetween_menus2, width1, heigth4}  
  
  -- buttons --
  options_button_xywh_t = {x_offset+width1+gui_offset, y_offset, main_w - width1 - gui_offset*3, main_h-gui_offset*2 }
  
 end
 
 ---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------
  
 function GUI_menu_item(b0, item_offset, is_selected_item, is_vert, color_t)
   if is_selected_item == nil then is_selected_item = 0 end
   gfx.setfont(1, font, fontsize_menu_item)    
   measurestr = gfx.measurestr(b0)
   if is_vert == false then 
     x0 = item_offset
     y0 = y + (h - fontsize_menu_name)/2 + 1
   end
   
   if is_vert == true then
     x0 = x + (w - measurestr)/2 + 1
     y0 = item_offset
   end
   
   w0 = measurestr
   h0 = fontsize_menu_item   
   gfx.r, gfx.g, gfx.b, gfx.a = color_t[1], color_t[2], color_t[3], is_selected_item * 0.8 + 0.3  
   gfx.x = x0
   gfx.y = y0
   gfx.drawstr(b0) 
   -- gui help --
   gfx.r, gfx.g, gfx.b, gfx.a = 1,1,1,gui_help
   gfx.roundrect(x0,y0,w0,h0,0.1,true) 
   return x0, y0, w0, h0
 end 
      
 ---------------------------------------------------------------------------------------------------------------   
  
 function GUI_menu (xywh_t, names_t, values_t, is_vertical, is_selected,itemcolor_t,frame_alpha)
   x = xywh_t[1]
   y = xywh_t[2]
   w = xywh_t[3]
   h = xywh_t[4]
   num_buttons = #values_t
      
   -- frame --
   if is_selected ~= nil and is_selected == true then gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = 0,0,1,1,1,0.5  
                          else gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = 0,0,1,1,1,frame_alpha end   
   gfx.roundrect(x,y,w,h,0.1,true)   
   
   -- define name strings -- 
   names_com = table.concat(names_t)
   menu_name = names_t[1] 
   b1 = names_t[2]
   b2 = names_t[3]
   b3 = names_t[4]
   b4 = names_t[5]
   b5 = names_t[6]
   b6 = names_t[7]
   b7 = names_t[8]
   b8 = names_t[9]
   b9 = names_t[10]   
   
   -- measure length of strings --
   gfx.setfont(1,font,fontsize_menu_name) 
   measurestrname = gfx.measurestr(menu_name)
   gfx.setfont(1,font,fontsize_menu_item)    
   measurestr1 = gfx.measurestr(b1)
   measurestr2 = gfx.measurestr(b2)
   if b3 ~= nil then measurestr3 = gfx.measurestr(b3) else measurestr3 = 0 end
   if b4 ~= nil then measurestr4 = gfx.measurestr(b4) else measurestr4 = 0 end
   if b5 ~= nil then measurestr5 = gfx.measurestr(b5) else measurestr5 = 0 end
   if b6 ~= nil then measurestr6 = gfx.measurestr(b6) else measurestr6 = 0 end
   if b7 ~= nil then measurestr7 = gfx.measurestr(b7) else measurestr7 = 0 end
   if b8 ~= nil then measurestr8 = gfx.measurestr(b8) else measurestr8 = 0 end
   if b9 ~= nil then measurestr9 = gfx.measurestr(b9) else measurestr9 = 0 end
   if b10 ~= nil then measurestr10 = gfx.measurestr(b10) else measurestr10 = 0 end
   measurestr_menu_com = gfx.measurestr(names_com) + (num_buttons)*beetween_items1
   
   if is_vertical == false then
   
     -- draw menu name --
     gfx.setfont(1,font,fontsize_menu_name)      
     x0 = x + (w - measurestr_menu_com)/2
     y0 = y + (h - fontsize_menu_name)/2
     gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = x0,y0,1,1,1,0.9 
     gfx.drawstr(menu_name)
     
     -- gui help frame for name --
     gfx.r, gfx.g, gfx.b, gfx.a = 1,1,1,gui_help
     gfx.roundrect(x0,y0,measurestrname,fontsize_menu_name,0.1,true,itemcolor_t) 
     
     -- draw menu items --     
     item_x_offset = x0 + measurestrname + beetween_items1
     x1,y1,w1,h1 = GUI_menu_item(b1, item_x_offset, values_t[1],false,itemcolor_t)
     
     item_x_offset = x1 + w1 + beetween_items1
     x2,y2,w2,h2 = GUI_menu_item(b2, item_x_offset, values_t[2],false,itemcolor_t)
     
     if b3~=nil then 
     item_x_offset = x2 + w2 + beetween_items1
     x3,y3,w3,h3 = GUI_menu_item(b3, item_x_offset, values_t[3],false,itemcolor_t) end
     
    else
    
     height_menu_com = fontsize_menu_name + fontsize_menu_item*num_buttons + beetween_items2*(num_buttons+1)
     
     -- draw menu name --
     gfx.setfont(1,font,fontsize_menu_name)      
     x0 = x + (w-measurestrname)/2
     y0 = y + (h - height_menu_com)/2
     gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = x0,y0,1,1,1,0.9 
     gfx.drawstr(menu_name)
     
     -- gui help frame for name --
     gfx.r, gfx.g, gfx.b, gfx.a = 1,1,1,gui_help
     gfx.roundrect(x0,y0,measurestrname,fontsize_menu_name,0.1,true) 
     
     -- draw menu items --     
     item_y_offset = y0 + fontsize_menu_name+ beetween_items2
     x1,y1,w1,h1 = GUI_menu_item(b1, item_y_offset, values_t[1],true,itemcolor_t)
     
     item_y_offset = y1 + h1 + beetween_items2
     x2,y2,w2,h2 = GUI_menu_item(b2, item_y_offset, values_t[2],true,itemcolor_t)
     
     if b3~=nil then 
     item_y_offset = y2 + h2 + beetween_items2
     x3,y3,w3,h3 = GUI_menu_item(b3, item_y_offset, values_t[3],true,itemcolor_t) end
     
     if b4~=nil then 
     item_y_offset = y3 + h3 + beetween_items2
     x4,y4,w4,h4 = GUI_menu_item(b4, item_y_offset, values_t[4],true,itemcolor_t) end  
     
     if b5~=nil then 
     item_y_offset = y4 + h4 + beetween_items2
     x5,y5,w5,h5 = GUI_menu_item(b5, item_y_offset, values_t[5],true,itemcolor_t) end  
     
     if b6~=nil then 
     item_y_offset = y5 + h5 + beetween_items2
     x6,y6,w6,h6 = GUI_menu_item (b6, item_y_offset, values_t[6],true,itemcolor_t) end 
   end   
                   
     
   coord_buttons_data = {x1, y1, w1, h1,
                         x2, y2, w2, h2,
                         x3, y3, w3, h3,
                         x4, y4, w4, h4,
                         x5, y5, w5, h6,
                         x6, y6, w6, h6,
                         x7, y7, w7, h7,
                         x8, y8, w8, h8,
                         x9, y9, w9, h9,
                         x10, y10, w10, h10}
   return coord_buttons_data 
 end  
 
 ---------------------------------------------------------------------------------------------------------------
  
function GUI_display_pos (pos, rgba_t, align, val)  
   if val == nil or val > 1 then val = 1 end   
   
  --[[if snap_mode_values_t[2] == 1 then -- if pattern mode        
     pat_len_position = reaper.TimeMap2_beatsToTime(0, 0, pattern_len-1)     
     x1 = display_rect_xywh_t[1] + (display_rect_xywh_t[3] * (pos / pat_len_position))   
   end
   
   
   if snap_mode_values_t[1] == 1 then -- if global  ]]
      x1 = display_rect_xywh_t[1] + display_rect_xywh_t[3] *   (pos / max_object_position)   
--   end
   
   if align == "full" then
     y1 = display_rect_xywh_t[2]
     y2 = display_rect_xywh_t[2] + display_rect_xywh_t[4]
   end
   
   if align == "bottom" then
     y1 = display_rect_xywh_t[2] + display_rect_xywh_t[4] - val * (display_rect_xywh_t[4] / 4)
     y2 = display_rect_xywh_t[2] + display_rect_xywh_t[4]
   end  
   
   if align == "top" then
     y1 = display_rect_xywh_t[2]
     y2 = display_rect_xywh_t[2] + val * (display_rect_xywh_t[4] / 4)
   end     
    
   gfx.x = x1
   gfx.y = y1
   gfx.r, gfx.g, gfx.b, gfx.a = rgba_t[1], rgba_t[2], rgba_t[3], rgba_t[4]
   if x1 >= display_rect_xywh_t[1] and x1 < display_rect_xywh_t[1] + display_rect_xywh_t[3] then
     gfx.line(x1, y1, x1, y2, 0.9)
   end  
end 
 
 ---------------------------------------------------------------------------------------------------------------
 
 function GUI_display() 
   -- display main rectangle -- 
   gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1,frame_alpha_default
   gfx.roundrect(display_rect_xywh_t[1], display_rect_xywh_t[2],display_rect_xywh_t[3], display_rect_xywh_t[4],0.1, true)
   
   -- center line
   gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 0.03
   gfx.line(display_rect_xywh_t[1], 
            display_rect_xywh_t[2]+display_rect_xywh_t[4]/2, 
            display_rect_xywh_t[1]+display_rect_xywh_t[3], 
            display_rect_xywh_t[2]+display_rect_xywh_t[4]/2, 0.9)   
         
   GUI_display_pos(editpos, editpos_rgba_t, "full")
   GUI_display_pos(playpos, playpos_rgba_t, "full")
   
   -- ref points positions
   if ref_points_t ~= nil then
     for i = 1, #ref_points_t do
       ref_point = ref_points_t[i]
       val = ref_point[2]
       if val == nil then val = 1 end       
       if use_vel_values_t[1] == 1 then
         GUI_display_pos(ref_point[1], ref_points_rgba_t, "top", ref_point[2])
        else  
         GUI_display_pos(ref_point[1], ref_points_rgba_t, "top", 1)
       end       
     end
   end  
   
   -- dest points positions
   if dest_points_t ~= nil then
     for i = 1, #dest_points_t do
       dest_point = dest_points_t[i]       
       if dest_point[2] == nil then val = 1 else val = dest_point[2] end
       GUI_display_pos(dest_point[1], dest_points_rgba_t, "bottom", val)
     end
   end    
 end  
 
---------------------------------------------------------------------------------------------------------------

 function GUI_slider_gradient(xywh_t, name, slider_val, type)
   if slider_val > 1 then slider_val = 1 end
   slider_val_inv = math.abs(math.abs(slider_val) - 1)
   x = xywh_t[1]
   y = xywh_t[2]
   w = xywh_t[3]-slider_val_inv*xywh_t[3]
   w0 = xywh_t[3]
   h = xywh_t[4]
   r,g,b,a = 1,1,1.1   
   gfx.x = x
   gfx.y = y
   drdx = 0
   drdy = 0
   dgdx = 0.0002
   dgdy = 0.002     
   dbdx = 0
   dbdy = 0
   dadx = 0.001
   dady = 0.0001
   
   if type == "normal" then
     gfx.gradrect(x,y,w,h, r,g,b,a, drdx, dgdx, dbdx, dadx, drdy, dgdy, dbdy, dady)
   end
   
   if type == "centered" then
     if slider_val > 0 then                  
       gfx.gradrect(x+w0/2,y,w/2,h,         r,g,b,a,    drdx, dgdx, dbdx,  dadx, drdy, dgdy, dbdy,  dady)
      else
       a_st =  dadx *  w/2
       gfx.gradrect(x + (w0/2-w/2),y,w/2,h, r,g,b,a_st, drdx, dgdx, dbdx, -dadx, drdy, dgdy, dbdy, -dady)
     end
   end
   
   if type == "mirror" then       
     gfx.gradrect(x+w0/2,y,w/2,h,         r,g,b,a,    drdx, dgdx, dbdx,  dadx, drdy, dgdy, dbdy,  dady)
     a_st =  dadx *  w/2
     gfx.gradrect(x + (w0/2-w/2),y,w/2,h, r,g,b,a_st, drdx, dgdx, dbdx, -dadx, drdy, dgdy, dbdy, -dady)     
   end
     
   -- draw name -- 
   gfx.setfont(1,font,fontsize_menu_name)
   measurestrname = gfx.measurestr(name)      
   x0 = x + (w0 - measurestrname)/2
   y0 = y + (h - fontsize_menu_name)/2
   gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = x0,y0,0.4, 1, 0.4,0.9 
   gfx.drawstr(name)
   
   --draw frame
   gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, frame_alpha_default
   gfx.roundrect(x,y,w0,h,0.1, true)   
 end 
 
---------------------------------------------------------------------------------------------------------------

 function GUI_button(xywh_t, name, name_pressed, state)
   x = xywh_t[1]
   y = xywh_t[2]
   w = xywh_t[3]
   h = xywh_t[4]
   gfx.x,  gfx.y = x,y
   
   
   
   -- draw name -- 
   gfx.setfont(1,font,fontsize_menu_name)
   measurestrname = gfx.measurestr(name)      
   x0 = x + (w - measurestrname)/2
   y0 = y + (h - fontsize_menu_name)/2
   gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = x0,y0,0.4, 1, 0.4,0.9 
   
   if state == false then 
     gfx.drawstr(name) 
     -- frame -- 
     gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, frame_alpha_default
     gfx.roundrect(x,y,w,h,0.1, true)
    else 
      gfx.drawstr(name_pressed) 
      -- frame -- 
      gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, frame_alpha_selected
      gfx.roundrect(x,y,w,h,0.1, true)
   end
 end
 
---------------------------------------------------------------------------------------------------------------
     
 function GUI_DRAW()
 
  if project_grid_measures < 1 then
  
   ------------------  
   --- main page ----
   ------------------  
   
     -- background --
     gfx.r, gfx.g, gfx.b, gfx.a = 0.2, 0.2, 0.2, 1
     gfx.rect(0,0,main_w,main_h)
    
     -- menus --  
     
     quantize_ref_xywh_buttons_t =   GUI_menu (quantize_ref_menu_xywh_t, quantize_ref_menu_names_t, quantize_ref_values_t, true,false,itemcolor1_t,0.05)
     if snap_mode_values_t[2] == 1 then -- if pattern mode
       meas_str_temp = gfx.measurestr(quantize_ref_menu_names_t[6])       -- if grid
       grid_value_slider_xywh_t = {x_offset, quantize_ref_xywh_buttons_t[18]-2, width1/2, fontsize_menu_item+4}
       swing_grid_value_slider_xywh_t = {x_offset, quantize_ref_xywh_buttons_t[22]-2, width1/2, fontsize_menu_item+4}
       if display_grid_value_slider == true then GUI_slider_gradient(grid_value_slider_xywh_t, "", grid_value, "normal") end 
       if display_swing_value_slider == true then GUI_slider_gradient(swing_grid_value_slider_xywh_t, "", swing_value, "centered") end 
     end  
     
     
     quantize_dest_xywh_buttons_t =  GUI_menu (quantize_dest_menu_xywh_t, quantize_dest_menu_names_t, quantize_dest_values_t, true,false,itemcolor2_t,0.05)
   
     GUI_display()
   
     GUI_slider_gradient(apply_slider_xywh_t, apply_bypass_slider_name, strenght_value,"normal")
   
     GUI_button(options_button_xywh_t, "<<", ">>", options_button_state)
     
   ------------------  
   -- options page --
   ------------------
   
     if options_button_state == true then     
       for i = 1, 6 do
         gfx.x, gfx.y = 0,0
         gfx.blurto(gui_offset*2+width1,main_h)
       end
       -- background + --
       gfx.r, gfx.g, gfx.b, gfx.a = 0, 0, 0, 0.8
       gfx.rect(0,0,gui_offset*2+width1,main_h)            
       
       -- areas background --
       
       gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 0.1
       gfx.rect(ref_options_area_xywh_t[1],ref_options_area_xywh_t[2],ref_options_area_xywh_t[3],ref_options_area_xywh_t[4])
       
       gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 0.1
       gfx.rect(quantize_options_area_xywh_t[1],quantize_options_area_xywh_t[2],quantize_options_area_xywh_t[3],quantize_options_area_xywh_t[4])
       
      -- ref setup area --
        snap_mode_xywh_buttons_t =      GUI_menu (snap_mode_menu_xywh_t, snap_mode_menu_names_t, snap_mode_values_t, false,false,itemcolor2_t,0)
        pat_len_xywh_buttons_t =      GUI_menu (pat_len_menu_xywh_t, pat_len_menu_names_t, pat_len_values_t, false,false,itemcolor2_t,0)
        pat_edge_xywh_buttons_t =      GUI_menu (pat_edge_menu_xywh_t, pat_edge_menu_names_t, pat_edge_values_t, false,false,itemcolor2_t,0)
        use_vel_xywh_buttons_t =        GUI_menu (use_vel_menu_xywh_t, use_vel_menu_names_t, use_vel_values_t, false,false,itemcolor2_t,0)
          use_vel_slider_xywh_t = {use_vel_xywh_buttons_t[1], use_vel_xywh_buttons_t[2], use_vel_xywh_buttons_t[3], use_vel_xywh_buttons_t[4]}
          GUI_slider_gradient(use_vel_slider_xywh_t, "", use_vel_value, "normal")
        sel_notes_mode_xywh_buttons_t =      GUI_menu (sel_notes_mode_menu_xywh_t, sel_notes_mode_menu_names_t, sel_notes_mode_values_t, false,false,itemcolor2_t,0)
        
      -- quantize setup area -- 
        snap_area_xywh_buttons_t =      GUI_menu (snap_area_menu_xywh_t, snap_area_menu_names_t, snap_area_values_t, false,false,itemcolor2_t,0)
          gravity_slider_xywh_t = {snap_area_xywh_buttons_t[1], snap_area_xywh_buttons_t[2], snap_area_xywh_buttons_t[3], snap_area_xywh_buttons_t[4]}
          if snap_area_values_t[1] == 1 then GUI_slider_gradient(gravity_slider_xywh_t, "", gravity_value, "mirror") end -- if gravity
        
        snap_dir_xywh_buttons_t =       GUI_menu (snap_dir_menu_xywh_t,  snap_dir_menu_names_t, snap_dir_values_t, false,false,itemcolor2_t,0)
        swing_scale_xywh_buttons_t =    GUI_menu (swing_scale_menu_xywh_t,  swing_scale_menu_names_t, swing_scale_values_t, false,false,itemcolor2_t,0)
        sel_notes_mode2_xywh_buttons_t =      GUI_menu (sel_notes_mode2_menu_xywh_t, sel_notes_mode2_menu_names_t, sel_notes_mode2_values_t, false,false,itemcolor2_t,0)
        
     end -- if options page on
     
   ------------------  
   -- error page --
   ------------------   
   
   else -- if snap > 1
     
     gfx.setfont(1,font,fontsize_menu_name)
     measure_err_str = gfx.measurestr("Set line spacing (Snap/Grid settings) lower than 1")
     gfx.x, gfx.y = (main_w-measure_err_str)/2, main_h/2
     gfx.drawstr("Set line spacing (Snap/Grid settings) lower than 1")   
    
  end -- if project_grid_measures == 0       
   
  gfx.update() 
  
 end
  
---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------    
 
 function GET_grid()
   project_grid_time = reaper.BR_GetNextGridDivision(0)
   project_grid_beats, project_grid_measures, project_grid_cml = reaper.TimeMap2_timeToBeats(0, project_grid_time)
   
   custom_grid_beats_t = {4/2,
                          4/3,
                          4/4,
                          4/6,
                          4/8,
                          4/12,
                          4/16,
                          4/24,
                          4/32,
                          4/48,
                          4/64}
                          
   custom_grid_beats_i = math.floor(grid_value*12)
   
   if project_grid_measures == 0 then
     if custom_grid_beats_i == 0 then 
       grid_beats = project_grid_beats 
      else
       grid_beats = custom_grid_beats_t[custom_grid_beats_i]
     end   
     grid_divider = math.ceil(math.round(4/grid_beats, 1))
     grid_string = "1/"..grid_divider
     if grid_divider % 3 == 0 then grid_string = "1/"..math.ceil(grid_divider/3*2).."T" end
    else
     grid_string = "error"
   end -- if proj grid measures ==0 / snap < 1  
   return  grid_beats, grid_string, project_grid_measures,project_grid_cml
 end 
  
 --------------------------------------------------------------------------------------------------------------- 
  
 function ENGINE1_get_reference_item_positions()
    ref_items_t = {} 
    ref_items_subt = {}
    count_sel_ref_items = reaper.CountSelectedMediaItems(0) 
    if count_sel_ref_items ~= nil then   -- get measures beetween items
      for i = 1, count_sel_ref_items, 1 do
        ref_item = reaper.GetSelectedMediaItem(0, i-1)          
        ref_item_pos = reaper.GetMediaItemInfo_Value(ref_item, "D_POSITION")
        ref_item_vol = reaper.GetMediaItemInfo_Value(ref_item, "D_VOL")
        ref_items_subt = {ref_item_pos, ref_item_vol}
        table.insert(ref_items_t, ref_items_subt)   
      end 
    end  
    return #ref_items_t 
  end 
  
 --------------------------------------------------------------------------------------------------------------- 
 
 function ENGINE1_get_reference_SM_positions()   
   ref_sm_pos_t = {}       
   count_sel_ref_items = reaper.CountSelectedMediaItems(0)  
   if count_sel_ref_items ~= nil then
     for i = 1, count_sel_ref_items, 1 do
     ref_item = reaper.GetSelectedMediaItem(0, i-1)       
       if ref_item ~= nil then
         ref_take = reaper.GetActiveTake(ref_item)
         if ref_take ~= nil then    
           takerate = reaper.GetMediaItemTakeInfo_Value(ref_take, "D_PLAYRATE" )           
           str_markers_count = reaper.GetTakeNumStretchMarkers(ref_take) 
           if  str_markers_count ~= nil then
             for j = 1, str_markers_count, 1 do             
              ref_item_pos = reaper.GetMediaItemInfo_Value(ref_item, "D_POSITION")                            
              ref_item_len = reaper.GetMediaItemInfo_Value(ref_item, "D_LENGTH")
              retval, ref_str_mark_pos = reaper.GetTakeStretchMarker(ref_take, j-1)
              ref_sm_pos = ref_item_pos + ref_str_mark_pos/takerate  
              if  ref_str_mark_pos > 0 and ref_str_mark_pos/takerate < ref_item_len-0.000001 then
                table.insert(ref_sm_pos_t, ref_sm_pos)              
              end
             end -- for
           end -- str_markers_count ~= nil
         end -- if take not nil         
       end -- if item not nil  
     end -- forcount sel items       
   end -- if sel items >0 
   return #ref_sm_pos_t   
 end
 
 --------------------------------------------------------------------------------------------------------------- 
 
 function ENGINE1_get_reference_EP_positions()   
  ref_ep_t = {}
  counttracks = reaper.CountTracks(0) 
  if  counttracks ~= nil then
    for i = 1, counttracks do 
      track = reaper.GetTrack(0, i-1)
      env_count = reaper.CountTrackEnvelopes(track)
      if env_count ~= nil then
        for j = 1, env_count do
          envelope = reaper.GetTrackEnvelope(track, j-1)
          if envelope ~= nil then
            envelope_points_count = reaper.CountEnvelopePoints(envelope)
            if envelope_points_count ~= nil then
              for k = 1, envelope_points_count, 1  do
                retval, ref_ep_pos, ref_ep_val, shape, tension, isselected = reaper.GetEnvelopePoint(envelope, k-1)
                if isselected == true then                   
                  table.insert(ref_ep_t, {ref_ep_pos, ref_ep_val} ) 
                end
              end  
            end -- if selected  
          end -- loop env points
        end  --envelope_points_count > 0
      end -- envelope not nil 
    end 
  end        
  
 -- take envelopes --
  count_items = reaper.CountSelectedMediaItems(0)
  if count_items ~= nil then
    for i = 1, count_items do
      item = reaper.GetSelectedMediaItem(0, i-1)
      if item ~= nil then
        takescount =  reaper.CountTakes(item)
        if takescount ~= nil then
          for j = 1, takescount do
            take = reaper.GetTake(item, j-1)
            if take ~= nil  then
              count_take_env = reaper.CountTakeEnvelopes(take)
              if count_take_env ~= nil then
                for env_id = 1, count_take_env do
                  TrackEnvelope = reaper.GetTakeEnvelope(take, env_id-1)
                  if TrackEnvelope ~= nil then
                    count_env_points = reaper.CountEnvelopePoints(TrackEnvelope)
                    if count_env_points ~= nil then 
                      for point_id = 1, count_env_points, 1 do    
                        retval, ref_ep_pos, ref_ep_val, shape, tension, selected = reaper.GetEnvelopePoint(TrackEnvelope, point_id-1)
                        if selected == true then                  
                          table.insert(ref_ep_t, {ref_ep_pos, ref_ep_val} ) 
                        end
                      end -- loop env points  
                    end  -- count_env_points ~= nil  
                  end -- TrackEnvelope ~= nil
                end  
              end
            end
          end
        end
      end
    end
  end
          
  return #ref_ep_t  
 end
 
 ---------------------------------------------------------------------------------------------------------------
 
 function ENGINE1_get_reference_notes_positions()  
     ref_notes_t  = {}
     count_sel_ref_items = reaper.CountSelectedMediaItems(0)
     if count_sel_ref_items ~= nil then   -- get measures beetween items
       for i = 1, count_sel_ref_items, 1 do
         ref_item = reaper.GetSelectedMediaItem(0, i-1)
         if ref_item ~= nil then
           ref_take = reaper.GetActiveTake(ref_item)
           if ref_take ~= nil then
             if reaper.TakeIsMIDI(ref_take) ==  true then   
               retval, notecntOut, ccevtcntOut = reaper.MIDI_CountEvts(ref_take)
               if notecntOut ~= nil then
                 for j = 1, notecntOut, 1 do                 
                   retval, selectedOut, mutedOut, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(ref_take, j-1)
                   if sel_notes_mode_values_t[1] == 1 then -- if selected only
                     if selectedOut == true then
                       ref_note_pos = reaper.MIDI_GetProjTimeFromPPQPos(ref_take, startppqpos)                   
                       table.insert(ref_notes_t, {ref_note_pos, vel/127})
                     end  
                   end  
                   if sel_notes_mode_values_t[2] == 1 then -- if all in item
                     ref_note_pos = reaper.MIDI_GetProjTimeFromPPQPos(ref_take, startppqpos)                   
                     table.insert(ref_notes_t, {ref_note_pos, vel/127})
                   end  
                 end -- count notes                   
               end -- notecntOut > 0
             end -- TakeIsMIDI
           end -- ref_take ~= nil 
         end-- ref_item ~= nil
       end -- for count_sel_ref_items
     end --   count_sel_ref_items > 0 
     return #ref_notes_t           
 end   
 
---------------------------------------------------------------------------
   
 function ENGINE1_get_reference_grid()
   ref_grid_t = {}
   for i = 0, 4, grid_beats do
     table.insert(ref_grid_t, i)
   end
 end 
 
 --------------------------------------------------------------------------------------------------------------- 
   
  function ENGINE1_get_reference_swing_grid()  
     ref_swing_grid_t = {}
     local i2 = 0
     for grid_step = 0, 4, grid_beats do       
       if i2 % 2 == 0 then 
         table.insert(ref_swing_grid_t, grid_step) end
       if i2 % 2 == 1 then        
         grid_step_swing = grid_step + swing_value* swing_scale*grid_beats         
         table.insert(ref_swing_grid_t, grid_step_swing) 
       end
       i2 = i2+1
     end   
end   
 
 --------------------------------------------------------------------------------------------------------------- 

 function ENGINE1_get_reference_FORM_points()
   ref_points_t = {}
   
     -- items --
     if quantize_ref_values_t[1] == 1 and ref_items_t ~= nil then     
       for i = 1, #ref_items_t do
         table_temp_val = ref_items_t[i]
         table.insert (ref_points_t, i, {table_temp_val[1],table_temp_val[2]})
       end
     end
     
     -- sm --
     if quantize_ref_values_t[2] == 1 then     
       for i = 1, #ref_sm_pos_t do
         table_temp_val = {ref_sm_pos_t[i],nil}
         table.insert (ref_points_t, i, table_temp_val)
       end
     end
     
     -- ep --
     if quantize_ref_values_t[3] == 1 then     
       for i = 1, #ref_ep_t do
         table_temp_val = ref_ep_t[i]
         table.insert (ref_points_t, i, {table_temp_val[1],table_temp_val[2]})
       end
     end
     
     -- notes --
     if quantize_ref_values_t[4] == 1 then     
       for i = 1, #ref_notes_t do
         table_temp_val = ref_notes_t[i]
         table.insert (ref_points_t, i, {table_temp_val[1],table_temp_val[2]})
       end
     end               
     
     -- grid --
     if quantize_ref_values_t[5] == 1 then     
       for i = 1, #ref_grid_t do
         table_temp_val = {ref_grid_t[i] , nil}
         table.insert (ref_points_t, i, table_temp_val)
       end
     end
     
     -- swing --
     if quantize_ref_values_t[6] == 1 then     
       for i = 1, #ref_swing_grid_t do
         table_temp_val = {ref_swing_grid_t[i], nil}
         table.insert (ref_points_t, i, table_temp_val)
       end
     end
    
    
    -- form pattern / generate pattern grid
           
     if ref_points_t ~= nil and snap_mode_values_t[2] == 1 then
        ref_points_t2 = {}--table for beats pos        
        retval, last_measure, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, max_object_position) -- last project measure
        first_measure = last_measure --start value  for loop
        for i = 1, #ref_points_t do          
          ref_point_subt_temp = ref_points_t[i]
          retval, measure, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, ref_point_subt_temp[1])
          first_measure = math.min(first_measure, measure)
        end  
        -- if pos not bigger than fisrt item measure + pattern length , add to table
        for i = 1, #ref_points_t do
          ref_point_subt_temp = ref_points_t[i]          
          retval, measure2, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, ref_point_subt_temp[1])
          if measure2 < first_measure + pattern_len then
            table.insert(ref_points_t2, {(retval+measure2*cml)-first_measure*cml, ref_point_subt_temp[2]})
          end  
        end
        -- add edges
        if pat_edge_values_t[1] == 1 then
          table.insert(ref_points_t2, {0, 1})
          table.insert(ref_points_t2, {pattern_len*cml, 1})
        end
        -- generate grid from ref_points_t2
        ref_points_t = {}
        for i=1, last_measure+8, pattern_len do          
          for j=1, #ref_points_t2 do
            ref_points_t2_subt = ref_points_t2[j]            
            ref_pos_time = reaper.TimeMap2_beatsToTime(0, ref_points_t2_subt[1], i-1)
            if ref_points_t2_subt[1] > cml then
              ref_pos_time = reaper.TimeMap2_beatsToTime(0, ref_points_t2_subt[1] - cml, i-1)
            end  
            table.insert(ref_points_t, {ref_pos_time, ref_points_t2_subt[2]} )
          end  
        end        
     end
 end 
   
 ---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------
 
function GET_project_len()
  positions_of_objects_t = {}
  count_tracks = reaper.CountTracks(0)
  if count_tracks ~= nil then    
    for i = 1, count_tracks, 1 do
      track = reaper.GetTrack(0, i-1)
      track_guid = reaper.BR_GetMediaTrackGUID(track)
      if track~= nil then
        count_envelopes = reaper.CountTrackEnvelopes(track)
        if count_envelopes ~= nil then
          for j = 1, count_envelopes, 1 do
            TrackEnvelope = reaper.GetTrackEnvelope(track, j-1)      
            if TrackEnvelope ~= nil then
              count_env_points = reaper.CountEnvelopePoints(TrackEnvelope)              
              if count_env_points ~= nil then 
                for k = 1, count_env_points, 1 do  
                  retval, position = reaper.GetEnvelopePoint(TrackEnvelope, k-1)                   
                  table.insert(positions_of_objects_t, position)
                end
              end  
            end
          end
        end  
      end
    end  
  end
  
  count_items = reaper.CountMediaItems(0) 
  if count_items ~= nil then   -- get measures beetween items
    for i = 1, count_items, 1 do
      item = reaper.GetMediaItem(0, i-1)          
      item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") 
      item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")   
      item_end = item_pos + item_len
      table.insert(positions_of_objects_t, item_end)  
    end 
  end  
  
  table.sort(positions_of_objects_t)
  i_max = #positions_of_objects_t
  max_object_position = positions_of_objects_t[i_max]
  retval, measuresOut, cml = reaper.TimeMap2_timeToBeats(0, max_object_position)
  max_object_position = reaper.TimeMap2_beatsToTime(0, 0, measuresOut)
  if max_object_position == nil then max_object_position = 0 end
end
  
 ---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------
   
 function ENGINE2_get_dest_items()
  dest_items_t = {}
  dest_items_subt = {}
  count_sel_items = reaper.CountSelectedMediaItems(0)
  if count_sel_items ~= nil then     
    for i = 1, count_sel_items, 1 do
      item = reaper.GetSelectedMediaItem(0, i-1)
      item_guid = reaper.BR_GetMediaItemGUID(item) 
      item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      item_vol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
      dest_items_subt = {item_guid, item_pos, item_vol}
      table.insert(dest_items_t, dest_items_subt)
    end
  return #dest_items_t
  end  
 end 

 ---------------------------------------------------------------------------------------------------------------
  
 function ENGINE2_get_dest_sm()
  dest_sm_t = {}
  dest_sm_subt = {} 
  count_sel_items = reaper.CountSelectedMediaItems(0)
  if count_sel_items ~= nil then 
    count_stretch_markers_com = 0
    for i = 1, count_sel_items, 1 do
      item = reaper.GetSelectedMediaItem(0, i-1) 
      if item ~= nil then   
        item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")    
        take = reaper.GetActiveTake(item)      
        if take ~= nil then
          if reaper.TakeIsMIDI(take) == false then          
            take_guid = reaper.BR_GetMediaItemTakeGUID(take)
            takerate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")                    
            count_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
            if count_stretch_markers ~= nil then
              for j = 1, count_stretch_markers,1 do
                retval, posOut, srcpos = reaper.GetTakeStretchMarker(take, j-1)
                dest_sm_subt = {take_guid, posOut, srcpos, item_pos, takerate, item_len}
                if posOut ~= 0 or posOut ~= item_len then
                  table.insert(dest_sm_t, dest_sm_subt)
                end  
              end -- loop takes  
            end -- count_stretch_markers ~= nil 
          end  
        end -- take ~= nil  
      end 
    end -- item loop
  return #dest_sm_t   
  end -- count_sel_items ~= nil
 end 
 
 ---------------------------------------------------------------------------------------------------------------
  
 function ENGINE2_get_dest_ep()
  dest_ep_t = {}
  dest_ep_subt = {}
  
  -- track envelopes --
  count_tracks = reaper.CountTracks(0)
  if count_tracks ~= nil then    
    for i = 1, count_tracks, 1 do
      track = reaper.GetTrack(0, i-1)
      track_guid = reaper.BR_GetMediaTrackGUID(track)
      if track~= nil then
        count_envelopes = reaper.CountTrackEnvelopes(track)
        if count_envelopes ~= nil then
          for env_id = 1, count_envelopes, 1 do
            TrackEnvelope = reaper.GetTrackEnvelope(track, env_id-1)      
            if TrackEnvelope ~= nil then
              count_env_points = reaper.CountEnvelopePoints(TrackEnvelope)
              if count_env_points ~= nil then 
                for point_id = 1, count_env_points, 1 do    
                  retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(TrackEnvelope, point_id-1)
                  if selected == true then                  
                     dest_ep_subt = {true, track_guid, env_id, point_id, time, value, shape, tension, selected}
                     table.insert(dest_ep_t, dest_ep_subt)
                  end
                end -- loop env points  
              end  -- count_env_points ~= nil  
            end -- TrackEnvelope ~= nil
          end -- loop enelopes
        end -- count_envelopes ~= nil  
      end -- track~= nil
    end  -- loop count_tracks
  end -- count_tracks ~= nil  
  
  -- take envelopes --
  count_items = reaper.CountSelectedMediaItems(0)
  if count_items ~= nil then
    for i = 1, count_items do
      item = reaper.GetSelectedMediaItem(0, i-1)
      if item ~= nil then
        takescount =  reaper.CountTakes(item)
        if takescount ~= nil then
          for j = 1, takescount do
            take = reaper.GetTake(item, j-1)
            take_guid = reaper.BR_GetMediaItemTakeGUID(take)
            if take ~= nil  then
              count_take_env = reaper.CountTakeEnvelopes(take)
              if count_take_env ~= nil then
                for env_id = 1, count_take_env do
                  TrackEnvelope = reaper.GetTakeEnvelope(take, env_id-1)
                  if TrackEnvelope ~= nil then
                    count_env_points = reaper.CountEnvelopePoints(TrackEnvelope)
                    if count_env_points ~= nil then 
                      for point_id = 1, count_env_points, 1 do    
                        retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(TrackEnvelope, point_id-1)
                        if selected == true then                  
                          dest_ep_subt = {false, take_guid, env_id, point_id, time, value, shape, tension, selected}
                          table.insert(dest_ep_t, dest_ep_subt)
                        end
                      end -- loop env points  
                    end  -- count_env_points ~= nil  
                  end -- TrackEnvelope ~= nil
                end  
              end
            end
          end
        end
      end
    end
  end
  
  return #dest_ep_t
  
 end  
 
 ---------------------------------------------------------------------------------------------------------------

 function ENGINE2_get_dest_notes() 
  dest_notes_t = {}
  dest_notes_t2 = {} -- for notes count if quant sel only
  dest_notes_subt = {} 
  count_sel_items = reaper.CountSelectedMediaItems(0)
  if count_sel_items ~= nil then   -- get measures beetween items
    for i = 1, count_sel_items, 1 do
      item = reaper.GetSelectedMediaItem(0, i-1)
      if item ~= nil then
        take = reaper.GetActiveTake(item)
        take_guid = reaper.BR_GetMediaItemTakeGUID(take)
        if take ~= nil then
          if reaper.TakeIsMIDI(take) ==  true then   
            retval, notecntOut, ccevtcntOut = reaper.MIDI_CountEvts(take)
              if notecntOut ~= nil then
                for j = 1, notecntOut, 1 do                 
                  retval, selectedOut, mutedOut, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, j-1) 
                  dest_note_pos = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos)                                 
                  dest_notes_subt = {take_guid, selectedOut, mutedOut, startppqpos, endppqpos, chan, pitch, vel, dest_note_pos}                   
                  table.insert(dest_notes_t, dest_notes_subt)  
                  if sel_notes_mode2_values_t[1] == 1 then
                    if selectedOut == true then
                      table.insert(dest_notes_t2, dest_notes_subt)
                    end  
                  end
                  if sel_notes_mode2_values_t[2] == 1 then
                    table.insert(dest_notes_t2, dest_notes_subt) 
                  end                  
                end -- count notes                   
              end -- notecntOut > 0
            end -- TakeIsMIDI
          end -- ref_take ~= nil 
        end-- ref_item ~= nil
      end -- for count_sel_ref_items
    end --   count_sel_ref_items > 0   
  return #dest_notes_t2
 end 
     
 ---------------------------------------------------------------------------------------------------------------

 function ENGINE2_get_dest_FORM_points()
 
   -- ONLY FOR GUI --
   
   dest_points_t = {} 
   
     -- items --
     if quantize_dest_values_t[1] == 1 and dest_items_t ~= nil then     
       for i = 1, #dest_items_t do
         table_temp_val_sub_t = dest_items_t[i]         
         table.insert (dest_points_t, i, {table_temp_val_sub_t[2], table_temp_val_sub_t[3]})         
       end
     end     
     
     -- sm --
     if quantize_dest_values_t[2] == 1 then     
       for i = 1, #dest_sm_t do
         table_temp_val = dest_sm_t[i]
         --take_guid, posOut, srcpos, item_pos, takerate         
         table.insert (dest_points_t, {table_temp_val[4] + (table_temp_val[2]/table_temp_val[5]), 1} )
       end
     end     
     
     -- ep --
     if quantize_dest_values_t[3] == 1 then     
       for i = 1, #dest_ep_t do
         table_temp_val = dest_ep_t[i]
         -- istrackenvelope, track_guid, env_id, point_id, time, value, shape, tension, selected
         table.insert (dest_points_t, {table_temp_val[5], table_temp_val[6]})
       end
     end
     
     -- notes --
     if quantize_dest_values_t[4] == 1 then     
       for i = 1, #dest_notes_t do
         table_temp_val = dest_notes_t[i]
         -- take_guid, selectedOut, mutedOut, startppqpos, endppqpos, chan, pitch, vel, dest_note_pos
         if sel_notes_mode2_values_t[1] == 1 then
           if table_temp_val[2] == true then
             table.insert (dest_points_t, {table_temp_val[9], table_temp_val[8]/127})
           end  
         end  
         if sel_notes_mode2_values_t[2] == 1 then
           table.insert (dest_points_t, {table_temp_val[9], table_temp_val[8]/127})
         end           
       end
     end   
                 
     --[[ grid --
     if quantize_ref_values_t[5] == 1 then     
       for i = 1, #ref_grid_t do
         table_temp_val = ref_grid_t[i] 
         table.insert (ref_points_t, i, table_temp_val)
       end
     end
     
     -- swing --
     if quantize_ref_values_t[6] == 1 then     
       for i = 1, #ref_swing_grid_t do
         table_temp_val = ref_swing_grid_t[i]
         table.insert (ref_points_t, i, table_temp_val)
       end
     end]]
     
 end 
 
 ---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------
 function ENGINE3_quantize_compare_sub(pos, vol, points_t)
 
      if points_t ~= nil then        
        for i = 1, #points_t do
                
          cur_ref_point_subt = points_t[i]          
          if i < #points_t then next_ref_point_subt = points_t[i+1] else next_ref_point_subt = nil end      
          
        -- perform comparison
        
          if snap_dir_values_t[1] == 1 then -- if snap to prev point
            if pos < cur_ref_point_subt[1] and i == 1 then 
              newval2 = {pos,vol} end
            if next_ref_point_subt ~= nil then if pos > cur_ref_point_subt[1] and pos < next_ref_point_subt[1]  then 
              newval2 = {cur_ref_point_subt[1],cur_ref_point_subt[2]} end end
            if pos > cur_ref_point_subt[1] and next_ref_point_subt == nil then 
              newval2 = {cur_ref_point_subt[1],cur_ref_point_subt[2]} end
          end   
                             
          if snap_dir_values_t[2] == 1 then -- if snap to closest point
            if pos < cur_ref_point_subt[1] and i == 1 then 
              newval2 = {cur_ref_point_subt[1],cur_ref_point_subt[2]} end
            if next_ref_point_subt ~= nil then   
              if pos > cur_ref_point_subt[1] and pos < next_ref_point_subt[1] and pos < cur_ref_point_subt[1] + (next_ref_point_subt[1] - cur_ref_point_subt[1])/2 then 
                newval2 = {cur_ref_point_subt[1],cur_ref_point_subt[2]} end
              if pos > cur_ref_point_subt[1] and pos < next_ref_point_subt[1] and pos > cur_ref_point_subt[1] + (next_ref_point_subt[1] - cur_ref_point_subt[1])/2 then 
                newval2 = {next_ref_point_subt[1],next_ref_point_subt[2]} end
            end  
            if pos > cur_ref_point_subt[1] and next_ref_point_subt == nil then 
              newval2 = {cur_ref_point_subt[1],cur_ref_point_subt[2]} end
          end
        
          if snap_dir_values_t[3] == 1 then -- if snap to next point
            if pos < cur_ref_point_subt[1] and i == 1 then 
              newval2 = {cur_ref_point_subt[1],cur_ref_point_subt[2]} end            
            if next_ref_point_subt ~= nil then if pos > cur_ref_point_subt[1] and pos < next_ref_point_subt[1] then 
              newval2 = {next_ref_point_subt[1],next_ref_point_subt[2]} end   end   
            if pos > cur_ref_point_subt[1] and next_ref_point_subt == nil then 
              newval2 = {pos,vol} end 
          end
        
        end -- for
      end -- if ref_point_t~= nil
      return newval2
   end   
      
 ---------------------------------------------------------------------------------------------------------------       
 
  function ENGINE3_quantize_compare(pos,vol)    
    newval = nil
    if snap_area_values_t[1] == 1 then -- if use gravity      
      pos_gravity_min = pos - gravity_mult_value*gravity_value if pos_gravity_min < 0 then pos_gravity_min = 0 end
      pos_gravity_max = pos + gravity_mult_value*gravity_value
      ref_points_t2 = {} -- store all points which is placed inside gravity area
      if ref_points_t ~= nil then        
        for i = 1, #ref_points_t do      
          cur_ref_point_subt = ref_points_t[i]
          if cur_ref_point_subt[1] >= pos_gravity_min and cur_ref_point_subt[1] <= pos_gravity_max then
            table.insert(ref_points_t2, {cur_ref_point_subt[1],cur_ref_point_subt[2]})
          end
        end
      end  
      if ref_points_t2 ~= nil and #ref_points_t2 >= 1 then
        newval = ENGINE3_quantize_compare_sub (pos,vol,ref_points_t2)
      end
    end
    
    if snap_area_values_t[2] == 1 then -- if snap everything
      newval = ENGINE3_quantize_compare_sub (pos,vol,ref_points_t)
    end -- if snap everything
    
    if newval ~= nil then 
      pos_ret = newval[1] 
      pos_ret = pos - (pos - newval[1]) * strenght_value
      if newval[2] ~= nil then 
        vol_ret = newval[2] 
        vol_ret = vol - (vol - newval[2]) * use_vel_value
       else
        vol_ret = vol
      end  
     else 
      pos_ret = pos
      vol_ret = vol  
    end
    return pos_ret, vol_ret
  end
     
 ---------------------------------------------------------------------------------------------------------------
  
  function ENGINE3_quantize_objects()    
    -------------------------------------------------------------------------------------
    --  items --------------------------------------------------------------------------
    -------------------------------------------------------------------------------------
    if quantize_dest_values_t[1] == 1 then 
    
     --  restore items pos and vol --
      if dest_items_t ~= nil then
        for i = 1, #dest_items_t do
          dest_items_subt = dest_items_t[i]
          item = reaper.BR_GetMediaItemByGUID(0, dest_items_subt[1])
          if item ~= nil then
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", dest_items_subt[2])
            reaper.SetMediaItemInfo_Value(item, "D_VOL", dest_items_subt[3])
          end
        end
      end      
      -- quantize items pos and vol --
      if dest_items_t ~= nil and restore_button_state == false then
        for i = 1, #dest_items_t do
          dest_items_subt = dest_items_t[i]
          item = reaper.BR_GetMediaItemByGUID(0, dest_items_subt[1])
          if item ~= nil then
            item_newpos, item_newvol = ENGINE3_quantize_compare(dest_items_subt[2],dest_items_subt[3])
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", item_newpos)
            reaper.SetMediaItemInfo_Value(item, "D_VOL", item_newvol)
          end
          reaper.UpdateItemInProject(item)
        end
      end
    end -- if quantize items  
    
    -----------------------------------------------------------------------------
    -- stretch markers ----------------------------------------------------------
    -----------------------------------------------------------------------------
    if quantize_dest_values_t[2] == 1 then 
    --dest sm
    --1take_guid, 2posOut, 3srcpos, 4item_pos, 5takerate, 6item_len
    
    --restore
      --delete all in current take
      --insert from table
    --apply in bypass is off
      --delete all in current take
      --quantize when inserting from table
      --  delete notes from dest takes --
      
    -- restore  
      if dest_sm_t ~= nil then
        for i = 1, #dest_sm_t do
          dest_sm_subt = dest_sm_t[i]  
          take = reaper.GetMediaItemTakeByGUID(0,dest_sm_subt[1])
          if take ~= nil then  
            count_sm = reaper.GetTakeNumStretchMarkers(take)
            if count_sm ~= nil then
              for j = 1 , count_sm do
                reaper.DeleteTakeStretchMarkers(take, j-1)
              end
            end            
          end  
        end
      end   
      if dest_sm_t ~= nil then
        for i = 1, #dest_sm_t do
          dest_sm_subt = dest_sm_t[i]  
          take = reaper.GetMediaItemTakeByGUID(0,dest_sm_subt[1])
          if take ~= nil then  
            reaper.SetMediaItemTakeInfo_Value(take, 'D_PLAYRATE', dest_sm_subt[5])
            reaper.SetTakeStretchMarker(take, -1, dest_sm_subt[2], dest_sm_subt[3])            
          end  
        end
      end 
      
      --quant stretch markers    
      if dest_sm_t ~= nil and restore_button_state == false then
        for i = 1, #dest_sm_t do
          dest_sm_subt = dest_sm_t[i]  
          take = reaper.GetMediaItemTakeByGUID(0,dest_sm_subt[1])
          if take ~= nil then  
            count_sm = reaper.GetTakeNumStretchMarkers(take)
            if count_sm ~= nil then
              for j = 1 , count_sm do
                reaper.DeleteTakeStretchMarkers(take, j-1)
              end
            end            
          end  
        end
      end
         
      if dest_sm_t ~= nil and restore_button_state == false then
        for i = 1, #dest_sm_t do
          dest_sm_subt = dest_sm_t[i]  
          take = reaper.GetMediaItemTakeByGUID(0,dest_sm_subt[1])
          if take ~= nil then 
            --1take_guid, 2posOut, 3srcpos, 4item_pos, 5takerate, 6item_len
            reaper.SetTakeStretchMarker(take, -1, 0, 0)
            reaper.SetTakeStretchMarker(take, -1, dest_sm_subt[6], dest_sm_subt[6])  
            reaper.SetMediaItemTakeInfo_Value(take, 'D_PLAYRATE', dest_sm_subt[5])            
            true_sm_pos = dest_sm_subt[4] + dest_sm_subt[2]/ dest_sm_subt[5]
            new_sm_pos = ENGINE3_quantize_compare(true_sm_pos,0)
            new_sm_pos_rev = (new_sm_pos - dest_sm_subt[4])*dest_sm_subt[5]            
            if new_sm_pos > 0 and dest_sm_subt[3] > 0 then
              reaper.SetTakeStretchMarker(take, -1, new_sm_pos_rev, dest_sm_subt[3])            
            end  
          end 
          item = reaper.GetMediaItemTake_Item(take) 
          reaper.UpdateItemInProject(item)
        end
      end 
           
    end
    -----------------------------------------------------------------------------
    -- points -------------------------------------------------------------------
    -----------------------------------------------------------------------------
    
    if quantize_dest_values_t[3] == 1 then 
      --  restore point pos and val --
      if dest_ep_t ~= nil then
        for i = 1, #dest_ep_t do
          dest_ep_subt = dest_ep_t[i]
          -- 1 is_track_env, 2 guid, 3 env_id, 4 point_id, 5 time, 6 value, 7 shape, 8 tension, 9  selected
          if dest_ep_subt[1] == true then -- if point of track envelope
            track = reaper.BR_GetMediaTrackByGUID(0, dest_ep_subt[2])
            if track ~= nil then TrackEnvelope = reaper.GetTrackEnvelope(track, dest_ep_subt[3]-1) end  end
          if dest_ep_subt[1] == false then -- if point of take envelope
            take = reaper.SNM_GetMediaItemTakeByGUID(0, dest_ep_subt[2])
            if take ~= nil then TrackEnvelope = reaper.GetTakeEnvelope(take, dest_ep_subt[3]-1) end end
          if  TrackEnvelope ~= nil then
            reaper.SetEnvelopePoint(TrackEnvelope, dest_ep_subt[4]-1, dest_ep_subt[5], dest_ep_subt[6], 
            dest_ep_subt[7], dest_ep_subt[8], dest_ep_subt[9], true)   
          end         
        end
        -- sort envelopes
        for i = 1, #dest_ep_t do
          dest_ep_subt = dest_ep_t[i]
          if dest_ep_subt[1] == true then track = reaper.BR_GetMediaTrackByGUID(0, dest_ep_subt[2])
            if track ~= nil then TrackEnvelope = reaper.GetTrackEnvelope(track, dest_ep_subt[3]-1) reaper.Envelope_SortPoints (TrackEnvelope) end end
          if dest_ep_subt[1] == false then -- if point of take envelope
            take = reaper.SNM_GetMediaItemTakeByGUID(0, dest_ep_subt[2])
            if take ~= nil then TrackEnvelope = reaper.GetTakeEnvelope(take, dest_ep_subt[3]-1) reaper.Envelope_SortPoints(TrackEnvelope) end end          
        end  
      end   
      -- quantize envpoints pos and values --
      if dest_ep_t ~= nil and restore_button_state == false then
        for i = 1, #dest_ep_t do
          dest_ep_subt = dest_ep_t[i]
          -- 1 is_track_env, 2 guid, 3 env_id, 4 point_id, 5 time, 6 value, 7 shape, 8 tension, 9  selected
          if dest_ep_subt[1] == true then -- if point of track envelope
            track = reaper.BR_GetMediaTrackByGUID(0, dest_ep_subt[2])
            if track ~= nil then TrackEnvelope = reaper.GetTrackEnvelope(track, dest_ep_subt[3]-1) end  end
          if dest_ep_subt[1] == false then -- if point of take envelope
            take = reaper.SNM_GetMediaItemTakeByGUID(0, dest_ep_subt[2])
            if take ~= nil then TrackEnvelope = reaper.GetTakeEnvelope(take, dest_ep_subt[3]-1) end end
          if  TrackEnvelope ~= nil then              
            ep_newpos, ep_newvol = ENGINE3_quantize_compare(dest_ep_subt[5], dest_ep_subt[6])
            reaper.SetEnvelopePoint(TrackEnvelope, dest_ep_subt[4]-1, ep_newpos, ep_newvol, 
            dest_ep_subt[7], dest_ep_subt[8], dest_ep_subt[9], true)
          end         
        end
      end  
      -- sort envelopes
        for i = 1, #dest_ep_t do
          dest_ep_subt = dest_ep_t[i]
          if dest_ep_subt[1] == true then track = reaper.BR_GetMediaTrackByGUID(0, dest_ep_subt[2])
            if track ~= nil then TrackEnvelope = reaper.GetTrackEnvelope(track, dest_ep_subt[3]-1) reaper.Envelope_SortPoints (TrackEnvelope) end end
          if dest_ep_subt[1] == false then -- if point of take envelope
            take = reaper.SNM_GetMediaItemTakeByGUID(0, dest_ep_subt[2])
            if take ~= nil then TrackEnvelope = reaper.GetTakeEnvelope(take, dest_ep_subt[3]-1) reaper.Envelope_SortPoints(TrackEnvelope) end end          
        end    
    end
    
    
    ----------------------------------------------------------------------------
    -- notes -------------------------------------------------------------------
    ----------------------------------------------------------------------------
    
    if quantize_dest_values_t[4] == 1 then 
    
      --RESTORE--
      
      --  delete notes from dest takes --
      if dest_notes_t ~= nil then
        for i = 1, #dest_notes_t do
          dest_notes_subt = dest_notes_t[i]
          --1take_guid, 2selectedOut, 3mutedOut, 4startppqpos, 5endppqpos, 6chan, 7pitch, 8vel, 9dest_note_pos  
          take = reaper.GetMediaItemTakeByGUID(0,dest_notes_subt[1])
          if take ~= nil then          
            -- delete notes from take
            retval, notecnt = reaper.MIDI_CountEvts(take)
            if notecntOut ~= nil then
              for j = 1, notecnt do
                reaper.MIDI_DeleteNote(take, 0)
                reaper.MIDI_Sort(take)
              end
            end 
          end  
        end
      end       
      --insert notes
      if quantize_dest_values_t[4] == 1 then 
        --  Insert notes   --
        if dest_notes_t ~= nil then
          for i = 1, #dest_notes_t do
            dest_notes_subt = dest_notes_t[i]
            --1take_guid, 2selectedOut, 3mutedOut, 4startppqpos, 5endppqpos, 6chan, 7pitch, 8vel, 9dest_note_pos  
            take = reaper.GetMediaItemTakeByGUID(0,dest_notes_subt[1])
            if take ~= nil then  
              reaper.MIDI_InsertNote(take, dest_notes_subt[2], dest_notes_subt[3], dest_notes_subt[4], dest_notes_subt[5], 
                dest_notes_subt[6], dest_notes_subt[7], dest_notes_subt[8], true)
            end 
            reaper.MIDI_Sort(take)
          end           
        end       
      end       
      
      --END RESTORE notes--
    if dest_notes_t ~= nil and restore_button_state == false then
      --  delete notes from dest takes --
      if dest_notes_t ~= nil then
        for i = 1, #dest_notes_t do
          dest_notes_subt = dest_notes_t[i]
          --1take_guid, 2selectedOut, 3mutedOut, 4startppqpos, 5endppqpos, 6chan, 7pitch, 8vel, 9dest_note_pos  
          take = reaper.GetMediaItemTakeByGUID(0,dest_notes_subt[1])
          if take ~= nil then          
            -- delete notes from take
            retval, notecnt = reaper.MIDI_CountEvts(take)
            if notecntOut ~= nil then
              for j = 1, notecnt do
                reaper.MIDI_DeleteNote(take, 0)
                reaper.MIDI_Sort(take)
              end
            end 
          end  
        end
      end  
      --insert
      for i = 1, #dest_notes_t do
        dest_notes_subt = dest_notes_t[i]
        --1take_guid, 2selectedOut, 3mutedOut, 4startppqpos, 5endppqpos, 6chan, 7pitch, 8vel, 9dest_note_pos ,10 1-based noteid    
        take = reaper.GetMediaItemTakeByGUID(0,dest_notes_subt[1])
        if take ~= nil then
          ppq_dif = dest_notes_subt[5] - dest_notes_subt[4]
          
          
          if sel_notes_mode2_values_t[1] == 1 then
            if dest_notes_subt[2] == true then
              notes_newpos, notes_newvol = ENGINE3_quantize_compare(dest_notes_subt[9], dest_notes_subt[8]/127)
             else
              notes_newpos = dest_notes_subt[9]
              notes_newvol = dest_notes_subt[8]/127
            end 
          end
          if sel_notes_mode2_values_t[2] == 1 then
            notes_newpos, notes_newvol = ENGINE3_quantize_compare(dest_notes_subt[9], dest_notes_subt[8]/127)
          end
          notes_newpos_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, notes_newpos)-1
          reaper.MIDI_InsertNote(take, dest_notes_subt[2], dest_notes_subt[3], notes_newpos_ppq, notes_newpos_ppq+ppq_dif, 
          dest_notes_subt[6], dest_notes_subt[7], math.ceil(notes_newvol*127), false)
          reaper.MIDI_Sort(take)
        end  
      end    
    end --dest_notes_t ~= nil and restore_button_state == false  
   end     --if quantize_dest_values_t[4] == 1 then 
  end -- func
     
 ---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------
      
 function MOUSE_click_under_gui_rect (object_coord_t, offset)
 
   x = object_coord_t[1+offset]
   y = object_coord_t[2+offset]
   w = object_coord_t[3+offset]
   h = object_coord_t[4+offset]
   
   if value_state == nil then value_state = false end
   
   if gfx.mouse_cap == 1 
      and mx > x
      and mx < x + w
      and my > y 
      and my < y + h 
      and mouse_state == nil 
      and value_state == false
       then         
         value_state = true
         mouse_state = true
   end   
   
   if gfx.mouse_cap == 1 
      and mx > x
      and mx < x + w
      and my > y 
      and my < y + h 
      and mouse_state == nil 
      and value_state == true
       then         
         value_state = false
         mouse_state = true
   end
   
   if gfx.mouse_cap&1 == 0 
      and mx > x
      and mx < x + w
      and my > y 
      and my < y + h then mouse_state = nil end   
     return value_state   
 end   
 
---------------------------------------------------------------------------------------------------------------
    
 function MOUSE_RB_clickhold_under_gui_rect (object_coord_t, offset) 
  if gfx.mouse_cap == 2 then RB_DOWN = 1 else RB_DOWN = 0 end   
  x = object_coord_t[1+offset]
  y = object_coord_t[2+offset]
  w = object_coord_t[3+offset]
  h = object_coord_t[4+offset]
  if RB_DOWN == 1
   and mx > x
   and mx < x + w
   and my > y 
   and my < y + h then       
    return true
  end  
 end 
     
---------------------------------------------------------------------------------------------------------------
    
 function MOUSE_clickhold_under_gui_rect (object_coord_t, offset) 
  if gfx.mouse_cap == 1 then LB_DOWN = 1 else LB_DOWN = 0 end   
  x = object_coord_t[1+offset]
  y = object_coord_t[2+offset]
  w = object_coord_t[3+offset]
  h = object_coord_t[4+offset]
  if LB_DOWN == 1
   and mx > x
   and mx < x + w
   and my > y 
   and my < y + h then       
    return true
  end  
 end  
 
 --------------------------------------------------------------------------------------------------------------- 
    
 function MOUSE_get() 
   mx, my = gfx.mouse_x, gfx.mouse_y
   if project_grid_measures < 1 then   
     options_button_state = MOUSE_click_under_gui_rect(options_button_xywh_t,0)   
   
   if options_button_state == false then
   
     --------------------
     ----- MAIN PAGE ----
     --------------------  
     
     ------------------------------
     ----- GET REFERENCE MENU -----
     ------------------------------
     
   if snap_mode_values_t[2] == 1 then 
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,0) == true then 
       quantize_ref_values_t = {1, 0, 0, 0, 0, 0} 
       count_reference_item_positions = ENGINE1_get_reference_item_positions() 
       ENGINE1_get_reference_FORM_points()end
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,4) == true then 
       quantize_ref_values_t = {0, 1, 0, 0, 0, 0} 
       count_reference_sm_positions = ENGINE1_get_reference_SM_positions() 
       ENGINE1_get_reference_FORM_points() end
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,8) == true then 
       quantize_ref_values_t = {0, 0, 1, 0, 0, 0} 
       count_reference_ep_positions = ENGINE1_get_reference_EP_positions() 
       ENGINE1_get_reference_FORM_points() end
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,12) == true then 
       quantize_ref_values_t = {0, 0, 0, 1, 0, 0} 
       count_reference_notes_positions = ENGINE1_get_reference_notes_positions() 
       ENGINE1_get_reference_FORM_points() end  
           -- grid --
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,16) == true or 
        MOUSE_clickhold_under_gui_rect(grid_value_slider_xywh_t, 0) == true then 
       quantize_ref_values_t = {0, 0, 0, 0, 1, 0}
       display_grid_value_slider = true
       if grid_value_slider_xywh_t ~= nil then grid_value = (mx - grid_value_slider_xywh_t[1])/grid_value_slider_xywh_t[3] end
       ENGINE1_get_reference_grid()
       ENGINE1_get_reference_FORM_points() 
      else
       display_grid_value_slider = false
     end
           -- swing --
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,20) == true or 
        MOUSE_clickhold_under_gui_rect(swing_grid_value_slider_xywh_t, 0) == true then 
        quantize_ref_values_t = {0, 0, 0, 0, 0, 1} 
        display_swing_value_slider = true
        if swing_grid_value_slider_xywh_t ~= nil then swing_value = ((mx - swing_grid_value_slider_xywh_t[1])/swing_grid_value_slider_xywh_t[3])*2-1 end
        ENGINE1_get_reference_swing_grid()
        ENGINE1_get_reference_FORM_points()
        ENGINE3_quantize_objects()
      else
        display_swing_value_slider = false
     end -- lb mouse on swing
     
     if MOUSE_RB_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,20) == true then
       swing_value_retval, swing_value_return_s =  reaper.GetUserInputs("Swing value", 1, "Swing", "") 
       if swing_value_retval ~= nil then 
         swing_value_return = tonumber(swing_value_return_s)           
         if swing_value_return == nil then swing_value = 0 else swing_value = swing_value_return / 100 end       
         if swing_value > 1 then swing_value = 1 end
         if swing_value < -1 then swing_value = -1 end
         ENGINE1_get_reference_swing_grid()
         ENGINE1_get_reference_FORM_points() 
       end 
     end -- rb mouse on swing   
   else
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,0) == true then 
       quantize_ref_values_t = {1, 0, 0, 0} 
       count_reference_item_positions = ENGINE1_get_reference_item_positions() 
       ENGINE1_get_reference_FORM_points() end
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,4) == true then 
       quantize_ref_values_t = {0, 1, 0, 0} 
       count_reference_sm_positions = ENGINE1_get_reference_SM_positions() 
       ENGINE1_get_reference_FORM_points() end
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,8) == true then 
       quantize_ref_values_t = {0, 0, 1, 0} 
       count_reference_ep_positions = ENGINE1_get_reference_EP_positions() 
       ENGINE1_get_reference_FORM_points() end
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,12) == true then 
       quantize_ref_values_t = {0, 0, 0, 1} 
       count_reference_notes_positions = ENGINE1_get_reference_notes_positions() 
       ENGINE1_get_reference_FORM_points() end                
  end
    
     ------------------------------
     -------- GET DEST MENU -------
     ------------------------------
     
     if MOUSE_clickhold_under_gui_rect(quantize_dest_xywh_buttons_t,0) == true then 
       quantize_dest_values_t = {1, 0, 0, 0} 
       count_dest_item_positions = ENGINE2_get_dest_items() 
       ENGINE2_get_dest_FORM_points() end
     if MOUSE_clickhold_under_gui_rect(quantize_dest_xywh_buttons_t,4) == true then 
       quantize_dest_values_t = {0, 1, 0, 0} 
       count_dest_sm_positions = ENGINE2_get_dest_sm() 
       ENGINE2_get_dest_FORM_points() end
     if MOUSE_clickhold_under_gui_rect(quantize_dest_xywh_buttons_t,8) == true then 
       quantize_dest_values_t = {0, 0, 1, 0} 
       count_dest_ep_positions = ENGINE2_get_dest_ep()  
       ENGINE2_get_dest_FORM_points()   end
     if MOUSE_clickhold_under_gui_rect(quantize_dest_xywh_buttons_t,12) == true then 
       quantize_dest_values_t = {0, 0, 0, 1} 
       count_dest_notes_positions = ENGINE2_get_dest_notes() 
       ENGINE2_get_dest_FORM_points() end 
     
     -- APPLY BUTTON / SLIDER --
     if MOUSE_clickhold_under_gui_rect(apply_slider_xywh_t,0) == true then 
       strenght_value = (mx - apply_slider_xywh_t[1])/apply_slider_xywh_t[3]*2
       if strenght_value >1 then strenght_value = 1 end
       ENGINE3_quantize_objects()
     end 
     
     -- restore BUTTON --  
     if MOUSE_RB_clickhold_under_gui_rect(apply_slider_xywh_t,0) == true then 
       restore_button_state = true 
       ENGINE3_quantize_objects()
      else  
       restore_button_state = false 
     end
       
   end
   
     -------------------------
     ----- OPTIONS PAGE -----
     ------------------------- 
     
   if options_button_state == true then
   
     ----- SNAP MODE MENU -----
     if snap_mode_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(snap_mode_xywh_buttons_t,0) == true then snap_mode_values_t = {1, 0} quantize_ref_values_t = {0, 0, 0, 0} end
       if MOUSE_clickhold_under_gui_rect(snap_mode_xywh_buttons_t,4) == true then snap_mode_values_t = {0, 1} quantize_ref_values_t = {0, 0, 0, 0, 1, 0} end
     end  
     ----- PATTERN LENGTH -----
     if pat_len_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(pat_len_xywh_buttons_t,0) == true then pat_len_values_t = {1, 0, 0} ENGINE2_get_dest_FORM_points() end
       if MOUSE_clickhold_under_gui_rect(pat_len_xywh_buttons_t,4) == true then pat_len_values_t = {0, 1, 0} ENGINE2_get_dest_FORM_points() end
       if MOUSE_clickhold_under_gui_rect(pat_len_xywh_buttons_t,8) == true then pat_len_values_t = {0, 0, 1} ENGINE2_get_dest_FORM_points() end
     end      
     ----- PATTERN EDGE -----
     if pat_edge_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(pat_edge_xywh_buttons_t,0) == true then pat_edge_values_t = {1, 0} ENGINE2_get_dest_FORM_points() end
       if MOUSE_clickhold_under_gui_rect(pat_edge_xywh_buttons_t,4) == true then pat_edge_values_t = {0, 1} ENGINE2_get_dest_FORM_points() end
     end      
     ----- USE VELOCITY ------       
     if use_vel_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(use_vel_xywh_buttons_t,0) == true then use_vel_values_t = {1, 0} end
       if MOUSE_clickhold_under_gui_rect(use_vel_xywh_buttons_t,4) == true then use_vel_values_t = {0, 1} end
     end  
     
     if use_vel_slider_xywh_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(use_vel_slider_xywh_t,0) == true then 
         use_vel_value = (mx - use_vel_slider_xywh_t[1])/use_vel_slider_xywh_t[3]*2 
         if use_vel_value > 1 then use_vel_value = 1 end
         ENGINE3_quantize_objects()
       end      
      end 
     ------ USE NOTES ------      
     if sel_notes_mode_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(sel_notes_mode_xywh_buttons_t,0) == true then sel_notes_mode_values_t = {1, 0} end
       if MOUSE_clickhold_under_gui_rect(sel_notes_mode_xywh_buttons_t,4) == true then sel_notes_mode_values_t = {0, 1} end
     end      
     
     
       
     ----- SNAP AREA MENU -----
     if snap_area_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(snap_area_xywh_buttons_t,0) == true then snap_area_values_t = {1, 0} end
       if MOUSE_clickhold_under_gui_rect(snap_area_xywh_buttons_t,4) == true then snap_area_values_t = {0, 1} end   
       
      if  gravity_slider_xywh_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(gravity_slider_xywh_t,0) == true then 
         gravity_value = (mx - gravity_slider_xywh_t[1])/gravity_slider_xywh_t[3]*2 
         if gravity_value > 1 then gravity_value = 1 end
         ENGINE3_quantize_objects()
       end 
      end 
     end  
     
     
     ----- SNAP DIR MENU -----
    if snap_area_values_t[2] == 1 then
     if snap_dir_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(snap_dir_xywh_buttons_t,0) == true then snap_dir_values_t = {1,0,0} end
       if MOUSE_clickhold_under_gui_rect(snap_dir_xywh_buttons_t,4) == true then snap_dir_values_t = {0,1,0} end
       if MOUSE_clickhold_under_gui_rect(snap_dir_xywh_buttons_t,8) == true then snap_dir_values_t = {0,0,1} end 
     end  
    end    
    if snap_area_values_t[1] == 1 then snap_dir_values_t = {0,1,0} end
    
     ----- SWING SCALE -----
     if swing_scale_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(swing_scale_xywh_buttons_t,0) == true then 
         swing_scale_values_t = {1,0} swing_scale = 1 end
       if MOUSE_clickhold_under_gui_rect(swing_scale_xywh_buttons_t,4) == true then 
         swing_scale_values_t = {0,1} swing_scale = 0.5 end
     end  
     
     ------ dest NOTES ------      
     if sel_notes_mode2_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(sel_notes_mode2_xywh_buttons_t,0) == true then sel_notes_mode2_values_t = {1, 0} end
       if MOUSE_clickhold_under_gui_rect(sel_notes_mode2_xywh_buttons_t,4) == true then sel_notes_mode2_values_t = {0, 1} end
     end
         
   end -- if options page on
   
   end -- if snap >1
 end
  
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

 function MAIN_exit()
   gfx.quit()
 end
 
 --------------------------------------------------------------------------------------------------------------- 
    
 function MAIN_run()
   GET_project_len()   
   DEFINE_dynamic_variables()   
   GUI_DRAW()   
   MOUSE_get()  
   reaper.UpdateArrange()    
   test_var(test)
   if gfx.getchar() == 27 then MAIN_exit() end
   if gfx.getchar() ~= -1 then reaper.defer(MAIN_run) else MAIN_exit() end
 end 
 
 main_w = 440
 main_h = 435
 gfx.init("Quantize tool // ".."Version "..vrs, main_w, main_h)
 reaper.atexit(MAIN_exit) 
 
 DEFINE_default_variables()
 DEFINE_default_variables_GUI()  
 MAIN_run()
  
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
  
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 --[[ 
function oldGUI_fill_slider(object_coord_t, var, center, a2)
  a1 = 0.2
  if a2 == nil then a2 = 0.3  end
  x = object_coord_t[1]
  y = object_coord_t[2]
  w = object_coord_t[3]
  h = object_coord_t[4]
  gfx.a = show_gui_help
  gfx.roundrect(x, y, w, h,0.1,true)
  if center == false then
    gfx.r, gfx.g, gfx.b = 1, 1, 1  
    gfx.x = x
    y1 = y + h
    for i = 1, w*var/100, 1 do 
      a = math.abs(math.abs(i/w*var/100 - 1) - 1) * a2
      gfx.a = a
      gfx.line(x+i,y, x+i, y1) 
    end    
    gfx.a = a1         
   else   
    gfx.r, gfx.g, gfx.b = 1, 1, 1      
    gfx.x = x
    y1 = y + h
    for i = 1, w*var/250, 1 do 
     a = math.abs(i*10/w/2*var/200 - 1) * a2
     gfx.a = a     
     gfx.line(x + w/2+i,y, x + w/2+i, y1) 
    end    
    gfx.a = a1     
    gfx.r, gfx.g, gfx.b = 1, 1, 1      
    gfx.x = x
    y1 = y + h
    for i = 1, w*var/250, 1 do 
    a = math.abs(i*10/w/2*var/200 - 1) * a2
    gfx.a = a     
    gfx.line(x + w/2-i+1,y, x + w/2-i+1, y1) 
    end    
    gfx.a = a1 
  end  
end


---------------------------------------------------------------------------------------------------------------
       
function oldMOUSE_toggleclick_under_gui_rect (object_coord_t, offset, time) 
  if gfx.mouse_cap == 1 then LB_DOWN = 1 else LB_DOWN = 0 end   
  if gfx.mouse_cap == 1 and cur_time  - set_click_time > time  then  
    LB_DOWN = 1
    set_click_time = cur_time
   else 
    LB_DOWN = 0      
  end  
  
  if offset == nil then offset = 0 end
  x = object_coord_t[1+offset]
  y = object_coord_t[2+offset]
  w = object_coord_t[3+offset]
  h = object_coord_t[4+offset]
  if LB_DOWN == 1 -- mouse on swing
   and mx > x
   and mx < x + w
   and my > y 
   and my < y + h then       
    return true
  end  
end 



--reaper.APITest()
--reaper.ShowConsoleMsg("")

]]
