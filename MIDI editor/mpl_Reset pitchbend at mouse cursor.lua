-- @description Reset pitchbend under mouse cursor
-- @version 1.02
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # support REAPER 6.0+
--    # use raw MIDI evt addition
--    # change name


  function mpl_InsertMIDICC(take, ppqpos_add, bytestr)
    local tableEvents = {}
    local t = 0 -- Table key
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    local MIDIlen = MIDIstring:len()
    local stringPos = 1 -- Position inside MIDIstring while parsing
    local offset, flags, msg1
    ppqpos = 0
    while stringPos < MIDIlen-12 do -- -12 to exclude final All-Notes-Off message
      offset, flags, msg1, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
      t = t + 1
      tableEvents[t] = string.pack("i4Bs4", offset, flags, msg1)
      ppqpos = ppqpos + offset
    end
    --flag high 4 bits for CC shape: &16=linear, &32=slow start/end, &16|32=fast start, &64=fast end, &64|16=bezier
    tableEvents[#tableEvents+1] = string.pack("i4Bs4", math.floor(ppqpos_add - ppqpos), 16, bytestr)
                  
    MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
    MIDI_Sort(take) 
  end
  ---------------------------------------------------------------------
  function ResetPitchBend()
     _, segmentOut, _ =BR_GetMouseCursorContext()
    if segmentOut == 'cc_lane' then
      local midieditor =  MIDIEditor_GetActive()
      local take =  MIDIEditor_GetTake( midieditor )
      local projtime = BR_GetMouseCursorContext_Position()
      local ppqpos = MIDI_GetPPQPosFromProjTime( take, projtime ) 
      if ppqpos < 0 then return end
      local chan = reaper.MIDIEditor_GetSetting_int( midieditor, 'default_note_chan' )
      local pitchbend = 8192              
      local lane = 224
      local byte1 = lane + chan 
      local byte2 = pitchbend & 0x7F
      local byte3 = pitchbend >> 7
      local bytestr  = string.char(byte1,byte2,byte3)
      retval, inlineEditorOut, noteRowOut, ccLaneOut, ccLaneValOut, ccLaneIdOut = reaper.BR_GetMouseCursorContext_MIDI()
      if ccLaneOut and ccLaneOut == 513 then 
        mpl_InsertMIDICC(take, ppqpos, bytestr)
        --ret = MIDI_InsertCC( take, false, false, ppqpos, 0xB, chan, 64,pitchbend )
        --MIDI_InsertEvt( take, false, false, ppqpos, bytestr ) 
      end
    end
  end
  
  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret and VF_CheckReaperVrs(5.966,true) then 
    Undo_BeginBlock()
    ResetPitchBend()
    Undo_EndBlock( 'mpl_Reset pitchbend under mouse cursor', -1 )
  end  