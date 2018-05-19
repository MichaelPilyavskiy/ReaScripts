-- @description Show selected MIDI item data
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Dev purposes. Returns MIDI take data
-- @changelog
--    # use reverse beats to seconds convertion for grid difference


  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  function math_q(num)  if math.abs(num - math.floor(num)) < math.abs(num - math.ceil(num)) then return math.floor(num) else return math.ceil(num) end end
  -----------------------------------------------------------------
  function getMIDIdata(take, it_pos)
      local evts = {}
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
      while nextPos <= MIDIlen do  
          prevPos = nextPos
          offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
          idx = idx + 1
          ppq_pos = ppq_pos + offset
          local pos_sec = MIDI_GetProjTimeFromPPQPos( take, ppq_pos )          
          local beats, measures, _, fullbeatsOutOptional, _ = TimeMap2_timeToBeats( 0, pos_sec )
          local back_conv_sec = TimeMap2_beatsToTime( 0, beats, measures)
          local grid_dt =  back_conv_sec  - pos_sec
          evts[idx] = {rawevt = s_pack("i4Bs4", offset, flags , msg),
                            offset=offset, 
                            flags=flags, 
                            msg=msg,
                            ppq_pos = ppq_pos,
                            pos_sec = pos_sec,
                            pos_sec_format = pos_sec_format,
                            pos_beats = beats,
                            grid_dt = grid_dt}
      end 
      return evts   
  end
  
  function main()
    local item = GetSelectedMediaItem(0,0)
    if not item then return end
    local it_pos =  GetMediaItemInfo_Value(item, 'D_POSITION')
    local take = GetActiveTake(item)
    if not take or not TakeIsMIDI(take) then return end
    data = getMIDIdata(take, it_pos)
    str = ''
    for i = 1, #data do
      str = str..'\n'
            ..i
            ..'   position (PPQ) ='..data[i].ppq_pos
            --..'         PPQ_offset ='..data[i].offset
            ..'         position(seconds) ='..data[i].pos_sec
            ..'         position(beats) ='..data[i].pos_beats
            ..'         grid_difference(seconds) ='..data[i].grid_dt
            
            ..'         msg type = 0x'..string.format("%x", data[i].msg:byte(1))
            ..'         channel = '..tonumber(1+data[i].msg:byte(1)&0xF)
            ..'         msg1 = '..tonumber(data[i].msg:byte(2)) 
            ..'         msg2 = '..tonumber(data[i].msg:byte(3)) 
            ..'         sel = '..tonumber(data[i].flags&1)
            ..'         mute = '..tonumber(data[i].flags&2)
    end
    ClearConsole()
    ShowConsoleMsg(str)
  end
  
  main()