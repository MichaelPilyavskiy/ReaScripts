------  Michael Pilyavskiy Quantize tool  ----


todo= 
[===[ To do list / requested features:
  -- ENGINE1_get_reference_FORM_points() / generate grid from ref_points_t2 for different timesigs
  -- quantize note end
  -- quantize note position only
  -- lmb click on grid add groove point
  -- rmb click on grid delete groove point
  -- prevent transients stretch markers quantize
  -- create objects
  -- getset ref pitch/pan from itemtakes notes and env points  
  
 ]===]  
 
bugs  =
[===[ Expected bugs which could not be fixed for this release: 
  -- io.popen doesn`t work in REAPER x86 http://forum.cockos.com/showthread.php?t=166046
     it is for showing list of user grooves in /reaper/grooves
  -- stretch markers bug: http://forum.cockos.com/project.php?issueid=5647
  -- stretch markers quantize DOES NOT work when Item Loop Source is on
  -- use this script only with 4/4 projects
 ]===]
 
about = [===[Quantize tool by Michael Pilyavskiy

Contacts.
            Soundcloud - http://soundcloud.com/mp57
            PromoDJ -  http://pdj.com/michaelpilyavskiy
            VK -  http://vk.com/michael_pilyavskiy         
            GitHub -  http://github.com/MichaelPilyavskiy/ReaScripts
            ReaperForum - http://forum.cockos.com/member.php?u=70694
         
Donation.
            Russia:
            -- QIWI +79102035901
            -- Yandex Money ID 410013415541705
            -- MasterCard 5189 0100 0686 8799
            
            World:
            -- http://paypal.me/donate2mpl
            
 ]===]
 
 vrs = "1.2 build 3"
 
changelog =                   
[===[
Changelog:
14.09.2015  1.2  build 3
          New
            middle mouse button click on apply slider to set strength value
          Improvements:
            project grid is default, form points on start
            right click on custom grid select/form project grid
            small improvements in pattern mode for project with different tempo (different timesignature still don`t work properly)
          Bugfixes:
            fixed preset system dont store dest str.marker settings
        
13.09.2015  1.1  build 3      
          New: 
            get reference str.marker from selected item/time selection of selected item
            quantize str.marker from selected item/time selection of selected item
            User Groove (import .rgt files for SWS Fingers Groove Tool)
            rmb click on display save current groove to rgt (SWS Fingers Groove Tool) file
            swing value support decimals (only if user type)
            store and recall preset - \REAPER\Scripts\mpl_Quantize_Tool_settings.txt
            set strength/swing/grid via CC and OSC with
              mpl_Quantize_Tool_set_strength.lua
              mpl_Quantize_Tool_set_swing.lua (beetween 0-100%)
              mpl_Quantize_Tool_set_grid.lua
              check in http://github.com/MichaelPilyavskiy/ReaScripts/tree/master/Tools

          Improvements:
            cutted options button (to prevent trigger options page)
            count ref/dest objects
            disable set 'Use Gravity' when choosing destination stretch markers
            Changing global/local mode form relevant mode points and leave previously got points
            Every menu changing also form ref.points or quantize objects to quick preview

          Performance:
            removed display bar lines. -10% CPU
            UpdateArrange() moved to main quantize function: 10%-20% less CPU, depending on how project is big

          Bugfixes: 
            incorrect project/custom grid values
            swing grid tempo bug, project grid tempo bug
            -1 tick midi notes position when quantize/restore
            display issues
            error if project is empty

          Info:
            improved syntax of info strings, thanks to heda!
            donate button
            manual updated           
            
28.08.2015  1.0 
            Public release     
            
23.06.2015  0.01 'swing items' idea
    
 ]===]
 
help1 = 
[===[1. What is it?
It`s LUA script for REAPER. I suppose you to have installed last version of REAPER and SWS/S&M extension (minimum REAPER 5.0 + SWS 2.8.0).

2. What it was created for?It was created because of limitation of REAPER snap/grid settings for main arrangement, especially  around swing grid context. Early times it was small script with simple GUI called "Swing Items". Also there was some limitations in Groove Tool from SWS/S&M extension, which is also very  powerful tool. So, I decided to build something that combines some useful features in case of snap and groove contexts.

3. Disclaimer. This could a very useful stuff. But it is still very rough-coded. So, just don`t forget to save you projects before using this tool.

4. How to use this? Ok there is actually two windows. First window is main and contain one selector for objects you wanna get 'groove points' from and another selector for choosing object you wanna quantize. Second window contains settings and link to information about me and 'readme' info, you watching now.

5. Main window.

5.1.0 Reference section. Here we somehow get 'groove points'. Count of reference points is in parentheses.
5.1.1 Items. To get reference points from items select items in your project and click on 'items'. 
5.1.2 Stretch Markers. To get reference points from stretch markers select items with stretch markers in your project and click on 'stretch markers'.
5.1.3 Envelope Points. To get reference points from envelope points select envelope points in any envelope (as track as take shold works) and click on 'envelope points'. 
5.1.4 Notes. To get reference points from notes select items with notes in your project or open take in midi editor and select notes and click on 'notes'. 
5.1.5 User Groove. Here you can manually type or paste name of SWS Fingers Groove Tool File (without extension). Note, this function is beta state.
5.1.6 Project Grid / Custom Grid - is a slider with grid selector. Project Grid is leftmost value. It is also apply button. Works only in Local (Pattern) mode.
5.1.7 Swing Grid is also a slider / apply button, so can listen what you swing on the fly.

5.2.0 Destination section. Here we store objects and their positions. Note! If you stored object to script by clicking this area, and move it to somewhere (so you manually change position), after every click on any 'Apply' action their positions and volumes will be firstly restored! This done to prevent feedback (store and snap->store and snap once again -> etc). Also count of objects placed  in parentheses
5.2.1 Items. Select items in project you wanna quantize and click 'Items' button. Number of items should be shown in parentheses. 
5.2.2 Stretch markers. Select stretch markers in item you wanna quantize and click 'Stretch markers' button. Also to be clear - be careful with stretch markers, because they could be very buggy and even crash Reaper if you will do something extreme. Of course I will fix something in future, but for now just be carefull and always save your current project state before using!.
5.2.3 Envelope Points. Select envelope points (as track as take envelope shold works) in project you wanna quantize and click 'Envelope points' button. 
5.2.4 Notes. Select notes or items with notes in project you wanna quantize and click 'Notes' button. 

5.3 Display
5.3.1 Green lines represent reference groove points and values (if any).
5.3.2 Blue lines represent quantized objectspositions and their values (if any).
5.3.3 White lines represent bars and beats.
5.3.4 Yellow line is play cursor. 
5.3.5 Red line is edit cursor.
5.3.6 Right click on display can save current groove to REAPER/Grooves folder.

5.4 Main 'Apply' slider
5.4.1 Left click on this slider set quantize parameters and snap objects positions and values (if any) to reference points. 
5.4.2 It is also strength slider, so if slider is 50%, snap is 50% stronger, 0% - nothing happened with objects, 100% solid snap to points.
5.4.3 Right click restore objects positions to moment when you stored them.

5.5 Options button 
5.5.1 Placed in the right corner. It open/close page with settings.

6. Options Page. Here you can set some settings.
6.1 Reference settings area
6.1.1 Snap reference mode. When 'Global' is selected, snap points is writed to the memory directly with their positions.When pattern mode is on, script firstly convert position of point in seconds to position in bar/beats. When it convert all of reference points, generates pattern and multiply this pattern to all project timeline. It is like 'new ghost grid generator'.
6.1.2 Pattern length. This set how much first bars reference points will be taken from.
6.1.3 Pattern edges. Add edges to start and end of pattern.
6.1.4 Using reference velocity. When quantize, use also velocity/value/gain of selected reference objects if possible.
6.1.5 How to get reference notes. You can set option if you wanna get only selected notes in selected items or all notes in selected items.
6.1.6 How to get reference stretch markers. You can setup how do you wanna get stretch markers positions - relative to grid or relative to bar of first item of first stretch marker. 
6.1.7 Allow to get stretch markers only within time selection.

6.2 Quantize objects settings area
6.2.1 Use gravity. If this selector is on 'Use gravity', then objects are quantized only if their positions are closer (area in seconds) to reference points. 'Snap everything' means every object you selected will be snapped to reference point. Be carefull with this when using with stretch markers.
6.2.2 Snap direction. That means if destination object position is right beetween two points, it will snap to pointdefined in this selector.
6.2.3 Swing scaling is made because of my previously misunderstanding REAPER setting of MIDI Editor, so as described 1x is swing 100% is next grid, 0.5x is half-grid or REAPER native behaviour.
6.2.4 Quantize notes. Select this if you wanna quantize all notes in item or only selected. You can also select notes in MIDI Editor, close it and select item. This also will works.
6.2.5 Allow to stretch stretch marker which are placed only within time selection. Other markers will be stayed at their place. If you wanna change markers selection, again set time selection and store destionation stretch markers (see 5.2.0)

6.3 Buttons
6.3.1 About/ChangeLog. Info about me, version (should be same as title), donation links and changelog.
6.3.2 Current Help on English. Relevant for version 1.08
6.3.3 Requested features, todo list and expected bugs. If you have suggestions, be free to write your thoughts. Contacts are in 'About'.
6.3.4 Donate button opens paypal donate link in default browser
6.3.5 Store current preset to \REAPER\Scripts\mpl_Quantize_Tool_settings.txt

7. Control.
7.1 Use mpl_Quantize_tool_set_swing.lua to control swing value via OSC or MIDI CC
7.2 Use mpl_Quantize_tool_set_strength.lua to control strength value via OSC or MIDI CC


Michael.
 ]===]
 --------------------
 ------- Code -------
 --------------------
   
 function test_var(test, test2)  
   if test ~= nil then  reaper.ShowConsoleMsg("") reaper.ShowConsoleMsg(test) end
   if test2 ~= nil then reaper.ShowConsoleMsg("\n") reaper.ShowConsoleMsg(test2) end
 end


 ---------------------------------------------------------------------------------------------------------------  
function open_URL()
  url = "http://paypal.me/donate2mpl"
  local OS=reaper.GetOS()
  if OS=="OSX32" or OS=="OSX64" then
    os.execute("open ".. url)
   else
    os.execute("start ".. url)
  end
end

 
 ---------------------------------------------------------------------------------------------------------------  
 function math.round(num, idp)
   local mult = 10^(idp or 0)
   return math.floor(num * mult + 0.5) / mult
 end 
       
 ---------------------------------------------------------------------------------------------------------------   
 function s_value(table_line, value_num)
    local value = tonumber(string.sub(settings_temp_t[table_line],value_num,value_num))
    if value == nil then value = 0 end
    return value
 end
       
 ---------------------------------------------------------------------------------------------------------------   
 function DEFINE_default_variables()    
   
   
   exepath = reaper.GetExePath()   
   settings_filename = exepath.."\\Scripts\\mpl_Quantize_Tool_settings.txt"
   settings_file = io.open(settings_filename,"r")
   if settings_file ~= nil then 
      settings_temp_t = {}  
      settings_content = settings_file:read("*all")
      for settings_line in io.lines(settings_filename) do
        table.insert(settings_temp_t, settings_line)  
      end
      settings_file:close()
      
      snap_mode_values_t = {s_value(1,1),s_value(1,2)} 
      pat_len_values_t = {s_value(2,1),s_value(2,2),s_value(2,3)}
      pat_edge_values_t = {s_value(3,1),s_value(3,2)} 
      use_vel_values_t = {s_value(4,1),s_value(4,2)} 
      sel_notes_mode_values_t = {s_value(5,1),s_value(5,2)} 
      sm_rel_ref_values_t = {s_value(6,1),s_value(6,2)} 
      sm_timesel_ref_values_t = {s_value(7,1),s_value(7,2)} 
      
      snap_area_values_t = {s_value(8,1),s_value(8,2)} 
      snap_dir_values_t = {s_value(9,1),s_value(9,2),s_value(9,3)}
      swing_scale_values_t = {s_value(10,1),s_value(10,2)} 
      sel_notes_mode_values_at = {s_value(11,1),s_value(11,2)}   
      sm_timesel_dest_values_t = {s_value(12,1),s_value(12,2)} 
     else
      snap_mode_values_t = {0,1} 
      pat_len_values_t = {1,0,0}
      pat_edge_values_t = {0,1}
      use_vel_values_t = {1,0} 
      sel_notes_mode_values_t = {0,1}
      sm_rel_ref_values_t = {1,0}
      sm_timesel_ref_values_t = {1,0}
      
      snap_area_values_t = {0,1}
      snap_dir_values_t = {0,1,0}
      swing_scale_values_t = {0,1}
      sel_notes_mode_values_at = {0,1}   
      sm_timesel_dest_values_t = {1,0}
   end
  
   
   
   
   restore_button_state = false
   options_button_state = false
   if snap_mode_values_t[2] == 1 then  quantize_ref_values_t = {0, 0, 0, 0, 0, 1, 0} else quantize_ref_values_t = {0, 0, 0, 0} end
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
   swing_value = 0.25
   strenght_value = 1
   last_strenght_value_s = ""
   gravity_value = 0.5
   gravity_mult_value = 0.3 -- second
   use_vel_value = 0
   if swing_scale_values_t[1]&1 then swing_scale = 1.0 end
   if swing_scale_values_t[2]&1 then swing_scale = 0.5 end
   groove_user_input = ""
   quantize_ref_menu_groove_name = "UserGroove"
   pattern_len = 1
 end
 
 --------------------------------------------------------------------------------------------------------------- 
  
 function DEFINE_dynamic_variables() 
   max_object_position, first_measure, last_measure, cml, first_measure_dest_time, last_measure_dest_time, last_measure_dest  = GET_project_len()
   
   timesig_error_ret = GET_timesigs()
   if timesig_error_ret == nil and cml_com == 4 then timesig_error_ret = false end
   
   playpos = reaper.GetPlayPosition() 
   editpos = reaper.GetCursorPosition()   
   
   timesel_st, timesel_end = reaper.GetSet_LoopTimeRange2(0, false, true, 0, 1, true)
   
   grid_beats, grid_string, project_grid_measures, project_grid_cml, grid_time, grid_bar_time = GET_grid()
   
   if pat_len_values_t[1] == 1 then  pattern_len = 1 end -- bar  
   if pat_len_values_t[2] == 1 then  pattern_len = 2 end 
   if pat_len_values_t[3] == 1 then  pattern_len = 4 end 
   
   -- default states for menus --
   snap_mode_menu_names_t = {"Snap reference mode:", "Global (timeline)","Local (pattern)"}
   pat_len_menu_names_t = {"Pattern length:", "1 bar","2 bars", "4 bars"}
   pat_edge_menu_names_t = {"Pattern edges:", "On","Off"}
   use_vel_menu_names_t = {"Ref. velocity:", "<   Use velocity / gain / point value ("..(math.ceil(math.round(use_vel_value*100,1))).."%)   >", "Don`t use"}
   sel_notes_mode_menu_names_t = {"Ref. notes:", "Get selected only","Get all notes in selected item"}
   sm_rel_ref_menu_names_t = {"Ref. str.markers position:", "Bar relative", "Item relative"}
   sm_timesel_ref_menu_names_t = {"Ref. str.markers:", "All", "Time selection"}
   
   snap_area_menu_names_t = {"Snap area:","< Use gravity ("..(math.ceil(math.round(gravity_value*gravity_mult_value,3)*1000)).." ms) >","Snap everything"}
   snap_dir_menu_names_t =  {"Snap direction:","To previous point","To closest point","To next point"} 
   swing_scale_menu_names_t =  {"Swing scaling:","1x (100% is next grid)","0.5x (REAPER behaviour)"}
   sel_notes_mode_menu_names_at = {"Quantize notes:", "Selected only","All notes in selected item"}
   sm_timesel_dest_menu_names_t = {"Destinaion str.markers:", "All", "Time selection"}
   
   ---------------------
   -- count reference --
   ---------------------
   if snap_mode_values_t[1] == 1 then
     if ref_points_t ~= nil then count_ref_positions = #ref_points_t else count_ref_positions = 0 end
    else
     if ref_points_t2 ~= nil then count_ref_positions = #ref_points_t2 else count_ref_positions = 0 end
   end  
   quantize_ref_menu_item_name = "Items" 
   quantize_ref_menu_sm_name = "Stretch markers" 
   quantize_ref_menu_ep_name = "Envelope points" 
   quantize_ref_menu_notes_name = "Notes" 
   
   if custom_grid_beats_i == 0 or custom_grid_beats_i == nil then  
       quantize_ref_menu_grid_name = "project grid: "..grid_string 
     else quantize_ref_menu_grid_name = "custom grid: "..grid_string end
       
   quantize_ref_menu_swing_name = "swing grid "..math.floor(swing_value*100).."%"   
   
   if snap_mode_values_t[2] == 1 then        
     quantize_ref_menu_names_t = {"Reference points ("..count_ref_positions..") :", quantize_ref_menu_item_name, quantize_ref_menu_sm_name,
                                quantize_ref_menu_ep_name, quantize_ref_menu_notes_name, quantize_ref_menu_groove_name,
                                quantize_ref_menu_grid_name,
                                quantize_ref_menu_swing_name}
    else
     quantize_ref_menu_names_t = {"Reference points ("..count_ref_positions..") :", quantize_ref_menu_item_name, quantize_ref_menu_sm_name,
                                quantize_ref_menu_ep_name, quantize_ref_menu_notes_name}
   end
   -----------------------                             
   -- count destination --                             
   -----------------------
   if dest_points_t ~= nil then count_dest_positions = #dest_points_t else count_dest_positions = 0 end
   quantize_dest_menu_item_name = "Items" 
   quantize_dest_menu_sm_name = "Stretch markers" 
   quantize_dest_menu_ep_name = "Envelope points" 
   quantize_dest_menu_notes_name = "Notes" 
   
   quantize_dest_menu_names_t = {"Objects to quantize ("..count_dest_positions..") :",quantize_dest_menu_item_name, quantize_dest_menu_sm_name,
                                quantize_dest_menu_ep_name, quantize_dest_menu_notes_name} 
   
   
   if restore_button_state == false then 
     apply_bypass_slider_name = "Apply (LMB) / Quantize strength (MMB) / Restore (RMB)" end
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
  beetween_items3 = 20 -- vert
  
  -- gfx.vars --
  gui_help = 0.0  
  font = "Arial"
  fontsize_menu_name  = 16
  fontsize_menu_item = fontsize_menu_name-1
  itemcolor1_t = {0.4, 1, 0.4}
  itemcolor2_t = {0.5, 0.8, 1}
  frame_alpha_default = 0.05  
  frame_alpha_selected = 0.1
  
  editpos_rgba_t = {0.5, 0, 0, 0.6}
  playpos_rgba_t = {0.5, 0.5, 0, 0.8}
  ref_points_rgba_t = {0, 1, 0, 0.5}
  dest_points_rgba_t = {0.1, 0.6, 1, 1}
  bar_points_rgba_t = {1,1,1,0.5}
  
  display_end = 1 -- 0..1
  display_start = 0 -- 0..1
  
  -- menus -- 
  snap_mode_menu_xywh_t = {x_offset, y_offset, width1, heigth2}
  pat_len_menu_xywh_t = {x_offset, y_offset+beetween_items3, width1, heigth2}
  pat_edge_menu_xywh_t = {x_offset, y_offset+beetween_items3*2, width1, heigth2}
  use_vel_menu_xywh_t = {x_offset, y_offset+beetween_items3*3, width1, heigth2}
  sel_notes_mode_menu_xywh_t = {x_offset, y_offset+beetween_items3*4, width1, heigth2}
  sm_rel_ref_menu_xywh_t = {x_offset, y_offset+beetween_items3*5, width1, heigth2}
  sm_timesel_ref_menu_xywh_t = {x_offset, y_offset+beetween_items3*6, width1, heigth2}
  
  y_offset2 = sm_timesel_ref_menu_xywh_t[2]+5
  snap_area_menu_xywh_t = {x_offset, y_offset2 + beetween_items3, width1, heigth2}
  snap_dir_menu_xywh_t = {x_offset, y_offset2 + beetween_items3*2, width1, heigth2}  
  swing_scale_menu_xywh_t = {x_offset,  y_offset2 + beetween_items3*3, width1, heigth2}
  sel_notes_mode_menu_xywh_at = {x_offset, y_offset2 + beetween_items3*4, width1, heigth2}
  sm_timesel_dest_menu_xywh_t = {x_offset, y_offset2 + beetween_items3*5, width1, heigth2}
  
  quantize_ref_menu_xywh_t = {x_offset, y_offset, width1/2, y_offset1-y_offset}
  quantize_dest_menu_xywh_t = {x_offset+width1/2+gui_offset, y_offset, width1/2-gui_offset , y_offset1-y_offset}

  -- options areas --
  ref_options_area_xywh_t = {x_offset, snap_mode_menu_xywh_t[2],width1, beetween_items3*6 + beetween_items3}
  quantize_options_area_xywh_t = {x_offset, snap_area_menu_xywh_t[2],width1, beetween_items3*5}  
  
  -- frames --
  display_rect_xywh_t = {x_offset, y_offset1+gui_offset, main_w-gui_offset*2, heigth3}  
  
  -- static slider --
  apply_slider_xywh_t = {x_offset, display_rect_xywh_t[2]+display_rect_xywh_t[4]+beetween_menus2, main_w-gui_offset*2, heigth4}  
  
  -- buttons --
  options_button_xywh_t = {x_offset+width1+gui_offset, y_offset, main_w - width1 - gui_offset*2, y_offset1-y_offset}
  options_buttons_width = 140
  about_button_xywh_t = {x_offset, y_offset+main_h - 50, options_buttons_width, 40}
  help_button_xywh_t = {x_offset + about_button_xywh_t[3] + 5, y_offset+main_h - 50,options_buttons_width, 40}
  todo_button_xywh_t = {x_offset + help_button_xywh_t[1] + help_button_xywh_t[3], y_offset+main_h - 50, options_buttons_width, 40}
  
  store_preset_button_xywh_t = {x_offset, y_offset+main_h - 95, options_buttons_width, 40}
    donate_button_xywh_t = {x_offset + store_preset_button_xywh_t[3] + 5, y_offset+main_h - 95,options_buttons_width, 40}
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
   
   gfx.r, gfx.g, gfx.b, gfx.a = color_t[1], color_t[2], color_t[3], is_selected_item * 0.8 + 0.17 
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
     
     if b7~=nil then 
     item_y_offset = y6 + h6 + beetween_items2
     x7,y7,w7,h7 = GUI_menu_item (b7, item_y_offset, values_t[7],true,itemcolor_t) end 
     
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
    
    --GUI_display_length
   x1 = display_rect_xywh_t[1] + display_rect_xywh_t[3] *   ( (pos-gui_display_offset) / gui_display_length)   
   
   if align == "centered" then
     y1 = display_rect_xywh_t[2] + display_rect_xywh_t[4]/2 - (display_rect_xywh_t[4]*0.5)*val
     y2 = display_rect_xywh_t[2] + display_rect_xywh_t[4]/2 + (display_rect_xywh_t[4]*0.5)*val
   end   
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
   
   gui_display_offset = first_measure_dest_time
   gui_display_length = last_measure_dest_time - first_measure_dest_time
   
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
   
   -- bars
   _, gui_display_length_bars = reaper.TimeMap2_timeToBeats(0, gui_display_length)
   for i = 0, gui_display_length_bars+1 do      
     bar_time = reaper.TimeMap2_beatsToTime(0, 0, i)  
     GUI_display_pos(0, bar_points_rgba_t, "centered", 0.4)   
     GUI_display_pos(bar_time, bar_points_rgba_t, "centered", 0.4)  
   end    
   
   -- beats
   if gui_display_length_bars <= 10 then
     for i = 1, cml*gui_display_length_bars do
       if i%cml ~= 0 then
         beat_time = reaper.TimeMap2_beatsToTime(0, i)
         GUI_display_pos(beat_time+gui_display_offset, bar_points_rgba_t, "centered", 0.2)
       end  
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

 function GUI_button(xywh_t, name, name_pressed, state, has_frame)
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
     if has_frame == true then
       gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, frame_alpha_default
       gfx.roundrect(x,y,w,h,0.1, true)
     end  
    else 
      gfx.drawstr(name_pressed) 
      -- frame -- 
     if has_frame == true then
        gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, frame_alpha_selected
      gfx.roundrect(x,y,w,h,0.1, true)
        end
   end   
 end
 
---------------------------------------------------------------------------------------------------------------
     
 function GUI_DRAW()
 
  if project_grid_measures < 1 and timesig_error_ret == false then
  
   ------------------  
   --- main page ----
   ------------------  
   
     -- background --
     gfx.r, gfx.g, gfx.b, gfx.a = 0.2, 0.2, 0.2, 1
     gfx.rect(0,0,main_w,main_h)
    
     -- menus --  
     
     quantize_ref_xywh_buttons_t =   GUI_menu (quantize_ref_menu_xywh_t, quantize_ref_menu_names_t, quantize_ref_values_t, true,false,itemcolor1_t,0.05)
     if snap_mode_values_t[2] == 1 then -- if pattern mode
       meas_str_temp = gfx.measurestr(quantize_ref_menu_names_t[7])       -- if grid
       grid_value_slider_xywh_t = {x_offset, quantize_ref_xywh_buttons_t[22]-2, width1/2, fontsize_menu_item+4}
       swing_grid_value_slider_xywh_t = {x_offset, quantize_ref_xywh_buttons_t[26]-2, width1/2, fontsize_menu_item+4}
       if display_grid_value_slider == true then GUI_slider_gradient(grid_value_slider_xywh_t, "", grid_value, "normal") end 
       if display_swing_value_slider == true then GUI_slider_gradient(swing_grid_value_slider_xywh_t, "", swing_value, "centered") end 
     end  
     
     
     quantize_dest_xywh_buttons_t =  GUI_menu (quantize_dest_menu_xywh_t, quantize_dest_menu_names_t, quantize_dest_values_t, true,false,itemcolor2_t,0.05)
   
     GUI_display()
   
     GUI_slider_gradient(apply_slider_xywh_t, apply_bypass_slider_name, strenght_value,"normal")
   
     GUI_button(options_button_xywh_t, "<<", ">>", options_button_state, true)
     
   ------------------  
   -- options page --
   ------------------
   
     if options_button_state == true then    
       -- background blur 
       for i = 1, 6 do
         gfx.x, gfx.y = 0,0
         gfx.blurto(gui_offset*2+width1,main_h)
       end
       -- background + --
       gfx.r, gfx.g, gfx.b, gfx.a = 0, 0, 0, 0.8
       gfx.rect(0,0,main_w,main_h)            
       
       -- areas background --
       
       gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 0.1
       gfx.rect(ref_options_area_xywh_t[1],ref_options_area_xywh_t[2],ref_options_area_xywh_t[3],ref_options_area_xywh_t[4])
       
       gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 0.1
       gfx.rect(quantize_options_area_xywh_t[1],quantize_options_area_xywh_t[2],quantize_options_area_xywh_t[3],quantize_options_area_xywh_t[4])
       
       -- buttons background --
       gfx.r, gfx.g, gfx.b, gfx.a = 0.5, 0.8, 1, 0.15
       gfx.rect(store_preset_button_xywh_t[1],store_preset_button_xywh_t[2], store_preset_button_xywh_t[3], store_preset_button_xywh_t[4])
       
       gfx.r, gfx.g, gfx.b, gfx.a = 0.5, 0.8, 1, 0.15
       gfx.rect(about_button_xywh_t[1], about_button_xywh_t[2], about_button_xywh_t[3], about_button_xywh_t[4])
       
       gfx.r, gfx.g, gfx.b, gfx.a = 0.5, 0.8, 1, 0.15
       gfx.rect(help_button_xywh_t[1], help_button_xywh_t[2],help_button_xywh_t[3], help_button_xywh_t[4])

       gfx.r, gfx.g, gfx.b, gfx.a = 0.5, 0.8, 1, 0.15
       gfx.rect(todo_button_xywh_t[1], todo_button_xywh_t[2],todo_button_xywh_t[3], todo_button_xywh_t[4])       
       
       gfx.r, gfx.g, gfx.b, gfx.a = 0.5, 0.8, 1, 0.15
       gfx.rect(donate_button_xywh_t[1], donate_button_xywh_t[2],donate_button_xywh_t[3], donate_button_xywh_t[4]) 
       
      -- ref setup area --
        snap_mode_xywh_buttons_t =      GUI_menu (snap_mode_menu_xywh_t, snap_mode_menu_names_t, snap_mode_values_t, false,false,itemcolor2_t,0)
        pat_len_xywh_buttons_t =        GUI_menu (pat_len_menu_xywh_t, pat_len_menu_names_t, pat_len_values_t, false,false,itemcolor2_t,0)
        pat_edge_xywh_buttons_t =       GUI_menu (pat_edge_menu_xywh_t, pat_edge_menu_names_t, pat_edge_values_t, false,false,itemcolor2_t,0)
        use_vel_xywh_buttons_t =        GUI_menu (use_vel_menu_xywh_t, use_vel_menu_names_t, use_vel_values_t, false,false,itemcolor2_t,0)
          use_vel_slider_xywh_t = {use_vel_xywh_buttons_t[1], use_vel_xywh_buttons_t[2], use_vel_xywh_buttons_t[3], use_vel_xywh_buttons_t[4]}
          GUI_slider_gradient(use_vel_slider_xywh_t, "", use_vel_value, "normal")
        sel_notes_mode_xywh_buttons_t = GUI_menu (sel_notes_mode_menu_xywh_t, sel_notes_mode_menu_names_t, sel_notes_mode_values_t, false,false,itemcolor2_t,0)
        sm_rel_ref_xywh_buttons_t =     GUI_menu (sm_rel_ref_menu_xywh_t, sm_rel_ref_menu_names_t, sm_rel_ref_values_t, false,false,itemcolor2_t,0)
        sm_timesel_ref_xywh_buttons_t = GUI_menu (sm_timesel_ref_menu_xywh_t, sm_timesel_ref_menu_names_t, sm_timesel_ref_values_t, false,false,itemcolor2_t,0)
        
      -- quantize setup area -- 
        snap_area_xywh_buttons_t =      GUI_menu (snap_area_menu_xywh_t, snap_area_menu_names_t, snap_area_values_t, false,false,itemcolor2_t,0)
          gravity_slider_xywh_t = {snap_area_xywh_buttons_t[1], snap_area_xywh_buttons_t[2], snap_area_xywh_buttons_t[3], snap_area_xywh_buttons_t[4]}
          if snap_area_values_t[1] == 1 then GUI_slider_gradient(gravity_slider_xywh_t, "", gravity_value, "mirror") end -- if gravity
        
        snap_dir_xywh_buttons_t =       GUI_menu (snap_dir_menu_xywh_t,  snap_dir_menu_names_t, snap_dir_values_t, false,false,itemcolor2_t,0)
        swing_scale_xywh_buttons_t =    GUI_menu (swing_scale_menu_xywh_t,  swing_scale_menu_names_t, swing_scale_values_t, false,false,itemcolor2_t,0)
        sel_notes_mode_xywh_buttons_at =      GUI_menu (sel_notes_mode_menu_xywh_at, sel_notes_mode_menu_names_at, sel_notes_mode_values_at, false,false,itemcolor2_t,0)
        sm_timesel_dest_xywh_buttons_t = GUI_menu (sm_timesel_dest_menu_xywh_t, sm_timesel_dest_menu_names_t, sm_timesel_dest_values_t, false,false,itemcolor2_t,0)
        
      -- buttons
       GUI_button(options_button_xywh_t, "<<", ">>", options_button_state, true)
       GUI_button(about_button_xywh_t, "About / ChangeLog","About / ChangeLog", _, true)
       GUI_button(help_button_xywh_t, "Help","Help", _, true)
       GUI_button(todo_button_xywh_t, "ToDo / Bugs","ToDo / Bugs", _, true)
       GUI_button(donate_button_xywh_t, "Donate if you like it","Donate if you like it", _, true) 
       GUI_button(store_preset_button_xywh_t, "Store preset","Store preset", _, true)  
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
    
 function GET_timesigs()
   timesig_count = reaper.CountTempoTimeSigMarkers(0)
   if timesig_count ~= nil then
     for i =1, timesig_count do
       _, _, _, _, _, timesig, timesig_denom = reaper.GetTempoTimeSigMarker(0, i-1)
       if timesig == 4 or timesig_denom == 4 then 
         timesig_error = false 
        else 
         timesig_error = true 
       end  
       if timesig == 0 and timesig_denom == 0 then  timesig_error = false   end
     end 
    else
     timesig_error = false  
   end
   return timesig_error
 end
 
 ---------------------------------------------------------------------------------------------------------------      
 function GET_grid()
   project_grid_time = reaper.BR_GetNextGridDivision(0)
   project_grid_beats, project_grid_measures, project_grid_cml = reaper.TimeMap2_timeToBeats(0, project_grid_time)
   
   custom_grid_beats_t = {4/4,
                          4/6,
                          4/8,
                          4/12,
                          4/16,
                          4/24,
                          4/32,
                          4/48,
                          4/64,
                          4/96,
                          4/128}
                                               
   custom_grid_beats_i = math.floor(grid_value*12)
   
   if project_grid_measures == 0 then
     if custom_grid_beats_i == 0 then 
       grid_beats = project_grid_beats *0.5       
      else
       grid_beats = custom_grid_beats_t[custom_grid_beats_i]       
     end   
     
     if grid_beats == nil then grid_beats = project_grid_beats end
     
     grid_divider = math.ceil(math.round(4/grid_beats, 1))*0.5
     grid_string = "1/"..math.ceil(grid_divider)
     
     if grid_divider % 3 == 0 then grid_string = "1/"..math.ceil(grid_divider/3*2).."T" end
     grid_time = reaper.TimeMap2_beatsToTime(0, grid_beats*2) 
     grid_bar_time  = reaper.TimeMap2_beatsToTime(0, 0, 1)
    else
     grid_string = "error"
   end -- if proj grid measures ==0 / snap < 1 
   return  grid_beats, grid_string, project_grid_measures,project_grid_cml, grid_time, grid_bar_time
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
                if sm_rel_ref_values_t[2] ==1 then  ref_sm_pos = ref_sm_pos-ref_item_pos end
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

 function ENGINE1_get_reference_usergroove()
   --if ref_groove_t == nil then -- if already got
    retval, groove_user_input = reaper.GetUserInputs("Type name of groove", 1, "Name of groove", "")
    if retval ~= nil or groove_user_input ~= "" then
      filename = exepath.."\\Grooves\\"..groove_user_input..".rgt"
      content_temp_t = {}
      file = io.open(filename, "r")
      if file ~= nil then
        content = file:read("*all")
        for line in io.lines(filename) do           
          table.insert(content_temp_t, line) 
        end
        file:close()
        
        beats_in_groove = tonumber(string.sub(content_temp_t[2], 28))
        pattern_len = beats_in_groove/4
        
        ref_groove_t = {}  
        table.insert(ref_groove_t, 0)
        for i = 1, #content_temp_t do
           if i>=5 then
             temp_var = tonumber(content_temp_t[i])
             temp_var_conv = reaper.TimeMap2_beatsToTime(0, temp_var)
             table.insert(ref_groove_t, temp_var_conv)
           end  
        end
        quantize_ref_menu_groove_name = groove_user_input
      end
      ENGINE1_get_reference_FORM_points() 
      ENGINE3_quantize_objects() 
      
    end
   --end  
 end
 
---------------------------------------------------------------------------
   
 function ENGINE1_get_reference_grid()   
   ref_grid_t = {}
   if cml == nil then cml = 4 end
   for i = 0, cml, grid_beats do
     grid_time_st2table  = reaper.TimeMap2_beatsToTime(0, i)
     table.insert(ref_grid_t, i)
     i = i + grid_beats
   end
 end 
 
 --------------------------------------------------------------------------------------------------------------- 
   
  function ENGINE1_get_reference_swing_grid()  
     ref_swing_grid_t = {}
     i2 = 0
     if cml_com == nil then cml_com = 4 end
     
     for grid_p = 0, cml_com, grid_beats do         
       if i2 % 2 == 0 then 
         grid_p_totable  = reaper.TimeMap2_beatsToTime(0, grid_p)
         table.insert(ref_swing_grid_t, grid_p_totable) end
       if i2 % 2 == 1 then        
         grid_p_totable_temp = grid_p + swing_value* swing_scale*grid_beats
         grid_p_totable= reaper.TimeMap2_beatsToTime(0, grid_p_totable_temp)
         table.insert(ref_swing_grid_t, grid_p_totable) 
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
         if sm_timesel_ref_values_t[2]==1 then 
           if ref_sm_pos_t[i] > timesel_st and ref_sm_pos_t[i] < timesel_end then  table.insert (ref_points_t, table_temp_val) end          
          else  
           table.insert (ref_points_t, table_temp_val)
         end    
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
     
     -- groove 
     if quantize_ref_values_t[5] == 1 and ref_groove_t ~= nil then     
       for i = 1, #ref_groove_t do
         table_temp_val = ref_groove_t[i]
         table.insert (ref_points_t, i, {table_temp_val, 1})
       end
     end      
     
     
     -- grid --
     if quantize_ref_values_t[6] == 1 and ref_grid_t ~= nil then     
       for i = 1, #ref_grid_t do
         temp_val5 = ref_grid_t[i]
         table.insert (ref_points_t, {temp_val5, 1})
       end
     end
     
     -- swing --
     if quantize_ref_values_t[7] == 1 and ref_swing_grid_t ~= nil then   
         for i = 1, #ref_swing_grid_t do
           temp_val4 = ref_swing_grid_t[i]
           table.insert (ref_points_t, {temp_val4, 1})
         end      
     end
    
    
    -- form pattern / generate pattern grid
           
     if ref_points_t ~= nil and snap_mode_values_t[2] == 1 then
        ref_points_t2 = {}--table for beats pos  
              
         -- first ref item measure
        ref_point_subt_temp_min = math.huge --start value  for loop
        for i = 1, #ref_points_t do          
          ref_point_subt_temp = ref_points_t[i]          
          ref_point_subt_temp_min = math.min(ref_point_subt_temp_min, ref_point_subt_temp[1])
        end  
        
        retval, first_pat_measure, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, ref_point_subt_temp_min)
        
        -- if pos not bigger than first item measure + pattern length , add to table
        for i = 1, #ref_points_t do
          ref_point_subt_temp = ref_points_t[i]          
          retval, measure2, cml1, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, ref_point_subt_temp[1])
          if measure2 < first_pat_measure + pattern_len then
            table.insert(ref_points_t2, {retval, ref_point_subt_temp[2]})
          end  
        end
        
        -- add edges
        if pat_edge_values_t[1] == 1 then
          table.insert(ref_points_t2, {0, 1})
          table.insert(ref_points_t2, {pattern_len*cml, 1})
        end
        
        -- generate grid from ref_points_t2
        ref_points_t = {}
        for i=1, 400, pattern_len do          
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
  --[[positions_of_objects_t = {}
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
  if max_object_position == nil then max_object_position = 1 end
  retval, measuresOut, cml = reaper.TimeMap2_timeToBeats(0, max_object_position)
  max_object_position = reaper.TimeMap2_beatsToTime(0, 0, measuresOut+1)
  if max_object_position == nil then max_object_position = 0 end
  retval, last_measure, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, max_object_position)]]
  
  max_point = 0
  min_point = math.huge
  
  if dest_points_t ~= nil then
    for i = 1, #dest_points_t do      
      dest_points_t_subt = dest_points_t[i]
      max_point = math.max(dest_points_t_subt[1],max_point)
      min_point = math.min(dest_points_t_subt[1],min_point)
    end
  end  
  _, first_measure_dest = reaper.TimeMap2_timeToBeats(0, min_point)  
  _, last_measure_dest = reaper.TimeMap2_timeToBeats(0, max_point)
  last_measure_dest = last_measure_dest+1
  first_measure_dest_time = reaper.TimeMap2_beatsToTime(0, 0, first_measure_dest)
  last_measure_dest_time = reaper.TimeMap2_beatsToTime(0, 0, last_measure_dest)
  
  if ref_points_t ~= nil then  
    for i = 1, #ref_points_t do
      ref_points_t_item_subt = ref_points_t[i]
      max_point = math.max(ref_points_t_item_subt[1],max_point)
      min_point = math.min(ref_points_t_item_subt[1],min_point)
    end  
  end  
  
  max_object_position = max_point
  _, first_measure = reaper.TimeMap2_timeToBeats(0, min_point)
  _, last_measure1 = reaper.TimeMap2_timeToBeats(0, max_point)
  last_measure = last_measure1 +1
  _, _, cml_com = reaper.TimeMap2_timeToBeats(0, 0)
  return max_object_position, first_measure, last_measure, cml_com, first_measure_dest_time, last_measure_dest_time, last_measure_dest
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
                if posOut > 0 and posOut < item_len-0.001 then
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
                  if sel_notes_mode_values_at[1] == 1 then
                    if selectedOut == true then
                      table.insert(dest_notes_t2, dest_notes_subt)
                    end  
                  end
                  if sel_notes_mode_values_at[2] == 1 then
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
         dest_sm = table_temp_val[4] + (table_temp_val[2]/table_temp_val[5])
         if sm_timesel_dest_values_t[1] == 1 then  table.insert (dest_points_t, {dest_sm, 1} )
           else 
             if dest_sm > timesel_st and dest_sm<timesel_end then
               table.insert (dest_points_t, {dest_sm, 1} )
             end
           end
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
         if sel_notes_mode_values_at[1] == 1 then
           if table_temp_val[2] == true then
             table.insert (dest_points_t, {table_temp_val[9], table_temp_val[8]/127})
           end  
         end  
         if sel_notes_mode_values_at[2] == 1 then
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
                reaper.DeleteTakeStretchMarkers(take, j)
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
                reaper.DeleteTakeStretchMarkers(take, j)
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
            if sm_timesel_dest_values_t[1] == 1 then            
              new_sm_pos = ENGINE3_quantize_compare(true_sm_pos,0)
             else
              if true_sm_pos>timesel_st and true_sm_pos<timesel_end then
                new_sm_pos = ENGINE3_quantize_compare(true_sm_pos,0)
               else
                new_sm_pos = true_sm_pos
              end
            end 
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
          
          
          if sel_notes_mode_values_at[1] == 1 then
            if dest_notes_subt[2] == true then
              notes_newpos, notes_newvol = ENGINE3_quantize_compare(dest_notes_subt[9], dest_notes_subt[8]/127)
             else
              notes_newpos = dest_notes_subt[9]
              notes_newvol = dest_notes_subt[8]/127
            end 
          end
          if sel_notes_mode_values_at[2] == 1 then
            notes_newpos, notes_newvol = ENGINE3_quantize_compare(dest_notes_subt[9], dest_notes_subt[8]/127)
          end
          notes_newpos_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, notes_newpos)
          reaper.MIDI_InsertNote(take, dest_notes_subt[2], dest_notes_subt[3], notes_newpos_ppq, notes_newpos_ppq+ppq_dif, 
          dest_notes_subt[6], dest_notes_subt[7], math.ceil(notes_newvol*127), false)
          reaper.MIDI_Sort(take)
        end  
      end    
    end --dest_notes_t ~= nil and restore_button_state == false  
   end     --if quantize_dest_values_t[4] == 1 then 
   reaper.UpdateArrange()
  end -- func
  
  
 ---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------      
 function ENGINE4_save_groove_as_rgt()
   if ref_points_t2 ~= nil then
     rgt_t = {}
     --form_return_lines
     rgt_t[1] = "Version: 0"
     rgt_t[2] = "Number of beats in groove: "..pattern_len*4
     rgt_t[3] = "Groove: "..#ref_points_t2.." positions"
     rgt_t[4] = "1e-007"
     for i = 2, #ref_points_t2 do
        rgt_t_item = ref_points_t2[i]
        rgt_t_item = tostring(math.round(rgt_t_item[1], 10))
        
        table.insert(rgt_t, rgt_t_item)
     end
     
     --write file
     retval, ret_groove_user_input = reaper.GetUserInputs("Save groove", 1, "Name of groove", "")
     if retval ~= nil or ret_groove_user_input ~= "" then     
       ret_filename = exepath.."\\Grooves\\"..ret_groove_user_input..".rgt"
       
       file = io.open(ret_filename,"w")   
       if   file~= nil then  
         for i = 1, #rgt_t do file:write(rgt_t[i].."\n") end
         file:close()
       end  
       
     end  
     
   end
 end
 
 ---------------------------------------------------------------------------------------------------------------
 function ENGINE4_save_preset()
   settings_t = {}
   
   settings_t[1] = table.concat(snap_mode_values_t, "")
   settings_t[2] = table.concat(pat_len_values_t, "")
   settings_t[3] = table.concat(pat_edge_values_t, "")
   settings_t[4] = table.concat(use_vel_values_t, "")
   settings_t[5] = table.concat(sel_notes_mode_values_t, "")
   settings_t[6] = table.concat(sm_rel_ref_values_t, "")
   settings_t[7] = table.concat(sm_timesel_ref_values_t, "")
   settings_t[8] = table.concat(snap_area_values_t, "")
   settings_t[9] = table.concat(snap_dir_values_t, "")
   settings_t[10] = table.concat(swing_scale_values_t, "")
   settings_t[11] = table.concat(sel_notes_mode_values_at, "")   
   settings_t[12] = table.concat(sm_timesel_dest_values_t, "")  
      
   file = io.open(settings_filename,"w")        
   if file ~= nil then
     for i = 1, #settings_t do file:write(settings_t[i].."\n") end
     file:write("\n".."Configuration for mpl Quantize Tool".."\n".."If you`re not sure what is that, don`t modify this!".."\n".."\n")
     file:close()
     reaper.MB("Configuration saved successfully to "..exepath.."\\Scripts\\mpl_Quantize_Tool_settings.txt", "Preset saving", 0)
    else
      reaper.MB("Something goes wrong", "Preset saving", 0)
   end  
   
   
 end
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


 function MOUSE_MB_clickhold_under_gui_rect (object_coord_t, offset) 
  if gfx.mouse_cap == 64 then MB_DOWN = 1 else MB_DOWN = 0 end   
  x = object_coord_t[1+offset]
  y = object_coord_t[2+offset]
  w = object_coord_t[3+offset]
  h = object_coord_t[4+offset]
  if MB_DOWN == 1
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
       quantize_ref_values_t = {1, 0, 0, 0, 0, 0, 0} 
       count_reference_item_positions = ENGINE1_get_reference_item_positions() 
       ENGINE1_get_reference_FORM_points()end
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,4) == true then 
       quantize_ref_values_t = {0, 1, 0, 0, 0, 0, 0} 
       count_reference_sm_positions = ENGINE1_get_reference_SM_positions() 
       ENGINE1_get_reference_FORM_points() end
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,8) == true then 
       quantize_ref_values_t = {0, 0, 1, 0, 0, 0, 0} 
       count_reference_ep_positions = ENGINE1_get_reference_EP_positions() 
       ENGINE1_get_reference_FORM_points() end
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,12) == true then 
       quantize_ref_values_t = {0, 0, 0, 1, 0, 0, 0} 
       count_reference_notes_positions = ENGINE1_get_reference_notes_positions() 
       ENGINE1_get_reference_FORM_points() end  
       
           -- user groove--
           
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,16) == true then 
       quantize_ref_values_t = {0, 0, 0, 0, 1, 0, 0} 
       ENGINE1_get_reference_usergroove()
     end  
     
           -- grid --
           
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,20) == true or  
        MOUSE_clickhold_under_gui_rect(grid_value_slider_xywh_t, 0) == true
     then quantize_ref_values_t = {0, 0, 0, 0, 0, 1, 0}
          display_grid_value_slider = true
          if grid_value_slider_xywh_t ~= nil then grid_value = (mx - grid_value_slider_xywh_t[1])/grid_value_slider_xywh_t[3] end
          ENGINE1_get_reference_grid()
          ENGINE1_get_reference_FORM_points() 
          ENGINE3_quantize_objects()
      else
       display_grid_value_slider = false
     end
     
     if MOUSE_RB_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,20) == true or  
        MOUSE_RB_clickhold_under_gui_rect(grid_value_slider_xywh_t, 0) == true
         then quantize_ref_values_t = {0, 0, 0, 0, 0, 1, 0}
          grid_value = 0
          ENGINE1_get_reference_grid()
          ENGINE1_get_reference_FORM_points() 
          ENGINE3_quantize_objects()
     end     
     
           -- swing --
           
     if MOUSE_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,24) == true or 
        MOUSE_clickhold_under_gui_rect(swing_grid_value_slider_xywh_t, 0) == true then 
        quantize_ref_values_t = {0, 0, 0, 0, 0, 0, 1} 
        display_swing_value_slider = true
        if swing_grid_value_slider_xywh_t ~= nil then 
          swing_value = ((mx - swing_grid_value_slider_xywh_t[1])/swing_grid_value_slider_xywh_t[3])*2-1 end
        ENGINE1_get_reference_swing_grid()
        ENGINE1_get_reference_FORM_points()
        ENGINE3_quantize_objects()
      else
        display_swing_value_slider = false
     end -- lb mouse on swing
     
     if MOUSE_RB_clickhold_under_gui_rect(quantize_ref_xywh_buttons_t,24) == true then
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
     
     -- APPLY BUTTON / SLIDER restore --  
     if MOUSE_RB_clickhold_under_gui_rect(apply_slider_xywh_t,0) == true then 
       restore_button_state = true 
       ENGINE3_quantize_objects()
      else  
       restore_button_state = false 
     end
     
     -- APPLY BUTTON / SLIDER type --  
     if MOUSE_MB_clickhold_under_gui_rect(apply_slider_xywh_t,0) == true then      
       strenght_value_retval, strenght_value_return_s =  reaper.GetUserInputs("Strenght value", 1, "Strenght (%)", "") 
       if strenght_value_retval ~= nil then 
         strenght_value_return = tonumber(strenght_value_return_s) 
         if strenght_value_return ~= nil then       
           strenght_value = strenght_value_return/100
           if math.abs(strenght_value) >1 then strenght_value = 1 end       
           ENGINE3_quantize_objects()           
         end
       end    
     end     
     
     -- DISPLAY --
     if MOUSE_RB_clickhold_under_gui_rect(display_rect_xywh_t,0) == true then 
       gfx.x, gfx.y = mx, my 
       should_save = gfx.showmenu("Save groove as rgt")
       if should_save == 1 then 
         ENGINE4_save_groove_as_rgt()
       end  
     end 
       
   end
   
     -------------------------
     ----- OPTIONS PAGE -----
     ------------------------- 
     
   if options_button_state == true then

  --|||-- SNAP DEST SETTING    
     ----- SNAP MODE MENU -----
     if snap_mode_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(snap_mode_xywh_buttons_t,0) == true then
         snap_mode_values_t = {1, 0} 
         quantize_ref_values_t = {quantize_ref_values_t[1], quantize_ref_values_t[2], quantize_ref_values_t[3], quantize_ref_values_t[4]} 
         ENGINE1_get_reference_FORM_points() 
       end
       if MOUSE_clickhold_under_gui_rect(snap_mode_xywh_buttons_t,4) == true then 
         snap_mode_values_t = {0, 1} 
         quantize_ref_values_t = {quantize_ref_values_t[1], quantize_ref_values_t[2], quantize_ref_values_t[3], quantize_ref_values_t[4], 0, 0} 
         ENGINE1_get_reference_FORM_points() end
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
       if MOUSE_clickhold_under_gui_rect(use_vel_xywh_buttons_t,0) == true then use_vel_values_t = {1, 0} ENGINE1_get_reference_FORM_points() end
       if MOUSE_clickhold_under_gui_rect(use_vel_xywh_buttons_t,4) == true then use_vel_values_t = {0, 1} ENGINE1_get_reference_FORM_points() end
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
       if MOUSE_clickhold_under_gui_rect(sel_notes_mode_xywh_buttons_t,0) == true then sel_notes_mode_values_t = {1, 0} ENGINE1_get_reference_FORM_points() end
       if MOUSE_clickhold_under_gui_rect(sel_notes_mode_xywh_buttons_t,4) == true then sel_notes_mode_values_t = {0, 1} ENGINE1_get_reference_FORM_points() end
     end
     ------ RELATIVE SM POSITION ------      
     if sm_rel_ref_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(sm_rel_ref_xywh_buttons_t,0) == true then sm_rel_ref_values_t = {1, 0} ENGINE1_get_reference_FORM_points() end
       if MOUSE_clickhold_under_gui_rect(sm_rel_ref_xywh_buttons_t,4) == true then sm_rel_ref_values_t = {0, 1} ENGINE1_get_reference_FORM_points() end
     end     
     ------ SM ALL/TIMESELECTION ONLY ------      
     if sm_timesel_ref_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(sm_timesel_ref_xywh_buttons_t,0) == true then sm_timesel_ref_values_t = {1, 0} ENGINE1_get_reference_FORM_points() end
       if MOUSE_clickhold_under_gui_rect(sm_timesel_ref_xywh_buttons_t,4) == true then sm_timesel_ref_values_t = {0, 1} ENGINE1_get_reference_FORM_points() end
     end      
          
  --|||-- SNAP QUANT SETTING   
     
       
     ----- SNAP AREA MENU -----
     if snap_area_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(snap_area_xywh_buttons_t,0) == true then snap_area_values_t = {1, 0} ENGINE3_quantize_objects() end
       if MOUSE_clickhold_under_gui_rect(snap_area_xywh_buttons_t,4) == true then snap_area_values_t = {0, 1} ENGINE3_quantize_objects() end   
       
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
       if MOUSE_clickhold_under_gui_rect(snap_dir_xywh_buttons_t,0) == true then snap_dir_values_t = {1,0,0} ENGINE3_quantize_objects() end
       if MOUSE_clickhold_under_gui_rect(snap_dir_xywh_buttons_t,4) == true then snap_dir_values_t = {0,1,0} ENGINE3_quantize_objects() end
       if MOUSE_clickhold_under_gui_rect(snap_dir_xywh_buttons_t,8) == true then snap_dir_values_t = {0,0,1} ENGINE3_quantize_objects() end 
     end  
    end    
    if snap_area_values_t[1] == 1 then snap_dir_values_t = {0,1,0} end
    
     ----- SWING SCALE -----
     if swing_scale_xywh_buttons_t ~= nil then
       if MOUSE_clickhold_under_gui_rect(swing_scale_xywh_buttons_t,0) == true then 
         swing_scale_values_t = {1,0} swing_scale = 1 ENGINE3_quantize_objects() end
       if MOUSE_clickhold_under_gui_rect(swing_scale_xywh_buttons_t,4) == true then 
         swing_scale_values_t = {0,1} swing_scale = 0.5 ENGINE3_quantize_objects() end
     end  
     
     ------ dest NOTES ------      
     if sel_notes_mode_xywh_buttons_at ~= nil then
       if MOUSE_clickhold_under_gui_rect(sel_notes_mode_xywh_buttons_at,0) == true then sel_notes_mode_values_at = {1, 0} ENGINE3_quantize_objects() end
       if MOUSE_clickhold_under_gui_rect(sel_notes_mode_xywh_buttons_at,4) == true then sel_notes_mode_values_at = {0, 1} ENGINE3_quantize_objects() end
     end
     
     ------ SM ALL/TIMESELECTION ONLY destination ------      
     if sm_timesel_dest_xywh_buttons_t ~= nil then
     if MOUSE_clickhold_under_gui_rect(sm_timesel_dest_xywh_buttons_t,0) == true then sm_timesel_dest_values_t = {1, 0} ENGINE3_quantize_objects() end
     if MOUSE_clickhold_under_gui_rect(sm_timesel_dest_xywh_buttons_t,4) == true then sm_timesel_dest_values_t = {0, 1} ENGINE3_quantize_objects() end
     end  
  ---------------------  
   
  --|||-- BUTTONS -----     
     -- STORE PRESET BUTTON --
     if MOUSE_clickhold_under_gui_rect(store_preset_button_xywh_t,0) == true then 
        ENGINE4_save_preset()        
        end

     -- ABOUT BUTTON --
     if MOUSE_clickhold_under_gui_rect(about_button_xywh_t,0) == true then 
       reaper.ShowConsoleMsg("") reaper.ShowConsoleMsg(about..changelog) end
     
     -- HELP BUTTON --
     if MOUSE_clickhold_under_gui_rect(help_button_xywh_t,0) == true then 
     reaper.ShowConsoleMsg("") reaper.ShowConsoleMsg(help1) end  
     
     -- TODO BUTTON --
     if MOUSE_clickhold_under_gui_rect(todo_button_xywh_t,0) == true then 
     reaper.ShowConsoleMsg("") reaper.ShowConsoleMsg(todo..bugs) end   
     
     -- DONATE BUTTON --
     if MOUSE_clickhold_under_gui_rect(donate_button_xywh_t,0) == true then 
     open_URL() end  
             
   end -- if options page on
   
   end -- if snap >1
 end
        
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
function EXT_get_sub(key, last_value_s)
  if reaper.HasExtState("mplQT_settings", key) == true then
    value_s = reaper.GetExtState("mplQT_settings", key)         
    if last_value_s == nil then last_value_s = ""  end
    if value_s ~= last_value_s then
      value_ret = tonumber(value_s)    
      last_value_s_ret = value_s
      is_apply = true
      local value = value_ret
     else
      is_apply = false
    end  
  end 
  return last_value_s_ret, value_ret, is_apply
end

---------------------------------------------------------------------------------------------------------------
function EXT_get()
  if last_strenght_value_s_ret == nil then first_time_st = true else first_time_st = false end
  last_strenght_value_s_ret, strenght_value_ret, is_apply_strenght = EXT_get_sub("Strenght", last_strenght_value_s)
  if strenght_value_ret ~= nil and is_apply_strenght == true then 
    strenght_value = strenght_value_ret 
    last_strenght_value_s = last_strenght_value_s_ret
    if first_time_st == false then
      ENGINE3_quantize_objects() 
    end  
  end
  
  if last_swing_value_s_ret == nil then first_time_sw = true else first_time_sw = false end
  last_swing_value_s_ret, swing_value_ret, is_apply_swing = EXT_get_sub("Swing", last_swing_value_s)
  if swing_value_ret ~= nil and is_apply_swing == true then 
    swing_value = swing_value_ret 
    last_swing_value_s = last_swing_value_s_ret
    if first_time_sw == false then
      snap_mode_values_t = {0,1} 
      quantize_ref_values_t = {0, 0, 0, 0, 0, 0, 1}
      ENGINE1_get_reference_swing_grid()
      ENGINE1_get_reference_FORM_points()
      ENGINE3_quantize_objects() 
    end  
  end

  if last_grid_value_s_ret == nil then first_time_grid = true else first_time_grid = false end
  last_grid_value_s_ret, grid_value_ret, is_apply_grid = EXT_get_sub("Grid", last_grid_value_s)
  if grid_value_ret ~= nil and is_apply_grid == true then 
    grid_value = grid_value_ret 
    last_grid_value_s = last_grid_value_s_ret
    if first_time_grid == false then    
      snap_mode_values_t = {0,1} 
      quantize_ref_values_t = {0, 0, 0, 0, 0, 1, 0}
      ENGINE1_get_reference_grid()
      ENGINE1_get_reference_FORM_points()
      ENGINE3_quantize_objects() 
    end  
  end  
end     


---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

 function MAIN_exit()
   gfx.quit()
 end
 
 --------------------------------------------------------------------------------------------------------------- 
    
 function MAIN_run()      
   DEFINE_dynamic_variables()   
   GUI_DRAW()   
   MOUSE_get()  
   EXT_get()       
   test_var(test)
   char = gfx.getchar()  
   --ENGINE4_save_preset()
   if char == 27 then MAIN_exit() end     
   if char ~= -1 then reaper.defer(MAIN_run) else MAIN_exit() end
 end 
 
 main_w = 440
 main_h = 435
 gfx.init("mpl Quantize tool // ".."Version "..vrs, main_w, main_h)
 reaper.atexit(MAIN_exit) 
 
 DEFINE_default_variables()
 DEFINE_default_variables_GUI() 
 
 GET_grid() 
 if grid_beats ~= nil then
   ENGINE1_get_reference_grid()
   ENGINE1_get_reference_FORM_points()
 end  

 MAIN_run()
