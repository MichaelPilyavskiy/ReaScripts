-- @description Remove selected takes MIDI PitchWheel
-- @about
--    code snippets based on juliansader work https://forum.cockos.com/member.php?u=14710
-- @version 1.0
-- @author juliansader, MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


  exclude_msg_type = 0xE -- PitchWheel
  local scr_title = 'Remove selected takes MIDI PitchWheel'
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end   
  -------------------------------------------------------------------------
  function FilterMIDIData(take, exclude_msg_type)
    local tableEvents = {}
    local t = 0 -- Table key
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    local MIDIlen = MIDIstring:len()
    local stringPos = 1 -- Position inside MIDIstring while parsing
    local offset, flags, msg
                
    while stringPos < MIDIlen-12 do -- -12 to exclude final All-Notes-Off message
      offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
      if msg:len() > 1 then
        if msg:byte(1)>>4 == exclude_msg_type then
          msg = "" -- (MPL: leave as an dummy event for to not brake offsets )
        end
      end
      t = t + 1
      tableEvents[t] = string.pack("i4Bs4", offset, flags, msg)
    end
                
    MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
    MIDI_Sort(take)    
  end
  
  
  -------------------------------------------------------------------------  
  Undo_BeginBlock()  
  for i = 1 , CountSelectedMediaItems(0) do
    local item = GetSelectedMediaItem(0,i-1)
    local take = GetActiveTake(item)
    if TakeIsMIDI(take) then 
      FilterMIDIData(take, exclude_msg_type)
    end
  end
  Undo_EndBlock(scr_title, 1)    
  
