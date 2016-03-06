  --[[
     * ReaScript Name: Add CC64 on to channel 0 of active MIDI Editor take
     * Lua script for Cockos REAPER
     * Author: Michael Pilyavskiy (mpl)
     * Author URI: http://forum.cockos.com/member.php?u=70694
     * Licence: GPL v3
     * Version: 1.0
    ]]
    
  --[[
    * Changelog: 
    * v1.0 (2016-08-06)
      + init release
  --]]
  
  function main()
    channel = 0
    MIDIEditor = reaper.MIDIEditor_GetActive()
    if MIDIEditor == nil then return end
    take = reaper.MIDIEditor_GetTake(MIDIEditor)
    if take == nil then return end
    item = reaper.GetMediaItemTake_Item(take)
    itempos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    if reaper.TakeIsMIDI(take) == false then return end
    pos = reaper.GetCursorPosition() 
    ppq = reaper.MIDI_GetPPQPosFromProjTime(take, pos)
    reaper.MIDI_InsertCC(take, 
                          false,--boolean selected, 
                          false,--boolean muted, 
                          ppq,--number ppqpos, 
                          176,--integer chanmsg, 
                          channel,--integer chan, 
                          64, 
                          127)
    reaper.UpdateItemInProject(item)
  end
  
  main()
