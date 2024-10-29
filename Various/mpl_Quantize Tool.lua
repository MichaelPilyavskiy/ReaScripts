-- @description QuantizeTool
-- @version 4.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=165672
-- @about Script for manipulating REAPER objects time and values
-- @changelog
--    + Ported to ReaImGui
--    # prevent using NF_AnalyzeMediaItemPeakAndRMS if not available




--------------------------------------------------------------------------------  init globals
  for key in pairs(reaper) do _G[key]=reaper[key] end 
  app_vrs = tonumber(GetAppVersion():match('[%d%.]+'))
  if app_vrs < 7 then return reaper.MB('This script require REAPER 7.0+','',0) end 
  local ImGui
  
  if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
  package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  ImGui = require 'imgui' '0.9.3.1'
  
  
-------------------------------------------------------------------------------- init external defaults 
EXT = {
        viewport_posX = 0,
        viewport_posY = 0,
        viewport_posW = 600,
        viewport_posH = 480,
        
        preset_base64_user = '',
        update_presets = 1, -- grab presets ONCE from old version
        
        UI_compactmode =1,
        UI_appatchange = 0,
        
        -- global
        CONF_name = 'default',
        CONF_act_initcatchref = 1 ,  -- catch ref on init
        CONF_act_catchreftimesel = 0 , 
        CONF_act_initcatchsrc = 1 ,
        CONF_act_catchsrctimesel = 0 , 
        CONF_act_initapp = 0,
        --CONF_act_initact = 0  ,
        CONF_act_appbuttoexecute = 0,
        
        
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
        CONF_src_selitems = 1,-- &2 == snap offset
        CONF_src_selitemsflag = 1, -- &1 positions &2 length &4 stretch &8 offset by autofadeout
        CONF_src_envpoints = 0,
        CONF_src_envpointsflags =1, -- ==1 selected ==2 all selected --==4 selected AI
        CONF_src_envpointsflag = 1, -- 1 values
        CONF_src_midi = 0 ,
        CONF_src_midi_fixnoteonvel0 = 0 ,
        CONF_src_midiflags = 1 ,
        CONF_src_midi_msgflag = 5,--&1 note on &2 note off &4 preserve length
        CONF_src_strmarkers = 0,
            
            
        -- action -----------------------
        --  align
        CONF_act_action = 1 ,  -- 2 create -- 3 ordered alignment -- 4 raw quantize
        CONF_act_aligndir = 1, -- 0 - always previous 1 - closest 2 - always next
        CONF_act_valuealign = 0, -- knob2 in the past
        CONF_offset_ms = 0,
        CONF_maxquantize_ms = 0, -- limit distance
        CONF_maxquantize_ignoreatreach = 0, -- limit distance
        CONF_minquantize_ms = 0, -- limit distance
        CONF_act_groupmode = 0, -- interpret closer items as group
        CONF_act_groupmode_valbeats = 0.015625, 
        CONF_act_groupmode_obeypitch = 0, 
        CONF_act_groupmode_direction = 0, -- 0 first note 1 between first and last 2 last
            
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
-------------------------------------------------------------------------------- INIT data
DATA = {
        ES_key = 'MPL_QuantizeTool',
        UI_name = 'Quantize Tool', 
        upd = true, 
        preset_name = 'untitled', -- for inputtext
        presets_factory = {
          ['Align items to edit cursor'] = 'CkNPTkZfTkFNRT1BbGlnbiBpdGVtcyB0byBlZGl0IGN1cnNvcgpDT05GX2FjdF9hY3Rpb249MQpDT05GX2FjdF9hbGlnbmRpcj0xCkNPTkZfYWN0X2NhdGNocmVmdGltZXNlbD0wCkNPTkZfYWN0X2NhdGNoc3JjdGltZXNlbD0wCkNPTkZfYWN0X2luaXRhcHA9MApDT05GX2FjdF9pbml0Y2F0Y2hyZWY9MQpDT05GX2FjdF9pbml0Y2F0Y2hzcmM9MQpDT05GX2NvbnZlcnRub3Rlb252ZWwwdG9ub3Rlb2ZmPTAKQ09ORl9lbnZzdGVwcz0wCkNPTkZfZXhjbHdpdGhpbj0wCkNPTkZfaW5jbHdpdGhpbj0wCkNPTkZfaW5pdGF0bW91c2Vwb3M9MApDT05GX2l0ZXJhdGlvbmxpbT0zMDAwMApDT05GX29mZnNldD0wLjUKQ09ORl9yZWZfZWRpdGN1cj0xCkNPTkZfcmVmX2VudnBvaW50cz0wCkNPTkZfcmVmX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9yZWZfZ3JpZD0wCkNPTkZfcmVmX2dyaWRfc3c9MApDT05GX3JlZl9ncmlkX3ZhbD0wLjUKQ09ORl9yZWZfbWFya2VyPTAKQ09ORl9yZWZfbWlkaT0wCkNPTkZfcmVmX21pZGlfbXNnZmxhZz0xCkNPTkZfcmVmX21pZGlmbGFncz0xCkNPTkZfcmVmX3BhdHRlcm49MApDT05GX3JlZl9wYXR0ZXJuX2dlbnNyYz0xCkNPTkZfcmVmX3BhdHRlcm5fbGVuMj04CkNPTkZfcmVmX3BhdHRlcm5fbmFtZT1sYXN0X3RvdWNoZWQKQ09ORl9yZWZfc2VsaXRlbXM9MApDT05GX3JlZl9zZWxpdGVtc192YWx1ZT0wCkNPTkZfcmVmX3N0cm1hcmtlcnM9MApDT05GX3JlZl90aW1lbWFya2VyPTAKQ09ORl9zcmNfZW52cG9pbnRzPTAKQ09ORl9zcmNfZW52cG9pbnRzZmxhZz0xCkNPTkZfc3JjX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9zcmNfbWlkaT0wCkNPTkZfc3JjX21pZGlfbXNnZmxhZz01CkNPTkZfc3JjX21pZGlmbGFncz0xCkNPTkZfc3JjX3Bvc2l0aW9ucz0xCkNPTkZfc3JjX3NlbGl0ZW1zPTEKQ09ORl9zcmNfc2VsaXRlbXNmbGFnPTEKQ09ORl9zcmNfc3RybWFya2Vycz0w',
          ['Align items to project grid'] = 'CkNPTkZfTkFNRT1BbGlnbiBpdGVtcyB0byBwcm9qZWN0IGdyaWQKQ09ORl9hY3RfYWN0aW9uPTEKQ09ORl9hY3RfYWxpZ25kaXI9MQpDT05GX2FjdF9jYXRjaHJlZnRpbWVzZWw9MApDT05GX2FjdF9jYXRjaHNyY3RpbWVzZWw9MApDT05GX2FjdF9pbml0YXBwPTAKQ09ORl9hY3RfaW5pdGNhdGNocmVmPTEKQ09ORl9hY3RfaW5pdGNhdGNoc3JjPTEKQ09ORl9jb252ZXJ0bm90ZW9udmVsMHRvbm90ZW9mZj0wCkNPTkZfZW52c3RlcHM9MApDT05GX2V4Y2x3aXRoaW49MApDT05GX2luY2x3aXRoaW49MApDT05GX2luaXRhdG1vdXNlcG9zPTAKQ09ORl9pdGVyYXRpb25saW09MzAwMDAKQ09ORl9vZmZzZXQ9MC41CkNPTkZfcmVmX2VkaXRjdXI9MApDT05GX3JlZl9lbnZwb2ludHM9MApDT05GX3JlZl9lbnZwb2ludHNmbGFncz0xCkNPTkZfcmVmX2dyaWQ9MgpDT05GX3JlZl9ncmlkX3N3PTAKQ09ORl9yZWZfZ3JpZF92YWw9MC41CkNPTkZfcmVmX21hcmtlcj0wCkNPTkZfcmVmX21pZGk9MApDT05GX3JlZl9taWRpX21zZ2ZsYWc9MQpDT05GX3JlZl9taWRpZmxhZ3M9MQpDT05GX3JlZl9wYXR0ZXJuPTAKQ09ORl9yZWZfcGF0dGVybl9nZW5zcmM9MQpDT05GX3JlZl9wYXR0ZXJuX2xlbjI9OApDT05GX3JlZl9wYXR0ZXJuX25hbWU9bGFzdF90b3VjaGVkCkNPTkZfcmVmX3NlbGl0ZW1zPTAKQ09ORl9yZWZfc2VsaXRlbXNfdmFsdWU9MApDT05GX3JlZl9zdHJtYXJrZXJzPTAKQ09ORl9yZWZfdGltZW1hcmtlcj0wCkNPTkZfc3JjX2VudnBvaW50cz0wCkNPTkZfc3JjX2VudnBvaW50c2ZsYWc9MQpDT05GX3NyY19lbnZwb2ludHNmbGFncz0xCkNPTkZfc3JjX21pZGk9MApDT05GX3NyY19taWRpX21zZ2ZsYWc9NQpDT05GX3NyY19taWRpZmxhZ3M9MQpDT05GX3NyY19wb3NpdGlvbnM9MQpDT05GX3NyY19zZWxpdGVtcz0xCkNPTkZfc3JjX3NlbGl0ZW1zZmxhZz0xCkNPTkZfc3JjX3N0cm1hcmtlcnM9MA==',
          ['Align item MIDI notes to project grid'] = 'CkNPTkZfTkFNRT1BbGlnbiBzZWxlY3RlZCBpdGVtIG5vdGVzIHRvIHByb2plY3QgZ3JpZApDT05GX2FjdF9hY3Rpb249MQpDT05GX2FjdF9hbGlnbmRpcj0xCkNPTkZfYWN0X2NhdGNocmVmdGltZXNlbD0wCkNPTkZfYWN0X2NhdGNoc3JjdGltZXNlbD0wCkNPTkZfYWN0X2luaXRhcHA9MApDT05GX2FjdF9pbml0Y2F0Y2hyZWY9MQpDT05GX2FjdF9pbml0Y2F0Y2hzcmM9MQpDT05GX2NvbnZlcnRub3Rlb252ZWwwdG9ub3Rlb2ZmPTAKQ09ORl9lbnZzdGVwcz0wCkNPTkZfZXhjbHdpdGhpbj0wCkNPTkZfaW5jbHdpdGhpbj0wCkNPTkZfaW5pdGF0bW91c2Vwb3M9MApDT05GX2l0ZXJhdGlvbmxpbT0zMDAwMApDT05GX29mZnNldD0wLjUKQ09ORl9yZWZfZWRpdGN1cj0wCkNPTkZfcmVmX2VudnBvaW50cz0wCkNPTkZfcmVmX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9yZWZfZ3JpZD0yCkNPTkZfcmVmX2dyaWRfc3c9MApDT05GX3JlZl9ncmlkX3ZhbD0wLjUKQ09ORl9yZWZfbWFya2VyPTAKQ09ORl9yZWZfbWlkaT0wCkNPTkZfcmVmX21pZGlfbXNnZmxhZz0xCkNPTkZfcmVmX21pZGlmbGFncz0xCkNPTkZfcmVmX3BhdHRlcm49MApDT05GX3JlZl9wYXR0ZXJuX2dlbnNyYz0xCkNPTkZfcmVmX3BhdHRlcm5fbGVuMj04CkNPTkZfcmVmX3BhdHRlcm5fbmFtZT1sYXN0X3RvdWNoZWQKQ09ORl9yZWZfc2VsaXRlbXM9MApDT05GX3JlZl9zZWxpdGVtc192YWx1ZT0wCkNPTkZfcmVmX3N0cm1hcmtlcnM9MApDT05GX3JlZl90aW1lbWFya2VyPTAKQ09ORl9zcmNfZW52cG9pbnRzPTAKQ09ORl9zcmNfZW52cG9pbnRzZmxhZz0xCkNPTkZfc3JjX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9zcmNfbWlkaT0xCkNPTkZfc3JjX21pZGlfbXNnZmxhZz01CkNPTkZfc3JjX21pZGlmbGFncz0yCkNPTkZfc3JjX3Bvc2l0aW9ucz0xCkNPTkZfc3JjX3NlbGl0ZW1zPTAKQ09ORl9zcmNfc2VsaXRlbXNmbGFnPTEKQ09ORl9zcmNfc3RybWFya2Vycz0w',
          ['Align stretch markers sequentally'] = 'CkNPTkZfTkFNRT1BbGlnbiBzdHJldGNoIG1hcmtlcnMgc2VxdWVudGFsbHkKQ09ORl9hY3RfYWN0aW9uPTIKQ09ORl9hY3RfYWxpZ25kaXI9MQpDT05GX2FjdF9hcHBidXR0b2V4ZWN1dGU9MApDT05GX2FjdF9jYXRjaHJlZnRpbWVzZWw9MApDT05GX2FjdF9jYXRjaHNyY3RpbWVzZWw9MApDT05GX2FjdF9ncm91cG1vZGU9MApDT05GX2FjdF9ncm91cG1vZGVfZGlyZWN0aW9uPTAKQ09ORl9hY3RfZ3JvdXBtb2RlX29iZXlwaXRjaD0wCkNPTkZfYWN0X2dyb3VwbW9kZV92YWxiZWF0cz0wLjAxNTYyNQpDT05GX2FjdF9pbml0YXBwPTAKQ09ORl9hY3RfaW5pdGNhdGNocmVmPTEKQ09ORl9hY3RfaW5pdGNhdGNoc3JjPTEKQ09ORl9hY3RfdmFsdWVhbGlnbj0wCkNPTkZfY29udmVydG5vdGVvbnZlbDB0b25vdGVvZmY9MApDT05GX2VudnN0ZXBzPTAKQ09ORl9leGNsd2l0aGluPTAKQ09ORl9pbmNsd2l0aGluPTAKQ09ORl9pbml0YXRtb3VzZXBvcz0wCkNPTkZfaXRlcmF0aW9ubGltPTMwMDAwCkNPTkZfbWF4cXVhbnRpemVfaWdub3JlYXRyZWFjaD0wCkNPTkZfbWF4cXVhbnRpemVfbXM9MApDT05GX21pbnF1YW50aXplX21zPTAKQ09ORl9vZmZzZXQ9MC41CkNPTkZfb2Zmc2V0X21zPTAKQ09ORl9yZWZfZWRpdGN1cj0wCkNPTkZfcmVmX2VudnBvaW50cz0wCkNPTkZfcmVmX2VudnBvaW50c2ZsYWdzPTEKQ09ORl9yZWZfZ3JpZD0yCkNPTkZfcmVmX2dyaWRfc3c9MC4zNApDT05GX3JlZl9ncmlkX3ZhbD0xLjAKQ09ORl9yZWZfbWFya2VyPTAKQ09ORl9yZWZfbWlkaT0wCkNPTkZfcmVmX21pZGlfbXNnZmxhZz0xCkNPTkZfcmVmX21pZGlmbGFncz0xCkNPTkZfcmVmX3BhdHRlcm49MApDT05GX3JlZl9wYXR0ZXJuX2dlbnNyYz0xCkNPTkZfcmVmX3BhdHRlcm5fbGVuMj04CkNPTkZfcmVmX3BhdHRlcm5fbmFtZT1BU1IxMCAxNid0aCBTdWJ6IDIgYmFyCkNPTkZfcmVmX3NlbGl0ZW1zPTAKQ09ORl9yZWZfc2VsaXRlbXNfdmFsdWU9MApDT05GX3JlZl9zdHJtYXJrZXJzPTAKQ09ORl9yZWZfdGltZW1hcmtlcj0wCkNPTkZfc3JjX2VudnBvaW50cz0wCkNPTkZfc3JjX2VudnBvaW50c2ZsYWc9MQpDT05GX3NyY19lbnZwb2ludHNmbGFncz0xCkNPTkZfc3JjX21pZGk9MApDT05GX3NyY19taWRpX21zZ2ZsYWc9NQpDT05GX3NyY19taWRpZmxhZ3M9MgpDT05GX3NyY19wb3NpdGlvbnM9MQpDT05GX3NyY19zZWxpdGVtcz0wCkNPTkZfc3JjX3NlbGl0ZW1zZmxhZz01CkNPTkZfc3JjX3N0cm1hcmtlcnM9MQ==',
          ['Align item MIDI notes to SWS groove'] = 'CkNPTkZfTkFNRT1BbGlnbiBzZWxlY3RlZCBpdGVtIE1JREkgdG8gU1dTIGdyb292ZQpDT05GX2FjdF9hY3Rpb249MQpDT05GX2FjdF9hbGlnbmRpcj0xCkNPTkZfYWN0X2FwcGJ1dHRvZXhlY3V0ZT0wCkNPTkZfYWN0X2NhdGNocmVmdGltZXNlbD0wCkNPTkZfYWN0X2NhdGNoc3JjdGltZXNlbD0wCkNPTkZfYWN0X2dyb3VwbW9kZT0wCkNPTkZfYWN0X2dyb3VwbW9kZV9kaXJlY3Rpb249MApDT05GX2FjdF9ncm91cG1vZGVfb2JleXBpdGNoPTAKQ09ORl9hY3RfZ3JvdXBtb2RlX3ZhbGJlYXRzPTAuMDE1NjI1CkNPTkZfYWN0X2luaXRhcHA9MApDT05GX2FjdF9pbml0Y2F0Y2hyZWY9MQpDT05GX2FjdF9pbml0Y2F0Y2hzcmM9MQpDT05GX2FjdF92YWx1ZWFsaWduPTAKQ09ORl9jb252ZXJ0bm90ZW9udmVsMHRvbm90ZW9mZj0wCkNPTkZfZW52c3RlcHM9MApDT05GX2V4Y2x3aXRoaW49MApDT05GX2luY2x3aXRoaW49MApDT05GX2luaXRhdG1vdXNlcG9zPTAKQ09ORl9pdGVyYXRpb25saW09MzAwMDAKQ09ORl9tYXhxdWFudGl6ZV9pZ25vcmVhdHJlYWNoPTAKQ09ORl9tYXhxdWFudGl6ZV9tcz0wCkNPTkZfbWlucXVhbnRpemVfbXM9MApDT05GX29mZnNldD0wLjUKQ09ORl9vZmZzZXRfbXM9MApDT05GX3JlZl9lZGl0Y3VyPTAKQ09ORl9yZWZfZW52cG9pbnRzPTAKQ09ORl9yZWZfZW52cG9pbnRzZmxhZ3M9MQpDT05GX3JlZl9ncmlkPTE2CkNPTkZfcmVmX2dyaWRfc3c9MApDT05GX3JlZl9ncmlkX3ZhbD0wLjUKQ09ORl9yZWZfbWFya2VyPTAKQ09ORl9yZWZfbWlkaT0wCkNPTkZfcmVmX21pZGlfbXNnZmxhZz0xCkNPTkZfcmVmX21pZGlmbGFncz0xCkNPTkZfcmVmX3BhdHRlcm49MApDT05GX3JlZl9wYXR0ZXJuX2dlbnNyYz0xCkNPTkZfcmVmX3BhdHRlcm5fbGVuMj0xNgpDT05GX3JlZl9wYXR0ZXJuX25hbWU9TVBDIDYzJSBTdWJ6IDQgYmFyCkNPTkZfcmVmX3NlbGl0ZW1zPTAKQ09ORl9yZWZfc2VsaXRlbXNfdmFsdWU9MApDT05GX3JlZl9zdHJtYXJrZXJzPTAKQ09ORl9yZWZfdGltZW1hcmtlcj0wCkNPTkZfc3JjX2VudnBvaW50cz0wCkNPTkZfc3JjX2VudnBvaW50c2ZsYWc9MQpDT05GX3NyY19lbnZwb2ludHNmbGFncz0xCkNPTkZfc3JjX21pZGk9MQpDT05GX3NyY19taWRpX21zZ2ZsYWc9NQpDT05GX3NyY19taWRpZmxhZ3M9MgpDT05GX3NyY19wb3NpdGlvbnM9MQpDT05GX3NyY19zZWxpdGVtcz0wCkNPTkZfc3JjX3NlbGl0ZW1zZmxhZz0xCkNPTkZfc3JjX3N0cm1hcmtlcnM9MA==',
          },
        presets = {
          factory= {},
          user= {}, 
          },
        val1 = 0,
        loudness_available =  APIExists('NF_AnalyzeMediaItemPeakAndRMS'),
        }
        
        
-------------------------------------------------------------------------------- UI init variables
UI = {}
-- font  
  UI.font='Arial'
  UI.font1sz=15
  UI.font2sz=14
  UI.font3sz=12
-- style
  UI.pushcnt = 0
  UI.pushcnt2 = 0
-- size / offset
  UI.spacingX = 4
  UI.spacingY = 3
-- mouse
  UI.hoverdelay = 0.8
  UI.hoverdelayshort = 0.8
-- colors 
  UI.main_col = 0x7F7F7F -- grey
  UI.textcol = 0xFFFFFF
  UI.but_hovered = 0x878787
  UI.windowBg = 0x303030
-- alpha
  UI.textcol_a_enabled = 1
  UI.textcol_a_disabled = 0.5
  
  UI.knob_handle = 0xc8edfa
  UI.default_data_col_adv = '#00ff00' -- green
  UI.default_data_col_adv2 = '#e61919 ' -- red

  UI.indent = 20
  UI.knob_resY = 150
  UI.popups = {}







function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  -------------------------------------------------------------------------------- 
  function UI.GetUserInputMB_replica(mode, key, title, num_inputs, captions_csv, retvals_csv_returnfunc, retvals_csv_setfunc) 
    local round = 4
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding, round)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, round)
    
      -- draw content
      -- (from reaimgui demo) Always center this window when appearing
      local center_x, center_y = ImGui.Viewport_GetCenter(ImGui.GetWindowViewport(ctx))
      ImGui.SetNextWindowPos(ctx, center_x, center_y, ImGui.Cond_Appearing, 0.5, 0.5)
      if ImGui.BeginPopupModal(ctx, key, nil, ImGui.WindowFlags_AlwaysAutoResize|ImGui.ChildFlags_Border) then
      
        -- MB replika
        if mode == 0 then
          ImGui.Text(ctx, captions_csv)
          ImGui.Separator(ctx) 
        
          if ImGui.Button(ctx, 'OK', 0, 0) then 
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end
          
          --[[ImGui.SetItemDefaultFocus(ctx)
          ImGui.SameLine(ctx)
          if ImGui.Button(ctx, 'Cancel', 120, 0) then 
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end]]
        end
        
        -- GetUserInput replika
        if mode == 1 then
          ImGui.SameLine(ctx)
          ImGui.SetKeyboardFocusHere( ctx )
          local retval, buf = ImGui.InputText( ctx, captions_csv, retvals_csv_returnfunc(), ImGui.InputTextFlags_EnterReturnsTrue ) 
          if retval then
            retvals_csv_setfunc(retval, buf)
            UI.popups[key].draw = false
            ImGui.CloseCurrentPopup(ctx) 
          end 
        end
        
        ImGui.EndPopup(ctx)
      end 
    
    
    ImGui.PopStyleVar(ctx, 4)
  end 
  
-------------------------------------------------------------------------------- 
function UI.MAIN_PushStyle(key, value, value2)  
  local iscol = key:match('Col_')~=nil
  local keyid = ImGui[key]
  if not iscol then 
    ImGui.PushStyleVar(ctx, keyid, value, value2)
    UI.pushcnt = UI.pushcnt + 1
  else 
    ImGui.PushStyleColor(ctx, keyid, math.floor(value2*255)|(value<<8) )
    UI.pushcnt2 = UI.pushcnt2 + 1
  end 
end
-------------------------------------------------------------------------------- 
function UI.MAIN_draw(open) 
  local w_min = 250
  local h_min = 80
  -- window_flags
    local window_flags = ImGui.WindowFlags_None
    --window_flags = window_flags | ImGui.WindowFlags_NoTitleBar
    window_flags = window_flags | ImGui.WindowFlags_NoScrollbar
    --window_flags = window_flags | ImGui.WindowFlags_MenuBar()
    --window_flags = window_flags | ImGui.WindowFlags_NoMove()
    window_flags = window_flags | ImGui.WindowFlags_NoResize
    window_flags = window_flags | ImGui.WindowFlags_NoCollapse
    --window_flags = window_flags | ImGui.WindowFlags_NoNav()
    --window_flags = window_flags | ImGui.WindowFlags_NoBackground()
    window_flags = window_flags | ImGui.WindowFlags_NoDocking
    --window_flags = window_flags | ImGui.WindowFlags_TopMost
    window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
    --if UI.disable_save_window_pos == true then window_flags = window_flags | ImGui.WindowFlags_NoSavedSettings() end
    --window_flags = window_flags | ImGui.WindowFlags_UnsavedDocument()
    --open = false -- disable the close button
  
  
    -- set style
      UI.pushcnt = 0
      UI.pushcnt2 = 0
    -- rounding
      UI.MAIN_PushStyle('StyleVar_FrameRounding',5)  
      UI.MAIN_PushStyle('StyleVar_GrabRounding',5)  
      UI.MAIN_PushStyle('StyleVar_WindowRounding',10)  
      UI.MAIN_PushStyle('StyleVar_ChildRounding',5)  
      UI.MAIN_PushStyle('StyleVar_PopupRounding',0)  
      UI.MAIN_PushStyle('StyleVar_ScrollbarRounding',9)  
      UI.MAIN_PushStyle('StyleVar_TabRounding',4)   
    -- Borders
      UI.MAIN_PushStyle('StyleVar_WindowBorderSize',0)  
      UI.MAIN_PushStyle('StyleVar_FrameBorderSize',0) 
    -- spacing
      UI.MAIN_PushStyle('StyleVar_WindowPadding',UI.spacingX,UI.spacingY)  
      UI.MAIN_PushStyle('StyleVar_FramePadding',10,5) 
      UI.MAIN_PushStyle('StyleVar_CellPadding',UI.spacingX, UI.spacingY) 
      UI.MAIN_PushStyle('StyleVar_ItemSpacing',UI.spacingX, UI.spacingY)
      UI.MAIN_PushStyle('StyleVar_ItemInnerSpacing',4,0)
      UI.MAIN_PushStyle('StyleVar_IndentSpacing',20)
      UI.MAIN_PushStyle('StyleVar_ScrollbarSize',20)
    -- size
      UI.MAIN_PushStyle('StyleVar_GrabMinSize',30)
      UI.MAIN_PushStyle('StyleVar_WindowMinSize',w_min,h_min)
    -- align
      UI.MAIN_PushStyle('StyleVar_WindowTitleAlign',0.5,0.5)
      UI.MAIN_PushStyle('StyleVar_ButtonTextAlign',0.5,0.5)
      --UI.MAIN_PushStyle('StyleVar_SelectableTextAlign,0,0 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextAlign,0,0.5 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextPadding,20,3 )
      --UI.MAIN_PushStyle('StyleVar_SeparatorTextBorderSize,3 )
    -- alpha
      UI.MAIN_PushStyle('StyleVar_Alpha',0.98)
      --UI.MAIN_PushStyle('StyleVar_DisabledAlpha,0.6 ) 
      UI.MAIN_PushStyle('Col_Border',UI.main_col, 0.3)
    -- colors
      --UI.MAIN_PushStyle('Col_BorderShadow(),0xFFFFFF, 1)
      UI.MAIN_PushStyle('Col_Button',UI.main_col, 0.3) 
      UI.MAIN_PushStyle('Col_ButtonActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_ButtonHovered',UI.but_hovered, 0.8)
      --UI.MAIN_PushStyle('Col_CheckMark(),UI.main_col, 0, true)
      --UI.MAIN_PushStyle('Col_ChildBg(),UI.main_col, 0, true)
      --UI.MAIN_PushStyle('Col_ChildBg(),UI.main_col, 0, true) 
      
      
      --Constant: Col_DockingEmptyBg
      --Constant: Col_DockingPreview
      --Constant: Col_DragDropTarget 
      UI.MAIN_PushStyle('Col_DragDropTarget',0xFF1F5F, 0.6)
      UI.MAIN_PushStyle('Col_FrameBg',0x1F1F1F, 0.7)
      UI.MAIN_PushStyle('Col_FrameBgActive',UI.main_col, .6)
      UI.MAIN_PushStyle('Col_FrameBgHovered',UI.main_col, 0.7)
      UI.MAIN_PushStyle('Col_Header',UI.main_col, 0.5) 
      UI.MAIN_PushStyle('Col_HeaderActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_HeaderHovered',UI.main_col, 0.98) 
      --Constant: Col_MenuBarBg
      --Constant: Col_ModalWindowDimBg
      --Constant: Col_NavHighlight
      --Constant: Col_NavWindowingDimBg
      --Constant: Col_NavWindowingHighlight
      --Constant: Col_PlotHistogram
      --Constant: Col_PlotHistogramHovered
      --Constant: Col_PlotLines
      --Constant: Col_PlotLinesHovered 
      UI.MAIN_PushStyle('Col_PopupBg',0x303030, 0.9) 
      UI.MAIN_PushStyle('Col_ResizeGrip',UI.main_col, 1) 
      --Constant: Col_ResizeGripActive 
      UI.MAIN_PushStyle('Col_ResizeGripHovered',UI.main_col, 1) 
      --Constant: Col_ScrollbarBg
      --Constant: Col_ScrollbarGrab
      --Constant: Col_ScrollbarGrabActive
      --Constant: Col_ScrollbarGrabHovered
      --Constant: Col_Separator
      --Constant: Col_SeparatorActive
      --Constant: Col_SeparatorHovered
      --Constant: Col_SliderGrab
      --Constant: Col_SliderGrabActive
      UI.MAIN_PushStyle('Col_Tab',UI.main_col, 0.37) 
      --UI.MAIN_PushStyle('Col_TabActive',UI.main_col, 1) 
      UI.MAIN_PushStyle('Col_TabHovered',UI.main_col, 0.8) 
      --Constant: Col_TabUnfocused
      --'Col_TabUnfocusedActive
      --UI.MAIN_PushStyle('Col_TabUnfocusedActive(),UI.main_col, 0.8, true)
      --Constant: Col_TableBorderLight
      --Constant: Col_TableBorderStrong
      --Constant: Col_TableHeaderBg
      --Constant: Col_TableRowBg
      --Constant: Col_TableRowBgAlt
      UI.MAIN_PushStyle('Col_Text',UI.textcol, UI.textcol_a_enabled) 
      --Constant: Col_TextDisabled
      --Constant: Col_TextSelectedBg
      UI.MAIN_PushStyle('Col_TitleBg',UI.main_col, 0.7) 
      UI.MAIN_PushStyle('Col_TitleBgActive',UI.main_col, 0.95) 
      --Constant: Col_TitleBgCollapsed 
      UI.MAIN_PushStyle('Col_WindowBg',UI.windowBg, 1)
    
  -- We specify a default position/size in case there's no data in the .ini file.
    local main_viewport = ImGui.GetMainViewport(ctx)
    local x, y, w, h =EXT.viewport_posX,EXT.viewport_posY, EXT.viewport_posW,EXT.viewport_posH
    ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )
    --ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
    local fixedw = 410
    if EXT.UI_compactmode == 1 then
      ImGui.SetNextWindowSize(ctx, fixedw, 110, ImGui.Cond_Always)
     else
      ImGui.SetNextWindowSize(ctx, fixedw, 600, ImGui.Cond_Always)
    end
    
  -- init UI 
    ImGui.PushFont(ctx, DATA.font1) 
    local rv,open = ImGui.Begin(ctx, DATA.UI_name, open, window_flags) 
    if rv then
      local Viewport = ImGui.GetWindowViewport(ctx)
      DATA.display_x, DATA.display_y = ImGui.Viewport_GetPos(Viewport) 
      DATA.display_w, DATA.display_h = ImGui.Viewport_GetSize(Viewport) 
      DATA.display_w_region, DATA.display_h_region = ImGui.Viewport_GetSize(Viewport) 
      
    -- calc stuff for childs
      UI.calc_xoffset,UI.calc_yoffset = ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding)
      local framew,frameh = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
      local calcitemw, calcitemh = ImGui.CalcTextSize(ctx, 'test')
      UI.calc_itemH = calcitemh + frameh * 2
      UI.calc_childH = math.floor(DATA.display_h_region - UI.calc_yoffset*6 - UI.calc_itemH*2)/3
      UI.calc_mainbut = math.floor(DATA.display_w_region - UI.calc_xoffset*4)/3
      if EXT.CONF_act_appbuttoexecute ==1 then  
        UI.calc_mainbut = math.floor(DATA.display_w_region - UI.calc_xoffset*5)/4
      end
      
    -- draw stuff
      UI.draw()
      ImGui.Dummy(ctx,0,0) 
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
      ImGui.End(ctx)
     else
      ImGui.PopStyleVar(ctx, UI.pushcnt)
      ImGui.PopStyleColor(ctx, UI.pushcnt2) 
    end 
    ImGui.PopFont( ctx ) 
    if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then return end
  
    return open
end
  --------------------------------------------------------------------------------  
  function UI.MAIN_PopStyle(ctx, cnt, cnt2)
    if cnt then 
      ImGui.PopStyleVar(ctx,cnt)
      UI.pushcnt = UI.pushcnt -cnt
    end
    if cnt2 then
      ImGui.PopStyleColor(ctx,cnt2)
      UI.pushcnt2 = UI.pushcnt2 -cnt2
    end
  end
-------------------------------------------------------------------------------- 
function DATA:CollectData() 
  -- sws groove
  local f_table = GUI_swsgroovesmenu_GetListedFile(GetResourcePath()..'/Data/Grooves/')
  DATA.SWSgr = {}
  for i = 1 , #f_table do  if f_table[i]:match('%.rgt') then DATA.SWSgr[f_table[i]:gsub('%.rgt', '')] = f_table[i] end end     
  -- old school placement
  local f_table = GUI_swsgroovesmenu_GetListedFile(GetResourcePath()..'/Grooves/')
  for i = 1 , #f_table do  if f_table[i]:match('%.rgt') then DATA.SWSgr[f_table[i]:gsub('%.rgt', '')] = f_table[i] end end  
  
  --[[ get visual array for plotting pattern
  if DATA.ref_pat then 
    DATA.arr_t = {}
    local wsz = 280
    local sws_len  = EXT.CONF_ref_pattern_len2
    for i = 1, #DATA.ref_pat do 
      local pos = DATA.ref_pat[i].pos_beats
      if pos < sws_len then
        local pos0 = math.floor(DATA.ref_pat[i].pos_beats * 100)
        DATA.arr_t[pos0+1] = DATA.ref_pat[i].val or 1
      end
    end
    local sz = sws_len*100
    for i = 1, sz do if not DATA.arr_t[i] then DATA.arr_t[i] = 0 end end
    DATA.arr = reaper.new_array(DATA.arr_t)
  end]]
  
end
-------------------------------------------------------------------------------- 
function DATA:CollectData_Always()

end
-------------------------------------------------------------------------------- 
function UI.MAINloop() 
  DATA.clock = os.clock() 
  DATA:handleProjUpdates()
  
  if DATA.upd == true then  DATA:CollectData()  end 
  DATA.upd = false
  DATA:CollectData_Always()
  -- draw UI
  UI.open = UI.MAIN_draw(true) 
  UI.MAIN_shortcuts()
  -- handle xy
  DATA:handleViewportXYWH()
  -- data
  if UI.open then defer(UI.MAINloop) end
end
-------------------------------------------------------------------------------- 
function UI.SameLine(ctx) ImGui.SameLine(ctx) end
-------------------------------------------------------------------------------- 
function UI.MAIN()
  
  EXT:load() 
  -- imgUI init
  ctx = ImGui.CreateContext(DATA.UI_name) 
  -- fonts
  DATA.font1 = ImGui.CreateFont(UI.font, UI.font1sz) ImGui.Attach(ctx, DATA.font1)
  DATA.font2 = ImGui.CreateFont(UI.font, UI.font2sz) ImGui.Attach(ctx, DATA.font2)
  DATA.font3 = ImGui.CreateFont(UI.font, UI.font3sz) ImGui.Attach(ctx, DATA.font3)  
  -- config
  ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayNormal, UI.hoverdelay)
  ImGui.SetConfigVar(ctx, ImGui.ConfigVar_HoverDelayShort, UI.hoverdelayshort)
  
  if EXT.CONF_act_initcatchref&1==1 then DATA:GetAnchorPoints() end
  if EXT.CONF_act_initcatchsrc&1==1 then DATA:GetTargets() end
  
  -- run loop
  defer(UI.MAINloop)
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
  DATA.upd = true
end
-----------------------------------------------------------------------------------------
function VF_CopyTable(orig)--http://lua-users.org/wiki/CopyTable
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[VF_CopyTable(orig_key)] = VF_CopyTable(orig_value)
        end
        setmetatable(copy, VF_CopyTable(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
--------------------------------------------------------------------------------  
function main() 
  EXT_defaults = VF_CopyTable(EXT)
  EXT:load()  
  DATA.PRESET_GetExtStatePresets()
  UI.MAIN() 
end
  -----------------------------------------------------------------------------------------    -- http://lua-users.org/wiki/SaveTableToFile
  function table.exportstring( s ) return string.format("%q", s) end
  
  --// The Save Function
  function table.save(  tbl )
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
  function table.load( str )
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

--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col) 
    UI.MAIN_PushStyle('Col_Button',col, 0.5) 
    UI.MAIN_PushStyle('Col_ButtonActive',col, 1) 
    UI.MAIN_PushStyle('Col_ButtonHovered',col, 0.8)
end
--------------------------------------------------------------------- 
function DATA.PRESET_GetExtStatePresets()
  DATA.presets.factory = DATA.presets_factory
  DATA.presets.user = table.load( EXT.preset_base64_user ) or {}
  
  -- ported from old version
  if EXT.update_presets == 1 then
    local t = {}
    for id_out=1, 32 do
      local str = GetExtState( DATA.ES_key, 'PRESET'..id_out)
      local str_dec = DATA.PRESET_decBase64(str)
      if str_dec== '' then goto nextpres end
      local tid = #t+1
      t[tid] = {str=str}
      for line in str_dec:gmatch('[^\r\n]+') do
        local key,value = line:gsub('[%{}]',''):match('(.-)=(.*)') 
        if key and value then
          t[tid][key]= tonumber(value) or value
        end
      end   
      local name = t[tid].CONF_NAME
      test = t[tid]
      DATA.presets.user[name] = VF_CopyTable(t[tid])
      ::nextpres::
    end
    EXT.update_presets = 0
    EXT:save()
  end
end
--------------------------------------------------------------------------------  
function UI.draw_plugin_handlelatchstate(t)  
  local paramval = DATA[t.param_key]
  
  -- trig
  --if  ImGui.IsItemActivated( ctx ) then 
  if  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then 
    DATA.latchstate = paramval 
    if t.appfunc_atclick then t.appfunc_atclick() end
    return 
  end
  
  if  ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
    DATA.latchstate = paramval 
    if t.appfunc_atclickR then t.appfunc_atclickR() end
    return 
  end
  
  -- drag
  if  ImGui.IsItemActive( ctx ) then
    local x, y = ImGui.GetMouseDragDelta( ctx )
    local outval = DATA.latchstate - y/UI.knob_resY
    outval = math.max(0,math.min(outval,1))
    local fxGUID = t.fxGUID
    local dx, dy = ImGui.GetMouseDelta( ctx )
    if dy~=0 then
      DATA[t.param_key] = outval
      if t.appfunc_atdrag then t.appfunc_atdrag() end
    end
  end
  
  if  ImGui.IsItemDeactivated( ctx ) then
    if t.appfunc_atrelease then t.appfunc_atrelease() end
  end
  
  if ImGui.IsItemHovered( ctx, ImGui.HoveredFlags_None ) then
    local vertical, horizontal = ImGui.GetMouseWheel( ctx )
    if vertical ~= 0 then
      local mod = 1
      if ImGui.IsKeyDown( ctx, ImGui.Mod_Shift ) then mod = 10 end
      DATA[t.param_key] = VF_lim(DATA[t.param_key] + vertical*0.01*mod)
      if t.appfunc_atrelease then t.appfunc_atrelease() end
    end
  end
  
end
-------------------------------------------------------------------------------- 
function UI.draw_knob(t) 
  local curposx, curposy = ImGui.GetCursorScreenPos(ctx)
  local butid = '##knob'..t.knobGUID
  ImGui.Button( ctx, butid, t.w, t.h)
  local item_w, item_h = reaper.ImGui_GetItemRectSize( ctx )
  UI.draw_plugin_handlelatchstate(t)  
  
  local val = DATA[t.param_key]
  
  
  if not val then return end
  local draw_list = ImGui.GetForegroundDrawList(ctx)
  local roundingIn = 0
  local col_rgba = 0xF0F0F0FF
  
  local radius = math.floor(math.min(item_w, item_h )/2)
  local radius_draw = math.floor(0.9 * radius)
  local center_x = curposx + item_w/2--radius
  local center_y = curposy + item_h/2
  local ang_min = -220
  local ang_max = 40
  local ang_val = ang_min + math.floor((ang_max - ang_min)*val)
  local radiusshift_y = (radius_draw- radius)
  ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_max))
  ImGui.DrawList_PathStroke(draw_list, 0xF0F0F02F,  ImGui.DrawFlags_None, 2)
  ImGui.DrawList_PathArcTo(draw_list, center_x, center_y - radiusshift_y, radius_draw, math.rad(ang_min),math.rad(ang_val+1))
  ImGui.DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2)
  
  local radius_draw2 = radius_draw-1
  local radius_draw3 = radius_draw-6
  ImGui.DrawList_PathClear(draw_list)
  ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw2 * math.cos(math.rad(ang_val)), center_y - radiusshift_y + radius_draw2 * math.sin(math.rad(ang_val)))
  ImGui.DrawList_PathLineTo(draw_list, center_x + radius_draw3 * math.cos(math.rad(ang_val)), center_y -radiusshift_y + radius_draw3 * math.sin(math.rad(ang_val)))
  ImGui.DrawList_PathStroke(draw_list, UI.knob_handle<<8|0xFF,  ImGui.DrawFlags_None, 2)
  
  
  ImGui.SetCursorScreenPos(ctx, curposx, curposy)
  ImGui.Dummy(ctx,t.w,  t.h)
end
-------------------------------------------------------------------------------- 
function UI.MAIN_shortcuts()
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_Escape,false )  then 
    for key in pairs(UI.popups) do UI.popups[key].draw = false end
    ImGui.CloseCurrentPopup( ctx ) 
  end
  if  ImGui.IsKeyPressed( ctx, ImGui.Key_Space,false )  then  reaper.Main_OnCommand(40044,0) end
end
--------------------------------------------------------------------------------  
function UI.draw()  
  UI.draw_preset() 
  
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Params',-1,0) then EXT.UI_compactmode = EXT.UI_compactmode~1 EXT:save() end
  
  -- get anchor points
  ImGui.Button(ctx, 'Get anchor\n    points', UI.calc_mainbut, UI.calc_itemH*2)
  if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then DATA:GetAnchorPoints() end
  if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then
    if EXT.CONF_ref_grid>0 then DATA:MarkerPoints_Show(DATA.ref_pat, UI.default_data_col_adv, true) else DATA:MarkerPoints_Show(DATA.ref, UI.default_data_col_adv, false) end
    DATA.catch_button = true
  end
  if DATA.catch_button == true and ImGui.IsMouseReleased( ctx, ImGui.MouseButton_Right ) then DATA:MarkerPoints_Clear() end 
  ImGui.SameLine(ctx)
  
  -- get targets
  ImGui.Button(ctx, 'Get targets', UI.calc_mainbut, UI.calc_itemH*2)
  if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Left ) then DATA:GetTargets() end
  if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then
    DATA:MarkerPoints_Show(DATA.src, UI.default_data_col_adv2)
    DATA.catch_button = true
  end
  if DATA.catch_button == true and ImGui.IsMouseReleased( ctx, ImGui.MouseButton_Right ) then DATA:MarkerPoints_Clear() end 
  ImGui.SameLine(ctx)
   
  -- knob
  UI.draw_knob({
    knobGUID = 'app_knob',
    w =UI.calc_mainbut, 
    h = UI.calc_itemH*2,
    param_key = 'val1',
    appfunc_atclick = function() 
      DATA:Quantize()
    end,
    
    appfunc_atclickR = function() 
      UI.popups['Set value'] = {
        trig = true,
        captions_csv = 'New value',
        func_getval = function()  
          return math.floor(DATA.val1*100)..'%'
        end,
        
        func_setval = function(retval, retvals_csv) 
          if tonumber(retvals_csv) then
            DATA.val1 = VF_lim(retvals_csv / 100)
            DATA:Quantize() 
            DATA:Execute() 
          end
        end
        }
    end, 
    
    appfunc_atdrag= function() 
      if EXT.CONF_act_appbuttoexecute == 0 then DATA:Execute() end 
    end,
    appfunc_atrelease= function() 
      if EXT.CONF_act_appbuttoexecute == 0 then DATA:Execute() Undo_OnStateChange2( 0, 'QuantizeTool' ) end 
    end,
  })
  
  --[[
      onmousereleaseR  = function() 
        if not DATA.val1 then DATA.val1 = 0 end
        local retval, retvals_csv = GetUserInputs('Align percent', 1, '', VF_math_Qdec(DATA.val1*100,2)..'%')
        if not retval then return end
        retvals_csv = tonumber(retvals_csv)
        if not retvals_csv then return end
        
        DATA.val1 = VF_lim(retvals_csv/100) 
        DATA.GUI.buttons.knob.val = DATA.val1
        DATA.GUI.buttons.knob.txt = VF_math_Qdec(DATA.val1*100,2)..'%'
        if EXT.CONF_act_appbuttoexecute ==1 then return end
        DATA:Execute() 
        Undo_OnStateChange2( 0, 'QuantizeTool' )  
      end ,
      onwheeltrig = function() 
                      local mult = 0
                      if not DATA.GUI.wheel_trig then return end
                      if DATA.GUI.wheel_dir then mult =1 else mult = -1 end
                      if not DATA.Quantize_state then DATA:Quantize()   end
                      DATA.val1 = VF_lim(DATA.val1 - 0.01*mult, 0,1)
                      DATA.GUI.buttons.knob.txt = 100*VF_math_Qdec(DATA.val1,2)..'%'
                      DATA.GUI.buttons.knob.val  = DATA.val1
                      if EXT.CONF_act_appbuttoexecute ==0 then 
                        DATA:Execute() 
                        Undo_OnStateChange2( 0, 'QuantizeTool' )  
                      end 
                      DATA.GUI.buttons.knob.refresh = true
                      
                    end
    }    
    ]]
                       
  -- apply
  if EXT.CONF_act_appbuttoexecute ==1 then  
    ImGui.SameLine(ctx) 
    if ImGui.Button(ctx, 'Apply', UI.calc_mainbut, UI.calc_itemH*2) then
      DATA:Execute() 
      Undo_OnStateChange2( 0, 'QuantizeTool' )  
    end
  end
                        
                        
  
  -- tabs
  if ImGui.BeginTabBar(ctx, 'tabs', ImGui.TabBarFlags_None) then 
     
    UI.draw_tab_anchor()  
    UI.draw_tab_targets()  
    UI.draw_tab_action() 
    UI.draw_tab_general()  
     
    ImGui.EndTabBar(ctx) 
  end 
  
  
  -- popups
  for key in pairs(UI.popups) do
    -- trig
    if UI.popups[key] and UI.popups[key].trig == true then
      UI.popups[key].trig = false
      UI.popups[key].draw = true
      ImGui.OpenPopup( ctx, key, ImGui.PopupFlags_NoOpenOverExistingPopup )
    end
    -- draw
    if UI.popups[key] and UI.popups[key].draw == true then UI.GetUserInputMB_replica(UI.popups[key].mode or 1, key, DATA.UI_name, 1, UI.popups[key].captions_csv, UI.popups[key].func_getval, UI.popups[key].func_setval) end 
  end
  
end

--------------------------------------------------------------------------------  
function UI.draw_tab_general()
  if ImGui.BeginTabItem(ctx, 'General') then 
    UI.activetab = 3
    if ImGui.Checkbox(ctx, 'Detect anchor points on initialization',EXT.CONF_act_initcatchref&1==1) then EXT.CONF_act_initcatchref = EXT.CONF_act_initcatchref~1 EXT:save() end  --ImGui.SetItemTooltip(ctx, 'Unmute destination sends before render')
    if ImGui.Checkbox(ctx, 'Obey time selection for anchor points',EXT.CONF_act_catchreftimesel&1==1) then EXT.CONF_act_catchreftimesel = EXT.CONF_act_catchreftimesel~1 EXT:save() end
    if ImGui.Checkbox(ctx, 'Detect targets on initialization',EXT.CONF_act_initcatchsrc&1==1) then EXT.CONF_act_initcatchsrc = EXT.CONF_act_initcatchsrc~1 EXT:save() end
    if ImGui.Checkbox(ctx, 'Obey time selection for targets',EXT.CONF_act_catchsrctimesel&1==1) then EXT.CONF_act_catchsrctimesel = EXT.CONF_act_catchsrctimesel~1 EXT:save() end
    if ImGui.Checkbox(ctx, 'Knob to set value, Apply to execute',EXT.CONF_act_appbuttoexecute&1==1) then EXT.CONF_act_appbuttoexecute = EXT.CONF_act_appbuttoexecute~1 EXT:save() end
    if ImGui.Checkbox(ctx, 'Update at parameters change',EXT.UI_appatchange&1==1) then EXT.UI_appatchange = EXT.UI_appatchange~1 EXT:save() end
    
    ImGui.EndTabItem(ctx)
  end
end
--------------------------------------------------------------------------------  
function VF_GetFormattedGrid(grid_div)
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
  local grid_swingamt_format = math.floor(grid_swingamt * 100)..'%'
  return grid_division, grid_str, is_triplet, grid_swingmode, grid_swingamt, grid_swingamt_format
end   

--------------------------------------------------------------------------------  
function UI.draw_flow_COMBO(t)
  local trig_action
  local preview_value
  
  if type(EXT[t.extstr]) == 'number' then 
    for key in pairs(t.values) do 
      local isint = ({math.modf(EXT[t.extstr])})[2] == 0 and ({math.modf(key)})[2] == 0 
      if type(key) == 'number' and key ~= 0 and ((isint==true and EXT[t.extstr]&key==key) or EXT[t.extstr]==key) then preview_value = t.values[key] break end 
    end
   elseif type(EXT[t.extstr]) == 'string' then 
    preview_value = EXT[t.extstr] 
  end
  if not preview_value and t.values[0] then preview_value = t.values[0] end 
  ImGui.SetNextItemWidth( ctx, 280 )
  if t.extw then ImGui.SetNextItemWidth( ctx, t.extw ) end
  if ImGui.BeginCombo( ctx, t.key, preview_value ) then
    for id in spairs(t.values) do
      local selected 
      if type(EXT[t.extstr]) == 'number' then 
        
        local isint = ({math.modf(EXT[t.extstr])})[2] == 0 and ({math.modf(id)})[2] == 0 
        selected = ((isint==true and id&EXT[t.extstr]==EXT[t.extstr]) or id==EXT[t.extstr])  and EXT[t.extstr]~= 0 
      end
      if type(EXT[t.extstr]) == 'string' then selected = EXT[t.extstr]==id end
      
      if ImGui.Selectable( ctx, t.values[id],selected  ) then
        EXT[t.extstr] = id
        trig_action = true
        EXT:save()
      end
    end
    ImGui.EndCombo(ctx)
  end
  
  -- reset
  if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
    DATA.PRESET_RestoreDefaults(t.extstr)
    trig_action = true
  end 
  
  if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  return  trig_action
end
--------------------------------------------------------------------------------  
function UI.draw_tab_anchor()
  local trig_action
  if ImGui.BeginTabItem(ctx, 'Anchor points') then 
    UI.activetab = 0 
    
    
    -- custom grid
      local grid_division, grid_str, is_triplet, grid_swingmode, grid_swingamt, grid_swingamt_format = VF_GetFormattedGrid(EXT.CONF_ref_grid_val ) 
      if EXT.CONF_ref_grid&4 == 4 then is_triplet  = true end
      if EXT.CONF_ref_grid&8 == 8 then 
        grid_swingamt = EXT.CONF_ref_grid_sw
        grid_swingamt_format  = math.floor(EXT.CONF_ref_grid_sw *100)..'%'
      end 
      if is_triplet then grid_str = grid_str..'T'  end
      if grid_swingamt ~= 0 then grid_str = grid_str..' swing '..grid_swingamt_format end
    -- proj grid
      local projgrid_division, projgrid_str, projis_triplet, projgrid_swingmode, projgrid_swingamt, projgrid_swingamt_format = VF_GetFormattedGrid()
      if projis_triplet then projgrid_str = projgrid_str..'T'  end
      if projgrid_swingamt ~= 0 then projgrid_str = projgrid_str..' swing '..projgrid_swingamt_format end   
    -- SWS
      local readoutw_extwSWSgr = 300
    
    
    trig_action = trig_action or UI.draw_flow_COMBO({['key']='Pattern',                 ['extstr'] = 'CONF_ref_grid',['values'] = {
      [0]='Off', 
      [1] = 'Pattern: Custom Grid ('..grid_str..')',
      [2] = 'Pattern: Project Grid ('..projgrid_str..')',
      [16] = 'SWS Groove', 
      }})
    if EXT.CONF_ref_grid&1==1 then  
      ImGui.Indent(ctx, UI.indent)
        if ImGui.Button(ctx, '/ 2') then  EXT.CONF_ref_grid_val = VF_lim(EXT.CONF_ref_grid_val / 2, 1/128, 1) EXT:save() trig_action = true  end ImGui.SameLine(ctx) 
        if ImGui.Button(ctx, 'x 2') then EXT.CONF_ref_grid_val = VF_lim(EXT.CONF_ref_grid_val * 2, 1/128, 1) EXT:save() trig_action = true  end ImGui.SameLine(ctx)
        if ImGui.Button(ctx,'Triplet') then EXT.CONF_ref_grid = EXT.CONF_ref_grid~4 EXT:save() trig_action = true end
        trig_action = trig_action or UI.draw_flow_CHECK({['key']='Swing',               ['extstr'] = 'CONF_ref_grid',       ['confkeybyte'] = 3})
        if EXT.CONF_ref_grid&8==8 then 
          ImGui.SameLine(ctx)
          trig_action = trig_action or UI.draw_flow_SLIDER({['key']='##sw',             ['extstr'] = 'CONF_ref_grid_sw',   ['min']=0,  ['max']=1, percent = true})
        end
      ImGui.Unindent(ctx, UI.indent)
    end
    
    if EXT.CONF_ref_grid&16==16 then
      ImGui.Indent(ctx, UI.indent)
      trig_action = trig_action or UI.draw_flow_COMBO({['key']='Groove',                ['extstr'] = 'CONF_ref_pattern_name',['values'] = DATA.SWSgr}) 
      trig_action = trig_action or UI.draw_flow_COMBO({['key']='Pattern length, beats', ['extstr'] = 'CONF_ref_pattern_len2',['values'] = {[4]='4', [8]='8', [16]='16' },['extw'] = 100}) 
      ImGui.Unindent(ctx, UI.indent)
    end 
    
    --[[if EXT.CONF_ref_grid>0 then
      ImGui.Indent(ctx, UI.indent)
      UI.draw_tab_anchor_plot()
      ImGui.Unindent(ctx, UI.indent)
    end]]
    
    trig_action = trig_action or UI.draw_flow_CHECK({['key']='Items',                   ['extstr'] = 'CONF_ref_selitems',       ['confkeybyte'] = 0})
    if EXT.CONF_ref_selitems&1==1 then
      ImGui.Indent(ctx,UI.indent)
      trig_action = trig_action or UI.draw_flow_CHECK({['key']='Obey snap offset',      ['extstr'] = 'CONF_ref_selitems',       ['confkeybyte'] = 1})
      if DATA.loudness_available == true then
        trig_action = trig_action or UI.draw_flow_COMBO({['key']='Used second value',            ['extstr'] = 'CONF_ref_selitems_value',['values'] = {[0]='Item volume',[1]='Audio Peak',[2]='Audio RMS' },['extw'] = 200})  
      end
      ImGui.Unindent(ctx,UI.indent)
    end
    trig_action = trig_action or UI.draw_flow_CHECK({['key']='Envelope points',         ['extstr'] = 'CONF_ref_envpoints',       ['confkeybyte'] = 0})
    if EXT.CONF_ref_envpoints&1==1 then
      ImGui.Indent(ctx,UI.indent)
      trig_action = trig_action or UI.draw_flow_COMBO({['key']='Source##ep',            ['extstr'] = 'CONF_ref_envpointsflags',['values'] = {[1]='Selected envelope',[2]='All envelopes',[4]='Automation Item' }})   
      ImGui.Unindent(ctx,UI.indent)
    end  
    trig_action = trig_action or UI.draw_flow_CHECK({['key']='MIDI',                    ['extstr'] = 'CONF_ref_midi',       ['confkeybyte'] = 0})
    if EXT.CONF_ref_midi&1==1 then
      ImGui.Indent(ctx,UI.indent)
      trig_action = trig_action or UI.draw_flow_COMBO({['key']='Source##midi',          ['extstr'] = 'CONF_ref_midiflags',['values'] = {[1]='MIDI Editor',[2]='Selected items'}})
      trig_action = trig_action or UI.draw_flow_CHECK({['key']='NoteOn',                ['extstr'] = 'CONF_ref_midi_msgflag',       ['confkeybyte'] = 0})
      trig_action = trig_action or UI.draw_flow_CHECK({['key']='NoteOff',               ['extstr'] = 'CONF_ref_midi_msgflag',       ['confkeybyte'] = 1})
      ImGui.Unindent(ctx,UI.indent)
    end  
    trig_action = trig_action or UI.draw_flow_CHECK({['key']='Stretch markers',         ['extstr'] = 'CONF_ref_strmarkers',       ['confkeybyte'] = 0})
    trig_action = trig_action or UI.draw_flow_CHECK({['key']='Project markers',         ['extstr'] = 'CONF_ref_marker',       ['confkeybyte'] = 0})
    trig_action = trig_action or UI.draw_flow_CHECK({['key']='Edit Cursor',             ['extstr'] = 'CONF_ref_editcur',       ['confkeybyte'] = 0})
    trig_action = trig_action or UI.draw_flow_CHECK({['key']='Tempo markers',           ['extstr'] = 'CONF_ref_timemarker',       ['confkeybyte'] = 0})
    ImGui.EndTabItem(ctx)
  end
  
  if EXT.UI_appatchange&1==1 and trig_action == true then 
    DATA:GetAnchorPoints() 
    trig_action = nil
  end
  
end
  ------------------------------------------------------------------------------------------------------
  function VF_lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end

--------------------------------------------------------------------------------  
function UI.draw_tab_targets()
  local trig_action
  if ImGui.BeginTabItem(ctx, 'Targets') then 
    UI.activetab = 1 
    
    
    trig_action = trig_action or UI.draw_flow_CHECK({['key']='Items',                             ['extstr'] = 'CONF_src_selitems',       ['confkeybyte'] = 0})
    if EXT.CONF_src_selitems&1==1 then
      ImGui.Indent(ctx,UI.indent)
        trig_action = trig_action or UI.draw_flow_CHECK({['key']='Items start positions',         ['extstr'] = 'CONF_src_selitemsflag',       ['confkeybyte'] = 0})
        trig_action = trig_action or UI.draw_flow_CHECK({['key']='Items end positions',           ['extstr'] = 'CONF_src_selitemsflag',       ['confkeybyte'] = 1}) 
        trig_action = trig_action or UI.draw_flow_CHECK({['key']='Obey snap offset',              ['extstr'] = 'CONF_src_selitems',           ['confkeybyte'] = 1})
        trig_action = trig_action or UI.draw_flow_CHECK({['key']='Stretch item instead move',     ['extstr'] = 'CONF_src_selitems',           ['confkeybyte'] = 2})
        trig_action = trig_action or UI.draw_flow_CHECK({['key']='Offset by auto fadeout length', ['extstr'] = 'CONF_src_selitems',           ['confkeybyte'] = 3})
      ImGui.Unindent(ctx,UI.indent)
    end
    
    trig_action = trig_action or UI.draw_flow_CHECK({['key']='Envelope points',                   ['extstr'] = 'CONF_src_envpoints',           ['confkeybyte'] = 0})
    if EXT.CONF_src_envpoints&1==1 then
      ImGui.Indent(ctx,UI.indent)
      trig_action = trig_action or UI.draw_flow_COMBO({['key']='Destination##ep',                     ['extstr'] = 'CONF_src_envpointsflags',['values'] = {[1]='Selected envelope', [2]='All envelopes', [4]='Automation Item'}})
      ImGui.Unindent(ctx,UI.indent)
    end
    
    trig_action = trig_action or UI.draw_flow_CHECK({['key']='MIDI notes',                        ['extstr'] = 'CONF_src_midi',           ['confkeybyte'] = 0})
    if EXT.CONF_src_midi&1==1 then
      ImGui.Indent(ctx,UI.indent)
      trig_action = trig_action or UI.draw_flow_COMBO({['key']='Destination##midi',                     ['extstr'] = 'CONF_src_midiflags',['values'] = {[1]='MIDI Editor', [2]='Selected items'}})
      trig_action = trig_action or UI.draw_flow_CHECK({['key']='NoteOn',                          ['extstr'] = 'CONF_src_midi_msgflag',           ['confkeybyte'] = 0})
      trig_action = trig_action or UI.draw_flow_CHECK({['key']='NoteOff',                         ['extstr'] = 'CONF_src_midi_msgflag',           ['confkeybyte'] = 1})
      trig_action = trig_action or UI.draw_flow_CHECK({['key']='Convert noteOn velocity 0 to NoteOff', ['extstr'] = 'CONF_src_midi_fixnoteonvel0',           ['confkeybyte'] = 0})
      trig_action = trig_action or UI.draw_flow_CHECK({['key']='Preserve notes length',           ['extstr'] = 'CONF_src_midi_msgflag',           ['confkeybyte'] = 2})
      ImGui.Unindent(ctx,UI.indent)
    end    
    
    trig_action = trig_action or UI.draw_flow_CHECK({['key']='Stretch markers',                  ['extstr'] = 'CONF_src_strmarkers',           ['confkeybyte'] = 0})
    
    
    ImGui.EndTabItem(ctx)
  end
  
  
  if EXT.UI_appatchange&1==1 and trig_action == true then 
    DATA:GetTargets() 
    trig_action = nil
  end
  
end
--------------------------------------------------------------------------------  
function UI.draw_flow_SLIDER(t) 
  local trig_action
    ImGui.SetNextItemWidth( ctx, 150 )
    local retval, v
    if t.int or t.block then
      local format = t.format
      retval, v = reaper.ImGui_SliderInt ( ctx, t.key..'##'..t.extstr, math.floor(EXT[t.extstr]), t.min, t.max, format )
      if retval then trig_action = true end
     elseif t.percent then
      retval, v = reaper.ImGui_SliderDouble( ctx, t.key..'##'..t.extstr, EXT[t.extstr]*100, t.percent_min or 0, t.percent_max or 100, t.format or '%.1f%%' )
      if retval then trig_action = true end
     else  
      retval, v = reaper.ImGui_SliderDouble( ctx, t.key..'##'..t.extstr, EXT[t.extstr], t.min, t.max, t.format )
      if retval then trig_action = true end
    end
    
    
    if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
      DATA.PRESET_RestoreDefaults(t.extstr)
      trig_action = true
     else
      if retval then 
        if t.percent then EXT[t.extstr] = v /100 else EXT[t.extstr] = v  end
        EXT:save() 
        trig_action = true
      end
    end
  
    if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  return trig_action
end
--------------------------------------------------------------------------------  
function UI.draw_flow_CHECK(t)
  local trig_action
  local byte = t.confkeybyte or 0
  if reaper.ImGui_Checkbox( ctx, t.key, EXT[t.extstr]&(1<<byte)==(1<<byte) ) then 
    EXT[t.extstr] = EXT[t.extstr]~(1<<byte) 
    trig_action = true 
    EXT:save() 
  end
  -- reset
  if reaper.ImGui_IsItemHovered( ctx, ImGui.HoveredFlags_None ) and ImGui_IsMouseClicked( ctx, ImGui.MouseButton_Right ) then
    DATA.PRESET_RestoreDefaults(t.extstr)
    trig_action = true 
  end
  
  if t.tooltip then  ImGui.SetItemTooltip(ctx, t.tooltip) end
  return trig_action
end
--------------------------------------------------------------------------------  
function UI.draw_tab_action()
  local trig_action
  if ImGui.BeginTabItem(ctx, 'Action') then 
    UI.activetab = 2 
    
    trig_action = trig_action or UI.draw_flow_COMBO({['key']='Action type',                       ['extstr'] = 'CONF_act_action',['values'] = {[1]='Position-based alignment', [2]='Ordered alignment'}})
    --[[trig_action = trig_action or UI.draw_flow_CHECK({['key']='Envelope points',                   ['extstr'] = 'CONF_src_envpoints',           ['confkeybyte'] = 0})
    if EXT.CONF_src_envpoints&1==1 then
      ImGui.Indent(ctx,UI.indent)
      trig_action = trig_action or UI.draw_flow_COMBO({['key']='Destination',                     ['extstr'] = 'CONF_src_envpointsflags',['values'] = {[1]='Selected envelope', [2]='All envelopes', [4]='Automation Item'}})
      ImGui.Unindent(ctx,UI.indent)
    end]]
    
    
    trig_action = trig_action or UI.draw_flow_SLIDER({['key']='Align second value, velocity/gain', ['extstr'] = 'CONF_act_valuealign',   ['min']=0,  ['max']=1, tooltip='Increase to reduce glitches'})
    trig_action = trig_action or UI.draw_flow_SLIDER({['key']='Offset',                           ['extstr'] = 'CONF_offset_ms',   ['min']=0,  ['max']=0.5})
    if EXT.CONF_act_action&1==1 then
      trig_action = trig_action or UI.draw_flow_COMBO({['key']='Direction',                       ['extstr'] = 'CONF_act_aligndir',['values'] = {[0]='Always previous point',[1]='Closest point',[2]='Always next point'}})
      trig_action = trig_action or UI.draw_flow_SLIDER({['key']='Maximum distance, s',            ['extstr'] = 'CONF_maxquantize_ms',   ['min']=0,  ['max']=0.5})
      trig_action = trig_action or UI.draw_flow_SLIDER({['key']='Minimum distance, s',            ['extstr'] = 'CONF_minquantize_ms',   ['min']=0,  ['max']=0.5})
      
      trig_action = trig_action or UI.draw_flow_CHECK({['key']='Group mode',                      ['extstr'] = 'CONF_act_groupmode',           ['confkeybyte'] = 0})
      if EXT.CONF_act_groupmode&1==1 then 
        ImGui.Indent(ctx,UI.indent)
        trig_action = trig_action or UI.draw_flow_COMBO({['key']='Grouping threshold, beats',     ['extstr'] = 'CONF_act_groupmode_valbeats',['values'] = {[1/128]='1/128',[1/64]='1/64',[1/32]='1/32',[1/16]='1/16',[1/8]='1/8',[1/4]='1/4',[1/2]='1/2'}})
        trig_action = trig_action or UI.draw_flow_CHECK({['key']='Obey same pitch for MIDI notes',['extstr'] = 'CONF_act_groupmode_obeypitch',           ['confkeybyte'] = 0})
        trig_action = trig_action or UI.draw_flow_COMBO({['key']='Priority',                      ['extstr'] = 'CONF_act_groupmode_direction',['values'] = {[0]='First event',[1]='Between first and last events',[2]='Last event'}})
        ImGui.Unindent(ctx,UI.indent)
      end
    end
    
    ImGui.EndTabItem(ctx)
  end
  
  if EXT.UI_appatchange&1==1 and trig_action == true then 
    DATA:Execute()  
    trig_action = nil
  end
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttoncolor(col) 
    UI.MAIN_PushStyle('Col_Button',col, 0.5) 
    UI.MAIN_PushStyle('Col_ButtonActive',col, 1) 
    UI.MAIN_PushStyle('Col_ButtonHovered',col, 0.8)
end
--------------------------------------------------------------------------------  
function UI.draw_setbuttonbackgtransparent() 
    UI.MAIN_PushStyle('Col_Button',0, 0) 
    UI.MAIN_PushStyle('Col_ButtonActive',0, 0) 
    UI.MAIN_PushStyle('Col_ButtonHovered',0, 0)
end
--------------------------------------------------------------------- 
  function DATA.PRESET_encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
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
--------------------------------------------------------------------- 
function DATA.PRESET_decBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
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
--------------------------------------------------------------------- 
function DATA.PRESET_ApplyPreset(base64str, preset_name)  
  if not base64str then return end
  local  preset_t = {}
  
  local str_dec = DATA.PRESET_decBase64(base64str)
  if str_dec~= '' then 
    for line in str_dec:gmatch('[^\r\n]+') do
      local key,value = line:gsub('[%{}]',''):match('(.-)=(.*)') 
      if key and value and key:match('CONF_') then preset_t[key]= tonumber(value) or value end
    end   
  end 
  for key in pairs(preset_t) do
    if key:match('CONF_') then 
      local presval = preset_t[key]
      EXT[key] = tonumber(presval) or presval
    end
  end 
  
  if preset_name then EXT.CONF_NAME = preset_name end
  EXT:save() 
end
--------------------------------------------------------------------------------  
function UI.draw_unsetbuttonstyle() 
  UI.MAIN_PopStyle(ctx, nil, 3)
end
--------------------------------------------------------------------- 
function DATA.PRESET_RestoreDefaults(key, UI)

  if not key then
    for key in pairs(EXT) do
      if key:match('CONF_') or (UI and UI == true and key:match('UI_'))then
        local val = EXT_defaults[key]
        if val then EXT[key]  = val end
      end
    end
   else
    local val = EXT_defaults[key]
    if val then EXT[key]  = val end
  end
  
  EXT:save() 
end
--------------------------------------------------------------------- 
function DATA.PRESET_GetCurrentPresetData()
  local str = ''
  for key in spairs(EXT) do if key:match('CONF_') then str = str..'\n'..key..'='..EXT[key] end end
  return DATA.PRESET_encBase64(str)
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
--------------------------------------------------------------------------------  
function UI.draw_preset() 
  -- preset 
  
  local select_wsz = 250
  local select_hsz = 18--UI.calc_itemH
  UI.draw_setbuttonbackgtransparent() ImGui.Button(ctx, 'Preset') UI.draw_unsetbuttonstyle() ImGui.SameLine(ctx)
  --ImGui.SetCursorPosX( ctx, DATA.display_w-UI.combo_w-UI.spacingX_wind )
  --ImGui.SetNextItemWidth( ctx, UI.combo_w )  
  local preview = EXT.CONF_name 
  
  
  
  if ImGui.BeginCombo(ctx, '##Preset', preview, ImGui.ComboFlags_HeightLargest) then 
    if ImGui.Button(ctx, 'Restore defaults') then DATA.PRESET_RestoreDefaults() end
    local retval, buf = reaper.ImGui_InputText( ctx, '##presname', DATA.preset_name )
    if retval then DATA.preset_name = buf end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Save current') then 
      local newID = DATA.preset_name--os.date()
      EXT.CONF_name = newID
      DATA.presets.user[newID] = DATA.PRESET_GetCurrentPresetData() 
      EXT.preset_base64_user = table.save(DATA.presets.user)
      EXT:save() 
    end
    
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5,1)
    
    local id = 0
    for preset in spairs(DATA.presets.factory) do
      id = id + 1
      if ImGui.Selectable(ctx, '[F] '..preset..'##factorypresets'..id, nil,nil,select_wsz,select_hsz) then 
        DATA.PRESET_ApplyPreset(DATA.presets.factory[preset], preset)
        EXT:save() 
      end
    end 
    local id = 0
    for preset in spairs(DATA.presets.user) do
      id = id + 1
      if ImGui.Selectable(ctx, preset..'##userpresets'..id, nil,nil,select_wsz,select_hsz) then 
        DATA.PRESET_ApplyPreset(DATA.presets.user[preset], preset)
        EXT:save() 
      end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Remove##remove'..id,0,select_hsz) then 
        DATA.presets.user[preset] = nil
        EXT.preset_base64_user = table.save(DATA.presets.user)
        EXT:save() 
      end
    end 
    
    
    
    ImGui.PopStyleVar(ctx)
    
    
    ImGui.EndCombo(ctx) 
  end  
  
  
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
    then 
    DATA.display_schedule_save = os.clock() 
  end
  if DATA.display_schedule_save and os.clock() - DATA.display_schedule_save > 0.3 then 
    EXT.viewport_posX = DATA.display_x
    EXT.viewport_posY = DATA.display_y
    EXT.viewport_posW = DATA.display_w
    EXT.viewport_posH = DATA.display_h
    EXT:save() 
    DATA.display_schedule_save = nil 
  end
  DATA.display_x_last = DATA.display_x
  DATA.display_y_last = DATA.display_y
  DATA.display_w_last = DATA.display_w
  DATA.display_h_last = DATA.display_h
end
-------------------------------------------------------------------------------- 
function DATA:handleProjUpdates()
  local SCC =  GetProjectStateChangeCount( 0 ) if (DATA.upd_lastSCC and DATA.upd_lastSCC~=SCC ) then DATA.upd = true end  DATA.upd_lastSCC = SCC
  local editcurpos =  GetCursorPosition()  if (DATA.upd_last_editcurpos and DATA.upd_last_editcurpos~=editcurpos ) then DATA.upd = true end DATA.upd_last_editcurpos=editcurpos 
  local reaproj = tostring(EnumProjects( -1 )) if (DATA.upd_last_reaproj and DATA.upd_last_reaproj ~= reaproj) then DATA.upd = true end DATA.upd_last_reaproj = reaproj
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

  ---------------------------------------------------------------------- 
  function DATA:GetTargets_SM() 
    local mode = EXT.CONF_src_strmarkers
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
      local retval, takeGUID = GetSetMediaItemTakeInfo_String( take, 'GUID', '', false )
      local group_master
      if not groupIDt[it_groupID] or it_groupID == 0 then 
        group_master = true  
        groupIDt[it_groupID] = #DATA[table_name]+1
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
          
          DATA[table_name][#DATA[table_name]+1] =
                  { pos = fullbeats,
                    pos_beats = fullbeats,
                    sm_pos_sec=sm_pos,
                    pos_sec = pos_glob,
                    srcpos_sec = srcpos_sec,
                    slope=slope,
                    srctype='strmark',
                    val =1,
                    ignore_search = ignore_search,
                    GUID = takeGUID,
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
  function DATA:GetTargets_MIDI_perTake(take, item, mode)
    local table_name = 'src'
    if not take or not ValidatePtr2( 0, take, 'MediaItem_Take*' ) or not TakeIsMIDI(take) then return end
    local retval, takeGUID = GetSetMediaItemTakeInfo_String( take, 'GUID', '', false )
    if EXT.CONF_src_midi_fixnoteonvel0 == 1 then DATA:GetTargets_MIDI_perTake_ConvertNoteOntNoteOffNotes(take) end
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
      
      if vel ==0 and isNoteOn == true then 
        isNoteOn = false
        isNoteOff = true 
        msg1 = string.pack("i4Bi4BBB", 0, flags, 3,  0x80| (chan-1), pitch, 0 )
      end
      
      local ignore_search = true 
  
        t0[#t0+1] = 
                          {       pos = fullbeats,
                                  pos_beats = fullbeats,
                                  pos_sec = pos_sec,
                                  ignore_search = ignore_search,
                                  GUID = takeGUID,
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
          
            
            local new_entry_id = #DATA[table_name]+1
            DATA[table_name][new_entry_id] = ppq_sorted_t[ppq][i2]
            if      (table_name=='src' and EXT.CONF_src_midi_msgflag&1==1)
                or  (table_name=='ref' and EXT.CONF_ref_midi_msgflag&1==1)  then 
                
              if mode&2 == 2 or (mode&2 == 0 and DATA[table_name][new_entry_id].flags&1==1) then
                DATA[table_name][new_entry_id].ignore_search = false 
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
                    
                    DATA[table_name][new_entry_id].note_len_PPQ = ppq_search - ppq
                    DATA[table_name][new_entry_id].is_note = true
                    DATA[table_name][new_entry_id].noteoff_msg1 = ppq_sorted_t[ppq_search][i2_search].msg1  
                    
                    DATA[table_name][new_entry_id+1] = ppq_sorted_t[ppq_search][i2_search] 
                    DATA[table_name][new_entry_id+1].src_id = new_entry_id
                    
                    if      (table_name=='src' and EXT.CONF_src_midi_msgflag&2==2)
                        or  (table_name=='ref' and EXT.CONF_ref_midi_msgflag&2==2)  then  
                      if mode&2 == 2 or (mode&2 == 0 and DATA[table_name][new_entry_id].flags&1==1) then DATA[table_name][new_entry_id+1].ignore_search = false  end
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
            local new_entry_id = #DATA[table_name]+1
            DATA[table_name][new_entry_id]=ppq_sorted_t[ppq][i2]
            
          end
        end
      end
    end
    
    
  end
  ---------------------------------------------------------------------- 
  function DATA:GetTargets_MIDI() 
    local mode  = EXT.CONF_src_midiflags
      if mode&2 == 0 then -- MIDI editor
        local ME = MIDIEditor_GetActive()
        local take = MIDIEditor_GetTake( ME ) 
        if take then 
          local item =  GetMediaItemTake_Item( take )
          if EXT.CONF_convertnoteonvel0tonoteoff == 1 and TakeIsMIDI(take) then VF_ConvertNoteOnVel0toNoteOff(take) end
          DATA:GetTargets_MIDI_perTake(take, item, mode)   
        end
       elseif   mode&2 == 2 then -- selected takes
        for i = 1, CountSelectedMediaItems(0) do
          local item = GetSelectedMediaItem(0,i-1)
          local take = GetActiveTake(item)
          if EXT.CONF_convertnoteonvel0tonoteoff == 1 and TakeIsMIDI(take) then VF_ConvertNoteOnVel0toNoteOff(take) end
          DATA:GetTargets_MIDI_perTake(take, item, mode) 
        end
      end
      
    end
  --------------------------------------------------------------------- 
  function DATA:GetTargets_Items() 
    local mode = EXT.CONF_src_selitemsflag
    local mode2 = EXT.CONF_src_selitems
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
      if mode2&2==2 then --snap offset
        position_has_snap_offs = true 
        snapoffs_sec = GetMediaItemInfo_Value( item, 'D_SNAPOFFSET' )
        pos = pos + snapoffs_sec
      end
      local is_sel = GetMediaItemInfo_Value( item, 'B_UISEL' ) == 1
      local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
      local val = GetMediaItemInfo_Value( item, 'D_VOL' )
      local tk_rate if take then  tk_rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )   end
      local retval, takeGUID = reaper.GetSetMediaItemTakeInfo_String( take, 'GUID', '', false )
      if is_sel then 
        local group_master
        if not groupIDt[groupID] or groupID == 0 then group_master = true  end
        if not DATA[table_name][id] then DATA[table_name][id] = {} end
        
        DATA[table_name][id].ignore_search = not is_sel
        DATA[table_name][id].pos = fullbeats
        DATA[table_name][id].pos_sec = pos
        DATA[table_name][id].position_has_snap_offs = position_has_snap_offs
        DATA[table_name][id].pos_beats = fullbeats
        DATA[table_name][id].snapoffs_sec = snapoffs_sec 
        DATA[table_name][id].takeGUID = takeGUID
        DATA[table_name][id].srctype='item'
        DATA[table_name][id].val =val
        DATA[table_name][id].it_len = len
        DATA[table_name][id].it_pos=it_pos
        DATA[table_name][id].groupID = groupID 
        DATA[table_name][id].ptr = item
        DATA[table_name][id].activetk_ptr = take
        DATA[table_name][id].activetk_rate = tk_rate
        DATA[table_name][id].group_master = group_master
        id = id + 1
        
        if table_name == 'src' and EXT.CONF_src_selitemsflag&2==2 then
          if not DATA[table_name][id] then DATA[table_name][id] = {} end
          local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos+len )
          DATA[table_name][id].ignore_search = not is_sel
          DATA[table_name][id].pos = fullbeats
          DATA[table_name][id].pos_sec = pos
          DATA[table_name][id].position_has_snap_offs = position_has_snap_offs
          DATA[table_name][id].pos_beats = beats
          DATA[table_name][id].snapoffs_sec = snapoffs_sec 
          DATA[table_name][id].GUID = takeGUID
          DATA[table_name][id].srctype='item_end'
          DATA[table_name][id].val =val
          DATA[table_name][id].it_len = len
          DATA[table_name][id].it_pos=it_pos
          DATA[table_name][id].groupID = GetMediaItemInfo_Value( item, 'I_GROUPID' )
          DATA[table_name][id].D_FADEOUTLEN = GetMediaItemInfo_Value( item, 'D_FADEOUTLEN_AUTO' )
          DATA[table_name][id].ptr = item
          DATA[table_name][id].activetk_ptr = take
          DATA[table_name][id].activetk_rate = tk_rate 
          DATA[table_name][id].group_master = group_master
          DATA[table_name][id].parent_position_entry = id-1
          id = id + 1    
        end
        
        groupIDt[groupID] = {}
      end
    end      
  end  
  --------------------------------------------------------------------- 
  function DATA:GetTargets_HandleGroupMode()
    if EXT.CONF_act_groupmode == 0 then return end
    
    local beats_difference_threshold = EXT.CONF_act_groupmode_valbeats
    local aligngroup_isActive, aligngroup_ID, aligngroup_basepos, aligngroup_masterID, aligngroup_masterPitch = nil, 0, 0, 0, -1
    local last_evt_pos = -math.huge
    
    if EXT.CONF_act_groupmode_obeypitch == 0 then 
      for srcid = 1, #DATA.src do
        local target_t = DATA.src[srcid]
        local curpos = target_t.pos_beats 
        if target_t.ignore_search == false then 
          if curpos - last_evt_pos > beats_difference_threshold then  -- init group or too far from last grouped point
            aligngroup_ID = aligngroup_ID + 1 
            aligngroup_masterID = srcid
            target_t.aligngroup_ids= {[1]=srcid}
            target_t.aligngroup_masterID = srcid
            target_t.aligngroup_ID = aligngroup_ID
          end 
          if curpos - last_evt_pos < beats_difference_threshold then -- tracking events in group
            target_t.aligngroup_ID = aligngroup_ID
            target_t.aligngroup_masterID = aligngroup_masterID
            if DATA.src[aligngroup_masterID] then table.insert(DATA.src[aligngroup_masterID].aligngroup_ids, srcid) end 
          end
          last_evt_pos = curpos
        end 
      end
    end
    
    local pitch_t = {}
    for i = -1, 127 do pitch_t[i] = {last_pos = -math.huge} end
    if EXT.CONF_act_groupmode_obeypitch == 1 then 
      for srcid = 1, #DATA.src do
        local target_t = DATA.src[srcid]
        local curpos = target_t.pos_beats 
        local pitch = target_t.pitch or -1
        if target_t.ignore_search == false then 
        
          if curpos - pitch_t[pitch].last_pos > beats_difference_threshold then  -- init group or too far from last grouped point
            aligngroup_ID = aligngroup_ID + 1 
            aligngroup_masterID = srcid
            target_t.aligngroup_ids= {[1]=srcid}
            target_t.aligngroup_masterID = srcid 
            target_t.aligngroup_ID = aligngroup_ID
            pitch_t[pitch].aligngroup_ID = aligngroup_ID
            pitch_t[pitch].aligngroup_masterID = aligngroup_masterID
            pitch_t[pitch].last_pos = curpos
          elseif curpos - pitch_t[target_t.pitch].last_pos < beats_difference_threshold then -- tracking events in group
            target_t.aligngroup_ID = pitch_t[pitch].aligngroup_ID
            target_t.aligngroup_masterID = pitch_t[pitch].aligngroup_masterID
            aligngroup_masterID = pitch_t[pitch].aligngroup_masterID
            if DATA.src[aligngroup_masterID] then table.insert(DATA.src[aligngroup_masterID].aligngroup_ids, srcid) end 
          end
          last_evt_pos = curpos
        end 
      end
    end
        
  end
  ---------------------------------------------------------------------- 
  function DATA:GetTargets_EPsub(env, item_pos0, tk_rate, AI_idx) 
    local table_name = 'src'
    if not env then return end
    local scaling_mode = GetEnvelopeScalingMode( env )
    if not AI_idx then AI_idx = 0 end
    local cnt =  CountEnvelopePointsEx( env,AI_idx-1 )
    for ptidx = 1, cnt do
      local retval, pos, value, shape, tension, selected = reaper.GetEnvelopePointEx( env, AI_idx-1, ptidx-1 )
      --if selected then
        local ptidx_cust = #DATA[table_name] + 1
        if item_pos0 then pos = pos/ tk_rate + item_pos0  end
        local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
        DATA[table_name][ptidx_cust] = {}
        DATA[table_name][ptidx_cust].item_pos = item_pos0
        DATA[table_name][ptidx_cust].pos = fullbeats
        DATA[table_name][ptidx_cust].pos_sec = pos
        DATA[table_name][ptidx_cust].pos_beats = fullbeats
        DATA[table_name][ptidx_cust].ptr = env
        DATA[table_name][ptidx_cust].ptr_str = genGuid('' )
        DATA[table_name][ptidx_cust].srctype='envpoint'
        DATA[table_name][ptidx_cust].selected = selected
        DATA[table_name][ptidx_cust].ID = ptidx-1
        DATA[table_name][ptidx_cust].shape = shape
        DATA[table_name][ptidx_cust].tension = tension
        DATA[table_name][ptidx_cust].val = ScaleFromEnvelopeMode( scaling_mode,value)
        DATA[table_name][ptidx_cust].ignore_search = not selected
        DATA[table_name][ptidx_cust].tk_rate = tk_rate
        DATA[table_name][ptidx_cust].AI_idx = AI_idx-1
        DATA[table_name][ptidx_cust].scaling_mode = scaling_mode
      --end
    end
  end
  --------------------------------------------------------------------- 
  function DATA:GetTargets_EP() 
    local mode = EXT.CONF_src_envpointsflags
    if mode==2 then 
      for i = 1, CountTracks(0) do
        local track = GetTrack(0,i-1)
        local cnt_env = CountTrackEnvelopes( track )
        for envidx = 1, cnt_env do
          local env = GetTrackEnvelope( track, envidx-1 )
          DATA:GetTargets_EPsub(env, nil, tk_rate, AI_idx)  
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
            DATA:GetTargets_EPsub(env, item_pos, tk_rate, AI_idx)  
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
            DATA:GetTargets_EPsub(env, nil, tk_rate, AI_idx)  
          end
        end
      end
      
     elseif mode==1 then -- selected
      local  env = GetSelectedEnvelope( 0 )
      local istakeenv, item_pos, tk_rate = DATA:IsTakeEnvelope(env) 
      DATA:GetTargets_EPsub(env, item_pos, tk_rate, AI_idx)  
    end
    
  end 
  --------------------------------------------------------------------- 
  function DATA:GetTargets()
    DATA.src = {}
    
    if EXT.CONF_src_selitems&1==1 then DATA:GetTargets_Items() end  
    if EXT.CONF_src_envpoints&1==1 then DATA:GetTargets_EP() end   
    if EXT.CONF_src_midi&1==1 then DATA:GetTargets_MIDI()  end 
    if EXT.CONF_src_strmarkers&1==1 then DATA:GetTargets_SM() end 
    
    -- sort src table by position 
      local sortedKeys = getKeysSortedByValue(DATA.src, function(a, b) return a < b end, 'pos')
      local t = {}
      for _, key in ipairs(sortedKeys) do t[#t+1] = DATA.src[key] end
      DATA.src = t 
  
    -- filter time selection
      if EXT.CONF_act_catchsrctimesel&1==1 then
        local ts_start, ts_end = GetSet_LoopTimeRange2( 0, false, false, 0, 0, false )
        local ts_startb, ts_endb =  ({TimeMap2_timeToBeats( 0, ts_start )})[4], ({TimeMap2_timeToBeats( 0, ts_end )})[4]
        for i = 1, #DATA.src do
          if not DATA:TimeSelMatchCondition(DATA.src[i].pos_sec, ts_startb, ts_endb) and DATA.src[i].ignore_search == false then DATA.src[i].ignore_search = true end
        end
      end 
      
    DATA:GetTargets_HandleGroupMode()
  end
  ------------------------------------------------------------------------------------------------------
  function getKeysSortedByValue(tbl, sortFunction, param) -- https://stackoverflow.com/questions/2038418/associatively-sorting-a-table-by-value-in-lua
    local keys = {}
    for key in pairs(tbl) do table.insert(keys, key) end  
    table.sort(keys, function(a, b) return sortFunction(tbl[a][param], tbl[b][param])  end)  
    return keys
  end  
  ----------------------------------------------------------------------  
  function DATA:GetAnchorPoints_MIDI(table_name)  
    if EXT.CONF_ref_midiflags == 1 then -- MIDI editor
      local ME = MIDIEditor_GetActive()
      local take = MIDIEditor_GetTake( ME ) 
      if take then 
        if EXT.CONF_convertnoteonvel0tonoteoff == 1 and TakeIsMIDI(take) then VF_ConvertNoteOnVel0toNoteOff(take) end
        DATA:GetAnchorPoints_MIDIsub(take)   
      end
     elseif   EXT.CONF_ref_midiflags == 2 then -- selected takes
      for i = 1, CountSelectedMediaItems(0) do
        local item = GetSelectedMediaItem(0,i-1)
        local take = GetActiveTake(item)
        if EXT.CONF_convertnoteonvel0tonoteoff == 1 and TakeIsMIDI(take) then VF_ConvertNoteOnVel0toNoteOff(take) end
        DATA:GetAnchorPoints_MIDIsub(take) 
      end
    end 
  end
  ---------------------------------------------------------------------- 
  function DATA:GetAnchorPoints_MIDIsub(take)
    local mode = EXT.CONF_ref_midi
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
                                        
      if (EXT.CONF_ref_midi_msgflag==1 and isNoteOn ) or (EXT.CONF_ref_midi_msgflag==3 and isNoteOff ) then
        DATA.ref[#DATA.ref+1] = { pos_sec = pos_sec,
                                  pos_beats = fullbeats,
                                  val = val
                                  }
      end
    end  
    
    
  end
  ---------------------------------------------------------------------- 
  function DATA:GetAnchorPoints_SM()
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
          DATA.ref[#DATA.ref+1] = { pos_sec = pos_glob,
                                      pos_beats = fullbeats,
                                      val = 1
                                      }
        end
      end 
    end   
  end
  ---------------------------------------------------------------------- 
  function DATA:GetAnchorPoints_Markers()
    local  retval, num_markers, num_regions = CountProjectMarkers( 0 )
    for i = 1, num_markers do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber = EnumProjectMarkers2( 0, i-1 )
      local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
      local val = tonumber(name)
      if not (val and (val >=-1 and val <=2))  then val = 1 end
      DATA.ref[#DATA.ref+1] = { 
                              pos_sec = pos,
                              pos_beats = fullbeats,
                              val = val
                            }
    end
  end
  ------------------------------------------------------------------------------------------------------  
  function VF_AnalyzeItemLoudness(item) -- https://forum.cockos.com/showpost.php?p=2050961&postcount=6
    if not APIExists('NF_AnalyzeMediaItemPeakAndRMS') then return end
    if not item then return end
    
    -- get channel count
    local take = GetActiveTake(item)
    local source = GetMediaItemTake_Source(take)
    local channelsInSource =  GetMediaSourceNumChannels(source)
    
    local windowSize = 0
    local reaperarray_peaks         = reaper.new_array(channelsInSource)
    local reaperarray_peakpositions = reaper.new_array(channelsInSource)
    local reaperarray_RMSs          = reaper.new_array(channelsInSource)
    local reaperarray_RMSpositions  = reaper.new_array(channelsInSource)
    
    -- REAPER sets initial (used) size to maximum size when creating reaper.array
    -- so we resize (set used size to 0) to make space for writing the values
    reaperarray_peaks.resize(0)
    reaperarray_peakpositions.resize(0)
    reaperarray_RMSs.resize(0)
    reaperarray_RMSpositions.resize(0)
    
    -- analyze
    local success = reaper.NF_AnalyzeMediaItemPeakAndRMS(item, windowSize, reaperarray_peaks, reaperarray_peakpositions, reaperarray_RMSs, reaperarray_RMSpositions)
    
    if success == true then
      -- convert reaper.arrays to Lua tables
      local peaksTable = reaperarray_peaks.table()
      local RMSsTable = reaperarray_RMSs.table()
      
      local peaks_com = 0
      local RMS_com = 0
      -- print results
      for i = 1, channelsInSource do
        peaks_com = peaks_com + peaksTable[i]
        RMS_com = RMS_com + RMSsTable[i]
      end
      
      peaks_com = peaks_com / channelsInSource
      RMS_com = RMS_com / channelsInSource
      
      return WDL_DB2VAL(peaks_com), WDL_DB2VAL(RMS_com)
      
    end
  end
  ---------------------------------------------------------------------- 
  function DATA:GetAnchorPoints_TempoMarkers()
    local  cnt = CountTempoTimeSigMarkers( 0 )
    for i = 1, cnt do
      local  retval, pos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = GetTempoTimeSigMarker( 0, i-1 )
      local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats( 0, pos )
      DATA.ref[#DATA.ref+1] = { 
                              pos_sec = pos,
                              pos_beats = fullbeats,
                              val = val
                            }
    end  
  end
  --------------------------------------------------------------------- 
  function DATA:GetAnchorPoints_Items() 
    for itemidx = 1,  CountSelectedMediaItems( 0 ) do
      local item = GetSelectedMediaItem( 0, itemidx - 1 )
      local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      if EXT.CONF_ref_selitems&2==2 then pos = pos + GetMediaItemInfo_Value( item, 'D_SNAPOFFSET' ) end
      local val = GetMediaItemInfo_Value( item, 'D_VOL' )
      if EXT.CONF_ref_selitems_value > 0 and DATA.loudness_available == true then
        local peak, RMS = VF_AnalyzeItemLoudness(item)
        if EXT.CONF_ref_selitems_value == 1 then val = peak elseif EXT.CONF_ref_selitems_value == 2 then val = RMS end
      end
      DATA.ref[#DATA.ref+1] = { pos_sec = pos,
                                  pos_beats = ({TimeMap2_timeToBeats( 0, pos)})[4],
                                  val = val
                                  }
    end
  end  
  ---------------------------------------------------------------------- 
  function DATA:GetAnchorPoints_gridcurrent()
    local retval, divisionIn, swingmodeIn, swingamtIn = GetSetProjectGrid( 0, false ) 
    if swingmodeIn == 0 then swingamtIn = 0 end 
    if not divisionIn then return end
    local id = 0
    for beat = 1, EXT.CONF_ref_pattern_len2 + 1, divisionIn*4 do
      local outpos = beat-1
      if swingamtIn ~= 0 then 
        if id%2 ==1 then outpos = outpos + swingamtIn * divisionIn*2 end
      end
      DATA.ref_pat[#DATA.ref_pat + 1] = {pos_beats = outpos, val = 1}
      id = id + 1
    end
  end
  ---------------------------------------------------------------------- 
  function DATA:GetAnchorPoints_pattern()  
    if EXT.CONF_ref_grid&16 == 16 then 
      local name = EXT.CONF_ref_pattern_name
      local fp =  GetResourcePath()..'/Data/Grooves/'..name..'.rgt'
      local f = io.open(fp, 'r')
      local content
      if f then  
        content = f:read("*all")
        f:close()
       else
        fp =  GetResourcePath()..'/Grooves/'..name..'.rgt'
        f = io.open(fp, 'r')
        if f then  
          content = f:read("*all")
          f:close()
        end
      end
      if not content or content == '' then return else DATA:GetAnchorPoints_PatternParseRGT(content, false) end
    end
  end
  ---------------------------------------------------------------------- 
  function DATA:GetAnchorPoints_PatternParseRGT(content, take_len)
    local len = content:match('Number of beats in groove: (%d+)')
    if len and take_len  and tonumber(len) then EXT.CONF_ref_pattern_len2 = tonumber(len) end
    
    DATA.ref_pat.len = tonumber(len) or 1
    
    local pat = '[%d%.%-%e]+'
    for line in content:gmatch('[^\r\n]+') do
    
      -- test first symb is number
        if not line:sub(1,1):match('%d') then goto next_line end
        
      -- pos
        local pos = tonumber(line:match(pat))
        local val = 1
        
        local check_val = line:match(pat..'%s('..pat..')')
        if check_val and tonumber(check_val) then val = tonumber(check_val) end
        
      if pos and val then DATA.ref_pat[#DATA.ref_pat +1] = {  pos_beats = pos, val = val} end
      
      
      ::next_line::
    end
  end 
  ---------------------------------------------------------------------- 
  function DATA:GetAnchorPoints_grid()
    local retval, divisionIn, swingmodeIn, swingamtIn 
    
    divisionIn = EXT.CONF_ref_grid_val
    swingamtIn = 0
    if EXT.CONF_ref_grid&4==4 then divisionIn = divisionIn* 2/3 end
    if EXT.CONF_ref_grid&8==8 then swingamtIn = EXT.CONF_ref_grid_sw end 
    
    if not divisionIn then return end
    local id = 0
    for beat = 1, EXT.CONF_ref_pattern_len2 + 1, divisionIn*4 do
      local outpos = beat-1
      if swingamtIn ~= 0 then 
        if id%2 ==1 then outpos = outpos + swingamtIn * divisionIn*2 end
      end
      DATA.ref_pat[#DATA.ref_pat + 1] = {pos_beats = outpos, val = 1}
      id = id + 1
    end
  end
  --------------------------------------------------------------------- 
  function DATA:GetAnchorPoints_EP() 
    if EXT.CONF_ref_envpointsflags==2 then -- all env
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
              DATA.ref[#DATA.ref+1] = { pos_sec = pos, pos_beats = ({TimeMap2_timeToBeats( 0, pos )})[4], val = ScaleFromEnvelopeMode(GetEnvelopeScalingMode( env ),val) }
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
                DATA.ref[#DATA.ref+1] = { pos_sec = pos, pos_beats = ({TimeMap2_timeToBeats( 0, pos )})[4], val = ScaleFromEnvelopeMode(GetEnvelopeScalingMode( env ),val) }
              end
            end
          end
        end
      end 
      
     elseif EXT.CONF_ref_envpointsflags==4 then -- AI 
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
                DATA.ref[#DATA.ref+1] = { pos_sec = pos, pos_beats = ({TimeMap2_timeToBeats( 0, pos )})[4], val = ScaleFromEnvelopeMode(GetEnvelopeScalingMode( env ),val) }
              end
            end
          end
        end
      end
      
     elseif EXT.CONF_ref_envpointsflags==1 then -- selected
      local  env = GetSelectedEnvelope( 0 )
      if env then 
        local istakeenv, item_pos, tk_rate = DATA:IsTakeEnvelope(env) 
        local cnt =  CountEnvelopePointsEx( env,-1 )
        for ptidx = 1, cnt do
          local retval, pos, val, shape, tension, selected = reaper.GetEnvelopePointEx( env, -1, ptidx-1 )
          if selected then
            DATA.ref[#DATA.ref+1] = { pos_sec = pos, pos_beats = ({TimeMap2_timeToBeats( 0, pos )})[4], val = ScaleFromEnvelopeMode(GetEnvelopeScalingMode( env ),val), istakeenv=istakeenv, item_pos=item_pos }
          end
        end
      end
    end
    
    
  end
  ---------------------------------------------------------------------- 
  function DATA:GetAnchorPoints_EditCursor()
    local pos = GetCursorPositionEx( 0 ) 
    local beats = TimeMap2_timeToBeats( 0,  pos )
    DATA.ref[#DATA.ref+1] = { 
                            pos_sec = pos,
                            pos_beats = beats,
                            val = 1
                          }
  end 
  ---------------------------------------------------------------------- 
  function DATA:GetAnchorPoints()
    DATA.ref = {}
    DATA.ref_pat = {}
    if EXT.CONF_ref_selitems&1==1 then DATA:GetAnchorPoints_Items() end 
    if EXT.CONF_ref_envpoints&1==1 then DATA:GetAnchorPoints_EP()  end
    if EXT.CONF_ref_midi&1==1 then DATA:GetAnchorPoints_MIDI()  end
    if EXT.CONF_ref_strmarkers&1==1 then DATA:GetAnchorPoints_SM()  end
    
    -- other stuff
    if EXT.CONF_ref_marker&1==1 then DATA:GetAnchorPoints_Markers()  end
    if EXT.CONF_ref_timemarker&1==1 then DATA:GetAnchorPoints_TempoMarkers()  end 
    if EXT.CONF_ref_editcur&1==1 then DATA:GetAnchorPoints_EditCursor()  end 
    
    -- pattern
    if EXT.CONF_ref_grid&1==1 then  DATA:GetAnchorPoints_grid()  end
    if EXT.CONF_ref_grid&2==2 then  DATA:GetAnchorPoints_gridcurrent()  end
    if EXT.CONF_ref_grid&16==16 then  DATA:GetAnchorPoints_pattern()  end
    
    -- sort ref table by position  
      local sortedKeys = getKeysSortedByValue(DATA.ref, function(a, b) return a and b and a < b end, 'pos_sec')
      local t = {}
      for _, key in ipairs(sortedKeys) do t[#t+1] = DATA.ref[key] end
      DATA.ref = t
    
    -- filter time selection
      if EXT.CONF_act_catchreftimesel&1==1 then
        local ts_start, ts_end = GetSet_LoopTimeRange2( 0, false, false, 0, 0, false )
        local ts_startb, ts_endb =  ({TimeMap2_timeToBeats( 0, ts_start )})[4], ({TimeMap2_timeToBeats( 0, ts_end )})[4]
        for i = #DATA.ref, 1, -1 do
          if not DATA:TimeSelMatchCondition(DATA.ref[i].pos_sec, ts_startb, ts_endb) then table.remove(DATA.ref, i) end
        end
      end
      
    -- count active points
      DATA.ref.src_cnt = #DATA.ref
  end
  ---------------------------------------------------------------------- 
  function DATA:IsTakeEnvelope(env) 
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
  function DATA:GetTargets_MIDI_perTake_ConvertNoteOntNoteOffNotes(take)
    local tableEvents = {}
    local t = 0
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    local MIDIlen = MIDIstring:len()
    local stringPos = 1
    local offset, flags, msg
    while stringPos < MIDIlen-12 do
      offset, flags, msg1, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos) 
        
      local msgtype = msg1:byte(1)&0xF0
      local chan = msg1:byte(1)&0xF
      if msgtype == 0x90 and msg1:byte(3) == 0 then 
        msgtype = 0x80
      end
      t = t + 1
      tableEvents[t] = string.pack("i4Bi4BBB", offset, flags, 3, msgtype|chan, msg1:byte(2), msg1:byte(3) )
    end
    
    MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
    MIDI_Sort(take)
  end 
  ---------------------------------------------------------------------- 
  function DATA:TimeSelMatchCondition(pos, ts_startb, ts_endb) return (pos >= ts_startb-0.0001 and pos <= ts_endb-0.001) end
  --------------------------------------------------------------------- 
  function DATA:MarkerPoints_Clear() 
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
  function DATA:MarkerPoints_Show(passed_t0, s16, is_pat)
    if not passed_t0 then return end
    local passed_t
    -- generate passed_t from pattern based on edit cursor
    if is_pat then 
      passed_t = {}
      local curpos = GetCursorPositionEx( 0 )
      local _, measures = TimeMap2_timeToBeats( 0, curpos )
      for i = 1, #passed_t0 do
        if passed_t0[i].pos_beats <= EXT.CONF_ref_pattern_len2 then
          local pos_sec = TimeMap2_beatsToTime( 0, passed_t0[i].pos_beats,measures )        
          local _, _, _, real_pos = reaper.TimeMap2_timeToBeats( 0, pos_sec ) 
          passed_t[#passed_t+1] = { pos_beats = real_pos,
                          val = passed_t0[i].val}
        end
      end
      local pos_rgn = TimeMap2_beatsToTime( 0, 0, measures ) 
      local end_rgn = TimeMap2_beatsToTime( 0, EXT.CONF_ref_pattern_len2, measures ) 
      local r,g,b = DATA:GUIhex2rgb(s16)
      AddProjectMarker2( 0, true, pos_rgn, end_rgn, 'QT_'.. EXT.CONF_ref_pattern_len2..' beats',
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
  ----------------------------------------------------------------------------- 
  function DATA:GUIhex2rgb(s16,set)
    if not s16 then return end
    if type(s16) =='string' then 
      s16 = s16:gsub('#',''):gsub('0X',''):gsub('0x','')
      int = tonumber(s16, 16)
      else return
    end
    local b,g,r = ColorFromNative(int)
    if set then
      if GetOS():match('Win') then gfx.set(r/255,g/255,b/255) else gfx.set(b/255,g/255,r/255) end
    end
    return r/255, g/255, b/255
  end
  ------------------------------------------------------------------------------------------------------
  function VF_math_Qdec(num, pow) if not pow then pow = 3 end return math.floor(num * 10^pow) / 10^pow end
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
  function DATA:Quantize()   
    if not DATA.ref or not DATA.src then return end  
    if EXT.CONF_act_action == 1 then DATA:Quantize_CalculatePBA() end
    if EXT.CONF_act_action == 2 then DATA:Quantize_CalculateOA() end
    DATA.Quantize_state= true
  end        
  --------------------------------------------------------------------- 
  function DATA:Quantize_CalculateOA() 
    if not DATA.src then return end
    
    DATA:Quantize_CalculatePBA_addpattern()  -- convert pattern into src edges
    local use_pattern if EXT.CONF_ref_grid > 0 then use_pattern = true end
    
    --split by GUID
    local src_t = {}
    for i = 1, #DATA.src do
      local GUID = DATA.src[i].GUID
      if not src_t[GUID] then src_t[GUID] = {} end
      src_t[GUID][#src_t[GUID]+1] = DATA.src[i]
    end
    
    for GUID in pairs(src_t) do 
      for i= 1, #src_t[GUID] do
        local tsrc = src_t[GUID][i]
        if tsrc.pos_sec and tsrc.ignore_search == false then 
        local t_ref = DATA.ref[i]
        if use_pattern then t_ref = DATA.ref_formed[i] end
          if t_ref then
            local pos_secOUT, out_val = t_ref.pos_sec, t_ref.pos_val 
            tsrc.pos_secOUT = pos_secOUT - EXT.CONF_offset_ms
            tsrc.valOUT = out_val
          end
        end
      end
    end
  end
  
  --------------------------------------------------------------------- 
  function DATA:Quantize_brutforce_RefID(pos_src)
    if not DATA.ref_formed then return end
    if #DATA.ref_formed < 1 then return end
    
    --[[local testID1 = 1
    local testID2 = #DATA.ref_formed
    for i = 1, EXT.CONF_iterationlim do
      if testID2 - testID1 < 2 then return testID1 end
      local id1 = math.max(1,testID1-1)
      local id2 = math.min(#DATA.ref_formed,testID2+1)
      local test_edge1 = DATA.ref_formed[id1].pos_sec
      local test_edge2 = DATA.ref_formed[id2].pos_sec
      if pos_src >= test_edge1 and pos_src <= test_edge2 then
        local midID = math.floor((testID1 + testID2) /2)
        local midpos = DATA.ref_formed[midID].pos_sec
        if pos_src >= midpos and pos_src <= test_edge2 then 
          testID1 = midID
         else
          testID2 = midID
        end
      end
    end
    
    if pos_src < DATA.ref_formed[1].pos_sec then return 1 end 
    if pos_src > DATA.ref_formed[#DATA.ref_formed].pos_sec then return #DATA.ref_formed end ]]
    
    local edge1= 1
    local edge2= #DATA.ref_formed
    
    -- filter_bounds 1st pass
      if  #DATA.ref_formed > 10 then
        midID = edge1 + math.floor( (edge2-edge1) /2)
        local pos_ref = DATA.ref_formed[midID].pos_sec
        if pos_src >= pos_ref then  
          edge1 = midID - 1
        end
      end
  
    -- filter_bounds 2nd pass
      if  #DATA.ref_formed > 50 then
        midID = edge1 + math.floor( (edge2-edge1) /2)
        local pos_ref = DATA.ref_formed[midID].pos_sec
        if pos_src >= pos_ref then  
          edge1 = midID - 1
        end
      end
  
    -- filter_bounds 3rd pass
      if  #DATA.ref_formed > 100 then
        midID = edge1 + math.floor( (edge2-edge1) /2)
        local pos_ref = DATA.ref_formed[midID].pos_sec
        if pos_src >= pos_ref then  
          edge1 = midID - 1
        end
      end
        
    local id = 1
    local min_diff = math.huge
    for i = edge1, edge2 do
      local pos_ref = DATA.ref_formed[i].pos_sec
      local cur_diff = math.abs(pos_ref - pos_src)
      if cur_diff < min_diff then id = i end
      min_diff = math.min(min_diff, cur_diff) 
    end
    
    
    return id
  end
  --------------------------------------------------------------------- 
  function DATA:Quantize_CalculatePBA() 
    DATA:Quantize_CalculatePBA_addpattern()  -- convert pattern into src edges
    if not DATA.src then return end
    for i = 1, #DATA.src do  
      if DATA.src[i].pos_sec and DATA.src[i].ignore_search == false then
        local pos_secOUT, out_val = DATA.src[i].pos_sec, DATA.src[i].pos_val
        --if DATA.ref[i].istakeenv then pos_secOUT = pos_secOUT + DATA.ref[i].item_pos end
        local refID = DATA:Quantize_brutforce_RefID(DATA.src[i].pos_sec)
        if refID and DATA.ref_formed[refID] then 
          if EXT.CONF_act_aligndir == 1 then -- 1 - closest
            pos_secOUT = DATA.ref_formed[refID].pos_sec
            out_val = DATA.ref_formed[refID].val 
           elseif EXT.CONF_act_aligndir == 0 then-- 0 - always previous 
            if DATA.src[i].pos_sec < DATA.ref_formed[refID].pos_sec and DATA.ref_formed[refID-1] then
              pos_secOUT = DATA.ref_formed[refID-1].pos_sec
              out_val = DATA.ref_formed[refID-1].val 
             else
              pos_secOUT = DATA.ref_formed[refID].pos_sec
              out_val = DATA.ref_formed[refID].val      
            end  
           elseif EXT.CONF_act_aligndir == 2 then--2 - always next
            if DATA.src[i].pos_sec > DATA.ref_formed[refID].pos_sec and DATA.ref_formed[refID+1] then
              pos_secOUT = DATA.ref_formed[refID+1].pos_sec
              out_val = DATA.ref_formed[refID+1].val 
             else
              pos_secOUT = DATA.ref_formed[refID].pos_sec
              out_val = DATA.ref_formed[refID].val      
            end                               
          end   
        end
        
        DATA.src[i].pos_secOUT = pos_secOUT - EXT.CONF_offset_ms
        DATA.src[i].valOUT = out_val
        
        if EXT.CONF_maxquantize_ms > 0  then
          if math.abs(DATA.src[i].pos_secOUT-DATA.src[i].pos_sec) > EXT.CONF_maxquantize_ms then 
            if EXT.CONF_maxquantize_ignoreatreach == 1 then 
              DATA.src[i].ignore_search = true
              DATA.src[i].pos_secOUT=DATA.src[i].pos_sec
             else
              if DATA.src[i].pos_secOUT>DATA.src[i].pos_sec then DATA.src[i].pos_secOUT = DATA.src[i].pos_sec + EXT.CONF_maxquantize_ms else DATA.src[i].pos_secOUT = DATA.src[i].pos_sec - EXT.CONF_maxquantize_ms end
            end
          end
        end
        
        if EXT.CONF_minquantize_ms > 0 and math.abs(DATA.src[i].pos_secOUT-DATA.src[i].pos_sec) < EXT.CONF_minquantize_ms then
          DATA.src[i].ignore_search = true
          DATA.src[i].pos_secOUT=DATA.src[i].pos_sec
        end 
      end
    end
    DATA:Quantize_CalculatePBA_handleGroupMode() 
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
  --------------------------------------------------------------------- 
  function DATA:Quantize_CalculatePBA_addpattern()
    DATA.ref_formed = CopyTable(DATA.ref)
    
    
    local edge_st = 10^31
    local edge_end = -10^31
    local edge_change = false
    local beats_def = 16
     
    if DATA.src then
      for i = 1, #DATA.src do
        local pos = DATA.src[i].pos_sec
        edge_st = math.min(edge_st, pos)
        edge_end = math.max(edge_end, pos)
        edge_change = true
      end
    end
    
    local _, edge_st_measure, _, _, _ = reaper.TimeMap2_timeToBeats( 0, edge_st )
    local _, edge_end_measure, _, _, _ = reaper.TimeMap2_timeToBeats( 0, edge_end )
    if edge_change then 
      for i = 1, #DATA.ref_pat do 
        for measures = math.max(0,edge_st_measure), edge_end_measure + 1 do
          local pos_sec =  TimeMap2_beatsToTime( 0, DATA.ref_pat[i].pos_beats, measures )
          DATA.ref_formed[#DATA.ref_formed+1] = {pos_sec = pos_sec, val = DATA.ref_pat[i].val}
        end
      end
     else return
    end
    
    -- sort ref table by position
      temp_id = {}
      for i = 1, #DATA.ref_formed do 
        local pos = DATA.ref_formed[i].pos_sec
        if DATA.ref_formed[i].istakeenv then pos = pos + DATA.ref_formed[i].item_pos end
        if pos then 
          temp_id[pos] = DATA.ref_formed[i].val 
        end
      end
      --table.sort(temp_id)
      DATA.ref_formed = {}
      for key in spairs(temp_id) do DATA.ref_formed[#DATA.ref_formed+1] = {pos_sec = key, val = temp_id[key]} end
      
  end
  --------------------------------------------------------------------- 
  function DATA:Quantize_CalculatePBA_handleGroupMode()   
    if EXT.CONF_act_groupmode == 0 then return end
    
    --[[ reset all slave outputs position
      for i = 1, #DATA.src do
        if DATA.src[i].ignore_search == true then goto next_targ end
        if not DATA.src[i].aligngroup_ID then goto next_targ end
        local aligngroup_masterID = DATA.src[i].aligngroup_masterID
        if aligngroup_masterID ~= i then DATA.src[i].pos_secOUT = DATA.src[i].pos_sec end
        ::next_targ::
      end]]
    
    -- first event align
      if EXT.CONF_act_groupmode_direction == 0 then
        for i = 1, #DATA.src do
          if DATA.src[i].ignore_search == true then goto next_targ0 end
          if not DATA.src[i].aligngroup_ID then goto next_targ0 end
          local aligngroup_masterID = DATA.src[i].aligngroup_masterID
          if aligngroup_masterID ~= i then goto next_targ0 end 
          local aligngroup_ids = DATA.src[aligngroup_masterID].aligngroup_ids
          if #aligngroup_ids == 1 then goto next_targ0 end 
          
          local shift = DATA.src[aligngroup_masterID].pos_secOUT  - DATA.src[aligngroup_masterID].pos_sec 
          for i2 = 1, #aligngroup_ids do
            local slaveID = aligngroup_ids[i2]
            if slaveID~= aligngroup_masterID then
              local diff = DATA.src[aligngroup_masterID].pos_secOUT-DATA.src[aligngroup_masterID].pos_sec
              DATA.src[slaveID].pos_secOUT = DATA.src[slaveID].pos_sec + diff
            end
          end
          ::next_targ0::
        end
      end
  
    -- last event align
      if EXT.CONF_act_groupmode_direction == 2 then
        for i = 1, #DATA.src do
          if DATA.src[i].ignore_search == true then goto next_targ2 end
          if not DATA.src[i].aligngroup_ID then goto next_targ2 end
          local aligngroup_masterID = DATA.src[i].aligngroup_masterID
          if aligngroup_masterID ~= i then goto next_targ2 end 
          local aligngroup_ids = DATA.src[aligngroup_masterID].aligngroup_ids
          if #aligngroup_ids == 1 then goto next_targ2 end 
          
          local lastevtID = aligngroup_ids[#aligngroup_ids]
          local shift = DATA.src[lastevtID].pos_secOUT  - DATA.src[lastevtID].pos_sec 
          for i2 = 1, #aligngroup_ids do
            local slaveID = aligngroup_ids[i2]
            if slaveID~= lastevtID then
              local diff = DATA.src[lastevtID].pos_secOUT-DATA.src[lastevtID].pos_sec
              DATA.src[slaveID].pos_secOUT = DATA.src[slaveID].pos_sec + diff
            end
          end
          ::next_targ2::
        end
      end
        
      -- between first and last event
        if EXT.CONF_act_groupmode_direction == 1 then 
          for i = 1, #DATA.src do
            if DATA.src[i].ignore_search == true then goto next_targ1 end
            if not DATA.src[i].aligngroup_ID then goto next_targ1 end 
            local aligngroup_masterID = DATA.src[i].aligngroup_masterID
            if aligngroup_masterID ~= i then goto next_targ1 end 
            local aligngroup_ids = DATA.src[aligngroup_masterID].aligngroup_ids 
            if #aligngroup_ids == 1 then goto next_targ1 end 
            local midID = aligngroup_ids[math.max(1,math.floor(#aligngroup_ids/2))]
            local midOUT = DATA.src[midID].pos_secOUT
             
            local first_evt = aligngroup_ids[1]
            local last_evt = aligngroup_ids[#aligngroup_ids]
            local midposdiff = (DATA.src[last_evt].pos_sec  + DATA.src[first_evt].pos_sec )/2
            
            local diff =  midposdiff - midOUT
            for i2 = 1, #aligngroup_ids do
              local slaveID = aligngroup_ids[i2]
              DATA.src[slaveID].pos_secOUT = DATA.src[slaveID].pos_sec - diff
            end
            ::next_targ1::
          end
        end
  end
  --------------------------------------------------------------------- 
  function DATA:Execute()  
    DATA.val2 = EXT.CONF_act_valuealign -- get from config, knob 2 in the past
    if not DATA.src or not DATA.ref then return end
    if EXT.CONF_src_selitems&1==1 then    
      DATA:Execute_Align_Items(1)  
      DATA:Execute_Align_Items(2)  
      DATA:Execute_Align_Items(3)  
    end
    if EXT.CONF_src_envpoints&1==1 then   DATA:Execute_Align_EnvPt() end
    if EXT.CONF_src_midi&1==1 then        DATA:Execute_Align_MIDI() end
    if EXT.CONF_src_strmarkers&1==1 then  DATA:Execute_Align_SM() end   
  end
  --------------------------------------------------------------------- 
  function DATA:Execute_Align_Items_UpdateItemsGroup(t, pos_shift, val_shift, len_diff, rate_diff)
    local groupID = t.groupID
    for i = 1 , #DATA.src do
      local t1 = DATA.src[i]
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
  function DATA:Execute_Align_Items(iteration)
    local last_pos
    local val1 = DATA.val1 or 0
    local val2 = DATA.val2 or 0
    for i = 1 , #DATA.src do
      local t = DATA.src[i]
      if not t.ignore_search and t.group_master == true then
        local it =  t.ptr
        
        if it then 
          if t.pos_secOUT then 
            local pos_secOUT = t.pos_sec + (t.pos_secOUT - t.pos_sec)*val1
            if EXT.CONF_src_selitems&2==2 and  t.position_has_snap_offs and t.srctype~='item_end'   then pos_secOUT = pos_secOUT - t.snapoffs_sec end 
            
                        
            if EXT.CONF_src_selitemsflag&1==1 and t.srctype~='item_end' and t.group_master == true and iteration == 1 then 
              SetMediaItemInfo_Value( it, 'D_POSITION', pos_secOUT )
              t.it_pos_change = pos_secOUT
              local pos_shift = pos_secOUT - t.pos_sec
              DATA:Execute_Align_Items_UpdateItemsGroup(t, pos_shift)
            end
            
            if EXT.CONF_src_selitemsflag&2==2 and t.srctype=='item_end' and t.group_master == true and iteration == 2 and  t.parent_position_entry and DATA.src[t.parent_position_entry] and DATA.src[t.parent_position_entry].it_pos_change then
              local D_FADEOUTLEN = 0
              if EXT.CONF_src_selitemsflag&8==8 then D_FADEOUTLEN = t.D_FADEOUTLEN end
              local out_len = pos_secOUT - DATA.src[t.parent_position_entry].it_pos_change  + D_FADEOUTLEN
              SetMediaItemInfo_Value( it, 'D_LENGTH', out_len)
              local len_diff = out_len - t.it_len
              DATA:Execute_Align_Items_UpdateItemsGroup(t, nil, nil, len_diff)
              if EXT.CONF_src_selitemsflag&4==4 then
                local rate_diff = t.it_len/out_len
                SetMediaItemTakeInfo_Value( t.activetk_ptr, 'D_PLAYRATE',  t.activetk_rate*rate_diff)
                DATA:Execute_Align_Items_UpdateItemsGroup(t, nil, nil, nil, rate_diff)
              end
            end 
          end 
          
          if t.valOUT then --and iteration == 3 then
            local val_shift = (t.valOUT - t.val)*val2
            SetMediaItemInfo_Value( it, 'D_VOL', t.val + val_shift)  
            DATA:Execute_Align_Items_UpdateItemsGroup(t, nil, val_shift)
          end
          
          UpdateItemInProject( it )
        end
      end  
    end
  end
  --------------------------------------------------------------------- 
  function DATA:Execute_Align_EnvPt()
    local val1 = DATA.val1 or 0
    local val2 = DATA.val2 or 0
    if not DATA.src[1] then return end
    
    -- collect various takes
    local env_t = {}
    for i = 1 , #DATA.src do
      local t = DATA.src[i]
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
  function DATA:Execute_Align_MIDI_sub(take_t, take) 
    local val1 = DATA.val1 or 0
    local val2 = DATA.val2 or 0
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
      
      if t.isNoteOn and EXT.CONF_src_midi_msgflag&1==1 then 
        local out_vel = math.max(1,math.floor(lim(out_val,0,1)*127))
        str_per_msg = str_per_msg.. string.pack("i4Bi4BBB", out_offs, t.flags, 3,  0x90| (t.chan-1), t.pitch, out_vel )
        
        if EXT.CONF_src_midi_msgflag&4==4 
        
          --and (   (EXT.CONF_src_midi&2==0 and t.flags&1 == 1) or EXT.CONF_src_midi&2==2 ) 
          
          and t.noteoff_msg1 then
          str_per_msg = str_per_msg.. string.pack("i4Bs4",  t.note_len_PPQ,  t.flags , t.noteoff_msg1)
          ppq_cur = ppq_cur+ t.note_len_PPQ
        end
        ppq_cur = ppq_cur+ out_offs
                
       elseif t.isNoteOff then
        if EXT.CONF_src_midi_msgflag&2==2 then
          str_per_msg = str_per_msg.. string.pack("i4Bi4BBB", out_offs, t.flags, 3,  0x80| (t.chan-1), t.pitch, 0 )
          ppq_cur = ppq_cur+ out_offs 
         elseif EXT.CONF_src_midi_msgflag&4~=4 or (EXT.CONF_src_midi_msgflag&4==4 and EXT.CONF_src_midi&2==0 and t.flags&1 ~= 1)then
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
  function DATA:Execute_Align_MIDI()  
    if #DATA.src < 1 then return end 
    -- sort takes
    local takes_t = {}
    for i = 1 , #DATA.src do
      local t = DATA.src[i]
      if not takes_t [t.GUID] then takes_t [t.GUID] = {} end
      takes_t [t.GUID] [#takes_t [t.GUID] + 1 ]  = VF_CopyTable(t)
    end  
    -- loop takes
    for GUID in pairs(takes_t) do
      local take =  GetMediaItemTakeByGUID( 0, GUID )
      DATA:Execute_Align_MIDI_sub(takes_t[GUID], take) 
    end
  end
  --------------------------------------------------------------------- 
  function DATA:Execute_Align_SMChilds_GetOutPos(relproj_pos, tmaster, tslavepoint)
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
  function DATA:Execute_Align_SMChilds(takes_t, it_groupID, tmaster)
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
            local ret = DATA:Execute_Align_SMChilds_GetOutPos(tslavepoint.relproj_pos, tmaster, tslavepoint)
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
  function DATA:Execute_Align_SM()
    local val1 = DATA.val1 or 0
    local val2 = DATA.val2 or 0
    -- collect stuff from points scope to takes scope
      local takes_t = {}
      for i = 1 , #DATA.src do
        local t = DATA.src[i]
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
        DATA:Execute_Align_SMChilds(takes_t, tmaster.smpoints[1].it_groupID, tmaster)
      end
        
  end  
  --------------------------------------------------------------------------------  
  function  UI.draw_tab_anchor_plot() 
    if not DATA.arr then return end
    ImGui.PlotHistogram(ctx, '##anchpathist', DATA.arr, 0, nil, 0, 1, 280, 0)
  end
-----------------------------------------------------------------------------------------
main()
  
  
  
  