-- @description InfoTool_GUI
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  -- specific functions for mpl_InfoTool
  
  function MPL_GetTableOfCtrlValues(str)  -- split .:
    if not str or type(str) ~= 'string' then return end
    local t = {} for val in str:gmatch('[%-%d]+.') do t[#t+1] = val end
    if #t == 0 and str:match('%d+') then t[1] = str end
    return t
  end
  ---------------------------------------------------
  function MPL_GetTableOfCtrlValues2(str, dig_cnt0)  -- split float
    if not str  then return end
    local dig_cnt
    local minus = str:match('%-')
    if not dig_cnt0 then dig_cnt = 3 else dig_cnt = dig_cnt0 end
    local t = {} for val in str:gmatch('[%-%d]+.') do t[#t+1] = val end
    if #t == 0 and str:match('%d+') then t[1] = str end
    if tonumber(str) then
      local int, div = math.modf(tonumber(str))
      div = tostring(div):match('%.(%d+)')
      --div = math.floor(math.abs(div * 10*dig_cnt))
      --div = string.format("%0"..dig_cnt.."d", div)
      local int_str
      if minus and not tostring(int):match('%-') then 
        int_str = '-'..int
       else
        int_str = tostring(int)
      end
      return {int_str..'.', tostring(div)}
     else 
      return {'undefined'}
    end
  end
  ---------------------------------------------------
  function MPL_ModifyFloatVal(src_val,int_ID,int_cnt,change_val,data, positive_only)
    if not src_val then return end
    local out_val = src_val
    local int_ID0 = int_cnt - int_ID -- ID from end
    
    if int_ID0 == 0 then
      out_val = out_val + change_val*0.01
     elseif int_ID0 == 1 then
      out_val = out_val + change_val
    end
    if math.abs(out_val) < 0.0001 then   out_val = 0 end            
    if positive_only == true and type(positive_only) == 'boolean' then return lim(out_val, 0, math.huge) 
     elseif positive_only and type(positive_only) == 'function' then return positive_only(out_val)
     else
      return out_val
    end
  end  
  ---------------------------------------------------
  function MPL_ModifyTimeVal(src_val_sec,int_ID,int_cnt,change_val,data, positive_only)
    local out_val = src_val_sec
    if not src_val_sec then return end
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
  ---------------------------------------------------
  function MPL_FormatPan(pan_val)
    local pan_str = 'undefined'
          if pan_val > 0 then 
            pan_str = math.floor((pan_val*100))..'% R'
           elseif pan_val < 0 then
            pan_str = math.floor(math.abs(pan_val*100))..'% L'
           elseif pan_val == 0 then
            pan_str = 'Center'
          end
    return pan_str
  end
  ---------------------------------------------------
  function MPL_GetFormattedGrid()
    local grid_flags, grid_division, grid_swingmode, grid_swingamt = GetSetProjectGrid( 0, false )
    local is_triplet
    local denom = 1/grid_division
    local grid_str
    if denom >=2 then 
      is_triplet = (1/grid_division) % 3 == 0 
      grid_str = '1/'..math.floor(denom)
      if is_triplet then grid_str = '1/'..math.floor(denom*2/3) end
     else 
      grid_str = 1
      is_triplet = math.abs(grid_division - 0.6666) < 0.001
    end
    return grid_division, grid_str, is_triplet
  end   
