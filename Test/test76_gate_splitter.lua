   
   threshold = -60 -- db
   release = 0.03 -- seconds
   
   
   count_items = reaper.CountSelectedMediaItems(0)
   if count_items ~= nil then
     items_t = {}
     for i =1, count_items do
       item = reaper.GetSelectedMediaItem(0, i-1)
       if item ~= nil then         
         item_guid = reaper.BR_GetMediaItemGUID (item)
         item_pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
         item_len = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
         track = reaper.GetMediaItem_Track(item)
         itemdata = {item_guid, item_pos, item_len}
         table.insert(items_t, itemdata)
         take = reaper.GetActiveTake(item)  
         if take ~= nil then         
           is_midi = reaper.TakeIsMIDI(take)      
           if is_midi == false then
             takerate = reaper.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
             src = reaper.GetMediaItemTake_Source(take)
             src_num_ch = 1 
             --src_num_ch = reaper.GetMediaSourceNumChannels(src)
             src_rate = reaper.GetMediaSourceSampleRate(src)
             audio_accessor = reaper.CreateTakeAudioAccessor(take)
             window_samples = math.floor(src_rate * item_len)             
             
             audio_accessor_buffer = reaper.new_array(window_samples)
             reaper.GetAudioAccessorSamples(audio_accessor, src_rate, src_num_ch, 0, window_samples, audio_accessor_buffer)
             audio_accessor_buffer_t = audio_accessor_buffer.table(1, window_samples)
             
             -- insert peaks into table
             peaks_db_t = {}
             for j =1, #audio_accessor_buffer_t do
               sample_db_val = math.log(audio_accessor_buffer_t[j]) * 20               
               table.insert(peaks_db_t, sample_db_val)
             end  
             
             -- detect gates start / lenght
             release_smpls = src_rate*release
             gates_t = {}
             prev_gate_pos = 0
             current_gate_len=0
             for k = 1, #peaks_db_t do
               peaks_db_item = peaks_db_t[k]               
               if peaks_db_item < threshold then
                 current_gate_pos = k
                 if current_gate_pos == prev_gate_pos + 1 then
                   current_gate_len = current_gate_len+1
                   gate_t_size = #gates_t
                   if gate_t_size == 0 then  gate_t_size = 1 end
                   table.insert(gates_t, gate_t_size, {current_gate_pos, current_gate_len})
                  else 
                   current_gate_len = 1
                   table.insert(gates_t, #gates_t + 1, {current_gate_pos, current_gate_len})
                 end  
                 prev_gate_pos = current_gate_pos
               end
             end
             
             -- form table from gate lengths matching release time
             gates_t2 = {}
             for m = 1, #gates_t do
               gates_subt = gates_t[m]
               if gates_subt[2] > release_smpls then
                 table.insert(gates_t2, {gates_subt[1],gates_subt[2]})
               end
             end
             
             -- form start point table
             start_point_t = {}
             for n = 1, #gates_t2 do
               gates_subt2 = gates_t2[n]
               start_point = gates_subt2[1]- gates_subt2[2]
               table.insert(start_point_t, start_point)
             end             
             
             -- delete same values from start points table
             start_point_t_delete_ids_t = {}
             for p = 1, #start_point_t do
               start_point_item = start_point_t[p]
               if start_point_item == prev_point_item then 
                 table.insert(start_point_t_delete_ids_t, p) 
               end 
               prev_point_item = start_point_item
             end             
             table.sort(start_point_t_delete_ids_t, function(a,b) return a > b end)
             for r =1, #start_point_t_delete_ids_t do
               table.remove(start_point_t, start_point_t_delete_ids_t[r])
             end
             
             -- search for maximum length refer to start points
             end_point_t = {}
             for t = 1, #start_point_t do
               start_point = start_point_t[t]
               max_len = 0
               for u = 1, #gates_t2 do 
                 gates_t2_subt = gates_t2[u]
                 if gates_t2_subt[1] - gates_t2_subt[2] == start_point then
                   max_len = math.max(max_len, gates_t2_subt[2])
                 end  
               end     
               table.insert(end_point_t, start_point+max_len)          
             end
                          
             --[[ split test
             for s = 1, #start_point_t do
               split_pos_item = start_point_t[s]
               reaper.SetTakeStretchMarker(take, -1, (split_pos_item/src_rate)*takerate)     
             end
             
             for s = 1, #end_point_t do
               split_pos_item = end_point_t[s]
               reaper.SetTakeStretchMarker(take, -1, (split_pos_item/src_rate)*takerate)     
             end]]
             
             -- form items
             item_edges_t = {}
             for w = 1, #start_point_t-1  do
               if w == 1 then 
                 i_start = 0 i_end = start_point_t[1] 
                else
                 i_start = end_point_t[w-1]
                 i_end = start_point_t[w]
               end               
               item_edges = {i_start, i_end}
               table.insert(item_edges_t,item_edges )
             end
             
                
             -- split trick:
                
             --duplicate item for splitting trick
             reaper.ApplyNudge(0, 0, 5, 0, 0, false, #start_point_t-1)
             --get matched items guids
             items_t2 = {}
             count_items2 = reaper.CountMediaItems(0)
             if count_items2 ~= nil then
               for i =1, count_items2 do
                 item2 = reaper.GetMediaItem(0, i-1)                   
                 item_pos2 = reaper.GetMediaItemInfo_Value(item2,"D_POSITION")
                 item_len2 = reaper.GetMediaItemInfo_Value(item2,"D_LENGTH")
                 if item_pos2 == item_pos and item_len2 == item_len then
                   item_guid2 = reaper.BR_GetMediaItemGUID(item2)
                   table.insert(items_t2, item_guid2)
                 end  
               end
             end  
                
             -- split items  
             for v =1,  #items_t2  do
               item_guid2ret = items_t2[v]
               item2 = reaper.BR_GetMediaItemByGUID(0,  item_guid2ret)
               item_edges_subt = {}
               item_edges_subt = item_edges_t[v]
               if item2 ~= nil then
                 reaper.SetMediaItemInfo_Value(item2,"D_POSITION", (item_edges_subt[1]/src_rate)*takerate)
                 reaper.SetMediaItemInfo_Value(item2,"D_LENGTH", (item_edges_subt[2]/src_rate)*takerate)
               end
             end
                          
             reaper.DestroyAudioAccessor(audio_accessor)
           end -- if isnt midi
         end -- if take ~=  nil
       end -- if item ~= nil
     end -- loop items
   end -- if count ~+ nil  
   
   reaper.UpdateArrange()
