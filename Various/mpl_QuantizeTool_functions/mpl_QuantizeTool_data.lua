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
  function Data_ApplyStrategy_reference(conf, obj, data, refresh, mouse, strategy)
    data.ref = {}
    data.ref_pat = {}
    Data_ApplyStrategy_reference_pos(conf, obj, data, refresh, mouse, strategy)
    if strategy.ref_values&2==2 then table.sort(data.ref, function (a,b) return a.pos and b.pos and a.pos<b.pos end) end

    Data_ApplyStrategy_reference_val(conf, obj, data, refresh, mouse, strategy)
    if strategy.ref_values&2~=2 then table.sort(data.ref, function (a,b) return a.pos and b.pos and a.pos<b.pos end) end    
    if strategy.ref_pattern&1==1 then Data_ApplyStrategy_reference_pattern(conf, obj, data, refresh, mouse, strategy) end      
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
  ---------------------------------------------------   
  function Data_ApplyStrategy_reference_pos(conf, obj, data, refresh, mouse, strategy)
    if strategy.ref_positions&1 ~=1 then return end
    
    if strategy.ref_selitems&1==1 then Data_GetItems_Pos(data, 'ref')  end       
    if strategy.ref_envpoints&1==1 then Data_GetEP_Pos(data, 'ref')  end
     
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
  function     Data_ApplyStrategy_reference_val(conf, obj, data, refresh, mouse, strategy)
    if strategy.ref_values&1~=1 then return end
    
    if strategy.ref_val_itemvol&1==1 then  Data_GetItems_Gain(data, 'ref') end    
    if strategy.src_val_envpoint&1==1 then Data_GetEP_Val (data, 'ref') end
  end
  --------------------------------------------------- 
  function Data_GetItems_Pos(data, table_name) 
      for selitem = 1, CountSelectedMediaItems(0) do
        local item =  GetSelectedMediaItem( 0, selitem-1 )
        local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
        local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
        if not data[table_name][selitem] then data[table_name][selitem] = {} end
        data[table_name][selitem].pos = fullbeats
        data[table_name][selitem].pos_beats = beats
        data[table_name][selitem].GUID = BR_GetMediaItemGUID( item )
        data[table_name][selitem].srctype='item'
        data[table_name][selitem].val = 1
      end      
  end
  --------------------------------------------------- 
  function Data_GetEP_Pos(data, table_name) 
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
  function Data_GetEP_Val(data, table_name) 
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
        --[[data[table_name][ptidx_cust].pos = fullbeats
        data[table_name][ptidx_cust].pos_beats = beats
        data[table_name][ptidx_cust].ptr = env
        data[table_name][ptidx_cust].srctype='envpoint'
        data[table_name][ptidx_cust].selected = selected
        data[table_name][ptidx_cust].ID = ptidx-1
        data[table_name][ptidx_cust].shape = shape
        data[table_name][ptidx_cust].tension = tension]]
        data[table_name][ptidx_cust].val = value
      end
    end
  end    
  
  --------------------------------------------------- 
  function Data_GetItems_Gain(data, table_name) 
      for selitem = 1, CountSelectedMediaItems(0) do
        local item =  GetSelectedMediaItem( 0, selitem-1 )
        local val = GetMediaItemInfo_Value( item, 'D_VOL' )
        if not data[table_name][selitem] then data[table_name][selitem] = {} end
        data[table_name][selitem].GUID = BR_GetMediaItemGUID( item )
        data[table_name][selitem].srctype='item'
        data[table_name][selitem].val = val
      end      
  end  
  
  --------------------------------------------------- 
  function Data_ApplyStrategy_source(conf, obj, data, refresh, mouse, strategy)
    data.src = {}
    
    -- positions
    if strategy.src_positions&1 ==1 and strategy.src_selitems&1==1 then Data_GetItems_Pos(data, 'src') end   
    if strategy.src_positions&1 ==1 and strategy.src_envpoint&1==1 then Data_GetEP_Pos(data, 'src') end   
    

    -- values
    if strategy.src_values&1==1 and strategy.src_val_itemvol&1==1 then Data_GetItems_Gain(data, 'src') end     
    if strategy.src_values&1==1 and strategy.src_val_envpoint&1==1 then Data_GetEP_Val(data, 'src') end
  end
  --------------------------------------------------- 
  function DataSearchPatternVal(conf, data, strategy, pos_src_full, pos_src_beats, val_src)
    if not data.ref_pat then return end
    local pat_ID 
    if #data.ref_pat == 1 then
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
  function Data_ApplyStrategy_action(conf, obj, data, refresh, mouse, strategy)    
    if not data.ref or not data.src then return end
    
    if strategy.act_action == 1 then
      for i = 1, #data.src do        
        if data.src[i].pos then
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
      centerID = math.ceil(limID1 + (limID2-limID1)/2)
      centerID_pos = data.ref[centerID].pos
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
          if strategy.src_positions&1==1 and t.out_pos then 
            local out_pos = t.pos + (t.out_pos - t.pos)*strategy.exe_val1
            out_pos = TimeMap2_beatsToTime( 0, out_pos)
            SetMediaItemInfo_Value( it, 'D_POSITION', out_pos )
          end 
          if strategy.src_values&1==1 and t.out_val then
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
      if strategy.src_positions&1==1 then out_pos = t.pos + (t.out_pos - t.pos)*strategy.exe_val1 end
      if strategy.src_values&1==1 then out_val = t.val + (t.out_val - t.val)*strategy.exe_val2 end
      out_pos = TimeMap2_beatsToTime( 0, out_pos)
      SetEnvelopePointEx( env, -1, t.ID, out_pos, out_val, t.shape, t.tension, t.selected, true )
    end  
    Envelope_SortPointsEx( env, -1 )
    UpdateArrange()
  end
  --------------------------------------------------- 
  function Data_Execute_Align(conf, obj, data, refresh, mouse, strategy)
    if not data.src or not data.ref then return end
    if strategy.src_selitems&1==1 then Data_Execute_Align_Items(conf, obj, data, refresh, mouse, strategy) end
    if strategy.src_envpoint&1==1 then Data_Execute_Align_EnvPt(conf, obj, data, refresh, mouse, strategy) end
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
      AddProjectMarker2( 0, true, pos_rgn, end_rgn, 'QT_'.. strategy.ref_pattern_len..' beats', -1, ColorToNative( math.floor(r*255),math.floor(g*255),math.floor(b*255))  |0x1000000 )
     else
      passed_t = passed_t0
    end
    
    for i = 1, #passed_t do
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
                        -1, 
                        ColorToNative( math.floor(r*255),math.floor(g*255),math.floor(b*255))  |0x1000000 )
    end
    
    
    
  end
  ---------------------------------------------------  
  function Data_ClearMarkerPoints(conf, obj, data, refresh, mouse, strategy) 
    local retval, num_markers, num_regions = CountProjectMarkers( 0 )
    for i = num_markers, 1, -1 do
      local  retval, isrgn, pos, rgnend, name, markrgnindexnumber = EnumProjectMarkers( i-1 )
      if name:lower():match('qt_') then 
        reaper.DeleteProjectMarker( proj, markrgnindexnumber, isrgn )
      end
    end
    for i = num_regions, 1, -1 do
      local  retval, isrgn, pos, rgnend, name, markrgnindexnumber = EnumProjectMarkers( i-1 )
      if name:lower():match('qt_') then 
        reaper.DeleteProjectMarker( proj, markrgnindexnumber, isrgn )
      end
    end
  end
  --------------------------------------------------- 
