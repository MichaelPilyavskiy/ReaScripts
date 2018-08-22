-- @description Smart duplicate events
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix maxppq var miss

-----------------------------------------------------------------------------------------  
  function SmartDuplicateNotes()
    local  ME = MIDIEditor_GetActive()
    if not ME then return end
    local take = MIDIEditor_GetTake(ME)
    if not take then return end
    local data = ParseRAWMIDI(take)
    local item = GetMediaItemTake_Item( take )
    local item_pos =  GetMediaItemInfo_Value( item, 'D_POSITION')
     ret, ppq_shift = CalcShift(item, item_pos, take, data)
    if not ret then return end
     extendMIDI, noteoff_ppq = AddShiftedSelectedEvents(take, data, ppq_shift )
    if extendMIDI then
      local start_qn =  TimeMap2_timeToQN( 0, item_pos )
      local end_qn =  reaper.MIDI_GetProjQNFromPPQPos( take, noteoff_ppq )
      MIDI_SetItemExtents(item, start_qn, end_qn)
    end
  end
-----------------------------------------------------------------------------------------  
  function ParseRAWMIDI(take)
      local data = {}
      local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
      if not gotAllOK then return end
      local s_unpack = string.unpack
      local s_pack   = string.pack
      local MIDIlen = MIDIstring:len()
      local idx = 0    
      local offset, flags, msg1
      local ppq_pos = 0
      local nextPos, prevPos = 1, 1 
      while nextPos <= MIDIlen do 
          
          prevPos = nextPos
          offset, flags, msg1, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
          idx = idx + 1
          ppq_pos = ppq_pos + offset
          data[idx] = {rawevt = s_pack("i4Bs4", offset, flags , msg1),
                            offset=offset, 
                            flags=flags, 
                            selected =flags&1==1,
                            muted =flags&2==2,
                            msg1=msg1,
                            ppq_pos = ppq_pos,
                            isNoteOn =msg1:byte(1)>>4 == 0x9,
                            isNoteOff =msg1:byte(1)>>4 == 0x8,
                            isCC = msg1:byte(1)>>4 == 0xB,
                            chan = 1+(msg1:byte(1)&0xF),
                            vel=vel}


      end
      return data
  end
----------------------------------------------------------------------------------------- 
  function CalcShift(item, item_pos, take, data)
    local min_ppq, max_ppq
    for i =1, #data do
      if data[i].selected and not min_ppq then min_ppq = data[i].ppq_pos end
      if data[i].selected                 then max_ppq = data[i].ppq_pos end      
    end
    if not max_ppq or not min_ppq then return end
    local ppq_dif = max_ppq - min_ppq    
    local time_dif = MIDI_GetProjTimeFromPPQPos(take, ppq_dif) - item_pos
    local retval, measures, cml = TimeMap2_timeToBeats(0, time_dif)
    local time_of_measure = TimeMap2_beatsToTime(0, 0, 1)
    local measure_ppq = MIDI_GetPPQPosFromProjTime(take, time_of_measure+ item_pos)
    local ppq_shift = measure_ppq * (measures+1) 
    return true, math.floor(ppq_shift)
  end
-----------------------------------------------------------------------------------------  
  function AddShiftedSelectedEvents(take, data, ppq_shift )
    local str = ''
    local last_ppq
    for i = 1, #data-1 do      
      local flag
      if data[i].flags&1==1 then flag = data[i].flags-1 else flag = data[i].flags end
      local str_per_msg = string.pack("i4Bs4", data[i].offset, flag , data[i].msg1)
      str = str..str_per_msg
      last_ppq = data[i].ppq_pos
    end
    
    for i = 1, #data-1 do   
      if data[i].selected then
        local new_ppq = data[i].ppq_pos + ppq_shift
        local str_per_msg = string.pack("i4Bs4", new_ppq-last_ppq, data[i].flags , data[i].msg1)
        str = str..str_per_msg
        last_ppq = new_ppq
      end
    end
    
    local noteoffoffs = data[#data].ppq_pos -last_ppq
    if data[#data].ppq_pos < last_ppq then noteoffoffs = 1 end
    str = str.. string.pack("i4Bs4", noteoffoffs, data[#data].flags , data[#data].msg1)
    MIDI_SetAllEvts(take, str) 
    
    if data[#data].ppq_pos < last_ppq then return true, noteoffoffs + last_ppq  end
  end
  
-----------------------------------------------------------------------------------------  
    function CheckFunctions(str_func)
      local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
      local f = io.open(SEfunc_path, 'r')
      if f then
        f:close()
        dofile(SEfunc_path)
        
        if not _G[str_func] then 
          reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
         else
          Undo_BeginBlock2( 0 )
          SmartDuplicateNotes()
          Undo_EndBlock( 'Smart duplicate notes', -1 )
        end        
       else
        reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
      end  
    end
  --------------------------------------------------------------------
  CheckFunctions('SetFXName')    
  
  
  
