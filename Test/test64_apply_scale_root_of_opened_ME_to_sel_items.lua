  function get_take_conf_chunk(take)
    local item = reaper.GetMediaItemTake_Item(take)
    local retval, chunk = reaper.GetItemStateChunk(item, "")
    local take_id = reaper.GetMediaItemTakeInfo_Value(take, "IP_TAKENUMBER") + 1
    for i = 1, take_id do
      conf_chunk_st = string.find(chunk,"KEYSNAP")
      if conf_chunk_st == nil then MB("Select scale first") break end
      chunk = string.sub(chunk, conf_chunk_st + 7)        
    end           
    conf_chunk_end = string.find(chunk,"TRACKSEL ")    
    chunk_ret = "KEYSNAP"..string.sub(chunk, 0, conf_chunk_end-2) 
          
    for last_str in string.gmatch(chunk_ret, "[^%s]+") do
      temp_sc = last_str
    end
    return chunk_ret
  end  
      
  -- get ref chunk --
      
  midi_editor = reaper.MIDIEditor_GetActive()
  if midi_editor ~= nil then
    take = reaper.MIDIEditor_GetTake(midi_editor)
    if take ~= nil then
      ref_item = reaper.GetMediaItemTake_Item(take)
      ref_chunk = get_take_conf_chunk(take)
    end
  end  
  
  -- set selected item active midi takes to same scale config
  if ref_chunk ~= nil then
    count_sel_items = reaper.CountSelectedMediaItems(0)
    if count_sel_items ~= nil then
      for i = 1, count_sel_items do
        item = reaper.GetSelectedMediaItem(0,i-1)             
        if item ~= nil and item ~= ref_item then   
          retval, item_chunk = reaper.GetItemStateChunk(item, "")   
          take = reaper.GetActiveTake(item)
          if take ~= nil then
            ismidi = reaper.TakeIsMIDI(take)
            if ismidi == true then
              take_config_chunk = get_take_conf_chunk(take)
              new_chunk = string.gsub(item_chunk, take_config_chunk, ref_chunk)
              reaper.SetItemStateChunk(item, new_chunk)
            end
          end                     
          reaper.UpdateItemInProject(item)
        end      
      end      
    end        
  end          
  
  reaper.UpdateArrange()
  
  if item_chunk~= nil and take_config_chunk~= nil and ref_chunk~= nil and  new_chunk~= nil then
reaper.ShowConsoleMsg("")
reaper.ShowConsoleMsg("selected item_chunk".."\n")
reaper.ShowConsoleMsg(item_chunk.."\n")
reaper.ShowConsoleMsg("current item take_midi scale config_chunk".."\n")
reaper.ShowConsoleMsg(take_config_chunk.."\n".."\n")
reaper.ShowConsoleMsg("midi scale config reference_chunk".."\n")
reaper.ShowConsoleMsg(ref_chunk.."\n".."\n")
reaper.ShowConsoleMsg("new_chunk to apply".."\n")
reaper.ShowConsoleMsg(new_chunk) 

end
