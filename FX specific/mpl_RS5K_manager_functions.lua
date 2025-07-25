-- @description mpl_RS5K_manager_functions
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

-- function for mpl_RS5K_manager and mpl_RS5K_SteSequencer
if not DATA then DATA = {} end
if not EXT then EXT = {} end
if not ImGui then ImGui = {} end
if not UI then UI = {} end



 
  --[[-------------------------------------------------------------------  
  function DATA:Launchpad_StuffSysex(SysEx_msg, mon_state0) 
    local mon_state = 0 if mon_state0 then mon_state = mon_state0 end
    if  DATA.MIDIbus and DATA.MIDIbus.tr_ptr and DATA.MIDIbus.valid == true then SetMediaTrackInfo_Value( DATA.MIDIbus.tr_ptr, 'I_RECMON', mon_state ) end -- prevent 
        
    if SysEx_msg and EXT.CONF_midioutput and EXT.CONF_midioutput ~=-1  then 
      local SysEx_msg_bin = '' for hex in SysEx_msg:gmatch('[A-F,0-9]+') do  SysEx_msg_bin = SysEx_msg_bin..string.char(tonumber(hex, 16)) end 
      SendMIDIMessageToHardware(EXT.CONF_midioutput, SysEx_msg_bin)   
    end
  end  ]]
  --------------------------------------------------------------------------------  
  function DATA:_Seq_PrintEnvelopes_GetEnvByParamName(track, param) local seq_envelope
    if not track then return end
    if not param then return end
    if not param:match('env_') then return end
    
    if param:match('env_pan') then 
      seq_envelope = GetTrackEnvelopeByChunkName( track, '<PANENV2' )
      if seq_envelope then  
        return seq_envelope, GetEnvelopeScalingMode( seq_envelope )
      end
    end
    
    if param:match('env_tracksend') then 
      local destGUID = param:match('(%{.-%})')
      if not destGUID then return end 
      local cntsends = GetTrackNumSends( track, 0 )
      for sendidx = 1, cntsends do 
        local P_DESTTRACK = GetTrackSendInfo_Value( track, 0, sendidx-1, 'P_DESTTRACK' )
        local P_DESTTRACKGUID = GetTrackGUID(P_DESTTRACK)
        if P_DESTTRACKGUID == destGUID then 
          seq_envelope =  GetTrackSendInfo_Value( track, 0, sendidx-1, 'P_ENV:<VOLENV' )
          if seq_envelope then  
            return seq_envelope, GetEnvelopeScalingMode( seq_envelope )
          end
        end
      end
    end
    
    if param:match('env_FX') then 
      local fxGUID,paramID = param:match('env_FX_(%{.-%})([%d]+)')
      if fxGUID and paramID then
        local ret,tr, fxid = VF_GetFXByGUID(fxGUID, track, DATA.proj)
        if fxid then
          local retval, minval, maxval = reaper.TrackFX_GetParam( track, fxid, paramID)
          seq_envelope = GetFXEnvelope( track, fxid, paramID, true )
          if seq_envelope then  return seq_envelope, GetEnvelopeScalingMode( seq_envelope ),minval, maxval end
        end
      end
    end
    
    
  
  end
  --------------------------------------------------------------------------------  
  function DATA:_Seq_PrintEnvelopes_writesteps(param_t, note)
    -- param t
      local seq_envelope = param_t.seq_envelope
      local scaling_mode = param_t.scaling_mode
      local minval = param_t.minval
      local maxval = param_t.maxval
      local param = param_t.param
       
    -- seq
      local t = DATA.seq
    
    -- pat data
      local pat_st = t.it_pos 
      local pat_end = pat_st + t.it_len
      local step_cnt = t.ext.children[note].step_cnt 
      if step_cnt == -1 then step_cnt = t.ext.patternlen end
      local steplength = 0.25
      if t.ext.children[note].steplength then steplength = t.ext.children[note].steplength end 
      local patlen_mult = 1
      if steplength<0.25 then patlen_mult = math.ceil(0.25/steplength) end
      local app_swing 
      if t.ext.swing~= 0 and steplength==0.25 then app_swing = t.ext.swing end
      if not t.ext.children[note].steps then t.ext.children[note].steps = {} end
      if not t.ext.children[note].steps[1] then t.ext.children[note].steps[1] = {val = 0} end
    
    -- clear env 
      DeleteEnvelopePointRange( seq_envelope, pat_st, pat_end-0.001 )
      
    -- boundary clamp
      local retval, cur_value, dVdS, ddVdS, dddVdS = Envelope_Evaluate( seq_envelope, pat_st-0.001, DATA.SR, 1 ) 
      local retval, cur_value_end, dVdS, ddVdS, dddVdS = Envelope_Evaluate( seq_envelope, pat_end, DATA.SR, 1 ) 
      local shape = 0
      local tension = 0
      InsertEnvelopePoint( seq_envelope, pat_st, cur_value, shape, tension, false, true )
      InsertEnvelopePoint( seq_envelope, pat_end-0.001, cur_value_end, shape, tension, false, true )
      local cur_value_scaled = ScaleFromEnvelopeMode( scaling_mode, cur_value )
      
    -- write values
      -- loop pattern length
      for step = 1, t.ext.patternlen*patlen_mult do 
        -- step pos
          local step_active = step%step_cnt 
          if step_active == 0 then step_active = step_cnt end 
          
        -- clamp strat of pattern if step not exist
          local allow_empty_steps =  t.ext.children[note].steps[step_active].val == 1
          if EXT.CONF_seq_env_clamp == 0 then allow_empty_steps = true end
          
          if not (t.ext.children[note].steps and t.ext.children[note].steps[step_active]) and step ~= 1 then goto skipnextstep end  
          local active = t.ext.children[note].steps[step_active] and t.ext.children[note].steps[step_active].val and allow_empty_steps == true
          
          if step ~= 1  then
            if not active then goto skipnextstep end  
          end
          
        -- val definition
          local val = t.ext.children[note].steps[step_active][param] 
          if not val or (step == 1 and not active)  then val = cur_value_scaled end
          val = ScaleToEnvelopeMode( scaling_mode, minval + val*(maxval-minval) ) 
          
        -- position
          local offset = 0
          local sw_shift = 0
          if t.ext.children[note].steps[step_active].offset then offset = t.ext.children[note].steps[step_active].offset*steplength end 
          if app_swing and step%2==0 then sw_shift = app_swing*steplength*0.5 end
          local beatpos = (step-1)*steplength
          local beatlen = steplength
          local beatpos_st = math.max(0, beatpos + offset + sw_shift)
          local beatpos_end =  math.min(beatpos+beatlen + offset ,t.ext.patternlen) 
          local point_pos = TimeMap2_beatsToTime(   DATA.proj, t.it_pos_fullbeats + beatpos_st )  
          if point_pos > pat_end then goto skipnextstep end  
        -- insert point
          local shape = 1
          local tension = 0 
          InsertEnvelopePoint( seq_envelope, point_pos, val, shape, tension, false, true ) 
          
        ::skipnextstep::
      end
      
    -- sort 
      Envelope_SortPoints( seq_envelope )
    
  end
  --------------------------------------------------------------------------------  
  function DATA:_Seq_PrintEnvelopes_note(note)
    if not (DATA.children[note] and DATA.seq.ext.children[note].steps and DATA.seq.ext.children[note].steps[0]) then return end -- 0 as a step check for existing params
    
    local srctr = DATA.children[note].tr_ptr 
    
    -- get parameters
    local parameters = {} 
    for param in pairs(DATA.seq.ext.children[note].steps[0]) do 
      local seq_envelope, scaling_mode,minval, maxval = DATA:_Seq_PrintEnvelopes_GetEnvByParamName(srctr, param)
      if seq_envelope then
        if not minval then minval = 0 end
        if not maxval then maxval = 1 end
        parameters[#parameters+1] = {
          param=param,
          seq_envelope=seq_envelope,
          scaling_mode=scaling_mode,
          minval=minval,
          maxval=maxval,
          } 
          
        -- initialize if not  exist
        local retval, ACTIVE = GetSetEnvelopeInfo_String( seq_envelope, 'ACTIVE', '', false )
        if ACTIVE and ACTIVE == '0' then 
          GetSetEnvelopeInfo_String( seq_envelope, 'ACTIVE', '1', true ) 
          GetSetEnvelopeInfo_String( seq_envelope, 'VISIBLE', '1', true ) 
          TrackList_AdjustWindows( false )
        end
        
      end
    end 
    local parameter_sz = #parameters
    if parameter_sz == 0 then return end 
    for paramID = 1, parameter_sz do DATA:_Seq_PrintEnvelopes_writesteps(parameters[paramID], note) end
    
  end
  --------------------------------------------------------------------------------  
  function DATA:_Seq_PrintEnvelopes(t)
    if not (t.ext and t.ext.children) then return end
    for note in pairs(t.ext.children) do DATA:_Seq_PrintEnvelopes_note(note, seqstart_fullbeats) end 
  end 
  --------------------------------------------------------------------------------   
  function DATA:_Seq_FXremove(note, parameter)
    local fxGUID,paramID = parameter:match('env_FX_(%{.-%})([%d]+)')
    if paramID and tonumber(paramID) then paramID = tonumber(paramID) end
    if not (fxGUID and paramID) then return end
    DATA.seq.ext.children[note].env_FXparamlist[fxGUID][paramID] = nil
    if DATA.seq.ext.children[note].steps then 
      for step in pairs(DATA.seq.ext.children[note].steps) do
        DATA.seq.ext.children[note].steps[step][parameter] = nil
        DATA.seq.ext.children[note].steps[step][parameter..'_shape'] = nil
        DATA.seq.ext.children[note].steps[step][parameter..'_tension'] = nil
      end
    end
    
    DATA:_Seq_Print()
  end
  --------------------------------------------------------------------------------  
  function DATA:_Seq_AddLastTouchedFX() 
    local retval, trackidx, itemidx, takeidx, fxidx, parm = GetTouchedOrFocusedFX( 0 )
    if not retval then return end
    local track = GetTrack(DATA.proj,trackidx)
    if not track then return end
    if itemidx >=0 then return end
    
    local note_layer_t, note, layer = DATA:Sampler_GetActiveNoteLayer()  
    if not note_layer_t then return end
    if note_layer_t.tr_ptr ~= track then return end
    
    if not DATA.seq.ext.children[note] then DATA.seq.ext.children[note] = {} end
    if not DATA.seq.ext.children[note].env_FXparamlist then DATA.seq.ext.children[note].env_FXparamlist = {} end
    
    local fxGUID = TrackFX_GetFXGUID( track, fxidx )
    if not fxGUID then return end
    if not DATA.seq.ext.children[note].env_FXparamlist[fxGUID] then DATA.seq.ext.children[note].env_FXparamlist[fxGUID] = {} end
    DATA.seq.ext.children[note].env_FXparamlist[fxGUID][parm] = 1
    DATA.temp_forceLTP_kselection = {fxGUID=fxGUID,parm=parm}
    
    DATA:_Seq_Print()
  end
  --------------------------------------------------------------------------------  
  function DATA:_Seq_CollectTrackEnv(fxGUID0,parm0 ) 
    local note_layer_t,note, layer = DATA:Sampler_GetActiveNoteLayer()  
    if not note_layer_t then return end
    
    -- track env 
    DATA.seq_param_selector_trackenv = {}
    
    -- pan
    DATA.seq_param_selector_trackenv[#DATA.seq_param_selector_trackenv+1] = {
      param = 'env_pan', 
      str= 'Pan',
      default=0, 
      minval = -1, 
      maxval = 1
      } 
      
    -- add sends
    if note_layer_t.sends then
      for sendidx = 1, #note_layer_t.sends do
        local P_DESTTRACKGUID=  note_layer_t.sends[sendidx].P_DESTTRACKGUID
        local str = 'Send: '..note_layer_t.sends[sendidx].P_DESTTRACKname
        DATA.seq_param_selector_trackenv[#DATA.seq_param_selector_trackenv+1] = {
          param = 'env_tracksend'..P_DESTTRACKGUID, 
          str= str,
          default=0, 
          minval = 0, 
          maxval = 1
          }
      end
    end
    
    
    -- track env  
    DATA.seq_param_selector_trackFXenv = {}
    if DATA.seq.ext.children[note].env_FXparamlist then 
      for fxGUID in spairs(DATA.seq.ext.children[note].env_FXparamlist) do
        for paramID in spairs(DATA.seq.ext.children[note].env_FXparamlist[fxGUID]) do
          if DATA.children[note] and DATA.children[note].tr_ptr then 
            local ret, tr, fxid = VF_GetFXByGUID(fxGUID, DATA.children[note].tr_ptr, DATA.proj)
            if fxid then
              local retval, fxname = reaper.TrackFX_GetFXName( DATA.children[note].tr_ptr, fxid )
              fxname = VF_ReduceFXname(fxname)
              local retval, paramname = reaper.TrackFX_GetParamName( DATA.children[note].tr_ptr, fxid,paramID)
              local id = #DATA.seq_param_selector_trackFXenv+1
              DATA.seq_param_selector_trackFXenv[id] = {
                  param = 'env_FX_'..fxGUID..paramID, 
                  str= fxname..' / #'..paramID..' - '..paramname, 
                  default=0, 
                  minval = 0, 
                  maxval = 1
                  }
              if DATA.temp_forceLTP_kselection and  DATA.temp_forceLTP_kselection.fxGUID and DATA.temp_forceLTP_kselection.parm then
                if DATA.temp_forceLTP_kselection.fxGUID == fxGUID and DATA.temp_forceLTP_kselection.parm == paramID then 
                  DATA.seq_param_selector_trackFXenvID = id
                  DATA.temp_forceLTP_kselection = nil
                end
              end
            end
          end
        end
      end
    end
    
  end
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
  function DATA:_Seq_FillNoteStepsToFullLength(note)   --Print to full pattern length 
  
    if note then
      if not (DATA.seq.ext and DATA.seq.ext.children and note and DATA.seq.ext.children[note]) then return end
      local step_cnt = DATA.seq.ext.children[note].step_cnt
      for step = step_cnt+1, DATA.seq.ext.patternlen do
        local activestep = (step%step_cnt)
        if activestep == 0 then activestep = step_cnt end
        DATA.seq.ext.children[note].steps[step] = CopyTable(DATA.seq.ext.children[note].steps[activestep])
      end 
      
      DATA.seq.ext.children[note].step_cnt = -1
      DATA:_Seq_Print()
    end
    
    if not note then
      if not (DATA.seq.ext and DATA.seq.ext.children) then return end 
      for note in pairs(DATA.seq.ext.children) do
        local step_cnt = DATA.seq.ext.children[note].step_cnt
        if step_cnt ~= -1 then
          for step = step_cnt+1, DATA.seq.ext.patternlen do
            local activestep = (step%step_cnt)
            if activestep == 0 then activestep = step_cnt end
            DATA.seq.ext.children[note].steps[step] = CopyTable(DATA.seq.ext.children[note].steps[activestep])
          end 
          DATA.seq.ext.children[note].step_cnt = -1
        end 
        
      end
      DATA:_Seq_Print()
    end
    
    
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
    if step_cnt == -1 then step_cnt = DATA.seq.ext.patternlen end
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
  function DATA:_Seq_Print(do_not_ignore_empty, minor_change) 
    if not (DATA.MIDIbus and DATA.MIDIbus.tr_ptr and DATA.MIDIbus.valid) then return end
    if not (DATA.seq.it_ptr and DATA.seq.tk_ptr) then return end
    if not DATA.seq.ext.children then return end 
    local item = DATA.seq.it_ptr
    local take = DATA.seq.tk_ptr
    if not (take and ValidatePtr2(DATA.proj, take, 'MediaItem_Take*')) then DATA.seq = nil return end
    
    
    if minor_change~=true then 
      Undo_BeginBlock2(DATA.proj)
      --test = time_precise()
      local outstr = table.savestring(DATA.seq.ext) --outstr = VF_encBase64(outstr) -- 4.43 off 
      GetSetMediaItemTakeInfo_String( take, 'P_EXT:MPLRS5KMAN_PATDATA', outstr, true)
      GetSetMediaItemTakeInfo_String( take, 'P_EXT:MPLRS5KMAN_PATDATA_IGNOREB64', 1, true) -- 4.43 patch DO NOT REMOVE
      --msg(os.date()..' '..time_precise()-test)
      DATA:_Seq_PrintMIDI_ShareGUID(DATA.seq ,outstr) -- store pattern data to the same GUID takes 
      Undo_EndBlock2(DATA.proj, 'Pattern edit', 0xFFFFFFFF)
      
      
    end 
    DATA:_Seq_PrintEnvelopes(DATA.seq)
    DATA:_Seq_PrintMIDI(DATA.seq) 
    GetSetMediaItemTakeInfo_String( take, 'P_EXT:MPLRS5KMAN_PATGUID', DATA.seq.ext.GUID, true) 
    
  end
  --------------------------------------------------------------------------------  
  function DATA:_Seq_PrintMIDI_ShareGUID(parent_t ,outstr) 
    if EXT.CONF_seq_force_GUIDbasedsharing~= 1 then return end
    
    local parenttake = parent_t.tk_ptr
    local parentGUID = parent_t.ext.GUID
    local form_data = parent_t.form_data
    local tr = DATA.MIDIbus.tr_ptr 
    local cnt = reaper.CountTrackMediaItems( tr)
    for itemidx = 1, cnt do
      local item = reaper.GetTrackMediaItem(tr, itemidx-1)
      local take = GetActiveTake(item)
      local it_pos = reaper.GetMediaItemInfo_Value( item,'D_POSITION' )  
      local ret, GUID = GetSetMediaItemTakeInfo_String( take, 'P_EXT:MPLRS5KMAN_PATGUID', '', false)
      if parenttake ~= take and ret and GUID ~= '' and GUID == parentGUID then  
        GetSetMediaItemTakeInfo_String( take, 'P_EXT:MPLRS5KMAN_PATDATA', outstr, true)
        local src = GetMediaItemTake_Source( take )
      end
    end
    
  end 
  --------------------------------------------------------------------------------  
  function math_q(num)  if math.abs(num - math.floor(num)) < math.abs(num - math.ceil(num)) then return math.floor(num) else return math.ceil(num) end end
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
    if DATA.seq_functionscall ~= true then return end 
    local retval, cur_projfn = reaper.EnumProjects( -1 ) 
    local last_valid_seq = CopyTable(DATA.seq)
    local item = GetSelectedMediaItem( -1, 0 )
    
    if last_valid_seq and last_valid_seq.valid==true and ValidatePtr(last_valid_seq.it_ptr, 'MediaItem*') then  
      if last_valid_seq.proj == DATA.proj then -- if same project
        if not item or (item and last_valid_seq.it_ptr == item)  then
          
          DATA.seq = last_valid_seq 
          return
        end
      end 
    end
    
    
    
    -- init pattern defaults
    DATA.seq = {
      valid = false,
      proj = DATA.proj,
      ext = {
              patternlen = 16,
              patternsteplen = EXT.CONF_seq_steplength, 
              children={}, 
              step_defaults={},
              swing = 0,
            },
      }
    
    
    -- init  
    
    if not item then return end
    local take = GetActiveTake(item)
    DATA.seq.valid = true
    DATA.seq.it_ptr = item
    DATA.seq.tk_ptr = take 
    DATA.seq.it_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
    local retval, measures, cml, seqstart_fullbeats, cdenom = reaper.TimeMap2_timeToBeats(DATA.proj, DATA.seq.it_pos ) 
    DATA.seq.it_pos_fullbeats = seqstart_fullbeats
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
    DATA.seq.srccount =  DATA.seq.it_len  / math.max(0.1,DATA.seq.srclen_sec)
    
    
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
    for note in spairs(DATA.children) do
      if not DATA.seq.ext.children[note] then DATA.seq.ext.children[note] = {} end
      if not DATA.seq.ext.children[note].steps then DATA.seq.ext.children[note].steps = {} end -- this is fixing wrong offset on misssing first step at DATA:_Seq_PrintMIDI(t) --{val=0} 
      if not DATA.seq.ext.children[note].step_cnt then DATA.seq.ext.children[note].step_cnt = EXT.CONF_seq_defaultstepcnt end--DATA.seq.ext.patternlen end -- init 16 steps 
      if not DATA.seq.ext.children[note].steplength then DATA.seq.ext.children[note].steplength = 0.25 end -- init 16 steps 
      
      for step = 1, DATA.seq.ext.children[note].step_cnt do
        if not DATA.seq.ext.children[note].steps[step] then DATA.seq.ext.children[note].steps[step] = {} end
        if not DATA.seq.ext.children[note].steps[step].val then DATA.seq.ext.children[note].steps[step].val = 0 end
      end
    end
    
    DATA:_Seq_RefreshHScroll()
    DATA:_Seq_CollectTrackEnv()
    
    local IDorder = 0
    for note in spairs(DATA.seq.ext.children) do
      IDorder = IDorder + 1
      DATA.seq.ext.children[note].IDorder = 9-IDorder
    end
    
    -- form matrix
    DATA.lp_matrix = {}
    for row = 1, 8 do
      DATA.lp_matrix[row] = {}
      for col = 1, 8 do
        DATA.lp_matrix[row][col] = {MIDI_note = col + ((9-row)*10)}
      end
    end
    
    
  end
  --------------------------------------------------------------------------------  
  function DATA:_Seq_RefreshHScroll()
    patlen = DATA.seq.ext.patternlen or 16
    DATA.seq.max_scroll = math.max(16,patlen-16) 
    DATA.seq.stepoffs = math.floor((DATA.seq_horiz_scroll or 0)*DATA.seq.max_scroll)
    if DATA.seq.ext.patternlen >= 128 then
      DATA.seq.stepoffs = 16 * math.floor(DATA.seq.stepoffs / 16) 
    end
  end
  
  --------------------------------------------------------------------------------  
  function DATA:_Seq_ModifyTools(note, mode, dir) 
    if not (DATA.seq.ext and DATA.seq.ext.children and note and DATA.seq.ext.children[note]) then return end
    local step_cnt = DATA.seq.ext.children[note].step_cnt
    if step_cnt == -1 then step_cnt = DATA.seq.ext.patternlen end
    local init = CopyTable(DATA.seq.ext.children[note].steps)
    
    if not init then return end
    -- shift
    if mode == 0 then 
      for i = 1, step_cnt do
        local src_step = i+1*dir
        if src_step > step_cnt then src_step = 1 end
        if src_step < 1 then src_step = step_cnt end
        if not DATA.seq.ext.children[note] then DATA.seq.ext.children[note] = {} end
        if not DATA.seq.ext.children[note].steps then DATA.seq.ext.children[note].steps = {} end
        if not DATA.seq.ext.children[note].steps[i] then DATA.seq.ext.children[note].steps[i] = {} end
        
        
        --local val = 0 
        --if init[src_step] and init[src_step].val then val = init[src_step].val end
        --DATA.seq.ext.children[note].steps[i].val = val or 0
        DATA.seq.ext.children[note].steps[i] = init[src_step]
      end
    end
    
    -- flip
    if mode == 1 then 
      for i = 1, step_cnt do
        local src_step = step_cnt - i + 1
        if init[src_step] and init[src_step].val then val = init[src_step].val end
        if not DATA.seq.ext.children[note] then DATA.seq.ext.children[note] = {} end
        if not DATA.seq.ext.children[note].steps then DATA.seq.ext.children[note].steps = {} end
        if not DATA.seq.ext.children[note].steps[i] then DATA.seq.ext.children[note].steps[i] = {} end 
        --local val = 0 
        --DATA.seq.ext.children[note].steps[i].val = val or 0
        DATA.seq.ext.children[note].steps[i] = init[src_step]
      end
    end
    
    -- flip
    if mode == 2 then 
      
      math.randomseed(time_precise()*10000)
      for i = 1, step_cnt do
        local val = 0 
        local rand = math.random()
        if rand <= EXT.CONF_seq_random_probability then val = 1 else val = 0 end 
        if init[src_step] and init[src_step].val then val = init[src_step].val end
        if not DATA.seq.ext.children[note] then DATA.seq.ext.children[note] = {} end
        if not DATA.seq.ext.children[note].steps then DATA.seq.ext.children[note].steps = {} end
        if not DATA.seq.ext.children[note].steps[i] then DATA.seq.ext.children[note].steps[i] = {} end
        DATA.seq.ext.children[note].steps[i].val = val or 0
      end
    end
    
    
    DATA:_Seq_Print() 
  end
  --------------------------------------------------------------------------------  
  function DATA:_Seq_PrintMIDI(t, do_not_ignore_empty, overrides) 
    local item = t.it_ptr
    local take = t.tk_ptr
    local item_pos = t.it_pos
    
    local metashift = 0
    local ppqreduce = 1
     
    if not (item and take) then return end
    if not t.ext.children then return end
    
    -- init ppq
    form_data = {}
    local steplength = 0.25 -- do not touch
    local _, _, _ seqstart_fullbeats = reaper.TimeMap2_timeToBeats( DATA.proj, item_pos ) 
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
      if step_cnt == -1 then step_cnt = DATA.seq.ext.patternlen end
      
      local patlen_mult = 1
      if steplength<0.25 then patlen_mult = math.ceil(0.25/steplength) end
      
      local app_swing 
      if DATA.seq.ext.swing~= 0 and steplength==0.25 then app_swing = DATA.seq.ext.swing end
      
      if not t.ext.children[note].steps then t.ext.children[note].steps = {} end
      if not t.ext.children[note].steps[1] then t.ext.children[note].steps[1] = {val = 0} end
      for step = 1, DATA.seq.ext.patternlen*patlen_mult do
        local step_active = step%step_cnt 
        if step_active == 0 then step_active = step_cnt end
        if not (t.ext.children[note].steps and t.ext.children[note].steps[step_active]) then goto skipnextstep end
        
        -- val 
        local val = t.ext.children[note].steps[step_active].val
        
        -- velocity
        local velocity = 0
        if val == 1 then velocity = default_velocity end
        if val == 1 and t.ext.children[note].steps[step_active].velocity then velocity = math.floor(t.ext.children[note].steps[step_active].velocity*127) end
        if velocity == 0 and step_active ~= 1 then goto skipnextstep end 
        
        -- split
        local split = 1
        if t.ext.children[note].steps[step_active].split then split = math_q(t.ext.children[note].steps[step_active].split) end 
        
        -- meta
        local addmeta
        local meta_pitch = 64
        if t.ext.children[note].steps[step_active].meta_pitch then meta_pitch = t.ext.children[note].steps[step_active].meta_pitch end 
        local meta_probability = 1
        if t.ext.children[note].steps[step_active].meta_probability then meta_probability = t.ext.children[note].steps[step_active].meta_probability end 
        if val ==1 and (meta_pitch ~= 64 or meta_probability ~= 1) then 
          addmeta = true
        end
        
        
        -- offset  / swing
        local offset = 0
        local sw_shift = 0
        if t.ext.children[note].steps[step_active].offset then offset = t.ext.children[note].steps[step_active].offset*steplength end 
        if app_swing and step%2==0 then sw_shift = app_swing*steplength*0.5 end
        local beatpos = (step-1)*steplength
        local beatlen = steplength
        if t.ext.children[note].steps[step_active].steplen_override then 
          beatlen = steplength * t.ext.children[note].steps[step_active].steplen_override
        end
        local beatpos_st = math.max(0, beatpos +offset + sw_shift)
        local beatpos_end =  math.min(beatpos+beatlen + offset ,DATA.seq.ext.patternlen)
        if  beatpos_st > DATA.seq.ext.patternlen then goto skipnextstep end
        
        
        local steppos_start_sec = TimeMap2_beatsToTime(   DATA.proj, seqstart_fullbeats + beatpos_st ) 
        local steppos_end_sec = TimeMap2_beatsToTime(     DATA.proj, seqstart_fullbeats + beatpos_end) 
        local steppos_start_ppq = MIDI_GetPPQPosFromProjTime( take, steppos_start_sec ) 
        local steppos_end_ppq = MIDI_GetPPQPosFromProjTime( take, steppos_end_sec )
        if  steppos_end_ppq - steppos_start_ppq < 2 then goto skipnextstep end
        
        --if sw_shift ~= 0 or offset ~= 0 then split = 1 end 
        
        if steppos_start_ppq < seqend_endppq then--and steppos_end_ppq < seqend_endppq then
          
          steppos_end_ppq = math.min(steppos_end_ppq, seqend_endppq)
          steppos_start_ppq = math.floor(steppos_start_ppq)
          steppos_end_ppq = math.floor(steppos_end_ppq)
          
          if split == 1 then 
            
            local meta
            if addmeta then
                  meta = {
                      [1] = note, -- note
                      [2] = math_q(meta_pitch or 64), -- pitch
                      [3] = math_q((meta_probability or 1)*127), -- probability
                  }
            end
            
            -- single note
            form_data[#form_data+1] = {
              ppq_start = steppos_start_ppq,
              ppq_end = steppos_end_ppq-ppqreduce,
              pitch = note,
              vel = velocity,
              meta=CopyTable(meta),
            }
            
            
            
           else
           
            -- split note
            local ppq_len = steppos_end_ppq - steppos_start_ppq
            local sliceppq_len = math.floor(ppq_len / split)
            for i = 1, split do
              local slice_steppos_start_ppq = steppos_start_ppq + sliceppq_len*(i-1)
              local slice_steppos_end_ppq = slice_steppos_start_ppq + sliceppq_len
              local meta
              if addmeta then
                  meta = {
                    [1] = note, -- note
                    [2] = math_q(meta_pitch or 64), -- pitch
                    [3] = math_q((meta_probability or 1)*127), -- probability
                  }
              end
              
              form_data[#form_data+1] = {
                ppq_start = slice_steppos_start_ppq,
                ppq_end = slice_steppos_end_ppq-ppqreduce,
                pitch = note,
                vel = velocity,
                meta=meta,
              }
            end
            
            
            
          end
          
          
          
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
    local str = ''
    local sz = #form_data
    for i = 1, sz do 
      
      --meta
      local SysEx_msg_bin = '' 
      if form_data[i].meta then
        local SysEx_msg = 'F0 60 01 '
        for id = 1, #form_data[i].meta do SysEx_msg= SysEx_msg..string.format("%X", form_data[i].meta[id])..' ' end SysEx_msg= SysEx_msg..'F7'
        for hex in SysEx_msg:gmatch('[A-F,0-9]+') do  SysEx_msg_bin = SysEx_msg_bin..string.char(tonumber(hex, 16)) end 
      end
      
      -- notes
      local pitch = form_data[i].pitch
      if pitch and  form_data[i].vel then
        local ppq = form_data[i].ppq_start
        local offset = ppq - lastppq
        
        -- note ON
        local offs_sysex = offset
        local offs_noteon = offset
        if SysEx_msg_bin ~= '' then 
          str = str..string.pack("i4Bs4", offs_sysex, flags, SysEx_msg_bin)
          offs_noteon = 0
        end
        str = str..string.pack("i4Bi4BBB", offs_noteon, flags, 3, 0x90, pitch, form_data[i].vel ) 
        lastppq = ppq
        
        -- noteOFF
        local ppq = form_data[i].ppq_end
        local offset = ppq - lastppq
        str = str..string.pack("i4Bi4BBB", offset, flags, 3, 0x80, pitch, 0)
        
        lastppq = ppq 
      end
      
      
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
    
    if DATA.seq.D_STARTOFFS~= 0 then return end
    if DATA.seq.srccount~= 1 then return end
    
    local out_len_beats = DATA.seq.ext.patternlen * DATA.seq.ext.patternsteplen 
    local retval, measures, cml, fullbeats_pos, cdenom = reaper.TimeMap2_timeToBeats( DATA.proj, DATA.seq.it_pos )
    local out_end_sec_OLD = TimeMap2_beatsToTime( proj, fullbeats_pos +  out_len_beats)
    
    local out_len_beats = patternlen * DATA.seq.ext.patternsteplen 
    local retval, measures, cml, fullbeats_pos, cdenom = reaper.TimeMap2_timeToBeats( DATA.proj, DATA.seq.it_pos )
    local out_end_sec = TimeMap2_beatsToTime( proj, fullbeats_pos +  out_len_beats)
    
    SetMediaItemInfo_Value( DATA.seq.it_ptr, 'D_LENGTH', out_end_sec - DATA.seq.it_pos )
    UpdateItemInProject(DATA.seq.it_ptr)
    
    
    if EXT.CONF_seq_patlen_extendchildrenlen ==1 and DATA.seq.ext and DATA.seq.ext.children then 
      for note in pairs(DATA.seq.ext.children) do if DATA.seq.ext.children[note].step_cnt ~= -1 then DATA.seq.ext.children[note].step_cnt = patternlen end end
    end
    
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
    if not data then return end
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
    if DATA.REAPERini and DATA.REAPERini.REAPER and DATA.REAPERini.REAPER.midioctoffs then offs = DATA.REAPERini.REAPER.midioctoffs-1 end
    local val = math.floor(note)
    local oct = math.floor(note / 12) + offs
    local note = math.fmod(note,  12)
    local key_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
    
    local out_str 
    
    -- handle names
      if t and t.P_NAME then return t.P_NAME end
      
    -- note  
      if note and oct and key_names[note+1] then 
        return key_names[note+1]..oct-1 
      end
  end
  
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or (x and x < 0.0000000298023223876953125) then return -150.0 end
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
    if not DATA.upd2 then return end
    
    if DATA.upd2.updatedevicevelocityrange then DATA:Auto_Device_RefreshVelocityRange(DATA.upd2.updatedevicevelocityrange) DATA.upd2.updatedevicevelocityrange = nil end
    if DATA.upd2.seqprint then DATA:_Seq_Print(nil, DATA.upd2.seqprint_minor) DATA.upd2.seqprint=nil DATA.upd2.seqprint_minor=nil end
    if DATA.upd2.refreshpeaks then DATA:CollectData2_GetPeaks() DATA.upd2.refreshpeaks = false end
    --DATA.upd2.refreshscroll
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
    
    if not DATA.seq_functionscall then 
      gmem_write(1025, 11) -- DATA.upd - step seq
    end
    
    DATA:_Seq_RefreshStepSeq()
  end
  -------------------------------------------------------------------------------- 
  function DATA:_Seq_RefreshStepSeq() 
    if not DATA.seq_functionscall then 
      gmem_write(1030,1 ) -- DATA.upd refresh steseq 
      gmem_write(1028, 1) -- force step seq to refresh EXT
    end
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
    DATA.projstr = tostring(DATA.proj)
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
    DATA:Choke_Read() 
    
    -- seq
    DATA:CollectData_Seq()
    
    --
    local allow_trig_auto_stuff = true
    if DATA.mainstate_manager == true and DATA.mainstate_seq == true then 
      if DATA.seq_functionscall == true then 
        if gmem_read(1028) == 1 then
          EXT:load()
          DATA.upd = true
          gmem_write(1028, 0)
        end
        allow_trig_auto_stuff = false 
      end
    end
    if allow_trig_auto_stuff == true then 
      -- auto handle stuff
      DATA:Auto_MIDIrouting() 
      DATA:Auto_MIDInotenames() 
      DATA:Auto_TCPMCP() 
    end
    
    DATA.upd2.refreshpeaks = true
  end
  -------------------------------------------------------------------------------- 
  function DATA:Auto_TCPMCP(force_show)
    if not (DATA.parent_track and DATA.parent_track.valid == true) then return end 
    local upd
    --CONF_onadd_newchild_trackheightflags = 0, -- &1 folder collapsed &2 folder supercollapsed &4 hide tcp &8 hide mcp
    
    -- reset after settings change
      if force_show == true then 
        SetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT', 0)
        for note in pairs(DATA.children) do
          local tr = DATA.children[note].tr_ptr
          SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 1)
          SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP',1 )
          -- children
          for layer = 1, #DATA.children[note].layers do 
            local tr = DATA.children[note].layers[layer].tr_ptr
            if tr then 
              SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 1 )
              SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP', 1 ) 
            end
          end
        end
        upd=true
      end
    
    -- set folder state
      if EXT.CONF_onadd_newchild_trackheightflags &1==1 then       -- set folder collapsed
        SetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT', 1)
       elseif EXT.CONF_onadd_newchild_trackheightflags &2==2 then       -- set folder collapsed
        SetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT', 2)
       elseif EXT.CONF_onadd_newchild_trackheightflags &2~=2 and EXT.CONF_onadd_newchild_trackheightflags &1~=1 then       -- set folder collapsed
        --local foldstate = GetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT')   
        --if foldstate ~=0 then SetMediaTrackInfo_Value( DATA.parent_track.ptr, 'I_FOLDERCOMPACT', 0)       end
      end
  
    -- set children states 
      if EXT.CONF_onadd_newchild_trackheightflags &4==4 or  EXT.CONF_onadd_newchild_trackheightflags &8==8 then 
        for note in pairs(DATA.children) do
          local tr = DATA.children[note].tr_ptr
          if not anytr then anytr = tr end
          -- device
          if tr then 
            if EXT.CONF_onadd_newchild_trackheightflags &8==8 and GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER') == 1 then SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 0 ) upd=true end
            if EXT.CONF_onadd_newchild_trackheightflags &4==4 and GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP') == 1 then SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP', 0 ) upd=true end  
          end
          -- children
          for layer = 1, #DATA.children[note].layers do 
            local tr = DATA.children[note].layers[layer].tr_ptr
            if tr then 
              if EXT.CONF_onadd_newchild_trackheightflags &8==8 and GetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER') == 1 then SetMediaTrackInfo_Value( tr, 'B_SHOWINMIXER', 0 ) upd=true end
              if EXT.CONF_onadd_newchild_trackheightflags &4==4 and GetMediaTrackInfo_Value( tr, 'B_SHOWINTCP') == 1 then SetMediaTrackInfo_Value( tr, 'B_SHOWINTCP', 0 ) upd=true end  
            end
          end
        end
      end
      
    -- refresh stuff 
      if upd==true then 
        TrackList_AdjustWindows( false )  
        reaper.UpdateTimeline()
        reaper.UpdateArrange()
      end
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
    
      -- input seq edit handler
        if DATA.seq_functionscall == true then 
          if DATA.temp_lasttrigsend_init and (not DATA.temp_lasttrigsend or (DATA.temp_lasttrigsend and time_precise() - DATA.temp_lasttrigsend>0.5) ) then
            DATA.temp_lasttrigsend = time_precise()
            gmem_write(1029,playingnote ) -- push a trigger to step seq
          end
          DATA.temp_lasttrigsend_init = true
        end
        
      if (DATA.lastMIDIinputnote and DATA.lastMIDIinputnote ~= playingnote) then triggernote = true  end
      DATA.lastMIDIinputnote = playingnote 
    end--{retval=retval, rawmsg=rawmsg, tsval=tsval, devIdx=devIdx, projPos=projPos, projLoopCnt=projLoopCnt,playingnote = rawmsg:byte(2) } 

    
    if triggernote == true then 
      if  EXT.UI_incomingnoteselectpad == 1 and DATA.parent_track and DATA.parent_track.ext then
        if EXT.CONF_seq_sendsysextoLP ~= 1 then
          DATA.parent_track.ext.PARENT_LASTACTIVENOTE = DATA.lastMIDIinputnote
          DATA:WriteData_Parent() --trigger write parent at script initialization // false storing last touched note to ext state
          DATA.upd = true
        end
      end
    end
    
  end
  --------------------------------------------------------------------------------
  function DATA:CollectData_Always()
    
    DATA.mainstate_manager = gmem_read(1026) == 1
    DATA.mainstate_seq = gmem_read(1027) == 1
    
    DATA:CollectData_Always_RecentEvent()
    DATA:CollectData_Always_ExtActions() 
    DATA:CollectData_Always_Peaks() 
    DATA:CollectData_Always_StepPositions()
    --DATA:CollectData_Always_LaunchPadInteraction()
    
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
    local refreshSEQ = gmem_read(1030)
    if DATA.seq_functionscall == true and refreshSEQ == 1 then 
      DATA.upd = true
      DATA.seq.valid = false
      gmem_write(1030,0 )
    end
    
    local actions = gmem_read(1025)
    if actions == 0 then return end
    if DATA.seq_functionscall == true then  
      -- sequencer
      if actions == 11 then 
        DATA.upd = true 
        gmem_write(1025,0 )
      end 
      return -- restrict ext actions for sequencer  
     else
     
      -- rack
      if actions == 10 then 
        DATA.upd = true 
        gmem_write(1025,0 )  
      end 
    end 
    ---------------------------------------------------------- rack 
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
    
    gmem_write(1025,0 ) -- clear to prevent infinite update
    
    
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
    if not (note_layer_t and note_layer_t.ISRS5K) then return end
    
   
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
    DATA.Launchpad_output = false
    DATA.MIDI_inputs = {[63]='All inputs',[62]='Virtual keyboard'}
    for dev = 1, reaper.GetNumMIDIInputs() do
      local retval, nameout = reaper.GetMIDIInputName( dev-1, '' )
      if retval then DATA.MIDI_inputs[dev-1] = nameout end
    end
    
    DATA.MIDI_outputs = {[-1]='[none]'}
    for dev = 1, reaper.GetNumMIDIOutputs() do
      local retval, nameout = reaper.GetMIDIOutputName( dev-1, '' )
      if retval then DATA.MIDI_outputs[dev-1] = nameout end
      
      if EXT.CONF_midioutput == dev-1 and 
        
        (
          nameout:lower():match('lpmini') or
          nameout:lower():match('lppro')
        )
       then
        
        DATA.Launchpad_output = true
      end
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
          PARENT_PADNAMES_OVERRIDES_b64 = ''
        }
        
        
        
        
        
        
      if EXT.UI_drracklayout == 2 then DATA.parent_track.ext.PARENT_DRRACKSHIFT = 11 end
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
      local ret, PARENT_PADNAMES_OVERRIDES_b64 = GetSetMediaTrackInfo_String ( parent_track, 'P_EXT:MPLRS5KMAN_PARENT_PADNAMES_OVERRIDES_b64', 0, false) 
      DATA.parent_track.padcustomnames_overrides = {}
      if PARENT_PADNAMES_OVERRIDES_b64~='' then
        local str = VF_decBase64(PARENT_PADNAMES_OVERRIDES_b64)
        for pair in str:gmatch('[%d]+%=".-"') do
          local id, val = pair:match('([%d]+)="(.-)%"')
          if id and val then 
            id = tonumber(id)
            if id then  DATA.parent_track.padcustomnames_overrides[id] = val end
          end
        end
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
 
        
      -- get track data
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
        local sends = {}
        local cntsends = GetTrackNumSends( track, 0 )
        for sendidx = 1, cntsends do 
          local sD_VOL = GetTrackSendInfo_Value( track, 0, sendidx-1, 'D_VOL' )
          local sD_PAN = GetTrackSendInfo_Value( track, 0, sendidx-1, 'D_PAN' )
          local P_DESTTRACK = GetTrackSendInfo_Value( track, 0, sendidx-1, 'P_DESTTRACK' )
          local ret, P_DESTTRACKname = GetTrackName(P_DESTTRACK)
          local P_DESTTRACKGUID = GetTrackGUID(P_DESTTRACK)
          sends[sendidx] ={
            D_VOL=sD_VOL,
            D_PAN=sD_PAN,
            P_DESTTRACK=P_DESTTRACK,
            P_DESTTRACKname=P_DESTTRACKname,
            P_DESTTRACKGUID=P_DESTTRACKGUID,
            
            }
        end
        
        
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
          sends=sends,
        } end 
      
      -- SYSHANDLER
        if DATA.children[note].SYSEXHANDLER_isvalid~=true then 
          local SYSHANDLER_ID = TrackFX_AddByName(track, 'sysex_handler', false, 0 )
          if SYSHANDLER_ID ~= -1 then
            DATA.children[note].SYSEXHANDLER_isvalid = true
            DATA.children[note].SYSEXHANDLER_ID = SYSHANDLER_ID
          end
          local ret, SYSEXMOD =          GetSetMediaTrackInfo_String   ( track, 'P_EXT:MPLRS5KMAN_SYSEXMOD', 0, false) SYSEXMOD = (tonumber(SYSEXMOD) or 0)==1
          DATA.children[note].SYSEXMOD = SYSEXMOD
        end
        
                
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
                                              sends=sends,
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
          DATA.children[note].sends = sends
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
    local I_RECMON = GetMediaTrackInfo_Value( track, 'I_RECMON')
    
    
    DATA.MIDIbus = {  tr_ptr = track, 
                      IP_TRACKNUMBER_0based = IP_TRACKNUMBER_0based,
                      valid = true,
                      I_FOLDERDEPTH = I_FOLDERDEPTH,
                      I_RECMON = I_RECMON,
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
 ------------------------------------------------------------------------------------------ 
 function DATA:Layout_Init(ID, fill_unexistent)  
   local defaults = {
       cell_cnt_max=64,
       startnote = 36,
       blockX = 4,
       toptobottom = 0,
       row_cnt = 8,
       col_cnt = 8,
       
     }
     
   if not fill_unexistent then 
     DATA.custom_layouts[ID] = CopyTable(defaults)
    else
     if not DATA.custom_layouts[ID] then DATA.custom_layouts[ID] = {} end
     for key in pairs(defaults) do
       if not DATA.custom_layouts[ID][key] then DATA.custom_layouts[ID][key] = defaults[key] end
     end
   end
   
 end
  ------------------------------------------------------------------------------------------ 
  function DATA:CollectDataInit_LoadCustomLayouts()  
    local s_b64 = EXT.UI_drracklayout_custommapB64
    DATA.custom_layouts = table.loadstring(s_b64) or {}
    local ID = EXT.UI_drracklayout_customID
    if not DATA.custom_layouts[ID]  then DATA:Layout_Init(ID) end
    DATA:Layout_Init(ID, true)
    
  end
  ------------------------------------------------------------------------------------------ 
  function DATA:Layout_SaveCustomLayouts()  
    EXT.UI_drracklayout_custommapB64 = table.savestring(DATA.custom_layouts ) or ""
    EXT:save()
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
      if DATA.parent_track.padcustomnames_overrides then 
        --DATA.parent_track.padcustomnames_overrides[selected_pad] = buf
        local outstr = ''
        for i = 0, 127 do outstr=outstr..i..'='..'"'..(DATA.parent_track.padcustomnames_overrides[i] or '')..'" ' end
        local PARENT_PADNAMES_OVERRIDES_b64 = VF_encBase64(outstr)
        GetSetMediaTrackInfo_String ( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN_PARENT_PADNAMES_OVERRIDES_b64', PARENT_PADNAMES_OVERRIDES_b64, true) 
      end
    end 
    
    -- clear string
    GetSetMediaTrackInfo_String( DATA.parent_track.ptr, 'P_EXT:MPLRS5KMAN', '', true) 
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
      if t.SET_SYSEXMOD then GetSetMediaTrackInfo_String( tr, 'P_EXT:MPLRS5KMAN_SYSEXMOD', t.SET_SYSEXMOD, true) end  
      
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
  function DATA:Drop_Pad(src_pad0,dest_pad0)
    if not src_pad0 and dest_pad0 then return end
    src_pad,dest_pad = tonumber(src_pad0),tonumber(dest_pad0)
    if not src_pad and dest_pad then return end
    
    if not DATA.paddrop_mode then 
      DATA:Drop_Pad_Swap(src_pad,dest_pad)  
     elseif DATA.paddrop_mode == 1 
      and DATA.children[src_pad] 
      and not DATA.children[dest_pad] 
      and DATA.children[src_pad].layers
      and #DATA.children[src_pad].layers==1
      and DATA.children[src_pad].layers[1] 
      and DATA.children[src_pad].layers[1].instrument_filename  then -- copy stuff to dest pad if it is free
      local filename = DATA.children[src_pad].layers[1].instrument_filename
      local drop_data = {
        layer = 1, 
        EOFFS = DATA.children[src_pad].layers[1].instrument_sampleendoffs,
        SOFFS = DATA.children[src_pad].layers[1].instrument_samplestoffs,
      }
      DATA:DropSample(filename, dest_pad0, drop_data)
      DATA.paddrop_mode = nil
    end
    DATA:_Seq_RefreshStepSeq()
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
    if EXT.CONF_midioutput ~= -1 then SetMediaTrackInfo_Value( MIDI_tr, 'I_MIDIHWOUT', EXT.CONF_midioutput<<5) end -- MIDI hardware output
    
    
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
    
    --[[ add midi note filter
    local fxname = 'JS: midi/midi_note_filter'
    local filtID = TrackFX_AddByName( MIDI_tr, fxname, true, -1 )
    if filtID&0xF000000~=0x1000000 then filtID = filtID|0x1000000  end
    TrackFX_SetOpen( MIDI_tr, filtID, false )
    TrackFX_SetParam( MIDI_tr, filtID, 0, 0 )
    TrackFX_SetParam( MIDI_tr, filtID, 1, 127 )
    TrackFX_SetParam( MIDI_tr, filtID, 2, 0 )]]
    
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
    local oldnote_t 
    local old_note = note_layer_t.noteID
    if old_note and DATA.children[old_note] then oldnote_t = DATA.children[old_note] end
    
    
    local tr = note_layer_t.tr_ptr
    local instrument_pos = note_layer_t.instrument_pos
    local midifilt_pos = note_layer_t.midifilt_pos
    if not note then return end
    if not midifilt_pos  then 
      if not (oldnote_t and oldnote_t.SYSEXMOD == true) then
        TrackFX_SetParamNormalized( tr, instrument_pos, 3, note/127 ) -- note range start
        TrackFX_SetParamNormalized( tr, instrument_pos, 4, note/127 ) -- note range end
      end
     else 
      TrackFX_SetParamNormalized( tr, midifilt_pos, 0, note/128)
      TrackFX_SetParamNormalized( tr, midifilt_pos, 1, note/128)
    end
    
    if oldnote_t and oldnote_t.SYSEXHANDLER_ID then 
      TrackFX_SetParam( oldnote_t.tr_ptr, oldnote_t.SYSEXHANDLER_ID, 0, note ) -- set new note
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
    DATA:_Seq_RefreshStepSeq()
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
    
    -- validate instrument_noteoff
    local instrument_noteoff
    if DATA.children[note] and DATA.children[note].layers and DATA.children[note].layers[layer or 1] and DATA.children[note].layers[layer or 1].instrument_noteoff then instrument_noteoff = DATA.children[note].layers[layer or 1].instrument_noteoff end 
    if instrument_noteoff then 
      if not drop_data.srct then drop_data.srct = {} end
      drop_data.srct.instrument_noteoff = instrument_noteoff
    end
    
    DATA:DropSample_ExportToRS5k(track, instrument_pos, filename, note, drop_data) 
    DATA.autoreposition = true
    
    DATA:_Seq_RefreshStepSeq()
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
      
      local temp_t = {
        tr_ptr = track,
        instrument_pos = instrument_pos
      }
      
      
      TrackFX_SetParamNormalized( track, instrument_pos, 2, 0) -- gain for min vel 
      TrackFX_SetParamNormalized( track, instrument_pos, 8, 0 ) -- max voices = 0
      
      local obeynoteoff = EXT.CONF_onadd_obeynoteoff if drop_data and drop_data.srct and drop_data.srct.instrument_noteoff then obeynoteoff = drop_data.srct.instrument_noteoff end
      TrackFX_SetParamNormalized( track, instrument_pos, 11, obeynoteoff) -- obey note offs
      
      -- ADSR
      
      local attack =    math.min(2,EXT.CONF_onadd_ADSR_A)       if EXT.CONF_onadd_ADSR_flags&1==1 then TrackFX_SetParamNormalized( track, instrument_pos, 9, attack )  end
      local decay_sec = math.min(15,EXT.CONF_onadd_ADSR_D-0.01)/15   if EXT.CONF_onadd_ADSR_flags&2==2 then TrackFX_SetParamNormalized( track, instrument_pos, 24, decay_sec )  end
      local sustain=    math.min(2,EXT.CONF_onadd_ADSR_S)       if EXT.CONF_onadd_ADSR_flags&4==4 then TrackFX_SetParamNormalized( track, instrument_pos, 25, sustain )  end
      local release =   math.min(2,EXT.CONF_onadd_ADSR_R)       if EXT.CONF_onadd_ADSR_flags&8==8 then TrackFX_SetParamNormalized( track, instrument_pos, 10, release )  end
      
      
    
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
    -- set DB
    if drop_data.set_DB then 
      DATA:WriteData_Child(track, {
        SET_useDB = 1,
        SET_useDB_name = drop_data.set_DB})  
    end
    
    
    if EXT.CONF_onadd_sysexmode == 1 then DATA:Action_RS5k_SYSEXMOD_ON(note, true, track, instrument_pos)end
    
    TrackFX_SetNamedConfigParm( track, instrument_pos, 'MODE',1 ) -- 
    DATA:DropSample_ExportToRS5kSetNoteRange(temp_t, note) 
    
    local SYSEXMOD = DATA.children[note] and DATA.children[note].SYSEXMOD == true
    if SYSEXMOD == true then 
      TrackFX_SetParamNormalized( track, instrument_pos, 3,0 ) -- note start
      TrackFX_SetParamNormalized( track, instrument_pos, 4, 1 ) -- note end
      TrackFX_SetParamNormalized( track, instrument_pos, 5, 0.5 ) -- pitch for start
      TrackFX_SetParamNormalized( track, instrument_pos, 6, 0.5 ) -- pitch for end
      TrackFX_SetNamedConfigParm( track, instrument_pos, 'MODE', 0 ) -- turn sample into freely configurable mode
    end
  end  
  -----------------------------------------------------------------------  
  function DATA:DropSample_RenameTrack(track,note,filename,drop_data) 
    if EXT.CONF_onadd_renametrack~=1 then return end
    local outname = '' 
    if DATA.padcustomnames and DATA.padcustomnames[note] and DATA.padcustomnames[note] ~='' then outname = DATA.padcustomnames[note] end
    if outname == '' and filename then
      local filename_sh = VF_GetShortSmplName(filename)
      if filename_sh and filename_sh:match('(.*)%.[%a]+') then filename_sh = filename_sh:match('(.*)%.[%a]+') end -- remove extension
      if drop_data and drop_data.tr_name_add and filename_sh then filename_sh = filename_sh .. ' '..drop_data.tr_name_add end
      outname = filename_sh
    end
    if outname then
      GetSetMediaTrackInfo_String( track, 'P_NAME', outname, true )
    end
  end
  --------------------------------------------------------------------------------  
  function DATA:Action_ExplodeTake_sub_readparent(take)
    local MIDIdata = {}
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    local MIDIlen = MIDIstring:len()
    local stringPos = 1
    local offset, flags, msg1
    local ppq_pos = 0
    local sysex_handler = {}
    while stringPos < MIDIlen do
      offset, flags, msg1, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos) 
      ppq_pos = ppq_pos + offset
      
      
      local validsysex = msg1:len()>3 and msg1:byte(1)==0xF0 and msg1:byte(2)==0x60 and msg1:byte(3)==0x01
      local CC = msg1:len()==3 and msg1:byte(1)&0xF0==0xB0
      local noteON = msg1:len()==3 and msg1:byte(1)&0xF0==0x90
      local noteOFF = msg1:len()==3 and msg1:byte(1)&0xF0==0x80
      
      local active_note = msg1:byte(2)
      if not active_note then goto skipmsg end
      if validsysex == true then active_note = msg1:byte(4) end 
      if CC == true and active_note == 123 then active_note = 'AllNotesOFF' end
       
      if not MIDIdata[active_note] then MIDIdata[active_note] = {} end
      local id = #MIDIdata[active_note] + 1 
      MIDIdata[active_note][id] = 
        {
          ppq_pos=ppq_pos,
          msg1=msg1,
          flags=flags
        }
        
      if sysex_handler [active_note] then 
        MIDIdata[active_note][id].meta = CopyTable(sysex_handler [active_note]) 
        sysex_handler [active_note] = nil
      end
      
      ::skipmsg::
    end
      
    return MIDIdata
  end
--------------------------------------------------------------------------------  
  function DATA:Action_ExplodeTake_sub_writechildren(item, take, MIDIdata)
    -- get boundary
      local D_POSITION = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local D_LENGTH = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local B_LOOPSRC = GetMediaItemInfo_Value( item, 'B_LOOPSRC' ) 
      local D_STARTOFFS = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
      local D_PLAYRATE = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
      local I_CUSTOMCOLOR = GetMediaItemTakeInfo_Value( take, 'I_CUSTOMCOLOR' )
      local pcmsrc = GetMediaItemTake_Source( take )
      local srclen, lengthIsQN = reaper.GetMediaSourceLength( pcmsrc )
      
      
    for note in pairs(MIDIdata) do
      if note and DATA.children[note] then
        local track = DATA.children[note].tr_ptr
        local SYSEXMOD = DATA.children[note].SYSEXMOD
        if DATA.children[note].SYSEXHANDLER_ID and DATA.children[note].SYSEXHANDLER_isvalid==true then TrackFX_SetEnabled( track, DATA.children[note].SYSEXHANDLER_ID, false ) end
        if DATA.children[note].layers and DATA.children[note].layers[1] and DATA.children[note].layers[1].midifilt_pos then TrackFX_SetEnabled( DATA.children[note].layers[1].tr_ptr, DATA.children[note].layers[1].midifilt_pos, false ) end 
        if track then
        
          local new_item = CreateNewMIDIItemInProj( track, D_POSITION, D_POSITION + D_LENGTH )
          local childtake = GetActiveTake(new_item)
          SetMediaItemTakeInfo_Value( childtake, 'D_STARTOFFS',D_STARTOFFS )
          SetMediaItemTakeInfo_Value( childtake, 'D_PLAYRATE',D_PLAYRATE ) 
          SetMediaItemTakeInfo_Value( childtake, 'I_CUSTOMCOLOR',I_CUSTOMCOLOR ) 
          SetMediaItemInfo_Value( new_item, 'B_LOOPSRC',B_LOOPSRC )
          
          -- add events
          local MIDIstring = ""
          local offset = 0
          local ppq_pos_last = 0
          for i = 1, #MIDIdata[note] do 
            local ppq_pos = MIDIdata[note][i].ppq_pos
            offset = ppq_pos - ppq_pos_last
            MIDIstring = MIDIstring..string.pack("i4Bs4",offset, MIDIdata[note][i].flags, MIDIdata[note][i].msg1)
            ppq_pos_last = ppq_pos 
            ::nextevent::
          end
          
          -- add all note off
          AllNotesOFF_t = MIDIdata['AllNotesOFF'][1]
          local ppq_pos = AllNotesOFF_t.ppq_pos
          offset = ppq_pos - ppq_pos_last
          MIDIstring = MIDIstring..string.pack("i4Bs4",offset, 0, AllNotesOFF_t.msg1)
          MIDI_SetAllEvts(childtake, MIDIstring)
          MIDI_Sort(childtake)
          
          if SYSEXMOD == true then DATA:Action_ExplodeTake_sub_sysexhandler(childtake) end
        end
      end
    end
    
    
  end
  --------------------------------------------------------------------------------  
  function DATA:Action_ExplodeTake_sub_sysexhandler(take)
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    local MIDIlen = MIDIstring:len()
    local stringPos = 1
    local offset, flags, msg1
    local ppq_pos = 0
    local sysex_handler = {}
    local MIDIstring_out = ''
    
    local pitch_correction = 0; 
    local val_rand = 0;
    local probability = 1; 
    
    while stringPos < MIDIlen do
      offset, flags, msg1, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos) 
      
      --// received sysex is F0 60 01 ...some_parameters.. F7
      if msg1:len() > 3 and msg1:byte(1)==0xF0 and msg1:byte(2)==0x60 and msg1:byte(3)==0x01 then 
        pitch_correction = msg1:byte(5);
        probability = msg1:byte(6)/127; 
        MIDIstring_out = MIDIstring_out..string.pack("i4Bs4", offset, 0, '') -- clear / preserve offset 
          
          
      --// note ON        
       elseif msg1:len() == 3 and msg1:byte(1)==0x90 then
        outpitch = 64;
        if pitch_correction ~= 0 then outpitch = pitch_correction end;
        MIDIstring_out = MIDIstring_out..string.pack("i4BI4BBB", offset, flags, 3, 
          msg1:byte(1),
          outpitch,
          msg1:byte(3))
          
      --// note OFF        
       elseif msg1:len() == 3 and msg1:byte(1)==0x80 then    
        outpitch = 64;
        if pitch_correction ~= 0 then outpitch = pitch_correction end;
        MIDIstring_out = MIDIstring_out..string.pack("i4BI4BBB", offset, flags, 3, 
          msg1:byte(1),
          outpitch,
          msg1:byte(3))
       elseif msg1:len() == 3 and msg1:byte(1)==0xB0 then    
        MIDIstring_out = MIDIstring_out..string.pack("i4BI4BBB", offset, flags, 3, 
          msg1:byte(1),
          msg1:byte(2),
          msg1:byte(3))          
      end
    end
    MIDI_SetAllEvts(take, MIDIstring_out)
    MIDI_Sort(take)
    
    
    --[[
    
    local outpitch = note
    if SYSEXMOD == true then 
      outpitch = 64 
      if tableEvents[i].meta and tableEvents[i].meta.pitchcorection then outpitch  = tableEvents[i].meta.pitchcorection end
    end
    
    
    activenote = msg1:byte(4)
    pitchcorection = msg1:byte(5)
    if pitchcorection == 0 then pitchcorection = 64 end
    probability = msg1:byte(6)
    meta[activenote]={
        pitchcorection=pitchcorection,
        probability=probability
      }]]
  end
  --------------------------------------------------------------------------------  
  function DATA:Action_ExplodeTake_sub(item)
    if not item then return end
    local take = GetActiveTake(item)
    if not (take and reaper.TakeIsMIDI(take)) then return end
    MIDI_Sort(take)
    MIDIdata = DATA:Action_ExplodeTake_sub_readparent(take)
    if not MIDIdata then return end
    DATA:Action_ExplodeTake_sub_writechildren(item, take, MIDIdata) 
    
    -- mute item
    SetMediaItemInfo_Value( item, 'B_MUTE', 1 )
  end
--------------------------------------------------------------------------------  
  function DATA:Action_ExplodeTake()
    Undo_BeginBlock2(DATA.proj)
    for i = 1, reaper.CountSelectedMediaItems(DATA.proj) do
      local item = GetSelectedMediaItem(DATA.proj, i-1)
      DATA:Action_ExplodeTake_sub(item)
    end
    Undo_EndBlock2(DATA.proj, 'Explode MIDI bus take by note', 0xFFFFFFFF)
  end
  --[[
  
  --------------------------------------------------------------------------------  
    function DATA:Action_ExplodeTake_old01062025()
      Undo_BeginBlock2(DATA.proj)
      for i = 1, reaper.CountSelectedMediaItems(DATA.proj) do
        local item = GetSelectedMediaItem(DATA.proj, i-1)
        if not item then goto nextitem end
        local take = GetActiveTake(item)
        if not (take and reaper.TakeIsMIDI(take)) then goto nextitem end
        
        MIDI_Sort(take)
        
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
        local meta = {}
        local ppq_pos = 0
        while stringPos < MIDIlen do
          offset, flags, msg1, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos) 
          ppq_pos = ppq_pos + offset
          if msg1:len()>3 and msg1:byte(1)==0xF0 and msg1:byte(2)==0x60 and msg1:byte(3)==0x01 then
            activenote = msg1:byte(4)
            pitchcorection = msg1:byte(5)
            if pitchcorection == 0 then pitchcorection = 64 end
            probability = msg1:byte(6)
            meta={
              pitchcorection=pitchcorection,
              probability=probability
              }
            tableEvents[#tableEvents+1] = {
              offset=offset,
              flags=flags,
              msg1='',
            }
            goto nextevt
          end
              
          local pitch = msg1:byte(2) 
          tableEvents[#tableEvents+1] = {
            offset=offset,
            flags=flags,
            msg1=msg1,
            tp= string.format("%x", msg1:byte(1)),
            meta=CopyTable(meta),
          }
          meta=nil
          t_pitch[pitch]=true 
          
          ::nextevt::
        end
        
        
        for note in pairs(t_pitch) do
          if note and DATA.children[note] then
            local track = DATA.children[note].tr_ptr
            local SYSEXMOD = DATA.children[note].SYSEXMOD
            if DATA.children[note].SYSEXHANDLER_ID and DATA.children[note].SYSEXHANDLER_isvalid==true then TrackFX_SetEnabled( track, DATA.children[note].SYSEXHANDLER_ID, false ) end
            if DATA.children[note].layers and DATA.children[note].layers[1] and DATA.children[note].layers[1].midifilt_pos then TrackFX_SetEnabled( DATA.children[note].layers[1].tr_ptr, DATA.children[note].layers[1].midifilt_pos, false ) end 
            if track then
              local new_item = CreateNewMIDIItemInProj( track, D_POSITION, D_POSITION + D_LENGTH )
              local childtake = GetActiveTake(new_item)
              SetMediaItemTakeInfo_Value( childtake, 'D_STARTOFFS',D_STARTOFFS )
              SetMediaItemTakeInfo_Value( childtake, 'D_PLAYRATE',D_PLAYRATE ) 
              SetMediaItemTakeInfo_Value( childtake, 'I_CUSTOMCOLOR',I_CUSTOMCOLOR ) 
              SetMediaItemInfo_Value( new_item, 'B_LOOPSRC',B_LOOPSRC )  
              local MIDIstring = ""
              for i = 1, #tableEvents-1 do
                
                
                
                
                if msg1:byte(2) ~= note then MIDIstring = MIDIstring..string.pack("i4Bs4", tableEvents[i].offset, tableEvents[i].flags, '') goto nextevent end  
                
                if tableEvents[i].meta and tableEvents[i].meta.pitchcorection  then
                  test = tableEvents[i].meta
                  MIDIstring = MIDIstring..string.pack("i4BI4BBB", tableEvents[i].offset, tableEvents[i].flags, 3, 
                    tableEvents[i].msg1:byte(1),
                    tableEvents[i].meta.pitchcorection,
                    tableEvents[i].msg1:byte(3))
                 else
                  if SYSEXMOD == true then -- alway print 64
                    MIDIstring = MIDIstring..string.pack("i4BI4BBB", tableEvents[i].offset, tableEvents[i].flags, 3, 
                      tableEvents[i].msg1:byte(1),
                      64,
                      tableEvents[i].msg1:byte(3))
                   else
                    MIDIstring = MIDIstring..string.pack("i4Bs4", tableEvents[i].offset, tableEvents[i].flags, tableEvents[i].msg1)
                  end
                end
                
                
                ::nextevent::
              end
              MIDIstring = MIDIstring..string.pack("i4Bs4", tableEvents[#tableEvents].offset, tableEvents[#tableEvents].flags, tableEvents[#tableEvents].msg1)
              MIDI_SetAllEvts(childtake, MIDIstring)
              MIDI_Sort(childtake)
            end
          end
        end
        
        ::nextitem::
      end
      Undo_EndBlock2(DATA.proj, 'Explode MIDI bus take by note', 0xFFFFFFFF)
    end
    ]]
--------------------------------------------------------------------------------  
  function DATA:Database_Load(sel_pad_only)
    if not EXT.UIdatabase_maps_current then return end
    if not DATA.reaperDB then return end
    local mapID = EXT.UIdatabase_maps_current
    if not (DATA.database_maps[mapID] and DATA.database_maps[mapID].map) then return end
    
    for note in spairs(DATA.database_maps[mapID].map) do
      if not sel_pad_only or (sel_pad_only == true and DATA.parent_track.ext.PARENT_LASTACTIVENOTE and note == DATA.parent_track.ext.PARENT_LASTACTIVENOTE) then
      
        local dbname = DATA.database_maps[mapID].map[note].dbname
        if DATA.reaperDB[dbname] and DATA.reaperDB[dbname].files then
          local sz = #DATA.reaperDB[dbname].files
          if sz>0 then
            local rand_fid = 1 + math.floor(math.random(sz-1))
            local fp = DATA.reaperDB[dbname].files[rand_fid].fp
            DATA:DropSample(fp, note, {set_DB = dbname})
          end
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
  
  --------------------------------------------------------------------------------  
  function DATA:CollectDataInit_EnumeratePlugins()
    local plugs_data = {
      types = {},
      vendors = {},
    } 
    for i = 1, 10000 do
      local retval, name, ident = reaper.EnumInstalledFX( i-1 )
      if not retval then break end
      if name:match('i%:') then
        local checkname=name
          :gsub('%(x64%)','')
          :gsub('%(x86%)','')
        local vendor = checkname:match('%((.-)%)')
        if not vendor or (vendor and vendor == '')then vendor = '[unknown]'end
        fxtype = name:match('(.-)%:') or 'Other'
        plugs_data.types[fxtype]=(plugs_data.types[fxtype] or 0) + 1
        plugs_data.vendors[vendor]=(plugs_data.vendors[vendor] or 0) + 1
        
        plugs_data[#plugs_data+1] = {name = name, 
                                     reduced_name = VF_ReduceFXname(name) ,
                                     ident = ident,
                                     vendor=vendor,
                                     fxtype=fxtype,
                                     }
  
      end                                   
    end
    DATA.installed_plugins = plugs_data
  end
  -------------------------------------------------------------------------------- 
  function UI.draw_3rdpartyimport_context_add(buf, note, drop_data) 
    local track = GetMasterTrack(-1) 
    local fxidx = TrackFX_AddByName( track, buf, false, -1 )
    if fxidx ~= -1 then
      local retval, fx_namesrc = reaper.TrackFX_GetNamedConfigParm( track, fxidx, 'fx_name' )
      local fx_name = VF_ReduceFXname(fx_namesrc)
      DATA:DropFX(fx_namesrc, fx_name, fxidx, track, note, drop_data)
      ImGui.CloseCurrentPopup(ctx)
    end
  end
    -------------------------------------------------------------------------------- 
  function UI.draw_3rdpartyimport_context(note,drop_data) 
    --[[local retval, trackidx, itemidx, takeidx, fxidx, parm = GetTouchedOrFocusedFX( 0 )
    local track = GetTrack(-1,trackidx) if  trackidx == -1 then track = GetMasterTrack(-1) end
    local retval, fx_namesrc = reaper.TrackFX_GetNamedConfigParm( track, fxidx, 'fx_name' )
    local is_instrument = (fx_namesrc:match('[%a]+i%:.*') or fx_namesrc:lower():match('synth')) and not (fx_namesrc: match('ReaSampl')or fx_namesrc:match('Macro'))
    local fx_name = VF_ReduceFXname(fx_namesrc)
    if retval and fx_name and is_instrument then
      if ImGui.Button(ctx, fx_name,-1)then-- then--'Import ['..fx_name..'] as instrument'
        DATA:DropFX(fx_namesrc, fx_name, fxidx, track, note, drop_data)
        ImGui.CloseCurrentPopup(ctx) 
      end   
     else
      ImGui.BeginDisabled(ctx,true) ImGui.Button(ctx, 'Import last touched FX as instrument',-1)ImGui.EndDisabled(ctx)
    end]]
    
    ImGui.SetNextItemWidth( ctx,-100)
    
    
    if ImGui.BeginMenu( ctx, 'Import 3rd party plugin', true ) then
      
      local cnt_com = #DATA.installed_plugins
      
      -- by type
      reaper.ImGui_SeparatorText(ctx, 'By type')
      for typestr in spairs(DATA.installed_plugins.types) do
        local cnt = DATA.installed_plugins.types[typestr]
        if ImGui.BeginMenu( ctx, typestr..' ('..cnt..')', true ) then 
          for i = 1, cnt_com do
            if DATA.installed_plugins[i].fxtype == typestr then 
              local name = DATA.installed_plugins[i].name or 'untitled'
              if name:match('%:(.*)') then name = name:match('%:(.*)') end
              local retval, p_selected = reaper.ImGui_MenuItem( ctx, name..'##plug'..i..typestr )
              if retval then UI.draw_3rdpartyimport_context_add(DATA.installed_plugins[i].name, note, drop_data)  end
            end
          end
          ImGui.EndMenu( ctx)
        end
      end
      
      -- by vendor
      reaper.ImGui_SeparatorText(ctx, 'By vendor')
      for vendorstr in spairs(DATA.installed_plugins.vendors) do
        local cnt = DATA.installed_plugins.vendors[vendorstr]
        if ImGui.BeginMenu( ctx, vendorstr..' ('..cnt..')', true ) then 
          for i = 1, cnt_com do
            if DATA.installed_plugins[i].vendor == vendorstr then 
              local name = DATA.installed_plugins[i].name or 'untitled'
              local retval, p_selected = reaper.ImGui_MenuItem( ctx, name..'##plug'..i..vendorstr )
              if retval then UI.draw_3rdpartyimport_context_add(DATA.installed_plugins[i].name, note, drop_data)  end
            end
          end
          ImGui.EndMenu( ctx)
        end
      end
      
      -- enter
      reaper.ImGui_SeparatorText(ctx, 'By entered name')
      local retval, buf = reaper.ImGui_InputText( ctx, '##fxinput', '', ImGui.InputTextFlags_EnterReturnsTrue )
      if retval then
      
        UI.draw_3rdpartyimport_context_add(buf, note, drop_data) 
        
      end
      
      
      ImGui.EndMenu( ctx)
    end
    
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
      
      DATA:DropSample(
          filename, 
          outnote, 
          {
            layer=1,
            SOFFS=loop_t[i].SOFFS,
            EOFFS=loop_t[i].EOFFS,
            tr_name_add = '- slice '..i,
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
    local str = EXT.UI_padcustomnames
    -- 4.57 patch fixing extstate multiline issue https://forum.cockos.com/showthread.php?t=298318
    local strB64 = EXT.UI_padcustomnamesB64
    if str~='' then
      EXT.UI_padcustomnamesB64 = VF_encBase64(EXT.UI_padcustomnames)
      EXT.UI_padcustomnames = ''
      EXT:save()
     else
      str = VF_decBase64(strB64)
    end
    if str == '' then return end
    for pair in str:gmatch('[%d]+%=".-"') do
      local id, val = pair:match('([%d]+)="(.-)%"')
      if id and val then 
        id = tonumber(id)
        if id then DATA.padcustomnames[id] = val end
      end
    end
    
    DATA.padautocolors = {}
    local str = EXT.UI_padautocolors
    -- 4.57 patch fixing extstate multiline issue https://forum.cockos.com/showthread.php?t=298318
    local strB64 = EXT.UI_padautocolorsB64
    if str~='' then
      EXT.UI_padautocolorsB64 = VF_encBase64(EXT.UI_padautocolors)
      EXT.UI_padautocolors = ''
      EXT:save()
     else
      str = VF_decBase64(strB64)
    end
    
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
      local step_cnt = -1
      if DATA.seq.ext.children[note] and DATA.seq.ext.children[note].step_cnt then step_cnt = DATA.seq.ext.children[note].step_cnt end
      if step_cnt == -1 then step_cnt = DATA.seq.ext.patternlen or EXT.CONF_seq_defaultstepcnt end
      local steplength = EXT.CONF_seq_steplength
      if DATA.seq.ext.children[note] and DATA.seq.ext.children[note].steplength then steplength = DATA.seq.ext.children[note].steplength end
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
    if not DATA.temp_pos_progress_last or (DATA.temp_pos_progress_last and DATA.temp_pos_progress_last ~= DATA.temp_pos_progress) then
      DATA:Launchpad_SendState()
    end
    DATA.temp_pos_progress_last = DATA.temp_pos_progress
  end
 
    --------------------------------------------------------------------------------  
  function VF_Open_URL(url) if GetOS():match("OSX") then os.execute('open "" '.. url) else os.execute('start "" '.. url)  end  end    
  --------------------------------------------------------------------- 
  function DATA:Choke_Read()  
    DATA.MIDIbus.choke_setup = {}
    local ret, midi_choke_Container = DATA:MIDI_Handler_Read() 
    if not ret then return end
    
    
    local tr =  DATA.MIDIbus.tr_ptr 
    local fxcnt = TrackFX_GetCount(tr)
    local retval, container_count = reaper.TrackFX_GetNamedConfigParm( tr, midi_choke_Container, 'container_count' )
    for subitem = 1, container_count do
      local choke_childID = 0x2000000 + subitem*(fxcnt+1) + (midi_choke_Container+1)
      local retval, fxname = reaper.TrackFX_GetNamedConfigParm( tr, choke_childID, 'renamed_name' )
      local dest,src = fxname:match('choke (%d+) by (%d+)')
      if src and tonumber(src) then src = tonumber(src) end
      if dest and tonumber(dest) then dest = tonumber(dest) end
      if dest and src then
        if not DATA.MIDIbus.choke_setup[dest] then DATA.MIDIbus.choke_setup[dest] = {} end 
        local retval, container_itemID = reaper.TrackFX_GetNamedConfigParm( tr, midi_choke_Container, 'container_item.'..(subitem-1) )
        DATA.MIDIbus.choke_setup[dest][src] = {exist = true, container_itemID = tonumber(container_itemID)}
      end
    end
  end  
  --------------------------------------------------------------------- 
  function DATA:MIDI_Handler_Read(allow_to_write)   
    if DATA.allow_container_usage ~= true then return end  
    if not DATA.MIDIbus.tr_ptr then return end 
    local container_name = DATA.MIDIhandler
    local tr =  DATA.MIDIbus.tr_ptr 
    local midi_choke_Container =  TrackFX_AddByName( tr, container_name, false, 0 ) 
    if allow_to_write~= true then 
      if midi_choke_Container == -1 then return end
     else 
      if midi_choke_Container == -1 then 
        midi_choke_Container =  TrackFX_AddByName( tr, 'Container', false, -1000 )
        TrackFX_SetNamedConfigParm( tr, midi_choke_Container, 'renamed_name', container_name )
        TrackFX_SetOpen( tr, midi_choke_Container, false ) 
      end 
      if midi_choke_Container == -1 then return end
    end
    DATA.MIDIbus.midi_choke_Container = midi_choke_Container
    return true, midi_choke_Container
  end  
  --------------------------------------------------------------------- 
  function DATA:Choke_Write()  
    -- get/init container ID
    local ret, midi_choke_Container = DATA:MIDI_Handler_Read(true) 
    if not ret then return end
    
    -- colect for remove 
    local tr =  DATA.MIDIbus.tr_ptr 
    local removeID = {}
    local retval, container_count = reaper.TrackFX_GetNamedConfigParm( tr, midi_choke_Container, 'container_count' )
    for dest in pairs(DATA.MIDIbus.choke_setup) do
      for src in pairs( DATA.MIDIbus.choke_setup[dest]) do
        if DATA.MIDIbus.choke_setup[dest][src].mark_for_remove == true then 
          removeID[DATA.MIDIbus.choke_setup[dest][src].container_itemID] = true
        end
      end
    end
    
    -- mark for add
    local add_FX = {}
    local addcnt = 0
    for dest in pairs(DATA.MIDIbus.choke_setup) do
      for src in pairs( DATA.MIDIbus.choke_setup[dest]) do
        if DATA.MIDIbus.choke_setup[dest][src].add == true then 
          if not add_FX[dest] then add_FX[dest] = {} end
          add_FX[dest][#add_FX[dest]+1] = src
          addcnt=addcnt+1
        end
      end
    end
    
    for fxID in spairs(removeID, function(t,a,b) return b < a end) do
      TrackFX_Delete( tr,fxID )
    end
    
    for dest in pairs(add_FX) do
      for id=1, #add_FX[dest] do
        local src = add_FX[dest][id]
        local choke_ID =  TrackFX_AddByName( tr, 'mpl_RS5K_manager_MIDIBUS_choke', false, -1 )
        local retval, container_count = reaper.TrackFX_GetNamedConfigParm( tr, midi_choke_Container, 'container_count' )
        local subitem = container_count + 1
        local choke_childID_dest = 0x2000000 + subitem*(TrackFX_GetCount(tr)+1) + (midi_choke_Container+1) 
        TrackFX_CopyToTrack( tr, choke_ID, tr, choke_childID_dest, true )
        local choke_childID_dest = 0x2000000 + subitem*(TrackFX_GetCount(tr)+1) + (midi_choke_Container+1) 
        TrackFX_SetOpen( tr, choke_childID_dest, false ) 
        TrackFX_SetNamedConfigParm( tr, choke_childID_dest, 'renamed_name', 'choke '..dest..' by '..src )
        TrackFX_SetParam( tr, choke_childID_dest, 0, src )
        TrackFX_SetParam( tr, choke_childID_dest, 1, dest )
      end
    end
    
    -- set obey note off
    if addcnt > 0 then
      for dest in pairs(add_FX) do DATA:Action_SetObeyNoteOff(dest) end
      DATA.upd = true 
    end
  end    
  --------------------------------------------------------------------- 
  function DATA:Action_SetObeyNoteOff(note)
    local note_t = DATA.children[note]
    if note_t and note_t.layers then
      for layer = 1, #note_t.layers do
        local note_layer_t = note_t.layers[layer]
        local obeynoteoff = TrackFX_GetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 11 )
        if note_layer_t.ISRS5K and obeynoteoff == 0 then TrackFX_SetParamNormalized( note_layer_t.tr_ptr, note_layer_t.instrument_pos, 11, 1 ) end
      end
    end
  end
  --------------------------------------------------------------------- 
  function DATA:MIDI_SysexHandler_fixmultiple(track,fx0)
    -- 4.57 patch
    local cnt = TrackFX_GetCount( track )
    for fx = cnt,1,-1 do
      local retval, buf = reaper.TrackFX_GetNamedConfigParm( track, fx-1, 'renamed_name' )
      if buf == 'sysex_handler' then 
        if fx0 ~= fx-1  then TrackFX_Delete( track, fx-1 ) end
      end
    end
  end
  --------------------------------------------------------------------- 
  function DATA:MIDI_SysexHandler_init(note, drop_tr)   
    local tr
    if not drop_tr then
      if not (DATA.children and DATA.children[note]) then return end
      tr =  DATA.children[note].tr_ptr 
     else 
      tr=drop_tr
    end
    
    if not tr then return end
    local dr_id = -1000
    if drop_tr then dr_id = 0 end
    local sysex_handler =  TrackFX_AddByName( tr, 'RS5K_manager_sysex_handler', false, dr_id )  
    if sysex_handler == -1 then sysex_handler = TrackFX_AddByName( tr, 'sysex_handler', false, 0 ) end
    
    if sysex_handler ~= -1 then  
     elseif dr_id == 0 then
      sysex_handler =  TrackFX_AddByName( tr, 'sysex_handler', false, 0 ) 
      if sysex_handler == -1 then sysex_handler =  TrackFX_AddByName( tr, 'RS5K_manager_sysex_handler', false, -1000 )  end
     else
      return
    end 
    
    if sysex_handler ~= -1 then
      TrackFX_SetNamedConfigParm( tr, sysex_handler, 'renamed_name', 'sysex_handler' )
      TrackFX_SetParam( tr, sysex_handler, 0, note ) -- set note
      TrackFX_SetOpen( tr, sysex_handler, false )  
      DATA:MIDI_SysexHandler_fixmultiple(tr,sysex_handler)
    end
    
    local midifilt_pos = TrackFX_AddByName( tr, 'midi_note_filter', false, 0) 
    if midifilt_pos ~= 0 then reaper.TrackFX_CopyToTrack( tr, midifilt_pos, tr, 0, true ) end
    return true
  end  
  --------------------------------------------------------------------- 
  function DATA:Action_RS5k_SYSEXMOD_ON(note, at_rs5k_drop, drop_tr, drop_rs5kpos)
    if DATA.children[note] then DATA.children[note].SYSEXMOD = true end
    if at_rs5k_drop==true then 
      DATA:WriteData_Child(drop_tr,{SET_SYSEXMOD=1})
      TrackFX_SetNamedConfigParm( drop_tr, drop_rs5kpos, 'MODE', 0 ) -- turn sample into freely configurable mode
      TrackFX_SetParam( drop_tr, drop_rs5kpos, 3, 0 ) -- set note start to 0
      TrackFX_SetParam( drop_tr, drop_rs5kpos, 4, 1 ) -- set note end to 127
      TrackFX_SetParam( drop_tr, drop_rs5kpos, 5, 0.5 - 0.5*64/80 ) -- set pitch start to -64
      TrackFX_SetParam( drop_tr, drop_rs5kpos, 6, 0.5 + 0.5*64/80 ) -- set pitch end to 64
      DATA:MIDI_SysexHandler_init(note, drop_tr) -- add sysex handler to child track
      return
    end
    
    
    Undo_BeginBlock2(-1) 
    local note_t = DATA.children[note]
    if note_t then 
      DATA:WriteData_Child(note_t.tr_ptr,{SET_SYSEXMOD=1})
      note_t.SYSEXHANDLER_isvalid = true 
    end
    if note_t and note_t.layers then
      for layer = 1, #note_t.layers do
        local note_layer_t = note_t.layers[layer]
        if note_layer_t.ISRS5K then 
          local track = note_layer_t.tr_ptr
          local fx = note_layer_t.instrument_pos 
          TrackFX_SetNamedConfigParm( track, fx, 'MODE', 0 ) -- turn sample into freely configurable mode
          TrackFX_SetParam( track, fx, 3, 0 ) -- set note start to 0
          TrackFX_SetParam( track, fx, 4, 1 ) -- set note end to 127
          TrackFX_SetParam( track, fx, 5, 0.5 - 0.5*64/80 ) -- set pitch start to -64
          TrackFX_SetParam( track, fx, 6, 0.5 + 0.5*64/80 ) -- set pitch end to 64
        end
      end
    end
    
    DATA:MIDI_SysexHandler_init(note) -- add sysex handler to child track
    Undo_EndBlock2(-1, 'Convert pad '..note..' to SysEx mode', 0xFFFFFFFF)
    
    
    --DATA.upd = true
    
  end
  --------------------------------------------------------------------- 
  function DATA:Action_RS5k_SYSEXMOD_OFF(note)
    Undo_BeginBlock2(-1) 
    local note_t = DATA.children[note]
    if note_t then DATA:WriteData_Child(note_t.tr_ptr,{SET_SYSEXMOD=0}) end
    
    if note_t and note_t.layers then
      for layer = 1, #note_t.layers do
        local note_layer_t = note_t.layers[layer]
        if note_layer_t.ISRS5K then 
          local track = note_layer_t.tr_ptr
          local fx = note_layer_t.instrument_pos 
          TrackFX_SetNamedConfigParm( track, fx, 'MODE', 1 )
          TrackFX_SetParam( track, fx, 3, note/127 )
          TrackFX_SetParam( track, fx, 4, note/127 ) 
          TrackFX_SetParamNormalized( track, fx, 5, 0.5 ) -- pitch for start
          TrackFX_SetParamNormalized( track, fx, 6, 0.5 ) -- pitch for end
        end
      end
    end
    
    -- remove handler
    local tr =  note_t.tr_ptr 
    local sysex_handler =  TrackFX_AddByName( tr, 'sysex_handler', false, 0 ) 
    if sysex_handler ~= -1 then TrackFX_Delete( tr, sysex_handler ) end
    
    Undo_EndBlock2(-1, 'Convert pad '..note..' to normal mode', 0xFFFFFFFF)
    
  end
  
  --------------------------------------------------------------------------------  
  function UI.VDragInt(ctx, str_id, size_w, size_h, v, v_min, v_max, formatIn, flagsIn, floor, default, image)
    
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,1,1) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding,1, 1) 
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,1, 1)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign,0.5,0.5)
    ImGui.PushFont(ctx, DATA.font4) 
    
    local x,y = reaper.ImGui_GetCursorPos(ctx)
    local v_out
    local dx, dy = reaper.ImGui_GetMouseDelta( ctx )
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize,size_h/2)
    ImGui.PopStyleVar(ctx)
    
    ImGui.InvisibleButton( ctx, str_id, size_w, size_h, reaper.ImGui_ButtonFlags_None() )
    local x1, y1 = reaper.ImGui_GetItemRectMin( ctx )
    local x2, y2 = reaper.ImGui_GetItemRectMax( ctx )
    if reaper.ImGui_IsItemActivated(ctx) then 
      local x, y = reaper.ImGui_GetMousePos( ctx )
      DATA.temp_VDragInt_y = y
      DATA.temp_VDragInt_v = v
      DATA.temp_VDragInt_str_id = str_id
    end
    if reaper.ImGui_IsItemActive(ctx) and DATA.temp_VDragInt_y and DATA.temp_VDragInt_v and DATA.temp_VDragInt_str_id == str_id then
      local x, y = reaper.ImGui_GetMousePos( ctx )
      local dy = DATA.temp_VDragInt_y - y
      v_out = VF_lim(DATA.temp_VDragInt_v + dy/UI.dragY_res,v_min, v_max)
      if floor then v_out = math.floor(v_out) end
    end
    if ImGui.IsItemHovered(ctx) then DATA.temp_ismousewheelcontrol_hovered = true end
    if default and ImGui.IsItemHovered(ctx) and ImGui.IsMouseDoubleClicked(ctx, ImGui.MouseButton_Left) then v_out = default dy = 1 end
    local deact = ImGui.IsItemDeactivated(ctx)
    local rightclick = ImGui.IsItemHovered(ctx) and ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Right)
    local vertical, horizontal = ImGui.GetMouseWheel( ctx )
    local mousewheel = ImGui.IsItemHovered(ctx) and vertical ~= 0
    if mousewheel then mousewheel = math.abs(vertical)/vertical end
      
    ImGui.SetCursorPos(ctx,x,y)
    
    if formatIn then ImGui.Button(ctx, formatIn..str_id..'info',size_w, size_h) end
  
    
    ImGui.PopFont(ctx) 
    ImGui.PopStyleVar(ctx,4)
    
    -- prevent commit when mouse is not moving
    if dy == 0 then return nil, nil,deact,rightclick,mousewheel end 
    if v_out then return  true,v_out,deact,rightclick,mousewheel end
  end
  
  ---------------------------------------------------------------------  
  function UI.Drop_UI_interaction_pad(note) 
    if note == -1 then
      local starting_emptynote = 36
      for i=starting_emptynote,127 do if not DATA.children[i] then 
        note = i 
        DATA.parent_track.ext.PARENT_LASTACTIVENOTE = note
        DATA.temp_scroll_to_note = note
        DATA:WriteData_Parent()
        break 
        end 
      end
    end
    
    -- validate is file or pad dropped
    local retval, count = ImGui.AcceptDragDropPayloadFiles( ctx, 127, ImGui.DragDropFlags_None )
    if retval then 
      DATA.upd2.refreshscroll = 1 --UI.draw_Seq() refresh
      local loop_success
      if count == 1 then loop_success, do_not_share = DATA:Auto_LoopSlice(note, count) end
      
      if do_not_share == true then return end
      
      
      -- import sample directly
      if loop_success ~= true then
      
        Undo_BeginBlock2(DATA.proj )
        for i = 1, count do 
          local retval, filename = reaper.ImGui_GetDragDropPayloadFile( ctx, i-1 )
          if not retval then return end  
          DATA:DropSample(filename, note + i-1, {layer=1})
        end 
        Undo_EndBlock2( DATA.proj , 'RS5k manager - drop samples to pads', 0xFFFFFFFF ) 
      end
        
      
     else
      local retval, payload = reaper.ImGui_AcceptDragDropPayload( ctx, 'moving_pad', '', ImGui.DragDropFlags_None )-- accept pad drop
      if retval and DATA.parent_track.ext.PARENT_LASTACTIVENOTE then 
        Undo_BeginBlock2(DATA.proj )
        local retval, types, payload, is_preview, is_delivery = reaper.ImGui_GetDragDropPayload( ctx )
        if retval and tonumber(payload)then 
          DATA:Drop_Pad(tonumber(payload),note)  
          gmem_write(1026,11|(DATA.parent_track.ext.PARENT_LASTACTIVENOTE<<8)|(note<<16))
        end  
        Undo_EndBlock2( DATA.proj , 'RS5k manager - move pad', 0xFFFFFFFF ) 
      end 
    end
  end
  -------------------------------------------------------------------  
  function DATA:Launchpad_SendState()
    if EXT.CONF_seq_stuffMIDItoLP == 0 then return end
    if not DATA.lp_matrix then return end
    
    
    -- form matrix
      local row = 0
      for note in spairs(DATA.seq.active_step) do
        row = row + 1
        
        if DATA.lp_matrix[row] then for col = 1, 8 do DATA.lp_matrix[row][col].state = 0 end end -- reset row states
        for step = 1, 8 do
          if    DATA.seq 
            and DATA.seq.ext 
            and DATA.seq.ext.children 
            and DATA.seq.ext.children[note] 
            and DATA.seq.ext.children[note].steps 
            and DATA.seq.ext.children[note].steps[step] 
            and DATA.seq.ext.children[note].steps[step].val 
            and DATA.seq.ext.children[note].steps[step].val == 1 
            and DATA.lp_matrix[row] 
            and DATA.lp_matrix[row][step] then 
            DATA.lp_matrix[row][step].state = 2
          end
        end
        local active_step = DATA.seq.active_step[note]
        if DATA.lp_matrix[row] and DATA.lp_matrix[row][active_step] then
          DATA.lp_matrix[row][active_step].state = 1
        end
      end
    
    local col_state
    for row = 1, 8 do
      for col = 1, 8 do
        col_state = 0
        if DATA.lp_matrix[row][col].state == 1 then col_state = 21 end
        if DATA.lp_matrix[row][col].state == 2 then col_state = 13 end
        StuffMIDIMessage( 16+EXT.CONF_midioutput, 0x90, DATA.lp_matrix[row][col].MIDI_note, col_state )
      end
    end 
    
    
  end 
  ----------------------------------------------------------------------
  function DATA:CollectData_Always_LaunchPadInteraction()
    if DATA.seq_functionscall ~= true then return end
    if not (DATA.seq and DATA.seq.ext and DATA.seq.ext.children) then return end
    
    local playingnote = gmem_read(1029)
    if playingnote ~= -1 then
      gmem_write(1029,-1)
      
      col_edit = playingnote%10 -- step
      row_edit = math.floor(playingnote/10) -- note
      local note_edit
      local step_edit = col_edit
      
      for note in pairs(DATA.seq.ext.children) do if DATA.seq.ext.children[note].IDorder == row_edit then note_edit = note break end end
      if note_edit  and step_edit then  
      
        
        if not DATA.seq.ext.children[note_edit].steps then DATA.seq.ext.children[note_edit].steps = {} end
        if not DATA.seq.ext.children[note_edit].steps[step_edit] then DATA.seq.ext.children[note_edit].steps[step_edit] = {val = 0} end
        DATA.seq.ext.children[note_edit].steps[step_edit].val = DATA.seq.ext.children[note_edit].steps[step_edit].val~1
        DATA:_Seq_Print()
        DATA:Launchpad_SendState()
      end
      
    end
    
    
  end
  
  --[[-------------------------------------------------------------------  
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
        DATA:Launchpad_StuffSysex(SysEx_msg, HWdevoutID) 
      end
      if is_LPProMK3 ==true then 
        SysEx_msg = 'F0h 00h 20h 29h 02h 0Eh 00h 04 00 00h F7h' 
        DATA:Launchpad_StuffSysex(SysEx_msg, HWdevoutID) 
      end
    end
    
    
    
    -- 
      if cmd == 'set/refresh active state' then
        SysEx_msg = 'F0h 00h 20h 29h 02h 0Dh 00h 7F F7h' 
        DATA:Launchpad_StuffSysex(SysEx_msg, HWdevoutID) 
      end
    
    --if cmd == 'drum layout' then
      if cmd == 'drum mode' then
        if is_LPminiMK3 ==true then 
          SysEx_msg = 'F0h 00h 20h 29h 02h 0Dh 10h 01 F7h' 
          DATA:Launchpad_StuffSysex(SysEx_msg, HWdevoutID) 
        end
      end
      
      
      if is_LPminiMK3 ==true or is_LPProMK3==true then 
        for ledId = 0, 81 do
          if DATA.children and DATA.children[ledId] and DATA.children[ledId].I_CUSTOMCOLOR then
            local msgtype = 90
            if DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE and DATA.parent_track.ext.PARENT_LASTACTIVENOTE == ledId then msgtype = 92 end
            SysEx_msg = msgtype..' '..string.format("%02X", ledId)..' 16'
            DATA:Launchpad_StuffSysex(SysEx_msg, HWdevoutID) 
           else
            local col = '00'
            if DATA.parent_track and DATA.parent_track.ext and DATA.parent_track.ext.PARENT_LASTACTIVENOTE and DATA.parent_track.ext.PARENT_LASTACTIVENOTE == ledId then col = '03' end
            SysEx_msg = '90 '..string.format("%02X", ledId)..' '..col
            DATA:Launchpad_StuffSysex(SysEx_msg, HWdevoutID) 
          end
        end
      end
      
    end]]
    
    
    --[[
    
    if cmd == 'programmer mode' then
      if is_LPminiMK3 ==true then 
        SysEx_msg = 'F0h 00h 20h 29h 02h 0Dh 00h 7F F7h' 
        DATA:Launchpad_StuffSysex(SysEx_msg, HWdevoutID) 
      end
      if is_LPProMK3 ==true then 
        SysEx_msg = 'F0h 00h 20h 29h 02h 0Eh 00h 11 00 00h F7h'
        DATA:Launchpad_StuffSysex(SysEx_msg, HWdevoutID) 
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
  
    end
    
  end ]]
  
  --------------------------------------------------------------------------------  
  function UI.draw_Rack_Pads_controls_handlemouse(note_t,note,popup_content0)
    if note == -1 then return end
    local popup_content
    if not popup_content0 then popup_content = 'pad' else popup_content = popup_content0 end
    if not (note_t and note_t.TYPE_DEVICE==true) and  ImGui.BeginDragDropTarget( ctx ) then  
      UI.Drop_UI_interaction_pad(note) 
      ImGui_EndDragDropTarget( ctx )
    end 
    
    if ImGui.IsItemActivated(ctx) then 
      if EXT.UI_clickonpadplaysample ==1 then DATA:Sampler_StuffNoteOn(note) end
    end
    
    if ImGui.IsItemClicked( ctx, ImGui.MouseButton_Right ) then 
      DATA.parent_track.ext.PARENT_LASTACTIVENOTE=note
      DATA:WriteData_Parent() 
      DATA.upd = true
      if popup_content0 ~= 'seq_pad' then 
        if UI.anypopupopen==true then DATA.trig_closepopup = true else DATA.trig_openpopup = popup_content end
      end
    end
    
    if ImGui.IsItemClicked(ctx,ImGui.MouseButton_Left) then -- click select track
      if EXT.UI_clickonpadselecttrack == 1 and note_t then SetOnlyTrackSelected( note_t.tr_ptr )  end
      if EXT.UI_clickonpadscrolltomixer == 1 and note_t then  SetMixerScroll( note_t.tr_ptr )  end
      DATA.parent_track.ext.PARENT_LASTACTIVENOTE=note 
      DATA.padcustomnames_selected_id = note
      DATA.padautocolors_selected_id = note
      DATA.settings_cur_note_database=note
      DATA:WriteData_Parent() 
      DATA.upd = true 
      if popup_content0 == 'seq_pad' then DATA:Sampler_StuffNoteOn(note) end
    end
     
    if ImGui.IsItemDeactivated( ctx ) then 
      if EXT.UI_pads_sendnoteoff == 1 then DATA:Sampler_StuffNoteOn(note, 0, true) end
    end
    
    if popup_content0 ~= 'seq_pad' then 
      if note_t and note_t.noteID and ImGui.BeginDragDropSource( ctx, ImGui.DragDropFlags_None ) then  
        ImGui.SetDragDropPayload( ctx, 'moving_pad', note_t.noteID, ImGui.Cond_Once )
        ImGui.Text(ctx, 'Move pad ['..note_t.noteID..'] '..note_t.P_NAME)
        DATA.paddrop_ID = note_t.noteID
        if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Mod_Ctrl()) then DATA.paddrop_mode = 1 end
        ImGui.EndDragDropSource(ctx)
      end
    end
  end
