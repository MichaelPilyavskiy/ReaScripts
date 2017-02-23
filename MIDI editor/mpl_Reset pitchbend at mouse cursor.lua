-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Reset pitchbend at mouse cursor
-- @changelog
--    + init release

retval, segmentOut, detailsOut =reaper.BR_GetMouseCursorContext()
if segmentOut == 'cc_lane' then
  midieditor =  reaper.MIDIEditor_GetActive()
  take =  reaper.MIDIEditor_GetTake( midieditor )
  projtime = reaper.BR_GetMouseCursorContext_Position()
  ppqpos =  reaper.MIDI_GetPPQPosFromProjTime( take, projtime )  
  chan = reaper.MIDIEditor_GetSetting_int( midieditor, 'default_note_chan' )
  pitchbend = 8192                                              
  lane = 224
  byte1 = lane + chan 
  byte2 = pitchbend & 0x7F
  byte3 = pitchbend >> 7
  bytestr  = string.char(byte1,byte2,byte3)
  reaper.MIDI_InsertEvt( take, false, false, ppqpos, bytestr )
end
