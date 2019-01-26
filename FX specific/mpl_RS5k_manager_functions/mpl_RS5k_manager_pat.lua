-- @description RS5k_manager_pat
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex

  function Pattern_EnumList(conf, obj, data, refresh, mouse, pat)
    
    local item = GetSelectedMediaItem(0,0)
    if not item then return end
    local take = GetActiveTake(item)
    if not TakeIsMIDI(take) then return end
    local ret, src_name = GetSetMediaItemTakeInfo_String( take, 'P_NAME' , '', false )
                                        
    -- search for existed pattern
     local t = {{str='Rename take/pattern|',
            func = function()
                      ret, str = GetUserInputs( conf.scr_title, 1, 'new name', src_name )
                      if ret then
                                    local item = GetSelectedMediaItem(0,0)
                                    if not item then return end
                                    local take_out = GetActiveTake(item)
                                    if not TakeIsMIDI(take_out) then return end
                                    GetSetMediaItemTakeInfo_String( take_out, 'P_NAME' , str, true )  
                                    refresh.GUI = true
                      end                  
                  end}}
      for i =0, 300 do
        local retval, key, val = EnumProjExtState( 0, conf.ES_key, i )
        if key:match('%{.-%}') then 
          local GUID = val:match('GUID (%{.-%})')
          if GUID then
            local take = GetMediaItemTakeByGUID( 0, GUID )
            if take and ValidatePtr2( 0, take, 'MediaItem_Take*' ) then
              local tkname = GetTakeName( take )
              local retval, poolGUID = BR_GetMidiTakePoolGUID( take )
              
              for i =1, #t do if tkname == t[i].str then goto skipnextentrypool end end
              
              t[#t+1] = {str = tkname,
                          func = function ()
                                    Pattern_Parse(conf, pat, poolGUID, tkname)
                                    
                                    local item = GetSelectedMediaItem(0,0)
                                    if not item then return end
                                    local take_out = GetActiveTake(item)
                                    if not TakeIsMIDI(take_out) then return end
                                    GetSetMediaItemTakeInfo_String( take_out, 'P_NAME' , tkname, true )
                                    local retval, poolGUID = BR_GetMidiTakePoolGUID( take_out )
                                    Pattern_Commit(conf, pat, poolGUID, take_out)
                                    Pattern_SaveExtState(conf, pat, poolGUID, take_out)
                                    --refresh.data = true
                                    --refresh.GUI = true
                                  end}
            end
          end
          ::skipnextentrypool::
        end
        if not retval then break end
      end
      Menu(mouse,t)
      --local ret, str = GetProjExtState( 0, conf.ES_key, 'PAT_'..poolGUID )
    -- show dropdown
    -- apply on selection
  end
  ----------------------------------------------------
  function Pattern_GetSrcData(obj)
    obj.pat_item_pos_sec = nil
    local item = GetSelectedMediaItem(0,0)
    if not item then return end
    local take = GetActiveTake(item)
    if not TakeIsMIDI(take) then return end
    local retval, poolGUID = BR_GetMidiTakePoolGUID( take )
    local take_name = GetTakeName( take )
    return true, poolGUID, take_name, take, item
  end
  ----------------------------------------------------
  function Pattern_Change(conf, pat, poolGUID, note, step, vel)
    -- add note tbl if not exist
    if not pat[note] then 
      pat[note] = { cnt_steps = conf.def_steps, steps = {}, swing = conf.def_swing} 
    end
    -- add step
    --if pat[note].steps[step]and pat[note].steps[step] > 0  then 
      pat[note].steps[step] = vel
     --else
      --pat[note].steps[step] = 0
    --end
  end
  ----------------------------------------------------  
  function Pattern_SaveExtState(conf, pat, poolGUID, take_ptr)
    local GUID = BR_GetMediaItemTakeGUID( take_ptr )
    local str = 'GUID '..GUID
    for note in pairs(pat) do
      if tonumber(note) then
        if not pat[note].swing then pat[note].swing = conf.def_swing end
        if not pat[note].cnt_steps then pat[note].cnt_steps = conf.def_steps end
        str = str..'\n'..'NOTE='..note..' '..pat[note].cnt_steps..' '..pat[note].swing
        if pat[note].steps then
          for step in spairs(pat[note].steps) do
            str = str..'\n'..'    STEP '..step..' '..pat[note].steps[step]
          end
        end
      end
    end
    
    --msg('SAVE'..str)
    SetProjExtState( 0, conf.ES_key, 'PAT_'..poolGUID, str )
  end
   ----------------------------------------------------   
  function Pattern_Parse(conf, pat, poolGUID, take_name)
    
    local ret, str = GetProjExtState( 0, conf.ES_key, 'PAT_'..poolGUID )
    --msg('PRS'..str)
    if ret == 0 then return end
    local cur_note, cnt_steps, swing
    for line in str:gmatch('[^\r\n]+') do
      if line:match('NOTE=(%d+)') then
        cur_note, cnt_steps, swing = line:match('NOTE=(%d+)%s(%d+)%s([%d%p]+)')
        cur_note = tonumber(cur_note)
        if not cur_note then 
          cur_note, cnt_steps, swing = line:match('NOTE=(%d+)%s(%d+)')
          cur_note = tonumber(cur_note)
        end
        cur_note = math.floor(cur_note)
        if not pat[cur_note] then pat[cur_note] = {steps  ={}} end
        pat[cur_note].cnt_steps =  tonumber(cnt_steps)
        pat[cur_note].swing = tonumber(swing)
      end
      if line:match('STEP%s(%d+)%s(%d+)') then
        local stepID, vel = line:match('STEP%s(%d+)%s(%d+)')
        pat[cur_note].steps[tonumber(stepID)] = tonumber(vel)
      end
    end
   end
   ----------------------------------------------------    
  function Pattern_Commit(conf, pat, poolGUID, take)
    -- clear MIDI
    local retval, notecnt, ccevtcnt, textsyxevtcnt = MIDI_CountEvts( take )
    for noteidx = notecnt, 1, -1 do MIDI_DeleteNote( take, noteidx-1 ) end
    
    -- add MIDI    
    local it =  GetMediaItemTake_Item( take )
    local it_pos =  GetMediaItemInfo_Value( it,'D_POSITION' )
    local toffs = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
    local trate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )     
    local it_pos_beats = ({ TimeMap2_timeToBeats( 0, it_pos - toffs/trate )})[4]
    
    for note in pairs(pat) do
      if tonumber(note) and pat[note].steps then
        for i_step in pairs(pat[note].steps) do
          local beat = (4/pat[note].cnt_steps) / trate
          local start_beats = it_pos_beats + (4/pat[note].cnt_steps * (i_step-1)) / trate
          local end_beats = it_pos_beats + (4/pat[note].cnt_steps * i_step) / trate
          if pat[note].swing then
            if pat[note].swing > 0 and pat[note].swing < 0.9 then 
              if i_step%2 ==0 then start_beats = start_beats + pat[note].swing *beat  end
             elseif pat[note].swing < 0 and pat[note].swing > -0.9 then 
              if i_step%2 ==0 then start_beats = start_beats + beat * pat[note].swing  end
              if i_step%2 ==1 then end_beats = end_beats + beat * pat[note].swing end
            end
          end
          local start_beats_ppq = MIDI_GetPPQPosFromProjTime( take,  TimeMap2_beatsToTime( 0, start_beats ) )
          local end_beats_ppq = MIDI_GetPPQPosFromProjTime( take,  TimeMap2_beatsToTime( 0, end_beats ) ) -1
          
          MIDI_InsertNote( 
           take, 
           false, -- selected
           false, -- muted
           start_beats_ppq,
           end_beats_ppq,
           0, -- channel
           note, -- pitch
           pat[note].steps[i_step], -- velocity
           true) -- no sort]]        
        end
      end
    end
         
    MIDI_Sort( take )
    --UpdateItemInProject( it )
  end   
