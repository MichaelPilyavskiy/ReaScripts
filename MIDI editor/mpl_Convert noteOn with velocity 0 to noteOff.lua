-- @description Convert noteOn with velocity 0 to noteOff
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335  
-- @metapackage
-- @provides
--    [main=midi_editor] . > mpl_Convert noteOn with velocity 0 to noteOff.lua
-- @changelog
--    # VF independent

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
  end
  --------------------------------------------------------------------  
  ----------------------------------------------------------------------      
  function ConvertNoteOntNoteOffNotes(take)
    local tableEvents = {}
    local t = 0
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    local MIDIlen = MIDIstring:len()
    local stringPos = 1
    local offset, flags, msg
    while stringPos < MIDIlen-12 do
      offset, flags, msg1, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos) 
        
      local msgtype = msg1:byte(1)&0xF0
      local chan = msg1:byte(1)&0xF
      if msgtype == 0x90 and msg1:byte(3) == 0 then 
        msgtype = 0x80
      end
      t = t + 1
      tableEvents[t] = string.pack("i4Bi4BBB", offset, flags, 3, msgtype|chan, msg1:byte(2), msg1:byte(3) )
    end
    
    MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
    MIDI_Sort(take)
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true) then 
    
    local midieditor = MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  MIDIEditor_GetTake( midieditor )
    if not take then return end
    Undo_BeginBlock()  
    ConvertNoteOntNoteOffNotes(take)
    Undo_EndBlock('Convert noteOn with velocity 0 to noteOff', 4)  
    
  end 