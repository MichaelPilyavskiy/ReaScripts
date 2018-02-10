  -- specific functions for mpl_InfoTool
  
  function MPL_GetTableOfCtrlValues(str)
    if not str then return end
    local t = {} for val in str:gmatch('[%-%d]+.') do t[#t+1] = val end
    if #t == 0 and str:match('%d+') then t[1] = str end
    return t
  end
  ---------------------------------------------------
  function MPL_ModifyTimeVal(src_val_sec,int_ID,int_cnt,change_val,data, positive_only)
    local out_val = src_val_sec
    local int_ID0 = int_cnt - int_ID -- ID from end
    local rul_format = data.rul_format
    
    -- Minutes:seconds
      if rul_format == 0 then 
        if int_ID0 == 0 then -- ms
          out_val = out_val + change_val*0.001
         elseif int_ID0 == 1 then -- s
          out_val = out_val + change_val
         elseif int_ID0 == 2 then -- min
          out_val = out_val + change_val*60
         elseif int_ID0 == 3 then -- hour
          out_val = out_val + change_val*3600         
        end
      end
  
    -- Measures.Beats
      if rul_format == 1 then 
        local measures_out
        local out_val_beats
        local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats(0, out_val)
        if int_ID0 == 0 then 
          out_val_beats = fullbeats + change_val*0.01
         elseif int_ID0 == 1 then 
          out_val_beats = fullbeats + change_val
         elseif int_ID0 == 2 then 
          measures_out = measures + change_val     
        end
        if not measures_out then
          out_val = TimeMap2_beatsToTime(0, out_val_beats)
         else 
          out_val = TimeMap2_beatsToTime(0, beats, measures_out)
        end
      end
  
    -- Seconds
      if rul_format == 2 then 
        if int_ID0 == 0 then -- ms
          out_val = out_val + change_val*0.001
         elseif int_ID0 == 1 then -- s
          out_val = out_val + change_val    
        end
      end
  
    -- Samples
      if rul_format == 3 then 
        if int_ID0 == 0 then 
          out_val = out_val + change_val/data.SR
        end
      end
  
    -- HH:MM:SS:frame
      if rul_format == 4 then 
        if int_ID0 == 0 then -- ms
          out_val = out_val + change_val/data.FR
         elseif int_ID0 == 1 then -- s
          out_val = out_val + change_val
         elseif int_ID0 == 2 then -- min
          out_val = out_val + change_val*60
         elseif int_ID0 == 3 then -- hour
          out_val = out_val + change_val*3600         
        end
      end
  
    -- frames
      if rul_format == 5 then 
        if int_ID0 == 0 then -- ms
          out_val = out_val + change_val/data.FR
         elseif int_ID0 == 1 then -- s
          out_val = out_val + change_val    
        end
      end
                                  
    if positive_only == true then return lim(out_val, 0, math.huge) 
     else
      return out_val
    end
  end  
  ---------------------------------------------------
  function MPL_GetCurrentRulerFormat()
    local ruler = -1
    local buf = reaper.format_timestr_pos( 30, '',-1 )
    if buf:match('%d%:%d%d%.%d%d%d') then return 0      -- Minutes:seconds
      elseif buf:match('%d%.%d+.%d%d') then return 1    -- Measures.Beats / Minutes:seconds
                                                        -- Measures.Beats (minimal)
                                                        -- Measures.Beats (minimal) / Minutes:seconds
      elseif buf:match('%d%.%d%d%d') then return 2      -- Seconds
      elseif buf:match('[^%p]%d+[^%p]') then 
        if tonumber(buf) > 10000 then 
          return 3                                      -- Samples
         else 
          return 5                                      -- Frames
        end           
      elseif buf:match('%d%:%d%d%:%d%d%:%d%d') then return 4 -- hhmmssfr
    end
    return ruler
  end
