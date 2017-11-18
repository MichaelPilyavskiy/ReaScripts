-- @description Reset pitchbend at mouse cursor
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # reset only if pitchbend CC lane under mouse cursor

  function ResetPitchBend()
    local _, segmentOut, _ =reaper.BR_GetMouseCursorContext()
    if segmentOut == 'cc_lane' then
      local midieditor =  reaper.MIDIEditor_GetActive()
      local take =  reaper.MIDIEditor_GetTake( midieditor )
      local projtime = reaper.BR_GetMouseCursorContext_Position()
      local ppqpos =  reaper.MIDI_GetPPQPosFromProjTime( take, projtime )  
      local chan = reaper.MIDIEditor_GetSetting_int( midieditor, 'default_note_chan' )
      local pitchbend = 8192                                              
      local lane = 224
      local byte1 = lane + chan 
      local byte2 = pitchbend & 0x7F
      local byte3 = pitchbend >> 7
      local bytestr  = string.char(byte1,byte2,byte3)
      retval, inlineEditorOut, noteRowOut, ccLaneOut, ccLaneValOut, ccLaneIdOut = reaper.BR_GetMouseCursorContext_MIDI()
      if ccLaneOut and ccLaneOut == 513 then reaper.MIDI_InsertEvt( take, false, false, ppqpos, bytestr ) end
    end
  end
  
  ResetPitchBend()