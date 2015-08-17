------  Michael Pilyavskiy Quantize tool  ----
 vrs = "0.15 (beta)"
 
 -- known bugs :
 -- gravity doesn`t work properly
 -- apply quantize crashes reaper  
 
 -- to do:
 -- global/local snap selector
 -- blue lines represent objects to quantize
 -- lmb click on grid add groove point
 -- rmb click on grid delete groove point
 -- quantize/get groove tempo envelope
 -- quantize/get groove take envelope
 
 about = "Quantize tool by Michael Pilyavskiy ".."\n"..
         "Version "..vrs.."\n"..
         "\n"..
         "\n"..
         " -- Soundcloud -- soundcloud.com/mp57".."\n"..
         " -- PromoDJ --  pdj.com/michaelpilyavskiy".."\n"..
         " -- VK --  vk.com/MPL57".."\n"..         
         " -- GitHub --  github.com/MichaelPilyavskiy/ReaScripts".."\n"
         .."\n"
         .."\n"
         .."\n"
         
         
    .."Changelog:".."\n"
    .."\n"
    .."\n" 
    .."  15.07.2015 - 0.15 info message when snap > 1 to prevent reaper crash".."\n" 
    .."            ".."\n"
    .."\n"      
    .."  13.07.2015 - 0.141 stretch markers quantize when takerate not equal 1".."\n" 
    .."            get groove from stretch markers when takerate not equal 1".."\n" 
    .."            envelope points quantize engine, gui improvements".."\n"
    .."            ".."\n"
    .."\n"     
    .."  11.07.2015 - 0.13 swing follow bug, markers quantize engine rebuilded again...".."\n" 
    .."\n"       
    .."  09.07.2015 - 0.12 empty type swing window, project grid option,".."\n" 
    .."            swing linked to grid, bypass, toggle state 0.5s for mouse click".."\n" 
    .."            str_markers quantize improvements".."\n"
    .."            ".."\n"
    .."\n"  
    .."  07.07.2015 - 0.113 restore exit button, right click on swing to type swing,".."\n" 
    .."            swing 100% is half grid, info, quantize items bug,".."\n" 
    .."            user cancelled swing dialog, get stretch markers via srcpos,".."\n"
    .."            centered swing".."\n"
    .."\n"    
    .."  06.07.2015 - 0.092 gui, groove points compare bug,".."\n" 
    .."            stretch markers get/quantize bugfixes,".."\n" 
    .."            draw grid bug, gravity function building ".."\n"
    .."\n"      
    .."  04.07.2015 - 0.081 swing always 1/4 bug , custom grid, fontsize = 16".."\n"        
    .."            quantize engine improvements".."\n"
    .."\n"    
    .."  02.07.2015 - 0.07 new gui, performance improvements...".."\n"
    .."\n"    
    .."  01.07.2015 - 0.06 menu count numbers, strength slider, point gravity slider,".."\n"
    .."            quantize engine basics".."\n"
    .."\n"
    .."  30.06.2015 - 0.05 about,get project grid".."\n"
    .."\n"
    .."  28.06.2015 - 0.04 get_groove function building".."\n"
    .."\n"
    .."  27.06.2015 - 0.03 font, back, menus".."\n"
    .."\n"
    .."  25.06.2015 - 0.02 gfx, snap direction, swing gui fill gradient, swing engine".."\n"
    .."\n"
    .."  23.06.2015 - 0.01 idea".."\n"
    
  
 ---------------------------------------------------------------------------------------------------------------  
 
 function ENGINE_groove_compare(pos_beats)
  if groove_points_t ~= nil then
   GET_groove_gravity()
   for j = 1, #groove_points_t, 1 do -- compare with groove point 
     cur_groove_point = groove_points_t[j]
     if snap_behaviour_values[2] == 1 then -- if snap everything   
       if j ~= 1 then prev_groove_point = groove_points_t[j-1] else prev_groove_point = 0 end 
       if j + 1 > #groove_points_t then next_groove_point = bars*4 else next_groove_point = groove_points_t[j+1] end 
         ---------------------------------------------------------
         if snap_direction_values[1] == 1 then -- to previous point
           if pos_beats > cur_groove_point and pos_beats < next_groove_point then new_pos_temp = cur_groove_point end
         end --snap_direction_values[1] == 1  
         ---------------------------------------------------------       
         if snap_direction_values[2] == 1 then -- to closest point                 
           if pos_beats > cur_groove_point and pos_beats < cur_groove_point+(next_groove_point - cur_groove_point)/2 then new_pos_temp = cur_groove_point end
           
           if pos_beats > cur_groove_point and pos_beats > cur_groove_point+(next_groove_point - cur_groove_point)/2 then new_pos_temp = next_groove_point end
           if pos_beats == cur_groove_point  then new_pos_temp = cur_groove_point end
         end  --snap_direction_values[2] == 1         
         ---------------------------------------------------------
         if snap_direction_values[3] == 1 then -- to previous point
           if pos_beats > cur_groove_point and pos_beats < next_groove_point then new_pos_temp = next_groove_point end
         end --snap_direction_values[3] == 1                           
     end      
     if snap_behaviour_values[1] == 1 then         
         if  pos_beats >= cur_groove_point_zone_min_t[j] and pos_beats <= cur_groove_point_zone_max_t[j] 
          then new_pos_temp = cur_groove_point 
            else new_pos_temp = pos_beats 
         end         
     end                 
   end  -- for j = 1, #groove_points_t,  
   return new_pos_temp 
  end -- if  groove_points_t ~= nil
 end
 
 ---------------------------------------------------------------------------------------------------------------
  
 function ENGINE_quantize_items_restore()  
  if groove_points_t ~= nil then 
   for i = 1, #items_to_quantize_info_t, 1 do
     items_to_quantize = items_to_quantize_info_t[i]  
     item_guid, item_pos_time = items_to_quantize:match("([^_]+)_([^_]+)")
     current_item = reaper.BR_GetMediaItemByGUID(0, item_guid)
     reaper.SetMediaItemInfo_Value(current_item, "D_POSITION", item_pos_time) 
   end -- for items 
  end    
 end
 
 ---------------------------------------------------------------------------------------------------------------
 
 function ENGINE_quantize_items() 
  ENGINE_quantize_items_restore()
  if groove_points_t ~= nil then 
   for i = 1, #items_to_quantize_info_t, 1 do
     items_to_quantize = items_to_quantize_info_t[i]  
     item_guid, item_pos_time = items_to_quantize:match("([^_]+)_([^_]+)")
     current_item = reaper.BR_GetMediaItemByGUID(0, item_guid)
     item_pos_beats, item_pos_measure, item_pos_cmlOut = reaper.TimeMap2_timeToBeats(0, item_pos_time)
     new_pos_temp = ENGINE_groove_compare(item_pos_beats) 
     if new_pos_temp ~= nil then
       delta_pos0 = (new_pos_temp - item_pos_beats)*(strength/100)
       delta_pos = BYPASS_engine(delta_pos0)
       item_new_pos = item_pos_beats + delta_pos   
       item_new_pos_time = reaper.TimeMap2_beatsToTime(0, item_new_pos, item_pos_measure)
       reaper.SetMediaItemInfo_Value(current_item, "D_POSITION", item_new_pos_time) 
     end  
   end -- for items 
  end   
 end -- func      
 
 ---------------------------------------------------------------------------------------------------------------
 
  function ENGINE_quantize_str_markers_restore()
   if   str_markers_to_quantize_info_t ~= nil and groove_points_t ~= nil then 
     for i = 1, #str_markers_to_quantize_info_t, 1 do
       str_markers_to_quantize = str_markers_to_quantize_info_t[i]
       take_guid  = str_markers_to_quantize:match("([^_]+)")        
       current_take = reaper.SNM_GetMediaItemTakeByGUID(0, take_guid)          
       count_stretch_markers = reaper.GetTakeNumStretchMarkers(current_take)
       for i = 1, count_stretch_markers, 1 do
         reaper.DeleteTakeStretchMarkers(current_take, i-1)
       end       
     end
     
     for i = 1, #str_markers_to_quantize_info_t, 1 do
       str_markers_to_quantize = str_markers_to_quantize_info_t[i]
       take_guid, spos, ssrcpos  = str_markers_to_quantize:match("([^_]+)_([^_]+)_([^_]+)")
       pos, srcpos = tonumber(spos),tonumber(ssrcpos)
       reaper.SetTakeStretchMarker(current_take, -1, pos, srcpos)
     end 
   end    
 end
 
 ---------------------------------------------------------------------------------------------------------------
        
 function ENGINE_quantize_str_markers()   
   ENGINE_quantize_str_markers_restore() 
   if   str_markers_to_quantize_info_t ~= nil and groove_points_t ~= nil then 
    for i = 1, #str_markers_to_quantize_info_t, 1 do
      -- get guid from string        
      str_markers_to_quantize = str_markers_to_quantize_info_t[i]
      take_guid = str_markers_to_quantize:match("([^_]+)")   
      
      -- get info 
      current_take = reaper.SNM_GetMediaItemTakeByGUID(0, take_guid)
      current_item = reaper.GetMediaItemTake_Item(current_take)     
      current_item_pos_time = reaper.GetMediaItemInfo_Value(current_item, "D_POSITION")
      current_item_len_time = reaper.GetMediaItemInfo_Value(current_item, "D_LENGHT")
      
      current_take_rate = reaper.GetMediaItemTakeInfo_Value(current_take, "D_PLAYRATE")
      -- execute through all markers markers
      
      count_stretch_markers = reaper.GetTakeNumStretchMarkers(current_take)      
      for j = 1, count_stretch_markers, 1 do
        
        retval, str_marker_pos_time, str_marker_srcpos_time = reaper.GetTakeStretchMarker(current_take, j-1)
        
        str_marker_pos_time_true = str_marker_pos_time/current_take_rate + current_item_pos_time  
        str_marker_pos_beats, str_marker_pos_measure, str_marker_pos_cmlOut = reaper.TimeMap2_timeToBeats(0, str_marker_pos_time_true)
        new_pos_temp = ENGINE_groove_compare(str_marker_pos_beats)             
        delta_pos0 = (new_pos_temp - str_marker_pos_beats)*(strength/100)                   
        delta_pos = BYPASS_engine(delta_pos0)
        
        str_marker_new_pos = str_marker_pos_beats + delta_pos
        str_marker_new_pos_time = reaper.TimeMap2_beatsToTime(0, str_marker_new_pos, str_marker_pos_measure)
        str_marker_new_pos_time_intake = (str_marker_new_pos_time - current_item_pos_time)*current_take_rate
        
        reaper.SetTakeStretchMarker(current_take, j-1, str_marker_new_pos_time_intake)
        
      end
    end  -- for i = 1, #str_markers_to_quantize_info_t
   end  
 end -- func   
 
 ---------------------------------------------------------------------------------------------------------------
  
 function BYPASS_engine(delta_pos0)
   if bypass == false then
     if new_pos_temp ~= nil then 
       delta_pos = delta_pos0
      else 
       delta_pos = 0 
     end 
    else  
     delta_pos = 0
   end
   return delta_pos
 end
 
 ---------------------------------------------------------------------------------------------------------------
 
 function ENGINE_quantize_env_points_restore()
   if groove_points_t ~= nil then 
     for i = 1, #envelope_points_to_quantize_info_t, 1 do
       envelope_points_to_quantize = envelope_points_to_quantize_info_t[i]  
       track_guid, env_num_s, point_num_s, value_s, position_s, shape_s,bezier_s = 
       envelope_points_to_quantize:match("([^_]+)_([^_]+)_([^_]+)_([^_]+)_([^_]+)_([^_]+)_([^_]+)") 
       
       env_num = tonumber(env_num_s)  -1
       point_num = tonumber(point_num_s)  -1
       value = tonumber(value)  
       position = tonumber(position_s)  
       shape = tonumber(shape_s)  
       bezier = tonumber(bezier_s)
       
       track = reaper.BR_GetMediaTrackByGUID(0, track_guid)  
       TrackEnvelope = reaper.GetTrackEnvelope(track, env_num) 
       if TrackEnvelope ~= nil then
         BR_Envelope = reaper.BR_EnvAlloc(TrackEnvelope, true)     
         reaper.BR_EnvSetPoint(BR_Envelope, point_num, position, value, shape, true, bezier)     
         reaper.BR_EnvFree(BR_Envelope, true)     
       end    
     end -- for 
   end  
 end
 
 ---------------------------------------------------------------------------------------------------------------
 
 function ENGINE_quantize_env_points()
   ENGINE_quantize_env_points_restore()
   if groove_points_t ~= nil then 
     for i = 1, #envelope_points_to_quantize_info_t, 1 do
       envelope_points_to_quantize = envelope_points_to_quantize_info_t[i]  
       track_guid, env_num_s, point_num_s, value_s, position_s, shape_s,bezier_s = 
         envelope_points_to_quantize:match("([^_]+)_([^_]+)_([^_]+)_([^_]+)_([^_]+)_([^_]+)_([^_]+)") 
         
       env_num = tonumber(env_num_s)  -1
       point_num = tonumber(point_num_s)  -1
       value = tonumber(value)  
       position = tonumber(position_s)  
       shape = tonumber(shape_s)  
       bezier = tonumber(bezier_s)
               
       track = reaper.BR_GetMediaTrackByGUID(0, track_guid)  
       TrackEnvelope = reaper.GetTrackEnvelope(track, env_num) 
       if TrackEnvelope ~= nil then
         BR_Envelope = reaper.BR_EnvAlloc(TrackEnvelope, true)
         envelope_point_pos_beats, envelope_point_pos_measure, envelope_point_pos_cmlOut = 
           reaper.TimeMap2_timeToBeats(0, position)
         new_pos_temp = ENGINE_groove_compare(envelope_point_pos_beats)  
              
         delta_pos0 = (new_pos_temp - envelope_point_pos_beats)*(strength/100)                   
         delta_pos = BYPASS_engine(delta_pos0)  
           
         envelope_point_pos_beats_new = envelope_point_pos_beats + delta_pos
         envelope_point_pos_time = reaper.TimeMap2_beatsToTime(0, envelope_point_pos_beats_new, envelope_point_pos_measure)
         reaper.BR_EnvSetPoint(BR_Envelope, point_num, envelope_point_pos_time, value, shape, true, bezier)
         
         reaper.BR_EnvFree(BR_Envelope, true)     
       end    
     end -- for  
    end     
 end
 ---------------------------------------------------------------------------------------------------------------
  
 function ENGINE_QUANTIZE()  
   if quantize_dest_values[1] == 1 then ENGINE_quantize_items() end
   if quantize_dest_values[2] == 1 then ENGINE_quantize_str_markers() end
   if quantize_dest_values[3] == 1 then ENGINE_quantize_env_points() end  
 end 
  
 ---------------------------------------------------------------------------------------------------------------
  
 function table.replace(table_name, i, value)
   table.insert(table_name, i, value)
   table.remove(table_name, i+1) 
 end
 
 ---------------------------------------------------------------------------------------------------------------
  
  function table.sum(table_name) 
    local sum = 0
    for i=1, #table_name, 1 do
      sum = sum + table_name[i]
    end
    return sum  
  end 
  
 ---------------------------------------------------------------------------------------------------------------
    
 function round(num, idp)
   local mult = 10^(idp or 0)
   return math.floor(num * mult + 0.5) / mult
 end     
    
 ---------------------------------------------------------------------------------------------------------------    
 
 function GET_grid()
  project_grid_time = reaper.BR_GetNextGridDivision(0)
  project_grid_beats, project_grid_measures, project_grid_cml = reaper.TimeMap2_timeToBeats(0, project_grid_time)
  
  
  if quantize_ref_values[5] == 1 then 
   if set_grid == 4 then
      get_grid = project_grid_beats  
     else 
      get_grid = set_grid
   end  
  else  
   get_grid = project_grid_beats   
  end
  
  if quantize_ref_values[6] == 1 then 
    if set_grid == 4 then
      get_grid = project_grid_beats  
     else 
      get_grid = set_grid
    end 
  end
  
  
  divider_r = round(4/get_grid, 1) 
   if  divider_r % 3 == 0 then  --grid_temp_v1 > 0 then 
     is_grid_triplet = true      
    else 
     is_grid_triplet = false 
   end      
   if project_grid_measures == 0 then
     if is_grid_triplet == true then grid_string = "1/"..tostring(  math.ceil(round(4/get_grid/3*2),1) )  .."T"
                                else grid_string = "1/"..tostring(math.ceil(4/get_grid)) end
     execute_mouse = 1                           
    else 
     execute_mouse = 0
     grid_string = ""
   end     
   get_grid = round(get_grid, 6) 
   return  grid_time, get_grid, is_grid_triplet, grid_string
 end 
 
 
 --------------------------------------------------------------------------------------------------------------- 
 
 function GET_groove_from_items()
    items_pos_t = {}        
    count_sel_ref_items = reaper.CountSelectedMediaItems(0) 
    if count_sel_ref_items > 0 then   -- get measures beetween items
      for i = 1, count_sel_ref_items, 1 do
        ref_item = reaper.GetSelectedMediaItem(0, i-1)          
        ref_item_pos = reaper.GetMediaItemInfo_Value(ref_item, "D_POSITION")          
        ref_item_pos_beats, ref_item_pos_measure, ref_item_pos_cmlOut = reaper.TimeMap2_timeToBeats(0, ref_item_pos)
        ref_item_pos_beats_compute = round(ref_item_pos_beats + ref_item_pos_measure * ref_item_pos_cmlOut, 4)
        table.insert(items_pos_t, ref_item_pos_beats_compute)  
      end 
    end            
    if count_sel_ref_items ~= nil and count_sel_ref_items > 0 then
        table.sort(items_pos_t, function(a,b) return a<b end)
        items_pos_max = items_pos_t[#items_pos_t]            
        table.sort(items_pos_t, function(a,b) return a>b end)
        items_pos_min = items_pos_t[#items_pos_t]         
        offset_grid = math.floor(items_pos_min/4)*ref_item_pos_cmlOut
        for i = 1, #items_pos_t, 1 do
          items_pos2 = items_pos_t[i] - offset_grid
          table.insert(groove_points_t, items_pos2)           
          table.sort(groove_points_t)
        end  
        bars = math.ceil(math.ceil(items_pos_max - offset_grid)/ref_item_pos_cmlOut)        
    end -- count_sel_ref_items > 0
    items_pos_t_size = #items_pos_t 
  end        
 
 --------------------------------------------------------------------------------------------------------------- 
 
 function GET_groove_from_str_mark()   
   str_mark_t = {}       
   count_sel_ref_items = reaper.CountSelectedMediaItems(0)  
   if count_sel_ref_items ~= nil then   -- get measures beetween items
     for i = 1, count_sel_ref_items, 1 do
     ref_item = reaper.GetSelectedMediaItem(0, i-1)   
       if ref_item ~= nil then
         ref_take = reaper.GetActiveTake(ref_item)
         if ref_take ~= nil then    
           takerate = reaper.GetMediaItemTakeInfo_Value(ref_take, "D_PLAYRATE" )           
           str_markers_count = reaper.GetTakeNumStretchMarkers(ref_take) 
           if  str_markers_count ~= nil then
             for i = 1, str_markers_count, 1 do
             
              ref_item_pos = reaper.GetMediaItemInfo_Value(ref_item, "D_POSITION")
              ref_item_pos_beats, ref_item_pos_measure, ref_item_pos_cmlOut = reaper.TimeMap2_timeToBeats(0, ref_item_pos)                               
              ref_item_len = reaper.GetMediaItemInfo_Value(ref_item, "D_LENGTH")
              ref_item_len_beats, ref_item_len_measure, ref_item_len_cmlOut = reaper.TimeMap2_timeToBeats(0, ref_item_len)
             
              retval, ref_str_mark_pos = reaper.GetTakeStretchMarker(ref_take, i-1)               
              if ref_str_mark_pos >= ref_item_pos and ref_str_mark_pos <= ref_item_pos + ref_item_len then
                ref_str_mark_pos_beats, ref_str_mark_pos_measure, ref_str_mark_pos_cml  = 
                reaper.TimeMap2_timeToBeats(0, ref_item_pos + ref_str_mark_pos/takerate)    
                table.insert(str_mark_t, ref_str_mark_pos_beats)                 
              end  
             end -- for
           end -- str_markers_count ~= nil
         end -- if take not nil         
       end -- if item not nil  
     end -- forcount sel items       
   end -- if sel items >0 
   str_mark_t_size = #str_mark_t   
   if str_markers_count ~= nil and str_markers_count > 0 then
     table.sort(str_mark_t, function(a,b) return a<b end)
     str_mark_max = str_mark_t[#str_mark_t]            
     table.sort(str_mark_t, function(a,b) return a>b end)
     str_mark_min = str_mark_t[#str_mark_t]         
     offset_grid = math.floor(str_mark_min/4)*ref_item_pos_cmlOut
     for i = 1, #str_mark_t, 1 do
       str_mark = str_mark_t[i] - offset_grid
       table.insert(groove_points_t, str_mark)           
       table.sort(groove_points_t)
     end  
     bars = math.ceil(math.ceil(str_mark_max - offset_grid)/ref_item_pos_cmlOut)
   end -- count_sel_ref_items > 0]]
 end
 
 --------------------------------------------------------------------------------------------------------------- 
 
 function GET_groove_from_env_points()   
   env_point_t = {}                     
   envelope = reaper.GetSelectedTrackEnvelope(0)
   if envelope ~= nil then
    envelope_points_count = reaper.CountEnvelopePoints(envelope)
    if envelope_points_count > 0 then
     for i = 1, envelope_points_count, 1  do
       retval, ep_pos, value, shape, tension, isselected = reaper.GetEnvelopePoint(envelope, i-1)
       if isselected == true then
         ep_pos_beats, ep_pos_measure, ep_pos_cmlOut  = reaper.TimeMap2_timeToBeats(0, ep_pos)
         ep_pos_compute = round(round(ep_pos_beats, 2) + ep_pos_measure*ep_pos_cmlOut, 2)
         if ep_pos_compute < 0 then
           ep_pos_compute = 0
         end  
         table.insert(env_point_t, ep_pos_compute)
       end -- if selected  
     end -- loop env points
    end  --envelope_points_count > 0
   end -- envelope not nil
   if envelope_points_count ~= nil then
     table.sort(env_point_t, function(a,b) return a<b end)
     ep_pos_max = env_point_t[#env_point_t]            
     table.sort(env_point_t, function(a,b) return a>b end)
     ep_pos_min = env_point_t[#env_point_t] 
     offset_grid_ep_pos = math.floor(ep_pos_min/4)*ep_pos_cmlOut      
     for i = 1, #env_point_t, 1 do
       ep_pos = env_point_t[i] - offset_grid_ep_pos   
       table.insert(groove_points_t, ep_pos)  
       table.sort(groove_points_t)
     end 
     bars = math.ceil(math.ceil(ep_pos_max - offset_grid_ep_pos)/ep_pos_cmlOut)      
   end 
   env_point_t_size = #env_point_t  
 end
 
 --------------------------------------------------------------------------------------------------------------- 
 
 function GET_groove_from_MIDI()  
    count_sel_ref_items = reaper.CountSelectedMediaItems(0)
     notes_t = {}      
     if count_sel_ref_items > 0 then   -- get measures beetween items
       for i = 1, count_sel_ref_items, 1 do
         ref_item = reaper.GetSelectedMediaItem(0, i-1)
         if ref_item ~= nil then
           ref_take = reaper.GetActiveTake(ref_item)
           if ref_take ~= nil then
             if reaper.TakeIsMIDI(ref_take) ==  true then   
               retval, notecntOut, ccevtcntOut = reaper.MIDI_CountEvts(ref_take)
               if notecntOut > 0 then
                 for i = 1, notecntOut, 1 do                 
                   retval, selectedOut, mutedOut, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(ref_take, i-1)
                   startppqpos_sec = reaper.MIDI_GetProjTimeFromPPQPos(ref_take, startppqpos)
                   notepos_beats, notepos_measure, notepos_cmlout  = reaper.TimeMap2_timeToBeats(0, startppqpos_sec)
                   notepos_beats_compute_r = round(notepos_beats, 4) + notepos_measure * notepos_cmlout                   
                   table.insert(notes_t, notepos_beats_compute_r) 
                 end -- count notes                   
               end -- notecntOut > 0
             end -- TakeIsMIDI
           end -- ref_take ~= nil 
         end-- ref_item ~= nil
       end -- for count_sel_ref_items
     end --   count_sel_ref_items > 0 
     notes_t_size = #notes_t  
     if notecntOut ~= nil and notecntOut > 0 then
       table.sort(notes_t, function(a,b) return a<b end)
       notes_max = notes_t[#notes_t]            
       table.sort(notes_t, function(a,b) return a>b end)
       notes_min = notes_t[#notes_t] 
       bars = math.ceil(math.ceil(notes_max - notes_min) / notepos_cmlout)               
       offset_grid_notes = math.floor(notes_min/4) * notepos_cmlout
       for i = 1, #notes_t, 1 do
         notes = notes_t[i] - offset_grid_notes   
         table.insert(groove_points_t, notes)  
         table.sort(groove_points_t)
       end
     end          
 end   
 
 ---------------------------------------------------------------------------------------------------------------
   
 function GET_groove_from_project_grid()
   grid_time, grid_set = GET_grid()          
   grid_beats_r1 = 0     
   inc = grid_set  
   for i = 0, bars*4, inc do
   table.insert(groove_points_t, grid_beats_r1)
   grid_beats_r1 = grid_beats_r1 + grid_set
   end
   bars = 1 
 end 
 
 --------------------------------------------------------------------------------------------------------------- 
   
function GET_groove_from_swing_grid()    
   grid_time, grid_set1 = GET_grid()
   bars = 1
   loop_cycles = bars*4 / grid_set1  
   swing_groove = 0
   for i = 0, loop_cycles, 1 do       
    if i % 2 == 0 then         
      table.insert(groove_points_t, swing_groove)
     elseif i % 2 == 1 then
      swing_groove1 = swing_groove + swing/200 * grid_set1
      table.insert(groove_points_t, swing_groove1)
    end
    swing_groove = swing_groove + grid_set1  
    end   
  end    
 
 --------------------------------------------------------------------------------------------------------------- 
 
  function GET_groove_gravity()  
   cur_groove_point_zone_min_delta_t = {}
   cur_groove_point_zone_max_delta_t = {} 
   cur_groove_point_zone_min_t = {}
   cur_groove_point_zone_max_t = {} 
   -- make table for zones
   for j = 1, #groove_points_t, 1 do 
     if j == 1                then prev_groove_point = 0 else      prev_groove_point = groove_points_t[j-1] end     
     if j == #groove_points_t then next_groove_point = 4*bars else next_groove_point = groove_points_t[j+1] end
     cur_groove_point = groove_points_t[j]  
       
     if j == 1 then 
                    table.insert(cur_groove_point_zone_min_delta_t, j, 0)
                    table.insert(cur_groove_point_zone_max_delta_t, j, (next_groove_point - cur_groove_point)/2) end
     if j > 1 and j <= #groove_points_t then 
                    table.insert(cur_groove_point_zone_min_delta_t, j, (cur_groove_point - prev_groove_point)/2)      
                    table.insert(cur_groove_point_zone_max_delta_t, j, (next_groove_point - cur_groove_point)/2) end
     if j == #groove_points_t then 
                    table.insert(cur_groove_point_zone_min_delta_t, j, (cur_groove_point - prev_groove_point)/2)      
                    table.insert(cur_groove_point_zone_max_delta_t, j, 0) end   
   end    
      
   -- edit table
   for j = 1, #groove_points_t, 1 do 
     if j == 1                then prev_groove_point = 0 else      prev_groove_point = groove_points_t[j-1] end     
     if j == #groove_points_t then next_groove_point = 4*bars else next_groove_point = groove_points_t[j+1] end
     cur_groove_point = groove_points_t[j]  
     
     table.insert(cur_groove_point_zone_min_t, j, cur_groove_point - cur_groove_point_zone_min_delta_t[j]*(gravity/100))
     table.insert(cur_groove_point_zone_max_t, j, cur_groove_point + cur_groove_point_zone_max_delta_t[j]*(gravity/100))
   end -- edit ]]  
  end 
 
 --------------------------------------------------------------------------------------------------------------- 
 
 function GET_groove_engine ()     
  groove_points_t = {} 
        
  if quantize_ref_values[1] == 1 then GET_groove_from_items() end
  if quantize_ref_values[2] == 1 then GET_groove_from_str_mark() end  
  if quantize_ref_values[3] == 1 then GET_groove_from_env_points()  end   
  if quantize_ref_values[4] == 1 then GET_groove_from_MIDI()  end
  if quantize_ref_values[5] == 1 then GET_groove_from_project_grid() end
  if quantize_ref_values[6] == 1 then GET_groove_from_swing_grid()   end      
  if groove_points_t == nil then groove_points_t = {0,0,0,0} end   
  if items_pos_t_size == nil then ref_items_count_info = 0 else ref_items_count_info = items_pos_t_size end  
  if str_mark_t_size == nil then ref_str_markers_count_info = 0 else ref_str_markers_count_info = str_mark_t_size end
  if env_point_t_size == nil then ref_envelope_points_count_info = 0 else ref_envelope_points_count_info = env_point_t_size end
  if notes_t_size == nil then ref_notes_count_info = 0 else ref_notes_count_info = notes_t_size end
  get_groove_engine_values = {ref_items_count_info, ref_str_markers_count_info, ref_envelope_points_count_info, ref_notes_count_info}  
    
end
  
 ---------------------------------------------------------------------------------------------------------------
  
 function GET_objects_to_quantize_env_points()
  new_pos_t = {}
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
              BR_Envelope = reaper.BR_EnvAlloc(TrackEnvelope, true)
              count_env_points = reaper.BR_EnvCountPoints(BR_Envelope)
              if count_env_points ~= nil then 
                for k = 1, count_env_points, 1 do    
                  retval, position, value, shapeOut, selected, bezier = reaper.BR_EnvGetPoint(BR_Envelope, k-1)
                  if selected == true then                  
--[[ store point ]] envelope_points_info = track_guid.."_"..j.."_"..k.."_"..value.."_"..position.."_"..shapeOut.."_"..bezier
                    table.insert(envelope_points_to_quantize_info_t, envelope_points_info)
                    table.insert(new_pos_t, position)
                  end
                end -- loop env points  
              end  -- count_env_points ~= nil        
              reaper.BR_EnvFree(BR_Envelope, true) 
            end -- TrackEnvelope ~= nil
          end -- loop enelopes
        end -- count_envelopes ~= nil  
      end -- track~= nil
    end  -- loop count_tracks
  end -- count_tracks ~= nil  
 end 
  
 ---------------------------------------------------------------------------------------------------------------
  
 function GET_objects_to_quantize_markers()
  new_pos_t = {}
  count_sel_items = reaper.CountSelectedMediaItems(0)
  if count_sel_items ~= nil then 
    count_stretch_markers_com = 0
    for i = 1, count_sel_items, 1 do
      item = reaper.GetSelectedMediaItem(0, i-1)      
      take = reaper.GetActiveTake(item)      
      if take ~= nil then
        take_guid = reaper.BR_GetMediaItemTakeGUID(take)        
        count_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
        if count_stretch_markers ~= nil then
          for j = 1, count_stretch_markers,1 do
            retval, posOut, srcpos = reaper.GetTakeStretchMarker(take, j-1) 
            str_marker_info = take_guid.."_"..posOut.."_"..srcpos
            --if posOut > 0 and srcpos > 0 then
--[[ store str.maker ]]  
              table.insert(str_markers_to_quantize_info_t, str_marker_info) 
              table.insert(new_pos_t, posOut)
            --end  
          end -- loop takes  
        end -- count_stretch_markers ~= nil 
      end -- take ~= nil      
      count_stretch_markers_com = count_stretch_markers_com + count_stretch_markers
    end -- item loop
  end -- count_sel_items ~= nil
 end   
  
  ---------------------------------------------------------------------------------------------------------------
  
 function GET_objects_to_quantize_items()
 new_pos_t = {}
  count_sel_items = reaper.CountSelectedMediaItems(0)
  if count_sel_items ~= nil then     
    for i = 1, count_sel_items, 1 do
      item = reaper.GetSelectedMediaItem(0, i-1)
      item_guid = reaper.BR_GetMediaItemGUID(item) 
      item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")      
      item_info_string = item_guid.."_"..item_pos
--[[ store item ]]  
      table.insert(items_to_quantize_info_t, i, item_info_string)
      table.insert(new_pos_t, item_pos)       
    end -- item loop
  end -- count_sel_items ~= nil
 end 
 
  ---------------------------------------------------------------------------------------------------------------
   
function GET_objects_to_quantize() local item, item_pos, count_sel_items, guid
  items_to_quantize_info_t = {}
  str_markers_to_quantize_info_t = {}
  envelope_points_to_quantize_info_t = {} 
   
  if quantize_dest_values[1] == 1 then GET_objects_to_quantize_items() end
  if quantize_dest_values[2] == 1 then GET_objects_to_quantize_markers() end
  if quantize_dest_values[3] == 1 then GET_objects_to_quantize_env_points() end  
  
  items_count_info = #items_to_quantize_info_t
  str_markers_count_info = #str_markers_to_quantize_info_t
  envelope_points_count_info = #envelope_points_to_quantize_info_t    
  quantize_dest_objects = {items_count_info, str_markers_count_info, envelope_points_count_info}
  quantize_dest_objects_com = table.sum(quantize_dest_objects)  
end  
    
 ---------------------------------------------------------------------------------------------------------------   
        
function GUI_background ()
  gfx.r, gfx.g, gfx.b, gfx.a = 0.2, 0.2, 0.2, 1
  gfx.rect(0,0,main_w,main_h)
end 

 ---------------------------------------------------------------------------------------------------------------
 
function GUI_GRID_rect () 
  if is_mouse_on_rect == true then a = 0.8 else a = 0.5 end
  gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, a
  gfx.roundrect(object_rect_coord_t[1], object_rect_coord_t[2],object_rect_coord_t[3], object_rect_coord_t[4],0.1, true)
end 

    
---------------------------------------------------------------------------------------------------------------    
    
function GUI_button (is_button_pressed, name, object_coord_t)
  if is_button_pressed == true then button_a = 1 else button_a = 0.6  end   
  gfx.r, gfx.g, gfx.b, gfx.a = 0.5, 0.4, 0.4, button_a
  gfx.roundrect(object_coord_t[1], 
                object_coord_t[2], 
                object_coord_t[3], 
                object_coord_t[4],0.1,true) 
  gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, show_gui_help
  gfx.roundrect(object_coord_t[1], 
                object_coord_t[2],  
                object_coord_t[3], 
                object_coord_t[4],0.1,true)   
  gfx.setfont(1,font, fontsize, b)
  local measurestr = gfx.measurestr(name) 
  w1,w2 = name:match("([^ ]+) ([^ ]+)")   
  
  if w2 == nil then--measurestr < object_coord_t[3] then
    gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = object_coord_t[1] + (object_coord_t[3] - measurestr)/2, 
                                             object_coord_t[2] + (object_coord_t[4] - fontsize)/2   , 0.4, 1, 0.4, button_a
    gfx.drawstr(name)  
   else 
     local measurestr1 = gfx.measurestr(w1)
     
     local measurestr2 = gfx.measurestr(w2)
    gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = object_coord_t[1] + (object_coord_t[3] - measurestr1)/2, 
                                               object_coord_t[2] + (object_coord_t[4] - fontsize)/2 - fontsize/2  , 0.4, 1, 0.4, button_a
    gfx.drawstr(w1) 
    gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = object_coord_t[1] + (object_coord_t[3] - measurestr2)/2, 
                                               object_coord_t[2] + (object_coord_t[4] - fontsize)/2 + fontsize/2  , 0.4, 1, 0.4, button_a
    gfx.drawstr(w2) 
   end 
end

---------------------------------------------------------------------------------------------------------------     

function GUI_menu (object_coord_t, names, values, num_buttons, is_selected, is_red1, is_red2)
   x = object_coord_t[1]
   y = object_coord_t[2]
   w = object_coord_t[3]
   h = object_coord_t[4]
   if is_selected == true then
      gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 0.5     
     else
      gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 0.1      
   end   
   gfx.roundrect(x,y,w,h,0.1,true)
   pattern = "([^,]+),([^,]+)"
   for i = 1, num_buttons - 1, 1 do
     pattern = pattern..",([^,]+)"
   end  
   y = y + (h - ((num_buttons+1) * fontsize + (num_buttons-2)*2) ) / 2
   name, b1, b2, b3, b4, b5, b6, b7 = names:match(pattern) 
   gfx.setfont(1,font, fontsize, b)   
   gfx.x = x
   gfx.y = y      
   measurestr_space = gfx.measurestr(" ")
   local measurestrname = gfx.measurestr(name)   
   local measurestr1 = gfx.measurestr(b1)
   local measurestr2 = gfx.measurestr(b2)
   local measurestr3 = gfx.measurestr(b3)
   local measurestr4 = gfx.measurestr(b4)
   local measurestr5 = gfx.measurestr(b5) 
   local measurestr6 = gfx.measurestr(b6) 
   local measurestr7 = gfx.measurestr(b7)    
   gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 1
   gfx.x = x + (w - measurestrname)/2
   gfx.drawstr(name)   
   x1 = x
   y1 = y + fontsize
   w1 = w
   h1 = fontsize
   gfx.x = x1
   gfx.y = y1   
   gfx.a = show_gui_help
   gfx.roundrect(x1,y1,w1,h1,0.1,true) 
   alpha = values[1] * 0.8 + 0.2   
   gfx.r, gfx.g, gfx.b, gfx.a = 0.4, 1, 0.4, alpha
   gfx.x = x + (w - measurestr1)/2
   gfx.drawstr(b1) 
   
   x2 = x
   y2 = y1 + fontsize + 2
   w2 = w
   h2 = fontsize
   gfx.x = x2
   gfx.y = y2   
   gfx.a = show_gui_help
   gfx.roundrect(x2,y2,w2,h2,0.1,true) 
   alpha = values[2] * 0.8 + 0.2     
   gfx.r, gfx.g, gfx.b, gfx.a = 0.4, 1, 0.4, alpha
   gfx.x = x + (w - measurestr2)/2
   gfx.drawstr(b2) 
   
   if b3 ~= nil then   
     x3 = x
     y3 = y2 + fontsize + 2
     w3 = w
     h3 = fontsize
     gfx.x = x3
     gfx.y = y3   
     gfx.a = show_gui_help
     gfx.roundrect(x3,y3,w3,h3,0.1,true) 
     alpha = values[3] * 0.8 + 0.2      
     gfx.r, gfx.g, gfx.b, gfx.a = 0.4, 1, 0.4, alpha
     gfx.x = x + (w - measurestr3)/2
     gfx.drawstr(b3) 
    else
     x3, y3, w3, h3 = 0,0,0,0
   end  
   
   if b4 ~= nil then
     x4 = x
     y4 = y3 + fontsize + 2
     w4 = w
     h4 = fontsize
     gfx.x = x4
     gfx.y = y4   
     gfx.a = show_gui_help
     gfx.roundrect(x4,y4,w4,h4,0.1,true) 
     alpha = values[4] * 0.8 + 0.2      
     gfx.r, gfx.g, gfx.b, gfx.a = 0.4, 1, 0.4, alpha
     gfx.x = x + (w - measurestr4)/2
     gfx.drawstr(b4) 
    else
     x4, y4, w4, h4 = 0,0,0,0
   end  
   
   if b5 ~= nil then
     x5 = x
     y5 = y4 + fontsize + 2
     w5 = w
     h5 = fontsize
     gfx.x = x5
     gfx.y = y5   
     gfx.a = show_gui_help
     gfx.roundrect(x5,y5,w5,h5,0.1,true) 
     alpha = values[5] * 0.8 + 0.2      
     gfx.r, gfx.g, gfx.b, gfx.a = 0.4, 1, 0.4, alpha
     gfx.x = x + (w - measurestr5)/2
     gfx.drawstr(b5) 
    else
     x5, y5, w5, h5 = 0,0,0,0
   end  
   
   if b6 ~= nil then
     x6 = x
     y6 = y5 + fontsize + 2
     w6 = w
     h6 = fontsize
     gfx.x = x6
     gfx.y = y6   
     gfx.a = show_gui_help
     gfx.roundrect(x6,y6,w6,h6,0.1,true) 
     alpha = values[6] * 0.8 + 0.2        
     gfx.r, gfx.g, gfx.b, gfx.a = 0.4, 1, 0.4, alpha
     gfx.x = x + (w - measurestr6)/2
     gfx.drawstr(b6) 
    else
     x6, y6, w6, h6 = 0,0,0,0
   end  
   
   coord_buttons_data = {x1, y1, w1, h1,
                         x2, y2, w2, h2,
                         x3, y3, w3, h3,
                         x4, y4, w4, h4,
                         x5, y5, w5, h6,
                         x6, y6, w6, h6}
   return coord_buttons_data
end  

--------------------------------------------------------------------------------------------------------------- 

function GUI_GRID_draw()
  grid_time, grid_beats, is_grid_triplet = GET_grid() 
  x1 = object_rect_coord_t[1]
  y1 = object_rect_coord_t[2]+(object_rect_coord_t[4]/2) 
  x2 = object_rect_coord_t[3]
  gfx.r, gfx.g, gfx.b,gfx.a = 1,1,1,0.2
  gfx.line(x1, y1, x2, y1, 0.9)
  if is_grid_triplet == 1 then
    stripes_in_bar = round(bars*(4 / grid_beats), 4)  + 1 --   bug
   else  
    stripes_in_bar = round(bars*(4 / grid_beats), 4)
   end 
  gfx.x = x1
  gfx.y = y1  
  for i = 0, stripes_in_bar*bars, 1 do
   delta = object_rect_coord_t[3] / (stripes_in_bar*bars)
   dy1 = 3
   dy2 = 7
   dy3 = 13
   dy4 = 17
   dy5 = 25
   if is_grid_triplet == false then
     dy = dy1--y1 + 5
     if i % 2 == 0 then dy = dy2 end 
     if i % 4 == 0 then dy = dy3 end
     if i % 8 == 0 then dy = dy4 end
     if i % 16 == 0 then dy = dy5 end  
    else
     dy = dy1--y1 + 5
     if i % 3 == 0 then dy = dy2 end 
     if i % 6 == 0 then dy = dy3 end
     if i % 12 == 0 then dy = dy4 end
     if i % 24 == 0 then dy = dy5 end   
   end    
   gfx.r, gfx.g, gfx.b,gfx.a = 1,1,1,0.5
   gfx.line(x1, y1, x1, y1 - dy, 0.9)
   gfx.line(x1, y1, x1, y1 + dy, 0.9)
   x1 = x1 + delta
   
  end  
   
end

---------------------------------------------------------------------------------------------------------------

function GUI_GRID_play_pos() local x1, y1, x2, y2
  playpos= reaper.GetPlayPosition()    
  playpos_beats, playpos_measure  = reaper.TimeMap2_timeToBeats(0, playpos) 
  x1 = object_rect_coord_t[1] + playpos_beats/(4*bars) * object_rect_coord_t[3] + object_rect_coord_t[3]*(playpos_measure/bars % 1)
  y1 = object_rect_coord_t[2] + object_rect_coord_t[4]
  x2 = object_rect_coord_t[1] + playpos_beats/(4*bars) * object_rect_coord_t[3] + object_rect_coord_t[3]*(playpos_measure/bars % 1)
  y2 = object_rect_coord_t[2]
  gfx.x = x1
  gfx.y = y1
  gfx.r, gfx.g, gfx.b, gfx.a = 0.4, 0, 0, 0.5
  gfx.line(x1, y1, x2, y2, 0.9)
end  

---------------------------------------------------------------------------------------------------------------

function GUI_GRID_groove() local x1, y1, x2, y2
 if groove_points_t ~= nil then
  for i = 1, #groove_points_t, 1 do  
   groove_point = groove_points_t[i]   
   x1 = object_rect_coord_t[1] + object_rect_coord_t[3]/bars/4*groove_point 
   y1 = object_rect_coord_t[2] + object_rect_coord_t[4]   
   dy = - 15   
   gfx.r, gfx.g, gfx.b, gfx.a = 0, 1, 0, 0.5  
   gfx.line(x1, y1, x1, y1+dy, 0.9)
  end  
 end 
end 

---------------------------------------------------------------------------------------------------------------

function GUI_GRID_dest()  local x1, y1, x2, y2  
 if new_pos_t ~= nil then
  for i = 1, #new_pos_t, 1 do  
   new_pos = new_pos_t[i]      
   x1 = object_rect_coord_t[1] + object_rect_coord_t[3]/bars/4*new_pos  
   y1 = object_rect_coord_t[2] --+ object_rect_coord_t[4]
   x2 = object_rect_coord_t[1] + object_rect_coord_t[3]/bars/4*new_pos 
   y2 = object_rect_coord_t[2] + object_rect_coord_t[4] - 20   
   gfx.r, gfx.g, gfx.b, gfx.a = 0, 0, 1, 1  
   gfx.line(x1, y1, x1, y2, 0.9)
  end  
 end 
end  

--------------------------------------------------------------------------------------------------------------- 

function GUI_fill_slider(object_coord_t, var, center, a2)
  a1 = 0.2
  if a2 == nil then a2 = 0.3  end
  x = object_coord_t[1]
  y = object_coord_t[2]
  w = object_coord_t[3]
  h = object_coord_t[4]
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
    --gfx.roundrect(x, y, w, h,0.1,true)     
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
   -- gfx.roundrect(x, y, w, h,0.1,true)     
    gfx.r, gfx.g, gfx.b = 1, 1, 1      
    gfx.x = x
    y1 = y + h
    for i = 1, w*var/250, 1 do 
    a = math.abs(i*10/w/2*var/200 - 1) * a2
    gfx.a = a     
    gfx.line(x + w/2-i+1,y, x + w/2-i+1, y1) 
    end    
    gfx.a = a1
    --gfx.roundrect(x, y, w, h,0.1,true) 
  end  
end

--------------------------------------------------------------------------------------------------------------- 

function GUI_fill_slider_inv(object_coord_t, var, center, a2)
  var = math.abs(var)
  a1 = 0.2
  if a2 == nil then a2 = 0.3  end
  x = object_coord_t[1]
  y = object_coord_t[2]
  w = object_coord_t[3]
  h = object_coord_t[4]
  if center == false then
    gfx.r, gfx.g, gfx.b = 1, 1, 1  
    gfx.x = x
    y1 = y + h
    for i = 1, w*var/100, 1 do 
      a = math.abs(math.abs(i/w*var/100 - 1) - 1) * a2
      gfx.a = a
      gfx.line(x-i,y, x-i, y1) 
    end    
    gfx.a = a1
   -- gfx.roundrect(x, y, w, h,0.1,true)     
   else   
    gfx.r, gfx.g, gfx.b = 1, 1, 1      
    gfx.x = x
    y1 = y + h
    for i = 1, w*var/250, 1 do 
     a = math.abs(i*10/w/2*var/200 - 1) * a2
     gfx.a = a     
     gfx.line(x - w/2+i,y, x - w/2+i, y1) 
    end    
    gfx.a = a1
   -- gfx.roundrect(x, y, w, h,0.1,true)     
    gfx.r, gfx.g, gfx.b = 1, 1, 1      
    gfx.x = x
    y1 = y + h
    for i = 1, w*var/250, 1 do 
    a = math.abs(i*10/w/2*var/200 - 1) * a2
    gfx.a = a     
    gfx.line(x - w/2-i+1,y, x - w/2-i+1, y1) 
    end    
    gfx.a = a1
   -- gfx.roundrect(x, y, w, h,0.1,true) 
  end  
end

---------------------------------------------------------------------------------------------------------------

function GUI_info(object_coord_t, string_info) 
    gfx.setfont(1,font, fontsize)
    x = object_coord_t[1]
    y = object_coord_t[2]
    w = object_coord_t[3]
    h = object_coord_t[4]
    gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = x+2,y+2,1,1,1,0.2    
    gfx.roundrect(x, y, w, h,0.1,true) 
    gfx.a = 1
    str_len_info = gfx.measurestr(string_info)
    gfx.x = x + (w-str_len_info)/2
    gfx.drawstr(string_info)
    
end

---------------------------------------------------------------------------------------------------------------

function GUI_define() 
  gfx.x = 0
  gfx.y = 0    
  main_w = 525
  main_h = 345
  x_offset = main_w / 40
  y_offset = 0  
  font = "Arial" 
  fontsize = 16
  
  ---- DEFINE OBJECTS ----  
 
 but_def = {200, 5, 125, 50}  
 b_def = {5, 5, 125, 50}                              
     -- ROW 1 --                             
  object_get2_coord_t =   {b_def[1], b_def[2], b_def[3], b_def[4]} -- quantize dest  
  
  qdcb =                  {b_def[1], 
                           b_def[2]+object_get2_coord_t[4]+5,
                           b_def[3], 
                           160}  -- quantize dest  
 -- GRID 1 --                                 
  object_rect_coord_t =   {b_def[1], 
                           qdcb[2]+qdcb[4]+5, 
                           main_w - (b_def[1]*2),
                           90}                                      
 -- INFO --
  object_info_coord_t =   {b_def[1], 
                          object_rect_coord_t[2]+object_rect_coord_t[4]+5, 
                          object_rect_coord_t[3],20}                           
                           
     -- ROW 2 -- 
  row2_x_offset = b_def[1]+ b_def[3] +5                                 
  sbcb =                  {row2_x_offset,
                           b_def[2], 
                           b_def[3], 
                           60} -- snap beh  
  sdcb =                  {row2_x_offset,  
                           b_def[2]+sbcb[4]+5, 
                           b_def[3], 
                           object_rect_coord_t[2]-15 -sbcb[4]} -- snap dir
  object_gravity_coord_t = {row2_x_offset, 
                            b_def[2] + 22, 
                            b_def[3], fontsize}
                            
  row3_x_offset = b_def[1]+ b_def[3]*2 +10                            
     -- ROW 3 --       
  object_get_coord_t =    {row3_x_offset, 
                           b_def[2],
                           b_def[3],
                           b_def[4]}
  qrcb =                  {row3_x_offset, 
                           b_def[2]+b_def[4]+5, 
                           b_def[3], 
                           object_rect_coord_t[2]-15 -object_get_coord_t[4]} -- reference  
  object_swing_coord_t =  {row3_x_offset, 
                           qrcb[2] + 126,
                           b_def[3], 
                           fontsize} -- for mouse
  object_swing1_coord_t =  {row3_x_offset+b_def[3]/2, 
                           qrcb[2] + 126,
                           b_def[3]/2, 
                           fontsize}
  object_swing2_coord_t =  {row3_x_offset + b_def[3]/2 +1, 
                           qrcb[2] + 126,
                           b_def[3]/2, 
                           fontsize}                                                      
                           
                           
  object_grid_coord_t =   {row3_x_offset, 
                           qrcb[2] + 108,
                           b_def[3], 
                           fontsize}    
  row3_x_offset = b_def[1]+ b_def[3]*3 +15                                                      
     -- ROW 4 --                                   
  object_strength_coord_t = {row3_x_offset, 
                           b_def[2], 
                           b_def[3], 
                           b_def[4]}                             
  object_bypass_coord_t = {row3_x_offset, 
                           object_strength_coord_t[2]+object_strength_coord_t[4]+5,
                           b_def[3],
                           30}                                                  
  object_about_coord_t =  {row3_x_offset, 
                           object_bypass_coord_t[2]+object_bypass_coord_t[4]+5,
                           b_def[3],
                           30}                            
  object_exit_coord_t =   {row3_x_offset, 
                           object_about_coord_t[2]+object_about_coord_t[4]+5,
                           b_def[3],
                           30}
  
end
---------------------------------------------------------------------------------------------------------------    
    
function GUI_draw ()
  gfx.init("Quantize tool // ".."Version "..vrs, main_w, main_h) 
  GUI_background()  
  if execute_mouse == 1 then
 ------- BUTTONS -------- 
  GUI_button(is_button_about_pressed, "About", object_about_coord_t)
  GUI_button(is_button_exit_pressed, "Exit", object_exit_coord_t)
  GUI_button(is_button_get_pressed, "Get Reference", object_get_coord_t)
  GUI_button(is_button_set_pressed, "Apply Quantize", object_strength_coord_t)
  GUI_button(is_button_get2_pressed, "Get Objects to quantize", object_get2_coord_t)
  GUI_button(is_button_bypass_pressed, "Bypass", object_bypass_coord_t)
  
 -------- MENUS --------- 
  snap_direction_coord_buttons = GUI_menu(sdcb, 
                                 "Snap direction,to previous point,to closest point,to next point", 
                                 snap_direction_values,3, is_snap_selected)
                                 
  snap_behaviour_coord_buttons = GUI_menu(sbcb,
                                "Snap behaviour,use gravity,snap everything", 
                                snap_behaviour_values, 2, is_snap_selected1) 
  
  items_count_info = quantize_dest_objects[1]
  str_markers_count_info = quantize_dest_objects[2]
  envelope_points_count_info = quantize_dest_objects[3]
  
  quantize_dest_names = "Quantize,".."items".." ("..items_count_info.."),"..
                        "stretch markers".." ("..str_markers_count_info.."),"..
                        "envelope points".." ("..envelope_points_count_info..")"
                              
  quantize_dest_coord_buttons =  GUI_menu(qdcb, quantize_dest_names, quantize_dest_values,3, is_quant_dest_selected)
                                   
  ref_items_count_info = get_groove_engine_values[1]
  ref_str_markers_count_info = get_groove_engine_values[2]
  ref_envelope_points_count_info = get_groove_engine_values[3]
  ref_notes_count_info = get_groove_engine_values[4]   
                          
  if set_grid ~= 4 then grid_str_sel = "custom grid " else grid_str_sel = "project grid " end
                          
  quantize_ref_names = "Reference,".."items".." ("..ref_items_count_info.."),"..
                       "stretch markers".." ("..ref_str_markers_count_info.."),"..
                       "envelope points".." ("..ref_envelope_points_count_info.."),"..
                       "notes".." ("..ref_notes_count_info.."),"..grid_str_sel..grid_string..",".."swing grid".." ("..swing.."%),"                                
  quantize_ref_coord_buttons =   GUI_menu(qrcb,quantize_ref_names, quantize_ref_values,6, is_quant_ref_selected)
  
  
   ------- GRID ---------
   GUI_GRID_rect(is_mouse_on_rect)  
   GUI_GRID_groove() 
   
   ------- GUI_GRID_dest() 
   GUI_GRID_play_pos() 
   GUI_GRID_draw()
  
  
  ------ SLIDERS -------
  GUI_fill_slider(object_strength_coord_t, strength, false)
  if snap_behaviour_values[1] == 1 then                
   GUI_fill_slider(object_gravity_coord_t, gravity, true)
  end                
  if quantize_ref_values[6] == 1 then
     if swing >= 0 then  GUI_fill_slider(object_swing1_coord_t, swing, false, 0.5)
                    else GUI_fill_slider_inv(object_swing2_coord_t, swing, false, 0.5) end
  end    
              
  if quantize_ref_values[5] == 1 then
     GUI_fill_slider(object_grid_coord_t, set_grid_slider, false)
  end      
  end
  ------ INFO ---------
  GUI_info(object_info_coord_t, string_info)          
end  
    
---------------------------------------------------------------------------------------------------------------
    
function MOUSE_toggleclick_under_gui_rect (object_coord_t, offset) 
  if gfx.mouse_cap == 1 then LB_DOWN = 1 else LB_DOWN = 0 end   
  if gfx.mouse_cap == 1 and cur_time  - set_click_time > 0.5  then  
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
    
---------------------------------------------------------------------------------------------------------------
    
function MOUSE_click_under_gui_rect (object_coord_t, offset) 
  if gfx.mouse_cap == 1 then LB_DOWN = 1 else LB_DOWN = 0 end   
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

---------------------------------------------------------------------------------------------------------------

function MOUSE_RB_click_under_gui_rect (object_coord_t, offset) 
  if gfx.mouse_cap == 2 then RB_DOWN = 1 else RB_DOWN = 0 end 
  if offset == nil then offset = 0 end
  x = object_coord_t[1+offset]
  y = object_coord_t[2+offset]
  w = object_coord_t[3+offset]
  h = object_coord_t[4+offset]
  if RB_DOWN == 1 -- mouse on swing
   and mx > x
   and mx < x + w
   and my > y 
   and my < y + h then       
    return true
  end  
end  

---------------------------------------------------------------------------------------------------------------

function MOUSE_under_gui_rect (object_coord_t, offset) 
  if offset == nil then offset = 0 end
  x = object_coord_t[1+offset]
  y = object_coord_t[2+offset]
  w = object_coord_t[3+offset]
  h = object_coord_t[4+offset]  
  if mx > x
   and mx < x + w
   and my > y 
   and my < y + h then       
    return true
  end  
end

---------------------------------------------------------------------------------------------------------------  
  
function MOUSE_get ()
  mx, my = gfx.mouse_x, gfx.mouse_y  
  
  -- default states for menus and buttons
  is_button_get2_pressed = false  
  is_quant_dest_selected = false
  
  is_snap_selected = false
  is_snap_selected1 = false
  
  is_quant_ref_selected = false
  
  is_button_set_pressed = false
  
  ----- RECT -----
  if MOUSE_under_gui_rect(object_rect_coord_t) == true  then is_mouse_on_rect = true
                                                        else is_mouse_on_rect = false end   
  --[[if MOUSE_RB_click_under_gui_rect(object_rect_coord_t) == true  then 
    get position -> convert to value -> if value eqaul some value in groove_points_t then delete value from table
                                                        end]]
  ----- BYPASS ----  
  if MOUSE_toggleclick_under_gui_rect      (object_bypass_coord_t) == true then is_button_bypass_pressed, bypass = BYPASS_toggle() ENGINE_QUANTIZE() end   
                                                     
  ----- ABOUT ----  
  if MOUSE_click_under_gui_rect(object_about_coord_t) == true then reaper.ShowConsoleMsg("") reaper.ShowConsoleMsg(about) end 
  if MOUSE_under_gui_rect      (object_about_coord_t) == true then is_button_about_pressed = true           
                                                              else is_button_about_pressed = false end                                                              
  ----- EXIT -----   
  if MOUSE_click_under_gui_rect(object_exit_coord_t) == true then  run_cond = 0 end 
  if MOUSE_under_gui_rect(object_exit_coord_t) == true  then is_button_exit_pressed = true           
                                                        else is_button_exit_pressed = false end                                                          
  ----- GET REFERENCE -----   
  if MOUSE_click_under_gui_rect(object_get_coord_t) == true then  GET_groove_engine() is_button_get_pressed = true                                                              
                                                                                 else is_button_get_pressed = false end 
  ----- GET2 OBJECTS -----   
  if MOUSE_click_under_gui_rect(object_get2_coord_t) == true then  GET_objects_to_quantize() is_button_get2_pressed = true 
                                                                                             is_quant_dest_selected = true end 
  ----- STRENGTH -----                                                          
  if MOUSE_click_under_gui_rect(object_strength_coord_t) == true then  
                                                            ENGINE_QUANTIZE()
                                                            
                                                            is_button_set_pressed = true
                                                            is_quant_dest_selected = true
                                                            is_snap_selected = true 
                                                            is_snap_selected1 = true
     strength = (math.floor((mx - object_strength_coord_t[1]) / object_strength_coord_t[3] * 100) + 1)*2
     if strength > 100 then strength = 100 end end                                                             
  ----- GRAVITY -----                                                            
  if MOUSE_click_under_gui_rect(object_gravity_coord_t) == true then  
     gravity = (math.floor((mx - object_gravity_coord_t[1] - object_gravity_coord_t[3]/2) / object_gravity_coord_t[3] * 150) + 1)*2
                                                        if  gravity < 0 then  gravity = 0 end
                                                        if  gravity > 100 then  gravity = 100 end                                                           
                                                            ENGINE_QUANTIZE()                
                                                            is_button_set_pressed = true
                                                            is_snap_selected = true 
                                                            is_quant_dest_selected = true                                                         
                                                        end
                                                            
  ----- SNAP DIR MENU -----
  if MOUSE_click_under_gui_rect(snap_direction_coord_buttons) == true then   snap_direction_values = {1, 0, 0} is_snap_selected = true   end
  if MOUSE_click_under_gui_rect(snap_direction_coord_buttons,4) == true then snap_direction_values = {0, 1, 0} is_snap_selected = true   end  
  if MOUSE_click_under_gui_rect(snap_direction_coord_buttons,8) == true then snap_direction_values = {0, 0, 1} is_snap_selected = true   end
     
  ----- SNAP BEH MENU -----
  if MOUSE_click_under_gui_rect(snap_behaviour_coord_buttons) == true then   snap_behaviour_values = {1, 0} is_snap_selected1 = true  end
  if MOUSE_click_under_gui_rect(snap_behaviour_coord_buttons,4) == true then snap_behaviour_values = {0, 1} is_snap_selected1 = true  end   
   
  ----- DESTINATION -----
  if MOUSE_click_under_gui_rect(quantize_dest_coord_buttons) == true then   quantize_dest_values = {1, 0, 0, 0} is_quant_dest_selected = true  end
  if MOUSE_click_under_gui_rect(quantize_dest_coord_buttons,4) == true then quantize_dest_values = {0, 1, 0, 0} is_quant_dest_selected = true  end  
  if MOUSE_click_under_gui_rect(quantize_dest_coord_buttons,8) == true then quantize_dest_values = {0, 0, 1, 0} is_quant_dest_selected = true  end 
  if MOUSE_click_under_gui_rect(quantize_dest_coord_buttons,12) == true then quantize_dest_values = {0, 0, 0, 1} is_quant_dest_selected = true  end 
  
  ----- REFERENCE -----
  if MOUSE_click_under_gui_rect(quantize_ref_coord_buttons) == true then   quantize_ref_values = {1, 0, 0, 0, 0, 0}  is_quant_ref_selected = true end
  if MOUSE_click_under_gui_rect(quantize_ref_coord_buttons,4) == true then quantize_ref_values = {0, 1, 0, 0, 0, 0}  is_quant_ref_selected = true end  
  if MOUSE_click_under_gui_rect(quantize_ref_coord_buttons,8) == true then quantize_ref_values = {0, 0, 1, 0, 0, 0}  is_quant_ref_selected = true end 
  if MOUSE_click_under_gui_rect(quantize_ref_coord_buttons,12) == true then quantize_ref_values = {0, 0, 0, 1, 0, 0}  is_quant_ref_selected = true end 
  if MOUSE_click_under_gui_rect(quantize_ref_coord_buttons,16) == true then quantize_ref_values = {0, 0, 0, 0, 1, 0}  is_quant_ref_selected = true end 
  if MOUSE_click_under_gui_rect(quantize_ref_coord_buttons,20) == true then quantize_ref_values = {0, 0, 0, 0, 0, 1} is_quant_ref_selected = true  end
  
  ----- IS INSIDE TOOL -----
 --[[ if MOUSE_under_gui_rect(object_main_coord_t) == true then is_mouse_inside = true
                                                       else is_mouse_inside = false --[[GET_objects_to_quantize() end    ]]
  ----- SWING -----                                                     
  if MOUSE_click_under_gui_rect(object_swing_coord_t) == true then
    --swing = math.floor( ((mx - object_swing_coord_t[1]) / object_swing_coord_t[3] * 100))
    swing = (math.floor((mx - object_swing_coord_t[1] - object_swing_coord_t[3]/2) / object_swing_coord_t[3] * 150) + 1)*2
    if swing > 100 then swing = 100 end
    if swing < -100 then swing = -100 end
    GET_groove_engine ()  
    ENGINE_QUANTIZE()
    is_button_get_pressed = true
    is_button_set_pressed = true  
    is_quant_ref_selected = true 
    is_button_set_pressed = true
    is_snap_selected = true 
    is_snap_selected1 = true 
    is_quant_dest_selected = true 
  end  

  ----- SWING -----                                                     
  if MOUSE_RB_click_under_gui_rect(object_swing_coord_t) == true then
    retval, swing_ret =  reaper.GetUserInputs("Swing value", 1, "Swing", "")    
    swing = tonumber(swing_ret)    
    if swing == nil then swing = 0 end
    if swing > 100 then swing = 100 end
    GET_groove_engine ()  
    ENGINE_QUANTIZE()
    is_button_get_pressed = true  
    is_quant_ref_selected = true 
    is_button_set_pressed = true
    is_snap_selected = true 
    is_quant_dest_selected = true 
  end  

  ----- GRID -----                                                     
  if MOUSE_click_under_gui_rect(object_grid_coord_t) == true then       
   div_temp2 = math.ceil(math.exp(((mx - object_grid_coord_t[1]) / object_grid_coord_t[3]) * 4.6))/2
   
   if div_temp2 > 2 and div_temp2 < 3 then div_temp2 = 2 end
   if div_temp2 > 3 and div_temp2 < 4 then div_temp2 = 3 end
   if div_temp2 > 4 and div_temp2 < 6 then div_temp2 = 4 end
   if div_temp2 > 6 and div_temp2 < 8 then div_temp2 = 6 end
   if div_temp2 > 8 and div_temp2 < 12 then div_temp2 = 8 end
   if div_temp2 > 12 and div_temp2 < 16 then div_temp2 = 12 end
   if div_temp2 > 16 and div_temp2 < 24 then div_temp2 = 16 end
   if div_temp2 > 24 and div_temp2 < 32 then div_temp2 = 24 end
   if div_temp2 > 32 then div_temp2 = 32 end 
   
    set_grid_slider = div_temp2/96
    set_grid = round(4/div_temp2, 4)
    GET_groove_engine ()  
    ENGINE_QUANTIZE()    
    is_button_get_pressed = true  
    is_quant_ref_selected = true 
    is_button_set_pressed = true
    is_snap_selected = true
    is_snap_selected1 = true 
    is_quant_dest_selected = true 
   
  end
end  

--------------------------------------------------------------------------------------------------------------- 

function INFO()
  if execute_mouse == 0 then string_info = "Set line spacing (Snap/Grid settings) lower than 1"  end  
  if execute_mouse == 1 then string_info = "Ok, let`s GET something you wanna quantize with this tool. Click on ''Get Objects''" end 
  if is_button_get2_pressed == true and quantize_dest_objects_com ~= nil and quantize_dest_objects_com == 0 then
     string_info = "Don`t forget to select type of you object under ''Quantize''" end     
  if quantize_dest_objects_com ~= nil and quantize_dest_objects_com > 0 and table.sum(snap_direction_values) + table.sum(snap_behaviour_values) >= 2 then 
     string_info = "Get reference from selected objects OR move swing / grid sliders" end
  if quantize_dest_values[2] == 1 and is_loop_source == 1 then
     string_info = "Stretch markers quantize DOES NOT work when Item Loop Source is ON" end
end
--------------------------------------------------------------------------------------------------------------- 
   
function BYPASS_toggle()
  byp_toggle_step = byp_toggle_step + 1
  div_byp_toggle_step = byp_toggle_step%2
  if div_byp_toggle_step == 0 then return true,true else return false,false end
end

--------------------------------------------------------------------------------------------------------------- 
    
function run() 
 cur_time = os.clock()
 GET_grid()
 INFO()
 if run_cond == 1 then 
   GUI_define() 
   GUI_draw()
   if execute_mouse == 1 then MOUSE_get() end
   gfx.update()
   reaper.UpdateArrange()    
   reaper.defer(run)
  else
   reaper.atexit(gfx.quit)
 end  
end 

--------------------------------------------------------------------------------------------------------------- 
  
   show_gui_help = 0   
   
   -- menus defaults --
   quantize_dest_values = {0, 0, 0, 0} -- menu
      
   snap_direction_values = {0,1,0} -- menu
   snap_behaviour_values = {0,1} -- menu   
   
   quantize_ref_values = {0, 0, 0, 0, 1, 0} -- menu
   
   get_groove_engine_values = {0, 0, 0, 0} -- object quantity
   quantize_dest_objects = {0, 0, 0, 0} -- object quantity
   bars = 2 -- default bars in main rect
   set_grid = 4
   
   new_pos_t = {} 
   groove_points_t = {}   
      
   swing = 50 
   set_grid_slider = 0   
   strength = 100
   gravity = 100  
   
   set_click_time = os.clock()
   byp_toggle_step = 1
   bypass = false
   
   execute_mouse =1   
   run_cond = 1   
    
---------------------------------------------------------------------------------------------------------------    

run()
   
--reaper.APITest()
--reaper.ShowConsoleMsg("")
--reaper.ShowConsoleMsg(r01_x)
