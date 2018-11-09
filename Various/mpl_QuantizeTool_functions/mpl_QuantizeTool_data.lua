-- @description QuantizeTool_data
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  
  ---------------------------------------------------  
  function CheckUpdates(obj, conf, refresh)
  
    -- force by proj change state
      obj.SCC =  GetProjectStateChangeCount( 0 ) 
      if not obj.lastSCC then 
        refresh.GUI_onStart = true  
        refresh.data = true
       elseif obj.lastSCC and obj.lastSCC ~= obj.SCC then 
        refresh.data = true
        refresh.GUI = true
        refresh.GUI_WF = true
      end 
      obj.lastSCC = obj.SCC
      
    -- window size
      local ret = HasWindXYWHChanged(obj)
      if ret == 1 then 
        refresh.conf = true 
        refresh.data = true
        refresh.GUI_onStart = true 
        refresh.GUI_WF = true       
       elseif ret == 2 then 
        refresh.conf = true
        refresh.data = true
      end
  end
  --------------------------------------------------- 
  function Data_GetMarkers(data, table_name)
    local  retval, num_markers, num_regions = CountProjectMarkers( 0 )
    for i = 1, num_markers do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber = EnumProjectMarkers2( 0, i-1 )
      local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
      local val = tonumber(name)
      if not (val and (val >=-1 and val <=2))  then val = 1 end
      data[table_name][i] = {pos = fullbeats,
                              val = val,
                              srctype = 'projmark'  }
    end
  end
  --------------------------------------------------- 
  function Data_GetTempoMarkers(data, table_name)
    local  cnt = CountTempoTimeSigMarkers( 0 )
    for i = 1, cnt do
      local  retval, pos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = GetTempoTimeSigMarker( 0, i-1 )
      local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
      data[table_name][i] = {pos = fullbeats,
                              val = 1,
                              srctype = 'tempomark'  }
    end  
  end
  ---------------------------------------------------    
  function Data_ApplyStrategy_reference(conf, obj, data, refresh, mouse, strategy)
    data.ref = {}
    data.ref_pat = {}
    
    if strategy.ref_positions&1 ==1 and strategy.ref_selitems&1==1 then Data_GetItems(data, 'ref', strategy.ref_selitems)  end       
    if strategy.ref_positions&1 ==1 and strategy.ref_envpoints&1==1 then Data_GetEP(data, 'ref')  end
    if strategy.ref_positions&1 ==1 and strategy.ref_midi&1==1 then Data_GetMIDI(data, strategy, 'ref', strategy.ref_midi)  end
    if strategy.ref_positions&1 ==1 and strategy.ref_strmarkers&1==1 then Data_GetSM(data, 'ref')  end
    if strategy.ref_positions&1 ==1 and strategy.ref_marker&1==1 then Data_GetMarkers(data, 'ref')  end
    if strategy.ref_positions&1 ==1 and strategy.ref_timemarker&1==1 then Data_GetTempoMarkers(data, 'ref')  end
    
    if strategy.ref_positions&1 ==1 and strategy.ref_editcur&1==1 then 
      data.ref[1] = { pos = ({TimeMap2_timeToBeats( 0,  GetCursorPositionEx( 0 ) )})[4],
                      val = 1}
    end
    if strategy.ref_pattern&1==1 then Data_ApplyStrategy_reference_pattern(conf, obj, data, refresh, mouse, strategy) end  
    
    --[[if strategy.ref_values&2==2 then table.sort(data.ref, function (a,b) return a.pos and b.pos and a.pos<b.pos end) end
    Data_ApplyStrategy_reference_val(conf, obj, data, refresh, mouse, strategy)
    if strategy.ref_values&2~=2 then table.sort(data.ref, function (a,b) return a.pos and b.pos and a.pos<b.pos end) end    
    if strategy.ref_pattern&1==1 then Data_ApplyStrategy_reference_pattern(conf, obj, data, refresh, mouse, strategy) end   ]]   
  end
  --------------------------------------------------- 
  function Data_PatternParseRGT(data, strategy, content, take_len)
    local len = content:match('Number of beats in groove: (%d+)')
    if len and take_len  and tonumber(len) then strategy.ref_pattern_len = tonumber(len) end
    local pat = '[%d%.%-%e]+'
    for line in content:gmatch('[^\r\n]+') do
    
      -- test first symb is number
        if not line:sub(1,1):match('%d') then goto next_line end
        
      -- pos
        local pos = tonumber(line:match(pat))
        local val = 1
        
        local check_val = line:match(pat..'%s('..pat..')')
        if check_val and tonumber(check_val) then val = tonumber(check_val) end
        
      if pos and val then data.ref_pat[#data.ref_pat +1] = {  pos = pos, val = val} end
      
      
      ::next_line::
    end
  end
  --------------------------------------------------- 
  function Data_ApplyStrategy_reference_pattern(conf, obj, data, refresh, mouse, strategy)
    if strategy.ref_pattern&2 == 2 then -- generate pattern
      if strategy.ref_pattern_gensrc&1==1 then -- cur grid
        local retval, divisionIn, swingmodeIn, swingamtIn = GetSetProjectGrid( 0, false )
        local id = 0
        for beat = 1, strategy.ref_pattern_len + 1, divisionIn*4 do
          local outpos = beat-1
          if swingamtIn ~= 0 then 
            if id%2 ==1 then outpos = outpos + swingamtIn * divisionIn*2 end
          end
          data.ref_pat[#data.ref_pat + 1] = {pos = outpos, val = 1}
          id = id + 1
        end
      end
    end
    
    if strategy.ref_pattern&2 == 0 then -- from file
      local name = strategy.ref_pattern_name
      local fp =  GetResourcePath()..'/Grooves/'..name..'.rgt'
      local f = io.open(fp, 'r')
      local content
      if f then 
        content = f:read("*all")
        f:close()
      end
      if not content or content == '' then return else Data_PatternParseRGT(data, strategy, content, false) end
    end
  end

  ---------------------------------------------------    
  function Data_ExportPattern(conf, obj, data, refresh, mouse, strategy, persist)
    if data.ref_pat == 0 then return end
    local str = 'Version: 1'..
          '\nNumber of beats in groove: '..tostring(strategy.ref_pattern_len)..
          '\nGroove: '..#data.ref_pat..' positions'
          
    for i = 1, #data.ref_pat do  str = str..'\n'..data.ref_pat[i].pos..' '..data.ref_pat[i].val  end
    local name
    if persist then name = 'last_touched' else name = strategy.ref_pattern_name end
    local out_fp =  GetResourcePath()..'/Grooves/'..name..'.rgt'
    local f = io.open(out_fp, 'w')
    if f then 
      f:write(str)
      f:close()
    end
    
  end
  --------------------------------------------------- 
  function Data_GetItems(data, table_name, mode) 
      for selitem = 1, CountSelectedMediaItems(0) do
        local item =  GetSelectedMediaItem( 0, selitem-1 )
        local take = GetActiveTake(item)
        local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
        
        local position_has_snap_offs, snapoffs_sec
        if mode&2==2 then --snap offset
          position_has_snap_offs = true
          snapoffs_sec = GetMediaItemInfo_Value( item, 'D_SNAPOFFSET' )
          pos = pos + snapoffs_sec
        end
        
        
        local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
        if not data[table_name][selitem] then data[table_name][selitem] = {} end
        local val = GetMediaItemInfo_Value( item, 'D_VOL' )
        data[table_name][selitem].pos = fullbeats
        data[table_name][selitem].position_has_snap_offs = position_has_snap_offs
        data[table_name][selitem].pos_beats = beats
        data[table_name][selitem].snapoffs_sec = snapoffs_sec 
        data[table_name][selitem].GUID = BR_GetMediaItemGUID( item )
        data[table_name][selitem].srctype='item'
        data[table_name][selitem].val =val
      end      
  end  
  --------------------------------------------------- 
  function Data_GetSM(data, table_name) 
    data[table_name].src_cnt = 0
    
    for i = 1, CountSelectedMediaItems(0) do
      local item =  GetSelectedMediaItem( 0, i-1 )
      if not item then return end
      local it_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local it_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local take = GetActiveTake(item)
      local rate  = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
      if not TakeIsMIDI(take) then
        for idx = 1, GetTakeNumStretchMarkers( take ) do
          local retval, sm_pos, srcpos_sec = GetTakeStretchMarker( take, idx-1 )
          local slope = GetTakeStretchMarkerSlope( take, idx-1 )
          local pos = it_pos + sm_pos / rate
          local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
                
          local ignore_search = false  
          if sm_pos < 0.0001 or math.abs(sm_pos - it_len) < 0.001 then ignore_search = true end -- boundary SM
          if not ignore_search then data[table_name].src_cnt = data[table_name].src_cnt + 1 end
                       
          data[table_name][#data[table_name]+1] =
                  { pos = fullbeats,
                    pos_beats = beats,
                    sm_pos_sec=sm_pos,
                    srcpos_sec = srcpos_sec,
                    slope=slope,
                    srctype='strmark',
                    val =1,
                    ignore_search = ignore_search,
                    GUID = BR_GetMediaItemTakeGUID( take ),
                    it_pos=it_pos,
                    it_len = it_len,
                    tk_rate = rate,
                    
                }
        end
      end 
    end     
  end   
  --------------------------------------------------- 
  function Data_GetMIDI_perTake(data, strategy, table_name, take)
    if not take or not ValidatePtr2( 0, take, 'MediaItem_Take*' ) or not TakeIsMIDI(take) then return end
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    if not gotAllOK then return end
    local s_unpack = string.unpack
    local s_pack   = string.pack
    local MIDIlen = MIDIstring:len()
    local offset, flags, msg1
    local ppq_pos, nextPos, prevPos, idx = 0, 1, 1 , 0
    while nextPos <= MIDIlen do  
      prevPos = nextPos
      offset, flags, msg1, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
      idx = idx + 1
      ppq_pos = ppq_pos + offset
      local selected = flags&1==1
      local pos_sec = MIDI_GetProjTimeFromPPQPos( take, ppq_pos )
      local beats, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( 0, pos_sec )
      local CClane, pitch, CCval,vel, pitch_format
      local isNoteOn = msg1:byte(1)>>4 == 0x9
      local isNoteOff = msg1:byte(1)>>4 == 0x8
      local isCC = msg1:byte(1)>>4 == 0xB
      local chan = 1+(msg1:byte(1)&0xF)

      --[[if mode == 1 and isNoteOn and selected then -- reference NoteOn
        data[table_name][#data[table_name]+1] = {pos = fullbeats,
                                 pos_beats = beats,
                                 val = msg1:byte(2)/127
                                 }
      
       elseif mode == -1 then]]
      local ignore_search = true
      
      if strategy.ref_midi_msgflag&1==1  and isNoteOn then ignore_search = false end
      if strategy.ref_midi_msgflag&2==2  and isNoteOff then ignore_search = false end
      
      if not ignore_search then data[table_name].src_cnt = data[table_name].src_cnt + 1 end
      data[table_name][#data[table_name]+1] = 
                          {       pos = fullbeats,
                                  pos_beats = beats,
                                  pitch = msg1:byte(2)/127,
                                  flags=flags,
                                  msg1=msg1,
                                  ppq_pos=ppq_pos,
                                  ignore_search = ignore_search,
                                  offset=offset,
                                  GUID = BR_GetMediaItemTakeGUID( take ),
                                  srctype = 'MIDIEvnt'
                                 }
      
    end   
  end  
  --------------------------------------------------- 
  function Data_GetMIDI(data, strategy, table_name, mode) 
  
    data[table_name].src_cnt = 0
    
    if mode&2 == 0 then -- MIDI editor
      local ME = MIDIEditor_GetActive()
      local take = MIDIEditor_GetTake( ME ) 
      Data_GetMIDI_perTake(data, strategy, table_name, take)   
     elseif   mode&2 == 2 then -- selected takes
      for i = 1, CountSelectedMediaItems(0) do
        local item = GetSelectedMediaItem(0,i-1)
        local take = GetActiveTake(item)
        Data_GetMIDI_perTake(data,strategy, table_name, take) 
      end
    end
    
  end
  ---------------------------------------------------
  function Data_Execute_Align_MIDI(conf, obj, data, refresh, mouse, strategy) 
    
    if data.src.src_cnt < 1 then return end
    
    -- sort atkes
    local takes_t = {}
    for i = 1 , #data.src do
      local t = data.src[i]
      if not takes_t [t.GUID] then takes_t [t.GUID] = {} end
        takes_t [t.GUID] [#takes_t [t.GUID] + 1 ]  = CopyTable(t)
      end 
    
    -- loop takes
    for GUID in pairs(takes_t) do
      local take =  GetMediaItemTakeByGUID( 0, GUID )
      if take then
    
        -- convert out_pos to ppq
        for i = 1, #takes_t[GUID] do
          local t = takes_t[GUID][i]
          
          if not t.ignore_search and t.out_pos then
            local out_pos = t.pos + (t.out_pos - t.pos)*strategy.exe_val1
            local out_pos_sec = TimeMap2_beatsToTime( 0, out_pos)
            t.ppq_posOUT = MIDI_GetPPQPosFromProjTime( take, out_pos_sec )
            for i2 = i+1, #takes_t[GUID] do
              local t2 = takes_t[GUID][i2]
              if t2.msg1:byte(1)>>4 == 0x8 and t2.msg1:byte(2)  == t.msg1:byte(2) then
                t2.ppq_posOUT = t2.ppq_pos +  (t.ppq_posOUT-t.ppq_pos)
                break
              end
            end
           else
            if not t.ppq_posOUT then t.ppq_posOUT = t.ppq_pos end
          end
          
        end
        
          
        
        -- return back all stuff
        local str_per_msg  = ''
        for i = 1, #takes_t[GUID] do
          local offset
          local t = takes_t[GUID][i]
          if i ==1 then offset = t.offset  + (t.ppq_posOUT - t.ppq_pos) else
            offset = t.ppq_posOUT - takes_t[GUID][i-1].ppq_posOUT
          end
          str_per_msg = str_per_msg.. string.pack("i4Bs4", math.modf(offset),  t.flags , t.msg1)
        end
        
        MIDI_SetAllEvts( take, str_per_msg )
      end
      local item =  GetMediaItemTake_Item( take )
      UpdateItemInProject( item )
    end
  end
  
  --------------------------------------------------- 
  function Data_Execute_Align_SM(conf, obj, data, refresh, mouse, strategy)
    --local take =  reaper.GetMediaItemTakeByGUID( 0, t.tkGUID ) 
    --if not take then return end
    -- collect various takes
    local takes_t = {}
    for i = 1 , #data.src do
      local t = data.src[i]
      if not takes_t [t.GUID] then takes_t [t.GUID] = {} end
        takes_t [t.GUID] [#takes_t [t.GUID] + 1 ]  = CopyTable(t)
      end 
      
    for GUID in pairs(takes_t) do
      local take =  GetMediaItemTakeByGUID( 0, GUID )
      if take then
        -- remove existed
        local cur_cnt =  GetTakeNumStretchMarkers( take )
        DeleteTakeStretchMarkers( take, 0, cur_cnt )
        for i = 1, #takes_t[GUID] do
          local t = takes_t[GUID][i]
          local out_pos
          if t.out_pos then
            local out_pos_sec = TimeMap2_beatsToTime( 0, t.out_pos )
            out_pos = lim(out_pos_sec - t.it_pos, 0, t.it_len)* t.tk_rate
            out_pos = t.sm_pos_sec + (out_pos - t.sm_pos_sec)*strategy.exe_val1
           else
            out_pos = t.sm_pos_sec
          end
          SetTakeStretchMarker( take, -1, out_pos, t.srcpos_sec )
        end
      end

      local first_t = takes_t[GUID]  [1]
      if first_t.pos_sec ~= 0 then
        SetTakeStretchMarker( take, -1, 0 )
      end
            
      local last_t = takes_t[GUID]  [#takes_t[GUID]]
      if last_t.srcpos_sec* last_t.tk_rate  ~= last_t.it_len then
        SetTakeStretchMarker( take, -1, last_t.it_len* last_t.tk_rate, last_t.it_len* last_t.tk_rate )
      end
      
      local item =  GetMediaItemTake_Item( take )
      UpdateItemInProject( item )
    end
  end      
  
  --------------------------------------------------- 
  function Data_GetEP(data, table_name) 
    local  env = GetSelectedEnvelope( 0 )
    if not env then return end
    local cnt = CountEnvelopePoints( env )
    local ptidx_cust = 0
    for ptidx = 1, cnt do
      local retval, pos, value, shape, tension, selected = GetEnvelopePoint( env, ptidx-1 )
      if selected then
        ptidx_cust = ptidx_cust + 1
        local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
        if not data[table_name][ptidx_cust] then data[table_name][ptidx_cust] = {} end
        data[table_name][ptidx_cust].pos = fullbeats
        data[table_name][ptidx_cust].pos_beats = beats
        data[table_name][ptidx_cust].ptr = env
        data[table_name][ptidx_cust].srctype='envpoint'
        data[table_name][ptidx_cust].selected = selected
        data[table_name][ptidx_cust].ID = ptidx-1
        data[table_name][ptidx_cust].shape = shape
        data[table_name][ptidx_cust].tension = tension
        data[table_name][ptidx_cust].val = value
      end
    end
  end  

  --------------------------------------------------- 
  function Data_ApplyStrategy_source(conf, obj, data, refresh, mouse, strategy)
    data.src = {}
    
    -- positions
    if strategy.src_positions&1 ==1 and strategy.src_selitems&1==1 then Data_GetItems(data, 'src', strategy.src_selitems) end   
    if strategy.src_positions&1 ==1 and strategy.src_envpoint&1==1 then Data_GetEP(data, 'src') end   
    if strategy.src_positions&1 ==1 and strategy.src_midi&1==1 then Data_GetMIDI(data, strategy, 'src', strategy.src_midi) end 
    if strategy.src_positions&1 ==1 and strategy.src_strmarkers&1==1 then Data_GetSM(data, 'src') end 
    
  end
  --------------------------------------------------- 
  function DataSearchPatternVal(conf, data, strategy, pos_src_full, pos_src_beats, val_src)
    if not data.ref_pat or not data.ref_pat[#data.ref_pat] or not data.ref_pat[#data.ref_pat].pos then return end
    local pat_ID 
    if #data.ref_pat == 1  then
      pat_ID = 1
      goto skip_to_ret_value
    end
    
    if pos_src_beats > data.ref_pat[#data.ref_pat].pos and pos_src_beats < strategy.ref_pattern_len then 
      pat_ID = #data.ref_pat
      goto skip_to_ret_value
    end

    if pos_src_beats < data.ref_pat[1].pos  then 
      pat_ID = 1
      goto skip_to_ret_value
    end
        
    for i = 2, #data.ref_pat do
      if pos_src_beats > strategy.ref_pattern_len then return end
      
      if pos_src_beats>= data.ref_pat[i-1].pos and pos_src_beats<= data.ref_pat[i].pos then
        if math.abs(pos_src_beats - data.ref_pat[i-1].pos) < math.abs(pos_src_beats - data.ref_pat[i].pos) then
          pat_ID = i-1
          goto skip_to_ret_value
         else 
          pat_ID = i
          goto skip_to_ret_value
        end
      end
      
    end
    ::skip_to_ret_value::
    if pat_ID and data.ref_pat[pat_ID] then 
      return pos_src_full - (pos_src_beats - data.ref_pat[pat_ID].pos), data.ref_pat[pat_ID].val
     else
      return pos_src_full, val_src
    end
  end
  --------------------------------------------------- 
  function Data_ApplyStrategy_actionCalculateAlign(conf, obj, data, refresh, mouse, strategy) 
      for i = 1, #data.src do        
        if data.src[i].pos and not data.src[i].ignore_search then
          if strategy.ref_pattern&1~=1 then 
            local refID = Data_brutforce_RefID(conf, data, strategy, data.src[i].pos)
            if refID and data.ref[refID] then 
              data.src[i].out_pos = data.ref[refID].pos
              data.src[i].out_val = data.ref[refID].val
            end
           else
            local pat_pos, pat_val = DataSearchPatternVal(conf, data, strategy, data.src[i].pos, data.src[i].pos_beats, data.src[i].val)
            if pat_pos and pat_val then 
              data.src[i].out_pos = pat_pos
              data.src[i].out_val = pat_val
            end
          end            
        end
      end
  end  
  --------------------------------------------------- 
  function Data_ApplyStrategy_action(conf, obj, data, refresh, mouse, strategy)    
    if not data.ref or not data.src then return end
    
    if strategy.act_action == 1 then Data_ApplyStrategy_actionCalculateAlign(conf, obj, data, refresh, mouse, strategy)  end
  end
  ---------------------------------------------------    
  function Data_brutforce_RefID(conf, data, strategy, pos_src)
    local results = #data.ref
    if results == 1 then return 1 end
    if results == 0 then return end
    
    local testpos1,testpos2
    local limID1 = 1
    local limID2 = #data.ref
    for iteration = 1, conf.iterationlim do
      results = limID2-limID1+1
      if results == 2 then
        testpos1 = data.ref[limID1].pos
        testpos2 = data.ref[limID2].pos
        if math.abs(pos_src - testpos1) < math.abs(pos_src - testpos2) then return limID1 else return limID2 end
      end
      local centerID = math.ceil(limID1 + (limID2-limID1)/2)
      local centerID_pos = data.ref[centerID].pos
      if pos_src < centerID_pos then limID2 = centerID else limID1 = centerID end
    end
    
    return
  end
  --------------------------------------------------- 
  function Data_Execute(conf, obj, data, refresh, mouse, strategy)
    if strategy.act_action == 1 then Data_Execute_Align(conf, obj, data, refresh, mouse, strategy) end
  end
  --------------------------------------------------- 
  function Data_Execute_Align_Items(conf, obj, data, refresh, mouse, strategy)
    for i = 1 , #data.src do
      local t = data.src[i]
        local it =  BR_GetMediaItemByGUID( 0, t.GUID )
        if it then 
          if t.out_pos then 
            local out_pos = t.pos + (t.out_pos - t.pos)*strategy.exe_val1
            out_pos = TimeMap2_beatsToTime( 0, out_pos)
            if t.position_has_snap_offs then 
              out_pos = out_pos - t.snapoffs_sec 
            end
            SetMediaItemInfo_Value( it, 'D_POSITION', out_pos )
          end 
          if t.out_val then
            SetMediaItemInfo_Value( it, 'D_VOL', t.val + (t.out_val - t.val)*strategy.exe_val2 )  
          end
          UpdateItemInProject( it )
        end
      end  
  end
  --------------------------------------------------- 
  function Data_Execute_Align_EnvPt(conf, obj, data, refresh, mouse, strategy)
    if not data.src[1] then return end
    local env = data.src[1].ptr
    if not env then return end
    for i = 1 , #data.src do
      local t = data.src[i]
      local out_pos = t.pos
      local out_val = t.val
      if t.out_pos then out_pos = t.pos + (t.out_pos - t.pos)*strategy.exe_val1 end
      if t.out_val then out_val = t.val + (t.out_val - t.val)*strategy.exe_val2 end
      out_pos = TimeMap2_beatsToTime( 0, out_pos)
      SetEnvelopePointEx( env, -1, t.ID, out_pos, out_val, t.shape, t.tension, t.selected, true )
    end  
    Envelope_SortPointsEx( env, -1 )
    UpdateArrange()
  end
  --------------------------------------------------- 
  function Data_Execute_Align(conf, obj, data, refresh, mouse, strategy)
    if not data.src or not data.ref then return end
    if strategy.src_selitems&1==1 then  Data_Execute_Align_Items(conf, obj, data, refresh, mouse, strategy) end
    if strategy.src_envpoint&1==1 then  Data_Execute_Align_EnvPt(conf, obj, data, refresh, mouse, strategy) end
    if strategy.src_midi&1==1 then      Data_Execute_Align_MIDI(conf, obj, data, refresh, mouse, strategy) end
    if strategy.src_strmarkers&1==1 then Data_Execute_Align_SM(conf, obj, data, refresh, mouse, strategy) end
  end
  ---------------------------------------------------   
  function Data_ShowPointsAsMarkers(conf, obj, data, refresh, mouse, strategy, passed_t0, col_str, is_pat)
    if not passed_t0 then return end
    local passed_t
    
    -- generate passed_t from pattern based on edit cursor
    if is_pat then 
      passed_t = {}
      local curpos = GetCursorPositionEx( 0 )
      local _, measures = TimeMap2_timeToBeats( 0, curpos )
      for i = 1, #passed_t0 do
        if passed_t0[i].pos <= strategy.ref_pattern_len then
          local pos_sec = TimeMap2_beatsToTime( 0, passed_t0[i].pos, measures )        
          local _, _, _, real_pos = reaper.TimeMap2_timeToBeats( 0, pos_sec ) 
          passed_t[#passed_t+1] = { pos = real_pos,
                          val = passed_t0[i].val}
        end
      end
      local pos_rgn = TimeMap2_beatsToTime( 0, 0, measures ) 
      local end_rgn = TimeMap2_beatsToTime( 0, strategy.ref_pattern_len, measures ) 
      local r,g,b = table.unpack(obj.GUIcol[col_str])
      AddProjectMarker2( 0, true, pos_rgn, end_rgn, 'QT_'.. strategy.ref_pattern_len..' beats',
                           -1, --want id
                           ColorToNative( math.floor(r*255),math.floor(g*255),math.floor(b*255))  |0x1000000 )
     else
      passed_t = passed_t0
    end
    
    for i = 1, #passed_t do
      if not passed_t[i].ignore_search then
        local pos_beats = passed_t[i].pos
        local pos_sec =  TimeMap2_beatsToTime( 0, pos_beats )
        local r,g,b = table.unpack(obj.GUIcol[col_str])
        local val_str = i 
        if passed_t[i].val then 
          val_str = passed_t[i].val
          if passed_t[i].val2 then val_str = val_str ..'_'..passed_t[i].val2 end
        end
        AddProjectMarker2( 0, false, 
                          pos_sec, 
                          -1, 
                          'QT_'..val_str, 
                          i, 
                          ColorToNative( math.floor(r*255),math.floor(g*255),math.floor(b*255))  |0x1000000 )
      end
    end
    
    
    
  end
  ---------------------------------------------------  
  function Data_ClearMarkerPoints(conf, obj, data, refresh, mouse, strategy) 
    local retval, num_markers, num_regions = CountProjectMarkers( 0 )
    for i = num_markers, 1, -1 do
      local  retval, isrgn, pos, rgnend, name, markrgnindexnumber = EnumProjectMarkers( i-1 )
      if name:lower():match('qt_%d') then 
        reaper.DeleteProjectMarker( proj, markrgnindexnumber, isrgn )
      end
    end
    for i = num_regions, 1, -1 do
      local  retval, isrgn, pos, rgnend, name, markrgnindexnumber = EnumProjectMarkers( i-1 )
      if name:lower():match('qt_%d') then 
        reaper.DeleteProjectMarker( proj, markrgnindexnumber, isrgn )
      end
    end
  end
  --------------------------------------------------- 
