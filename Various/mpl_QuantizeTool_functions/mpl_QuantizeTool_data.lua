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
    Data_ApplyStrategy_reference_pos(conf, obj, data, refresh, mouse, strategy)
    if strategy.ref_values&2==2 then table.sort(data.ref, function (a,b) return a.pos and b.pos and a.pos<b.pos end) end
    Data_ApplyStrategy_reference_val(conf, obj, data, refresh, mouse, strategy)
    if strategy.ref_values&2~=2 then table.sort(data.ref, function (a,b) return a.pos and b.pos and a.pos<b.pos end) end
  end
  ---------------------------------------------------   
  function Data_ApplyStrategy_reference_pos(conf, obj, data, refresh, mouse, strategy)
    if strategy.ref_positions&1 ~=1 then return end
    
    if strategy.ref_selitems&1==1 then
      for selitem = 1, CountSelectedMediaItems(0) do
        local item =  GetSelectedMediaItem( 0, selitem-1 )
        local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
        local retval, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
        if not data.ref[selitem] then data.ref[selitem] = {} end
        data.ref[selitem].pos = fullbeats
      end
    end   
    
    if strategy.ref_envpoints&1==1 then
      local  env = GetSelectedEnvelope( 0 )
      if not env then return end
      local cnt = CountEnvelopePoints( env )
      local ptidx_cust = 0
      for ptidx = 1, cnt do
        local retval, pos, value, shape, tension, selected = GetEnvelopePoint( env, ptidx-1 )
        if selected then
          ptidx_cust = ptidx_cust + 1
          local retval, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
          if not data.ref[ptidx_cust] then data.ref[ptidx_cust] = {} end
          data.ref[ptidx_cust].pos = fullbeats
        end
      end
    end     
     
  end  
  ---------------------------------------------------     
  function     Data_ApplyStrategy_reference_val(conf, obj, data, refresh, mouse, strategy)
    if strategy.ref_values&1~=1 then return end
    
    -- attach out_of_scope values to last position if any
      local last_pos = 0
      if #data.ref > 1 and data.ref[#data.ref].pos then last_pos = data.ref[#data.ref].pos end
    
    if strategy.ref_val_itemvol&1==1 then 
      for selitem = 1, CountSelectedMediaItems(0) do
        local item =  GetSelectedMediaItem( 0, selitem-1 )
        local val = GetMediaItemInfo_Value( item, 'D_VOL' )
        if not data.ref[selitem] then data.ref[selitem] = {pos =last_pos} end
        data.ref[selitem].val = val
      end
    end
    
    if strategy.ref_envpoints&1==1 then
      local  env = GetSelectedEnvelope( 0 )
      if not env then return end
      local cnt = CountEnvelopePoints( env )
      local ptidx_cust = 0
      for ptidx = 1, cnt do
        local retval, pos, value, shape, tension, selected = GetEnvelopePoint( env, ptidx-1 )
        if selected then
          ptidx_cust = ptidx_cust + 1
          if not data.ref[ptidx_cust] then data.ref[ptidx_cust] = {pos=last_pos} end
          data.ref[ptidx_cust].val = value
        end
      end
    end 
  end
  --------------------------------------------------- 
  function Data_ApplyStrategy_source(conf, obj, data, refresh, mouse, strategy)
    data.src = {}
    
    -- positions
    if (strategy.src_positions&1 ==1 and strategy.src_selitems&1==1) or (strategy.src_values&1==1 and strategy.src_val_itemvol&1==1) then
      for selitem = 1, CountSelectedMediaItems(0) do
        local item =  GetSelectedMediaItem( 0, selitem-1 )
        local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
        local retval, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
        local val 
        if strategy.src_val_itemvol&1==1 then val = GetMediaItemInfo_Value( item, 'D_VOL' ) end
        data.src[#data.src +1] = {srctype='item',
                                  GUID = BR_GetMediaItemGUID( item ),
                                  pos = fullbeats,
                                  val = val}
      end
    end    
  end
  --------------------------------------------------- 
  function Data_ApplyStrategy_action(conf, obj, data, refresh, mouse, strategy)    
    if not data.ref or not data.src then return end
    
    if strategy.act_action == 1 then
      for i = 1, #data.src do        
        if data.src[i].pos then
          local refID = Data_brutforce_RefID(conf, data, strategy, data.src[i].pos)
          if refID and data.ref[refID] then 
            data.src[i].out_pos = data.ref[refID].pos
            data.src[i].out_val = data.ref[refID].val
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
  function Data_Execute_Align(conf, obj, data, refresh, mouse, strategy)
    
    for i = 1 , #data.src do
      local t = data.src[i]
      if t.srctype=='item' then
        local it =  BR_GetMediaItemByGUID( 0, t.GUID )
        if it then 
          if strategy.src_positions&1==1 then 
            local out_pos = t.pos + (t.out_pos - t.pos)*strategy.exe_val1
            out_pos = TimeMap2_beatsToTime( 0, out_pos)
            SetMediaItemInfo_Value( it, 'D_POSITION', out_pos )
          end 
          if strategy.src_values&1==1 then
            SetMediaItemInfo_Value( it, 'D_VOL', t.val + (t.out_val - t.val)*strategy.exe_val2 )  
          end
          UpdateItemInProject( it )
        end
      end
  
    end
  end
  ---------------------------------------------------   
  function Data_ShowPointsAsMarkers(conf, obj, data, refresh, mouse, strategy, passed_t, col_str) 
    if not passed_t then return end
    
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
  end
  --------------------------------------------------- 
