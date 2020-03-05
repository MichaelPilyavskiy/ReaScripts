-- @description InteractiveToolbar_DataUpdate
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  -- update obj/project data for 
  
  function DataUpdate2(data, mouse, widgets, obj, conf)
    -- update master track peaks
    if not data.masterdata.peakR then 
      data.masterdata.peakR = {} 
      data.masterdata.peakL = {} 
    end
    if not ValidatePtr2( 0, data.masterdata.ptr, 'MediaTrack*') then return end
    local id = #data.masterdata.peakL +1
    local pkL =  Track_GetPeakInfo( data.masterdata.ptr,0 )
    if pkL < 0.001 then pkL = 0 end
    local pkR = Track_GetPeakInfo( data.masterdata.ptr,1 )
    if pkR < 0.001 then pkR = 0 end
    
    table.insert(data.masterdata.peakL, 1 , pkL)
    table.insert(data.masterdata.peakR, 1 , pkR)
    if #data.masterdata.peakL > conf.master_buf*conf.scaling then 
      table.remove(data.masterdata.peakL, #data.masterdata.peakL)
      table.remove(data.masterdata.peakR, #data.masterdata.peakL)
    end
    data.masterdata.peakL[#data.masterdata.peakL] = 0 
    data.masterdata.peakR[#data.masterdata.peakL] = 0 
  end
  ---------------------------------------------------
  function DataUpdate(data, mouse, widgets, obj, conf)
    DataUpdate_RulerGrid(data, conf) 
    
    if conf.ignore_context&(1<<9) ~= (1<<9) then
      DataUpdate_TimeSelection(data, conf)
      DataUpdate_PlayState(data, conf)
      DataUpdate_TempoTimeSignature(data)
      DataUpdate_LastTouchedFX(data)
    end
    --DataUpdate_Toolbar(data,conf)
    
    if not data.tap_data then data.tap_data = {} end
    if not data.tap_data.tapst then data.tap_data.tapst = {} end
    
    data.pitch_format = conf.pitch_format
    data.oct_shift = conf.oct_shift
    data.always_use_x_axis = conf.always_use_x_axis
    data.MM_doubleclick = conf.MM_doubleclick
    data.MM_rightclick = conf.MM_rightclick
    data.MM_grid_rightclick = conf.MM_grid_rightclick
    data.MM_grid_ignoreleftdrag=conf.MM_grid_ignoreleftdrag
    data.MM_grid_doubleclick = conf.MM_grid_doubleclick
    data.MM_grid_default_reset_grid = conf.MM_grid_default_reset_grid
    data.persist_clock_showtimesec = conf.persist_clock_showtimesec
    data.relative_it_len = conf.relative_it_len
    
    -- reset buttons data
      obj.b = {}
      
    -- persisten widgets
      if conf.ignore_context&(1<<9) ~= (1<<9) then
        obj.persist_margin = Obj_UpdatePersist(data, obj, mouse, widgets, conf) 
        -- MUST be before DataUpdate_Context for passing persist_margin
       else
        obj.persist_margin = gfx.w
      end
    -- context widgets  
      DataUpdate_Context(data, mouse, widgets, obj, conf) 
    -- update com butts
      Obj_UpdateCom(data, mouse, obj, widgets, conf) 
    -- reset name if overlap persist
      if obj.b.type_name.x + obj.b.type_name.w > obj.persist_margin then
        obj.b.type_name = nil
        obj.b.obj_name = nil
      end  
      
  end
  ---------------------------------------------------  
  function DataUpdate_RulerGrid(data, conf)  
    data.rul_format = MPL_GetCurrentRulerFormat()
    data.SR = tonumber(reaper.format_timestr_pos(1, '', 4))
    data.FR = TimeMap_curFrameRate( 0 )
    data.grid_val, data.grid_val_format, data.grid_istriplet, data.grid_swingactive_int, data.grid_swingamt, data.grid_swingamt_format = MPL_GetFormattedGrid()
    data.MIDIgrid_val, data.MIDIgrid_val_format, data.MIDIgrid_istriplet = MPL_GetFormattedMIDIGrid()
    
    
    data.grid_isactive =  GetToggleCommandStateEx( 0, 1157 )==1
    data.MIDIgrid_isactive =  GetToggleCommandStateEx( 32060, 1014 )==1
    data.grid_swingactive = data.grid_swingactive_int == 1
    data.ruleroverride = conf.ruleroverride
    data.grid_rel_snap =  GetToggleCommandStateEx( 0, 41054 ) --Item edit: Toggle relative grid snap
    data.MIDIgrid_rel_snap =  GetToggleCommandStateEx( 32060, 40829 )
    data.grid_vis =  GetToggleCommandStateEx( 0, 40145 ) -- toggle grid visibility
    data.MIDIgrid_vis =  GetToggleCommandStateEx( 32060,1017 )
    
  end
  --[[-------------------------------------------------
  function DataUpdate_Toolbar(data,conf)
    local toolb_id = 1
    
  end]]
  ---------------------------------------------------
  function DataUpdate_Context(data, mouse, widgets, obj, conf)    
    --[[ 
      contexts for data.obj_type_int
        0 empty item
        1 MIDI item
        2 audio item
        3 multiple items    
        6 envelope
        7 track
        8 MIDI message
        9 persistent
        
        --deprecated:
        --4 envelope point
        --5 multiple envelope points        
        --8 note
        --9 cc
        --10 ruler evt
        
    ]]  
    data.obj_type = 'No object selected'
    data.obj_type_int = -1  
    
    local item if conf.ignore_context&(1<<0) ~= (1<<0) then item = GetSelectedMediaItem(0,0) end
    local item_parent_tr if item then item_parent_tr = GetMediaItem_Track( item ) end
  
    local env if conf.ignore_context&(1<<6) ~= (1<<6) then env = GetSelectedEnvelope( 0 ) end
    local env_parent_tr if env then env_parent_tr  = Envelope_GetParentTrack( env ) end    
    
    local tr if conf.ignore_context&(1<<7) ~= (1<<7) then tr = GetSelectedTrack(0,0) end
    data.fsel_tr = GetSelectedTrack(0,0) 
        
    local ME, MEtake,is_takeOK if conf.ignore_context&(1<<8) ~= (1<<8) then ME = MIDIEditor_GetActive() end
    if ME then 
      MEtake = MIDIEditor_GetTake( ME ) 
      is_takeOK = ValidatePtr2( 0, MEtake, 'MediaItem_Take*' )  
    end
    
    if env then
      local is_envOk =  ValidatePtr2( 0, env, 'TrackEnvelope*' )  
      if not is_envOk then env = nil end
    end
    
    if  conf.use_context_specific_conditions == 1 and data.last_fsel_tr 
        and data.last_fsel_tr ~= data.fsel_tr 
        and not (
                  (item_parent_tr and item_parent_tr == data.fsel_tr )
                  or  
                  (env_parent_tr and env_parent_tr == data.fsel_tr) 
                )
        and tr
      then 
      DataUpdate_Track(data, tr)
      Obj_UpdateTrack(data, obj, mouse, widgets, conf)   
      goto skip_context_selector
    end
    
    cur_context = 0
    if ME and MEtake and is_takeOK then
      DataUpdate_MIDIEditor(data, ME )
      Obj_UpdateMIDIEditor(data, obj, mouse, widgets, conf)
      cur_context = 1
     elseif env then    
      DataUpdate_Envelope(data, env)
      Obj_UpdateEnvelope(data, obj, mouse, widgets, conf)
      cur_context = 2 
     elseif item then 
      local obj_type = DataUpdate_Item(data) 
      Obj_UpdateItem(data, obj, mouse, widgets, conf)
      cur_context = 3
      if obj_type == 1 then cur_context = 5 end -- midi
      if obj_type == 2 then cur_context = 6 end -- midi
     elseif tr then
      DataUpdate_Track(data, tr)
      Obj_UpdateTrack(data, obj, mouse, widgets, conf) 
      cur_context = 4 
    end
    
    if cur_context and last_cur_context and last_cur_context ~= cur_context then
       if cur_context == 0 then 
        if conf.actiononchangecontext_no ~= '' then 
          local comID = NamedCommandLookup( conf.actiononchangecontext_no )
          if comID ~= 0 then Main_OnCommand( comID , 0 ) end
        end    
       elseif cur_context == 1 then 
        if conf.actiononchangecontext_ME ~= '' then 
          local comID = NamedCommandLookup( conf.actiononchangecontext_ME )
          if comID ~= 0 then Main_OnCommand( comID , 0 ) end
        end
       elseif cur_context == 2 then 
         if conf.actiononchangecontext_env ~= '' then 
           local comID = NamedCommandLookup( conf.actiononchangecontext_env )
           if comID ~= 0 then Main_OnCommand( comID , 0 ) end
         end 
       elseif cur_context == 3 then 
        if conf.actiononchangecontext_item ~= '' then 
          local comID = NamedCommandLookup( conf.actiononchangecontext_item )
          if comID ~= 0 then Main_OnCommand( comID , 0 ) end
        end  
       elseif cur_context == 5 then 
        if conf.actiononchangecontext_itemM ~= '' then 
          local comID = NamedCommandLookup( conf.actiononchangecontext_itemM )
          if comID ~= 0 then Main_OnCommand( comID , 0 ) end
        end 
       elseif cur_context == 6 then 
        if conf.actiononchangecontext_itemA ~= '' then 
          local comID = NamedCommandLookup( conf.actiononchangecontext_itemA )
          if comID ~= 0 then Main_OnCommand( comID , 0 ) end
        end                 
       elseif cur_context == 4 then 
        if conf.actiononchangecontext_track ~= '' then 
          local comID = NamedCommandLookup( conf.actiononchangecontext_track )
          if comID ~= 0 then Main_OnCommand( comID , 0 ) end
        end   
      end            
    end
    
    last_cur_context = cur_context
    
    ::skip_context_selector::
    data.last_fsel_tr = data.fsel_tr
    --[[ force_track_context engine
      local window, segment, details = BR_GetMouseCursorContext()
      data.fsel_tr = GetSelectedTrack(0,0)
      local force_track_context = --((window == 'tcp' and segment == 'track') or (window == arrange and segment == 'track' and details == 'empty'))and
                                  (data.last_fsel_tr and data.last_fsel_tr ~= data.fsel_tr)
                                  and (data.last_obj_type_int and data.last_obj_type_int ~= 7)
      --ClearConsole()
      data.last_fsel_tr = data.fsel_tr
      data.last_obj_type_int =data.obj_type_int]]
            
  end
  ---------------------------------------------------
  function DataUpdate_TimeSelection(data, conf)
    local TS_st, TSend = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )
    data.timeselectionstart, data.timeselectionend, data.timeselectionlen = TS_st, TSend,  TSend-TS_st
    if conf.timiselwidgetsformatoverride == -2 then
      data.timiselwidgetsformatoverride = data.ruleroverride
     else
      data.timiselwidgetsformatoverride = conf.timiselwidgetsformatoverride
    end
    data.timeselectionstart_format = format_timestr_pos( data.timeselectionstart, '',data.timiselwidgetsformatoverride ) 
    data.timeselectionend_format = format_timestr_pos( data.timeselectionend, '', data.timiselwidgetsformatoverride )
    data.timeselectionlen_format = format_timestr_len( data.timeselectionlen, '', TS_st,data.timiselwidgetsformatoverride )
  end
  ---------------------------------------------------
    
  function DataUpdate_PlayState(data, conf)
    local int_playstate = GetPlayStateEx( 0 )
    data.play = int_playstate&1==1
    data.pause = int_playstate&2==2
    data.record = int_playstate&4==4
    data.editcur_pos = GetCursorPositionEx( 0 )
    data.repeat_state = GetToggleCommandStateEx( 0, 1068 ) 
    local editcur_pos_format =  format_timestr_pos( data.editcur_pos, '', data.ruleroverride )
    if conf.persist_clock_showtimesec > 0 then -- SEE GUI_Main
    
    
      if conf.persist_clock_showtimesec == 1 then 
        data.editcur_pos_format = editcur_pos_format..' / '..format_timestr_pos( data.editcur_pos, '', 0 )
       elseif conf.persist_clock_showtimesec == 2 then 
        data.editcur_pos_format = editcur_pos_format..' / '..format_timestr_pos( data.editcur_pos, '', 5 )
      end
      
     else
      data.editcur_pos_format = editcur_pos_format
    end
  end
  
  ---------------------------------------------------
    
  function DataUpdate_LastTouchedFX(data)
    data.LTFX = {}
    local ret, tr, fx, param = GetLastTouchedFX()
    if ret then
      local tr = CSurf_TrackFromID( tr, false )
      local isvalid = reaper.ValidatePtr2( 0, tr, 'MediaTrack*' )
      if isvalid then
        data.LTFX.exist = true
        data.LTFX_trptr = tr
        data.LTFX_fxID = fx
        data.LTFX_parID = param
        _, data.LTFX_fxname = TrackFX_GetFXName( tr, fx, '' )
        
        _, data.LTFX_parname = TrackFX_GetParamName( tr, fx, param, '' )
        data.LTFX_val =  TrackFX_GetParamNormalized( tr, fx, param )
        local _, LTFX_val_format = TrackFX_GetFormattedParamValue( tr, fx, param, '' )
        data.LTFX_val_format = LTFX_val_format:match('%d+')
      end
    end
  end
  
  ---------------------------------------------------
  function DataUpdate_TempoTimeSignature(data)
    local int_TM = FindTempoTimeSigMarker( 0, data.editcur_pos )
    data.TempoMarker_ID = int_TM
    if int_TM == -1 then 
      local bpm= Master_GetTempo()
      local _, timesig_num = GetProjectTimeSignature2( 0 )
      local _, _, _, _, timesig_denom = TimeMap2_timeToBeats( 0, 0 )
      data.TempoMarker_timesig1 = math.floor(timesig_num)
      data.TempoMarker_timesig2 = math.floor(timesig_denom)
      data.TempoMarker_bpm= bpm
      
      data.TempoMarker_lineartempochange = false
     else
      local _, timepos, measureposOut, beatposOut, bpm, timesig_num, timesig_denom, lineartempoOut = GetTempoTimeSigMarker( 0, int_TM )
      data.TempoMarker_bpm= bpm
      data.TempoMarker_lineartempochange = lineartempoOut
      data.TempoMarker_timepos = timepos
      data.TempoMarker_timesig_num = timesig_num
      data.TempoMarker_timesig_denom = timesig_denom
      if timesig_num > 0 and timesig_denom > 0  then
        data.TempoMarker_timesig1 = math.floor(timesig_num)
        data.TempoMarker_timesig2 = math.floor(timesig_denom)
       else
        local _, timesig_num = GetProjectTimeSignature2( 0 )
        local _, _, _, _, timesig_denom = TimeMap2_timeToBeats( 0, 0 )
        data.TempoMarker_timesig1 = math.floor(timesig_num)
        data.TempoMarker_timesig2 = math.floor(timesig_denom)
      end
    end
    if data.TempoMarker_bpm then data.TempoMarker_bpm_format= string.format("%.3f", data.TempoMarker_bpm) end
  end
  ---------------------------------------------------
  function DataUpdate_Item(data, item)
    data.name = ''  
    data.it={}
    
    local obj_type
    local cnt_selected = 0
    for i = 1, CountSelectedMediaItems(0) do
      data.it[i] = {}
      local item = GetSelectedMediaItem(0,i-1)
          
      data.it[i].ptr_item = item
          
      data.it[i].item_pos = GetMediaItemInfo_Value( item, 'D_POSITION')
      data.it[i].item_len = GetMediaItemInfo_Value( item, 'D_LENGTH')
      data.it[i].item_end = data.it[i].item_pos + data.it[i].item_len
      data.it[i].snap_offs = GetMediaItemInfo_Value( item, 'D_SNAPOFFSET')
      data.it[i].fadein_len = GetMediaItemInfo_Value( item, 'D_FADEINLEN')
      data.it[i].fadeout_len = GetMediaItemInfo_Value( item, 'D_FADEOUTLEN')       
      data.it[i].item_pos_format = format_timestr_pos( data.it[i].item_pos, '', data.ruleroverride ) 
      data.it[i].item_len_format = format_timestr_len( data.it[i].item_len, '', 0, data.ruleroverride ) 
      data.it[i].item_end_format = format_timestr_pos( data.it[i].item_pos+data.it[i].item_len, '', data.ruleroverride ) 
      data.it[i].snap_offs_format = format_timestr_len( data.it[i].snap_offs, '', 0, data.ruleroverride )
      data.it[i].fadein_len_format = format_timestr_len( data.it[i].fadein_len, '', 0, data.ruleroverride )
      data.it[i].fadeout_len_format = format_timestr_len( data.it[i].fadeout_len, '', 0, data.ruleroverride )
      data.it[i].col = GetMediaItemInfo_Value( item, 'I_CUSTOMCOLOR' )
      
      
      data.it[i].vol = GetMediaItemInfo_Value( item, 'D_VOL')
      data.it[i].vol_format = WDL_VAL2DB(data.it[i].vol, true)..'dB'    
      --data.it[i].vol_format = dBFromReaperVal(data.it[i].vol)..'dB'      
      data.it[i].lock = GetMediaItemInfo_Value( item, 'C_LOCK')
      data.it[i].mute = GetMediaItemInfo_Value( item, 'B_MUTE')
      data.it[i].loop = GetMediaItemInfo_Value( item, 'B_LOOPSRC')     
        
      local take = GetActiveTake(item)
      if take then
        data.it[i].ptr_take = take
        local _, tk_name = GetSetMediaItemTakeInfo_String( take, "P_NAME", '', false )         
        data.it[i].start_offs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
        data.it[i].start_offs_format = format_timestr_len(data.it[i].start_offs, '', 0, data.ruleroverride )
        data.it[i].pitch = GetMediaItemTakeInfo_Value( take, 'D_PITCH' )
        data.it[i].pitch_format = math.floor(data.it[i].pitch *1000) / 1000
        data.it[i].name = tk_name
        data.it[i].isMIDI = TakeIsMIDI(take)
        data.it[i].chanmode = GetMediaItemTakeInfo_Value( take, 'I_CHANMODE' )
        data.it[i].preservepitch = GetMediaItemTakeInfo_Value( take, 'B_PPITCH')
        data.it[i].pitchmode = GetMediaItemTakeInfo_Value( take, 'I_PITCHMODE' )>>16
        data.it[i].pitchsubmode = GetMediaItemTakeInfo_Value( take, 'I_PITCHMODE' )&65535
        data.it[i].pan = GetMediaItemTakeInfo_Value( take, 'D_PAN' )
        data.it[i].pan_format = MPL_FormatPan(data.it[i].pan)
        data.it[i].rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
        data.it[i].rate_format = math.floor(data.it[i].rate *100) / 100
        
        local retval, sectionOut, startOut, lengthOut, fadeOut, reverseOut  = BR_GetMediaSourceProperties( take )
        data.it[i].srclen = lengthOut
        data.it[i].srclen_format = format_timestr_len( data.it[i].srclen, '', 0, data.ruleroverride ) 
        data.it[i].src_reverse = reverseOut
        data.it[i].src_start = startOut
        data.it[i].src_fade = fadeOut
        data.it[i].src_section = sectionOut
        
       else
        local note = ULT_GetMediaItemNote( item )
        if note then 
          data.it[i].name = note:match('.-\n')
        end        
      end 
      
      
      if take then 
        if TakeIsMIDI(take) then 
          data.it[i].obj_type_int = 1
          if obj_type then obj_type = 3 else obj_type = 1 end
         else 
          if obj_type then obj_type = 3 else obj_type = 2 end
          data.it[i].obj_type_int = 2
        end
       else
        if obj_type then obj_type = 3 else obj_type = 0 end
        data.it[i].obj_type_int = 0
      end
      
    end
    
    
    --  set obj type 
      if obj_type == 0 then 
          data.obj_type = 'Empty Item'
          data.obj_type_int = 0
       elseif obj_type == 1 then 
          data.obj_type = 'MIDI Item'
          data.obj_type_int = 1
       elseif obj_type == 2 then 
          data.obj_type = 'Audio Item' 
          data.obj_type_int = 2
       elseif obj_type == 3 then 
          data.obj_type = 'Items ('..#data.it..')'
          data.obj_type_int = 3
      end   
    return  obj_type
  end  
------------------------------------------------------------------------
  function DataUpdate_Envelope(data, env)
    if not env then return end
    data.name = ''  
    data.ep={}
    
    data.env_ptr = env
    local tr, env_FXid, env_paramid = Envelope_GetParentTrack( env )
   
    
    -- get val limits
      local BR_env = BR_EnvAlloc( env, false )
      local _, _, _, _, _, _, minValue, maxValue, centr = BR_EnvGetProperties( BR_env )
      BR_EnvFree( BR_env, false )
      data.minValue, data.maxValue, data.env_defValue= minValue, maxValue, centr

    if tr then 

      data.obj_type_int = 6
      local _, tr_name = GetTrackName( tr, '' )
      local _, env_name =  GetEnvelopeName( env, '' )
      data.name = tr_name..' | '..env_name
      data.env_isvolume = env_name:match('Volume') ~= nil
      data.env_name=env_name
      data.env_parenttr = tr
      data.env_parentFX = env_FXid
      data.env_parentParam = env_paramid
      local retval, buf = TrackFX_GetFXName( tr,  env_FXid, env_paramid )
      data.env_parentFXname = buf
    end 
        
    local obj_type, first_selected, env_hasselpoint
    local cnt_selected_pts = 0
    for i = 1, CountEnvelopePoints( env ) do      
      local retval, time, value, shape, tension, selected = GetEnvelopePointEx( env, -1, i-1 )
      data.ep[i] = {}
      data.ep[i].pos = time
      data.ep[i].pos_format = format_timestr_pos( time, '', data.ruleroverride ) 
      data.ep[i].value = value
       data.ep[i].value_format =  string.format("%.2f", value)
      if data.env_isvolume then  
        data.ep[i].value_format = string.format("%.2f", SLIDER2DB(value))--string.format("%.2f", WDL_VAL2DB(value))    
      end
      
      data.ep[i].shape = shape
      data.ep[i].tension = tension
      data.ep[i].selected = selected
      if selected then cnt_selected_pts = cnt_selected_pts +1 end
      if not first_selected and selected then 
        data.ep.sel_point_ID = i
        first_selected = true
      end
      
      if tr then 
        if cnt_selected_pts > 0 then 
           data.obj_type = 'Envelope points ('..cnt_selected_pts..' selected)'
          else 
           data.obj_type = 'Envelope'
        end
      end
      --[[if selected then 
        if env_hasselpoint and env_hasselpoint == 1 and not env_hasselpoint == 2 then 
          env_hasselpoint = 2 
        end
        env_hasselpoint = 1        
      end]]
    end
    
    
    
    -- reaper.CountAutomationItems( env ) 
       
    --[[if env_hasselpoint == 1 then 
      data.obj_type = 'Envelope point'
      data.obj_type_int = 4  
     elseif env_hasselpoint == 2 then
      data.obj_type = 'Envelope points'
      data.obj_type_int = 5   
     else
      data.obj_type_int = 6
      data.obj_type = 'Envelope'
    end  ]]  
    return true
  end  
  -------------------------------------------------
  function DataUpdate_MIDIEditor(data, ME)
    data.name = ''  
    data.ep={}
    data.ME_ptr = ME
    
    local take= MIDIEditor_GetTake( ME ) 
    if not take or not ValidatePtr2( 0, take, 'MediaItem_Take*' ) then return end
    data.obj_type = 'MIDI Editor'
    data.obj_type_int = 8
    
    data.take_ptr = take 
    --local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
    --data.take_hash = MIDIstring
    local _, take_name = GetSetMediaItemTakeInfo_String( take, "P_NAME", '', false )   
    data.take_name = take_name
    local item  = GetMediaItemTake_Item( take )
    data.item_ptr = item
    data.item_pos = GetMediaItemInfo_Value( item, 'D_POSITION')
    
    
    -- parse RAW MIDI data
      if not take then return end
      data.evts = {}
      local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
      if not gotAllOK then return end
      local s_unpack = string.unpack
      local s_pack   = string.pack
      local MIDIlen = MIDIstring:len()
      local idx = 0    
      local offset, flags, msg1
      local first_selected, first_selectedCC, first_selectednote
      local ppq_pos = 0
      local nextPos, prevPos = 1, 1 
      local cnt_sel_notes, cnt_sel_CC, cnt_sel_evts_other = 0,0,0
      local last_note_id = {}
      while nextPos <= MIDIlen do  
          prevPos = nextPos
          offset, flags, msg1, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
          idx = idx + 1
          ppq_pos = ppq_pos + offset
          local selected = flags&1==1
          if not first_selected and selected then first_selected = idx end
          local pos_sec = MIDI_GetProjTimeFromPPQPos( take, ppq_pos )
          local pos_sec_format = format_timestr_pos( pos_sec, '', data.ruleroverride ) 
          local CClane, pitch, CCval,vel, pitch_format
          local isNoteOn = msg1:byte(1)>>4 == 0x9
          
          
          local isNoteOff = msg1:byte(1)>>4 == 0x8
          local isCC = msg1:byte(1)>>4 == 0xB
          local chan = 1+(msg1:byte(1)&0xF)
          if not first_selectedCC and selected and isCC then first_selectedCC = idx end
          if not first_selectednote and selected and isNoteOn then first_selectednote = idx end
          
          if isNoteOn or isNoteOff then 
            pitch = msg1:byte(2) 
            
            if isNoteOn then last_note_id[pitch] = idx end
            
            
            pitch_format = MPL_FormatMIDIPitch(data, pitch)
            vel = msg1:byte(3) 
            if selected then cnt_sel_notes = cnt_sel_notes+1  end
           elseif isCC then 
            CClane = msg1:byte(2) 
            CCval = msg1:byte(3)
            if selected then cnt_sel_CC = cnt_sel_CC + 1  end
           else 
            if selected then cnt_sel_evts_other = cnt_sel_evts_other + 1  end
          end
          data.evts[idx] = {rawevt = s_pack("i4Bs4", offset, flags , msg1),
                            offset=offset, 
                            flags=flags, 
                            selected =selected,
                            muted =flags&2==2,
                            msg1=msg1,
                            ppq_pos = ppq_pos,
                            pos_sec = pos_sec,
                            pos_sec_format = pos_sec_format,
                            isNoteOn =isNoteOn,
                            isNoteOff =isNoteOff,
                            isCC = isCC,
                            CClane=CClane,
                            pitch=pitch,
                            pitch_format=  pitch_format,
                            CCval=CCval,
                            chan = chan,
                            vel=vel}
        if last_note_id[pitch] and isNoteOff==true then 
          local last_rel_pitchid = last_note_id[pitch]
          local ppq_len = ppq_pos - data.evts[last_rel_pitchid].ppq_pos
          local len_sec = MIDI_GetProjTimeFromPPQPos( take, ppq_pos ) - data.evts[last_rel_pitchid].pos_sec
          local notelen_format = format_timestr_len(len_sec, '', 0, data.ruleroverride ) 
          data.evts[last_rel_pitchid].notelen = ppq_len
          data.evts[last_rel_pitchid].notelen_sec = len_sec
          data.evts[last_rel_pitchid].notelen_format = notelen_format
          last_note_id[pitch] = nil
        end
      end
      
      data.evts.first_selected = first_selected
      data.evts.first_selectednote = first_selectednote
      data.evts.first_selectedCC = first_selectedCC
      data.evts.cnt_sel_notes, data.evts.cnt_sel_CC, data.cnt_sel_evts_other =  math.ceil(cnt_sel_notes/2), cnt_sel_CC, cnt_sel_evts_other
      
    if cnt_sel_notes > 0 or cnt_sel_CC > 0 or cnt_sel_evts_other > 0 then
      local midistr = ''
      if cnt_sel_notes > 0 then midistr = midistr..'Note ('..math.ceil(cnt_sel_notes/2)..') ' end
      if cnt_sel_CC > 0 then midistr = midistr..'CC ('..cnt_sel_CC..')  ' end
      if cnt_sel_evts_other > 0 then midistr = midistr..'Others ('..cnt_sel_evts_other..')' end
      data.obj_type = midistr
    end


  end
  ----------------------------------------------------------------------
  function DataUpdate_Track_FXControls(data, tr, GUID)
    -- parse extstate
    data.tr_FXCtrl = {}
    local ret, str = GetProjExtState( 0, 'MPL_InfoTool', 'FXCtrl' )
    if ret ~= 1 then return end
    local linktr
    for line in str:gmatch('[^\r\n]+') do
      if line:match('LINK_TR') then linktr = line:match('LINK_TR[%s]+(.*)') end
      if linktr == GUID then
        if linktr and not data.tr_FXCtrl[linktr] then data.tr_FXCtrl[linktr] = {} end
        if linktr and line:match('SLOT [%d]+') then
          local t = {}
          for val in line:gmatch('[^%s]+') do t[#t+1] = val   end
          if #t == 7 then
            local trackGUID = t[3]
            local FX_GUID = t[4]
            local paramnum =   tonumber(t[5])
            local lim1 =       tonumber(t[6])
            local lim2 =       tonumber(t[7])
            local track = BR_GetMediaTrackByGUID( 0, trackGUID )
            local FXid = GetFXByGUID(track, FX_GUID)
            if FXid then 
              local val = TrackFX_GetParamNormalized( track, FXid, paramnum )
              local retval, paramname = TrackFX_GetParamName( track, FXid, paramnum, '' )
              local retval, paramformat = TrackFX_GetFormattedParamValue( track, FXid, paramnum, '' )
              local retval, fxname =  TrackFX_GetFXName( track, FXid, '' )
              local tr_ID = CSurf_TrackToID( track, false )
              table.insert(data.tr_FXCtrl[linktr],  { tr_ID=tr_ID,
                                                    trackGUID = trackGUID,
                                                    FX_GUID = FX_GUID,
                                                    paramnum = paramnum,
                                                    lim1 = lim1,
                                                    lim2 = lim2,
                                                    val = val,
                                                    paramname=paramname,
                                                    paramformat=paramformat,
                                                    fxname=fxname})
            end
          end
        end
      end
    end
    
  end
  
  ----------------------------------------------------------------------
  function DataUpdate_Track(data, tr)
    data.name = ''  
    data.tr = {}
    local cnt = CountSelectedTracks(0)
    if cnt > 1 then 
      data.obj_type = 'Tracks ('..cnt..')'
     else 
      data.obj_type = 'Track'
    end
    data.obj_type_int = 7
    if not data.curent_trFXID then data.curent_trFXID = 1 end
    
    local fr_cnt_min, fr_cnt_max = -math.huge,math.huge
    for i = 1, cnt do
      local tr = GetSelectedTrack(0,i-1)
      data.tr[i] = {GUID = GetTrackGUID( tr )}
      
      -- freeze
        local freezecnt = BR_GetMediaTrackFreezeCount( tr )
        data.tr[i].freezecnt=freezecnt
        fr_cnt_max = math.min(fr_cnt_max, freezecnt)
        fr_cnt_min = math.max(fr_cnt_min, freezecnt)
        
      -- sends 
        if i == 1 then
          data.tr_send = {}
          data.tr_cnt_sends = GetTrackNumSends(tr, 0 )
          data.tr_cnt_sendsHW = GetTrackNumSends(tr, 1 )
          for send_i = 1, data.tr_cnt_sends+data.tr_cnt_sendsHW do
            local desttr_ptr = BR_GetMediaTrackSendInfo_Track(tr, 0, send_i-1-data.tr_cnt_sendsHW, 1 )
            local s_vol = GetTrackSendInfo_Value( tr, 0, send_i-1-data.tr_cnt_sendsHW, 'D_VOL' )
            local s_vol_dB = WDL_VAL2DB(s_vol)  
            local retval, s_name = GetTrackSendName( tr, send_i-1-data.tr_cnt_sendsHW, '' )
            local s_vol_slider = DB2SLIDER(s_vol_dB )/1000
            data.tr_send[send_i] = {
                                    desttr_ptr=desttr_ptr,
                                    s_vol=s_vol,
                                    s_name=s_name,
                                    s_vol_slider=s_vol_slider,
                                    s_vol_dB=s_vol_dB}
          end
          if not data.active_context_id and data.tr_send[1] then 
            data.active_context_id = 1 
            data.active_context_sendmixer =      data.tr_send[1].s_name  
            data.active_context_sendmixer_val =  data.tr_send[1].s_vol
          end          
        end
    
      -- rec 
        if i == 1 then
          data.tr_recv = {}
          data.tr_cnt_receives = GetTrackNumSends(tr, -1 )
          for receives_i = 1, data.tr_cnt_receives do
            local _, r_name = GetTrackReceiveName(tr, receives_i-1, '' ) 
            local srctr_ptr = BR_GetMediaTrackSendInfo_Track(tr, -1, receives_i-1, 0 )
            local r_vol = GetTrackSendInfo_Value( tr, -1, receives_i-1, 'D_VOL' )
            local r_vol_dB = WDL_VAL2DB(r_vol)  
            local r_vol_slider = DB2SLIDER(r_vol_dB )/1000
            data.tr_recv[receives_i] = {srctr_ptr=srctr_ptr,
                                    r_vol=r_vol,
                                    r_name=r_name,
                                    r_vol_slider=r_vol_slider,
                                    r_vol_dB=r_vol_dB}
          end
          if not data.active_context_id2 and data.tr_recv[1] then 
            data.active_context_id2 = 1 
            data.active_context_sendmixer2 =      data.tr_recv[1].r_name  
            data.active_context_sendmixer_val2 =  data.tr_recv[1].r_vol
          end          
        end
                  
      -- FX 
        if i ==1 then
          data.tr[i].fx_names= {}
          local instr = TrackFX_GetInstrument( tr )
          for fxid = 1, TrackFX_GetCount( tr ) do 
            local vrs_num =  GetAppVersion()
            local vrs_num = tonumber(vrs_num:match('[%d%.]+'))
            local is_online = true 
            if vrs_num >= 5.95 then is_online = not TrackFX_GetOffline( tr, fxid-1 )  end      
            data.tr[i].fx_names[fxid] = {name = MPL_ReduceFXname(({TrackFX_GetFXName( tr, fxid-1, '' )})[2]),
                                          is_instr = instr==fxid-1,
                                          is_enabled =  TrackFX_GetEnabled( tr, fxid-1 ),
                                          is_online =  is_online}
          end
        end
        
      -- tr name 
        data.tr[i].ptr = tr
        local _, tr_name = GetTrackName( tr, '' )
        local trID = CSurf_TrackToID( tr, false )
        if trID < 1 then trID = '' else trID = trID..': '  end
        data.tr[i].name = trID..tr_name
        data.tr[i].name_proj = tr_name
      
      -- values
        data.tr[i].pan = GetMediaTrackInfo_Value( tr, 'D_PAN' )
        data.tr[i].pan_format = MPL_FormatPan(data.tr[i].pan)
        data.tr[i].vol = GetMediaTrackInfo_Value( tr, 'D_VOL' )
        data.tr[i].vol_format = dBFromReaperVal(data.tr[i].vol)..'dB'
        data.tr[i].pol = GetMediaTrackInfo_Value( tr, 'B_PHASE' )
        data.tr[i].parsend = GetMediaTrackInfo_Value( tr, 'B_MAINSEND' )         
        data.tr[i].col = GetTrackColor( tr )
        
        
        local toffs_flag = GetMediaTrackInfo_Value( tr, 'I_PLAY_OFFSET_FLAG' )
        local toffs = GetMediaTrackInfo_Value( tr, 'D_PLAY_OFFSET' )
        if toffs_flag&1==1 then
          toffs = 0
         else
          if toffs_flag&2== 2 then toffs = toffs / data.SR end
        end
        data.tr[i].toffs = math_q_dec(toffs,4 )
        data.tr[i].toffs_flag=toffs_flag
        
        
      -- delay time_adjustment
        data.tr[i].delay = 0
        local delayFX_pos = TrackFX_AddByName( tr, 'time_adjustment', false, 0 )
        if delayFX_pos >=0 then
          data.tr[i].delay_FXpos = delayFX_pos
          local val = TrackFX_GetParamNormalized( tr, delayFX_pos, 0 )
          data.tr[i].delay = (val-0.5)*0.2
        end
        data.tr[i].delay_format = format_timestr_len( data.tr[i].delay, '', 0,3 ) 
    end    
    
    data.tr.freezecnt_format = '('..data.tr[1].freezecnt..')'
    if cnt>1 then 
      if fr_cnt_min==0 and fr_cnt_max == 0 then 
        data.tr.freezecnt_format = '(0)'
       else
        data.tr.freezecnt_format = '('..fr_cnt_max..'-'..fr_cnt_min..')'
      end
    end
    
    if not data.defsendvol or not data.defsendpan then
      data.defsendvol = tonumber(({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendvol', '0',  get_ini_file() )})[2])
      data.defsendpan = 0
      data.defsendflag = tonumber(({BR_Win32_GetPrivateProfileString( 'REAPER', 'defsendflag', '0',  get_ini_file() )})[2])
    end
    
    if data.defsendvol then
      local dBval = dBFromReaperVal(data.defsendvol)
      if not tonumber(dBval) then dBval = -math.huge end
      data.defsendvol_format = string.format("%.2f", dBval)
      data.defsendvol_slider = reaper.DB2SLIDER(dBval )/1000
      data.defsendpan_format = MPL_FormatPan(data.defsendpan)
      data.defsendpan_slider = data.defsendpan
    end
    
    -- parse predefined sends
      data.PreDefinedSend_GUID = {}
      local retval, PreDefinedSend_GUID = GetProjExtState( 0, 'MPL_InfoTool', 'PreDefinedSend_GUID' )
      if retval > 0 then
        for GUID in PreDefinedSend_GUID:gmatch('[^%s]+') do data.PreDefinedSend_GUID[GUID] = 1 end
      end
      
    -- parse FX controls
      DataUpdate_Track_FXControls(data, tr, data.tr[1].GUID)
      
    return true
  end
