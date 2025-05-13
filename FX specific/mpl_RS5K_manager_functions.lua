-- @description mpl_RS5K_manager_functions
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

-- function for mpl_RS5K_manager and mpl_RS5K_SteSequencer
if not DATA then DATA = {} end
if not EXT then EXT = {} end
if not ImGui then ImGui = {} end

RS5K_manager_functions_version = 4.43

  
    -------------------------------------------------------------------------------- 
  function DATA:_Seq_Clear(note)
    if not (DATA.seq.ext and DATA.seq.ext.children ) then return end
    
    if note and DATA.seq.ext.children[note] and DATA.seq.ext.children[note].steps then DATA.seq.ext.children[note].steps = nil return end
    
    -- all
    local t = {}
    for note in pairs(DATA.seq.ext.children) do t[#t+1] = note end 
    for i = 1, #t do 
      local note = t[i]
      if DATA.seq.ext.children[note  ] then DATA.seq.ext.children[note ].steps = nil end 
    end
    DATA:_Seq_Print(true) 
  end
    -------------------------------------------------------------------------------- 
  function DATA:_Seq_Fill(note, pat)
    if not (DATA.seq.ext and DATA.seq.ext.children and note and DATA.seq.ext.children[note]) then return end
    local tfill = {}
    for char in pat:gmatch('.') do
      local val = 0
      if char == '1' then val = 1 end
      tfill[#tfill+1] = val
    end
    
    local step_cnt = DATA.seq.ext.children[note].step_cnt
    for i = 1, step_cnt do 
      local src_step= 1+((i-1)%#tfill)
      if tfill[src_step] and tfill[src_step] then val = tfill[src_step] end
      if not DATA.seq.ext.children[note] then DATA.seq.ext.children[note] = {} end
      if not DATA.seq.ext.children[note].steps then DATA.seq.ext.children[note].steps = {} end
      if not DATA.seq.ext.children[note].steps[i] then DATA.seq.ext.children[note].steps[i] = {} end
      DATA.seq.ext.children[note].steps[i].val = val or 0
    end
    
  end
  --------------------------------------------------------------------------------  
  function math_q(num)  if math.abs(num - math.floor(num)) < math.abs(num - math.ceil(num)) then return math.floor(num) else return math.ceil(num) end end
  --------------------------------------------------------------------------------  
  function DATA:_Seq_Print(do_not_ignore_empty, minor_change) 
    if not (DATA.MIDIbus and DATA.MIDIbus.tr_ptr and DATA.MIDIbus.valid) then return end
    if not (DATA.seq.it_ptr and DATA.seq.tk_ptr) then return end
    if not DATA.seq.ext.children then return end 
    local item = DATA.seq.it_ptr
    local take = DATA.seq.tk_ptr
    SetMediaItemInfo_Value( item, 'B_LOOPSRC',1 )
    
    
    if minor_change~=true then 
      --test = time_precise()
      local outstr = table.savestring(DATA.seq.ext) 
      --outstr = VF_encBase64(outstr) -- 4.43 off
      GetSetMediaItemTakeInfo_String( take, 'P_EXT:MPLRS5KMAN_PATDATA', outstr, true)
      GetSetMediaItemTakeInfo_String( take, 'P_EXT:MPLRS5KMAN_PATDATA_IGNOREB64', 1, true) 
      --msg(os.date()..' '..time_precise()-test)
    end
    DATA:_Seq_PrintMIDI(DATA.seq)  
    GetSetMediaItemTakeInfo_String( take, 'P_EXT:MPLRS5KMAN_PATGUID', DATA.seq.ext.GUID, true) 
    
  end
  --------------------------------------------------------------------------------  
  function DATA:Auto_LoopSlice_CreatePattern(loop_t) 
    if not loop_t then return end
    local slicecnt = math.min(16,#loop_t)
    
    DATA:_Seq_Insert()
    DATA:CollectData() -- to refresh note existing data
    if not DATA.seq.ext.children then DATA.seq.ext.children = {} end 
    function __f_slice2pattern_modloopt() end
    
    local steplength = 0.25
    for slice = 1, slicecnt do
      local note = loop_t[slice].outnote
      if note then
        DATA.seq.ext.children[note] = {
          steplength =steplength,
          step_cnt = slicecnt,
          steps = {}
          }
        DATA.seq.ext.children[note].steps[slice] = {val = 1}
      end
    end
    
    DATA.seq.ext.patternlen = slicecnt
    DATA:_Seq_Print() 
  end  
  --------------------------------------------------------------------------------  
  function DATA:_Seq_Insert() 
    if not (DATA.MIDIbus and DATA.MIDIbus.tr_ptr and DATA.MIDIbus.valid) then return end
    local track = DATA.MIDIbus.tr_ptr
    local curpos = GetCursorPosition()
    
    -- get quantized pos
    local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( DATA.proj, curpos )
    local posst = TimeMap2_beatsToTime(  DATA.proj, 0, measures )
    local posend = TimeMap2_beatsToTime(  DATA.proj, 0, measures+1)
    
    local item = CreateNewMIDIItemInProj( track, posst, posend )
    SelectAllMediaItems( DATA.proj, false )
    SetMediaItemSelected( item, true )
    SetMediaItemInfo_Value( item, 'B_LOOPSRC',1 )
    
    UpdateItemInProject(item)
    DATA:CollectData_Seq() 
  end
  
  -------------------------------------------------------------------------------  
  function DATA:CollectData_Seq() 
    -- init pattern defaults
    DATA.seq = {
      valid = false,
      ext = {
              patternlen = 16,
              patternsteplen = 0.25,
              children={}, 
              step_defaults={},
              swing = 0,
            }
      }
    
    -- init
    if not (DATA.MIDIbus and DATA.MIDIbus.tr_ptr and DATA.MIDIbus.valid) then return end
    local track = DATA.MIDIbus.tr_ptr
    local item = GetSelectedMediaItem( DATA.proj, 0 )
    if not item then return end
    if GetMediaItem_Track( item ) ~= track then return end  
    local take = GetActiveTake(item)
    
    -- init
    DATA.seq.valid = true
    DATA.seq.it_ptr = item
    DATA.seq.tk_ptr = take 
    DATA.seq.it_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
    DATA.seq.it_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
    DATA.seq.I_GROUPID = GetMediaItemInfo_Value( item, 'I_GROUPID' )
    DATA.seq.D_STARTOFFS = GetMediaItemTakeInfo_Value( take,'D_STARTOFFS' )
    DATA.seq.D_PLAYRATE = GetMediaItemTakeInfo_Value( take,'D_PLAYRATE' )
    local source = GetMediaItemTake_Source( take ) 
    local qnlen, lengthIsQN = reaper.GetMediaSourceLength( source )
    DATA.seq.srclen_sec = TimeMap_QNToTime_abs( DATA.proj, qnlen)
    if DATA.seq.D_STARTOFFS < 0 then
      DATA.seq.it_pos_compensated = DATA.seq.it_pos - DATA.seq.D_STARTOFFS
     elseif DATA.seq.D_STARTOFFS > 0 then
      DATA.seq.it_pos_compensated = DATA.seq.it_pos + (DATA.seq.srclen_sec  - DATA.seq.D_STARTOFFS) /DATA.seq.D_PLAYRATE
     else
      DATA.seq.it_pos_compensated = DATA.seq.it_pos
    end
    local retval, measures, cml, fullbeats_pos, cdenom = reaper.TimeMap2_timeToBeats( DATA.proj, DATA.seq.it_pos )
    local retval, measures, cml, fullbeats_end, cdenom = reaper.TimeMap2_timeToBeats( DATA.proj, DATA.seq.it_pos +  DATA.seq.it_len )
    DATA.seq.it_len_beats =fullbeats_end - fullbeats_pos
    
    DATA.seq.tkname = ''
    local retval, tkname = reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', '', false )
    if retval then DATA.seq.tkname = tkname  end
    
    
    -- load ext data
    local patdata
    local ret_patdata_b64, patdata_b64 = GetSetMediaItemTakeInfo_String( take, 'P_EXT:MPLRS5KMAN_PATDATA', '', false)
    local ret, MPLRS5KMAN_PATDATA_IGNOREB64 = GetSetMediaItemTakeInfo_String( take, 'P_EXT:MPLRS5KMAN_PATDATA_IGNOREB64', '', false) -- 4.43 use native b64 converter
    if (MPLRS5KMAN_PATDATA_IGNOREB64 and tonumber(MPLRS5KMAN_PATDATA_IGNOREB64) and tonumber(MPLRS5KMAN_PATDATA_IGNOREB64) == 1) then 
      patdata = patdata_b64
     else
      if ret_patdata_b64 and patdata_b64 then patdata = VF_decBase64(patdata_b64) end
    end
    if patdata and patdata ~= '' then DATA.seq.ext = table.loadstring(patdata) end
    if not DATA.seq.ext then DATA.seq.ext = {} end
    if not DATA.seq.ext.children then DATA.seq.ext.children = {} end
    if not DATA.seq.ext.patternsteplen then DATA.seq.ext.patternsteplen = 0.25 end-- 4.38+ 
    if not DATA.seq.ext.GUID then DATA.seq.ext.GUID = genGuid() end-- 4.39+
    if not DATA.seq.ext.step_defaults then DATA.seq.ext.step_defaults = {} end-- 4.40+
    if not DATA.seq.ext.swing then DATA.seq.ext.swing = 0 end-- 4.42
    
    
    -- fill / init
    for note in pairs(DATA.children) do
      if not DATA.seq.ext.children[note] then DATA.seq.ext.children[note] = {} end
      if not DATA.seq.ext.children[note].steps then DATA.seq.ext.children[note].steps = {} end -- this is fixing wrong offset on misssing first step at DATA:_Seq_PrintMIDI(t) --{val=0} 
      if not DATA.seq.ext.children[note].step_cnt then DATA.seq.ext.children[note].step_cnt = 16 end--DATA.seq.ext.patternlen end -- init 16 steps 
      if not DATA.seq.ext.children[note].steplength then DATA.seq.ext.children[note].steplength = 0.25 end -- init 16 steps 
      
      for step = 1, DATA.seq.ext.children[note].step_cnt do
        if not DATA.seq.ext.children[note].steps[step] then DATA.seq.ext.children[note].steps[step] = {} end
        if not DATA.seq.ext.children[note].steps[step].val then DATA.seq.ext.children[note].steps[step].val = 0 end
      end
    end
    
    DATA:_Seq_RefreshHScroll()
    
  end
  --------------------------------------------------------------------------------  
  function DATA:_Seq_RefreshHScroll()
    DATA.seq.max_scroll = math.max(16,DATA.seq.ext.patternlen-16) 
    DATA.seq.stepoffs = math.floor((DATA.seq_horiz_scroll or 0)*DATA.seq.max_scroll)
  end
  --------------------------------------------------------------------------------  
  function DATA:_Seq_PrintMIDI(t, do_not_ignore_empty, overrides) 
    local item = t.it_ptr
    local take = t.tk_ptr
    local item_pos = t.it_pos
    
    if not (item and take) then return end
    if not t.ext.children then return end
    
    -- init ppq
    local form_data = {}
    local steplength = 0.25 -- do not touch
    local _, _, _ seqstart_fullbeats = reaper.TimeMap2_timeToBeats( DATA.proj, item_pos ) 
    local seqst_sec = MIDI_GetPPQPosFromProjTime( take, item_pos) 
    local seqend_sec = TimeMap2_beatsToTime(     DATA.proj, seqstart_fullbeats + DATA.seq.ext.patternlen *steplength ) 
    local seqend_endppq = MIDI_GetPPQPosFromProjTime( take, seqend_sec) 
    t.seqend_endppq = seqend_endppq -- send to childs export
    
    -- form table
    for note in pairs(t.ext.children) do
      
      if not DATA.children[note] then goto skipnextnote end
      local steplength = 0.25
      local default_velocity = 120 -- TODO store per note
      if t.ext.children[note].steplength then steplength = t.ext.children[note].steplength end 
      local step_cnt = t.ext.children[note].step_cnt 
      
      local patlen_mult = 1
      if steplength<0.25 then patlen_mult = math.ceil(0.25/steplength) end
      
      local app_swing 
      if DATA.seq.ext.swing~= 0 and steplength==0.25 then app_swing = DATA.seq.ext.swing end
      
      for step = 1, DATA.seq.ext.patternlen*patlen_mult do
        local step_active = step%step_cnt 
        if step_active == 0 then step_active = step_cnt end
        if not (t.ext.children[note].steps and t.ext.children[note].steps[step_active]) then goto skipnextstep end
        
        -- offset 
        local shift = 0
        local sw_shift = 0
        if t.ext.children[note].steps[step_active].offset then shift = t.ext.children[note].steps[step_active].offset*steplength end 
        if app_swing and step%2==0 then 
          sw_shift = app_swing*steplength*0.5
        end
        local beatpos = math.max(0,(step-1)*steplength  +shift + sw_shift)
        if  beatpos > DATA.seq.ext.patternlen then goto skipnextstep end
        
        
        local steppos_start_sec = TimeMap2_beatsToTime(   DATA.proj, seqstart_fullbeats + beatpos ) 
        local steppos_end_sec = TimeMap2_beatsToTime(     DATA.proj, seqstart_fullbeats + step*steplength + shift ) 
        local steppos_start_ppq = MIDI_GetPPQPosFromProjTime( take, steppos_start_sec ) 
        local steppos_end_ppq = MIDI_GetPPQPosFromProjTime( take, steppos_end_sec ) 
        
        if  steppos_end_ppq - steppos_start_ppq < 100 then goto skipnextstep end
        
        -- velocity
        local velocity = 0
        if t.ext.children[note].steps[step_active].val == 1 then velocity = default_velocity end
        if t.ext.children[note].steps[step_active].val  == 1 and t.ext.children[note].steps[step_active].velocity then velocity = math.floor(t.ext.children[note].steps[step_active].velocity*127) end
        
        if steppos_start_ppq < seqend_endppq then--and steppos_end_ppq < seqend_endppq then
          steppos_end_ppq = math.min(steppos_end_ppq, seqend_endppq)
          form_data[#form_data+1] = {
            ppq_start = math.floor(steppos_start_ppq),
            ppq_end = math.floor(steppos_end_ppq),
            pitch = note,
            vel = velocity,
          }
        end
        ::skipnextstep::
      end  
      
      ::skipnextnote::
    end
    if #form_data< 1 and do_not_ignore_empty ~= true then return end
    
    
    -- output to MIDI 
    local offset = 0
    local flags = 0
    local ppq 
    
    local lastppq = 0
    --if #form_data< 1 then lastppq = seqst_sec end
    local str = ''
    local sz = #form_data
    for i = 1, sz do 
      local ppq = form_data[i].ppq_start
      local offset = ppq - lastppq
      local str_per_msg = string.pack("i4Bi4BBB", offset, flags, 3, 0x90, form_data[i].pitch, form_data[i].vel )
      str = str..str_per_msg
      lastppq = ppq
      
      local ppq = form_data[i].ppq_end
      local offset = ppq - lastppq
      local str_per_msg = string.pack("i4Bi4BBB", offset, flags, 3, 0x80, form_data[i].pitch, 0)
      str = str..str_per_msg
      lastppq = ppq 
    end
    
    -- close loop source
      local ppq = t.seqend_endppq
      local offset = math.floor(ppq - lastppq)
      local str_per_msg = string.pack("i4BI4BBB", offset, flags, 3, 0xB0, 123, 0)
      str = str..str_per_msg
    
    
    MIDI_SetAllEvts(take, str)
    MIDI_Sort(take) 
    SetMediaItemTakeInfo_Value( take,'D_STARTOFFS',DATA.seq.D_STARTOFFS )
    
    return form_data
  end
  --------------------------------------------------------------------------------  
  function DATA:_Seq_SetItLength_Beats(patternlen) 
    if not (DATA.MIDIbus and DATA.MIDIbus.tr_ptr and DATA.MIDIbus.valid) then return end
    if not (DATA.seq.it_ptr and DATA.seq.tk_ptr and DATA.seq.ext.patternsteplen) then return end
    
    local out_len_beats = patternlen * DATA.seq.ext.patternsteplen 
    local retval, measures, cml, fullbeats_pos, cdenom = reaper.TimeMap2_timeToBeats( DATA.proj, DATA.seq.it_pos )
    local out_end_sec = TimeMap2_beatsToTime( proj, fullbeats_pos +  out_len_beats)
    SetMediaItemInfo_Value( DATA.seq.it_ptr, 'D_LENGTH', out_end_sec - DATA.seq.it_pos )
    UpdateItemInProject(DATA.seq.it_ptr)
  end
  --------------------------------------------------------------------------------  
  function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  ---------------------------------------------------------------------------------------------------------------------
  function VF_SmoothT(t, smooth)
    local t0 = CopyTable(t)
    for i = 2, #t do t[i]= t0[i] * (t[i] - (t[i] - t[i-1])*smooth )  end
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
  ---------------------------------------------------------------------------------------------------------------------
  function VF_NormalizeT(t, threshold)
    if not t then return end
    local sz
    if type(t) == 'table' then sz = #t else sz = t.get_alloc() end
    local m = 0 
    local val 
    for i= 1, sz do m = math.max(math.abs(t[i]),m) end
    for i= 1, sz do
      val = t[i] / m  
      if threshold and val < threshold then val = 0 end
      t[i] = val
    end
  end 
  ---------------------------------------------------------------------------------------------------------------------
  function VF_GetParentFolder(dir) return dir:match('(.*)[%\\/]') end
  ---------------------------------------------------
  function VF_ReduceFXname(s)
    local s_out = s:match('[%:%/%s]+(.*)')
    if not s_out then return s end
    s_out = s_out:gsub('%(.-%)','') 
    --if s_out:match('%/(.*)') then s_out = s_out:match('%/(.*)') end
    local pat_js = '.*[%/](.*)'
    if s_out:match(pat_js) then s_out = s_out:match(pat_js) end  
    if not s_out then return s else 
      if s_out ~= '' then return s_out else return s end
    end
  end
  ------------------------------------------------------- 
  function VF_BFpluginparam(find_Str, tr, fx, param) 
    if not find_Str then return end
    local find_Str_val = find_Str:match('[%d%-%.]+')
    if not (find_Str_val and tonumber(find_Str_val)) then return end
    local find_val =  tonumber(find_Str_val)
    
    local iterations = 500
    local mindiff = 10^-14
    local precision = 10^-10
    local min, max = 0,1
    for i = 1, iterations do -- iterations
      local param_low = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, min) 
      local param_mid = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, min + (max-min)/2) 
      local param_high = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, max)  
      if find_val <= param_low then return min  end
      if find_val == param_mid and math.abs(min-max) < mindiff then return VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision) end
      if find_val >= param_high then return max end
      if find_val > param_low and find_val < param_mid then 
        min = min 
        max = min + (max-min)/2 
        if math.abs(min-max) < mindiff then return VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision) end
       else
        min = min + (max-min)/2 
        max = max 
        if math.abs(min-max) < mindiff then return VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision) end
      end
    end 
    
  end 
  -------------------------------------------------------  
  function VF_BFpluginparam_GetFormattedParamInternal(tr, fx, param, val)
    local param_n
    if val then TrackFX_SetParamNormalized( tr, fx, param, val ) end
    local _, buf = TrackFX_GetFormattedParamValue( tr , fx, param, '' )
    --local param_str = buf:match('%-[%d%.]+') or buf:match('[%d%.]+')
    local param_str = buf:match('[%d%a%-%.]+')
    if param_str then param_n = tonumber(param_str) end
    if not param_n and param_str:lower():match('%-inf') then param_n = - math.huge
    elseif not param_n and param_str:lower():match('inf') then param_n = math.huge end
    return param_n
  end
  -------------------------------------------------------  
  function VF_BFpluginparam_PreciseCheck(tr, fx, param, find_val, min, max, precision)
    for value_precise = min, max, precision do
      local param_form = VF_BFpluginparam_GetFormattedParamInternal(tr , fx, param, value_precise)  
      if find_val == param_form then  return value_precise end
    end
    return min + (max-min)/2 
  end 
    -----------------------------------------------------------------------------  
  function VF_Open_URL(url) if GetOS():match("OSX") then os.execute('open "" '.. url) else os.execute('start "" '.. url)  end  end  

  ---------------------------------------------------------------------
  function VF_GetLTP()
    local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX() 
    local tr, trGUID, fxGUID, param, paramname, ret, fxname,paramformat
    if retval then 
      tr = CSurf_TrackFromID( tracknumber, false )
      trGUID = GetTrackGUID( tr )
      fxGUID = TrackFX_GetFXGUID( tr, fxnumber )
      retval, buf = reaper.GetTrackName( tr )
      ret, paramname = TrackFX_GetParamName( tr, fxnumber, paramnumber, '')
      ret, fxname = TrackFX_GetFXName( tr, fxnumber, '' )
      paramval = TrackFX_GetParam( tr, fxnumber, paramnumber )
      retval, paramformat = TrackFX_GetFormattedParamValue(  tr, fxnumber, paramnumber, '' )
     else 
      return
    end
    return {tr = tr,
            trtracknumber=tracknumber,
            trGUID = trGUID,
            fxGUID = fxGUID,
            trname = buf,
            paramnumber=paramnumber,
            paramname=paramname,
            paramformat = paramformat,
            paramval=paramval,
            fxnumber=fxnumber,
            fxname=fxname
            }
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
-----------------------------------------------------------------------------------------    -- http://lua-users.org/wiki/SaveTableToFile
function table.exportstring( s ) return string.format("%q", s) end

--// The Save Function
function table.savestring(  tbl )
local outstr = ''
  local charS,charE = "   ","\n"

  -- initiate variables for save procedure
  local tables,lookup = { tbl },{ [tbl] = 1 }
  outstr = outstr..'\n'..( "return {"..charE )

  for idx,t in ipairs( tables ) do
     outstr = outstr..'\n'..( "-- Table: {"..idx.."}"..charE )
     outstr = outstr..'\n'..( "{"..charE )
     local thandled = {}

     for i,v in ipairs( t ) do
        thandled[i] = true
        local stype = type( v )
        -- only handle value
        if stype == "table" then
           if not lookup[v] then
              table.insert( tables, v )
              lookup[v] = #tables
           end
           outstr = outstr..'\n'..( charS.."{"..lookup[v].."},"..charE )
        elseif stype == "string" then
           outstr = outstr..'\n'..(  charS..table.exportstring( v )..","..charE )
        elseif stype == "number" then
           outstr = outstr..'\n'..(  charS..tostring( v )..","..charE )
        end
     end

     for i,v in pairs( t ) do
        -- escape handled values
        if (not thandled[i]) then
        
           local str = ""
           local stype = type( i )
           -- handle index
           if stype == "table" then
              if not lookup[i] then
                 table.insert( tables,i )
                 lookup[i] = #tables
              end
              str = charS.."[{"..lookup[i].."}]="
           elseif stype == "string" then
              str = charS.."["..table.exportstring( i ).."]="
           elseif stype == "number" then
              str = charS.."["..tostring( i ).."]="
           end
        
           if str ~= "" then
              stype = type( v )
              -- handle value
              if stype == "table" then
                 if not lookup[v] then
                    table.insert( tables,v )
                    lookup[v] = #tables
                 end
                 outstr = outstr..'\n'..( str.."{"..lookup[v].."},"..charE )
              elseif stype == "string" then
                 outstr = outstr..'\n'..( str..table.exportstring( v )..","..charE )
              elseif stype == "number" then
                 outstr = outstr..'\n'..( str..tostring( v )..","..charE )
              end
           end
        end
     end
     outstr = outstr..'\n'..( "},"..charE )
  end
  outstr = outstr..'\n'..( "}" )
  return outstr
end

--// The Load Function
function table.loadstring( str )
if str == '' then return end
  local ftables,err = load( str )
  if err then return _,err end
  local tables = ftables()
  for idx = 1,#tables do
     local tolinki = {}
     for i,v in pairs( tables[idx] ) do
        if type( v ) == "table" then
           tables[idx][i] = tables[v[1]]
        end
        if type( i ) == "table" and tables[i[1]] then
           table.insert( tolinki,{ i,tables[i[1]] } )
        end
     end
     -- link indices
     for _,v in ipairs( tolinki ) do
        tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
     end
  end
  return tables[1]
end  
  ------------------------------------------------------------------------------------------------------
  function VF_lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
    ---------------------------------------------------------------------  
  function VF_LIP_load(fileName) -- https://github.com/Dynodzzo/Lua_INI_Parser/blob/master/LIP.lua
    assert(type(fileName) == 'string', 'Parameter "fileName" must be a string.');
    local file = assert(io.open(fileName, 'r'), 'Error loading file : ' .. fileName);
    local data = {};
    local section;
    for line in file:lines() do
      local tempSection = line:match('^%[([^%[%]]+)%]$');
      if(tempSection)then
        section = tonumber(tempSection) and tonumber(tempSection) or tempSection;
        data[section] = data[section] or {};
      end
      local param, value = line:match('^([%w|_]+)%s-=%s-(.+)$');
      if(param and value ~= nil)then
        if(tonumber(value))then
          value = tonumber(value);
        elseif(value == 'true')then
          value = true;
        elseif(value == 'false')then
          value = false;
        end
        if(tonumber(param))then
          param = tonumber(param);
        end
        if data[section] then 
          data[section][param] = value;
        end
      end
    end
    file:close();
    return data;
  end
    ---------------------------------------------------------------------------------------------------------------------
  function VF_encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
    if not data then return end
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
      return ((data:gsub('.', function(x) 
          local r,b='',x:byte()
          for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
          return r;
      end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
          if (#x < 6) then return '' end
          local c=0
          for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
          return b:sub(c+1,c+1)
      end)..({ '', '==', '=' })[#data%3+1])
  end
  ------------------------------------------------------------------------------------------------------
  function VF_decBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
      data = string.gsub(data, '[^'..b..'=]', '')
      return (data:gsub('.', function(x)
          if (x == '=') then return '' end
          local r,f='',(b:find(x)-1)
          for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
          return r;
      end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
          if (#x ~= 8) then return '' end
          local c=0
          for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
              return string.char(c)
      end))
  end
  ---------------------------------------------------------------------------------------------------------------------
  function VF_GetShortSmplName(path) 
    local fn = path
    fn = fn:gsub('%\\','/')
    if fn then fn = fn:reverse():match('(.-)/') end
    if fn then fn = fn:reverse() end
    return fn
  end
  ---------------------------------------------------------------------  
  function VF_Format_Pan(D_PAN) 
    local D_PAN_format = 'C'
    if D_PAN > 0 then 
      D_PAN_format = math.floor(math.abs(D_PAN*100))..'R'
     elseif D_PAN < 0 then 
      D_PAN_format = math.floor(math.abs(D_PAN*100))..'L'
    end
    return D_PAN_format
  end
  ----------------------------------------------------------------------- 
  function VF_Format_Note(note ,t) 
    local offs = 0
    if DATA.REAPERini and DATA.REAPERini.REAPER and DATA.REAPERini.REAPER.midioctoffs then offs = DATA.REAPERini.REAPER.midioctoffs end
    local val = math.floor(note)
    local oct = math.floor(note / 12)
    local note = math.fmod(note,  12)
    local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
    
    local out_str 
    
    -- handle names
      if t and t.P_NAME then out_str = t.P_NAME end 
    --[[ handle db
      if t and t.layers then 
        local hasdb
        for layer = 1, #t.layers do
          if t.layers[layer].SET_useDB and t.layers[layer].SET_useDB&1==1 then 
            hasdb = true
          end
        end
        if hasdb == true then out_str = '[DB] '..out_str  end
      end]]
      
      if out_str then return out_str end
      
    -- note  
      if note and oct and key_names[note+1] then 
        return key_names[note+1]..oct-1 
      end
  end
  
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else return v end
  end
  --------------------------------------------------
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or -1) do
      local tr = GetTrack(reaproj or -1,i-1)
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end
  ---------------------------------------------------
  function VF_GetFXByGUID(GUID, tr, proj)
    if not GUID then return end
    local pat = '[%p]+'
    if not tr then
      for trid = 1, CountTracks(proj or -1) do
        local tr = GetTrack(proj,trid-1)
        local fxcnt_main = TrackFX_GetCount( tr ) 
        local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
        for fx = 1, fxcnt do
          local fx_dest = fx
          if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
          if TrackFX_GetFXGUID( tr, fx-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx-1 end 
        end
      end  
     else
      if not (ValidatePtr2(proj or -1, tr, 'MediaTrack*')) then return end
      local fxcnt_main = TrackFX_GetCount( tr ) 
      local fxcnt = fxcnt_main + TrackFX_GetRecCount( tr ) 
      for fx = 1, fxcnt do
        local fx_dest = fx
        if fx > fxcnt_main then fx_dest = 0x1000000 + fx - fxcnt_main end  
        if TrackFX_GetFXGUID( tr, fx_dest-1):gsub(pat,'') == GUID:gsub(pat,'') then return true, tr, fx_dest-1 end 
      end
    end    
  end
  
  -------------------------------------------------------------------------------- 
  function DATA:CollectData2() -- do various stuff after refresh main data 
    if not (DATA.upd2 and DATA.upd2.refresh == true) then return end
    if DATA.upd2.updatedevicevelocityrange then DATA:Auto_Device_RefreshVelocityRange(DATA.upd2.updatedevicevelocityrange) end
    if DATA.upd2.seqprint then DATA:_Seq_Print(nil, DATA.upd2.seqprint_minor)  end
    DATA:CollectData2_GetPeaks()
    DATA.upd2 = {} 
  end  
  
  -------------------------------------------------------------------------------- 
  function EXT:save() 
    if not DATA.ES_key then return end 
    for key in pairs(EXT) do 
      if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then 
        SetExtState( DATA.ES_key, key, EXT[key], true  ) 
      end 
    end 
    EXT:load()
  end
  -------------------------------------------------------------------------------- 
  function EXT:load() 
    if not DATA.ES_key then return end
    for key in pairs(EXT) do 
      if (type(EXT[key]) == 'string' or type(EXT[key]) == 'number') then 
        if HasExtState( DATA.ES_key, key ) then 
          local val = GetExtState( DATA.ES_key, key ) 
          EXT[key] = tonumber(val) or val 
        end 
      end  
    end 
    --DATA.upd = true
  end
  -------------------------------------------------------------------------------- 
  function DATA:handleViewportXYWH()
    if not (DATA.display_x and DATA.display_y) then return end 
    if not DATA.display_x_last then DATA.display_x_last = DATA.display_x end
    if not DATA.display_y_last then DATA.display_y_last = DATA.display_y end
    if not DATA.display_w_last then DATA.display_w_last = DATA.display_w end
    if not DATA.display_h_last then DATA.display_h_last = DATA.display_h end
    
    if  DATA.display_x_last~= DATA.display_x 
      or DATA.display_y_last~= DATA.display_y 
      or DATA.display_w_last~= DATA.display_w 
      or DATA.display_h_last~= DATA.display_h 
      --or (DATA.display_dockID and DATA.display_dockID ~= DATA.dockID)
      then 
      DATA.display_schedule_save = os.clock() 
    end
    if DATA.display_schedule_save and os.clock() - DATA.display_schedule_save > 0.3 then 
      EXT.viewport_posX = DATA.display_x
      EXT.viewport_posY = DATA.display_y
      EXT.viewport_posW = DATA.display_w
      EXT.viewport_posH = DATA.display_h
      --EXT.viewport_dockID = DATA.display_dockID
      EXT:save() 
      DATA.display_schedule_save = nil 
    end
    DATA.display_x_last = DATA.display_x
    DATA.display_y_last = DATA.display_y
    DATA.display_w_last = DATA.display_w
    DATA.display_h_last = DATA.display_h
    
    --DATA.display_dockID = DATA.dockID
  end
  -------------------------------------------------------------------------------- 
  function DATA:handleProjUpdates()
    local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
    local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
    local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
  end
    function VF_GetProjectSampleRate() return tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) end -- get sample rate obey project start offset
  --------------------------------------------------------------------------------  
  function DATA:CollectData()  
    DATA.proj, DATA.proj_fn = EnumProjects( -1 )
    DATA.SR = VF_GetProjectSampleRate()
    
     -- parent
    DATA.parent_track = {
        valid = false,
        name = '', 
      }
    DATA:CollectData_Parent()
    
    -- children
    DATA.MIDIbus = {} 
    DATA.children = {}
    DATA:CollectData_Children()
    
    -- macro
    DATA:CollectData_Macro()
     
    -- other
    DATA:CollectData_ReadChoke() 
    
    -- seq
    DATA:CollectData_Seq()
    -- auto handle routing and stuff
    DATA:Auto_MIDIrouting() 
    DATA:Auto_MIDInotenames() 
    DATA:Auto_TCPMCP() 
     
    DATA:Auto_StuffSysex()
    
    DATA.upd2.refresh = true
  end
  -------------------------------------------------------------------------------- 
  function DATA:Auto_TCPMCP(force_show)
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end 
    
    if force_show == true then 
      for child in pairs(DATA.children) do
        local tr = DATA.children[child].tr_ptr
        SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 1)
        SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP',1 )
      end
    end
    
    
    if EXT.CONF_onadd_newchild_trackheightflags &1==1 then       -- set folder collapsed
      SetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT', 1)
     elseif EXT.CONF_onadd_newchild_trackheightflags &2==2 then       -- set folder collapsed
      SetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT', 2)
     elseif EXT.CONF_onadd_newchild_trackheightflags &2~=2 and EXT.CONF_onadd_newchild_trackheightflags &1~=1 then       -- set folder collapsed
      --local foldstate = GetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT')   
      --if foldstate ~=0 then SetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT', 0)       end
    end
  
    --if EXT.CONF_onadd_newchild_trackheightflags &4==4 or EXT.CONF_onadd_newchild_trackheightflags &8==8 then
      for child in pairs(DATA.children) do
        local tr = DATA.children[child].tr_ptr
        -- device
        if tr then 
          if EXT.CONF_onadd_newchild_trackheightflags &8==8 then 
            if GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER') == 1 then SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 0 )end
           elseif EXT.CONF_onadd_newchild_trackheightflags &4==4 then 
            if GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP') == 1 then SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP', 0 )end 
           else 
            --if GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP') == 0 then SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP', 1 )end             
            --if GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER') == 0 then SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 1 )end             
          end
        end
        -- children
        for layer = 1, #DATA.children[child].layers do 
          local tr = DATA.children[child].layers[layer].tr_ptr
          if tr then 
            if EXT.CONF_onadd_newchild_trackheightflags &8==8 then 
              if GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER') == 1 then SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 0 )end
             elseif EXT.CONF_onadd_newchild_trackheightflags &4==4 then 
              if GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP') == 1 then SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP', 0 )end 
             else 
              --if GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP') == 0 then SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP', 1 )end             
              --if GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER') == 0 then SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 1 )end             
            end
          end
        end
      end
    --end
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectDataInit_ParseREAPERDB()
    if EXT.CONF_ignoreDBload == 1 then return end
    local reaperini = get_ini_file()
    local backend = VF_LIP_load(reaperini)
    local exp_section = backend.reaper_explorer
    if not exp_section then 
      exp_section = backend.reaper_sexplorer
      if not exp_section then return end
    end 
    
    
    local reaperDB = {}
    for key in pairs(exp_section) do
      if key:match('Shortcut') then 
        if tostring(exp_section[key]) and tostring(exp_section[key]):lower():match('reaperfilelist') then 
          local db_key = key:gsub('Shortcut','ShortcutT')
          if exp_section[db_key] then   
            local dbame = exp_section[db_key]
            local db_filename = exp_section[key]
            DATA.reaperDB[dbame] = {filename = db_filename}
            
            local fullfp =  GetResourcePath()..'/MediaDB/'..db_filename
            local t = {}
            if  file_exists( fullfp ) then  
              t = {}
              local f =io.open(fullfp,'rb')
              local content = ''
              if f then  content = f:read('a') end f:close() 
              for line in content:gmatch('[^\r\n]+') do
                if line:match('FILE %"(.-)%"') then
                  local fp = line:match('FILE %"(.-)%"')
                  t [#t+1] = {fp = fp,
                              fp_short  =VF_GetShortSmplName(fp)
                              }
                end 
              end
            end
            
            DATA.reaperDB[dbame].files = t
            
          end
        end
      end
    end
    
  end
  ---------------------------------------------------------------------------------------------------------------------
  function DATA:CollectData2_GetPeaks_grabpeaks(t, padw, ignoreboundary) 
    local filename = t.instrument_filename
    if not filename then return end
    if not padw then return end
    
    local src = PCM_Source_CreateFromFileEx(filename, true )
    if not src then return end  
    local src_len =  GetMediaSourceLength( src ) 
    local stoffs_sec = 0
    local slice_len = src_len
    if ignoreboundary~= true then
      stoffs_sec = t.instrument_samplestoffs * src_len
      slice_len = src_len * (t.instrument_sampleendoffs - t.instrument_samplestoffs) 
    end
    local SR = GetMediaSourceSampleRate( src )
    local peakrate = SR
    if padw ~= -1 then
      peakrate =  math.max(padw / slice_len,200)
    end
     
    -- if slice_len > 30 then return {}, slice_len end   
    if slice_len < 0.01 then return  end   
    local n_ch = 1
    local want_extra_type = 0--115  -- 's' char 
    local n_spls = math.floor(slice_len*peakrate)
    if n_spls < 10 then return end  
    local buf = new_array(n_spls * n_ch * 2) -- min, max, spectral each chan(but now mono only)
    local retval =  PCM_Source_GetPeaks(    src, 
                                        peakrate, 
                                        stoffs_sec,--starttime, 
                                        n_ch,--numchannels, 
                                        n_spls, 
                                        want_extra_type, 
                                        buf ) 
    --buf.clear() 
    PCM_Source_Destroy( src )
    return buf, SR
  end
  ---------------------------------------------------------------------------------------------------------------------
  function DATA:CollectData2_GetPeaks()
    for note in pairs(DATA.children) do
      if DATA.children[note].layers and DATA.children[note].layers[1] then   
        local t = DATA.children[note].layers[1] 
        if not (DATA.peakscache[note] and DATA.peakscache[note].peaks_arr_valid==true and DATA.peakscache[note].peaks_arr) then 
          local arr = DATA:CollectData2_GetPeaks_grabpeaks(t, UI.calc_rack_padw) 
          if not DATA.peakscache[note] then DATA.peakscache[note] = {} end
          DATA.peakscache[note].peaks_arr = arr
          DATA.peakscache[note].peaks_arr_valid = true
        end
      end
    end
    
    local t, note, layer = DATA:Sampler_GetActiveNoteLayer()
    if DATA.children and DATA.children[note] and DATA.children[note].layers and DATA.children[note].layers[1] then
      if not (t.peaks_arr_sampler and t.peaks_arr_sampler_valid==true) then 
        t.peaks_arr_sampler = DATA:CollectData2_GetPeaks_grabpeaks(t, UI.settingsfixedW) 
        local full = true
        t.peaks_arr_samplerfull = DATA:CollectData2_GetPeaks_grabpeaks(t, UI.settingsfixedW, full) 
        t.peaks_arr_sampler_valid = true
      end
    end
  end    
  --------------------------------------------------------------------------------
  function DATA:CollectData_Always_RecentEvent()
    if not DATA.SR then return end
    local triggernote
    local retval, rawmsg, tsval, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(0)
    if retval == 0 then return end -- stop if return null sequence
    if not ((devIdx & 0x10000) == 0 or devIdx == 0x1003e) then return end-- should works without this after REAPER6.39rc2, so thats just in case
    local isNoteOn = rawmsg:byte(1)>>4 == 0x9
    local isNoteOff = rawmsg:byte(1)>>4 == 0x8
    local playingnote = rawmsg:byte(2) 
    if isNoteOn == true and tsval > -4800 then -- only reeeally latest messages
      if (DATA.lastMIDIinputnote and DATA.lastMIDIinputnote ~= playingnote) then triggernote = true end
      DATA.lastMIDIinputnote = playingnote 
    end--{retval=retval, rawmsg=rawmsg, tsval=tsval, devIdx=devIdx, projPos=projPos, projLoopCnt=projLoopCnt,playingnote = rawmsg:byte(2) } 

    
    if triggernote == true then 
      if  EXT.UI_incomingnoteselectpad == 1 and DATA.parent_track and DATA.parent_track.ext then
        DATA.parent_track.ext.PARENT_LASTACTIVENOTE = DATA.lastMIDIinputnote
        DATA:WriteData_Parent() --trigger write parent at script initialization // false storing last touched note to ext state
        DATA.upd = true
      end
    end
    
  end
  --------------------------------------------------------------------------------
  function DATA:CollectData_Always()
    DATA:CollectData_Always_RecentEvent()
    DATA:CollectData_Always_ExtActions() 
    DATA:CollectData_Always_Peaks() 
    DATA:CollectData_Always_StepPositions()
  end
  ----------------------------------------------------------------------
  function DATA:CollectData_Always_Peaks() 
    if not DATA.children then return end
    if EXT.CONF_showplayingmeters == 0 then return end
    local max_sz = 2
    for note in pairs(DATA.children) do
      if not DATA.children[note].peaks then DATA.children[note].peaks = {} end
      local track = DATA.children[note].tr_ptr
      if track and ValidatePtr2(-1,track, 'MediaTrack*') then
        local L = Track_GetPeakInfo( track, 0 )
        local R = Track_GetPeakInfo( track, 1 )
        table.insert(DATA.children[note].peaks, 1, {L,R})
        local sz = #DATA.children[note].peaks
        local rmsL,rmsR = 0,0
        for i = 1, sz do
          rmsL = rmsL + DATA.children[note].peaks[i][1]
          rmsR = rmsR + DATA.children[note].peaks[i][2]
        end
        DATA.children[note].peaksRMS_L = rmsL / sz
        DATA.children[note].peaksRMS_R = rmsR / sz
        if sz>max_sz then DATA.children[note].peaks[max_sz+1] = nil end
      end
      
    end
  end
  ----------------------------------------------------------------------
  function DATA:CollectData_Always_ExtActions()
    local actions = gmem_read(1025)
    if actions == 0 then return end
    
    -- Device / New kit
    if actions == 1 then    DATA:Sampler_NewRandomKit() end 
    
    
    -- prev sample
    if actions == 2 then   
      local note_layer_t = DATA:Sampler_GetActiveNoteLayer() 
      DATA:Sampler_NextPrevSample(note_layer_t,1) 
    end
    
    -- next sample
    if actions == 3 then   
      local note_layer_t, spls = DATA:Sampler_GetActiveNoteLayer()
      DATA:Sampler_NextPrevSample(note_layer_t,0 )  
    end
    
    -- rand sample
    if actions == 4 then   
      local note_layer_t, spls = DATA:Sampler_GetActiveNoteLayer()
      DATA:Sampler_NextPrevSample(note_layer_t,2 ) 
    end
  
    if actions == 6 then   -- lock active note database changes 
      if DATA.parent_track and DATA.parent_track.ext then
        local note_layer_t = DATA:Sampler_GetActiveNoteLayer() 
        note_layer_t.SET_useDB = note_layer_t.SET_useDB~2
        DATA.upd = true
        Undo_BeginBlock2(DATA.proj )
        DATA:WriteData_Child(tr, {SET_useDB=note_layer_t.SET_useDB})
        Undo_EndBlock2( DATA.proj , 'RS5k manager - lock sample from randomization', 0xFFFFFFFF )  
      end 
    end
    
    if actions == 7 then   -- drumrack solo
      if DATA.parent_track and DATA.parent_track.ext then 
        local note = DATA.parent_track.ext.PARENT_LASTACTIVENOTE
        local note_t = DATA.children[note]
        Undo_BeginBlock2(DATA.proj )
        local outval = 2 if note_t.I_SOLO>0 then outval = 0 end SetMediaTrackInfo_Value( note_t.tr_ptr, 'I_SOLO', outval ) DATA.upd = true
        Undo_EndBlock2( DATA.proj , 'RS5k manager - Solo pad', 0xFFFFFFFF ) 
      end 
    end
    
    if actions == 8 then   -- drumrack mute
      if DATA.parent_track and DATA.parent_track.ext then 
        local note = DATA.parent_track.ext.PARENT_LASTACTIVENOTE
        local note_t = DATA.children[note]
        Undo_BeginBlock2(DATA.proj )
        SetMediaTrackInfo_Value( note_t.tr_ptr, 'B_MUTE', note_t.B_MUTE~1 ) DATA.upd = true
        Undo_EndBlock2( DATA.proj , 'RS5k manager - Mute pad', 0xFFFFFFFF ) 
      end 
    end
  
    if actions == 9 then   -- drumrack clear
      if DATA.parent_track and DATA.parent_track.ext then 
        DATA:Sampler_RemovePad(DATA.parent_track.ext.PARENT_LASTACTIVENOTE)
      end
    end
    
    
    gmem_write(1025,0 )
  end
  -----------------------------------------------------------------------
  function DATA:Sampler_RemovePad(note, layer) 
    if not (note and DATA.children and DATA.children[note]) then return end 
    local tr_ptr = DATA.children[note].tr_ptr
    if layer and DATA.children[note].layers and DATA.children[note].layers[layer] and DATA.children[note].layers[layer].tr_ptr then tr_ptr = DATA.children[note].layers[layer].tr_ptr end 
    --[[if not layer and not tr_ptr then 
      layer = 1
      if DATA.children[note].layers and DATA.children[note].layers[layer] then tr_ptr = DATA.children[note].layers[layer].tr_ptr end 
    end]]
    
    if not (tr_ptr and ValidatePtr2(-1,tr_ptr,'MediaTrack*')) then return end
    
    Undo_BeginBlock2(DATA.proj )
    --DeleteTrack( tr_ptr )
    Main_OnCommand(40769,0)-- Unselect (clear selection of) all tracks/items/envelope points 
    SetOnlyTrackSelected( tr_ptr )
    --Main_OnCommand(40184,0)-- Remove items/tracks/envelope points (depending on focus) - no prompting // THIS remove device with childrens AND handles keeping structure 
    Main_OnCommand(40005,0)-- Track: Remove tracks
    Undo_EndBlock2( DATA.proj , 'RS5k manager - Remove pad', 0xFFFFFFFF ) 
    SetOnlyTrackSelected( DATA.parent_track.ptr )
    DATA.upd = true
  end 
  ---------------------------------------------------------------------------------------------------------------------
  function DATA:Sampler_GetActiveNoteLayer()  
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end
    local layer =  DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER or 1  
    local note if not DATA.parent_track.ext.PARENT_LASTACTIVENOTE then return else note =DATA.parent_track.ext.PARENT_LASTACTIVENOTE end
    
    if DATA.children[note] 
      and DATA.children[note].layers 
      and DATA.children[note].layers[layer] then  
      return DATA.children[note].layers[layer],note,layer
    end
    
    if DATA.children[note] and DATA.children[note].layers and not DATA.children[note].layers[layer] then  
      return DATA.children[note],note,0
    end
    
  end
  -------------------------------------------------------------------------------- 
  function DATA:Sampler_NextPrevSample_getfilestable(note_layer_t) 
    local noteID = note_layer_t.noteID
    if noteID then DATA.peakscache[noteID] = nil end
    
    local fn = note_layer_t.instrument_filename:gsub('\\', '/') 
    local path = fn:reverse():match('[%/]+.*'):reverse():sub(0,-2)
    local cur_file =     fn:reverse():match('.-[%/]'):reverse():sub(2)
    local files_table = {}
    if note_layer_t.SET_useDB&1~=1 then 
      local i = 0
      repeat
        local fp = reaper.EnumerateFiles( path, i )
        if fp and reaper.IsMediaExtension(fp:gsub('.+%.', ''), false) then
          files_table[#files_table+1] = { fp = path..'/'..fp,
                                          fp_short  =fp
                                        }
        end
        i = i+1
      until fp == nil
      table.sort(files_table, function(a,b) return a.fp_short<b.fp_short end )
     else
      local db_name = note_layer_t.SET_useDB_name
      if db_name and DATA.reaperDB[db_name] then files_table = DATA.reaperDB[db_name].files end
    end
    return files_table,cur_file
  end
  -------------------------------------------------------------------------------- 
  function DATA:Sampler_NextPrevSample(note_layer_t, mode) 
     
    if not mode then mode = 0 end
    if not note_layer_t.ISRS5K then return end
    
   
    local files_table,cur_file = DATA:Sampler_NextPrevSample_getfilestable(note_layer_t) 
    local trig_id
    local undohistory_str = 'Next sample'
    local files_tablesz = #files_table 
    
    local currentID = note_layer_t.SET_useDB_lastID
    if not currentID and mode ~=2 then 
      for i = 1, #files_table do if files_table[i].fp_short == cur_file then  currentID=i break end  end
    end
    
    if mode == 0  then    -- search file list next
      if #files_table < 2 then return end
      trig_id = currentID + 1
      if trig_id > files_tablesz then trig_id = 1 end--wrap
      goto trig_file_section
    end
    
    if mode == 1  then    -- search file list prev
      if files_tablesz < 2 then return end
      trig_id = currentID - 1
      if trig_id <1 then trig_id = files_tablesz end--wrap
      goto trig_file_section
    end
      
    if mode ==2 then        -- search file list random
      math.randomseed(time_precise()*10000)
      if #files_table < 2 then return end
      trig_id = math.floor(math.random(#files_table)) +1
      goto trig_file_section 
    end    
    
    ::trig_file_section::
    if trig_id and files_table[trig_id] then 
      local trig_file = files_table[trig_id].fp
      Undo_BeginBlock2(DATA.proj )
      DATA:DropSample(trig_file, note_layer_t.noteID, {layer=note_layer_t.layerID})  
      Undo_EndBlock2( DATA.proj , 'RS5k manager - '..undohistory_str, 0xFFFFFFFF ) 
      DATA:WriteData_Child(note_layer_t.tr_ptr, {SET_useDB_lastID = trig_id})   
    end
      
  end
  --------------------------------------------------------------------------------  
  function DATA:CollectDataInit_MIDIdevices()
    DATA.MIDI_inputs = {[63]='All inputs',[62]='Virtual keyboard'}
    for dev = 1, reaper.GetNumMIDIInputs() do
      local retval, nameout = reaper.GetMIDIInputName( dev-1, '' )
      if retval then DATA.MIDI_inputs[dev-1] = nameout end
    end
  end
  ---------------------------------------------------------------------  
  function DATA:Auto_StuffSysex_dec2hex(dec)  local pat = "%02X" return  string.format(pat, dec) end
  function DATA:Auto_StuffSysex() 
    if EXT.UI_drracklayout == 2 then DATA:Auto_StuffSysex_sub('set/refresh active state') end 
  end  
  
  ---------------------------------------------------------------------  
  function DATA:Auto_StuffSysex_sub(cmd) local SysEx_msg  
    if  not (EXT.CONF_launchpadsendMIDI == 1 and EXT.UI_drracklayout == 2) then return end 
    -- search HW MIDI out 
      local is_LPminiMK3
      local is_LPProMK3
      --local LPminiMK3_name = "LPMiniMK3 MIDI"
      local LPminiMK3_name = "MIDIOUT2 (LPMiniMK3 MIDI)"
      local LPProMK3_name = "LPProMK3 MIDI"
      for dev = 1, reaper.GetNumMIDIOutputs() do
        local retval, nameout = reaper.GetMIDIOutputName( dev-1, '' )
        if retval and nameout == LPminiMK3_name then HWdevoutID =  dev-1 is_LPminiMK3 = true break end --nameout:match(LPminiMK3_name)
        if retval and nameout == LPProMK3_name then HWdevoutID =  dev-1 is_LPProMK3 = true break end 
      end
      if not HWdevoutID then return end
    
    -- action on release
    if cmd == 'on release' then -- set to key layout
      if is_LPminiMK3 ==true then 
        SysEx_msg = 'F0h 00h 20h 29h 02h 0Dh 00h 05 F7h' 
        DATA:Auto_StuffSysex_stuff(SysEx_msg, HWdevoutID) 
      end
      if is_LPProMK3 ==true then 
        SysEx_msg = 'F0h 00h 20h 29h 02h 0Eh 00h 04 00 00h F7h' 
        DATA:Auto_StuffSysex_stuff(SysEx_msg, HWdevoutID) 
      end
    end
    
    
    
    -- 
      if cmd == 'set/refresh active state' then
        SysEx_msg = 'F0h 00h 20h 29h 02h 0Dh 00h 7F F7h' 
        DATA:Auto_StuffSysex_stuff(SysEx_msg, HWdevoutID) 
      end
    
    --[[if cmd == 'drum layout' then
      
      if cmd == 'drum mode' then
        if is_LPminiMK3 ==true then 
          SysEx_msg = 'F0h 00h 20h 29h 02h 0Dh 10h 01 F7h' 
          DATA:Auto_StuffSysex_stuff(SysEx_msg, HWdevoutID) 
        end
      end
      
      
      if is_LPminiMK3 ==true or is_LPProMK3==true then 
        for ledId = 0, 81 do
          if DATA.children and DATA.children[ledId] and DATA.children[ledId].I_CUSTOMCOLOR then
            local msgtype = 90
            if DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE and DATA.parent_track.ext.PARENT_LASTACTIVENOTE == ledId then msgtype = 92 end
            SysEx_msg = msgtype..' '..string.format("%02X", ledId)..' 16'
            DATA:Auto_StuffSysex_stuff(SysEx_msg, HWdevoutID) 
           else
            local col = '00'
            if DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE and DATA.parent_track.ext.PARENT_LASTACTIVENOTE == ledId then col = '03' end
            SysEx_msg = '90 '..string.format("%02X", ledId)..' '..col
            DATA:Auto_StuffSysex_stuff(SysEx_msg, HWdevoutID) 
          end
        end
      end
      
    end]]
    
    
    --[[
    
    if cmd == 'programmer mode' then
      if is_LPminiMK3 ==true then 
        SysEx_msg = 'F0h 00h 20h 29h 02h 0Dh 00h 7F F7h' 
        DATA:Auto_StuffSysex_stuff(SysEx_msg, HWdevoutID) 
      end
      if is_LPProMK3 ==true then 
        SysEx_msg = 'F0h 00h 20h 29h 02h 0Eh 00h 11 00 00h F7h'
        DATA:Auto_StuffSysex_stuff(SysEx_msg, HWdevoutID) 
      end
    end
    
    
    
    if cmd == 'programmer mode: set colors' then
      
        local colorstr = '' 
        for ledId = 0, 81 do
          if DATA.children and DATA.children[ledId] and DATA.children[ledId].I_CUSTOMCOLOR then
            local lightingtype = 3 
            local color = ImGui.ColorConvertNative(DATA.children[ledId].I_CUSTOMCOLOR) & 0xFFFFFF 
            r = math.floor(((color>>16)&0xFF) * 0.5)
            g = math.floor(((color>>8)&0xFF) * 0.5)
            b = math.floor(((color>>0)&0xFF) * 0.5)
            colorstr = colorstr..
              DATA:Auto_StuffSysex_dec2hex(lightingtype)..' '..
              DATA:Auto_StuffSysex_dec2hex(ledId)..' '..
              string.format("%X", r)..' '..
              string.format("%X", g)..' '..
              string.format("%X", b)..' '
           else
            local lightingtype = 0
            local palettecol = 0
            colorstr = colorstr..
              DATA:Auto_StuffSysex_dec2hex(lightingtype)..' '..
              DATA:Auto_StuffSysex_dec2hex(ledId)..' '..
              DATA:Auto_StuffSysex_dec2hex(palettecol)..' '
          end
        end
        
        if is_LPminiMK3 ==true then SysEx_msg = 'F0h 00h 20h 29h 02h 0Dh 03h '..colorstr..'F7h' end
        if is_LPProMK3 ==true then SysEx_msg = 'F0h 00h 20h 29h 02h 0Eh 03h '..colorstr..'F7h' end 

    end]]
    
  end 
  ---------------------------------------------------------------------  
  function DATA:Auto_StuffSysex_stuff(SysEx_msg, HWdevoutID) 
    if SysEx_msg and HWdevoutID then
      local SysEx_msg_bin = '' for hex in SysEx_msg:gmatch('[A-F,0-9]+') do  SysEx_msg_bin = SysEx_msg_bin..string.char(tonumber(hex, 16)) end 
      SendMIDIMessageToHardware(HWdevoutID, SysEx_msg_bin)
    end
  end
  --------------------------------------------------------------------- 
  function DATA:Auto_Device_RefreshVelocityRange(note)
    if not (DATA.children and DATA.children[note] and DATA.children[note].layers) then return end
    if DATA.children[note].TYPE_DEVICE_AUTORANGE == false then return end
    
    if #DATA.children[note].layers == 0 then return end
    
    local min_velID = 17
    local max_velID = 18
    local block_sz = 127 / #DATA.children[note].layers
    
    for layer =1, #DATA.children[note].layers do
      if DATA.children[note].layers[layer].ISRS5K == true then 
        local track = DATA.children[note].layers[layer].tr_ptr
        local instrument_pos = DATA.children[note].layers[layer].instrument_pos
        
        TrackFX_SetParamNormalized( track, instrument_pos, min_velID, (block_sz*(layer-1))  *1/127)
        TrackFX_SetParamNormalized( track, instrument_pos, max_velID, (-1+block_sz*(layer))  *1/127 )
        if layer == #DATA.children[note].layers then 
          TrackFX_SetParamNormalized( track, instrument_pos, max_velID, 1)
        end
      end 
    end
  end
  --------------------------------------------------------------------- 
  function DATA:Auto_MIDInotenames() 
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end 
    
    for note = 0,127 do 
      if EXT.CONF_autorenamemidinotenames&1==1 then 
        -- midi bus
        if DATA.MIDIbus.valid == true then
          local outname = ''
          if DATA.children[note] and DATA.children[note].P_NAME then outname = DATA.children[note].P_NAME end
          if DATA.padcustomnames and DATA.padcustomnames[note] and DATA.padcustomnames[note] ~='' then outname = DATA.padcustomnames[note] end
          local curname = GetTrackMIDINoteNameEx( DATA.proj,  DATA.MIDIbus.tr_ptr, note,-1 )
          if curname ~= outname then SetTrackMIDINoteNameEx( DATA.proj,  DATA.MIDIbus.tr_ptr, note, -1, outname) end
        end
      end
      
      if EXT.CONF_autorenamemidinotenames&2==2 then 
        -- clear device
        if DATA.children[note] and DATA.children[note].tr_ptr and DATA.children[note].TYPE_DEVICE == true then 
          local curname = GetTrackMIDINoteNameEx( DATA.proj,  DATA.children[note].tr_ptr, note,-1 )
          if curname ~= '' then SetTrackMIDINoteNameEx( DATA.proj, DATA.children[note].tr_ptr, note, -1, '') end
        end
        -- set reg childrens to only theirs notes
        if DATA.children[note] and DATA.children[note].tr_ptr and DATA.children[note].layers then 
          for layer =1 , #DATA.children[note].layers do
            for tracknote = 0, 127 do
              local outname = ''
              if tracknote == note then outname =DATA.children[note].layers[layer].P_NAME end
              local curname = GetTrackMIDINoteNameEx( DATA.proj,  DATA.children[note].layers[layer].tr_ptr, tracknote,-1 )
              if curname ~= outname then SetTrackMIDINoteNameEx( DATA.proj,  DATA.children[note].layers[layer].tr_ptr, tracknote, -1, outname) end
            end 
          end
        end
        
      end
    end
  end
  -----------------------------------------------------------------------  
  function DATA:Validate_InitFilterDrive(note_layer_t) 
    local track = note_layer_t.tr_ptr
    if not note_layer_t.fx_reaeq_isvalid then 
      local reaeq_pos = TrackFX_AddByName( track, 'ReaEQ', 0, 1 )
      TrackFX_Show( track, reaeq_pos, 2 )
      TrackFX_SetNamedConfigParm( track, reaeq_pos, 'BANDTYPE0',3 )
      TrackFX_SetParamNormalized( track, reaeq_pos, 0, 1 )
      local GUID = reaper.TrackFX_GetFXGUID( track, reaeq_pos )
      DATA:WriteData_Child(track, {FX_REAEQ_GUID = GUID}) 
      DATA.upd = true
    end
     
    if not note_layer_t.fx_ws_isvalid then
      local ws_pos = TrackFX_AddByName( track, 'waveShapingDstr', 0, 1 )--'Distortion\\waveShapingDstr'
      TrackFX_Show( track, ws_pos, 2 )
      TrackFX_SetParamNormalized( track, ws_pos, 0, 0 )
      local GUID = reaper.TrackFX_GetFXGUID( track, ws_pos )
      DATA:WriteData_Child(track, {FX_WS_GUID = GUID}) 
      DATA.upd = true
    end
  end
  --------------------------------------------------------------------- 
  function DATA:Auto_MIDIrouting() 
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end 
    if not (DATA.MIDIbus.valid == true) then return end
    local note_layer_tr = DATA.MIDIbus.tr_ptr
    local cntsends = GetTrackNumSends( note_layer_tr, 0 )
    local sends = {}
    for sendidx = 1, cntsends do
      local I_SRCCHAN = GetTrackSendInfo_Value( note_layer_tr, 0, sendidx-1, 'I_SRCCHAN' )
      local P_DESTTRACK = GetTrackSendInfo_Value( note_layer_tr, 0, sendidx-1, 'P_DESTTRACK' )
      local I_MIDIFLAGS = GetTrackSendInfo_Value( note_layer_tr, 0, sendidx-1, 'I_MIDIFLAGS' )
      local retval, P_DESTTRACK_GUID = reaper.GetSetMediaTrackInfo_String( P_DESTTRACK, 'GUID', '', false )
      if I_SRCCHAN == -1 then
        sends[P_DESTTRACK_GUID] = {
          I_MIDIFLAGS=I_MIDIFLAGS,
          sendidx=sendidx-1,
        }
      end
    end
      
    -- validate links
      for note in pairs(DATA.children) do
        -- make sure there is no midi send to device  
        if DATA.children[note].TYPE_DEVICE == true and DATA.children[note].TR_GUID and sends[DATA.children[note].TR_GUID] then RemoveTrackSend( note_layer_tr, 0, sends[DATA.children[note].TR_GUID].sendidx ) end
        
        -- check devicechilds/regular childs
        if DATA.children[note].layers then
          for layer in pairs(DATA.children[note].layers) do
            if DATA.children[note].layers[layer] and DATA.children[note].layers[layer].TR_GUID then
              local destGUID = DATA.children[note].layers[layer].TR_GUID
              
              if not sends[destGUID] or (sends[destGUID] and sends[destGUID].I_MIDIFLAGS ~= DATA.parent_track.ext.PARENT_MIDIFLAGS) then   
                local sendidx = CreateTrackSend( DATA.MIDIbus.tr_ptr, DATA.children[note].layers[layer].tr_ptr )
                if sendidx >=0 then
                  SetTrackSendInfo_Value( DATA.MIDIbus.tr_ptr, 0, sendidx, 'I_SRCCHAN',-1 )
                  SetTrackSendInfo_Value( DATA.MIDIbus.tr_ptr, 0, sendidx, 'I_MIDIFLAGS',DATA.parent_track.ext.PARENT_MIDIFLAGS )
                end
              end
              
            end 
          end
        end
        
      end   
  end
  --------------------------------------------------------------------- 
  function DATA:CollectData_ReadChoke(allow_add_choke) 
    -- validate choke
      if not DATA.MIDIbus.tr_ptr then return end
      local tr =  DATA.MIDIbus.tr_ptr
      local fxname = 'mpl_RS5K_manager_MIDIBUS_choke.jsfx' 
      local chokeJSFX_pos =  TrackFX_AddByName( tr, fxname, false, 0 )
      local CHOKE_GUID
      if chokeJSFX_pos == -1 then  
        if allow_add_choke == true then 
          DATA.MIDIbus.CHOKE_valid = true 
          chokeJSFX_pos =  TrackFX_AddByName( tr, fxname, false, -1000 ) 
          CHOKE_GUID = TrackFX_GetFXGUID( tr, chokeJSFX_pos ) 
          DATA:WriteData_Child(tr, {CHOKE_GUID=CHOKE_GUID}) 
          TrackFX_Show( tr, chokeJSFX_pos, 0|2 )
        end
        --for i = 1, 16 do TrackFX_SetParamNormalized( tr, chokeJSFX_pos, 33+i, i/1024 ) end -- ini source gmem IDs]]
       else
        CHOKE_GUID = TrackFX_GetFXGUID(tr, chokeJSFX_pos ) 
      end
      if chokeJSFX_pos == -1 then return end
    
    -- print to table
      DATA.MIDIbus.CHOKE_valid = true
      DATA.MIDIbus.CHOKE_pos = chokeJSFX_pos
      DATA.MIDIbus.CHOKE_GUID = CHOKE_GUID
     
    -- read group flags
      DATA.MIDIbus.CHOKE_flags = {} 
      for slider = 0, 63 do
        local flags = TrackFX_GetParamNormalized( tr, chokeJSFX_pos, slider )
        flags = math.floor(flags*65535)
        local noteID1 = slider*2
        local noteID2 = slider*2+1
        DATA.MIDIbus.CHOKE_flags[noteID1] = flags&0xFF
        DATA.MIDIbus.CHOKE_flags[noteID2] = (flags>>8)&0xFF 
      end
  end 
  -----------------------------------------------------------------------
  function DATA:Sampler_NewRandomKit() 
    if not (DATA.parent_track and DATA.parent_track.ext) then return end
    Undo_BeginBlock2(DATA.proj )
    
    for note in pairs(DATA.children) do 
      if DATA.children[note].TYPE_DEVICE~= true then 
        for layer =1,#DATA.children[note].layers do 
          local note_layer_t = DATA.children[note].layers[layer]
          if note_layer_t.SET_useDB&1==1 and  note_layer_t.SET_useDB&2~=2 then 
            DATA:Sampler_NextPrevSample(note_layer_t, 2)  
          end
        end
      end
    end
    
    
    Undo_EndBlock2( DATA.proj , 'RS5k manager - New kit', 0xFFFFFFFF )
    DATA.upd=true
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_Parent()  
    DATA.parent_track.ext_load = false
    -- get track pointer
      local parent_track 
      local retval, trGUIDext = reaper.GetProjExtState( DATA.proj, 'MPLRS5KMAN', 'STICKPARENTGUID' )
      if retval and trGUIDext ~= '' then 
        parent_track = VF_GetTrackByGUID(trGUIDext, DATA.proj)
        if not parent_track then 
          parent_track = GetSelectedTrack(DATA.proj,0) 
          SetProjExtState( DATA.proj, 'MPLRS5KMAN', 'STICKPARENTGUID','' )
        end -- load selected track if external is not found
        DATA.parent_track.ext_load = true
       else
        -- get selected track
        parent_track = GetSelectedTrack(DATA.proj,0)
      end
    
    
    -- catch parent by childen
      if parent_track then 
        local ret, parGUID = DATA:CollectData_IsChildOwnedByParent(parent_track)
        if parGUID and parGUID ~= '' then parent_track = VF_GetTrackByGUID(parGUID,DATA.proj) end 
      end
      
    if not parent_track then return end 
    
    -- get native data
      local retval, trGUID = GetSetMediaTrackInfo_String( parent_track, 'GUID', '', false ) 
      local retval, name = GetSetMediaTrackInfo_String( parent_track, 'P_NAME', '', false )
      local IP_TRACKNUMBER_0based = GetMediaTrackInfo_Value( parent_track, 'IP_TRACKNUMBER')-1 
      local I_FOLDERDEPTH = GetMediaTrackInfo_Value( parent_track, 'I_FOLDERDEPTH')
      local I_CUSTOMCOLOR = GetMediaTrackInfo_Value( parent_track, 'I_CUSTOMCOLOR')
      local cnt_tracks = CountTracks( DATA.proj )
      local IP_TRACKNUMBER_0basedlast = IP_TRACKNUMBER_0based
      
      if I_FOLDERDEPTH == 1 then
        local depth = 0
        for trid = IP_TRACKNUMBER_0based + 1, cnt_tracks do
          local tr = GetTrack(DATA.proj, trid-1)
          depth = depth + GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH')
          if depth <= 0 then 
            IP_TRACKNUMBER_0basedlast = trid-1
            break
          end
        end
      end 
       
    -- init ext data
      DATA.parent_track.ext = {
          PARENT_DRRACKSHIFT = 36,
          PARENT_MACROCNT = 16,
          PARENT_LASTACTIVENOTE = -1,
          PARENT_LASTACTIVENOTE_LAYER = 1,
          PARENT_LASTACTIVEMACRO = -1,
          PARENT_MIDIFLAGS = 0,
          PARENT_MACRO_GUID = '',
        }
      if EXT.UI_drracklayout == 2 then 
        DATA.parent_track.ext.PARENT_DRRACKSHIFT = 11
      end
    -- read values v3 (backw compatibility)
      local retval, chunk = GetSetMediaTrackInfo_String(parent_track, 'P_EXT:MPLRS5KMAN', '', false )
      if retval and chunk ~= '' then
        for line in chunk:gmatch('[^\r\n]+') do
          local key,value = line:match('([%p%a%d]+)%s([%p%a%d]+)')
          if key and value then 
            DATA.parent_track.ext[key] = tonumber(value) or value
          end
        end
      end
    
    -- v4
      
      local ret, GUIDINTERNAL = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_GUIDINTERNAL', '', false)         if ret then DATA.parent_track.ext.PARENT_GUID_INTERNAL = GUIDINTERNAL end
      local ret, DRRACKSHIFT = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_DRRACKSHIFT', 0, false)            if ret then DATA.parent_track.ext.PARENT_DRRACKSHIFT = tonumber(DRRACKSHIFT) end
      local ret, MACROCNT = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_MACROCNT', 0, false)                  if ret then DATA.parent_track.ext.PARENT_MACROCNT = tonumber(MACROCNT) end
      local ret, LASTACTIVENOTE = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_LASTACTIVENOTE', 0, false)      if ret then DATA.parent_track.ext.PARENT_LASTACTIVENOTE = tonumber(LASTACTIVENOTE) end
      local ret, LASTACTIVENOTE_LAYER = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_LASTACTIVENOTE_LAYER', 0, false)  if ret then DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER = tonumber(LASTACTIVENOTE_LAYER ) end
      local ret, LASTACTIVEMACRO = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_LASTACTIVEMACRO', 0, false)    if ret then DATA.parent_track.ext.PARENT_LASTACTIVEMACRO = tonumber(LASTACTIVEMACRO ) end
      local ret, MIDIFLAGS = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_MIDIFLAGS', 0, false)                if ret then DATA.parent_track.ext.PARENT_MIDIFLAGS = tonumber(MIDIFLAGS) end
      local ret, MACRO_GUID = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_MACRO_GUID', 0, false)              if ret then DATA.parent_track.ext.PARENT_MACRO_GUID = MACRO_GUID end
      local ret, MACROEXT_B64 = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_MACROEXT_B64', 0, false)
       if ret then 
        DATA.parent_track.ext.PARENT_MACROEXT_B64 = MACROEXT_B64      
        DATA.parent_track.ext.PARENT_MACROEXT = table.loadstring(VF_decBase64(MACROEXT_B64)) or {}
      end  
      
      
    DATA.parent_track.valid = true
    DATA.parent_track.ptr = parent_track
    DATA.parent_track.trGUID = trGUID
    DATA.parent_track.name = name
    DATA.parent_track.IP_TRACKNUMBER_0based = IP_TRACKNUMBER_0based
    DATA.parent_track.IP_TRACKNUMBER_0basedlast = IP_TRACKNUMBER_0basedlast
    DATA.parent_track.I_FOLDERDEPTH = I_FOLDERDEPTH
    DATA.parent_track.I_CUSTOMCOLOR = I_CUSTOMCOLOR
    
    
  end
  ---------------------------------------------------------------------
  function DATA:CollectData_IsChildOwnedByParent(track)  
    local ret, parGUID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_PARENTGUID', '', false) 
    if DATA.parent_track.trGUID and parGUID == DATA.parent_track.trGUID then ret = true else ret = false end 
    
    return ret, parGUID
  end
  --------------------------------------------------------------------- 
  function DATA:CollectData_Macro()
    DATA.parent_track.macro = {}
    if DATA.parent_track.valid ~= true then return end
    local MACRO_GUID = DATA.parent_track.ext.PARENT_MACRO_GUID   
    if not (MACRO_GUID and MACRO_GUID~='') then 
      --DATA:Macro_InitChildrenMacro()
      return 
    end

    -- validate macro jsfx
      local ret,tr, MACRO_pos = VF_GetFXByGUID(MACRO_GUID, DATA.parent_track.ptr, DATA.proj)
      if not (ret and MACRO_pos and MACRO_pos ~= -1) then return end
      DATA.parent_track.macro.pos = MACRO_pos 
      DATA.parent_track.macro.fxGUID = MACRO_GUID
      DATA.parent_track.macro.valid = true

    -- get sliders
      DATA.parent_track.macro.sliders = {}
      for i = 1, 16 do
        local param_val = TrackFX_GetParamNormalized( DATA.parent_track.ptr, MACRO_pos, i )
        DATA.parent_track.macro.sliders[i] = {
          val = param_val,
        }
      end

    -- get links 
      for note in pairs(DATA.children) do
        if DATA.children[note] and DATA.children[note].layers then 
          for layer in pairs(DATA.children[note].layers) do
            has_links = DATA:CollectData_Macro_sub(DATA.children[note].layers[layer])
          end
        end
      end
      
    -- print to children table
      for slider in pairs(DATA.parent_track.macro.sliders) do
        if DATA.parent_track.macro.sliders[slider].links then 
          for link in pairs(DATA.parent_track.macro.sliders[slider].links) do
            local t = DATA.parent_track.macro.sliders[slider].links[link].note_layer_t
            for key in pairs(t) do
              if key:match('instrument_') and key:match('ID') and not key:match('MACRO')  then 
                local param = t[key]
                local param_dest = DATA.parent_track.macro.sliders[slider].links[link].param_dest
                if param_dest == param  then t[key..'_MACRO'] = slider end
              end
            end
          end
        end
      end
      
      
  end
  -------------------------------------------------------------------  
  function DATA:CollectData_Macro_sub(note_layer_t)
    if not note_layer_t then return end
    if not note_layer_t.tr_ptr then return end
    for fxid = 1,  TrackFX_GetCount( note_layer_t.tr_ptr ) do
      if fxid ~= note_layer_t.MACRO_pos then
        for paramnumber = 0, TrackFX_GetNumParams( note_layer_t.tr_ptr, fxid-1 )-1 do
          local isactive = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.active')})[2] isactive = tonumber(isactive) 
          if isactive and isactive ==1 then
            local src_fx = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.effect')})[2] src_fx = tonumber(src_fx) 
            local src_param = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.param')})[2] src_param = tonumber(src_param) 
            if src_fx and src_fx == note_layer_t.MACRO_pos then
              local retval, pname = reaper.TrackFX_GetParamName( note_layer_t.tr_ptr, fxid-1,paramnumber)
              local macroID = src_param  
              if DATA.parent_track.macro.sliders[macroID] then 
                if not DATA.parent_track.macro.sliders[macroID].links then DATA.parent_track.macro.sliders[macroID].links = {} end
                local linkID = #DATA.parent_track.macro.sliders[macroID].links+1
                local baseline = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'mod.baseline')})[2] baseline = tonumber(baseline) 
                local plink_offset = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.offset')})[2] plink_offset = tonumber(plink_offset) 
                local plink_scale = ({TrackFX_GetNamedConfigParm(note_layer_t.tr_ptr, fxid-1, 'param.'..paramnumber..'plink.scale')})[2] plink_scale = tonumber(plink_scale) 
                local plink_offset_format = math.floor(plink_offset*100)..'%'
                local plink_scale_format = math.floor(plink_scale*100)..'%'
                
                
                local UI_min = baseline
                local UI_max = baseline + plink_scale
                
                
                DATA.parent_track.macro.sliders[macroID].links[linkID] = {
                    linkID=linkID,
                    param_name = pname,
                    plink_offset = plink_offset,
                    plink_offset_format = plink_offset_format,
                    plink_scale = plink_scale,
                    plink_scale_format = plink_scale_format,
                    note_layer_t = note_layer_t,
                    fx_dest = fxid-1,
                    param_dest = paramnumber,
                    UI_min = UI_min,
                    UI_max = UI_max,
                    baseline=baseline,
                  }
                DATA.parent_track.macro.sliders[macroID].has_links = true 
              end 
            end
          end
        end
      end
    end 
    return has_links
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_FormatVolume(D_VOL)  
    return ( math.floor(WDL_VAL2DB(D_VOL)*10)/10) ..'dB'
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_Children()   
    if DATA.parent_track.valid ~= true then return end 
    for i = DATA.parent_track.IP_TRACKNUMBER_0based+1, DATA.parent_track.IP_TRACKNUMBER_0basedlast do -- loop through track inside selected folder
    
      -- validate parent
        local track = GetTrack(DATA.proj, i) 
        if DATA:CollectData_IsChildOwnedByParent(track) ~= true  then goto nexttrack end
        
      -- handle midi
        local retMIDI = DATA:CollectData_Children_MIDIbus(track) 
        if retMIDI == true then goto nexttrack end         
 
        
      -- get base child data
        local retval, trGUID =             GetSetMediaTrackInfo_String( track, 'GUID', '', false ) 
        local retval, P_NAME =             GetSetMediaTrackInfo_String( track, 'P_NAME', '', false ) 
        local IP_TRACKNUMBER_0based =             GetMediaTrackInfo_Value( track, 'IP_TRACKNUMBER')
        local D_VOL =                      GetMediaTrackInfo_Value( track, 'D_VOL' )
        local D_VOL_format =               DATA:CollectData_FormatVolume(D_VOL)  
        local D_PAN =                      GetMediaTrackInfo_Value( track, 'D_PAN' )
        local D_PAN_format =               VF_Format_Pan(D_PAN)
        local B_MUTE =                     GetMediaTrackInfo_Value( track, 'B_MUTE' )
        local I_SOLO =                     GetMediaTrackInfo_Value( track, 'I_SOLO' )
        local I_CUSTOMCOLOR =              GetMediaTrackInfo_Value( track, 'I_CUSTOMCOLOR' )
        local I_FOLDERDEPTH =              GetMediaTrackInfo_Value( track, 'I_FOLDERDEPTH' ) 
        local I_PLAY_OFFSET_FLAG =         GetMediaTrackInfo_Value( track, 'I_PLAY_OFFSET_FLAG' ) 
        local D_PLAY_OFFSET =              GetMediaTrackInfo_Value( track, 'D_PLAY_OFFSET' ) 
        local PLAY_OFFSET = 0
        if I_PLAY_OFFSET_FLAG&1==0 then
          if I_PLAY_OFFSET_FLAG&2==2 then PLAY_OFFSET = D_PLAY_OFFSET / DATA.SR else PLAY_OFFSET = D_PLAY_OFFSET end
        end
        local PLAY_OFFSET_format =        math.floor(PLAY_OFFSET*1000)..'ms'
  
      -- validate attached note
        local ret, note =                   GetSetMediaTrackInfo_String         ( track, 'P_EXT:MPLRS5KMAN_NOTE',0, false) 
        note = tonumber(note) 
        if not note then goto nexttrack end 
        
      -- init note/layer
        if not DATA.children[note] then DATA.children[note] = {
          layers = {}, 
          P_NAME = P_NAME,
          I_CUSTOMCOLOR = I_CUSTOMCOLOR,
          B_MUTE = B_MUTE,
          I_SOLO = I_SOLO,
          tr_ptr = track,
          noteID=note,
          IP_TRACKNUMBER_0based=IP_TRACKNUMBER_0based,
        } end 
        
                
      -- define type (regular_child / device / device_child)
        local ret, TYPE_REGCHILD =          GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', 0, false) TYPE_REGCHILD = (tonumber(TYPE_REGCHILD) or 0)==1
        local ret, TYPE_DEVICECHILD =       GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD', 0, false) TYPE_DEVICECHILD = (tonumber(TYPE_DEVICECHILD) or 0)==1
        local ret, TYPE_DEVICE =            GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TYPE_DEVICE', 0, false) TYPE_DEVICE =  (tonumber(TYPE_DEVICE) or 0)==1 
        local ret, TYPE_DEVICE_AUTORANGE =            GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TYPE_DEVICE_AUTORANGE', 0, false) TYPE_DEVICE_AUTORANGE =  (tonumber(TYPE_DEVICE_AUTORANGE) or EXT.CONF_onadd_autosetrange)==1 
        
       
        
        local ret, TYPE_DEVICECHILD_PARENTDEVICEGUID = GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD_PARENTDEVICEGUID', 0, false)
        local TYPE_DEVICECHILD_valid 

      -- various
        local ret, MPLRS5KMAN_TSADD = GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_TSADD', 0, false) MPLRS5KMAN_TSADD = tonumber(MPLRS5KMAN_TSADD) or 0
                  
                  
      -- refresh / patch on missing or non-valid devices
        if TYPE_DEVICE ~= true then 
        
          TYPE_DEVICECHILD_valid = false 
          if TYPE_DEVICECHILD_PARENTDEVICEGUID then 
            local devicetr = VF_GetTrackByGUID(TYPE_DEVICECHILD_PARENTDEVICEGUID, DATA.proj)
            if devicetr then
              TYPE_DEVICECHILD_valid = true
              --[[local ret, note_device =        GetSetMediaTrackInfo_String   ( devicetr, 'P_EXT:MPLRS5KMAN_NOTE',0, false) note_device = tonumber(note_device)
              if note_device then 
                note = note_device 
                GetSetMediaTrackInfo_String ( track, 'P_EXT:MPLRS5KMAN_NOTE',note, true) -- refresh device child note , make sure track is not inside different device
              end]]
             else
              TYPE_REGCHILD = true -- patch for case if TYPE_DEVICECHILD_PARENTDEVICEGUID is found but parent device is not valid
            end
           else
            TYPE_REGCHILD = true -- patch for case if TYPE_DEVICECHILD_PARENTDEVICEGUID not found but TYPE_REGCHILD not set 
          end 
          
        end
        
      -- add layer to note if device child
        if TYPE_DEVICECHILD == true or TYPE_REGCHILD == true then  
          local midifilt_pos = TrackFX_AddByName( track, 'midi_note_filter', false, 0) 
          if midifilt_pos == - 1 then midifilt_pos = nil end
            local layer = #DATA.children[note].layers +1 
            DATA.children[note].layers[layer] = { 
                                              
                                              noteID = note,
                                              layerID = layer,
                                              
                                              tr_ptr = track,
                                              TR_GUID =  trGUID,
                                              
                                              TYPE_REGCHILD=TYPE_REGCHILD, 
                                              TYPE_DEVICECHILD=TYPE_DEVICECHILD,
                                              TYPE_DEVICECHILD_PARENTDEVICEGUID=TYPE_DEVICECHILD_PARENTDEVICEGUID,
                                              TYPE_DEVICECHILD_valid = TYPE_DEVICECHILD_valid,
                                              MPLRS5KMAN_TSADD=MPLRS5KMAN_TSADD,
                                              
                                              D_VOL = D_VOL,
                                              D_VOL_format = D_VOL_format,
                                              D_PAN = D_PAN,
                                              D_PAN_format = D_PAN_format,
                                              B_MUTE = B_MUTE,
                                              I_SOLO = I_SOLO,
                                              I_CUSTOMCOLOR = I_CUSTOMCOLOR,
                                              I_FOLDERDEPTH = I_FOLDERDEPTH,
                                              P_NAME=P_NAME,
                                              IP_TRACKNUMBER_0based=IP_TRACKNUMBER_0based,
                                              PLAY_OFFSET = PLAY_OFFSET,
                                              PLAY_OFFSET_format = PLAY_OFFSET_format,
                                              
                                              midifilt_pos=midifilt_pos,
                                              }
          DATA:CollectData_Children_ExtState          (DATA.children[note].layers[layer])  
          DATA:CollectData_Children_InstrumentParams  (DATA.children[note].layers[layer]) 
          DATA:CollectData_Children_FXParams          (DATA.children[note].layers[layer]) 
          if DATA.children[note].layers[layer].SET_useDB&1==1 then DATA.children[note].has_setDB = true end
          if DATA.children[note].layers[layer].SET_useDB&2==2 then DATA.children[note].has_setDBlocked = true end
          
        end
        
      -- add device data
        if TYPE_DEVICE then 
          DATA.children[note].TYPE_DEVICE = TYPE_DEVICE  
          DATA.children[note].TYPE_DEVICE_AUTORANGE=TYPE_DEVICE_AUTORANGE
          DATA.children[note].tr_ptr = track
          DATA.children[note].TR_GUID = trGUID
          DATA.children[note].MACRO_GUID = MACRO_GUID
          DATA.children[note].noteID = note
          DATA.children[note].MACRO_pos =MACRO_pos
          
          DATA.children[note].D_VOL = D_VOL
          DATA.children[note].D_VOL_format = D_VOL_format
          DATA.children[note].D_PAN = D_PAN
          DATA.children[note].D_PAN_format = D_PAN_format
          DATA.children[note].B_MUTE = B_MUTE
          DATA.children[note].I_SOLO = I_SOLO
          DATA.children[note].I_CUSTOMCOLOR = I_CUSTOMCOLOR
          DATA.children[note].I_FOLDERDEPTH = I_FOLDERDEPTH
          DATA.children[note].P_NAME = P_NAME
        end
      
      
      ::nexttrack::
    end
    
    -- make sure layer exist otherwise set to 1
    if DATA.parent_track.ext.PARENT_LASTACTIVENOTE and DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER and DATA.children[DATA.parent_track.ext.PARENT_LASTACTIVENOTE] and 
      not ( DATA.children[DATA.parent_track.ext.PARENT_LASTACTIVENOTE].layers and DATA.children[DATA.parent_track.ext.PARENT_LASTACTIVENOTE].layers[DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER] ) 
     then 
      DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER = 1 
    end
    
  end  
  
  
  ---------------------------------------------------------------------   
  function DATA:CollectData_Children_InstrumentParams_RS5k(note_layer_t, track,instrument_pos)
    
    if not note_layer_t.ISRS5K then return end
    
    note_layer_t.instrument_enabled = TrackFX_GetEnabled( track, instrument_pos )
    note_layer_t.instrument_volID = 0
    note_layer_t.instrument_vol = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_volID ) 
    note_layer_t.instrument_vol_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_volID )})[2]..'dB'
    note_layer_t.instrument_panID = 1
    note_layer_t.instrument_pan = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_panID ) 
    note_layer_t.instrument_pan_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_panID )})[2]
    note_layer_t.instrument_attackID = 9
    note_layer_t.instrument_attack = TrackFX_GetParamNormalized( track, instrument_pos,note_layer_t.instrument_attackID ) 
    note_layer_t.instrument_attack_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_attackID )})[2]..'ms'
    note_layer_t.instrument_decayID = 24
    note_layer_t.instrument_decay = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_decayID ) 
    note_layer_t.instrument_decay_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_decayID )})[2]..'ms'
    note_layer_t.instrument_sustainID = 25
    note_layer_t.instrument_sustain = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_sustainID ) 
    note_layer_t.instrument_sustain_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_sustainID )})[2]..'dB'
    note_layer_t.instrument_releaseID = 10
    note_layer_t.instrument_release = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_releaseID ) 
    note_layer_t.instrument_release_format=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_releaseID )})[2]..'ms'
    note_layer_t.instrument_loopID = 12
    note_layer_t.instrument_loop = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_loopID )
    note_layer_t.instrument_samplestoffsID = 13
    note_layer_t.instrument_samplestoffs = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_samplestoffsID ) 
    note_layer_t.instrument_samplestoffs_format = (math.floor(note_layer_t.instrument_samplestoffs*1000)/10)..'%'
    note_layer_t.instrument_sampleendoffsID = 14
    note_layer_t.instrument_sampleendoffs = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_sampleendoffsID ) 
    note_layer_t.instrument_sampleendoffs_format = (math.floor(note_layer_t.instrument_sampleendoffs*1000)/10)..'%'
    note_layer_t.instrument_loopoffsID = 23
    note_layer_t.instrument_loopoffs = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_loopoffsID ) 
    note_layer_t.instrument_loopoffs_format = math.floor(note_layer_t.instrument_loopoffs *30*10000)/10
    
    note_layer_t.instrument_loopoffs_max = 1
    note_layer_t.instrument_attack_max = 1 
    note_layer_t.instrument_decay_max = 1 
    note_layer_t.instrument_release_max = 1 
    if note_layer_t.SAMPLELEN and note_layer_t.SAMPLELEN ~= 0 then 
      local st_s = note_layer_t.instrument_samplestoffs * note_layer_t.SAMPLELEN
      local end_s = note_layer_t.instrument_sampleendoffs * note_layer_t.SAMPLELEN
      note_layer_t.instrument_loopoffs_max = (end_s - st_s) / 30 
      note_layer_t.instrument_loopoffs_norm =  VF_lim(note_layer_t.instrument_loopoffs / note_layer_t.instrument_loopoffs_max )
      note_layer_t.instrument_attack_max = math.min(1,note_layer_t.SAMPLELEN/2) 
      note_layer_t.instrument_attack_norm = VF_lim(note_layer_t.instrument_attack / note_layer_t.instrument_attack_max   ) 
      note_layer_t.instrument_decay_max = math.min(1,note_layer_t.SAMPLELEN/15) 
      note_layer_t.instrument_decay_norm =  VF_lim(note_layer_t.instrument_decay / note_layer_t.instrument_decay_max  ) 
      note_layer_t.instrument_release_max = math.min(1,note_layer_t.SAMPLELEN/2) 
      note_layer_t.instrument_release_norm =  VF_lim(note_layer_t.instrument_release / note_layer_t.instrument_release_max )        
    end
    
    note_layer_t.instrument_maxvoicesID = 8
    note_layer_t.instrument_maxvoices = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_maxvoicesID ) 
    note_layer_t.instrument_maxvoices_format = math.floor(note_layer_t.instrument_maxvoices*64)
    note_layer_t.instrument_tuneID = 15
    note_layer_t.instrument_tune = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_tuneID ) 
    note_layer_t.instrument_tune_format = ({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t.instrument_tuneID )})[2]..'st'
    note_layer_t.instrument_filename = ({TrackFX_GetNamedConfigParm(  track, instrument_pos, 'FILE0') })[2]
    note_layer_t.instrument_noteoffID = 11
    note_layer_t.instrument_noteoff = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t.instrument_noteoffID ) 
    note_layer_t.instrument_noteoff_format = math.floor(note_layer_t.instrument_noteoff) 
    local filename_short = VF_GetShortSmplName(note_layer_t.instrument_filename) if filename_short and filename_short:match('(.*)%.[%a]+') then filename_short = filename_short:match('(.*)%.[%a]+') end 
    note_layer_t.instrument_filename_short = filename_short 
  end
  ---------------------------------------------------------------------   
  function DATA:CollectData_Children_InstrumentParams_3rdparty(note_layer_t, track,instrument_pos)
    if note_layer_t.ISRS5K==true then return end
    
    note_layer_t.instrument_enabled = TrackFX_GetEnabled( track, instrument_pos )
    local retval, fx_name = TrackFX_GetNamedConfigParm( track, instrument_pos, 'fx_name' )
    note_layer_t.instrument_fx_name = fx_name
    
    if not (DATA.plugin_mapping and DATA.plugin_mapping[fx_name] )then return end
    
    local supported_params = {
        'instrument_volID',
        'instrument_attackID',
        'instrument_decayID',
        'instrument_sustainID',
        'instrument_releaseID',
      }
    
    for pid=1, #supported_params do
      local param = supported_params[pid]
      local paramclear = param:match('(.*)ID')
      if DATA.plugin_mapping[fx_name][param] and paramclear then 
        note_layer_t[param] = DATA.plugin_mapping[fx_name][param]
        note_layer_t[paramclear] = TrackFX_GetParamNormalized( track, instrument_pos, note_layer_t[param] ) 
        note_layer_t[paramclear..'_format']=({TrackFX_GetFormattedParamValue( track, instrument_pos, note_layer_t[param] )})[2]
      end
    end
  end
  ---------------------------------------------------------------------   
  function DATA:CollectData_Children_InstrumentParams(note_layer_t, is_minor)
    local track = note_layer_t.tr_ptr
    local instrument_pos
    
    -- validate tr
    if is_minor ~= true then 
      local ret, tr, instrument_pos0 = VF_GetFXByGUID(note_layer_t.INSTR_FXGUID, track, DATA.proj)
      if not ret then 
        -- try to catch by instance name
        local instrument_pos0_1 = TrackFX_AddByName( track, 'rs5k', false, 0 )
        local instrument_pos0_2 = TrackFX_AddByName( track, 'reasamplo', false, 0 )
        if instrument_pos0_1 ~= -1 then 
          instrument_pos0 = instrument_pos0_1 
         elseif instrument_pos0_2 ~= -1 then 
          instrument_pos0 = instrument_pos0_2 
         else
          return 
        end
        local instrumentGUID = TrackFX_GetFXGUID( track, instrument_pos0 )
        DATA:WriteData_Child(track, {
          SET_instrFXGUID = instrumentGUID,
        }) 
      end 
      note_layer_t.instrument_pos=instrument_pos0
      instrument_pos=instrument_pos0
     else
      instrument_pos = note_layer_t.instrument_pos
    end 
    
    DATA:CollectData_Children_InstrumentParams_RS5k(note_layer_t, track, instrument_pos)
    DATA:CollectData_Children_InstrumentParams_3rdparty(note_layer_t, track, instrument_pos)
    
  end 
  ---------------------------------------------------------------------  
  function DATA:CollectData_Children_FXParams(note_layer_t)  
    if not note_layer_t then return end
    -- ReaEQ
    note_layer_t.fx_reaeq_isvalid = false
    if note_layer_t.FX_REAEQ_GUID then  
      local ret,tr, reaeqpos = VF_GetFXByGUID(note_layer_t.FX_REAEQ_GUID, note_layer_t.tr_ptr)
      if ret and reaeqpos and reaeqpos ~= -1 then    
        local track = note_layer_t.tr_ptr
        note_layer_t.fx_reaeq_isvalid = true
        note_layer_t.fx_reaeq_pos = reaeqpos
        note_layer_t.fx_reaeq_cut = TrackFX_GetParamNormalized( track, reaeqpos, 0 )
        note_layer_t.fx_reaeq_gain = TrackFX_GetParamNormalized( track, reaeqpos, 1)
        note_layer_t.fx_reaeq_bw = TrackFX_GetParamNormalized( track, reaeqpos, 2 )
        local fr= math.floor(({TrackFX_GetFormattedParamValue( track, reaeqpos, 0 )})[2])
        if fr>10000 then fr = (math.floor(fr/100)/10)..'k' end
        note_layer_t.fx_reaeq_cut_format = fr..'Hz'
        
        note_layer_t.fx_reaeq_gain_format = ({TrackFX_GetFormattedParamValue( track, reaeqpos, 1 )})[2]..'dB'
        note_layer_t.fx_reaeq_bw_format = ({TrackFX_GetFormattedParamValue( track, reaeqpos, 2 )})[2]
        note_layer_t.fx_reaeq_bandenabled = ({TrackFX_GetNamedConfigParm( track, reaeqpos, 'BANDENABLED0' )})[2]=='1'
        note_layer_t.fx_reaeq_bandtype = tonumber(({TrackFX_GetNamedConfigParm( track, reaeqpos, 'BANDTYPE0' )})[2])
        local reaeq_bandtype_format = ''
        if DATA.bandtypemap and DATA.bandtypemap[note_layer_t.fx_reaeq_bandtype] then reaeq_bandtype_format = DATA.bandtypemap[note_layer_t.fx_reaeq_bandtype] end
        note_layer_t.fx_reaeq_bandtype_format = reaeq_bandtype_format  
      end
    end
    
    -- WS
    note_layer_t.fx_ws_isvalid = false
    if note_layer_t.FX_WS_GUID then
      local ret,tr, wspos = VF_GetFXByGUID(note_layer_t.FX_WS_GUID, note_layer_t.tr_ptr)
      if ret and wspos and wspos ~= -1 then 
        local track = note_layer_t.tr_ptr
        note_layer_t.fx_ws_isvalid = true
        note_layer_t.fx_ws_pos = wspos
        note_layer_t.fx_ws_drive = TrackFX_GetParamNormalized( track, wspos, 0 )
        note_layer_t.fx_ws_drive_format = (math.floor(1000*note_layer_t.fx_ws_drive)/10)..'%'
      end
    end
  end 
  --------------------------------------------------------------------- 
  function DATA:CollectData_Children_ExtState(t) 
      local track = t.tr_ptr
    -- main plug data
      local ret, INSTR_FXGUID = GetSetMediaTrackInfo_String  ( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_FXGUID', 0, false)   if INSTR_FXGUID == '' then INSTR_FXGUID = nil end 
      local ret, ISRS5K = GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_CHILD_ISRS5K', 0, false) ISRS5K = (tonumber(ISRS5K) or 0)==1  
      t.INSTR_FXGUID=     INSTR_FXGUID
      t.ISRS5K=           ISRS5K
    
    -- rs5k specific 
      local ret, SAMPLELEN = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_SAMPLELEN', '', false)  SAMPLELEN = tonumber(SAMPLELEN) or 0 
      t.SAMPLELEN = SAMPLELEN
      local ret, SAMPLEBPM = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_SAMPLEBPM', '', false)  SAMPLEBPM = tonumber(SAMPLEBPM) or 0 
      t.SAMPLEBPM = SAMPLEBPM   
      local ret, LUFSNORM = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_LUFSNORM', '', false)
      t.LUFSNORM = LUFSNORM   
      
      
      --[[local ret, PEAKS = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_PEAKS', '', false)
      if ret then 
        t.peaks_t = {} 
        local i = 1 
        for val in PEAKS:gmatch('[^%|]+') do 
          if tonumber(val) then t.peaks_t[i] = tonumber(val) i = i + 1 end
        end
        t.peaks_arr = new_array(t.peaks_t)
      end]]
      
    --[[  3rd party ADSR + tune map
      local ret, INSTR_PARAM_CACHE = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_CACHE', '', false) INSTR_PARAM_CACHE = tonumber(INSTR_PARAM_CACHE) or nil
      local ret, INSTR_PARAM_VOL = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_VOL', '', false) INSTR_PARAM_VOL = tonumber(INSTR_PARAM_VOL) or nil
      local ret, INSTR_PARAM_TUNE = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_TUNE', '', false) INSTR_PARAM_TUNE = tonumber(INSTR_PARAM_TUNE) or nil
      local ret, INSTR_PARAM_ATT = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_ATT', '', false) INSTR_PARAM_ATT = tonumber(INSTR_PARAM_ATT) or nil
      local ret, INSTR_PARAM_DEC = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_DEC', '', false) INSTR_PARAM_DEC = tonumber(INSTR_PARAM_DEC) or nil
      local ret, INSTR_PARAM_SUS = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_SUS', '', false) INSTR_PARAM_SUS = tonumber(INSTR_PARAM_SUS) or nil
      local ret, INSTR_PARAM_REL = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_REL', '', false) INSTR_PARAM_REL = tonumber(INSTR_PARAM_REL) or nil 
      t.INSTR_PARAM_CACHE=INSTR_PARAM_CACHE
      t.INSTR_PARAM_VOL=INSTR_PARAM_VOL
      t.INSTR_PARAM_TUNE=INSTR_PARAM_TUNE
      t.INSTR_PARAM_ATT=INSTR_PARAM_ATT
      t.INSTR_PARAM_DEC=INSTR_PARAM_DEC
      t.INSTR_PARAM_SUS=INSTR_PARAM_SUS
      t.INSTR_PARAM_REL=INSTR_PARAM_REL]]
      
    -- midi filter
      local ret, MIDIFILTGUID = GetSetMediaTrackInfo_String  ( track, 'P_EXT:MPLRS5KMAN_CHILD_MIDIFILTGUID', 0, false)  if MIDIFILTGUID == '' then MIDIFILTGUID = nil end
      t.MIDIFILTGUID=MIDIFILTGUID
    
    -- reaeq// validate
      local ret, FX_REAEQ_GUID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_FX_REAEQ_GUID', '', false) if FX_REAEQ_GUID == '' then FX_REAEQ_GUID = nil end 
      if FX_REAEQ_GUID then 
        local ret, tr, eqpos = VF_GetFXByGUID(FX_REAEQ_GUID:gsub('[%{%}]',''),track, DATA.proj) 
        if not eqpos then FX_REAEQ_GUID=nil end
      end
      t.FX_REAEQ_GUID = FX_REAEQ_GUID
    
    -- waveshaper // validate
      local ret, FX_WS_GUID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_FX_WS_GUID', '', false) if FX_WS_GUID == '' then FX_WS_GUID = nil end 
      if FX_WS_GUID then 
        local ret, tr, wspos = VF_GetFXByGUID(FX_WS_GUID:gsub('[%{%}]',''),track, DATA.proj) 
        if not wspos then FX_WS_GUID=nil end
      end
      t.FX_WS_GUID=FX_WS_GUID
    
    -- macro
      local _, MACRO_GUID = GetSetMediaTrackInfo_String ( track, 'P_EXT:MPLRS5KMAN_MACRO_GUID', 0, false) if MACRO_GUID == '' then MACRO_GUID = nil end 
      local  ret, tr, MACRO_pos
      if MACRO_GUID then ret, tr, MACRO_pos = VF_GetFXByGUID(MACRO_GUID:gsub('[%{%}]',''),track, DATA.proj) end
      if not MACRO_pos then MACRO_GUID = nil  end 
      t.MACRO_GUID = MACRO_GUID 
      t.MACRO_pos = MACRO_pos
    
    -- list samples in path or database
      local ret, SPLLISTDB = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB', '', false) SPLLISTDB = tonumber(SPLLISTDB) or 0
      t.SET_useDB=SPLLISTDB
      local ret, SET_useDB_lastID = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB_ID', '', false) SET_useDB_lastID = tonumber(SET_useDB_lastID) or 0
      t.SET_useDB_lastID = SET_useDB_lastID
      local ret, SPLLISTDB_name = GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB_NAME', '', false) if SPLLISTDB_name == '' then SPLLISTDB_name = nil end 
      t.SET_useDB_name=SPLLISTDB_name
      
      
  end
  -------------------------------------------------------------------------------- 
  function DATA:CollectData_Children_MIDIbus(track)
    local ret, isMIDIbus = GetSetMediaTrackInfo_String ( track, 'P_EXT:MPLRS5KMAN_MIDIBUS', 0, false)    
    isMIDIbus = (tonumber(isMIDIbus) or 0)==1   
    if not (ret and isMIDIbus == true) then return end
    local IP_TRACKNUMBER_0based = GetMediaTrackInfo_Value( track, 'IP_TRACKNUMBER')-1
    local I_FOLDERDEPTH = GetMediaTrackInfo_Value( track, 'I_FOLDERDEPTH')
    
    DATA.MIDIbus = {  tr_ptr = track, 
                      IP_TRACKNUMBER_0based = IP_TRACKNUMBER_0based,
                      valid = true,
                      I_FOLDERDEPTH = I_FOLDERDEPTH
                  } 
    return true
  end
  -----------------------------------------------------------------------------  
  function DATA:Sampler_StuffNoteOn(note, vel, is_off) 
   if not note then return end
   
   
    if not is_off then 
      StuffMIDIMessage( 0, 0x90, note, vel or EXT.CONF_default_velocity ) 
     else
      StuffMIDIMessage( 0, 0x80, note, 0 ) 
    end
  end
  ---------------------------------------------------------------------  
  function DATA:WriteData_Parent() 
    if not (DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.valid == true) then return end
    GetSetMediaTrackInfo_String( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_VERSION', DATA.version, true)
    
    -- v4.14+
    if DATA.parent_track.trGUID  then  
      local ret, GUIDINTERNAL = GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_GUIDINTERNAL', '', false) 
      if not ret then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_GUIDINTERNAL', DATA.parent_track.trGUID, true) end
    end
    
    -- v4 separate stuff from chunk
    if DATA.parent_track.ext then 
      
      if DATA.parent_track.ext.PARENT_DRRACKSHIFT  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_DRRACKSHIFT', DATA.parent_track.ext.PARENT_DRRACKSHIFT or '', true) end
      if DATA.parent_track.ext.PARENT_LASTACTIVENOTE  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_LASTACTIVENOTE', DATA.parent_track.ext.PARENT_LASTACTIVENOTE or '', true) end
      if DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_LASTACTIVENOTE_LAYER', DATA.parent_track.ext.PARENT_LASTACTIVENOTE_LAYER or '', true) end
      if DATA.parent_track.ext.PARENT_MACROCNT  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_MACROCNT', DATA.parent_track.ext.PARENT_MACROCNT or '', true) end
      if DATA.parent_track.ext.PARENT_LASTACTIVEMACRO  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_LASTACTIVEMACRO', DATA.parent_track.ext.PARENT_LASTACTIVEMACRO or '', true) end
      if DATA.parent_track.ext.PARENT_MIDIFLAGS  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_MIDIFLAGS', DATA.parent_track.ext.PARENT_MIDIFLAGS or '', true) end
      if DATA.parent_track.ext.PARENT_MACRO_GUID  then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_MACRO_GUID', DATA.parent_track.ext.PARENT_MACRO_GUID or '', true) end
      if DATA.parent_track.ext.PARENT_MACROEXT    then
        local outstr = table.savestring(DATA.parent_track.ext.PARENT_MACROEXT)
        GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_MACROEXT_B64', VF_encBase64(outstr), true)
      end
      
    end
    
    -- clear string
    GetSetMediaTrackInfo_String( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN', '', true) 
  end
  --------------------------------------------------------------------- 
  function DATA:WriteData_UpdateChoke() 
    if not (DATA.MIDIbus.CHOKE_valid and DATA.MIDIbus.CHOKE_flags ) then return end 
    local tr = DATA.MIDIbus.tr_ptr 
    local fx = DATA.MIDIbus.CHOKE_pos
    -- write group flags
    Undo_BeginBlock2(DATA.proj )
    for slider = 0, 63 do
      local noteID1 = slider*2
      local noteID2 = slider*2+1
      local flags1 = DATA.MIDIbus.CHOKE_flags[noteID1]
      local flags2 = DATA.MIDIbus.CHOKE_flags[noteID2]
      local out_mixed = (flags2<<8) + flags1
      TrackFX_SetParamNormalized( tr, fx, slider, out_mixed/65535 )
    end 
    
    -- auto set obey note off
    for note = 0, 127 do
      if DATA.children[note] and DATA.children[note].layers then
        for layer = 1, #DATA.children[note].layers do
          if DATA.children[note].layers[layer].ISRS5K == true then
            local tr_ptr = DATA.children[note].layers[layer].tr_ptr
            local instrument_pos = DATA.children[note].layers[layer].instrument_pos
            TrackFX_SetParamNormalized( tr_ptr, instrument_pos, 11, 1 )
          end
        end
      end
    end
    Undo_EndBlock2( DATA.proj , 'RS5k manager - update choke', 0xFFFFFFFF ) 
  end
  ---------------------------------------------------------------------
  function DATA:WriteData_Child(tr, t) 
    if not ValidatePtr2(DATA.proj,tr,'MediaTrack*') then return end
    GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_VERSION', DATA.version, true)
    
    -- v4.14+
    if DATA.parent_track.trGUID  then  
      local ret, GUIDINTERNAL = GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_GUIDINTERNAL', '', false) 
      if not ret then GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_GUIDINTERNAL', DATA.parent_track.trGUID, true) end
    end
    
    -- meta FX
      if t.MACRO_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_MACRO_GUID', t.MACRO_GUID, true) end
      if t.CHOKE_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHOKE_GUID', t.CHOKE_GUID, true) end
      if t.MIDIFILT_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_MIDIFILTGUID', t.MIDIFILT_GUID, true) end 
      if t.FX_REAEQ_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_FX_REAEQ_GUID', t.FX_REAEQ_GUID, true) end      
      if t.FX_WS_GUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_FX_WS_GUID', t.FX_WS_GUID, true) end      
      
    -- types
      if t.SET_MarkParentForChild then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_PARENTGUID', t.SET_MarkParentForChild, true) end 
      if t.SET_MarkType_RegularChild then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', 1, true)
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD', '', true) 
       elseif t.SET_MarkType_Device then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICE', 1, true)
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', '', true)
       elseif t.SET_MarkType_MIDIbus then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_MIDIBUS', 1, true)
       elseif t.SET_MarkType_DeviceChild_deviceGUID then 
        --GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD', 1, true) 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', '', true)
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICECHILD_PARENTDEVICEGUID', t.SET_MarkType_DeviceChild_deviceGUID, true) 
       elseif t.SET_MarkType_TYPE_DEVICE_AUTORANGE then 
        GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_TYPE_DEVICE_AUTORANGE', t.SET_MarkType_TYPE_DEVICE_AUTORANGE, true)         
      end 
      
    -- rs5k manager data
      if t.SET_noteID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_NOTE', t.SET_noteID, true) end 
      if t.SET_instrFXGUID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_FXGUID', t.SET_instrFXGUID, true) end 
      if t.SET_isrs5k then  GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_ISRS5K', 1, true) end      
      if t.SET_useDB then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB', t.SET_useDB, true) end  
      if t.SET_useDB_name then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB_NAME', t.SET_useDB_name, true) end  
      if t.SET_useDB_lastID then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_SPLLISTDB_ID', t.SET_useDB_lastID, true) end  
      if t.SET_SAMPLELEN then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_SAMPLELEN', t.SET_SAMPLELEN, true) end  
      if t.SET_SAMPLEBPM then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_SAMPLEBPM', t.SET_SAMPLEBPM, true) end  
      if t.SET_LUFSNORM then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_LUFSNORM', t.SET_LUFSNORM, true) end  
      
      --[[if t.INSTR_PARAM_CACHE then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_CACHE', t.INSTR_PARAM_CACHE, true) end
      if t.INSTR_PARAM_VOL then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_VOL', t.INSTR_PARAM_VOL, true) end
      if t.INSTR_PARAM_TUNE then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_TUNE', t.INSTR_PARAM_TUNE, true) end
      if t.INSTR_PARAM_ATT then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_ATT', t.INSTR_PARAM_ATT, true) end
      if t.INSTR_PARAM_DEC then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_DEC', t.INSTR_PARAM_DEC, true) end
      if t.INSTR_PARAM_SUS then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_SUS', t.INSTR_PARAM_SUS, true) end
      if t.INSTR_PARAM_REL then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_CHILD_INSTR_PARAM_REL', t.INSTR_PARAM_REL, true) end]]
      
    
  end
  ---------------------------------------------------------------------  
  function DATA:Drop_Pad_Swap(src_pad,dest_pad)  
    -- set dest device/devicechidren
    if DATA.children[dest_pad] then   
      DATA:WriteData_Child(DATA.children[dest_pad].tr_ptr, {SET_noteID = src_pad})  
      if DATA.children[dest_pad].layers then
        for layer = 1, #DATA.children[dest_pad].layers do
          DATA:WriteData_Child(DATA.children[dest_pad].layers[layer].tr_ptr, {SET_noteID = src_pad})  
          DATA:DropSample_ExportToRS5kSetNoteRange(DATA.children[dest_pad].layers[layer], src_pad) 
        end
      end 
      local filename  if DATA.children[dest_pad] and DATA.children[dest_pad].layers and DATA.children[dest_pad].layers[1] and DATA.children[dest_pad].layers[1].instrument_filename then filename = DATA.children[dest_pad].layers[1].instrument_filename end
      DATA:DropSample_RenameTrack(DATA.children[dest_pad].tr_ptr,src_pad,filename) 
    end
    
    -- set src device/devicechidren
    if DATA.children[src_pad] then   
      DATA:WriteData_Child(DATA.children[src_pad].tr_ptr, {SET_noteID = dest_pad})  
      if DATA.children[src_pad].layers then
        for layer = 1, #DATA.children[src_pad].layers do
          DATA:WriteData_Child(DATA.children[src_pad].layers[layer].tr_ptr, {SET_noteID = dest_pad})  
          DATA:DropSample_ExportToRS5kSetNoteRange(DATA.children[src_pad].layers[layer], dest_pad)
        end
      end
      local filename  if DATA.children[src_pad] and DATA.children[src_pad].layers and DATA.children[src_pad].layers[1] and DATA.children[src_pad].layers[1].instrument_filename then filename = DATA.children[src_pad].layers[1].instrument_filename end
      DATA:DropSample_RenameTrack(DATA.children[src_pad].tr_ptr,dest_pad,filename) 
    end
    DATA.peakscache[src_pad] = nil
    DATA.peakscache[dest_pad] = nil
    DATA.upd = true
    DATA.autoreposition = true
  end
  ---------------------------------------------------------------------  
  function DATA:Drop_Pad_Duplicate(src_pad,dest_pad)  
    -- set dest device/devicechidren
    if DATA.children[dest_pad] then return end 
    if DATA.children[src_pad].TYPE_DEVICE == true then return end 
    
    -- duplicate source track
      local track = DATA.children[src_pad].tr_ptr
      SetOnlyTrackSelected( track )
      Main_OnCommand(40062,0)--  Track: Duplicate tracks 
      
    -- set src device/devicechidren  
      DATA:WriteData_Child(DATA.children[src_pad].tr_ptr, {SET_noteID = dest_pad})  
      if DATA.children[src_pad].layers then
        for layer = 1, #DATA.children[src_pad].layers do
          DATA:WriteData_Child(DATA.children[src_pad].layers[layer].tr_ptr, {SET_noteID = dest_pad})  
          DATA:DropSample_ExportToRS5kSetNoteRange(DATA.children[src_pad].layers[layer], dest_pad)
        end
      end
      local filename  if DATA.children[src_pad] and DATA.children[src_pad].layers and DATA.children[src_pad].layers[1] and DATA.children[src_pad].layers[1].instrument_filename then filename = DATA.children[src_pad].layers[1].instrument_filename end
      DATA:DropSample_RenameTrack(DATA.children[src_pad].tr_ptr,dest_pad,filename) 
      
      
    DATA.peakscache[src_pad] = nil
    DATA.peakscache[dest_pad] = nil
    DATA.upd = true
    DATA.autoreposition = true
  end
  ---------------------------------------------------------------------  
  function DATA:Drop_Pad(src_pad0,dest_pad0)
    if not src_pad0 and dest_pad0 then return end
    src_pad,dest_pad = tonumber(src_pad0),tonumber(dest_pad0)
    if not src_pad and dest_pad then return end
    
    if not DATA.paddrop_mode then 
      DATA:Drop_Pad_Swap(src_pad,dest_pad)  
     elseif DATA.paddrop_mode == 1 and not DATA.children[dest_pad]  then -- copy stuff to dest pad if it is free
      DATA:Drop_Pad_Duplicate(src_pad,dest_pad)  
      DATA.paddrop_mode = nil
    end
    
  end
  ---------------------------------------------------------------------  
  function DATA:Validate_MIDIbus_AND_ParentFolder() -- set parent as folder if need, since it is a first validation check in DATA:DropSample
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end
    if (DATA.MIDIbus and DATA.MIDIbus.valid == true) then return end
    
    -- make sure parent extstate is set
    if not ( DATA.parent_track and DATA.parent_track.ext_load == true) then 
      DATA:WriteData_Parent() 
    end
    
    -- insert new
    InsertTrackAtIndex( DATA.parent_track.IP_TRACKNUMBER_0based+1, false )
    local MIDI_tr = GetTrack(DATA.proj, DATA.parent_track.IP_TRACKNUMBER_0based+1)
    
    -- set params
    GetSetMediaTrackInfo_String( MIDI_tr, 'P_NAME', 'MIDI bus', 1 )
    SetMediaTrackInfo_Value( MIDI_tr, 'I_RECMON', 1 )
    SetMediaTrackInfo_Value( MIDI_tr, 'I_RECARM', 1 )
    SetMediaTrackInfo_Value( MIDI_tr, 'I_RECMODE', 0 ) -- record MIDI out
    local channel,physical_input = EXT.CONF_midichannel, EXT.CONF_midiinput
    SetMediaTrackInfo_Value( MIDI_tr, 'I_RECINPUT', 4096 + channel + (physical_input<<5)) -- set input to all MIDI
    
    -- make parent track folder
    if DATA.parent_track.I_FOLDERDEPTH ~= 1 then
      SetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERDEPTH',1 )
      SetMediaTrackInfo_Value( MIDI_tr,               'I_FOLDERDEPTH',DATA.parent_track.I_FOLDERDEPTH-1 ) 
    end 
    
    DATA:WriteData_Child(MIDI_tr, {
      SET_MarkParentForChild = DATA.parent_track.trGUID,
      SET_MarkType_MIDIbus = true,
      })  
      
    -- refresh last track in tree if parent track was at initial state
    if DATA.parent_track.IP_TRACKNUMBER_0basedlast == DATA.parent_track.IP_TRACKNUMBER_0based then
      DATA.parent_track.IP_TRACKNUMBER_0basedlast = DATA.parent_track.IP_TRACKNUMBER_0based +1
    end
    
    DATA:CollectData_Children_MIDIbus(MIDI_tr)
    DATA.upd = true
  end
  -----------------------------------------------------------------------  
  function DATA:DropSample_ExportToRS5k_CopySrc(filename)
    local prpath = reaper.GetProjectPathEx( 0 )
    local filename_path = VF_GetParentFolder(filename)
    local filename_name = VF_GetShortSmplName(filename)
    if prpath and filename_path and filename_name then
      prpath = prpath..'/'..EXT.CONF_onadd_copysubfoldname..'/'
      
      RecursiveCreateDirectory( prpath, 0 )
      local src = filename
      local dest = prpath..filename_name
      local fsrc = io.open(src, 'rb')
      if fsrc then
        content = fsrc:read('a') 
        fsrc:close()
        fdest = io.open(dest, 'wb')
        if fdest then 
          fdest:write(content)
          fdest:close()
          return dest
        end
      end
    end
    return filename
  end
  --------------------------------------------------------------------- 
  function DATA:DropSample_ExportToRS5kSetNoteRange(note_layer_t, note) 
    local tr = note_layer_t.tr_ptr
    local instrument_pos = note_layer_t.instrument_pos
    local midifilt_pos = note_layer_t.midifilt_pos
    
    if not note then return end
    if not midifilt_pos  then 
      TrackFX_SetParamNormalized( tr, instrument_pos, 3, (note)/127 ) -- note range start
      TrackFX_SetParamNormalized( tr, instrument_pos, 4, (note)/127 ) -- note range end
     else 
      TrackFX_SetParamNormalized( tr, midifilt_pos, 0, note/128)
      TrackFX_SetParamNormalized( tr, midifilt_pos, 1, note/128)
    end
  end
  --------------------------------------------------------------------- 
  function DATA:DropSample_AddNewTrack(deviceparent, note, SET_MarkType_DeviceChild_deviceGUID) 
    -- define position
    local ID = DATA.parent_track.IP_TRACKNUMBER_0based+1 -- after parent
    
    -- add / handle tree
    InsertTrackAtIndex( ID, false )
    local new_tr = GetTrack(DATA.proj, ID)  
    
    -- add custom template
    if deviceparent ~= true and EXT.CONF_onadd_customtemplate ~= '' then 
      local f = io.open(EXT.CONF_onadd_customtemplate,'rb')
      local content
      if f then 
        content = f:read('a')
        f:close()
      end
      local GUID = GetTrackGUID( new_tr )
      content = content:gsub('TRACK ', 'TRACK '..GUID)
      SetTrackStateChunk( new_tr, content, false )
      TrackFX_Show( new_tr, 0, 0 ) -- hide chain
      for fxid = 1,  TrackFX_GetCount( new_tr ) do TrackFX_Show( new_tr,fxid-1, 2 ) end-- hide chain
    end  
    
    -- set height
    if EXT.CONF_onadd_newchild_trackheight > 0 then SetMediaTrackInfo_Value( new_tr, 'I_HEIGHTOVERRIDE', EXT.CONF_onadd_newchild_trackheight ) end 
    
    -- print timestamp
    GetSetMediaTrackInfo_String(  new_tr, 'P_EXT:MPLRS5KMAN_TSADD', os.time(), true) 
    if EXT.CONF_onadd_takeparentcolor == 1 then SetMediaTrackInfo_Value( new_tr, 'I_CUSTOMCOLOR',DATA.parent_track.I_CUSTOMCOLOR ) end
    
    -- auto color
    if EXT.CONF_autocol == 1 and DATA.padautocolors and DATA.padautocolors[note] then 
      local r,g,b = 
        (DATA.padautocolors[note]>>24)&0xFF, 
        (DATA.padautocolors[note]>>16)&0xFF, 
        (DATA.padautocolors[note]>>8)&0xFF
      local color = ColorToNative(r,g,b)|0x1000000
      SetMediaTrackInfo_Value( new_tr, 'I_CUSTOMCOLOR', color )
    end
    
    -- move in structure
    DATA:DropSample_AddNewTrack_Move(new_tr, deviceparent, note, SET_MarkType_DeviceChild_deviceGUID)
    
    return new_tr
  end 
  --------------------------------------------------------------------- 
  function DATA:DropSample_AddNewTrack_Move(new_tr, deviceparent, note, SET_MarkType_DeviceChild_deviceGUID)
    local exact_note 
    local next_note 
    for note0 in spairs(DATA.children) do
      if note0 == note then exact_note = true end
      if note0 > note then next_note = note0 break end
    end    
    
    -- new regular child
      if deviceparent~=true and not SET_MarkType_DeviceChild_deviceGUID then
        local beforeTrackIdx
        if next_note then
          beforeTrackIdx = DATA.children[next_note].IP_TRACKNUMBER_0based
         else
          if (DATA.MIDIbus and DATA.MIDIbus.IP_TRACKNUMBER_0based) then
            beforeTrackIdx = DATA.MIDIbus.IP_TRACKNUMBER_0based+1 -- goes before midi bus
           else
            beforeTrackIdx = DATA.parent_track.IP_TRACKNUMBER_0based+1 -- goes after parent
          end
        end
        
        if EXT.CONF_onadd_ordering == 0 then -- 0 sorted by note 1 at the top 2 at the bottom
          DATA:Auto_Reposition_TrackGetSelection()
          SetOnlyTrackSelected( new_tr )
          ReorderSelectedTracks( beforeTrackIdx, 0 )
          DATA:Auto_Reposition_TrackRestoreSelection()
         elseif EXT.CONF_onadd_ordering == 1 then
          -- after parent
         elseif EXT.CONF_onadd_ordering == 2 then
          
          local last_tr = GetTrack(DATA.proj, DATA.parent_track.IP_TRACKNUMBER_0basedlast+1)
          if last_tr then
            local last_trdepth = GetMediaTrackInfo_Value( last_tr, 'I_FOLDERDEPTH' ) 
            DATA:Auto_Reposition_TrackGetSelection()
            SetOnlyTrackSelected( new_tr ) 
            beforeTrackIdx = DATA.parent_track.IP_TRACKNUMBER_0basedlast+2 -- goes after last track
            DATA.parent_track.IP_TRACKNUMBER_0basedlast = DATA.parent_track.IP_TRACKNUMBER_0basedlast + 1 -- MUST refresh otherwise break structure
            ReorderSelectedTracks( beforeTrackIdx, 0 )
            if last_trdepth == -1 then -- last track was 2nd level
              SetMediaTrackInfo_Value( last_tr, 'I_FOLDERDEPTH', 0)-- set midi bus to normal child
              SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH', -1 )-- set new_tr to enclose parent
             else
              SetMediaTrackInfo_Value( last_tr, 'I_FOLDERDEPTH', last_trdepth + 1 ) -- set midi bus to normal child
              SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH', last_trdepth )-- set new_tr to enclose parent
            end
            DATA:Auto_Reposition_TrackRestoreSelection()
          end
          
        end
      end
    
    -- new layer
      if deviceparent~=true and SET_MarkType_DeviceChild_deviceGUID and exact_note then
        local beforeTrackIdx = DATA.children[note].IP_TRACKNUMBER_0based +1 -- goes after parent 
        DATA:Auto_Reposition_TrackGetSelection()
        SetOnlyTrackSelected( new_tr )
        ReorderSelectedTracks( beforeTrackIdx, 0 )--make sure parent is folder
        DATA:Auto_Reposition_TrackRestoreSelection()
        DATA.upd2.updatedevicevelocityrange = note
        DATA.upd2.refresh = true
      end
   
    -- new device
      if deviceparent==true then
        if exact_note then -- child exist
          SetOnlyTrackSelected( new_tr )
          local beforeTrackIdx = DATA.children[note].IP_TRACKNUMBER_0based -- before child
          ReorderSelectedTracks( beforeTrackIdx, 0 )
          local child_tr = GetTrack(-1,DATA.children[note].IP_TRACKNUMBER_0based)
          SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH', 1 ) -- enclose new device
          local I_FOLDERDEPTH = GetMediaTrackInfo_Value( child_tr, 'I_FOLDERDEPTH') -- enclose new device
          SetMediaTrackInfo_Value( child_tr, 'I_FOLDERDEPTH', I_FOLDERDEPTH-1 ) -- enclose new device
          return
        end
        
        local beforeTrackIdx
        if (DATA.MIDIbus and DATA.MIDIbus.IP_TRACKNUMBER_0based) then
          beforeTrackIdx = DATA.MIDIbus.IP_TRACKNUMBER_0based -- before midi bus
         else
          beforeTrackIdx = DATA.parent_track.IP_TRACKNUMBER_0based+1 -- after parent
        end
        if next_note then beforeTrackIdx = DATA.children[next_note].IP_TRACKNUMBER_0based end -- before next note if any
        DATA:Auto_Reposition_TrackGetSelection()
        SetOnlyTrackSelected( new_tr )
        ReorderSelectedTracks( beforeTrackIdx, 0 )
        DATA:Auto_Reposition_TrackRestoreSelection()
      end
      
  end
  ---------------------------------------------------------------------  
  function DATA:DropSample_ValidateTrack(note, layer)
    local track 
    
    -- track exists
    if  
      layer and 
      DATA.children[note] and 
      DATA.children[note].layers and 
      DATA.children[note].layers[layer] and 
      DATA.children[note].layers[layer].tr_ptr and 
      ValidatePtr2(DATA.proj, DATA.children[note].layers[layer].tr_ptr, 'MediaTrack*') then 
     return DATA.children[note].layers[layer].tr_ptr 
    end 
    
    
    -- add 
      local SET_MarkType_DeviceChild_deviceGUID
      if DATA.children[note] and DATA.children[note].TYPE_DEVICE == true then
        local deviceGUID = DATA.children[note].TR_GUID
        SET_MarkType_DeviceChild_deviceGUID = deviceGUID
       else
        -- add device parent 
        if layer ~= 1 then
          local device_parent = DATA:DropSample_AddNewTrack(true, note) 
          local retval, deviceGUID = GetSetMediaTrackInfo_String( device_parent, 'GUID', '', false  )
          SET_MarkType_DeviceChild_deviceGUID = deviceGUID
          GetSetMediaTrackInfo_String( device_parent, 'P_NAME', 'Note '..note, 1 )
          DATA:WriteData_Child(device_parent, {
            SET_MarkParentForChild = DATA.parent_track.trGUID,
            SET_MarkType_Device = true,
            SET_noteID=note,
            SET_noteID=note,
            }) 
        end
      end
      
      
      local track = DATA:DropSample_AddNewTrack(false, note, SET_MarkType_DeviceChild_deviceGUID)
      DATA:WriteData_Child(track, {
        SET_MarkParentForChild = DATA.parent_track.trGUID,
        SET_MarkType_RegularChild = true,
        SET_MarkType_DeviceChild_deviceGUID=SET_MarkType_DeviceChild_deviceGUID,
        SET_noteID=note,
        }) 
      return track
      
      
    
  end  
  
  -----------------------------------------------------------------------  
  function DATA:DropFX_Export(track, instrument_pos, note, fxname)  
    local midifilt_pos = TrackFX_AddByName( track, 'midi_note_filter', false, -1000 ) 
    DATA:DropSample_ExportToRS5kSetNoteRange({tr_ptr=track, instrument_pos=instrument_pos,midifilt_pos=midifilt_pos}, note) 
    
    -- set parameters
      if EXT.CONF_onadd_float == 0 then TrackFX_SetOpen( track, instrument_pos, false ) end
    
    -- store external data
      local instrumentGUID = TrackFX_GetFXGUID( track, instrument_pos)
      DATA:WriteData_Child(track, {
        SET_instrFXGUID = instrumentGUID,
        SET_noteID=note,
        SET_isrs5k=false,
      }) 
    
    -- rename track
      if EXT.CONF_onadd_renametrack==1 then 
        GetSetMediaTrackInfo_String( track, 'P_NAME', fxname, true )
      end
      
  end
  ---------------------------------------------------------------------  
  function DATA:DropFX(fx_namesrc, fxname, fxidx, src_track, note, drop_data)
    if not (fx_namesrc and src_track and note) then return end
    local layer = 1
    if drop_data and drop_data.layer then layer = drop_data.layer end
    
    -- validate parenbt track
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end 
    DATA:Validate_MIDIbus_AND_ParentFolder() -- make sure parent track is folder for tree consistency 
    DATA.upd = true
     
    -- validate track    
    local track = DATA:DropSample_ValidateTrack(note, layer)
    if not track then return end
    
    -- validate instr pos
    local instrument_pos 
    if DATA.children[note] and DATA.children[note].layers and DATA.children[note].layers[layer or 1] and DATA.children[note].layers[layer or 1].instrument_pos then instrument_pos = DATA.children[note].layers[layer or 1].instrument_pos end 
    if instrument_pos then TrackFX_Delete( track, instrument_pos ) end
    
    -- insert rs5k
    TrackFX_CopyToTrack( src_track, fxidx, track, 0, true )
    local instrument_pos = TrackFX_AddByName( track, fx_namesrc, false, 0)  
    if instrument_pos == -1 then return end
    DATA:DropFX_Export(track, instrument_pos, note, fxname) 
    
    
    DATA.autoreposition = true    
  end
  ---------------------------------------------------------------------  
  function DATA:DropSample(filename, note, drop_data)
    if not (filename and note) then return end
    local layer = 1
    if drop_data and drop_data.layer then layer = drop_data.layer end
    if not (drop_data.SOFFS and drop_data.EOFFS) then drop_data.SOFFS = 0 drop_data.EOFFS = 1 end --4.37
    
    -- validate parent track
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end 
    DATA:Validate_MIDIbus_AND_ParentFolder() -- make sure parent track is folder for tree consistency 
    DATA.upd = true
     
    -- validate track    
    local track = DATA:DropSample_ValidateTrack(note, layer)
    if not track then return end
    
    -- validate instr pos
    local instrument_pos 
    if DATA.children[note] and DATA.children[note].layers and DATA.children[note].layers[layer or 1] and DATA.children[note].layers[layer or 1].instrument_pos then instrument_pos = DATA.children[note].layers[layer or 1].instrument_pos end 
    
    -- insert rs5k
    if not instrument_pos then
      instrument_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, 0) -- query
      if instrument_pos == -1 then instrument_pos = TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1000 ) end
      if instrument_pos == -1 then return end
    end
      
    DATA:DropSample_ExportToRS5k(track, instrument_pos, filename, note, drop_data) 
    DATA.autoreposition = true
  end   
  -----------------------------------------------------------------------  
  function DATA:DropSample_ExportToRS5k(track, instrument_pos, filename, note, drop_data) 
      
    -- validate filename
      if not (track and  instrument_pos and filename and filename~='')  then return end 
      DATA.peakscache[note] = nil
    -- handle file
      if EXT.CONF_onadd_copytoprojectpath == 1 then filename = DATA:DropSample_ExportToRS5k_CopySrc(filename) end 
    -- set parameters
      if EXT.CONF_onadd_float == 0 then TrackFX_SetOpen( track, instrument_pos, false ) end
      TrackFX_SetNamedConfigParm( track, instrument_pos, 'FILE0', filename)
      TrackFX_SetNamedConfigParm( track, instrument_pos, 'DONE', '')
      if EXT.CONF_onadd_renameinst == 1 and EXT.CONF_onadd_renameinst_str ~= '' then
        local str = EXT.CONF_onadd_renameinst_str
        str = str:gsub('%#note',note)
        if drop_data.layer then str = str:gsub('%#layer',drop_data.layer) else str = str:gsub('%#layer','') end
        TrackFX_SetNamedConfigParm( track, instrument_pos, 'renamed_name', str)
      end
      TrackFX_SetParamNormalized( track, instrument_pos, 2, 0) -- gain for min vel
      TrackFX_SetParamNormalized( track, instrument_pos, 5, 0.5 ) -- pitch for start
      TrackFX_SetParamNormalized( track, instrument_pos, 6, 0.5 ) -- pitch for end
      TrackFX_SetParamNormalized( track, instrument_pos, 8, 0 ) -- max voices = 0
      TrackFX_SetParamNormalized( track, instrument_pos, 11, EXT.CONF_onadd_obeynoteoff) -- obey note offs
      
      -- ADSR
      TrackFX_SetParamNormalized( track, instrument_pos, 9, 0 ) -- attack 
      if drop_data.custom_release_sec then
        local custom_release =math.min(drop_data.custom_release_sec/2,1)
        TrackFX_SetParamNormalized( track, instrument_pos, 10, custom_release ) -- release
      end
      if drop_data.custom_decay_sec then
        local custom_decay_sec =math.min(drop_data.custom_decay_sec/15,1)
        TrackFX_SetParamNormalized( track, instrument_pos, 24, custom_decay_sec ) -- release
      end 
      if drop_data.custom_sustain then
        TrackFX_SetParamNormalized( track, instrument_pos, 25, drop_data.custom_sustain )
      end
      
      
      local temp_t = {
        tr_ptr = track,
        instrument_pos = instrument_pos
      }
      DATA:DropSample_ExportToRS5kSetNoteRange(temp_t, note)
    
    -- set offsets
      if drop_data and drop_data.SOFFS and drop_data.EOFFS then
        TrackFX_SetParamNormalized( track, instrument_pos, 13, drop_data.SOFFS )
        TrackFX_SetParamNormalized( track, instrument_pos, 14, drop_data.EOFFS )
      end
    
    -- store external data
      local src = PCM_Source_CreateFromFileEx( filename, true )
      if src then
        local src_len =  GetMediaSourceLength( src )  
        
        -- auto normalization
        if EXT.CONF_onadd_autoLUFSnorm_toggle == 1 then 
          
          local normalizeTo = 0
          local normalizeTarget = EXT.CONF_onadd_autoLUFSnorm
          
          local norm_check1 = 0
          local norm_check2 = 0
          
          if drop_data.SOFFS then norm_check1 = drop_data.SOFFS * src_len end
          if drop_data.EOFFS then norm_check2 = drop_data.EOFFS * src_len end
          
          local LUFSNORM = CalculateNormalization( src, normalizeTo, normalizeTarget, norm_check1, norm_check2 ) 
          local LUFSNORM_db = WDL_VAL2DB(LUFSNORM)
          drop_data.LUFSNORM_db = LUFSNORM_db
          
          LUFSNORM_db = drop_data.LUFSNORM_db
          LUFSNORM_db= tostring(LUFSNORM_db)
          local v = VF_BFpluginparam(LUFSNORM_db, track, instrument_pos,0)
          v = VF_lim(v,0.1,1)
          TrackFX_SetParamNormalized( track, instrument_pos,0, v )   
          function __f_lufs_compensation() end
        end
        
        PCM_Source_Destroy( src )
        
        if src_len then  
          local instrumentGUID = TrackFX_GetFXGUID( track, instrument_pos)
          local SAMPLEBPM ,LUFSNORM_db
          if drop_data.SAMPLEBPM then SAMPLEBPM = drop_data.SAMPLEBPM end
          if drop_data.LUFSNORM_db then LUFSNORM_db = drop_data.LUFSNORM_db end
          DATA:WriteData_Child(track, {
            SET_SAMPLELEN = src_len,
            SET_SAMPLEBPM = SAMPLEBPM,
            SET_LUFSNORM = LUFSNORM_db,
            SET_instrFXGUID = instrumentGUID,
            SET_noteID=note,
            SET_isrs5k=true,
          }) 
        end 
      end
      
    -- rename track
    DATA:DropSample_RenameTrack(track,note,filename,drop_data) 
    
    if drop_data.set_DB then 
      DATA:WriteData_Child(track, {
        SET_useDB = 1,
        SET_useDB_name = drop_data.set_DB})  
    end
  end  
  -----------------------------------------------------------------------  
  function DATA:DropSample_RenameTrack(track,note,filename,drop_data) 
    if EXT.CONF_onadd_renametrack~=1 then return end
    local outname = '' 
    if DATA.padcustomnames and DATA.padcustomnames[note] and DATA.padcustomnames[note] ~='' then outname = DATA.padcustomnames[note] end
    if outname == '' and filename then
      local filename_sh = VF_GetShortSmplName(filename)
      if filename_sh:match('(.*)%.[%a]+') then filename_sh = filename_sh:match('(.*)%.[%a]+') end -- remove extension
      if drop_data and drop_data.tr_name_add then filename_sh = filename_sh .. ' '..drop_data.tr_name_add end
      outname = filename_sh
    end
    GetSetMediaTrackInfo_String( track, 'P_NAME', outname, true )
  end

--------------------------------------------------------------------------------  
  function DATA:Action_ExplodeTake()
    Undo_BeginBlock2(DATA.proj)
    for i = 1, reaper.CountSelectedMediaItems(DATA.proj) do
      local item = GetSelectedMediaItem(DATA.proj, i-1)
      if not item then goto nextitem end
      local take = GetActiveTake(item)
      if not (take and reaper.TakeIsMIDI(take)) then goto nextitem end
      
      local D_POSITION = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local D_LENGTH = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local B_LOOPSRC = GetMediaItemInfo_Value( item, 'B_LOOPSRC' )
      SetMediaItemInfo_Value( item, 'B_MUTE', 1 )
      local D_STARTOFFS = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
      local D_PLAYRATE = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
      local I_CUSTOMCOLOR = GetMediaItemTakeInfo_Value( take, 'I_CUSTOMCOLOR' )
      local pcmsrc = GetMediaItemTake_Source( take )
      local srclen, lengthIsQN = reaper.GetMediaSourceLength( pcmsrc )
      
      local t_pitch= {}
       tableEvents = {}
      local t = 0
      local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
      local MIDIlen = MIDIstring:len()
      local stringPos = 1
      local offset, flags, msg1
      local val = 1
      while stringPos < MIDIlen do
        offset, flags, msg1, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
        tableEvents[#tableEvents+1] = {
          offset=offset,
          flags=flags,
          msg1=msg1,
        }
        local pitch = msg1:byte(2)
        t_pitch[pitch]=true
      end
      
      
      
      for note in pairs(t_pitch) do
        if note and DATA.children[note] then
          local track = DATA.children[note].tr_ptr
          if track then
            local new_item = CreateNewMIDIItemInProj( track, D_POSITION, D_POSITION + D_LENGTH )
            local take = GetActiveTake(new_item)
            SetMediaItemTakeInfo_Value( take, 'D_STARTOFFS',D_STARTOFFS )
            SetMediaItemTakeInfo_Value( take, 'D_PLAYRATE',D_PLAYRATE ) 
            SetMediaItemTakeInfo_Value( take, 'I_CUSTOMCOLOR',I_CUSTOMCOLOR ) 
            SetMediaItemInfo_Value( new_item, 'B_LOOPSRC',B_LOOPSRC ) 
            
            local MIDIstring = ""
            for i = 1, #tableEvents-1 do
              local msg1 = tableEvents[i].msg1
              if msg1:byte(2) ~= note then msg1 = '' end
              MIDIstring = MIDIstring..string.pack("i4Bs4", tableEvents[i].offset, tableEvents[i].flags, msg1)
            end
            MIDIstring = MIDIstring..string.pack("i4Bs4", tableEvents[#tableEvents].offset, tableEvents[#tableEvents].flags, tableEvents[#tableEvents].msg1)
            MIDI_SetAllEvts(take, MIDIstring)
            MIDI_Sort(take)
          end
        end
      end
      
      ::nextitem::
    end
    Undo_EndBlock2(DATA.proj, 'Explode MIDI bus take by note', 0xFFFFFFFF)
  end
--------------------------------------------------------------------------------  
  function DATA:Database_Load(sel_pad_only)
    if not EXT.UIdatabase_maps_current then return end
    if not DATA.reaperDB then return end
    local mapID = EXT.UIdatabase_maps_current
    if not (DATA.database_maps[mapID] and DATA.database_maps[mapID].map) then return end
    
    for note in pairs(DATA.database_maps[mapID].map) do
      if not sel_pad_only or (sel_pad_only == true and DATA.parent_track.ext.PARENT_LASTACTIVENOTE and note == DATA.parent_track.ext.PARENT_LASTACTIVENOTE) then
      
        local dbname = DATA.database_maps[mapID].map[note].dbname
        if DATA.reaperDB[dbname] and DATA.reaperDB[dbname].files then
          local sz = #DATA.reaperDB[dbname].files
          local rand_fid = 1 + math.floor(math.random(sz-1))
          local fp = DATA.reaperDB[dbname].files[rand_fid].fp
          DATA:DropSample(fp, note, {set_DB = dbname})
        end
      
      end
    end
  end
--------------------------------------------------------------------------------  
  function DATA:Database_Save(ignore_current_rack)  
    if not EXT.UIdatabase_maps_current then return end
    if not DATA.reaperDB then return end
    local mapID = EXT.UIdatabase_maps_current
    if not (DATA.database_maps[mapID] and DATA.database_maps[mapID].map) then return end
    
    if not ignore_current_rack then
      for note in pairs(DATA.children) do
        if DATA.children[note].layers 
          and DATA.children[note].layers[1] 
          and DATA.children[note].layers[1].SET_useDB_name
         then
          local dbname = DATA.children[note].layers[1].SET_useDB_name
          if not DATA.database_maps[mapID].map[note] then DATA.database_maps[mapID].map[note] = {} end
          DATA.database_maps[mapID].map[note].dbname=dbname
        end
      end
    end
    
    local s = 'DBNAME '..DATA.database_maps[mapID].dbname..'\n'
    if not DATA.database_maps[mapID].map then return '' end
    for note in pairs(DATA.database_maps[mapID].map) do
      s = s..'NOTE'..note
      for param in pairs(DATA.database_maps[mapID].map[note]) do 
        local tp =  type(DATA.database_maps[mapID].map[note][param]) 
        if tp == 'string' or tp == 'number' then 
          s = s ..' <'..param..'>'..DATA.database_maps[mapID].map[note][param]..'</'..param..'>' 
        end
      end
      s = s..'\n'
    end
    
    EXT['CONF_database_map'..mapID] = VF_encBase64(s)
    EXT:save() 
  end  
  
  -----------------------------------------------------------------------  
  function DATA:Sampler_ShowME(note0, layer0) 
    local note 
    if not note then 
      if not DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE then return end 
      note = DATA.parent_track.ext.PARENT_LASTACTIVENOTE 
     else 
      note = note0 
    end
    local layer if not layer then layer = 1 else layer = layer0 end
    if not DATA.children[note] then return end
    local t = DATA.children[note].layers[layer] -- layer == 1 do stuff on device/instrument or first layer only // layer defined = do stuff on defined layer 
    if not t.instrument_filename then return end
    OpenMediaExplorer( t.instrument_filename, false )
  end  
  
  -------------------------------------------------------------------------------- 
  function DATA:Action_LearnController(tr,fxnumber,paramnumber, clear)
    if not (tr and fxnumber and paramnumber) then return end
    local midi1, midi2
    local retval1, rawmsg, tsval, devIdx, projPos, projLoopCnt = MIDI_GetRecentInputEvent(0)
    
    --[[local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
    if not retval then return end 
    local trid = tracknumber&0xFFFF
    local itid = (tracknumber>>16)&0xFFFF
    if itid > 0 then return end -- ignore item FX
    local tr
    if trid==0 then tr = GetMasterTrack(0) else tr = GetTrack(0,trid-1) end
    if not tr then return end]]
    
    if clear~= true then
      if retval1 == 0 then return end
      midi2 = rawmsg:byte(2)
      midi1 = rawmsg:byte(1)  
      Undo_BeginBlock2( DATA.proj )
      TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.learn.midi1', midi1)
      TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.learn.midi2', midi2) 
      Undo_EndBlock2( DATA.proj, 'Bind controller to RS5k manager', 0xFFFFFFFF )
     else
      Undo_BeginBlock2( DATA.proj )
      TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.learn.midi1', '')
      TrackFX_SetNamedConfigParm( tr, fxnumber, 'param.'..paramnumber..'.learn.midi2', '') 
      Undo_EndBlock2( DATA.proj, 'Clear macro binding', 0xFFFFFFFF )
    end
  end
  
  -----------------------------------------------------------------------------  
  function DATA:Macro_ConfirmLastTouchedParamIsChild()
    local t = VF_GetLTP()
    if not t then return end
    local note_out, layer_out
    local lt_TR_GUID = t.trGUID
    for note in pairs(DATA.children) do
      if DATA.children[note].TR_GUID then 
        if DATA.children[note].TR_GUID == lt_TR_GUID then 
          return true, DATA.children[note], t.fxnumber, t.paramnumber
        end
      end
      if DATA.children[note].layers then
        for layer in pairs(DATA.children[note].layers) do
          if DATA.children[note].layers[layer].TR_GUID and DATA.children[note].layers[layer].TR_GUID == lt_TR_GUID then
            return true, DATA.children[note].layers[layer], t.fxnumber, t.paramnumber
          end
        end
      end
    end
  end
  -----------------------------------------------------------------------------  
  function DATA:Macro_AddLink(srct0,fxnumber0,paramnumber0, offset0, scale0)
    DATA.upd = true
    -- validate stuff
      if DATA.parent_track.valid ~= true then return end 
      if not DATA.parent_track.ext.PARENT_LASTACTIVEMACRO then return end 
      if DATA.parent_track.ext.PARENT_LASTACTIVEMACRO == -1 then return end
    
    -- validate locals / last touched param
      local ret, srct, fxnumber, paramnumber = DATA:Macro_ConfirmLastTouchedParamIsChild()
      if not ret and not srct0 then 
        return 
       elseif (srct0 and fxnumber0 and paramnumber0) then
        srct, fxnumber, paramnumber = srct0, fxnumber0, paramnumber0
      end 
    
    -- init child macro
      if not srct.MACRO_pos then DATA:Macro_InitChildrenMacro(true, srct) fxnumber=fxnumber+1 end 
      
    -- link
      local param_src = tonumber(DATA.parent_track.ext.PARENT_LASTACTIVEMACRO)
      local fx_src = tonumber(srct.MACRO_pos)
      
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.active', 1)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.scale', scale0 or 1)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.offset', offset0 or 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.effect',fx_src)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.param', param_src)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.midi_bus', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.midi_chan', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.midi_msg', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.plink.midi_msg2', 0)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.mod.active', 1)
      TrackFX_SetNamedConfigParm(srct.tr_ptr, fxnumber, 'param.'..paramnumber..'.mod.visible', 0)
  end
  
  -----------------------------------------------------------------------  
  function DATA:Macro_InitChildrenMacro(child_mode, srct)
    --if DATA.parent_track.macro.valid == true and not child_mode then return end
    
    local fxname = 'mpl_RS5k_manager_MacroControls.jsfx'
    
    -- master
    if not child_mode then
      local macroJSFX_pos =  TrackFX_AddByName( DATA.parent_track.ptr, fxname, false, 0 )
      if macroJSFX_pos == -1 then
        macroJSFX_pos =  TrackFX_AddByName( DATA.parent_track.ptr, fxname, false, -1000 ) 
        local macroJSFX_fxGUID = reaper.TrackFX_GetFXGUID( DATA.parent_track.ptr, macroJSFX_pos ) 
        DATA.parent_track.ext.PARENT_MACRO_GUID =macroJSFX_fxGUID
        DATA:WriteData_Parent()
        TrackFX_Show( DATA.parent_track.ptr, macroJSFX_pos, 0|2 )
        for i = 1, 16 do TrackFX_SetParamNormalized( DATA.parent_track.ptr, macroJSFX_pos, 33+i, i/1024 ) end -- init source gmem IDs
      end
      return macroJSFX_pos
    end
    
    
    -- child_mode
    if child_mode == true then 
      if not srct then return end
      if not srct.MACRO_pos then
        macroJSFX_pos =  TrackFX_AddByName( srct.tr_ptr, fxname, false, -1000 )
        if macroJSFX_pos == -1 then return end --MB('RS5k manager_MacroControls JSFX is missing. Make sure you installed it correctly via ReaPack.', '', 0) end
        local macroJSFX_fxGUID = reaper.TrackFX_GetFXGUID( srct.tr_ptr, macroJSFX_pos )  
        TrackFX_Show( srct.tr_ptr, macroJSFX_pos, 0|2 )
        TrackFX_SetParamNormalized( srct.tr_ptr, macroJSFX_pos, 0, 1 ) -- set mode to slave
        for i = 1, 16 do TrackFX_SetParamNormalized( srct.tr_ptr, macroJSFX_pos, 17+i, i/1024 ) end -- ini source gmem IDs
        DATA:WriteData_Child(srct.tr_ptr, {MACRO_GUID=macroJSFX_fxGUID})
        srct.MACRO_pos = macroJSFX_pos
        return macroJSFX_pos
      end
    end
    
  end
  -----------------------------------------------------------------------  
  function DATA:Macro_ClearLink()
    if not (DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVEMACRO) then return end 
    local macroID = DATA.parent_track.ext.PARENT_LASTACTIVEMACRO
    if not DATA.parent_track.macro.sliders[macroID].links then return end
    for link = #DATA.parent_track.macro.sliders[macroID].links, 1, -1 do
      local tmacro = DATA.parent_track.macro.sliders[macroID].links[link]
      TrackFX_SetNamedConfigParm(tmacro.note_layer_t.tr_ptr, tmacro.fx_dest, 'param.'..tmacro.param_dest..'plink.active', 0) 
    end
        
  end    
  
  ----------------------------------------------------------------------
  function DATA:Actions_TemporaryGetAudio(filename) 
    
    local PCM_Source = PCM_Source_CreateFromFile( filename )
    local srclen, lengthIsQN = reaper.GetMediaSourceLength( PCM_Source )
    if srclen > EXT.CONF_crop_maxlen then
      --if PCM_Source then  PCM_Source_Destroy( PCM_Source )  end
      return
    end
    
    
    -- add temp stuff for audio read
    local tr_cnt = CountTracks(DATA.proj)
    InsertTrackInProject( DATA.proj, tr_cnt, 0 )
    local temp_track  = GetTrack(DATA.proj, tr_cnt) 
    local temp_item = AddMediaItemToTrack( temp_track )
    local temp_take = AddTakeToMediaItem( temp_item )
    SetMediaItemTake_Source( temp_take, PCM_Source )
    SetMediaItemInfo_Value( temp_item, 'D_POSITION', 0 )
    SetMediaItemInfo_Value( temp_item, 'D_LENGTH',srclen ) 
    local SR = reaper.GetMediaSourceSampleRate( PCM_Source )  
    local window_spls = SR  * srclen 
    local samplebuffer = reaper.new_array(window_spls) 
    local accessor = CreateTakeAudioAccessor( temp_take )
    GetAudioAccessorSamples( accessor, SR, 1, 0, window_spls, samplebuffer ) 
    --if reaper.ValidatePtr2( DATA.proj, PCM_Source, 'PCM_Source*' ) then  PCM_Source_Destroy( PCM_Source )  end
    DestroyAudioAccessor( accessor ) 
    DeleteTrack( temp_track )
    
    local samplebuffer_t = samplebuffer.table()
    samplebuffer.clear()
    return samplebuffer_t,srclen,SR
  end
  ----------------------------------------------------------------------
  function DATA:Action_CropToAudibleBoundaries(note_layer_t) 
    if not note_layer_t then return end 
    local filename = note_layer_t.instrument_filename
    if not filename then return end
    local samplebuffer_t = DATA:Actions_TemporaryGetAudio(filename)  
    if not samplebuffer_t then return end
    
    -- threshold
    local threshold_lin = WDL_DB2VAL(EXT.CONF_cropthreshold)
    local cnt_peaks = #samplebuffer_t 
    local loopst = 0
    local loopend = 1
    for i = 1, cnt_peaks do if math.abs(samplebuffer_t[i]) > threshold_lin then loopst = i/cnt_peaks break end end
    for i = cnt_peaks, 1, -1 do if math.abs(samplebuffer_t[i]) > threshold_lin then loopend = i/cnt_peaks break end end  
    TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 13, loopst ) 
    TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 14, loopend ) 
    DATA.upd = true
  end  
  
  --------------------------------------------------------------------------------
  function DATA:Action_ShiftOffset_NextTransient(note_layer_t)  
    if not note_layer_t then return end 
    
    local instrument_samplestoffs = note_layer_t.instrument_samplestoffs
    local instrument_sampleendoffs = note_layer_t.instrument_sampleendoffs
    local SAMPLELEN = note_layer_t.SAMPLELEN
    local transientahead  = EXT.CONF_stepmode_transientahead / SAMPLELEN
    
    local filename = note_layer_t.instrument_filename
    if not filename then return end
    local buf,srclen,SR = DATA:Actions_TemporaryGetAudio(filename)  
    if not buf then return end
     
    local bufsz = #buf
    local startID = math.floor(bufsz* instrument_samplestoffs)  
    local check_area = math.floor(0.05*SR)
    local step_skip = 10
    for i = startID+check_area, bufsz-check_area, step_skip do
      local curval = math.abs(buf[i])
      if curval < 0.01 then goto nextframe end 
      local rmsarea = 0
      for i2 = i , i+check_area do rmsarea = rmsarea + math.abs(buf[i2]) end rmsarea=rmsarea / check_area 
      if rmsarea < 0.05 then goto nextframe end
      
      if curval / rmsarea < 0.1  then
        
        -- search loudest peak
        local maxpeakID  = i
        local maxval = 0
        for i2 = i-step_skip , i+check_area+step_skip do 
          if math.abs(buf[i2]) > maxval then  maxpeakID = i2 end
          maxval = math.max(maxval, math.abs(buf[i2]) )
        end
        
        --[[ reverse search minimum
        local minpeakID  = maxpeakID
        local minval = 0
        for i2 = maxpeakID , maxpeakID-check_area,-1 do 
          if math.abs(buf[i2]) < minval then  minpeakID = i2 end
          minval = math.min(minval, math.abs(buf[i2]) )
          if math.abs(buf[i2]) < 0.01 then minpeakID = i2 break end 
        end]]
        
        local outID = maxpeakID
        out_shift = VF_lim(outID/bufsz - instrument_samplestoffs)
        
        break
        
      end
      ::nextframe::
    end
    if out_shift then out_shift = out_shift - transientahead end
    
    return out_shift
  end
    --------------------------------------------------------------------------------
  function DATA:Action_ShiftOffset(note_layer_t, mode, dir)
    if not (note_layer_t and note_layer_t.ISRS5K == true ) then return end
    local note = note_layer_t.noteID
    
    local instrument_samplestoffs = note_layer_t.instrument_samplestoffs
    local instrument_sampleendoffs = note_layer_t.instrument_sampleendoffs
    local SAMPLELEN = note_layer_t.SAMPLELEN
    if not (SAMPLELEN and SAMPLELEN > 0) then return end
    
    local rel_length = instrument_sampleendoffs-instrument_samplestoffs
    
    local step_value = DATA.boundarystep[EXT.CONF_stepmode].val
    
    local out_shift
    if step_value > 0 then -- seconds
      step_value_rel = step_value / SAMPLELEN
      out_shift = step_value_rel
     elseif step_value == -100 then -- search for next transient
      out_shift = DATA:Action_ShiftOffset_NextTransient(note_layer_t)
     elseif step_value < 0 then -- beats
      local step_value_beats = math.abs(step_value)
      local bpm = note_layer_t.SAMPLEBPM or 0
      if bpm == 0 then bpm = reaper.Master_GetTempo() end
      local beat_time = 60 / bpm
      out_shift = (beat_time * step_value_beats) / SAMPLELEN
    end
    
    if not out_shift then return end
    
    local outst = instrument_samplestoffs
    local outend = instrument_sampleendoffs
    
    -- shift start
      if mode == 0 then 
        outst = VF_lim(instrument_samplestoffs + out_shift*dir) 
        if EXT.CONF_stepmode_keeplen==1 then outend = VF_lim(instrument_sampleendoffs + out_shift*dir) end
    -- shift start to boundary
       elseif mode == 2 then
        if dir == -1 then 
          out_shift = -instrument_samplestoffs
         else
          out_shift = instrument_sampleendoffs-instrument_samplestoffs
        end 
        outst = VF_lim(instrument_samplestoffs + out_shift) 
        if EXT.CONF_stepmode_keeplen==1 then outend = VF_lim(instrument_sampleendoffs + out_shift) end     
        
    -- shift end
       elseif mode == 1 then 
         outend  = VF_lim(instrument_sampleendoffs + out_shift*dir) 
         if EXT.CONF_stepmode_keeplen==1 then outst = VF_lim(instrument_samplestoffs + out_shift*dir) end
    -- shift end to doundary
       elseif mode == 3 then 
        if dir == -1 then 
          out_shift = - instrument_sampleendoffs
         else
          out_shift = 1-instrument_sampleendoffs
        end
        outend  = VF_lim(instrument_sampleendoffs + out_shift) 
        if EXT.CONF_stepmode_keeplen==1 then outst = VF_lim(instrument_samplestoffs + out_shift) end   
      end
    
    if outend - outst < 0.01 then return end
    note_layer_t.instrument_samplestoffs = outst
    note_layer_t.instrument_sampleendoffs = outend
    TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 13, outst ) 
    TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 14, outend )
    DATA.upd = true
    DATA.peakscache[note]  = nil
  end  
  
  ------------------------------------------------------------------------------------------   
  function DATA:CollectDataInit_PluginParametersMapping_Get() 
    DATA.plugin_mapping = table.loadstring(VF_decBase64(EXT.CONF_plugin_mapping_b64)) or {}
  end
  ------------------------------------------------------------------------------------------   
  function DATA:CollectDataInit_PluginParametersMapping_Set() 
    EXT.CONF_plugin_mapping_b64 = VF_encBase64(table.savestring(DATA.plugin_mapping))
    EXT:save()
  end  
  
  --------------------------------------------------------------------  
  function DATA:Auto_LoopSlice_CDOE(item) 
  
    local FFTsz = 512
    local window_overlap = 2
    local ED_sum = {positions = {}, values = {}, onsets = {}}
     
    -- init pointers
    local item_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
    local take = GetActiveTake(item)
    if not take or TakeIsMIDI(take ) then return end 
    local pcm_src  =  GetMediaItemTake_Source( take )
    local SR = reaper.GetMediaSourceSampleRate( pcm_src )  
    local window_spls = FFTsz
    local window_sec = window_spls / SR
    local samplebuffer = reaper.new_array(window_spls) 
    local accessor = CreateTakeAudioAccessor( take )
    
    -- grab [FFT magnitude & phase] per frame -> bin
    
    local i = 0
    local FFTt = {}
    for pos_seek = 0, item_len, window_sec/window_overlap do
      GetAudioAccessorSamples( accessor, SR, 1, pos_seek, window_spls, samplebuffer ) 
      
      local rms = 0
      for i = 1, window_spls do rms = rms + math.abs(samplebuffer[i]) end rms = rms / window_spls
      
      samplebuffer.fft_real(FFTsz, true, 1 ) 
      i = i + 1
      ED_sum.positions[i] = pos_seek--math.max(pos_seek +  window_sec/window_overlap)
      FFTt[i] = {rms=rms} 
      local bin2 = -1
      for val = 1, FFTsz-2, 2 do 
        local Re = samplebuffer[val]
        local Im = samplebuffer[val + 1]
        local magnitude = math.sqrt(Re^2 + Im^2)
        local phase = math.atan(Im, Re)
        local bin = 1 + (val - 1)/2
        FFTt[i][bin] = {magnitude=magnitude,phase=phase}
      end
    end
    samplebuffer.clear()
    reaper.DestroyAudioAccessor( accessor )
    
    -- calculate CDOE difference
    local sz = #FFTt[1]
    test = sz
    local hp = 30 -- DC offset / HP
    local lp = sz--math.floor(sz*0.5) -- slightly low pass
    ED_sum.values[1] = 0
    ED_sum.values[2] = 0
    for frame = 3, #FFTt do
      local rms = FFTt[frame].rms
      local t = FFTt[frame]
      local t_prev = FFTt[frame-1]
      local t_prev2 = FFTt[frame-2] 
      local sum = 0
      local Euclidean_distance, magnitude_targ, Im1, Im2, Re1, Re2
      for bin = hp, lp do
        magnitude_targ = t_prev[bin].magnitude
        phase_targ = t_prev[bin].phase + (t_prev[bin].phase - t_prev2[bin].phase) 
        Re2 = magnitude_targ * math.cos(phase_targ)
        Im2 = magnitude_targ * math.sin(phase_targ)
        Re1 = t[bin].magnitude * math.cos(t[bin].phase)
        Im1 = t[bin].magnitude * math.sin(t[bin].phase) 
        Euclidean_distance = math.sqrt((Re2 - Re1)^2 + (Im2 - Im1)^2)
        sum = sum + Euclidean_distance --*(1-bin/sz) -- weight to highs
      end 
      ED_sum.values[frame] = sum--^0.9 --* rms
    end 
    
    local szED = #ED_sum.values
    ED_sum.values[szED] =0
    --VF_Weight()
    --VF_NormalizeT(ED_sum.values)
    
    -- build threshold env
    ED_sum.weight_threshold = {}
    local threshold_area = DATA.loopcheck_trans_area_frame -- forward frame
    for i = 1, szED-threshold_area do 
      ED_sum.values[i] = ED_sum.values[i]
      local rms = 0
      for i2 = i, i+threshold_area do rms=rms+ED_sum.values[i2] end rms = rms / threshold_area
      ED_sum.weight_threshold[i] = rms 
    end
    for i = szED-threshold_area, szED do ED_sum.weight_threshold[i] = ED_sum.weight_threshold[szED-threshold_area] end
    ED_sum.values[1] = ED_sum.values[3]
    ED_sum.values[2] = ED_sum.values[3]
    
    VF_NormalizeT(ED_sum.weight_threshold)
    VF_NormalizeT(ED_sum.values, 0.001)
    -- apply compression
    for i = 1, szED do
      ED_sum.values[i] = ED_sum.values[i] * (1-ED_sum.weight_threshold[i])
    end
    VF_NormalizeT(ED_sum.values)

    -- get onsets
    local minval = 0.01
    local minareasum = DATA.loopcheck_trans_area_frame * minval
    local sz = #ED_sum.values 
    local val = 0 
    local lastid = 1
    for i = 1, sz-DATA.loopcheck_trans_area_frame do
      val = 0 
      if i==1 then  val = 1  end
      local curval = ED_sum.values[i]
      local arearms = 0
      local minpeak = math.huge
      local maxpeak = 0
      local minpeakID = i
      local maxpeakID = i
      for i2 = i, i+DATA.loopcheck_trans_area_frame do
        arearms = arearms + ED_sum.values[i2]
        if ED_sum.values[i2] > maxpeak then maxpeakID = i2 end
        maxpeak = math.max(maxpeak, ED_sum.values[i2])
        if ED_sum.values[i2] < minpeak then minpeakID = i2 end
        minpeak = math.min(minpeak, ED_sum.values[i2])
      end
      arearms = arearms / DATA.loopcheck_trans_area_frame
      if minpeak / arearms < 0.4  
        and minpeakID < maxpeakID
        and arearms > 0.2
        then 
        val = 1 
        lastid = i 
      end
      ::nextframe::
      ED_sum.onsets[i] = val
    end
    
    
    -- filter closer onsets
    for i = 1, sz-1 do
      if ED_sum.onsets[i] == 1 and ED_sum.onsets[i+1] == 1  then 
        local minpeak = math.huge
        local minpeakID = i
        for i2 = i, i+DATA.loopcheck_trans_area_frame do
          if ED_sum.values[i2] == 0 then break end
          if ED_sum.values[i2] < minpeak then minpeakID = i2 end
          minpeak = math.min(minpeak, ED_sum.values[i2])
        end
        
        for i2 = i, i+DATA.loopcheck_trans_area_frame do ED_sum.onsets[i2] =0 end
        ED_sum.onsets[minpeakID] =1 
      end
    end
    
    
    -- fine tune positions 
    local area = 0.05 -- sec
    local window_spls = math.floor(area*2 * SR)
    local samplebuffer = reaper.new_array(window_spls) 
    local accessor = CreateTakeAudioAccessor( take )
    for i = 2, sz do
      if ED_sum.onsets[i] == 1 then
        local pos_seek = ED_sum.positions[i] - area/2
        GetAudioAccessorSamples( accessor, SR, 1, pos_seek, window_spls, samplebuffer )
        local minval = math.huge
        local pos_min = ED_sum.positions[i]
        local val
        for i2 = 1, window_spls do
          val = math.abs(samplebuffer[i2])
          if val < minval then ED_sum.positions[i] = pos_seek + i2/SR end
          minval = math.min(minval, val)
        end
      end
    end
    samplebuffer.clear()
    reaper.DestroyAudioAccessor( accessor )
    
    -- fine tune
    return ED_sum
  end  
  ---------------------------------------------------------------------  
  function DATA:Auto_LoopSlice_extract_loopt(filename) 
    local loop_t= {}
    
    -- check by name
    local filter = EXT.CONF_loopcheck_filter:lower():gsub('%s+','')
    local words = {}
    for word in filter:gmatch('[^,]+') do words[word] = true end
    local test_filename = filename:lower():gsub('[%s%p]+','')
    for word in pairs(words) do if test_filename:match(word) then return end end
    
    -- build PCM
    local PCM_Source = PCM_Source_CreateFromFile( filename )
    local srclen, lengthIsQN = GetMediaSourceLength( PCM_Source )
    if lengthIsQN ==true or (srclen < EXT.CONF_loopcheck_minlen or srclen > EXT.CONF_loopcheck_maxlen) then 
      --PCM_Source_Destroy( PCM_Source )
      return
    end
    
    -- get bpm
    local bpm = 60 / (srclen / 4)
    if bpm < 80 then 
      bpm = bpm *2 
     elseif bpm >180 then 
      bpm = bpm /2
     else
      bpm = 0
    end
    if bpm%1 > 0.98 then  bpm = math.ceil(bpm) elseif bpm%1 < 0.02 then  bpm = math.floor(bpm) end
    
    -- add temp stuff for audio read
    local tr_cnt = CountTracks(DATA.proj)
    InsertTrackInProject( DATA.proj, tr_cnt, 0 )
    local temp_track  = GetTrack(DATA.proj, tr_cnt) 
    local temp_item = AddMediaItemToTrack( temp_track )
    local temp_take = AddTakeToMediaItem( temp_item )
    SetMediaItemTake_Source( temp_take, PCM_Source )
    SetMediaItemInfo_Value( temp_item, 'D_POSITION', 0 )
    SetMediaItemInfo_Value( temp_item, 'D_LENGTH',srclen ) 
    local CDOE = DATA:Auto_LoopSlice_CDOE(temp_item)
    if DATA.loopcheck_testdraw == 1 then
      DATA.temp_CDOE_arr = reaper.new_array(CDOE.values)
      DATA.temp_CDOE_arr2 = reaper.new_array(CDOE.onsets)
    end
    DeleteTrack( temp_track )
    
    -- form start/end offset
    if not (CDOE and CDOE.positions and CDOE.onsets) then return end
    local sz = #CDOE.onsets
    local frame_st
    for i = 1, sz do
      if CDOE.onsets[i] == 1 or i==sz then 
        if not frame_st then 
          frame_st = i 
         else
          local startframe = frame_st+2
          if frame_st == 1 then startframe = 1 end
          local endframe = math.min(sz,i+2)
          
          local pos_sec_st = CDOE.positions[startframe]
          local pos_sec_end = CDOE.positions[endframe]
          if pos_sec_st and pos_sec_end then
            local SOFFS = pos_sec_st / srclen
            local EOFFS = pos_sec_end / srclen
            loop_t[#loop_t+1] = {
              SOFFS = SOFFS,
              EOFFS = EOFFS,
              debug_len = pos_sec_end - pos_sec_st
            }
            frame_st = i
          end
        end
      end
    end
    
    
    if #loop_t<2 then return end
    
    return loop_t, bpm, srclen
  end
  ---------------------------------------------------------------------  
  function DATA:Auto_LoopSlice_ShareDATA(loop_t,note,filename,bpm) 
    PreventUIRefresh( 1 )
    Undo_BeginBlock2( DATA.proj)
    for i = 1, #loop_t do 
      local outnote = note + i-1  
      if outnote > 127 then break end
      loop_t[i].outnote = outnote 
      local custom_release_sec, custom_decay_sec, custom_sustain
      --[[if EXT.CONF_loopcheck_smoothend_use == 1 then
        local slicelen = (loop_t[i].EOFFS - loop_t[i].SOFFS) * srclen
        custom_release_sec = EXT.CONF_loopcheck_smoothend
        custom_decay_sec =  slicelen - EXT.CONF_loopcheck_smoothend
        custom_sustain = 0
      end]] 
      
      DATA:DropSample(
          filename, 
          outnote, 
          {
            layer=1,
            SOFFS=loop_t[i].SOFFS,
            EOFFS=loop_t[i].EOFFS,
            tr_name_add = '- slice '..i,
            custom_release_sec = custom_release_sec,
            custom_decay_sec = custom_decay_sec,
            custom_sustain = custom_sustain,
            SAMPLEBPM = bpm,
          }
        )
    end
    Undo_EndBlock2( DATA.proj , 'RS5k manager - drop and slice loop to pads', 0xFFFFFFFF ) 
    PreventUIRefresh( -1 )
  end
  --------------------------------------------------------------------- 
  function DATA:Auto_LoopSlice_CreateMIDI(stretchmidi, srclen,loop_t,note, bpm)
    if not (note and srclen and loop_t ) then return end
    if  DATA.MIDIbus and DATA.MIDIbus.tr_ptr and DATA.MIDIbus.valid == true then
      local new_item = CreateNewMIDIItemInProj( DATA.MIDIbus.tr_ptr, GetCursorPosition(), GetCursorPosition() + srclen )
      local take = GetActiveTake(new_item)
      for i = 1, #loop_t do 
        local outnote = note + i-1 
        if outnote > 127 then break end
        local pos_st = loop_t[i].SOFFS * srclen
        local pos_end = loop_t[i].EOFFS * srclen
        local startppqpos = MIDI_GetPPQPosFromProjTime( take, pos_st +GetCursorPosition()  )
        local endppqpos = MIDI_GetPPQPosFromProjTime( take, pos_end +GetCursorPosition()  )
        MIDI_InsertNote( take, false, false, startppqpos, endppqpos, 0, outnote, 100, false ) 
      end
      MIDI_Sort( take )
      
      SetMediaItemInfo_Value( new_item, 'B_LOOPSRC', 1)
      
      if stretchmidi == true and bpm ~= 0 then 
        local bpm_proj = Master_GetTempo()
        local outrate = bpm_proj / bpm
        if outrate > 2 then 
          outrate = outrate / 2 
         elseif outrate < 0.5 then 
          outrate = outrate * 2 
        end
        
        
        if outrate > 0.5 and outrate < 2 then 
          SetMediaItemTakeInfo_Value( take, 'D_PLAYRATE', outrate )
          SetMediaItemInfo_Value( new_item, 'D_LENGTH',srclen/outrate ) 
        end
      end
    end
  end
  ---------------------------------------------------------------------  
  function DATA:Auto_LoopSlice(note, count)   -- test audio framgment if it contain slices
    function __f_loopslice() end
    if EXT.CONF_loopcheck&1==0 then return end  
    
    local loop_t = {}
    local createMIDI,createPattern
    local retval, filename = reaper.ImGui_GetDragDropPayloadFile( ctx, 0 )
    local bpm, srclen
    
    -- if ask then stop to RESTORE collected data
      if DATA.temp_loopslice_askforadd and DATA.temp_loopslice_askforadd.confirmed == true then 
        loop_t = CopyTable(DATA.temp_loopslice_askforadd.loop_t)
        note = DATA.temp_loopslice_askforadd.note
        filename = DATA.temp_loopslice_askforadd.filename
        bpm = DATA.temp_loopslice_askforadd.bpm
        srclen = DATA.temp_loopslice_askforadd.srclen
        createMIDI = DATA.temp_loopslice_askforadd.createMIDI
        stretchmidi = DATA.temp_loopslice_askforadd.stretchmidi
        createPattern = DATA.temp_loopslice_askforadd.createPattern
        
        DATA.temp_loopslice_askforadd = nil
        goto applycollecteddata
       else 
        loop_t, bpm, srclen = DATA:Auto_LoopSlice_extract_loopt(filename) 
      end
    
    
    -- if ask then stop to SAVE collected data
      if not DATA.temp_loopslice_askforadd then 
        if not (loop_t and #loop_t>1) then return end 
        DATA.temp_loopslice_askforadd = 
        { note=note,
          loop_t=loop_t,
          filename = filename,
          bpm = bpm,
          srclen =srclen,
          createMIDI = false,
          stretchmidi = true,
          createPattern = false,
        }
        
        local do_not_share = true
        return false, do_not_share
      end 
    
    ::applycollecteddata::
    DATA:Auto_LoopSlice_ShareDATA(loop_t,note,filename,bpm)  
    if createMIDI==true then 
      DATA:Auto_LoopSlice_CreateMIDI(stretchmidi, srclen,loop_t, note, bpm) 
     elseif createPattern==true then 
      DATA:Auto_LoopSlice_CreatePattern(loop_t) 
    end
    
    if #loop_t>1 then return true end
    
  end
  
  ------------------------------------------------------------------------------------------ 
  function DATA:CollectDataInit_LoadCustomPadStuff() 
    DATA.padcustomnames = {}
    DATA.padautocolors = {}
    
    local str = EXT.UI_padcustomnames
    if str == '' then return end
    for pair in str:gmatch('[%d]+%=".-"') do
      local id, val = pair:match('([%d]+)="(.-)%"')
      if id and val then 
        id = tonumber(id)
        if id then DATA.padcustomnames[id] = val end
      end
    end
    
    local str = EXT.UI_padautocolors
    if str == '' then return end
    for pair in str:gmatch('[%d]+%=".-"') do
      local id, val = pair:match('([%d]+)="(.-)%"')
      if id and val then 
        id = tonumber(id)
        if id then DATA.padautocolors[id] = tonumber(val) end
      end
    end
    
    
  end
  ------------------------------------------------------------------------------------------   
  function DATA:CollectDataInit_ReadDBmaps()
    DATA.database_maps = {}
    for i = 1,8 do
      DATA.database_maps[i] = {}
      local dbmapchunk_b64 = EXT['CONF_database_map'..i]
      if dbmapchunk_b64 then 
        local dbmapchunk = VF_decBase64(dbmapchunk_b64)
        local map = {}
        local dbname = 'Untitled '..i
        for line in dbmapchunk:gmatch('[^\r\n]+') do 
          if line:match('NOTE(%d+)') then 
            local note = line:match('NOTE(%d+)')
            if note then note =  tonumber(note) end
            if note then
              local params = {}
              for param in line:gmatch('%<.-%>.-%<%/.-%>') do 
                local key = param:match('%<(.-)%>')
                local val = param:match('%<.-%>(.-)%<%/.-%>')
                params[key] = tonumber(val ) or val
              end
              map[note] = params
            end
          end
          if line:match('DBNAME (.*)') then dbname = line:match('DBNAME (.*)') end
        end
        
        DATA.database_maps[i] = {
          valid = true, 
          dbmapchunk = dbmapchunk,
          map=map, 
          dbname = dbname}
                    
      end
    end
  end
  ------------------------------------------------------------------------------------------   
  function DATA:Sampler_ImportSelectedItems() 
    local note =  0
    if  DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE then note = DATA.parent_track.ext.PARENT_LASTACTIVENOTE end
    
    
    Undo_BeginBlock2(DATA.proj)
    local items_to_remove = {}
    for  i = 1, CountSelectedMediaItems(-1) do
      local drop_data = {layer=1}
      local item = GetSelectedMediaItem(-1,i-1)
      
      local retval, GUID = reaper.GetSetMediaItemInfo_String( item, 'GUID', '', false ) 
      items_to_remove[GUID] = true
      
      local tk = GetActiveTake( item ) 
      if not(tk and not TakeIsMIDI( tk )) then goto nextitem end
      
      local section,src_len 
      local src = GetMediaItemTake_Source( tk)
      local src_len =  GetMediaSourceLength( src )
      
      -- handle reversed source
      if not src or (src and GetMediaSourceType( src ) == 'SECTION') then  
        parent_src =  GetMediaSourceParent( src ) 
        src_len =  GetMediaSourceLength( parent_src )
       else
        parent_src = src
      end
      
      -- handle section
      if parent_src then
        if GetMediaSourceType( src ) == 'SECTION' then 
          local retval, offs, len, rev = reaper.PCM_Source_GetSectionInfo( src )
          drop_data.SOFFS = offs / src_len
          drop_data.EOFFS = (offs + len)/ src_len
         elseif GetMediaSourceType( src ) == 'WAVE' then
          local take = GetActiveTake(item)
          local D_STARTOFFS = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
          local D_LENGTH = GetMediaItemInfo_Value( item, 'D_LENGTH' )
          local D_PLAYRATE = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
          drop_data.SOFFS = D_STARTOFFS  / src_len
          drop_data.EOFFS = (D_STARTOFFS + D_LENGTH*D_PLAYRATE)/ src_len
        end
      end  
      
      if parent_src then 
        local filenamebuf = GetMediaSourceFileName( parent_src )
        if filenamebuf then 
          filenamebuf = filenamebuf:gsub('\\','/')
          DATA:DropSample(filenamebuf,note+i-1, drop_data) 
        end
      end
      
      ::nextitem::
    end
    
    if EXT.CONF_importselitems_removesource == 1 then
      for itemGUID in pairs(items_to_remove ) do 
        local it = VF_GetMediaItemByGUID(DATA.proj, itemGUID)
        if it then DeleteTrackMediaItem(  reaper.GetMediaItemTrack( it ), it ) end
      end
    end
    Undo_EndBlock2(DATA.proj, 'RS5k manager - import selected items', 0xFFFFFFFF)
    
    UpdateArrange()
  end
  ---------------------------------------------------------------------
  function VF_GetMediaItemByGUID(optional_proj, itemGUID)
    local optional_proj0 = optional_proj or -1
    local itemCount = CountMediaItems(optional_proj);
    for i = 1, itemCount do
      local item = GetMediaItem(0, i-1);
      local retval, stringNeedBig = GetSetMediaItemInfo_String(item, "GUID", '', false)
      if stringNeedBig  == itemGUID then return item end
    end
  end 
  -------------------------------------------------------------------------------- 
  function DATA:Auto_Reposition_TrackGetSelection()
    DATA.TrackSelection = {}
    local cnt = CountTracks(-1)
    for i = 1, cnt do
      local track = GetTrack(-1,i-1)
      local GUID = GetTrackGUID( track )
      if IsTrackSelected( track ) then DATA.TrackSelection[GUID] = true end
    end
  end
  -------------------------------------------------------------------------------- 
  function DATA:Auto_Reposition_TrackRestoreSelection()
    local cnt = CountTracks(-1)
    for i = 1, cnt do
      local track = GetTrack(-1,i-1)
      local GUID = GetTrackGUID( track )
      SetTrackSelected( track, DATA.TrackSelection[GUID]==true )
    end 
    DATA.TrackSelection = {}
  end
  
  --------------------------------------------------------------------------------
  function DATA:CollectData_Always_StepPositions() 
    if not (DATA.proj and reaper.ValidatePtr(DATA.proj, 'ReaProject*')) then return end
    if not (DATA.parent_track and DATA.parent_track.valid == true and DATA.seq and DATA.seq.valid == true and DATA.seq.tk_ptr ) then return end
    DATA.seq.active_step = {}
    
    local curpos = GetCursorPositionEx( DATA.proj )--+0.01
    if GetPlayStateEx( DATA.proj  )&1==1 then curpos = GetPlayPositionEx( DATA.proj ) end
    
    local beats, measures, cml, curpos_fullbeats, cdenom = TimeMap2_timeToBeats( DATA.proj, curpos )
    local it_pos = DATA.seq.it_pos
    local it_pos_compensated = DATA.seq.it_pos_compensated
    local it_len = DATA.seq.it_len
    local it_end = it_pos + it_len
    if not (curpos>=it_pos and curpos<=it_end) then return end
    
    
    
    local patternsteplen = 0.25
    local patternlen =DATA.seq.ext.patternlen or 16
    local beats, measures, cml, patstart_fullbeats, cdenom = TimeMap2_timeToBeats( DATA.proj, it_pos_compensated ) 
    local pat_progress = (((curpos_fullbeats-patstart_fullbeats)/patternsteplen)/patternlen)%1
    local pat_beats_com = patternlen*patternsteplen
    DATA.seq.active_pat_progress = pat_progress
    DATA.seq.active_pat_step = math.floor(pat_progress*patternlen)+1
    
    for note in pairs(DATA.children) do 
      local step_cnt = DATA.seq.ext.children[note].step_cnt or 16
      local steplength = DATA.seq.ext.children[note].steplength
      local available_steps_per_pattern = pat_beats_com / steplength
      local activestep = math.floor(available_steps_per_pattern * pat_progress)+1
      if step_cnt < patternlen then 
        activestep = activestep %step_cnt
        if activestep == 0 then activestep = step_cnt end
      end
      
      --DATA.children[note].activestep = activestep
      --DATA.children[note].available_steps_per_pattern = available_steps_per_pattern
      DATA.seq.active_step[note] = activestep
    end
    
    
    DATA.temp_pos_progress = pat_progress
  end
  
    --------------------------------------------------------------------------------  
  function VF_Open_URL(url) if GetOS():match("OSX") then os.execute('open "" '.. url) else os.execute('start "" '.. url)  end  end    
