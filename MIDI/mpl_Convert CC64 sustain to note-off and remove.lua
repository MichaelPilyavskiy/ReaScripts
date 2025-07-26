-- @description Convert CC64 sustain to note-off and remove
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @provides
--    [main=main,midi_editor] .
-- @changelog
--    + init
     
     
  for key in pairs(reaper) do _G[key]=reaper[key] end
------------------------------------------------------------------------------------------------------  
  function main()
    local midieditor = MIDIEditor_GetActive()
    if midieditor then 
      local take = MIDIEditor_GetTake( midieditor )
      main_sub(take)
      return
    end
    
    for i = 1, CountSelectedMediaItems(-1) do
      local it = GetSelectedMediaItem(-1,i-1)
      if it then 
        local take = GetActiveTake(it)
        if (take and reaper.TakeIsMIDI(take)) then main_sub(take) end
      end
    end
  end 
------------------------------------------------------------------------------------------------------    
  function main_sub(take) 
    local evts = getevts(take)
    mpl_SustainToNoteOff(evts)
    setevtsback(take,evts)
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
    local pitch
    while nextPos <= MIDIlen do  
        prevPos = nextPos
        offset, flags, msg1, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos) 
        ppq_pos = ppq_pos + offset
        local isNoteOn = msg1:byte(1)>>4 == 0x9 
        local isNoteOff = msg1:byte(1)>>4 == 0x8
        local pitch
        if isNoteOn or isNoteOff then pitch = msg1:byte(2) end
        if not isNoteOff then
          idx = idx + 1
          evts[idx] = {
                            flags=flags, 
                            msg1=msg1,
                            ppq_pos = ppq_pos,
                            isnote = isNoteOn,
                            
                            msgtype = msg1:byte(1)&0xF0, 
                            chan = msg1:byte(1)&0xF, 
                            byte2 = msg1:byte(2),
                            byte3 = msg1:byte(3),
                            
                            }
        end
        
        if isNoteOn then notesopen[pitch] = idx end
        
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
  function setevtsback(take,evts)
    local str = ""
    local s_pack = string.pack
    local ppq_pos = 0
    for i = 1, #evts do
      if not evts[i].ignore ~= true then goto skip end
      if not evts[i].isnote then
        str=str..s_pack("i4Bs4", evts[i].ppq_pos - ppq_pos, evts[i].flags , evts[i].msg1)
        ppq_pos = evts[i].ppq_pos 
       else 
        str=str..string.pack("i4BI4BBB", evts[i].ppq_pos - ppq_pos, evts[i].flags, 3, 0x90 | evts[i].chan, evts[i].byte2, evts[i].byte3)
        str=str..string.pack("i4BI4BBB", evts[i].ppq_len, evts[i].flags, 3, 0x80 | evts[i].chan, evts[i].byte2, 0)
        ppq_pos = evts[i].ppq_pos+evts[i].ppq_len 
      end
      ::skip::
    end
    
    MIDI_SetAllEvts(take, str)
    MIDI_Sort(take)
  end  
------------------------------------------------------------------------------------------------------    
  function mpl_SustainToNoteOff(evts)
    -- 1bit quantize CC64
    local sz = #evts
    for i = 1, sz do
      if evts[i].msgtype&0xF0 == 0xB0 and evts[i].byte2 == 64 then
        if evts[i].byte3 > 0 then 
          local cc64msg = evts[i].msg1
          evts[i].msg1 = string.char(cc64msg:byte(1))..string.char(cc64msg:byte(2))..string.char(0x7F) 
        end
      end
    end
    
    -- extract cc64 blocks
    cc64blocks = {}
    local cur_blockid,gate = 0
    for i = 1, sz do
      if evts[i].msgtype&0xF0 == 0xB0 and evts[i].byte2 == 64 then
        if evts[i].byte3 > 0 and gate ~= true then 
          gate = true
          cur_blockid = cur_blockid + 1
          cc64blocks[cur_blockid] = {ppq_st = evts[i].ppq_pos}
        end 
        if evts[i].byte3 == 0 and gate == true then  
          cc64blocks[cur_blockid].ppq_end = evts[i].ppq_pos
          gate = false
        end
      end
    end
    
    -- enclose infinite block
    for i = 1, #cc64blocks do
      if not cc64blocks[i].ppq_end then cc64blocks[i].ppq_end = evts[#evts].ppq_pos-1 end
    end
    
    -- extend notes
    for i = 1, sz do
      if evts[i].isnote == true then
        local ppq_st = evts[i].ppq_pos
        local ppq_end = evts[i].ppq_pos + evts[i].ppq_len
        for j = 1, #cc64blocks do
          if 
            (cc64blocks[j].ppq_st >= ppq_st and cc64blocks[j].ppq_st <= ppq_end) -- cc64 triggered after NoteOn, before noteOff 
            or 
            (cc64blocks[j].ppq_st <= ppq_st and cc64blocks[j].ppq_end > ppq_end) -- cc64 triggered before noteOn, released after noteOff
            then 
            evts[i].ppq_len = cc64blocks[j].ppq_end - evts[i].ppq_pos
            break
          end
        end
      end 
    end
    
    
  end
------------------------------------------------------------------------------------------------------    
  Undo_BeginBlock2(-1)
  main()
  Undo_EndBlock2( -1, 'Convert CC64 sustain to note-off and remove', 0xFFFFFFFF )
  
  