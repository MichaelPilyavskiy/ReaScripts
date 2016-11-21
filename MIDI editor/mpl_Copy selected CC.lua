-- @description Copy selected CC
-- @version 1.0
-- @author mpl
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + init release


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
    
    local str = ''
    for ccidx = 1, ccevtcntOut do
      local _, selectedOut, _, ppqposOut, chanmsg, chanOut, CC_lane, CC_value = reaper.MIDI_GetCC( take, ccidx-1 )
      if selectedOut == true and CC_lane == CC_lane_active and chanOut == default_note_chan then
        if str =='' then decrease_PPQ = ppqposOut end
        str = str..'\n '..math.floor(ppqposOut - decrease_PPQ)..' '..math.floor(CC_value)
      end    
    end          
    reaper.SetExtState( 'mpl CopyCC buffer', 'buffer', str, false )
  end
  
  main()
  
  
