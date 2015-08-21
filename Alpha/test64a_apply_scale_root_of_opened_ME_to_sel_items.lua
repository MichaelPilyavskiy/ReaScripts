reaper.ShowConsoleMsg("")
  midieditor = reaper.MIDIEditor_GetActive() 
  if  midieditor ~= nil then
    is_scale_enabled = reaper.MIDIEditor_GetSetting_int(midieditor, "scale_enabled")
    if is_scale_enabled == 1 then
    
      --form pattern table
      scale_root = reaper.MIDIEditor_GetSetting_int(midieditor, "scale_root")
      retval, scale_pat_original = reaper.MIDIEditor_GetSetting_str(midieditor, "scale", "")
      scale_pat = string.sub(scale_pat_original, 13-scale_root).. string.sub(scale_pat_original, 0, 12-scale_root)
      scale_pat_t={} 
      scale_pat:gsub(".",function(c) if c ~= "0" then c = "1" else c = "0"end table.insert(scale_pat_t,c)end)
      
      --loop through selected items notes
      sel_item_count = reaper.CountSelectedMediaItems(0)
      if sel_item_count ~= nil and scale_pat_t ~= nil then
        for i = 1, sel_item_count do
          item = reaper.GetSelectedMediaItem(0, i-1)
          count_takes = reaper.CountTakes(item)
          if count_takes ~= nil then
            for j = 1, count_takes do
              take = reaper.GetTake(item, j-1)
              if take ~= nil then
                retval, notecnt = reaper.MIDI_CountEvts(take)
                if notecnt ~= nil then
                  for k = 1, notecnt do
                    retval,selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, k-1)                    
                    pitch_norm = pitch % 12                    
                    if scale_pat_t[pitch_norm+1] == "0" then
                       set_pitch = pitch
                       m = 1
                       repeat 
                         set_pitch = set_pitch + m 
                         pitch_norm = pitch % 12 
                       until 
                         (scale_pat_t[pitch_norm+1] == "1") 
                      else
                       set_pitch = pitch
                    end
                    
                    reaper.MIDI_SetNote(take, k-1, selected, muted, startppqpos, endppqpos, chan, set_pitch, vel, true)
                    reaper.ShowConsoleMsg("pitch"..pitch.."\n".."set_pitch"..set_pitch.."\n")
                  end                    
                end
              end
              reaper.MIDI_Sort(take)
            end
          end
          reaper.UpdateItemInProject(item)
        end
      end      
    end
  end  
