-- @description InteractiveToolbar_basefunc
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex



  ---------------------------------------------------
  function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  function Action(s) Main_OnCommand(NamedCommandLookup(s), 0) end
  -------------------------------------------------------  
  function MPL_BFPARAM_GetFormattedParamInternal(tr, fx, param, val)
    local param_n
    if val then TrackFX_SetParamNormalized( tr, fx, param, val ) end
    local _, buf = TrackFX_GetFormattedParamValue( tr , fx, param, '' )
    local param_str = buf:match('%-[%d%.]+') or buf:match('[%d%.]+')
    if param_str then param_n = tonumber(param_str) end
    return param_n
  end
  ------------------------------------------------------- 
  function MPL_BFPARAM_BF(find , pow, tr, fx, param) 
    if not tonumber(find) then return end
    local find =  tonumber(find)
    local BF_s, BF_e,closer_out_val = 0, 1
    local TS = os.clock()
    for step_pow = -1, pow, -1 do
      local last_param_n
      for val = BF_s, BF_e, 10^step_pow do 
        if os.clock() - TS > 5 then MB('Brutforce timeout.\nOperation cancelled.', scr_nm, 0) return end 
        local param_n = MPL_BFPARAM_GetFormattedParamInternal(tr , fx, param, val)
        if not last_param_n and find <= param_n  then return val end
        if last_param_n and find > last_param_n and find <= param_n then 
          BF_s = val - 10^step_pow
          BF_e = val
          closer_out_val = val
          break
        end
        last_param_n = param_n
      end
      if not closer_out_val then return 1 end
    end
    return closer_out_val
  end
  -------------------------------------------------------
  function MPL_BFPARAM_GetStringTable(tr, fx, param, steps)
    local t = {}
    local last_str
    for val = 0, 1, 1/steps do
      TrackFX_SetParamNormalized( tr, fx, param, val )
      local str = ({TrackFX_GetFormattedParamValue( tr , fx, param, '' )})[2]
      if not last_str or last_str ~= str then t[#t+1] = {str = str, val=val} end
      last_str = str
    end
    return t
  end
  -------------------------------------------------------
  function MPL_BFPARAM_main(tr,fx, param) 
    if not (tr and fx and param) then return end
    local param_rpr_val = TrackFX_GetParamNormalized( tr, fx, param )
    local cur_param = MPL_BFPARAM_GetFormattedParamInternal(tr , fx, param)
    local retval, find = GetUserInputs( 'Input formatted value', 1, 'value,extrawidth=200', ({TrackFX_GetFormattedParamValue( tr , fx, param, '' )})[2] )
    if not retval then return end
    if cur_param then    
      ReaperVal = MPL_BFPARAM_BF(find, -14, tr, fx, param)    
     else
      local t_val = MPL_BFPARAM_GetStringTable(tr, fx, param, 127 )
      for i = 1, #t_val do 
        if t_val[i].str:lower():find(find:lower()) then 
          ReaperVal = t_val[i].val break end
      end
    end
    if not ReaperVal then ReaperVal = param_rpr_val end
    return ReaperVal  
  end
  ---------------------------------------------------
  function MPL_GetTableOfCtrlValues(str)  -- split -:
    if not str or type(str) ~= 'string' then return end
    local t = {} for val in str:gmatch('[%-%d]+.') do t[#t+1] = val end
    if #t == 0 and str:match('%d+') then t[1] = str end
    return t
  end
  ----------------------------------------------------------------------
  function GetFXByGUID(track, FX_GUID)
    if not track then return end
    for i = 1, TrackFX_GetCount( track ) do
      local fxGUID = TrackFX_GetFXGUID( track, i-1 )
      if fxGUID == FX_GUID then return i-1 end
    end
  end
  ---------------------------------------------------
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
  end
  ---------------------------------------------------
  function MPL_GetTableOfCtrlValues2(str, dig_cnt0)  -- split float
    local str = tostring(str)
    if not str  then return end
    local dig_cnt
    local minus = str:match('%-')
    if not dig_cnt0 then dig_cnt = 3 else dig_cnt = dig_cnt0 end
    --str = string.format('%.'..dig_cnt..'f',str)
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
      div = div:sub(0,4)
      return {int_str..'.', tostring(div)}
     else 
      return {'undefined'}
    end
  end
  ---------------------------------------------------
  function MPL_ModifyFloatVal(src_val,int_ID,int_cnt,change_val,data, positive_only, pow_tol, ignore_fields)
    if not src_val then return end
    local out_val = src_val
    local int_ID0 = int_cnt - int_ID -- ID from end
    if int_ID0 == 0 then  
      if not ignore_fields then 
        if pow_tol then out_val = out_val + change_val*10^pow_tol else out_val = out_val + change_val*0.001  end
       else
        if pow_tol then out_val = out_val + change_val*10^pow_tol else out_val = out_val + change_val*0.01 end
      end    
      
     elseif int_ID0 == 1 then
      if not ignore_fields then 
        if pow_tol then out_val = out_val + change_val*10^pow_tol else out_val = out_val + change_val*0.01 end
       else
        if pow_tol then out_val = out_val + change_val*10^pow_tol else out_val = out_val + change_val*0.01 end
      end
      
    end
    
    --out_val = string.format("%.2f", out_val)
    
    if math.abs(out_val) < 0.00001 then   out_val = 0 end            
    if positive_only == true and type(positive_only) == 'boolean' then return lim(out_val, 0, math.huge) 
     elseif positive_only and type(positive_only) == 'function' then return positive_only(out_val)
     else
      return out_val
    end
  end  
  ---------------------------------------------------
  function MPL_ModifyIntVal(src_val,int_ID,int_cnt,change_val,data, positive_only, pow_tol, ignore_fields)
    if not src_val then return end
    local out_val = math.floor(src_val+change_val)
    if positive_only == true and type(positive_only) == 'boolean' then return lim(out_val, 0, math.huge) 
     elseif positive_only and type(positive_only) == 'function' then return positive_only(out_val)
     else
      return out_val
    end
  end    
  -------------------------------------------------------------- 
  function MPL_ParsePanVal(out_str_toparse)
    if not out_str_toparse then return 0 end
    local out_val
    if out_str_toparse:lower():match('[rlc]') then
      if out_str_toparse:lower():match('r') then side = 1 
          elseif out_str_toparse:lower():match('l') then side = -1 
          elseif out_str_toparse:lower():match('c') then side = 0
      end 
      local val = out_str_toparse:match('%d+')
      if not val then return 0 end
      out_val = side * val/100
     else
      out_val = tonumber(out_str_toparse)
      if not out_val then return 0 end
      out_val = out_val/100
    end
    return out_val
  end
  ---------------------------------------------------
  function MPL_ModifyFloatVal2(src_val,int_ID,int_cnt,change_val,data, positive_only, pow_tol, ignore_fields)
    if not src_val then return end
    local out_val = src_val
    local int_ID0 = int_cnt - int_ID -- ID from end
    if int_ID0 == 0 then  
      out_val = out_val + change_val*0.01
     elseif int_ID0 == 1 then
      out_val = out_val + change_val
    end
    
    if math.abs(out_val) < 0.00001 then   out_val = 0 end            
    if positive_only == true and type(positive_only) == 'boolean' then return lim(out_val, 0, math.huge) 
     elseif positive_only and type(positive_only) == 'function' then return positive_only(out_val)
     else
      return out_val
    end
  end 
  ---------------------------------------------------
  function MPL_ModifyFloatVal3(src_val,int_ID,int_cnt,change_val,data, positive_only, pow_tol, ignore_fields, pow_tol2)
    if not src_val then return end
    local out_val = src_val
    local int_ID0 = int_cnt - int_ID -- ID from end
    if int_ID0 == 0 then  
      if not pow_tol then pow_tol = -2 end
      out_val = out_val + change_val*10^pow_tol
     elseif int_ID0 == 1 then
      if not pow_tol2 then pow_tol2 = 0 end
      out_val = out_val + change_val*10^pow_tol2
    end
    
    if math.abs(out_val) < 0.00001 then   out_val = 0 end            
    if positive_only == true and type(positive_only) == 'boolean' then return lim(out_val, 0, math.huge) 
     elseif positive_only and type(positive_only) == 'function' then return positive_only(out_val)
     else
      return out_val
    end
  end    
  -------------------------------------------------------------------------------
  function MPL_ModifyTimeVal(src_val_sec,int_ID,int_cnt,change_val,data, positive_only, _, _, _, rul_format0)
    local out_val = src_val_sec
    if not src_val_sec then return end
    local int_ID0 = int_cnt - int_ID -- ID from end
    local rul_format = data.rul_format
    if rul_format0 and rul_format0 ~= -1 then rul_format = rul_format0 end
    

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
  function MPL_ParseMIDIPitch(data, str) 
    local oct_shift = -3+math.floor(data.oct_shift )
    if data.pitch_format == 0 then-- midi pitch
      return tonumber(val)
     elseif data.pitch_format == 1 then
      local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
      for i = 1, #key_names do
        local str_let = str:match('[^%d]+')
        local str_num = str:match('%d+')
        if str_let and str_let:lower() == (key_names[i]:lower()) and tonumber(str_num) then
          local note = i
          local oct = oct_shift + 12*(1+tonumber(str_num))
          return oct+note
        end
      end
      
     elseif data.pitch_format == 2 then
      local key_names = {'C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B'}
      for i = 1, #key_names do
        local str_let = str:match('[^%d]+')
        local str_num = str:match('%d+')
        if str_let and str_let:lower() == (key_names[i]:lower()) and tonumber(str_num) then
          local note = i
          local oct = oct_shift + 12*(1+tonumber(str_num))
          return oct+note
        end
      end     
     
     elseif data.pitch_format == 3 then
      local key_names = {'Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'}
      for i = 1, #key_names do
        local str_let = str:match('[^%d]+')
        local str_num = str:match('%d+')
        if str_let and str_let:lower() == (key_names[i]:lower()) and tonumber(str_num) then
          local note = i
          local oct = oct_shift + 12*(1+tonumber(str_num))
          return oct+note
        end
      end     
      
     elseif data.pitch_format == 4 then
      local key_names = {'Do', 'Re♭', 'Re', 'Mi♭', 'Mi', 'Fa', 'Sol♭', 'Sol', 'La♭', 'La', 'Si♭', 'Si'}
      for i = 1, #key_names do
        local str_let = str:match('[^%d]+')
        local str_num = str:match('%d+')
        if str_let and str_let:lower() == (key_names[i]:lower()) and tonumber(str_num) then
          local note = i
          local oct = oct_shift + 12*(1+tonumber(str_num))
          return oct+note
        end
      end 
      
     elseif data.pitch_format == 5 then 
      local F = tonumber(str)
      if F then return math.floor(69+12*math.log(F/440, 2)) end
    end
    
  end
  ---------------------------------------------------
  function MPL_FormatMIDIPitch(data, val) 
    local oct_shift = -3+math.floor(data.oct_shift )
    if data.pitch_format == 0 -- midi pitch
     then return val
    elseif data.pitch_format == 1 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift end
     elseif data.pitch_format == 2 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B'}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift end  
     elseif data.pitch_format == 3 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift end      
     elseif data.pitch_format == 4 then
      if not val then return end
      local val = math.floor(val)
      local oct = math.floor(val / 12)
      local note = math.fmod(val,  12)
      local key_names = {'Do', 'Re♭', 'Re', 'Mi♭', 'Mi', 'Fa', 'Sol♭', 'Sol', 'La♭', 'La', 'Si♭', 'Si'}
      if note and oct and key_names[note+1] then return key_names[note+1]..oct+oct_shift end       
     elseif 
      data.pitch_format == 5 -- freq
      then return math.floor(440 * 2 ^ ( (val - 69) / 12))..'Hz'
    end
  end
  ---------------------------------------------------
  --strNeed64 reaper.mkvolstr(strNeed64, vol )
  --strNeed64 reaper.mkpanstr(strNeed64, pan )
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
  function MPL_GetFormattedGrid(grid_div)
    local grid_flags, grid_division, grid_swingmode, grid_swingamt 
    if not grid_div then 
      grid_flags, grid_division, grid_swingmode, grid_swingamt  = GetSetProjectGrid( 0, false )
     else 
      grid_flags, grid_division, grid_swingmode, grid_swingamt = 0,grid_div,0,0
    end
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
    grid_swingamt_format = math.floor(grid_swingamt * 100)..'%'
    return grid_division, grid_str, is_triplet, grid_swingmode, grid_swingamt, grid_swingamt_format
  end     
  ---------------------------------------------------
  function MPL_GetFormattedMIDIGrid()
    
    --SN_FocusMIDIEditor()
    
    local ME = MIDIEditor_GetActive()
    if not ME then return end
    take = MIDIEditor_GetTake( ME )
    local is_valid = ValidatePtr2( 0, take, 'MediaItem_Take*' )
    if not take or not is_valid then return end
    local grid_flags, grid_division, grid_swingmode, grid_swingamt 
    grid_division, grid_swingamt = MIDI_GetGrid( take )
    grid_division = grid_division/4
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
    grid_swingamt_format = math.floor(grid_swingamt * 100)..'%'
    return grid_division, grid_str, is_triplet, grid_swingmode, grid_swingamt, grid_swingamt_format
  end     
  
  
 ---------------------------------------------------  
  function lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end

  ---------------------------------------------------
  function CopyTable(orig)--http://lua-users.org/wiki/CopyTable
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[CopyTable(orig_key)] = CopyTable(orig_value)
          end
          setmetatable(copy, CopyTable(getmetatable(orig)))
      else -- number, string, boolean, etc
          copy = orig
      end
      return copy
  end 
  ---------------------------------------------------
  function ExtState_Load(conf)
    local def = ExtState_Def()
    for key in pairs(def) do 
      local es_str = GetExtState(def.ES_key, key)
      if es_str == '' then conf[key] = def[key] else conf[key] = tonumber(es_str) or es_str end
    end
  end  

    function F_open_URL(url) if GetOS():match("OSX") then os.execute('open '.. url) else os.execute('start '..url) end  end

  ---------------------------------------------------  
  function HasCurPosChanged()
    local cur_pos = GetCursorPositionEx( 0 )
    local ret = false
    if lastcur_pos and lastcur_pos ~= cur_pos then  ret = true end
    lastcur_pos = cur_pos
    return ret
  end
  ---------------------------------------------------
  function HasTimeSelChanged()
    local TS_st, TSend = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )
    local ret = false
    if lastTS_st and lastTSend and (lastTS_st ~= TS_st or lastTSend ~=TSend)  then  ret = true end
    lastTS_st, lastTSend = TS_st, TSend
    return ret
  end
  ---------------------------------------------------
  function HasGridChanged()
    local _, ProjGid = GetSetProjectGrid( 0, false )
    local ret = false
    if last_ProjGid and last_ProjGid ~= ProjGid  then  ret = true end
    last_ProjGid = ProjGid
    return ret
  end 
  ---------------------------------------------------
  function HasPlayStateChanged()
    local int_playstate = GetPlayStateEx( 0 )
    local int_repeat =  GetToggleCommandState( 1068 )
    local ret = false
    if (lastint_playstate and lastint_playstate ~= int_playstate)
        or (lastint_repeat and lastint_repeat ~= int_repeat)  then  
      ret = true 
    end
    lastint_playstate = int_playstate
    lastint_repeat = int_repeat
    return ret
  end 
  ---------------------------------------------------
  function HasRulerFormChanged()
    local FormTS = format_timestr_pos( 100, '', -1 )
    local ret = false
    if last_FormTS and last_FormTS ~= FormTS  then  ret = true end
    last_FormTS = FormTS 
    return ret
  end
  ---------------------------------------------------
  function dBFromReaperVal(val)  local out
    if not val or type(val) == 'string' then val = 0 end
    if val < 1 then 
      out = 20*math.log(val, 10)
     else 
      out = 6*math.log(val, 2)
    end 
    return string.format('%.2f',out)
  end
  -------------------------------------------------------
  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end
  function WDL_VAL2DB(x, reduce)
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else 
      if reduce then 
        return string.format('%.2f', v)
       else 
        return v 
      end
    end
  end

  -------------------------------------------------------
  function ParseDbVol(out_str_toparse)
    if not out_str_toparse or not out_str_toparse:match('%d') then return end
    if out_str_toparse:find('1.#JdB') then return end
    out_str_toparse = out_str_toparse:lower():gsub('db', '')
    local out_val = tonumber(out_str_toparse) 
    if not out_val then return end
    out_val = lim(out_val, -150, 12)
    out_val = WDL_DB2VAL(out_val)
    return out_val
  end
  --[[-------------------------------------------------
  function ReaperValfromdB(dB_val)  local out
    local dB_val = tonumber(dB_val)
    if not dB_val or type(dB_val) == 'string' then return 0 end
    if dB_val < 0 then 
      out = 10^(dB_val/20)
     else 
      out = 10^(dB_val/20)
    end 
    return out--string.format('%.2f',tonumber(out))
  end]]
  ---------------------------------------------------
  function HasSelEnvChanged()
    local Sel_env = GetSelectedEnvelope( 0 )
    local ret = false
    if (Sel_env and not last_Sel_env) or (last_Sel_env and last_Sel_env ~= Sel_env)  then  ret = true end
    last_Sel_env = Sel_env 
    return ret
  end  
  ---------------------------------------------------
  function Config_ParseIni(conf_path, widgets) 
    local def_conf = Config_DefaultStr()
    --  create if not exists
      local f = io.open(conf_path, 'r')
      local cont
      if f then
        cont = f:read('a')
        f:close()
       else
        f = io.open(conf_path, 'w')
        if f then 
          f:write(def_conf)
          f:close()
        end
      end
    
    
                      
    --  parse widgets 
      for i = 1, #widgets.types_t do 
        local widg_str = widgets.types_t[i]
        if widg_str ~= nil then
          local retval, str_widgets_tags = BR_Win32_GetPrivateProfileString( widg_str, 'order', '', conf_path )
          widgets[widg_str] = {}
          for w in str_widgets_tags:gmatch('#(%a+)') do widgets[widg_str] [  #widgets[widg_str] +1 ] = w end
            
          widgets[widg_str].buttons = {}
          local retval, buttons_str = BR_Win32_GetPrivateProfileString( widg_str, 'buttons', '', conf_path )
          for w in buttons_str:gmatch('#(%a+)') do widgets[widg_str].buttons [  #widgets[widg_str].buttons +1 ] = w end
        end
      end
      
    -- persist
      local retval, pers_widg = BR_Win32_GetPrivateProfileString( 'Persist', 'order', '', conf_path )
      widgets.Persist = {}
      for w in pers_widg:gmatch('#(%a+)') do widgets.Persist [  #widgets.Persist +1 ] = w end
      
     --[[ widgets.Persist.buttons = {}
      local retval, buttons_str = BR_Win32_GetPrivateProfileString( 'Persist', 'buttons', '', conf_path )
      for w in buttons_str:gmatch('#(%a+)') do widgets.Persist.buttons [  #widgets.Persist.buttons +1 ] = w end]]
  end
  ---------------------------------------------------
  function Config_DumpIni(widgets, conf_path) 
      local str = '//Configuration for MPL InfoTool'
        
  
                        
      --  parse widgets 
        for i = 1, #widgets.types_t do 
          local widg_str = widgets.types_t[i]
          if widg_str then 
            str = str..'\n'..'['..widg_str..']'
            local ord = ''
            for i2 =1 , #widgets[widg_str] do 
              ord = ord..'#'..widgets[widg_str][i2]..' '
            end
            str = str..'\norder='..ord
            if widgets[widg_str].buttons and #widgets[widg_str].buttons > 0 then
              local b_ord = ''
              for i2 =1 , #widgets[widg_str].buttons do 
                b_ord = b_ord..'#'..widgets[widg_str].buttons[i2]..' '
              end
              str = str..'\nbuttons='..b_ord
            end
          end
        end
        
      -- persist
          local widg_str = 'Persist'
          str = str..'\n'..'['..widg_str..']'
          local ord = ''
          for i2 =1 , #widgets[widg_str] do 
            ord = ord..'#'..widgets[widg_str][i2]..' '
          end
          str = str..'\norder='..ord
          if widgets[widg_str].buttons and #widgets[widg_str].buttons > 0 then
            local b_ord = ''
            for i2 =1 , #widgets[widg_str].buttons do 
              b_ord = b_ord..'#'..widgets[widg_str].buttons[i2]..' '
            end
            str = str..'\nbuttons='..b_ord
          end
          
        
      local f = io.open(conf_path, 'w')        
      if f then 
        f:write(str)
        f:close()
      end           
    end
  ---------------------------------------------------
  function Config_Reset(conf_path)
    local def_conf = Config_DefaultStr()
    local f = io.open(conf_path, 'w')
    if f then 
      f:write(def_conf)
      f:close()
    end
    redraw = 1
    SCC_trig = true
  end
