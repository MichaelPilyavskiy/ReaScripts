-- @description QuantizeTool
-- @version 3.05
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @about Script for manipulating REAPER objects time and values
-- @changelog
--    + Knob: fix entering decimal values
--    + Knob: show value
--    + Knob: allow to set with mousewheel
--    # Compact mode: rearrange view
--    # Change width/height defaults

  
  DATA2 = {}
  ---------------------------------------------------------------------  
  function main()
    if not DATA.extstate then DATA.extstate = {} end
    DATA.extstate.version = 3.05
    DATA.extstate.extstatesection = 'MPL_QuantizeTool'
    DATA.extstate.mb_title = 'QuantizeTool'
    DATA.extstate.default = 
                          {  
                          wind_x =  100,
                          wind_y =  100,
                          wind_w =  470,
                          wind_h =  65,
                          dock =    0, 
                          
                          UI_groupflags = 0,
                          UI_appatchange = 0,
                          UI_initatmouse = 0,
                          UI_enableshortcuts = 1,
                          UI_showtooltips = 1,
                          
                          -- global
                          CONF_NAME = 'default',
                          CONF_act_initcatchref = 1 ,  -- catch ref on init
                          CONF_act_catchreftimesel = 0 , 
                          CONF_act_initcatchsrc = 1 ,
                          CONF_act_catchsrctimesel = 0 , 
                          CONF_act_initapp = 0,
                          --CONF_act_initact = 0  ,
                          CONF_act_appbuttoexecute = 0,
                          
                          FPRESET1='CkNPTkZfTkFNRT1BbGlnbiBpdGVtcyB0byBlZGl0IGN1cnNvcgpDT05GX2FjdF9hY3Rpb249MQpDT05GX2FjdF9hbGlnbmRpcj0xCkNPTkZfYWN0X2NhdGNocmVmdGltZXNlbD0wCkNPTkZfYWN0X2NhdGNoc3JjdGltZXNlbD0wCkNPTkZfYWN0X2luaXRhcHA9MApDT05GX2FjdF9pbml0Y2F0Y2hyZWY9MQpDT05GX2FjdF9pbml0Y2F0Y2hzcmM9MQpDT05GX2NvbnZlcnRub3Rlb252ZWwwdG9ub3Rlb2ZmPTAKQ09ORl9lbnZzdGVwcz0wCkNPTkZfZXhjbHdpdGhpbj0wCkNPTkZfaW5jbHdpdGhpbj0wCkNPTkZfaW5pdGF0bW91c2Vwb3M9MApDT05GX2l0ZXJhdGlvbmxpbT0zMDAwMApDT05GX29mZnNldD0wLjUKQ09ORl9yZWZfZWRpdGN1cj0xCkNPTkZfcmVmX2VudnBvaW50cz0wCkNPTkZfcmVmX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9yZWZfZ3JpZD0wCkNPTkZfcmVmX2dyaWRfc3c9MApDT05GX3JlZl9ncmlkX3ZhbD0wLjUKQ09ORl9yZWZfbWFya2VyPTAKQ09ORl9yZWZfbWlkaT0wCkNPTkZfcmVmX21pZGlfbXNnZmxhZz0xCkNPTkZfcmVmX21pZGlmbGFncz0xCkNPTkZfcmVmX3BhdHRlcm49MApDT05GX3JlZl9wYXR0ZXJuX2dlbnNyYz0xCkNPTkZfcmVmX3BhdHRlcm5fbGVuMj04CkNPTkZfcmVmX3BhdHRlcm5fbmFtZT1sYXN0X3RvdWNoZWQKQ09ORl9yZWZfc2VsaXRlbXM9MApDT05GX3JlZl9zZWxpdGVtc192YWx1ZT0wCkNPTkZfcmVmX3N0cm1hcmtlcnM9MApDT05GX3JlZl90aW1lbWFya2VyPTAKQ09ORl9zcmNfZW52cG9pbnRzPTAKQ09ORl9zcmNfZW52cG9pbnRzZmxhZz0xCkNPTkZfc3JjX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9zcmNfbWlkaT0wCkNPTkZfc3JjX21pZGlfbXNnZmxhZz01CkNPTkZfc3JjX21pZGlmbGFncz0xCkNPTkZfc3JjX3Bvc2l0aW9ucz0xCkNPTkZfc3JjX3NlbGl0ZW1zPTEKQ09ORl9zcmNfc2VsaXRlbXNmbGFnPTEKQ09ORl9zcmNfc3RybWFya2Vycz0w',
                          FPRESET2='CkNPTkZfTkFNRT1BbGlnbiBpdGVtcyB0byBwcm9qZWN0IGdyaWQKQ09ORl9hY3RfYWN0aW9uPTEKQ09ORl9hY3RfYWxpZ25kaXI9MQpDT05GX2FjdF9jYXRjaHJlZnRpbWVzZWw9MApDT05GX2FjdF9jYXRjaHNyY3RpbWVzZWw9MApDT05GX2FjdF9pbml0YXBwPTAKQ09ORl9hY3RfaW5pdGNhdGNocmVmPTEKQ09ORl9hY3RfaW5pdGNhdGNoc3JjPTEKQ09ORl9jb252ZXJ0bm90ZW9udmVsMHRvbm90ZW9mZj0wCkNPTkZfZW52c3RlcHM9MApDT05GX2V4Y2x3aXRoaW49MApDT05GX2luY2x3aXRoaW49MApDT05GX2luaXRhdG1vdXNlcG9zPTAKQ09ORl9pdGVyYXRpb25saW09MzAwMDAKQ09ORl9vZmZzZXQ9MC41CkNPTkZfcmVmX2VkaXRjdXI9MApDT05GX3JlZl9lbnZwb2ludHM9MApDT05GX3JlZl9lbnZwb2ludHNmbGFncz0xCkNPTkZfcmVmX2dyaWQ9MgpDT05GX3JlZl9ncmlkX3N3PTAKQ09ORl9yZWZfZ3JpZF92YWw9MC41CkNPTkZfcmVmX21hcmtlcj0wCkNPTkZfcmVmX21pZGk9MApDT05GX3JlZl9taWRpX21zZ2ZsYWc9MQpDT05GX3JlZl9taWRpZmxhZ3M9MQpDT05GX3JlZl9wYXR0ZXJuPTAKQ09ORl9yZWZfcGF0dGVybl9nZW5zcmM9MQpDT05GX3JlZl9wYXR0ZXJuX2xlbjI9OApDT05GX3JlZl9wYXR0ZXJuX25hbWU9bGFzdF90b3VjaGVkCkNPTkZfcmVmX3NlbGl0ZW1zPTAKQ09ORl9yZWZfc2VsaXRlbXNfdmFsdWU9MApDT05GX3JlZl9zdHJtYXJrZXJzPTAKQ09ORl9yZWZfdGltZW1hcmtlcj0wCkNPTkZfc3JjX2VudnBvaW50cz0wCkNPTkZfc3JjX2VudnBvaW50c2ZsYWc9MQpDT05GX3NyY19lbnZwb2ludHNmbGFncz0xCkNPTkZfc3JjX21pZGk9MApDT05GX3NyY19taWRpX21zZ2ZsYWc9NQpDT05GX3NyY19taWRpZmxhZ3M9MQpDT05GX3NyY19wb3NpdGlvbnM9MQpDT05GX3NyY19zZWxpdGVtcz0xCkNPTkZfc3JjX3NlbGl0ZW1zZmxhZz0xCkNPTkZfc3JjX3N0cm1hcmtlcnM9MA==',
                          FPRESET3='CkNPTkZfTkFNRT1BbGlnbiBzZWxlY3RlZCBpdGVtIG5vdGVzIHRvIHByb2plY3QgZ3JpZApDT05GX2FjdF9hY3Rpb249MQpDT05GX2FjdF9hbGlnbmRpcj0xCkNPTkZfYWN0X2NhdGNocmVmdGltZXNlbD0wCkNPTkZfYWN0X2NhdGNoc3JjdGltZXNlbD0wCkNPTkZfYWN0X2luaXRhcHA9MApDT05GX2FjdF9pbml0Y2F0Y2hyZWY9MQpDT05GX2FjdF9pbml0Y2F0Y2hzcmM9MQpDT05GX2NvbnZlcnRub3Rlb252ZWwwdG9ub3Rlb2ZmPTAKQ09ORl9lbnZzdGVwcz0wCkNPTkZfZXhjbHdpdGhpbj0wCkNPTkZfaW5jbHdpdGhpbj0wCkNPTkZfaW5pdGF0bW91c2Vwb3M9MApDT05GX2l0ZXJhdGlvbmxpbT0zMDAwMApDT05GX29mZnNldD0wLjUKQ09ORl9yZWZfZWRpdGN1cj0wCkNPTkZfcmVmX2VudnBvaW50cz0wCkNPTkZfcmVmX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9yZWZfZ3JpZD0yCkNPTkZfcmVmX2dyaWRfc3c9MApDT05GX3JlZl9ncmlkX3ZhbD0wLjUKQ09ORl9yZWZfbWFya2VyPTAKQ09ORl9yZWZfbWlkaT0wCkNPTkZfcmVmX21pZGlfbXNnZmxhZz0xCkNPTkZfcmVmX21pZGlmbGFncz0xCkNPTkZfcmVmX3BhdHRlcm49MApDT05GX3JlZl9wYXR0ZXJuX2dlbnNyYz0xCkNPTkZfcmVmX3BhdHRlcm5fbGVuMj04CkNPTkZfcmVmX3BhdHRlcm5fbmFtZT1sYXN0X3RvdWNoZWQKQ09ORl9yZWZfc2VsaXRlbXM9MApDT05GX3JlZl9zZWxpdGVtc192YWx1ZT0wCkNPTkZfcmVmX3N0cm1hcmtlcnM9MApDT05GX3JlZl90aW1lbWFya2VyPTAKQ09ORl9zcmNfZW52cG9pbnRzPTAKQ09ORl9zcmNfZW52cG9pbnRzZmxhZz0xCkNPTkZfc3JjX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9zcmNfbWlkaT0xCkNPTkZfc3JjX21pZGlfbXNnZmxhZz01CkNPTkZfc3JjX21pZGlmbGFncz0yCkNPTkZfc3JjX3Bvc2l0aW9ucz0xCkNPTkZfc3JjX3NlbGl0ZW1zPTAKQ09ORl9zcmNfc2VsaXRlbXNmbGFnPTEKQ09ORl9zcmNfc3RybWFya2Vycz0w',
                          
                          -- reference
                          
                          -- positions
                          CONF_ref_selitems  =      0, --&2 snap offset -- &4 handle grouping
                          CONF_ref_selitems_value = 0, -- 0 gain 1 peak 2 RMS
                          CONF_ref_envpoints =      0,
                          CONF_ref_envpointsflags = 1, -- ==1 selected ==2 all selected --==4 selected AI
                          CONF_ref_midi = 0,
                          CONF_ref_midiflags = 1, -- ==1 MIDI editor ==2 Selected items
                          CONF_ref_midi_msgflag = 1, --&2 note off
                          CONF_ref_strmarkers = 0, 
                          CONF_ref_editcur = 0 ,    
                          CONF_ref_marker = 0,   
                          CONF_ref_timemarker = 0  ,
                              
                          CONF_ref_grid = 1 ,   -- &2 current &4 triplet &8 swing
                          CONF_ref_grid_val = 0.5, 
                          CONF_ref_grid_sw = 0,  
                                
                            -- pattern
                          CONF_ref_pattern = 0,
                          CONF_ref_pattern_gensrc = 1,
                          --CONF_ref_pattern_len = 4,
                          CONF_ref_pattern_len2 = 8,
                          CONF_ref_pattern_name = 'last_touched',
                              
                          -- target -----------------------
                          -- positions
                          CONF_src_positions = 1,
                          CONF_src_selitems = 1,
                          CONF_src_selitemsflag = 1, -- &1 positions &2 length &4 stretch &8 offset by autofadeout
                          CONF_src_envpoints = 0,
                          CONF_src_envpointsflags =1, -- ==1 selected ==2 all selected --==4 selected AI
                          CONF_src_envpointsflag = 1, -- 1 values
                          CONF_src_midi = 0 ,
                          CONF_src_midiflags = 1 ,
                          CONF_src_midi_msgflag = 5,--&1 note on &2 note off &4 preserve length
                          CONF_src_strmarkers = 0,
                              
                              
                          -- action -----------------------
                          --  align
                          CONF_act_action = 1 ,  -- 2 create -- 3 ordered alignment -- 4 raw quantize
                          CONF_act_aligndir = 1, -- 0 - always previous 1 - closest 2 - always next
                          CONF_act_valuealign = 0, -- knob2 in the past
                              
                          -- execute -----------------------
                          --exe_val1 = 0, -- align=strength, raw=value 
                          CONF_inclwithin = 0, -- exe_val3 = 0, -- align=inclwithin/0-disabled sec
                          CONF_exclwithin = 0, -- exe_val4 = 0, -- align=exclwithin/0-disabled
                          CONF_offset = 0.5,--  exe_val5 = 0.5, -- align=offset
                          CONF_envsteps = 0,--0.5,--  exe_val2 = 0, -- align=value, raw/envelope=steps
                          
                          -- other
                          CONF_initatmousepos =     0,
                          CONF_iterationlim = 30000, -- deductive brutforce
                          CONF_convertnoteonvel0tonoteoff=0, 
                          }
                          
    DATA:ExtStateGet()
    DATA:ExtStateGetPresets() 
    if DATA.extstate.UI_initatmouse&1==1 then
      local w = DATA.extstate.wind_w
      local h = DATA.extstate.wind_h 
      local x, y = GetMousePosition()
      DATA.extstate.wind_x = x-w/2
      DATA.extstate.wind_y = y-h/2
    end
    
    if DATA.extstate.CONF_act_initcatchref&1==1 then DATA2:GetAnchorPoints() end
    if DATA.extstate.CONF_act_initcatchsrc&1==1 then DATA2:GetTargets() end
    
    
    DATA:GUIinit()
    GUI_RESERVED_init(DATA)
    if DATA.extstate.CONF_act_initcatchref&1==1 or DATA.extstate.CONF_act_initcatchsrc&1==1 then GUI_initdata(DATA)  end
    RUN()
  end
  --------------------------------------------------------------------- 
  function DATA2:GetAnchorPoints_Items() 
    for itemidx = 1,  CountSelectedMediaItems( 0 ) do
      local item = GetSelectedMediaItem( 0, itemidx - 1 )
      local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      if DATA.extstate.CONF_ref_selitems&2==2 then pos = pos + GetMediaItemInfo_Value( item, 'D_SNAPOFFSET' ) end
      local val = GetMediaItemInfo_Value( item, 'D_VOL' )
      if DATA.extstate.CONF_ref_selitems_value > 0 then
        local peak, RMS = VF_AnalyzeItemLoudness(item)
        if DATA.extstate.CONF_ref_selitems_value == 1 then val = peak elseif DATA.extstate.CONF_ref_selitems_value == 2 then val = RMS end
      end
      DATA2.ref[#DATA2.ref+1] = { pos_sec = pos,
                                  pos_beats = ({TimeMap2_timeToBeats( 0, pos)})[4],
                                  val = val
                                  }
    end
  end  
  --------------------------------------------------------------------- 
  function DATA2:GetTargets_Items() 
    local mode = DATA.extstate.CONF_src_selitemsflag
    local table_name = 'src'
    local groupIDt = {}
    local id = 1
    for itemidx = 1, CountMediaItems(0) do
      local item =  GetMediaItem( 0,itemidx-1 )
      local item_tr =  GetMediaItem_Track( item )
      local take = GetActiveTake(item)
      local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local it_pos = pos
      local len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local groupID = GetMediaItemInfo_Value( item, 'I_GROUPID' )
      
      local position_has_snap_offs, snapoffs_sec
      if mode&2==2 then --snap offset
        position_has_snap_offs = true
        snapoffs_sec = GetMediaItemInfo_Value( item, 'D_SNAPOFFSET' )
        pos = pos + snapoffs_sec
      end
      local is_sel = GetMediaItemInfo_Value( item, 'B_UISEL' ) == 1
      local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
      local val = GetMediaItemInfo_Value( item, 'D_VOL' )
      local tk_rate if take then  tk_rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )   end
      if is_sel then 
        local group_master
        if not groupIDt[groupID] or groupID == 0 then group_master = true  end
        if not DATA2[table_name][id] then DATA2[table_name][id] = {} end
        
        DATA2[table_name][id].ignore_search = not is_sel
        DATA2[table_name][id].pos = fullbeats
        DATA2[table_name][id].pos_sec = pos
        DATA2[table_name][id].position_has_snap_offs = position_has_snap_offs
        DATA2[table_name][id].pos_beats = fullbeats
        DATA2[table_name][id].snapoffs_sec = snapoffs_sec 
        DATA2[table_name][id].GUID = VF_GetItemGUID( item )
        DATA2[table_name][id].srctype='item'
        DATA2[table_name][id].val =val
        DATA2[table_name][id].it_len = len
        DATA2[table_name][id].it_pos=it_pos
        DATA2[table_name][id].groupID = groupID 
        DATA2[table_name][id].ptr = item
        DATA2[table_name][id].activetk_ptr = take
        DATA2[table_name][id].activetk_rate = tk_rate
        DATA2[table_name][id].group_master = group_master
        id = id + 1
        
        if table_name == 'src' and DATA.extstate.CONF_src_selitemsflag&2==2 then
          if not DATA2[table_name][id] then DATA2[table_name][id] = {} end
          local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos+len )
          DATA2[table_name][id].ignore_search = not is_sel
          DATA2[table_name][id].pos = fullbeats
          DATA2[table_name][id].pos_sec = pos
          DATA2[table_name][id].position_has_snap_offs = position_has_snap_offs
          DATA2[table_name][id].pos_beats = beats
          DATA2[table_name][id].snapoffs_sec = snapoffs_sec 
          DATA2[table_name][id].GUID = VF_GetItemGUID( item )
          DATA2[table_name][id].srctype='item_end'
          DATA2[table_name][id].val =val
          DATA2[table_name][id].it_len = len
          DATA2[table_name][id].it_pos=it_pos
          DATA2[table_name][id].groupID = GetMediaItemInfo_Value( item, 'I_GROUPID' )
          DATA2[table_name][id].D_FADEOUTLEN = GetMediaItemInfo_Value( item, 'D_FADEOUTLEN_AUTO' )
          DATA2[table_name][id].ptr = item
          DATA2[table_name][id].activetk_ptr = take
          DATA2[table_name][id].activetk_rate = tk_rate 
          DATA2[table_name][id].group_master = group_master
          DATA2[table_name][id].parent_position_entry = id-1
          id = id + 1    
        end
        
        groupIDt[groupID] = {}
      end
    end      
  end  
  --------------------------------------------------------------------- 
  function DATA2:GetAnchorPoints_EP() 
    if DATA.extstate.CONF_ref_envpointsflags==2 then -- all env
      for i = 1, CountTracks(0) do
        local track = GetTrack(0,i-1)
        local cnt_env = CountTrackEnvelopes( track )
        for envidx = 1, cnt_env do
          local env = GetTrackEnvelope( track, envidx-1 )
          local retval, time, value0, shape, tension, selected = GetEnvelopePointEx( env, -1, i-1 )
          local cnt =  CountEnvelopePointsEx( env,-1 )
          for ptidx = 1, cnt do
            local retval, pos, val, shape, tension, selected = reaper.GetEnvelopePointEx( env, -1, ptidx-1 )
            if selected then
              DATA2.ref[#DATA2.ref+1] = { pos_sec = pos, pos_beats = ({TimeMap2_timeToBeats( 0, pos )})[4], val = ScaleFromEnvelopeMode(GetEnvelopeScalingMode( env ),val) }
            end
          end
        end
      end 
      -- get take env
      for itemidx = 1, CountMediaItems( 0 ) do
        local item = GetMediaItem( 0, itemidx-1 )
        local item_pos =  GetMediaItemInfo_Value( item, 'D_POSITION' )
        for  takeidx = 1, CountTakes( item ) do
          local take  =  GetTake( item, takeidx-1 )
          local tk_rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
          for envidx = 1,  CountTakeEnvelopes( take ) do
            local env =  GetTakeEnvelope( take, envidx-1 )
            local cnt =  CountEnvelopePointsEx( env,-1 )
            for ptidx = 1, cnt do
              local retval, pos, val, shape, tension, selected = reaper.GetEnvelopePointEx( env, -1, ptidx-1 )
              if selected then
                pos = pos/ tk_rate + item_pos 
                DATA2.ref[#DATA2.ref+1] = { pos_sec = pos, pos_beats = ({TimeMap2_timeToBeats( 0, pos )})[4], val = ScaleFromEnvelopeMode(GetEnvelopeScalingMode( env ),val) }
              end
            end
          end
        end
      end 
      
     elseif DATA.extstate.CONF_ref_envpointsflags==4 then -- AI 
      for i = 1, CountTracks(0) do
        local track = GetTrack(0,i-1)
        local cnt_env = CountTrackEnvelopes( track )
        for envidx = 1, cnt_env do
          local env = GetTrackEnvelope( track, envidx-1 )
          for AI_idx =1, CountAutomationItems( env ) do
            local cnt =  CountEnvelopePointsEx( env,AI_idx-1 )
            for ptidx = 1, cnt do
              local retval, pos, val, shape, tension, selected = reaper.GetEnvelopePointEx( env, AI_idx-1, ptidx-1 )
              if selected then
                DATA2.ref[#DATA2.ref+1] = { pos_sec = pos, pos_beats = ({TimeMap2_timeToBeats( 0, pos )})[4], val = ScaleFromEnvelopeMode(GetEnvelopeScalingMode( env ),val) }
              end
            end
          end
        end
      end
      
     elseif DATA.extstate.CONF_ref_envpointsflags==1 then -- selected
      local  env = GetSelectedEnvelope( 0 )
      if env then 
        local istakeenv, item_pos, tk_rate = DATA2:IsTakeEnvelope(env) 
        local cnt =  CountEnvelopePointsEx( env,-1 )
        for ptidx = 1, cnt do
          local retval, pos, val, shape, tension, selected = reaper.GetEnvelopePointEx( env, -1, ptidx-1 )
          if selected then
            DATA2.ref[#DATA2.ref+1] = { pos_sec = pos, pos_beats = ({TimeMap2_timeToBeats( 0, pos )})[4], val = ScaleFromEnvelopeMode(GetEnvelopeScalingMode( env ),val), istakeenv=istakeenv, item_pos=item_pos }
          end
        end
      end
    end
    
    
  end
  --------------------------------------------------------------------- 
  function DATA2:GetTargets_EP() 
    local mode = DATA.extstate.CONF_src_envpointsflags
    if mode==2 then 
      for i = 1, CountTracks(0) do
        local track = GetTrack(0,i-1)
        local cnt_env = CountTrackEnvelopes( track )
        for envidx = 1, cnt_env do
          local env = GetTrackEnvelope( track, envidx-1 )
          DATA2:GetTargets_EPsub(env, nil, tk_rate, AI_idx)  
        end
      end 
      -- get take env
      for itemidx = 1, CountMediaItems( 0 ) do
        local item = GetMediaItem( 0, itemidx-1 )
        local item_pos =  GetMediaItemInfo_Value( item, 'D_POSITION' )
        for  takeidx = 1, CountTakes( item ) do
          local take  =  GetTake( item, takeidx-1 )
          local tk_rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
          for envidx = 1,  CountTakeEnvelopes( take ) do
            local env =  GetTakeEnvelope( take, envidx-1 )
            DATA2:GetTargets_EPsub(env, item_pos, tk_rate, AI_idx)  
          end
        end
      end 
      
     elseif mode==4 then -- AI
      for i = 1, CountTracks(0) do
        local track = GetTrack(0,i-1)
        local cnt_env = CountTrackEnvelopes( track )
        for envidx = 1, cnt_env do
          local env = GetTrackEnvelope( track, envidx-1 )
          for AI_idx =1, CountAutomationItems( env ) do
            DATA2:GetTargets_EPsub(env, nil, tk_rate, AI_idx)  
          end
        end
      end
      
     elseif mode==1 then -- selected
      local  env = GetSelectedEnvelope( 0 )
      local istakeenv, item_pos, tk_rate = DATA2:IsTakeEnvelope(env) 
      DATA2:GetTargets_EPsub(env, item_pos, tk_rate, AI_idx)  
    end
    
  end 
  ---------------------------------------------------------------------- 
  function DATA2:IsTakeEnvelope(env) 
    for itemidx = 1,  reaper.CountMediaItems( 0) do
      local item =  reaper.GetMediaItem( 0, itemidx-1 )
      for tkid =1 ,  CountTakes( item ) do
        local take =  GetTake( item, tkid-1 )
        for tkenvid = 1, reaper.CountTakeEnvelopes( take ) do
          local tkenv = reaper.GetTakeEnvelope( take, tkenvid-1 )
          if tkenv == env then 
            local item_pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
            local tk_rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
            return true , item_pos, tk_rate
          end
        end
      end
    end
  end
  ---------------------------------------------------------------------- 
  function DATA2:GetTargets_EPsub(env, item_pos0, tk_rate, AI_idx) 
    local table_name = 'src'
    if not env then return end
    local scaling_mode = GetEnvelopeScalingMode( env )
    if not AI_idx then AI_idx = 0 end
    local cnt =  CountEnvelopePointsEx( env,AI_idx-1 )
    for ptidx = 1, cnt do
      local retval, pos, value, shape, tension, selected = reaper.GetEnvelopePointEx( env, AI_idx-1, ptidx-1 )
      --if selected then
        local ptidx_cust = #DATA2[table_name] + 1
        if item_pos0 then pos = pos/ tk_rate + item_pos0  end
        local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
        DATA2[table_name][ptidx_cust] = {}
        DATA2[table_name][ptidx_cust].item_pos = item_pos0
        DATA2[table_name][ptidx_cust].pos = fullbeats
        DATA2[table_name][ptidx_cust].pos_sec = pos
        DATA2[table_name][ptidx_cust].pos_beats = fullbeats
        DATA2[table_name][ptidx_cust].ptr = env
        DATA2[table_name][ptidx_cust].ptr_str = genGuid('' )
        DATA2[table_name][ptidx_cust].srctype='envpoint'
        DATA2[table_name][ptidx_cust].selected = selected
        DATA2[table_name][ptidx_cust].ID = ptidx-1
        DATA2[table_name][ptidx_cust].shape = shape
        DATA2[table_name][ptidx_cust].tension = tension
        DATA2[table_name][ptidx_cust].val = ScaleFromEnvelopeMode( scaling_mode,value)
        DATA2[table_name][ptidx_cust].ignore_search = not selected
        DATA2[table_name][ptidx_cust].tk_rate = tk_rate
        DATA2[table_name][ptidx_cust].AI_idx = AI_idx-1
        DATA2[table_name][ptidx_cust].scaling_mode = scaling_mode
      --end
    end
  end
  ---------------------------------------------------------------------- 
  function DATA2:GetTargets_MIDI_perTake(take, item, mode)
    local table_name = 'src'
    if not take or not ValidatePtr2( 0, take, 'MediaItem_Take*' ) or not TakeIsMIDI(take) then return end
    local item_pos = 0 
    if item then item_pos  = GetMediaItemInfo_Value( item, 'D_POSITION' )  end
    local t_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
    local tk_rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
    
    local t0 = {}
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
      local pitch = msg1:byte(2)
      local vel = msg1:byte(3) 
      if not vel then vel = 120 end 
      local ignore_search = true 

        t0[#t0+1] = 
                          {       pos = fullbeats,
                                  pos_beats = fullbeats,
                                  pos_sec = pos_sec,
                                  ignore_search = ignore_search,
                                  GUID = VF_GetTakeGUID( take ),
                                  tk_offs = t_offs,
                                  it_pos = item_pos, 
                                  tk_rate = tk_rate,
                                  ptr = take,
                                  
                                  pitch = msg1:byte(2),
                                  val = vel/127,
                                  
                                  flags=flags,
                                  msg1=msg1,
                                  ppq_pos=ppq_pos,
                                  offset=offset,
                                  srctype = 'MIDIEvnt',
                                  isNoteOn =isNoteOn,
                                  isNoteOff=isNoteOff,
                                  isCC =isCC,
                                  chan=chan,
                                  pitch = pitch
                                 }
    end  
    
    
    local ppq_sorted_t = {}
    local ppq_t = {}
    
    -- sort stuff by ppq
      for i = 1, #t0 do
        local t = t0[i]
        local ppq_pos = t.ppq_pos
        if not ppq_sorted_t[ppq_pos] then 
          ppq_sorted_t[ppq_pos] = {} 
          ppq_t[#ppq_t+1] = ppq_pos 
        end
        ppq_sorted_t[ppq_pos] [#ppq_sorted_t[ppq_pos]+1] = t
      end    
      table.sort(ppq_t)
      
    -- sort 
    for i = 1, #ppq_t do
      local ppq = ppq_t[i]
      if ppq_sorted_t[ppq] then 
      
        for i2 = 1, #ppq_sorted_t[ppq] do
          if ppq_sorted_t[ppq][i2].isNoteOn then
          
            
            local new_entry_id = #DATA2[table_name]+1
            DATA2[table_name][new_entry_id] = ppq_sorted_t[ppq][i2]
            if      (table_name=='src' and DATA.extstate.CONF_src_midi_msgflag&1==1)
                or  (table_name=='ref' and DATA.extstate.CONF_ref_midi_msgflag&1==1)  then 
                
              if mode&2 == 2 or (mode&2 == 0 and DATA2[table_name][new_entry_id].flags&1==1) then
                DATA2[table_name][new_entry_id].ignore_search = false 
              end
            end
  
            
            -- search noteoff/add note to table
            for searchid = i+1, #ppq_t do
              local ppq_search = ppq_t[searchid]
              if ppq_sorted_t[ppq_search] then                
                
                for i2_search = 1, #ppq_sorted_t[ppq_search] do                  
                  if      ppq_sorted_t[ppq_search][i2_search].isNoteOff ==true
                      and ppq_sorted_t[ppq_search][i2_search].chan == ppq_sorted_t[ppq][i2].chan 
                      and ppq_sorted_t[ppq_search][i2_search].pitch == ppq_sorted_t[ppq][i2].pitch 
                    then
                    
                    DATA2[table_name][new_entry_id].note_len_PPQ = ppq_search - ppq
                    DATA2[table_name][new_entry_id].is_note = true
                    DATA2[table_name][new_entry_id].noteoff_msg1 = ppq_sorted_t[ppq_search][i2_search].msg1  
                    
                    DATA2[table_name][new_entry_id+1] = ppq_sorted_t[ppq_search][i2_search] 
                    DATA2[table_name][new_entry_id+1].src_id = new_entry_id
                    
                    if      (table_name=='src' and DATA.extstate.CONF_src_midi_msgflag&2==2)
                        or  (table_name=='ref' and DATA.extstate.CONF_ref_midi_msgflag&2==2)  then  
                      if mode&2 == 2 or (mode&2 == 0 and DATA2[table_name][new_entry_id].flags&1==1) then DATA2[table_name][new_entry_id+1].ignore_search = false  end
                    end
                         
                         
                    table.remove(ppq_sorted_t[ppq_search], i2_search)
                    if #ppq_sorted_t[ppq_search] == 0 then ppq_sorted_t[ppq_search] = nil end
                    goto next_evt
                                        
                  end
                end
              end
            end
            
            ::next_evt::
            -- add other events to table
           elseif not (ppq_sorted_t[ppq][i2].isNoteOn or ppq_sorted_t[ppq][i2].isNoteOff) then
            local new_entry_id = #DATA2[table_name]+1
            DATA2[table_name][new_entry_id]=ppq_sorted_t[ppq][i2]
            
          end
        end
      end
    end
    
  end
  ---------------------------------------------------------------------- 
  function DATA2:GetAnchorPoints_MIDIsub(take)
    local mode = DATA.extstate.CONF_ref_midi
    if not take or not ValidatePtr2( 0, take, 'MediaItem_Take*' ) or not TakeIsMIDI(take) then return end
    local item_pos = 0 
    if item then item_pos  = GetMediaItemInfo_Value( item, 'D_POSITION' )  end
    local t_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
    local tk_rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
    
    local t0 = {}
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
      local pitch = msg1:byte(2)
      local vel = msg1:byte(3) 
      if not vel then vel = 127 end 
      local val = vel/127
      local ignore_search = true  
                                        
      if (DATA.extstate.CONF_ref_midi_msgflag==1 and isNoteOn ) or (DATA.extstate.CONF_ref_midi_msgflag==3 and isNoteOff ) then
        DATA2.ref[#DATA2.ref+1] = { pos_sec = pos_sec,
                                  pos_beats = fullbeats,
                                  val = val
                                  }
      end
    end  
    
    
  end
  ----------------------------------------------------------------------  
  function DATA2:GetAnchorPoints_MIDI(table_name)  
    if DATA.extstate.CONF_ref_midiflags == 1 then -- MIDI editor
      local ME = MIDIEditor_GetActive()
      local take = MIDIEditor_GetTake( ME ) 
      if take then 
        if DATA.extstate.CONF_convertnoteonvel0tonoteoff == 1 and TakeIsMIDI(take) then VF_ConvertNoteOnVel0toNoteOff(take) end
        DATA2:GetAnchorPoints_MIDIsub(take)   
      end
     elseif   DATA.extstate.CONF_ref_midiflags == 2 then -- selected takes
      for i = 1, CountSelectedMediaItems(0) do
        local item = GetSelectedMediaItem(0,i-1)
        local take = GetActiveTake(item)
        if DATA.extstate.CONF_convertnoteonvel0tonoteoff == 1 and TakeIsMIDI(take) then VF_ConvertNoteOnVel0toNoteOff(take) end
        DATA2:GetAnchorPoints_MIDIsub(take) 
      end
    end 
  end
  ---------------------------------------------------------------------- 
  function DATA2:GetTargets_MIDI() 
    local mode  = DATA.extstate.CONF_src_midiflags
      if mode&2 == 0 then -- MIDI editor
        local ME = MIDIEditor_GetActive()
        local take = MIDIEditor_GetTake( ME ) 
        if take then 
          local item =  GetMediaItemTake_Item( take )
          if DATA.extstate.CONF_convertnoteonvel0tonoteoff == 1 and TakeIsMIDI(take) then VF_ConvertNoteOnVel0toNoteOff(take) end
          DATA2:GetTargets_MIDI_perTake(take, item, mode)   
        end
       elseif   mode&2 == 2 then -- selected takes
        for i = 1, CountSelectedMediaItems(0) do
          local item = GetSelectedMediaItem(0,i-1)
          local take = GetActiveTake(item)
          if DATA.extstate.CONF_convertnoteonvel0tonoteoff == 1 and TakeIsMIDI(take) then VF_ConvertNoteOnVel0toNoteOff(take) end
          DATA2:GetTargets_MIDI_perTake(take, item, mode) 
        end
      end
      
    end
  ---------------------------------------------------------------------- 
  function DATA2:GetAnchorPoints_SM()
    for i = 1, CountSelectedMediaItems(0) do
      local item =  GetSelectedMediaItem( 0, i-1 )
      if not item then return end
      local it_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local it_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local it_UIsel = GetMediaItemInfo_Value( item, 'B_UISEL' )
      local it_groupID = GetMediaItemInfo_Value( item, 'I_GROUPID' )
      
      local take = GetActiveTake(item)
      local tk_rate  = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
      local stoffst  = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
      
      if not TakeIsMIDI(take) then
        for idx = 1, GetTakeNumStretchMarkers( take ) do
          local retval, sm_pos, srcpos_sec = GetTakeStretchMarker( take, idx-1 )
          local pos_glob = it_pos + sm_pos / tk_rate
          local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos_glob )
          DATA2.ref[#DATA2.ref+1] = { pos_sec = pos_glob,
                                      pos_beats = fullbeats,
                                      val = 1
                                      }
        end
      end 
    end   
  end
  ---------------------------------------------------------------------- 
  function DATA2:GetTargets_SM() 
    local mode = DATA.extstate.CONF_src_strmarkers
    local table_name = 'src'
    local groupIDt = {}
    for i = 1, CountSelectedMediaItems(0) do
      local item =  GetSelectedMediaItem( 0, i-1 )
      if not item then return end
      local it_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local it_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local it_UIsel = GetMediaItemInfo_Value( item, 'B_UISEL' )
      local it_groupID = GetMediaItemInfo_Value( item, 'I_GROUPID' )
      
      local take = GetActiveTake(item)
      local tk_rate  = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
      local stoffst  = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
      
      local group_master
      if not groupIDt[it_groupID] or it_groupID == 0 then 
        group_master = true  
        groupIDt[it_groupID] = #DATA2[table_name]+1
      end 
      
      
      if not TakeIsMIDI(take) then
        for idx = 1, GetTakeNumStretchMarkers( take ) do
          local retval, sm_pos, srcpos_sec = GetTakeStretchMarker( take, idx-1 )
          local slope = GetTakeStretchMarkerSlope( take, idx-1 )
          local pos_glob = it_pos + sm_pos / tk_rate
          local itpos = sm_pos / tk_rate
          local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos_glob )
                
          local ignore_search = false  
          if it_UIsel == 0 then ignore_search = true end
          if pos_glob <= it_pos+0.0001 
            or pos_glob >= it_pos + it_len+0.0001 
            or itpos == 0 
            or math.abs(itpos - it_len )  < 0.001
            then ignore_search = true end
          
          DATA2[table_name][#DATA2[table_name]+1] =
                  { pos = fullbeats,
                    pos_beats = fullbeats,
                    sm_pos_sec=sm_pos,
                    pos_sec = pos_glob,
                    srcpos_sec = srcpos_sec,
                    slope=slope,
                    srctype='strmark',
                    val =1,
                    ignore_search = ignore_search,
                    GUID = VF_GetTakeGUID( take ),
                    it_groupID = GetMediaItemInfo_Value( item, 'I_GROUPID' ),
                    it_ptr = item,
                    it_pos=it_pos,
                    it_len = it_len,
                    it_group_master = group_master,
                    it_groupID = it_groupID,
                    --it_groupIDmaster = groupIDt[it_groupID],
                    tk_rate = tk_rate,
                    tk_ptr= take,
                    tk_offs =stoffst,
                    smid = idx-1,
                }
        end
      end 
    end     
  end   
  ---------------------------------------------------------------------- 
  function DATA2:GetAnchorPoints_Markers()
    local  retval, num_markers, num_regions = CountProjectMarkers( 0 )
    for i = 1, num_markers do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber = EnumProjectMarkers2( 0, i-1 )
      local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
      local val = tonumber(name)
      if not (val and (val >=-1 and val <=2))  then val = 1 end
      DATA2.ref[#DATA2.ref+1] = { 
                              pos_sec = pos,
                              pos_beats = fullbeats,
                              val = val
                            }
    end
  end
  ---------------------------------------------------------------------- 
  function DATA2:GetAnchorPoints_TempoMarkers()
    local  cnt = CountTempoTimeSigMarkers( 0 )
    for i = 1, cnt do
      local  retval, pos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = GetTempoTimeSigMarker( 0, i-1 )
      local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
      DATA2.ref[#DATA2.ref+1] = { 
                              pos_sec = pos,
                              pos_beats = fullbeats,
                              val = val
                            }
    end  
  end
  ---------------------------------------------------------------------- 
  function DATA2:GetAnchorPoints_grid()
    local retval, divisionIn, swingmodeIn, swingamtIn 
    
    divisionIn = DATA.extstate.CONF_ref_grid_val
    swingamtIn = 0
    if DATA.extstate.CONF_ref_grid&4==4 then divisionIn = divisionIn* 2/3 end
    if DATA.extstate.CONF_ref_grid&8==8 then swingamtIn = DATA.extstate.CONF_ref_grid_sw end 
    
    if not divisionIn then return end
    local id = 0
    for beat = 1, DATA.extstate.CONF_ref_pattern_len2 + 1, divisionIn*4 do
      local outpos = beat-1
      if swingamtIn ~= 0 then 
        if id%2 ==1 then outpos = outpos + swingamtIn * divisionIn*2 end
      end
      DATA2.ref_pat[#DATA2.ref_pat + 1] = {pos_beats = outpos, val = 1}
      id = id + 1
    end
  end
  ---------------------------------------------------------------------- 
  function DATA2:GetAnchorPoints_gridcurrent()
    local retval, divisionIn, swingmodeIn, swingamtIn = GetSetProjectGrid( 0, false ) 
    if swingmodeIn == 0 then swingamtIn = 0 end 
    if not divisionIn then return end
    local id = 0
    for beat = 1, DATA.extstate.CONF_ref_pattern_len2 + 1, divisionIn*4 do
      local outpos = beat-1
      if swingamtIn ~= 0 then 
        if id%2 ==1 then outpos = outpos + swingamtIn * divisionIn*2 end
      end
      DATA2.ref_pat[#DATA2.ref_pat + 1] = {pos_beats = outpos, val = 1}
      id = id + 1
    end
  end
  ---------------------------------------------------------------------- 
  function DATA2:GetAnchorPoints_pattern()  
    if DATA.extstate.CONF_ref_grid&16 == 16 then 
      local name = DATA.extstate.CONF_ref_pattern_name
      local fp =  GetResourcePath()..'/Grooves/'..name..'.rgt'
      local f = io.open(fp, 'r')
      local content
      if f then 
        content = f:read("*all")
        f:close()
      end
      if not content or content == '' then return else DATA2:GetAnchorPoints_PatternParseRGT(content, false) end
    end
  end
  ---------------------------------------------------------------------- 
  function DATA2:GetAnchorPoints_PatternParseRGT(content, take_len)
    local len = content:match('Number of beats in groove: (%d+)')
    if len and take_len  and tonumber(len) then DATA.extstate.CONF_ref_pattern_len2 = tonumber(len) end
    local pat = '[%d%.%-%e]+'
    for line in content:gmatch('[^\r\n]+') do
    
      -- test first symb is number
        if not line:sub(1,1):match('%d') then goto next_line end
        
      -- pos
        local pos = tonumber(line:match(pat))
        local val = 1
        
        local check_val = line:match(pat..'%s('..pat..')')
        if check_val and tonumber(check_val) then val = tonumber(check_val) end
        
      if pos and val then DATA2.ref_pat[#DATA2.ref_pat +1] = {  pos_beats = pos, val = val} end
      
      
      ::next_line::
    end
  end 
  ---------------------------------------------------------------------- 
  function DATA2:GetAnchorPoints_EditCursor()
    local pos = GetCursorPositionEx( 0 ) 
    local beats = TimeMap2_timeToBeats( 0,  pos )
    DATA2.ref[#DATA2.ref+1] = { 
                            pos_sec = pos,
                            pos_beats = beats,
                            val = 1
                          }
  end
  ---------------------------------------------------------------------- 
  function DATA2:TimeSelMatchCondition(pos, ts_startb, ts_endb)
    return (pos >= ts_startb-0.0001 and pos <= ts_endb-0.001)
  end
  ---------------------------------------------------------------------- 
  function DATA2:GetAnchorPoints()
    DATA2.ref = {}
    DATA2.ref_pat = {}
    if DATA.extstate.CONF_ref_selitems&1==1 then DATA2:GetAnchorPoints_Items() end 
    if DATA.extstate.CONF_ref_envpoints&1==1 then DATA2:GetAnchorPoints_EP()  end
    if DATA.extstate.CONF_ref_midi&1==1 then DATA2:GetAnchorPoints_MIDI()  end
    if DATA.extstate.CONF_ref_strmarkers&1==1 then DATA2:GetAnchorPoints_SM()  end
    
    -- other stuff
    if DATA.extstate.CONF_ref_marker&1==1 then DATA2:GetAnchorPoints_Markers()  end
    if DATA.extstate.CONF_ref_timemarker&1==1 then DATA2:GetAnchorPoints_TempoMarkers()  end 
    if DATA.extstate.CONF_ref_editcur&1==1 then DATA2:GetAnchorPoints_EditCursor()  end 
    
    -- pattern
    if DATA.extstate.CONF_ref_grid&1==1 then  DATA2:GetAnchorPoints_grid()  end
    if DATA.extstate.CONF_ref_grid&2==2 then  DATA2:GetAnchorPoints_gridcurrent()  end
    if DATA.extstate.CONF_ref_grid&16==16 then  DATA2:GetAnchorPoints_pattern()  end
    
    -- sort ref table by position  
      local sortedKeys = getKeysSortedByValue(DATA2.ref, function(a, b) return a and b and a < b end, 'pos_sec')
      local t = {}
      for _, key in ipairs(sortedKeys) do t[#t+1] = DATA2.ref[key] end
      DATA2.ref = t
    
    -- filter time selection
      if DATA.extstate.CONF_act_catchreftimesel&1==1 then
        local ts_start, ts_end = GetSet_LoopTimeRange2( 0, false, false, 0, 0, false )
        local ts_startb, ts_endb =  ({TimeMap2_timeToBeats( 0, ts_start )})[4], ({TimeMap2_timeToBeats( 0, ts_end )})[4]
        for i = #DATA2.ref, 1, -1 do
          if not DATA2:TimeSelMatchCondition(DATA2.ref[i].pos_sec, ts_startb, ts_endb) then table.remove(DATA2.ref, i) end
        end
      end
      
    -- count active points
      DATA2.ref.src_cnt = #DATA2.ref
  end
  --------------------------------------------------------------------- 
  function DATA2:MarkerPoints_Clear() 
    local retval, num_markers, num_regions = CountProjectMarkers( 0 )
    for i = num_markers, 1, -1 do
      --local  retval, isrgn, pos, rgnend, name, markrgnindexnumber = EnumProjectMarkers( i-1 ) -- this remove existing mrkers
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0,i-1 )
      if name:lower():match('qt_')  then --name ~= '' and name ~= ' 'and 
        reaper.DeleteProjectMarker( 0, markrgnindexnumber, isrgn )
      end
    end
    for i = num_regions, 1, -1 do
      local  retval, isrgn, pos, rgnend, name, markrgnindexnumber = EnumProjectMarkers( i-1 )
      if name ~= '' and name:lower():match('qt_') then 
        reaper.DeleteProjectMarker( 0, markrgnindexnumber, isrgn )
      end
    end
  end
  --------------------------------------------------------------------- 
  function DATA2:MarkerPoints_Show(passed_t0, s16, is_pat)
    if not passed_t0 then return end
    local passed_t
    -- generate passed_t from pattern based on edit cursor
    if is_pat then 
      passed_t = {}
      local curpos = GetCursorPositionEx( 0 )
      local _, measures = TimeMap2_timeToBeats( 0, curpos )
      for i = 1, #passed_t0 do
        if passed_t0[i].pos_beats <= DATA.extstate.CONF_ref_pattern_len2 then
          local pos_sec = TimeMap2_beatsToTime( 0, passed_t0[i].pos_beats,measures )        
          local _, _, _, real_pos = reaper.TimeMap2_timeToBeats( 0, pos_sec ) 
          passed_t[#passed_t+1] = { pos_beats = real_pos,
                          val = passed_t0[i].val}
        end
      end
      local pos_rgn = TimeMap2_beatsToTime( 0, 0, measures ) 
      local end_rgn = TimeMap2_beatsToTime( 0, DATA.extstate.CONF_ref_pattern_len2, measures ) 
      local r,g,b = DATA:GUIhex2rgb(s16)
      AddProjectMarker2( 0, true, pos_rgn, end_rgn, 'QT_'.. DATA.extstate.CONF_ref_pattern_len2..' beats',
                           -1, --want id
                           ColorToNative( math.floor(r*255),math.floor(g*255),math.floor(b*255))  |0x1000000 )
     else
      passed_t = passed_t0
    end
    
    local imark = 0
    for i = 1, #passed_t do
      if not passed_t[i].ignore_search and passed_t[i].pos_beats then
        local pos_beats = passed_t[i].pos_beats
        local pos_sec = TimeMap2_beatsToTime( 0, pos_beats )
        local r,g,b = DATA:GUIhex2rgb(s16)
        
        local val_str = i 
        if passed_t[i].val then 
          val_str = passed_t[i].val
          if passed_t[i].val2 then val_str = val_str ..'_'..passed_t[i].val2 end
        end
        imark = imark + 1
        AddProjectMarker2( 0, false, 
                          pos_sec, 
                          -1, 
                          'QT_pos:'..VF_math_Qdec(pos_sec)..' val:'..VF_math_Qdec(val_str), 
                          imark, 
                          ColorToNative( math.floor(r*255),math.floor(g*255),math.floor(b*255))  |0x1000000 )
      end
    end
    
  end
  --------------------------------------------------------------------- 
  function DATA2:GetTargets()
    DATA2.src = {}
    
    if DATA.extstate.CONF_src_selitems&1==1 then DATA2:GetTargets_Items() end  
    if DATA.extstate.CONF_src_envpoints&1==1 then DATA2:GetTargets_EP() end   
    if DATA.extstate.CONF_src_midi&1==1 then DATA2:GetTargets_MIDI()  end 
    if DATA.extstate.CONF_src_strmarkers&1==1 then DATA2:GetTargets_SM() end 
    
    -- sort ref table by position 
    if DATA.extstate.CONF_act_action == 3 then 
      local sortedKeys = VF_getKeysSortedByValue(DATA2.src, function(a, b) return a < b end, 'pos')
      local t = {}
      for _, key in ipairs(sortedKeys) do t[#t+1] = DATA2.src[key] end
      DATA2.src = t
      
    end
  
    -- filter time selection
      if DATA.extstate.CONF_act_catchsrctimesel&1==1 then
        local ts_start, ts_end = GetSet_LoopTimeRange2( 0, false, false, 0, 0, false )
        local ts_startb, ts_endb =  ({TimeMap2_timeToBeats( 0, ts_start )})[4], ({TimeMap2_timeToBeats( 0, ts_end )})[4]
        for i = 1, #DATA2.src do
          if not DATA2:TimeSelMatchCondition(DATA2.src[i].pos_sec, ts_startb, ts_endb) and DATA2.src[i].ignore_search == false then DATA2.src[i].ignore_search = true end
        end
      end
              
          
  end
  --------------------------------------------------------------------- 
  function DATA2:Execute_Align_Items_UpdateItemsGroup(t, pos_shift, val_shift, len_diff, rate_diff)
    local groupID = t.groupID
    for i = 1 , #DATA2.src do
      local t1 = DATA2.src[i]
      if (not t1.group_master or (t1.group_master and t1.group_master == false) ) and t1.groupID== groupID then
        if pos_shift then 
          SetMediaItemInfo_Value( t1.ptr, 'D_POSITION' , t1.pos_sec + pos_shift)-- - pos_shift)
        end
        if val_shift then 
          SetMediaItemInfo_Value( t1.ptr, 'D_VOL' , t1.val + val_shift)
        end
        if len_diff then
          SetMediaItemInfo_Value( t1.ptr, 'D_LENGTH' , t1.it_len + len_diff)
        end
        if rate_diff then
          SetMediaItemTakeInfo_Value( t1.activetk_ptr, 'D_PLAYRATE',  t1.activetk_rate*rate_diff)
        end
        UpdateItemInProject( t1.ptr )
      end
    end
  end  
  --------------------------------------------------------------------- 
  function DATA2:Execute_Align_Items(iteration)
    local last_pos
    local val1 = DATA2.val1 or 0
    local val2 = DATA2.val2 or 0
    for i = 1 , #DATA2.src do
      local t = DATA2.src[i]
      if not t.ignore_search and t.group_master == true then
        local it =  t.ptr--BR_GetMediaItemByGUID( 0, t.GUID )
        if it then 
          if t.pos_secOUT then 
            local pos_secOUT = t.pos_sec + (t.pos_secOUT - t.pos_sec)*val1
            if t.position_has_snap_offs and t.srctype~='item_end' and DATA.extstate.CONF_src_selitems&2==2 then pos_secOUT = pos_secOUT - t.snapoffs_sec end  
                        
            if DATA.extstate.CONF_src_selitemsflag&1==1 and t.srctype~='item_end' and t.group_master == true and iteration == 1 then 
              SetMediaItemInfo_Value( it, 'D_POSITION', pos_secOUT )
              t.it_pos_change = pos_secOUT
              local pos_shift = pos_secOUT - t.pos_sec
              DATA2:Execute_Align_Items_UpdateItemsGroup(t, pos_shift)
            end
            
            if DATA.extstate.CONF_src_selitemsflag&2==2 and t.srctype=='item_end' and t.group_master == true and iteration == 2 and  t.parent_position_entry and DATA2.src[t.parent_position_entry] and DATA2.src[t.parent_position_entry].it_pos_change then
              local D_FADEOUTLEN = 0
              if DATA.extstate.CONF_src_selitemsflag&8==8 then D_FADEOUTLEN = t.D_FADEOUTLEN end
              local out_len = pos_secOUT - DATA2.src[t.parent_position_entry].it_pos_change  + D_FADEOUTLEN
              SetMediaItemInfo_Value( it, 'D_LENGTH', out_len)
              local len_diff = out_len - t.it_len
              DATA2:Execute_Align_Items_UpdateItemsGroup(t, nil, nil, len_diff)
              if DATA.extstate.CONF_src_selitemsflag&4==4 then
                local rate_diff = t.it_len/out_len
                SetMediaItemTakeInfo_Value( t.activetk_ptr, 'D_PLAYRATE',  t.activetk_rate*rate_diff)
                DATA2:Execute_Align_Items_UpdateItemsGroup(t, nil, nil, nil, rate_diff)
              end
            end 
          end 
          
          if t.valOUT then --and iteration == 3 then
            local val_shift = (t.valOUT - t.val)*val2
            SetMediaItemInfo_Value( it, 'D_VOL', t.val + val_shift)  
            DATA2:Execute_Align_Items_UpdateItemsGroup(t, nil, val_shift)
          end
          
          UpdateItemInProject( it )
        end
      end  
    end
  end
  --------------------------------------------------------------------- 
  function DATA2:Execute_Align_EnvPt()
    local val1 = DATA2.val1 or 0
    local val2 = DATA2.val2 or 0
    if not DATA2.src[1] then return end
    
    -- collect various takes
    local env_t = {}
    for i = 1 , #DATA2.src do
      local t = DATA2.src[i]
      local ptr = t.ptr_str
      if ptr then
        if not env_t [t.ptr_str] then env_t [t.ptr_str] = {} end
        env_t [ptr] [#env_t [ptr] + 1 ]  = CopyTable(t)
      end
    end
    for ptr_str in pairs(env_t ) do
      local env = env_t[ptr_str][1].ptr
      local last_AI_idx
      for i = 1, #env_t[ptr_str] do
        local t = env_t[ptr_str][i]
        local pos_secOUT = t.pos_sec
        local out_val = t.val
        if t.pos_secOUT then pos_secOUT = t.pos_sec + (t.pos_secOUT - t.pos_sec)*val1 end
        if t.valOUT then out_val = t.val + (t.valOUT - t.val)*val2 end 
        if t.item_pos then pos_secOUT  = (pos_secOUT - t.item_pos)*t.tk_rate end
        out_val = ScaleToEnvelopeMode( t.scaling_mode,out_val)
        SetEnvelopePointEx( env, t.AI_idx, t.ID, pos_secOUT, out_val, t.shape, t.tension, t.selected, true )
        last_AI_idx = t.AI_idx   
      end  
      Envelope_SortPointsEx( env, last_AI_idx )
    end
    UpdateArrange()
  end
  --------------------------------------------------------------------- 
  function DATA2:Execute_Align_MIDI_sub(take_t, take) 
    local val1 = DATA2.val1 or 0
    local val2 = DATA2.val2 or 0
    if not take then return end
    local str_per_msg  = ''
    local ppq_cur = 0
    for i = 1, #take_t do
      local t = take_t[i]
      
      local ppq_posOUT = t.ppq_pos
      
      if t.pos_secOUT then
        local pos_secOUT_sec = t.pos_sec + (t.pos_secOUT - t.pos_sec)*val1
        ppq_posOUT = MIDI_GetPPQPosFromProjTime( take, pos_secOUT_sec )
      end
      
      local out_val = t.val
      if t.out_val then
        out_val = t.val + (t.out_val - t.val)*val2
      end
            
      local out_offs = math.floor(ppq_posOUT-ppq_cur)
      
      if t.isNoteOn and DATA.extstate.CONF_src_midi_msgflag&1==1 then 
        local out_vel = math.max(1,math.floor(lim(out_val,0,1)*127))
        str_per_msg = str_per_msg.. string.pack("i4Bi4BBB", out_offs, t.flags, 3,  0x90| (t.chan-1), t.pitch, out_vel )
        
        if DATA.extstate.CONF_src_midi_msgflag&4==4 and ((DATA.extstate.CONF_src_midi&2==0 and t.flags&1 == 1) or DATA.extstate.CONF_src_midi&2==2) and t.noteoff_msg1 then
          str_per_msg = str_per_msg.. string.pack("i4Bs4",  t.note_len_PPQ,  t.flags , t.noteoff_msg1)
          ppq_cur = ppq_cur+ t.note_len_PPQ
        end
        ppq_cur = ppq_cur+ out_offs
                
       elseif t.isNoteOff then
        if DATA.extstate.CONF_src_midi_msgflag&2==2 then
          str_per_msg = str_per_msg.. string.pack("i4Bi4BBB", out_offs, t.flags, 3,  0x80| (t.chan-1), t.pitch, 0 )
          ppq_cur = ppq_cur+ out_offs 
         elseif DATA.extstate.CONF_src_midi_msgflag&4~=4 or (DATA.extstate.CONF_src_midi_msgflag&4==4 and DATA.extstate.CONF_src_midi&2==0 and t.flags&1 ~= 1)then
          str_per_msg = str_per_msg.. string.pack("i4Bs4", out_offs,  t.flags , t.msg1)
          ppq_cur = ppq_cur+ out_offs
        end   
        
       else
        str_per_msg = str_per_msg.. string.pack("i4Bs4", out_offs,  t.flags , t.msg1)
        ppq_cur = ppq_cur+ out_offs
      end
      
    end
    MIDI_SetAllEvts( take, str_per_msg )
    MIDI_Sort(take)
    local item = GetMediaItemTake_Item( take )
    UpdateItemInProject(item) 
  end
  --------------------------------------------------------------------- 
  function DATA2:Execute_Align_MIDI()  
    if #DATA2.src < 1 then return end 
    -- sort takes
    local takes_t = {}
    for i = 1 , #DATA2.src do
      local t = DATA2.src[i]
      if not takes_t [t.GUID] then takes_t [t.GUID] = {} end
      takes_t [t.GUID] [#takes_t [t.GUID] + 1 ]  = VF_CopyTable(t)
    end  
    -- loop takes
    for GUID in pairs(takes_t) do
      local take =  GetMediaItemTakeByGUID( 0, GUID )
      DATA2:Execute_Align_MIDI_sub(takes_t[GUID], take) 
    end
  end
  --------------------------------------------------------------------- 
  function DATA2:Execute_Align_SMChilds_GetOutPos(relproj_pos, tmaster, tslavepoint)
    for i = 1, #tmaster.smpoints do
      local tmasterpoint = tmaster.smpoints[i]
      if tmasterpoint.relproj_outpos and tmasterpoint.relproj_pos then
        local ptmin = tmasterpoint.relproj_outpos
        local ptmax = tmasterpoint.relproj_pos
        if tmasterpoint.relproj_outpos > tmasterpoint.relproj_pos then 
          ptmax = tmasterpoint.relproj_outpos
          ptmin = tmasterpoint.relproj_pos
        end
        if relproj_pos >= ptmin-0.01 and relproj_pos <= ptmax+0.01 then return tslavepoint.tk_rate * (tmasterpoint.relproj_outpos-tslavepoint.it_pos) end
      end
    end
  end
  --------------------------------------------------------------------- 
  function DATA2:Execute_Align_SMChilds(takes_t, it_groupID, tmaster)
    for GUID in pairs(takes_t) do
      local tslave = takes_t[GUID]
      if tslave.it_group_master~= true and tslave.smpoints and tslave.smpoints[1] and tslave.it_groupID ~= it_groupID and it_groupID ~= 0 then
        local take = tslave.smpoints[1].tk_ptr
        if take then
          -- remove existed
          local cur_cnt =  GetTakeNumStretchMarkers( take )
          DeleteTakeStretchMarkers( take, 0, cur_cnt )
          for i = 1, #tslave.smpoints do
            local tslavepoint = tslave.smpoints[i]
            tslavepoint.relproj_pos = tslavepoint.it_pos+tslavepoint.sm_pos_sec/tslavepoint.tk_rate
            local ret = DATA2:Execute_Align_SMChilds_GetOutPos(tslavepoint.relproj_pos, tmaster, tslavepoint)
            local outpos = tslavepoint.sm_pos_sec
            if ret then outpos = ret end
            SetTakeStretchMarker( take, -1, outpos, tslavepoint.srcpos_sec)
          end
          UpdateItemInProject( tslave.smpoints[1].it_ptr )
        end 
      end
    end
  end
  --------------------------------------------------------------------- 
  function DATA2:Execute_Align_SM()
    local val1 = DATA2.val1 or 0
    local val2 = DATA2.val2 or 0
    -- collect stuff from points scope to takes scope
      local takes_t = {}
      for i = 1 , #DATA2.src do
        local t = DATA2.src[i]
        if not takes_t [t.GUID] then takes_t [t.GUID] = {it_group_master = t.it_group_master, smpoints = {}} end
        takes_t [t.GUID].smpoints[#takes_t [t.GUID].smpoints + 1 ]  = CopyTable(t)
      end 
    
    -- align group masters
      for GUID in pairs(takes_t) do
        local tmaster = takes_t[GUID]
        if tmaster.it_group_master == true and tmaster.smpoints and tmaster.smpoints[1] then
          local take = tmaster.smpoints[1].tk_ptr
          if take then
            -- remove existed
            local cur_cnt =  GetTakeNumStretchMarkers( take )
            DeleteTakeStretchMarkers( take, 0, cur_cnt )
            for i = 1, #tmaster.smpoints do
              local tmasterpoint = tmaster.smpoints[i]
              local pos_secOUT
              if tmasterpoint.pos_secOUT then
                local pos_secOUT_sec = tmasterpoint.pos_secOUT
                pos_secOUT = (pos_secOUT_sec - tmasterpoint.it_pos)*tmasterpoint.tk_rate
                pos_secOUT = tmasterpoint.sm_pos_sec + (pos_secOUT - tmasterpoint.sm_pos_sec)*val1
                tmasterpoint.pos_secOUT_sec = pos_secOUT
               else
                pos_secOUT = tmasterpoint.sm_pos_sec
                tmasterpoint.pos_secOUT_sec = pos_secOUT
              end
              SetTakeStretchMarker( take, -1, pos_secOUT, tmasterpoint.srcpos_sec)
              tmasterpoint.relproj_outpos = tmasterpoint.it_pos+tmasterpoint.pos_secOUT_sec/tmasterpoint.tk_rate
              tmasterpoint.relproj_pos = tmasterpoint.it_pos+tmasterpoint.sm_pos_sec/tmasterpoint.tk_rate
            end
            UpdateItemInProject( tmaster.smpoints[1].it_ptr )
          end 
        end
        DATA2:Execute_Align_SMChilds(takes_t, tmaster.smpoints[1].it_groupID, tmaster)
      end
        
  end  
  --------------------------------------------------------------------- 
  function DATA2:Execute()  
    DATA2.val2 = DATA.extstate.CONF_act_valuealign -- get from config, knob 2 in the past
    if not DATA2.src or not DATA2.ref then return end
    if DATA.extstate.CONF_src_selitems&1==1 then    
      DATA2:Execute_Align_Items(1)  
      DATA2:Execute_Align_Items(2)  
      DATA2:Execute_Align_Items(3)  
    end
    if DATA.extstate.CONF_src_envpoints&1==1 then   DATA2:Execute_Align_EnvPt() end
    if DATA.extstate.CONF_src_midi&1==1 then        DATA2:Execute_Align_MIDI() end
    if DATA.extstate.CONF_src_strmarkers&1==1 then  DATA2:Execute_Align_SM() end   
  end
  --------------------------------------------------------------------- 
  function DATA2:Quantize()   
    if not DATA2.ref or not DATA2.src then return end  
    if DATA.extstate.CONF_act_action == 1 then DATA2:Quantize_CalculatePBA() end
    if DATA.extstate.CONF_act_action == 2 then DATA2:Quantize_CalculateOA() end
    DATA2.Quantize_state= true
  end
  --------------------------------------------------------------------- 
  function DATA2:Quantize_brutforce_RefID(pos_src)
    if not DATA2.ref_formed then return end
    if #DATA2.ref_formed < 1 then return end
    
    --[[local testID1 = 1
    local testID2 = #DATA2.ref_formed
    for i = 1, DATA.extstate.CONF_iterationlim do
      if testID2 - testID1 < 2 then return testID1 end
      local id1 = math.max(1,testID1-1)
      local id2 = math.min(#DATA2.ref_formed,testID2+1)
      local test_edge1 = DATA2.ref_formed[id1].pos_sec
      local test_edge2 = DATA2.ref_formed[id2].pos_sec
      if pos_src >= test_edge1 and pos_src <= test_edge2 then
        local midID = math.floor((testID1 + testID2) /2)
        local midpos = DATA2.ref_formed[midID].pos_sec
        if pos_src >= midpos and pos_src <= test_edge2 then 
          testID1 = midID
         else
          testID2 = midID
        end
      end
    end
    
    if pos_src < DATA2.ref_formed[1].pos_sec then return 1 end 
    if pos_src > DATA2.ref_formed[#DATA2.ref_formed].pos_sec then return #DATA2.ref_formed end ]]
    
    local edge1= 1
    local edge2= #DATA2.ref_formed
    
    -- filter_bounds 1st pass
      if  #DATA2.ref_formed > 10 then
        midID = edge1 + math.floor( (edge2-edge1) /2)
        local pos_ref = DATA2.ref_formed[midID].pos_sec
        if pos_src >= pos_ref then  
          edge1 = midID - 1
        end
      end

    -- filter_bounds 2nd pass
      if  #DATA2.ref_formed > 50 then
        midID = edge1 + math.floor( (edge2-edge1) /2)
        local pos_ref = DATA2.ref_formed[midID].pos_sec
        if pos_src >= pos_ref then  
          edge1 = midID - 1
        end
      end

    -- filter_bounds 3rd pass
      if  #DATA2.ref_formed > 100 then
        midID = edge1 + math.floor( (edge2-edge1) /2)
        local pos_ref = DATA2.ref_formed[midID].pos_sec
        if pos_src >= pos_ref then  
          edge1 = midID - 1
        end
      end
        
    local id = 1
    local min_diff = math.huge
    for i = edge1, edge2 do
      local pos_ref = DATA2.ref_formed[i].pos_sec
      local cur_diff = math.abs(pos_ref - pos_src)
      if cur_diff < min_diff then id = i end
      min_diff = math.min(min_diff, cur_diff) 
    end
    
    
    return id
  end
  --------------------------------------------------------------------- 
  function DATA2:Quantize_CalculatePBA_addpattern()
    DATA2.ref_formed = CopyTable(DATA2.ref)
    
    
    local edge_st = 10^31
    local edge_end = -10^31
    local edge_change = false
    local beats_def = 16
     
    if DATA2.src then
      for i = 1, #DATA2.src do
        local pos = DATA2.src[i].pos_sec
        edge_st = math.min(edge_st, pos)
        edge_end = math.max(edge_end, pos)
        edge_change = true
      end
    end
    
    local _, edge_st_measure, _, _, _ = reaper.TimeMap2_timeToBeats( 0, edge_st )
    local _, edge_end_measure, _, _, _ = reaper.TimeMap2_timeToBeats( 0, edge_end )
    if edge_change then 
      for i = 1, #DATA2.ref_pat do 
        for measures = math.max(0,edge_st_measure), edge_end_measure + 1 do
          local pos_sec =  TimeMap2_beatsToTime( 0, DATA2.ref_pat[i].pos_beats, measures )
          DATA2.ref_formed[#DATA2.ref_formed+1] = {pos_sec = pos_sec, val = DATA2.ref_pat[i].val}
        end
      end
     else return
    end
    
    -- sort ref table by position
      local id = {}
      for i = 1, #DATA2.ref_formed do 
        local pos = DATA2.ref_formed[i].pos_sec
        if DATA2.ref_formed[i].istakeenv then pos = pos + DATA2.ref_formed[i].item_pos end
        id[pos] = DATA2.ref_formed[i].val 
      end
      table.sort(id)
      DATA2.ref_formed = {}
      for key in spairs(id) do DATA2.ref_formed[#DATA2.ref_formed+1] = {pos_sec = key, val = id[key]} end
      
  end
  --------------------------------------------------------------------- 
  function DATA2:Quantize_CalculateOA() 
    if not DATA2.src then return end
    for i = 1, #DATA2.src do  
      if DATA2.src[i].pos_sec and DATA2.src[i].ignore_search == false then 
        if DATA2.ref[i] then
          local pos_secOUT, out_val = DATA2.ref[i].pos_sec, DATA2.ref[i].pos_val 
          DATA2.src[i].pos_secOUT = pos_secOUT
          DATA2.src[i].valOUT = out_val
        end
      end
    end
  end
  --------------------------------------------------------------------- 
  function DATA2:Quantize_CalculatePBA() 
    
    DATA2:Quantize_CalculatePBA_addpattern()  -- convert pattern into src edges
    
    if not DATA2.src then return end
    for i = 1, #DATA2.src do  
      if DATA2.src[i].pos_sec and DATA2.src[i].ignore_search == false then
        local pos_secOUT, out_val = DATA2.src[i].pos_sec, DATA2.src[i].pos_val
        --if DATA2.ref[i].istakeenv then pos_secOUT = pos_secOUT + DATA2.ref[i].item_pos end
        local refID = DATA2:Quantize_brutforce_RefID(DATA2.src[i].pos_sec)
        if refID and DATA2.ref_formed[refID] then 
          if DATA.extstate.CONF_act_aligndir == 1 then -- 1 - closest
            pos_secOUT = DATA2.ref_formed[refID].pos_sec
            out_val = DATA2.ref_formed[refID].val 
           elseif DATA.extstate.CONF_act_aligndir == 0 then-- 0 - always previous 
            if DATA2.src[i].pos_sec < DATA2.ref_formed[refID].pos_sec and DATA2.ref_formed[refID-1] then
              pos_secOUT = DATA2.ref_formed[refID-1].pos_sec
              out_val = DATA2.ref_formed[refID-1].val 
             else
              pos_secOUT = DATA2.ref_formed[refID].pos_sec
              out_val = DATA2.ref_formed[refID].val      
            end  
           elseif DATA.extstate.CONF_act_aligndir == 2 then--2 - always next
            if DATA2.src[i].pos_sec > DATA2.ref_formed[refID].pos_sec and DATA2.ref_formed[refID+1] then
              pos_secOUT = DATA2.ref_formed[refID+1].pos_sec
              out_val = DATA2.ref_formed[refID+1].val 
             else
              pos_secOUT = DATA2.ref_formed[refID].pos_sec
              out_val = DATA2.ref_formed[refID].val      
            end                               
          end   
        end
        
        DATA2.src[i].pos_secOUT = pos_secOUT
        DATA2.src[i].valOUT = out_val
      end
    end
  end
  --------------------------------------------------------------------- 
  function GUI_RESERVED_init_shortcuts(DATA)
    if DATA.extstate.UI_enableshortcuts == 0 then return end 
    DATA.GUI.shortcuts[32] = function() VF_Action(40044) end -- space to transport play
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_init(DATA)
    
    DATA.GUI.custom_mainbuth = 30
    DATA.GUI.custom_texthdef = 23
    DATA.GUI.custom_offset = math.floor(DATA.GUI.default_scale*DATA.GUI.default_txt_fontsz/2)
    DATA.GUI.custom_mainsepx = 400--(gfx.w/ 2)/GUI.default_scale
    DATA.GUI.custom_mainbutw = ((gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx)-DATA.GUI.custom_offset*2) / 2
    DATA.GUI.custom_scrollw = 10
    DATA.GUI.custom_frameascroll = 0.05
    DATA.GUI.custom_default_framea_normal = 0.1
    DATA.GUI.custom_spectralw = DATA.GUI.custom_mainbutw*3 + DATA.GUI.custom_offset*2
    DATA.GUI.custom_layerset= 21
    DATA.GUI.custom_datah = (gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth*3-DATA.GUI.custom_offset*6) /2
    DATA.GUI.custom_dataw = gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx-DATA.GUI.custom_offset
    
    DATA.GUI.default_data_a = 0.7-- normal
    DATA.GUI.default_data_a2 = 0.2 -- ignore serach
    
    DATA.GUI.default_data_col_adv = '#00ff00' -- green
    DATA.GUI.default_data_col_adv2 = '#e61919 ' -- red
    
    --[[ define compact mode
      local w,h = gfx.w,gfx.h
      DATA.GUI.compactmode = 0
      DATA.GUI.compactmodelimh = 200
      DATA.GUI.compactmodelimw = 500
      if w < DATA.GUI.compactmodelimw*DATA.GUI.default_scale or h < DATA.GUI.compactmodelimh*DATA.GUI.default_scale then DATA.GUI.compactmode = 1 end]]
    
    -- shortcuts
      GUI_RESERVED_init_shortcuts(DATA)
      
    GUI_buttons(DATA)
  end
  
  --------------------------------------------------------------------- 
  function GUI_buttons(DATA) 
    DATA.GUI.buttons = {} 
    -- main buttons
      DATA.GUI.buttons.getreference = { x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Get anchor points',
                            txt_short = 'Get AP',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            onmouseclick =  function() DATA2:GetAnchorPoints() GUI_initdata(DATA) end,
                            --hide = DATA.GUI.compactmode==1,
                            --ignoremouse = DATA.GUI.compactmode==1,
                            } 
      DATA.GUI.buttons.showreference = { x=DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbutw,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Show anchor points',
                            txt_short = 'Show AP',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            onmouseclick =  function() 
                                              if DATA.extstate.CONF_ref_grid>0 then--xtstate.CONF_ref_grid&16==16 or DATA.extstate.CONF_ref_grid&1==1) then
                                                DATA2:MarkerPoints_Show(DATA2.ref_pat, DATA.GUI.default_data_col_adv, true) 
                                               else
                                                DATA2:MarkerPoints_Show(DATA2.ref, DATA.GUI.default_data_col_adv, false) 
                                              end
                                            end,
                            onmouserelease = function() DATA2:MarkerPoints_Clear() end,
                            --hide = DATA.GUI.compactmode==1,
                            --ignoremouse = DATA.GUI.compactmode==1,
                            }                             
      DATA.GUI.buttons.getdub = { x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset*3 + DATA.GUI.custom_mainbuth+DATA.GUI.custom_datah,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Get targets',
                            txt_short = 'Get Targ',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            --hide = DATA.GUI.compactmode==1,
                            --ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() DATA2:GetTargets() GUI_initdata(DATA) end}
      DATA.GUI.buttons.showdub = { x=DATA.GUI.custom_offset*2+DATA.GUI.custom_mainbutw,
                            y=DATA.GUI.custom_offset*3 + DATA.GUI.custom_mainbuth+DATA.GUI.custom_datah,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Show targets',
                            txt_short = 'Show targ',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            onmouseclick =  function() DATA2:MarkerPoints_Show(DATA2.src, DATA.GUI.default_data_col_adv2) end,
                            onmouserelease = function() DATA2:MarkerPoints_Clear() end,
                            --hide = DATA.GUI.compactmode==1,
                            --ignoremouse = DATA.GUI.compactmode==1,
                            }  
      local frame_a, ignoremouse = 0, true
      if DATA.extstate.CONF_act_appbuttoexecute ==1 then frame_a,ignoremouse = nil, false end
      DATA.GUI.buttons.calcapp = { x=DATA.GUI.custom_offset,
                            y=DATA.GUI.custom_offset*5 + DATA.GUI.custom_mainbuth*2+DATA.GUI.custom_datah*2,
                            w=DATA.GUI.custom_mainbutw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Quantize',
                            txt_short = 'APP',
                            txt_col = '#00FF00',--'#FF0000',
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            ignoremouse = ignoremouse,
                            --hide = DATA.GUI.compactmode==1,
                            frame_a = frame_a,
                            frame_asel = frame_a,
                            onmouserelease = function() 
                                      if DATA.extstate.CONF_act_appbuttoexecute ==0 then return end
                                      DATA2:Execute() 
                                      Undo_OnStateChange2( 0, 'QuantizeTool' )  
                                    end
                            }      
      local knobw = (DATA.GUI.custom_mainbutw)---DATA.GUI.custom_offset /2  
      if not DATA2.val1 then DATA2.val1 = 0 end
      DATA.GUI.buttons.knob = { x=DATA.GUI.custom_offset*2 + DATA.GUI.custom_mainbutw ,
                            y=DATA.GUI.custom_offset*5 + DATA.GUI.custom_mainbuth*2+DATA.GUI.custom_datah*2,
                            w=knobw,
                            h=DATA.GUI.custom_mainbuth,
                            txt = VF_math_Qdec(DATA2.val1*100,2)..'%',
                            --txt_fontsz = DATA.GUI.default_txt_fontsz,
                            knob_isknob = true,
                            knob_showvalueright = true,
                            val_res = 0.25,
                            val = 0,
                            frame_a = DATA.GUI.default_framea_normal,
                            frame_asel = DATA.GUI.default_framea_normal,
                            back_sela = 0,
                            --hide = DATA.GUI.compactmode==1,
                            --ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =    function() DATA2:Quantize() end,
                            onmousedrag =     function() 
                                DATA.GUI.buttons.knob.txt = VF_math_Qdec(DATA2.val1*100,2)..'%'
                                DATA2.val1 = DATA.GUI.buttons.knob.val 
                                if DATA.extstate.CONF_act_appbuttoexecute ==0 then 
                                  DATA2:Execute()
                                end 
                              end,
                            onmouserelease  = function() 
                                DATA.GUI.buttons.knob.txt = VF_math_Qdec(DATA2.val1*100,2)..'%'
                                DATA2.val1 = DATA.GUI.buttons.knob.val 
                                if DATA.extstate.CONF_act_appbuttoexecute ==0 then 
                                  DATA2:Execute() 
                                  Undo_OnStateChange2( 0, 'QuantizeTool' )  
                                end 
                                DATA.GUI.buttons.knob.refresh = true
                              end,
                            onmousereleaseR  = function() 
                              if not DATA2.val1 then DATA2.val1 = 0 end
                              local retval, retvals_csv = GetUserInputs('Align percent', 1, '', VF_math_Qdec(DATA2.val1*100,2)..'%')
                              if not retval then return end
                              retvals_csv = tonumber(retvals_csv)
                              if not retvals_csv then return end
                              
                              DATA2.val1 = VF_lim(retvals_csv/100) 
                              DATA.GUI.buttons.knob.val = DATA2.val1
                              DATA.GUI.buttons.knob.txt = VF_math_Qdec(DATA2.val1*100,2)..'%'
                              if DATA.extstate.CONF_act_appbuttoexecute ==1 then return end
                              DATA2:Execute() 
                              Undo_OnStateChange2( 0, 'QuantizeTool' )  
                            end ,
                            onwheeltrig = function() 
                                            local mult = 0
                                            if not DATA.GUI.wheel_trig then return end
                                            if DATA.GUI.wheel_dir then mult =1 else mult = -1 end
                                            if not DATA2.Quantize_state then DATA2:Quantize()   end
                                            DATA2.val1 = VF_lim(DATA2.val1 - 0.01*mult, 0,1)
                                            DATA.GUI.buttons.knob.txt = 100*VF_math_Qdec(DATA2.val1,2)..'%'
                                            DATA.GUI.buttons.knob.val  = DATA2.val1
                                            if DATA.extstate.CONF_act_appbuttoexecute ==0 then 
                                              DATA2:Execute() 
                                              Undo_OnStateChange2( 0, 'QuantizeTool' )  
                                            end 
                                            DATA.GUI.buttons.knob.refresh = true
                                            
                                          end
                          } 
      DATA.GUI.buttons.preset = { x=DATA.GUI.custom_offset*3+DATA.GUI.custom_mainbutw*2,
                            y=DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainsepx-DATA.GUI.custom_offset*2,
                            h=DATA.GUI.custom_mainbuth,
                            txt = 'Preset: '..(DATA.extstate.CONF_NAME or ''),
                            txt_fontsz = DATA.GUI.default_txt_fontsz2,
                            --hide = DATA.GUI.compactmode==1,
                            --ignoremouse = DATA.GUI.compactmode==1,
                            onmouseclick =  function() DATA:GUIbut_preset(DATA) end} 
    -- settings
      DATA.GUI.buttons.Rsettings = { x=gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_mainsepx,
                            y=DATA.GUI.custom_mainbuth + DATA.GUI.custom_offset,
                            w=DATA.GUI.custom_mainsepx,
                            h=gfx.h/DATA.GUI.default_scale-DATA.GUI.custom_mainbuth - DATA.GUI.custom_offset,
                            txt = 'Settings',
                            --txt_fontsz = GUI.default_txt_fontsz3,
                            offsetframe_a = 0.1,
                            offsetframe = DATA.GUI.custom_offset,
                            frame_a = DATA.GUI.custom_default_framea_normal,
                            ignoremouse = true,
                            --hide = DATA.GUI.compactmode==1,
                            } 
                                              
    
      if DATA.GUI.custom_mainbutw/DATA.GUI.default_scale < 150 then
        local butw = math.floor(((gfx.w-DATA.GUI.custom_offset*6)/DATA.GUI.default_scale)/4)
        local buth = DATA.GUI.custom_mainbuth
        DATA.GUI.buttons.Rsettings.y = buth*3+DATA.GUI.custom_offset*3
        DATA.GUI.buttons.Rsettings.h = gfx.h/DATA.GUI.default_scale - (buth*3+DATA.GUI.custom_offset*3)
        
        DATA.GUI.buttons.getreference.x=DATA.GUI.custom_offset 
        DATA.GUI.buttons.getreference.y=DATA.GUI.custom_offset
        DATA.GUI.buttons.getreference.w=butw
        DATA.GUI.buttons.getreference.h=buth
        
        DATA.GUI.buttons.showreference.x=DATA.GUI.custom_offset*2 +butw
        DATA.GUI.buttons.showreference.y=DATA.GUI.custom_offset
        DATA.GUI.buttons.showreference.w=butw
        DATA.GUI.buttons.showreference.h=buth
                                      
        DATA.GUI.buttons.getdub.x=DATA.GUI.custom_offset*3 +butw*2
        DATA.GUI.buttons.getdub.y=DATA.GUI.custom_offset
        DATA.GUI.buttons.getdub.w=butw
        DATA.GUI.buttons.getdub.h=buth        
        
        DATA.GUI.buttons.showdub.x=DATA.GUI.custom_offset*4 +butw*3
        DATA.GUI.buttons.showdub.y=DATA.GUI.custom_offset
        DATA.GUI.buttons.showdub.w=butw
        DATA.GUI.buttons.showdub.h=buth        
        
        DATA.GUI.buttons.calcapp.x=DATA.GUI.custom_offset
        DATA.GUI.buttons.calcapp.y=DATA.GUI.custom_offset*2+buth
        DATA.GUI.buttons.calcapp.w=butw
        DATA.GUI.buttons.calcapp.h=buth   
        
        DATA.GUI.buttons.knob.x=DATA.GUI.custom_offset*2 +butw
        DATA.GUI.buttons.knob.y=DATA.GUI.custom_offset*2+buth
        DATA.GUI.buttons.knob.w=butw
        DATA.GUI.buttons.knob.h=buth   
        
        DATA.GUI.buttons.preset.x=DATA.GUI.custom_offset*3 +butw*2
        DATA.GUI.buttons.preset.y=DATA.GUI.custom_offset*2+buth
        DATA.GUI.buttons.preset.w=butw*2+DATA.GUI.custom_offset
        DATA.GUI.buttons.preset.h=buth    
        
        DATA.GUI.buttons.Rsettings.x=DATA.GUI.custom_offset
        DATA.GUI.buttons.Rsettings.y=DATA.GUI.custom_offset*3+buth*2
        DATA.GUI.buttons.Rsettings.w=gfx.w/DATA.GUI.default_scale - DATA.GUI.custom_offset*2
        DATA.GUI.buttons.Rsettings.h=gfx.h/DATA.GUI.default_scale-(DATA.GUI.custom_offset*3+buth*2)
        
      end
      
      GUI_initdata(DATA)
      DATA:GUIBuildSettings()
      
    --[[ define compact mode
      local w,h = gfx.w,gfx.h
      DATA.GUI.compactmode = 0
      DATA.GUI.compactmodelimh = 200
      DATA.GUI.compactmodelimw = 500
      if w < DATA.GUI.compactmodelimw*DATA.GUI.default_scale or h < DATA.GUI.compactmodelimh*DATA.GUI.default_scale then DATA.GUI.compactmode = 1 end]]
      
    for but in pairs(DATA.GUI.buttons) do DATA.GUI.buttons[but].key = but end                                 
    
  end
  -----------------------------------------------------------------------------  
    function GUI_RESERVED_draw_data(DATA, b)
      local t = b.val_data
      if not t then return end
      
      local w
      for pos in spairs(t) do 
        w = 1
        local pos_norm = VF_lim(pos)
        local val = t[pos]
        local y= math.floor(b.y+b.h-b.h*val)
        local h = math.floor(b.h*val)
        if tostring(pos)and tostring(pos):match('pat') then
          val = 0.1
          w = 3
          y= math.floor(b.y+b.h-b.h*val)
          h = math.floor(b.h*val)
        end
        local x = b.x + (b.w-b.x) * pos_norm
        gfx.rect(x * DATA.GUI.default_scale,y * DATA.GUI.default_scale,w,h * DATA.GUI.default_scale)
      end
      --[[
      local min_betweentxt_px = 20
      local edge_st = DATA2.edge_st
      local edge_end = DATA2.edge_end
      if not (b.val_data and edge_st and edge_end ) then return end
      
      local lasttext_pos = 0 
      DATA:GUIhex2rgb(DATA.GUI.default_data_col, true)
      local y = b.y
      local h = b.h
      for i = 1, #t do 
        local pos = t[i].pos_sec
        local txt = VF_math_Qdec(pos,1)
        if pos and y and h then 
          gfx.a = DATA.GUI.default_data_a
          if t[i].ignore_search==true then  gfx.a = DATA.GUI.default_data_a2 end
          local pos_norm = (pos - edge_st) / (edge_end - edge_st)
          local x = b.x + math.floor(pos_norm * (b.w-b.x))
          if x > DATA.GUI.custom_dataw then break end
          local val2 = 1
          if t[i].val then val2 = VF_lim(t[i].val) end
          val2 = (val2*0.9) + 0.1
          gfx.rect(x,math.floor(y+h-h*val2),1,math.floor(h*val2),1)
          gfx.x,gfx.y = x+2,y
          if b.val_data_draw then if lasttext_pos < gfx.x and x + gfx.measurestr(txt)<b.x+b.w then gfx.drawstr(txt) lasttext_pos = x + gfx.measurestr(txt) + min_betweentxt_px end end
          
        end
      end]]
    end
  ---------------------------------------------------------------------  
  function GUI_initdata(DATA) 
    if DATA.GUI.custom_mainbutw/DATA.GUI.default_scale < 150 then return end
    -- init data
      DATA.GUI.srcpoints = {}
      DATA.GUI.destpoints = {} 
      local project_end =  reaper.GetProjectLength( 0 )
      if project_end == 0 then return end 
      local _,project_end_measure, _, _, _ = reaper.TimeMap2_timeToBeats( 0, project_end )
    
    -- add anchor points
      if DATA2.ref then 
        for i = 1, #DATA2.ref do 
          local pos_sec = DATA2.ref[i].pos_sec
          if DATA2.ref[i].istakeenv and DATA2.ref[i].item_pos then pos_sec = pos_sec + DATA2.ref[i].item_pos end
          local val = DATA2.ref[i].val
          local pos_normal = pos_sec / project_end
          DATA.GUI.srcpoints[pos_normal] = val or 1
        end
      end
    -- add anchor pattern
      if DATA2.ref_pat then
        for i = 1, #DATA2.ref_pat do 
          for measures = 0, project_end_measure + 1 do
            local pos_sec =  TimeMap2_beatsToTime( 0, DATA2.ref_pat[i].pos_beats, measures )
            local pos_normal = pos_sec / project_end
            DATA.GUI.srcpoints[pos_normal] = DATA2.ref_pat[i].val or 1
          end
        end
      end
    -- add targets
      if DATA2.src then 
        for i = 1, #DATA2.src do 
          local pos_sec = DATA2.src[i].pos_sec
          local val = DATA2.src[i].val
          local pos_normal = pos_sec / project_end
          DATA.GUI.destpoints[pos_normal] = val or 1
        end
      end    
    
    local xdata = DATA.GUI.custom_offset
    DATA.GUI.buttons.anchpdata = { x=xdata, -- link to GUI.buttons.getreference
                            y=DATA.GUI.custom_mainbuth+DATA.GUI.custom_offset*2,
                            w=DATA.GUI.custom_dataw,
                            h=DATA.GUI.custom_datah,
                            ignoremouse = true,
                            hide = DATA.GUI.compactmode==1,
                            refresh = true,
                            val_data = DATA.GUI.srcpoints,
                            --frame_a =1
                            } 
    DATA:GUIquantizeXYWH(DATA.GUI.buttons.refdata)
    
    DATA.GUI.buttons.targdata = { x=xdata, -- link to GUI.buttons.getreference
                            y=DATA.GUI.custom_mainbuth*2+DATA.GUI.custom_offset*4 + DATA.GUI.custom_datah,
                            w=DATA.GUI.custom_dataw,
                            h=DATA.GUI.custom_datah,
                            ignoremouse = true,
                            hide = DATA.GUI.compactmode==1,
                            refresh = true,
                            val_data = DATA.GUI.destpoints,
                            --frame_a = 0.5
                            } 
      DATA:GUIquantizeXYWH(DATA.GUI.buttons.targdata) 
  end
  ---------------------------------------------------------------------  
  function GUI_swsgroovesmenu_GetListedFile(path, fname_check, position)
          -- get files list
          local files = {}
          local i = 0
          repeat
          local file = reaper.EnumerateFiles( path, i )
          if file then
            files[#files+1] = file
          end
          i = i+1
          until file == nil
          
          if not position then return files end
          
        -- search file list
          for i = 1, #files do
            --if files[i]:gsub('%%',''):lower():match(literalize(fname_check:lower():gsub('%%',''))) then 
            local ref_file = VF_deliteralize(files[i]:lower())
            local test_file = VF_deliteralize(fname_check:lower())
            if ref_file:match(test_file) then 
              if position == -1 then -- prev
                if i ==1 then return files[#files] else return files[i-1] end
               elseif position == 1 then -- next
                if i ==#files then return files[1] else return files[i+1] end
              end
            end
          end
          return files[1]
        end

  --------------------------------------------------------------------- 
  ---------------------------------------------------------------------  
  function DATA2:ProcessAtChange(DATA, appatchange_flags0)
    if DATA.extstate.UI_appatchange&1~=1 then return end
    local appatchange_flags = appatchange_flags0 or 0
    if appatchange_flags&1==1 then DATA2:GetAnchorPoints() end
    if appatchange_flags&2==2 then DATA2:GetTargets() end
    if appatchange_flags>0 then GUI_initdata(DATA) end
  end
  ---------------------------------------------------------------------  
  function GUI_RESERVED_BuildSettings(DATA)   
    local readoutw_extw = 150
    
    -- grid
      local cust_grid
      if DATA.extstate.CONF_ref_grid&2==0 then cust_grid = DATA.extstate.CONF_ref_grid_val end
      local grid_division, grid_str, is_triplet, grid_swingmode, grid_swingamt, grid_swingamt_format = VF_GetFormattedGrid(cust_grid)
      if DATA.extstate.CONF_ref_grid&2==0 and DATA.extstate.CONF_ref_grid&4 == 4 then is_triplet  = true end
      if DATA.extstate.CONF_ref_grid&2==0 and  DATA.extstate.CONF_ref_grid&8 == 8 then 
        grid_swingamt = DATA.extstate.CONF_ref_grid_sw
        grid_swingamt_format  = math.floor(DATA.extstate.CONF_ref_grid_sw *100)..'%'
      end 
      if is_triplet then grid_str = grid_str..'T' end
      if grid_swingamt ~= 0 then grid_str = grid_str..' swing '..grid_swingamt_format end
    
    
    -- SWS
      local readoutw_extwSWSgr = 300
      local f_table = GUI_swsgroovesmenu_GetListedFile(GetResourcePath()..'/Grooves/')
      local SWSgr = {}
      for i = 1 , #f_table do 
        if f_table[i]:match('%.rgt') then
          SWSgr[f_table[i]:gsub('%.rgt', '')] = f_table[i]
        end
      end
      
      
    local  t = 
    { 
      {str = 'Global' ,                                   group = 1, itype = 'sep'},
        {str = 'Detect anchor points on initialization' , group = 1, itype = 'check', confkey = 'CONF_act_initcatchref', level = 1},
        {str = 'Obey time selection for anchor points' ,  group = 1, itype = 'check', confkey = 'CONF_act_catchreftimesel', level = 1},
        {str = 'Detect targets on initialization' ,       group = 1, itype = 'check', confkey = 'CONF_act_initcatchsrc', level = 1},
        {str = 'Obey time selection for targets' ,        group = 1, itype = 'check', confkey = 'CONF_act_catchsrctimesel', level = 1},
        {str = 'Knob to set value, APP to execute' ,      group = 1, itype = 'check', confkey = 'CONF_act_appbuttoexecute', level = 1, func_onrelease = function() DATA.UPD.onGUIinit = true end},
        
      {str = 'Anchor points' ,                            group = 2, itype = 'sep'},
        {str = 'Items' ,                                  group = 2, itype = 'check', confkey = 'CONF_ref_selitems', confkeybyte = 0, level = 1},
          {str = 'Obey snap offset' ,                     group = 2, itype = 'check', confkey = 'CONF_ref_selitems', confkeybyte = 1, level = 2, hide = DATA.extstate.CONF_ref_selitems&1~=1},
          {str = 'Used value' ,                           group = 2, itype = 'readout', confkey = 'CONF_ref_selitems_value', level = 2, hide = DATA.extstate.CONF_ref_selitems&1~=1, menu = {[0]='Item volume',[1]='Audio Peak',[2]='Audio RMS'},readoutw_extw = readoutw_extw,},
        {str = 'Envelope points' ,                        group = 2, itype = 'check', confkey = 'CONF_ref_envpoints', level = 1},
          {str = 'Source' ,                               group = 2, itype = 'readout', confkey = 'CONF_ref_envpointsflags', level = 2, hide = DATA.extstate.CONF_ref_envpoints&1~=1, menu = {[1]='Selected envelope',[2]='All envelopes',[4]='Automation Item'},readoutw_extw = readoutw_extw},
        {str = 'MIDI' ,                                   group = 2, itype = 'check', confkey = 'CONF_ref_midi', level = 1},
          {str = 'Source' ,                               group = 2, itype = 'readout', confkey = 'CONF_ref_midiflags', level = 2, hide = DATA.extstate.CONF_ref_midi~=1, menu={[1]='MIDI Editor',[2]='Selected items'},readoutw_extw = readoutw_extw},
          {str = 'NoteOn' ,                               group = 2, itype = 'check', confkey = 'CONF_ref_midi_msgflag', level = 2, hide = DATA.extstate.CONF_ref_midi~=1, confkeybyte = 0},
          {str = 'NoteOff' ,                              group = 2, itype = 'check', confkey = 'CONF_ref_midi_msgflag', level = 2, hide = DATA.extstate.CONF_ref_midi~=1, confkeybyte = 1},
        {str = 'Stretch markers' ,                        group = 2, itype = 'check', confkey = 'CONF_ref_strmarkers', level = 1},
        {str = 'Project markers' ,                        group = 2, itype = 'check', confkey = 'CONF_ref_marker', level = 1},
        {str = 'Edit Cursor' ,                            group = 2, itype = 'check', confkey = 'CONF_ref_editcur', level = 1},
        {str = 'Tempo markers' ,                          group = 2, itype = 'check', confkey = 'CONF_ref_timemarker', level = 1},
        
      {str = 'Anchor points pattern' ,                    group = 3, itype = 'sep'},
        {str = 'Custom Grid ('..grid_str..')' ,           group = 3, itype = 'check', confkey = 'CONF_ref_grid', level = 1},
          {str = '/ 2' ,                                  group = 3, itype = 'button', level = 2, hide = DATA.extstate.CONF_ref_grid&1~=1, func = function() DATA.extstate.CONF_ref_grid_val = VF_lim(DATA.extstate.CONF_ref_grid_val / 2, 1/128, 1) end },
          {str = '* 2' ,                                  group = 3, itype = 'button', level = 2, hide = DATA.extstate.CONF_ref_grid&1~=1, func = function() DATA.extstate.CONF_ref_grid_val = VF_lim(DATA.extstate.CONF_ref_grid_val * 2, 1/128, 1) end },
          {str = 'Triplet' ,                              group = 3, itype = 'check', level = 2, hide = DATA.extstate.CONF_ref_grid&1~=1, confkey='CONF_ref_grid', confkeybyte = 2},
          {str = 'Swing' ,                                group = 3, itype = 'check', level = 2, hide = DATA.extstate.CONF_ref_grid&1~=1, confkey='CONF_ref_grid', confkeybyte = 3},
          {str = 'Swing value' ,                          group = 3, itype = 'readout', level = 2, hide = DATA.extstate.CONF_ref_grid&1~=1, confkey ='CONF_ref_grid_sw', val_res = 0.05, ispercentvalue = true},
        {str = 'Project Grid' ,                           group = 3, itype = 'check', confkey = 'CONF_ref_grid', level = 1, confkeybyte = 1},
        {str = 'SWS Groove' ,                           group = 3, itype = 'check', confkey='CONF_ref_grid', level = 1, confkeybyte = 4},
          {str = '' ,                               group = 3, itype = 'readout', confkey='CONF_ref_pattern_name', level = 2, menu=SWSgr,readoutw_extw = readoutw_extwSWSgr },
        {str = 'Pattern length (beats)' ,                 group = 3, itype = 'readout', confkey = 'CONF_ref_pattern_len2', level = 1, menu = { [4]='4', [8]='8', [16]='16' },}, 
        
      {str = 'Targets' ,                                  group = 4, itype = 'sep'},
        {str = 'Items' ,                                  group = 4, itype = 'check', confkey = 'CONF_src_selitems', level = 1},
          {str = 'Items start positions' ,                group = 4, itype = 'check', confkey = 'CONF_src_selitemsflag', confkeybyte=0, level = 2,hide = DATA.extstate.CONF_src_selitems&1~=1,},
          {str = 'Items end positions' ,                  group = 4, itype = 'check', confkey = 'CONF_src_selitemsflag', confkeybyte=1, level = 2,hide = DATA.extstate.CONF_src_selitems&1~=1,},
          {str = 'Obey snap offset' ,                     group = 4, itype = 'check', confkey = 'CONF_src_selitems', confkeybyte=1, level = 2,hide = DATA.extstate.CONF_src_selitems&1~=1,},
          {str = 'Stretch item instead move' ,            group = 4, itype = 'check', confkey = 'CONF_src_selitemsflag', confkeybyte=2, level = 2,hide = DATA.extstate.CONF_src_selitems&1~=1,},
          {str = 'Offset by auto fadeout length' ,        group = 4, itype = 'check', confkey = 'CONF_src_selitemsflag', confkeybyte=3, level = 2,hide = DATA.extstate.CONF_src_selitems&1~=1,},
        {str = 'Envelope points' ,                        group = 4, itype = 'check', confkey = 'CONF_src_envpoints', level = 1},
          {str = 'Destination' ,                          group = 4, itype = 'readout', confkey = 'CONF_src_envpointsflags', level = 2, hide = DATA.extstate.CONF_src_envpoints&1~=1, menu = {[1]='Selected envelope',[2]='All envelopes',[4]='Automation Item'},readoutw_extw = readoutw_extw},
        {str = 'MIDI' ,                                   group = 4, itype = 'check', confkey = 'CONF_src_midi', level = 1},
          {str = 'Destination' ,                          group = 4, itype = 'readout', confkey = 'CONF_src_midiflags', level = 2, hide = DATA.extstate.CONF_src_midi~=1, menu={[1]='MIDI Editor',[2]='Selected items'},readoutw_extw = readoutw_extw},
          {str = 'NoteOn' ,                               group = 4, itype = 'check', confkey = 'CONF_src_midi_msgflag', level = 2, hide = DATA.extstate.CONF_src_midi~=1, confkeybyte = 0},
          {str = 'NoteOff' ,                              group = 4, itype = 'check', confkey = 'CONF_src_midi_msgflag', level = 2, hide = DATA.extstate.CONF_src_midi~=1, confkeybyte = 1},
          {str = 'Preserve notes length' ,                group = 4, itype = 'check', confkey = 'CONF_src_midi_msgflag', level = 2, hide = DATA.extstate.CONF_src_midi~=1, confkeybyte = 2},
        {str = 'Stretch markers' ,                        group = 4, itype = 'check', confkey = 'CONF_src_strmarkers', level = 1},
        
      {str = 'Action' ,                                   group = 6, itype = 'sep'}, 
        {str = 'Position-based alignment' ,               group = 6, itype = 'check', confkey = 'CONF_act_action', level = 1, isset = 1, tooltip='Search and brutforce closer objects'},
          {str = 'Direction' ,group = 6, itype = 'readout', confkey = 'CONF_act_aligndir', level = 2, hide = DATA.extstate.CONF_act_action~=1, menu={[0]='Always previous point',[1]='Closest point',[2]='Always next point'},readoutw_extw = readoutw_extw},
        {str = 'Ordered alignment' ,                      group = 6, itype = 'check', confkey = 'CONF_act_action', level = 1, isset = 2, tooltip='Align by point order'},   
        {str = 'Align value (velocity, gain)' ,           group = 6, itype = 'readout', confkey = 'CONF_act_valuealign', level = 1, val_res = 0.05, val_format = function(x) return math.floor(x*100)..'%' end,val_format_rev = function(x) if not (x and tonumber(x)) then return 0 end return tonumber(x)/100 end },   

      {str = 'UI options' ,                               group = 5, itype = 'sep'},  
        {str = 'Enable shortcuts' ,                       group = 5, itype = 'check', confkey = 'UI_enableshortcuts', level = 1},
        {str = 'Init UI at mouse position' ,              group = 5, itype = 'check', confkey = 'UI_initatmouse', level = 1},
        {str = 'Show tootips' ,                           group = 5, itype = 'check', confkey = 'UI_showtooltips', level = 1},
        {str = 'Process on settings change',              group = 5, itype = 'check', confkey = 'UI_appatchange', level = 1},
        
    }
    
    -- add confirm function
      for key in pairs(t) do
        if (t[key].group == 2 or t[key].group == 3) and itype ~= 'sep' then t[key].func_onrelease = function() DATA2:ProcessAtChange(DATA, 1) end end
        if t[key].group == 4 and itype ~= 'sep' then t[key].func_onrelease = function() DATA2:ProcessAtChange(DATA, 2) end end
      end
    return t
    
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.15) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then main() end end