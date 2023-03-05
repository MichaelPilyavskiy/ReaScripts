-- @description Convert noteOn with velocity 0 to noteOff
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335  
-- @metapackage
-- @provides
--    [main=midi_editor] . > mpl_Convert noteOn with velocity 0 to noteOff.lua
-- @changelog
--    + init
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
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  -------------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.18) if ret then local ret2 = VF_CheckReaperVrs(5.95,true) if ret2 then 
    
    local midieditor = MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  MIDIEditor_GetTake( midieditor )
    if not take then return end
    Undo_BeginBlock()  
    ConvertNoteOntNoteOffNotes(take)
    Undo_EndBlock('Convert noteOn with velocity 0 to noteOff', 4)  
    
  end end