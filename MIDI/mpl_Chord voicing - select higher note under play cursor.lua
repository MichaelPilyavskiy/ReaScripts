-- @description Chord voicing - select higher note under play cursor
-- @version 1.04
-- @author MPL
-- @provides [main=main,midi_editor] .
-- @changelog
--    # fix spairs error

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end---------------------------------------------------
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
  ----------------------------------------------------------------------  
  function main(take)
    if not take or not TakeIsMIDI(take) then return end  
    local playcurpos =  GetPlayPosition2()
    if  GetPlayState()&1==0 then playcurpos = GetCursorPosition() end
    local evts = getevts(take)  
    chords = {}
    chords = chords_get(take, evts)
    modifychords(chords,take, playcurpos) 
    setevtsback(take,evts,chords)
  end
  ----------------------------------------------------------------------
  function modifychords(chords,take, playcurpos)
    for ppq in spairs(chords) do
      has_selectedflag= false
      for chordnote = 1, #chords[ppq] do if chords[ppq][chordnote].flags&1==1 then has_selectedflag = true break end end
      
      --if has_selectedflag then 
      local maxpitch = -1
      local chordnoteout
      for chordnote = 1, #chords[ppq] do 
        if  chords[ppq][chordnote].pitch > maxpitch then
          chordnoteout = chordnote
          maxpitch = chords[ppq][chordnote].pitch
        end 
      end
      
        for chordnote = 1, #chords[ppq] do  
          local timest = MIDI_GetProjTimeFromPPQPos( take, chords[ppq][chordnote].ppq_pos )
          local timeen = MIDI_GetProjTimeFromPPQPos( take, chords[ppq][chordnote].ppq_pos+(chords[ppq][chordnote].ppq_len or 0) )
          if (timest<=playcurpos and timeen >=playcurpos) and chordnoteout == chordnote
            then chords[ppq][chordnote].flags = 1 
           else 
            chords[ppq][chordnote].flags = 0 
          end
        end 
      --end
    end
  end
  ----------------------------------------------------------------------
  function setevtsback(take,evts,chords) 
    local str = ""
    local s_pack = string.pack
    local ppq_pos = 0
    for i = 1, #evts-1 do
      if not evts[i].isnote then
        str=str..s_pack("i4Bs4", evts[i].ppq_pos - ppq_pos, evts[i].flags , evts[i].msg1)
        ppq_pos = evts[i].ppq_pos
      end
    end
    
    for ppq in spairs(chords) do
      for chordnote = 1, #chords[ppq] do
        if chords[ppq][chordnote].ppq_len then 
          str=str..string.pack("i4BI4BBB", chords[ppq][chordnote].ppq_pos - ppq_pos, chords[ppq][chordnote].flags, 3, 0x90 | chords[ppq][chordnote].chan, chords[ppq][chordnote].pitch, chords[ppq][chordnote].vel)
          str=str..string.pack("i4BI4BBB", chords[ppq][chordnote].ppq_len, chords[ppq][chordnote].flags, 3, 0x80 | chords[ppq][chordnote].chan, chords[ppq][chordnote].pitch, 0)
          ppq_pos = chords[ppq][chordnote].ppq_pos+chords[ppq][chordnote].ppq_len
        end
      end
    end
    
    MIDI_SetAllEvts(take, str)
    MIDI_Sort(take)
  end
  ----------------------------------------------------------------------
  function getevts(take)   
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    if not gotAllOK then return end 
    local s_unpack = string.unpack
    local MIDIlen = MIDIstring:len()
    local idx = 0    
    local offset, flags, msg1
    local ppq_pos = 0
    local nextPos, prevPos = 1, 1 
    local pitch
    
    -- collect mesages
    local evts = {}
    local notesopen = {}
    while nextPos <= MIDIlen do  
        prevPos = nextPos
        offset, flags, msg1, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos) 
        ppq_pos = ppq_pos + offset
        local pos_sec = MIDI_GetProjTimeFromPPQPos( take, ppq_pos )
        local CClane, pitch, CCval,vel, pitch_format
        local isNoteOn = msg1:byte(1)>>4 == 0x9 
        local isNoteOff = msg1:byte(1)>>4 == 0x8
        local pitch
        if isNoteOn == true and msg1:byte(3) == 0 then isNoteOn = false isNoteOff = true end
        if isNoteOn or isNoteOff then
          pitch = msg1:byte(2)
        end
        if not isNoteOff then
          idx = idx + 1
          evts[idx] = {
                            flags=flags, 
                            msg1=msg1,
                            ppq_pos = ppq_pos,
                            isnote = isNoteOn}
        end
        
        if isNoteOn then
          notesopen[pitch] = idx
        end
        
        if isNoteOff==true then  
          local last_rel_pitchid = notesopen[pitch]
          if evts[last_rel_pitchid] then
            local ppq_len = ppq_pos - evts[last_rel_pitchid].ppq_pos
            evts[last_rel_pitchid].ppq_len = ppq_len
            notesopen[pitch] = nil
          end
        end
    end
    return evts
  end
  
  
  ----------------------------------------------------------------------
  function chords_get(take, evts, store_to_rpp) 
    local ppq_filter =  reaper.MIDI_GetPPQPosFromProjQN( take, 0.25 ) 
    local last_ppq_pos = 0
    -- extract chords
      local chords = {}
      for i = 1, #evts do
        if evts[i].isnote then 
          local msg1 = evts[i].msg1
          local flags = evts[i].flags
          local ppq_pos = evts[i].ppq_pos 
          local ppq_len = evts[i].ppq_len 
          if ppq_pos - last_ppq_pos < ppq_filter then ppq_pos = last_ppq_pos end
          if not chords[ppq_pos] then  chords[ppq_pos] = {} end
          local norm_pitch = msg1:byte(2)%12
          chords[ppq_pos] [#chords[ppq_pos]+1]= {
              pitch = msg1:byte(2),
              vel = msg1:byte(3),
              chan = msg1:byte(1)&0xF,
              ppq_len = ppq_len,
              ppq_pos = evts[i].ppq_pos ,
              flags = flags
            }
          last_ppq_pos = ppq_pos
        end
      end
      
    return chords
  end
 --------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.32,true) then 
    Undo_BeginBlock()
    local ME = reaper.MIDIEditor_GetActive()
    if ME then
      --take = reaper.MIDIEditor_GetTake(ME)
      for takeindex = 1, 100 do
        local take = MIDIEditor_EnumTakes( ME, takeindex-1, true) 
        if not take then break end
        main(take) 
      end
     else
      for i = 1, CountSelectedMediaItems(0) do
        local item = GetSelectedMediaItem(0,i-1)
        local take = GetActiveTake(item) 
        if take then main(take) end
      end
    end
    Undo_EndBlock('Chord voicing - select higher note under play cursor', 0xFFFFFFFF)
  end 
