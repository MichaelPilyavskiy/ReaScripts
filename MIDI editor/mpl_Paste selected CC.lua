-- @description Paste selected CC
-- @version 1.0
-- @author mpl
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + init release


-- get settings
  function main()
    local midieditor =  reaper.MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  reaper.MIDIEditor_GetTake( midieditor )
    if not take or not reaper.TakeIsMIDI(take) then return end
    local _, _, ccevtcntOut = reaper.MIDI_CountEvts( take )  
    local default_note_chan = reaper.MIDIEditor_GetSetting_int( midieditor, 'default_note_chan' )
    local CC_lane_active = reaper.MIDIEditor_GetSetting_int( midieditor, 'last_clicked_cc_lane' )
    local cur_sec =  reaper.GetCursorPosition()
    local cur_ppq = reaper.MIDI_GetPPQPosFromProjTime( take, cur_sec )  
    
    local t = {}
    local str = reaper.GetExtState( 'mpl CopyCC buffer', 'buffer' )
    if not str or str == '' then return end
    for num in str:gmatch('[%d]+') do t[#t+1] = num end
    local t2 = {}
    for i = 1, #t-1, 2 do  t2[#t2+1] = {ppq = t[i], val = t[i+1]} end
    for i = 1, #t2 do 
      reaper.MIDI_InsertCC( take, false, false, t2[i].ppq + cur_ppq, 176, default_note_chan, CC_lane_active, t2[i].val )
    end
  end
  
  main()
