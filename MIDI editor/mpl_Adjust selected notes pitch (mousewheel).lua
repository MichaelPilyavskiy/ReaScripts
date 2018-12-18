-- @description Adjust selected notes pitch (mousewheel)
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  function MoveNotesVertically(take, dir)
    local dir_int = 1
    if dir then dir_int = -1 end
    local tableEvents = {}
    local t = 0
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    local MIDIlen = MIDIstring:len()
    local stringPos = 1
    local offset, flags, msg
                
    while stringPos < MIDIlen-12 do
      offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
      out_val = msg:byte(2)
      if msg:len() > 1 and ( msg:byte(1)>>4 == 0x9 or msg:byte(1)>>4 == 0x8 ) and flags&1==1 then  out_val = math.max(0,math.min(msg:byte(2)  - dir_int,127)) end
      t = t + 1
      tableEvents[t] = string.pack("i4Bi4BBB", offset, flags, 3, msg:byte(1), out_val, msg:byte(3) )
    end
                
    MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
    MIDI_Sort(take)    
  end
  
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  -------------------------------------------------------------------------  
  function main(dir)
    if val == 0 then return end
    local midieditor = MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  MIDIEditor_GetTake( midieditor )
    if not take then return end
    Undo_BeginBlock()  
    MoveNotesVertically(take, val>0)
    Undo_EndBlock('mpl_Adjust selected notes pitch (mousewheel)', 1)  
  end  
  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then 
    is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
    if is_new_value then     main(val) end
  end
    
  