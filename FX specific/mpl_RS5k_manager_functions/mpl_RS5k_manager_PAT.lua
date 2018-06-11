-- @description RS5k_manager_PAT
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  ---------------------------------------------------
  function GetSeqHash(hash) 
    local t = {}
    if not hash then return t end
    for hex in hash:gmatch('[%a%d][%a%d]') do 
      local val = tonumber(hex, 16)
      t[#t+1] = math.min(math.max(0,val),127) 
    end
    return t
  end
  -----------------------------------------------------------------------  
  function FormSeqHash(step_cnt, t)
    local out_val = ''
    for i = 1, step_cnt do
      local sval if not t[i] then sval = 0 else sval = math.min(math.max(0,t[i]),127)  end
      out_val = out_val..''..string.format("%02X", sval)
    end
    return out_val
  end
  -----------------------------------------------------------------------
  function IncrementPatternName(name)--GetNewPatternName
    if not name then return end
    if name:reverse():find('[%d]+_') == 1 then 
      local id = name:reverse():match('[%d]+'):reverse()
      return name:reverse():match('(_.*)'):reverse()..math.floor(id+1)
     else
      return name..'_1'
    end
  end
  -----------------------------------------------------------------------  
  function SelectLinkedPatterns(conf, data, pat_name)
    if conf.global_mode == 0 then 
      tr = data.parent_track
     elseif conf.global_mode == 1 or conf.global_mode == 2 then
      tr = data.parent_trackMIDI
    end
    if not tr then return end
    for i = 1,  CountTrackMediaItems(tr) do
      local it =  GetTrackMediaItem(tr,i-1)
      if it then
        local tk = GetActiveTake(it)
        if tk and TakeIsMIDI(tk) then 
          local _, tk_name = GetSetMediaItemTakeInfo_String( tk, 'P_NAME', '',  0 )
          SetMediaItemSelected( it, tk_name == pat_name )
        end
      end  
    end
    UpdateArrange()
  end
  ---------------------------------------------------
  function CommitPattern_InsertSource(tr, sample_path, pos , vel)
    if not tr then return end
    local item = AddMediaItemToTrack( tr )
    local take = AddTakeToMediaItem( item )
    local src = PCM_Source_CreateFromFile( sample_path)
    local src_len = GetMediaSourceLength( src )    
    SetMediaItemInfo_Value( item, 'D_POSITION', pos)
    SetMediaItemInfo_Value( item, 'D_LENGTH', src_len)
    SetMediaItemInfo_Value( item, 'D_FADEINLEN', 0 )
    SetMediaItemInfo_Value( item, 'D_FADEOUTLEN', 0.001 )
    SetMediaItemInfo_Value( item, 'B_LOOPSRC', 0 )
    SetMediaItemInfo_Value( item, 'D_VOL', vel / 127 )
    BR_SetTakeSourceFromFile2( take, sample_path,false, true)
    UpdateItemInProject( item )
    return item, pos+src_len
  end
  ---------------------------------------------------
  function CommitPattern_ClearDumpTrack(track, src_pat_item, offs)
    if not track or not src_pat_item then return end
    local t1 = GetMediaItemInfo_Value( src_pat_item, 'D_POSITION' )
    local t2 = GetMediaItemInfo_Value( src_pat_item, 'D_LENGTH' ) + t1
    
    for it_idx = CountTrackMediaItems( track ), 1, -1 do
      local it = GetTrackMediaItem( track, it_idx-1 )
      local it_pos = GetMediaItemInfo_Value( it, 'D_POSITION' )
      if it_pos > t1-offs and it_pos < t2 - offs then 
        DeleteTrackMediaItem( track, it ) 
        
      end
      if it_pos < t1 - offs then break end
    end
  end
  ----------------------------------------------------------------------- 
  function CheckPatCond(data, pat, note)
    if not data or not note then return false end
    if data[note] then return true end
    if not pat[pat.SEL] then return  end
    for key in pairs(pat[pat.SEL]) do
      if key == ('NOTE'..note) then return true end
    end
    return false
  end
  ---------------------------------------------------
  function CommitPatternSub(data, conf, pat, it, tk, pat_t,it_pos_QN,it_pos,it_len )
    local offs = 0.0001
    local MeasPPQ = MIDI_GetPPQPosFromProjQN( tk, it_pos_QN )
    -- update name
    GetSetMediaItemTakeInfo_String( tk, 'P_NAME', pat_t.NAME,  1 )
    -- clear MIDI data
    for i = ({MIDI_CountEvts( tk )})[2], 1, -1 do MIDI_DeleteNote( tk, i-1 ) end
    -- clear child items for dump items mode
    if conf.global_mode == 2 then 
      for key in spairs(pat_t) do
        if key:match('NOTE[%d]+') then
          local note = tonumber(key:match('[%d]+'))
          local child_tr = GetDestTrackByNote(data, conf,data.parent_track, note, false) 
          CommitPattern_ClearDumpTrack(child_tr, it,offs) 
        end
      end
    end
    -- add notes
      for key in spairs(pat_t) do
        if key:match('NOTE[%d]+') then
          local t = pat_t[key]
          local note = tonumber(key:match('[%d]+'))
          local child_tr = GetDestTrackByNote(data, conf,data.parent_track, note, false)
          if child_tr then
            local FIPM = GetMediaTrackInfo_Value( child_tr, 'B_FREEMODE')
          end
          local _,_,sample_path = GetSampleNameByNote(data, note)
          local mult if not pat_t.PATLEN then mult = 1 else mult = pat_t.PATLEN end
          local step_len = math.ceil(MeasPPQ/t.STEPS)*mult
          local last_source_end
          local last_pos = true
          for step = 1, t.STEPS do
            if t.seq and t.seq[step] and t.seq[step] > 0 then
              MIDI_InsertNote( 
               tk, 
               false, -- selected
               false, -- muted
               step_len * (step-1), -- start ppq
               step_len * step,  -- end ppq
               0, -- channel
               note, -- pitch
               t.seq[step], -- velocity
               true) -- no sort
              if conf.global_mode == 2 then 
                local pos = MIDI_GetProjTimeFromPPQPos( tk, step_len * (step-1) )
                if pos > it_pos-offs and pos < it_pos + it_len+offs then
                  local it, source_end = CommitPattern_InsertSource(child_tr, sample_path, pos, t.seq[step]) 
                  if FIPM and it and last_source_end and last_source_end >= pos then 
                    if last_pos == true then 
                      reaper.SetMediaItemInfo_Value( it, 'F_FREEMODE_Y', 0.5 )
                      reaper.SetMediaItemInfo_Value( it, 'F_FREEMODE_H', 0.5 )
                      last_pos = false
                     else
                      reaper.SetMediaItemInfo_Value( it, 'F_FREEMODE_Y', 0 )
                      reaper.SetMediaItemInfo_Value( it, 'F_FREEMODE_H', 0.5 )
                      last_pos = true
                    end  
                   else 
                    last_pos = true                
                  end
                  last_source_end = source_end
                end
              end
            end
          end
        end
      end
    -- update GUI
    reaper.MIDI_Sort( tk )
    UpdateItemInProject( it )
  end
  ---------------------------------------------------
  function CommitPattern(data, conf, pat, mode, old_name, new_name)
    local int_mode
    if mode then int_mode = mode else int_mode = conf.commit_mode end
    if int_mode == 0 then -- set/upd selected items
      
      if pat[pat.SEL] then
        for i = 1, CountSelectedMediaItems(0) do
          local it = GetSelectedMediaItem(0,i-1)
          local it_pos =  GetMediaItemInfo_Value( it,'D_POSITION' )
          local it_len =  GetMediaItemInfo_Value( it,'D_LENGTH' )
          local it_pos_beats = ({ TimeMap2_timeToBeats( 0, it_pos )})[4]
          local it_pos_beats_1measure = TimeMap2_beatsToTime( 0, it_pos_beats, 1 )
          local it_pos_QN =  TimeMap2_timeToQN( 0, it_pos_beats_1measure )          
          local tk = GetActiveTake(it)
          if tk and TakeIsMIDI(tk) then CommitPatternSub(data, conf, pat, it, tk, pat[pat.SEL],it_pos_QN,it_pos,it_len) end
        end
        
      end
      
     elseif int_mode == 1 then -- propagate patterns by name
      if pat[pat.SEL] then
        for i = 1, CountMediaItems(0) do
          local it = GetMediaItem(0,i-1)
          if it then
            local it_pos =  GetMediaItemInfo_Value( it,'D_POSITION' )
            local it_pos =  GetMediaItemInfo_Value( it,'D_POSITION' )
            local it_len =  GetMediaItemInfo_Value( it,'D_LENGTH' )
            local it_pos_beats = ({ TimeMap2_timeToBeats( 0, it_pos )})[4]
            local it_pos_beats_1measure = TimeMap2_beatsToTime( 0, it_pos_beats, 1 )
            local it_pos_QN =  TimeMap2_timeToQN( 0, it_pos_beats_1measure )
            local tk = GetActiveTake(it)
            if tk and TakeIsMIDI(tk) then 
              local _, tk_name = GetSetMediaItemTakeInfo_String( tk, 'P_NAME', '',  0 )
              local chk_name if old_name then chk_name = old_name else chk_name = pat[pat.SEL].NAME end
              if tk_name == chk_name then
                if conf.global_mode == 2 then SetMediaItemInfo_Value( it,'B_MUTE', 1 ) end
                CommitPatternSub(data, conf, pat, it, tk, pat[pat.SEL],it_pos_QN,it_pos,it_len)
              end
              if new_name then GetSetMediaItemTakeInfo_String( tk, 'P_NAME', new_name,  1 ) end
            end
          end
        end
      end
           
    end
  end
  
  ---------------------------------------------------
  function ExtState_Save_Patterns(conf, obj, data, refresh, mouse, pat) 
    local str = '//MPL_RS5K_PATLIST'
    
    -- store parent track
    str = str..'\nPARENT_GUID '..GetTrackGUID( data.parent_track )..'\n'

    -- store MIDI track
    if data.parent_trackMIDI then 
      local miditr_GUID = GetTrackGUID( data.parent_trackMIDI )
      str = str..'PARENTMIDI_GUID '..miditr_GUID..'\n'
    end    
    
    
    local ind = '   '
    for k,v in spairs(pat, function(t,a,b) return tostring(b):lower() > tostring(a):lower() end) do 
    --for k in pairs(pat) do 
      
      if tonumber(k) then
        local pat_t = pat[k]
        str = str..'\n<PAT'
        for key in spairs(pat_t) do
          if not key:match('NOTE[%d]+') then 
            str = str..'\n'..ind..key..' '..pat_t[key]
           else
            local steps = conf.default_steps
            if pat_t[key] and pat_t[key].STEPS then steps = pat_t[key].STEPS end
            str = str..'\n'..ind..key..' '..tonumber(steps)
            if pat_t[key].SEQHASH then str = str..' '..pat_t[key].SEQHASH end
          end
        end
        str = str..'\n>'
       else
        str = str..'\n'..k..' '..pat[k]
      end
    end  
    
    --ClearConsole()
    --msg('\nSAVE\n'..str)
    SetProjExtState( 0, conf.ES_key, 'PAT', str )
    CommitPattern(data, conf, pat )
  end
  ---------------------------------------------------
  function ExtState_Load_Patterns(data, conf)
    local pat = {}
    local ret, str = GetProjExtState( 0, conf.ES_key, 'PAT' )
    --msg('load\n'..str)
    
    if not ret then return end
    
    -- get parent
    if str:match('PARENT_GUID') then 
      data.parent_track_GUID = str:match('PARENT_GUID (.-)\n') 
      local stored_tr = BR_GetMediaTrackByGUID( 0, data.parent_track_GUID )
      data.parent_track = stored_tr
    end
    
    -- get MIDI tr
    if str:match('PARENTMIDI_GUID') then 
      data.parent_trackMIDI_GUID = str:match('PARENTMIDI_GUID (.-)\n') 
      local stored_tr = BR_GetMediaTrackByGUID( 0, data.parent_trackMIDI_GUID )
      data.parent_trackMIDI = stored_tr
    end    
    
    -- parse patterns
      for line in str:gmatch('<PAT[\n\r](.-)>') do   
        pat[#pat+1] = {}     
        for l2 in line:gmatch('[^\r\n]+') do          
          local key = l2:match('[%a%d]+')
          
          if not key:match('NOTE[%d]+')then
            local val = l2:match('[%a%d][%s](.*)')
            if tonumber(val) then val = tonumber(val) end
            pat[#pat][key] = val
           else
            local t = {} for val in l2:gmatch('[^%s]+') do t[#t+1] = val end
            if not pat[#pat][key] then pat[#pat][key] = {} end
            pat[#pat][key].STEPS = math.floor(tonumber(t[2]))
            pat[#pat][key].SEQHASH = t[3]
            pat[#pat][key].seq = GetSeqHash(t[3])
          end
        end
      end
    -- parse params
      for line in str:gmatch('[^\r\n]+') do 
        if line:find('[%a]+ [%d]+') and line:find('[%a]+ [%d]+') == 1 then 
          local key = line:match('[%a]+')
          local val = line:match('[%d]+') if val then val = tonumber(val) end
          pat[key] = val
        end 
      end
    
    -- sort by name
      local pat_2 = CopyTable(pat)
      pat = {}
      local names = {}
      for i = 1, #pat_2 do names[pat_2[i].NAME] = i end
      for key in spairs(names) do pat[#pat+1] = pat_2[ names[key] ] end
    
    -- selected
      local selected = str:match('SEL ([%d]+)')
      if selected and tonumber(selected) then selected = tonumber(selected) end
      if pat[selected] then pat.SEL = selected end
    return pat
  end
