-- @description Remove selected takes MIDI data
-- @version 1.11
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @metapackage
-- @provides
--    [main] . > mpl_Remove selected takes all MIDI data except notes.lua
--    [main] . > mpl_Remove selected takes ProgramChange.lua
--    [main] . > mpl_Remove selected takes AfterTouch.lua
--    [main] . > mpl_Remove selected takes PitchWheel.lua
--    [main] . > mpl_Remove selected takes TextEvents.lua
--    [main] . > mpl_Remove selected takes MIDI CC data.lua
--    [main] . > mpl_Remove selected takes MIDI CC0 Bank Select (MSB).lua
--    [main] . > mpl_Remove selected takes MIDI CC1 Modulation Wheel.lua
--    [main] . > mpl_Remove selected takes MIDI CC2 Breath controller.lua
--    [main] . > mpl_Remove selected takes MIDI CC4 Foot Pedal (MSB).lua
--    [main] . > mpl_Remove selected takes MIDI CC5 Portamento Time (MSB).lua
--    [main] . > mpl_Remove selected takes MIDI CC6 Data Entry (MSB).lua
--    [main] . > mpl_Remove selected takes MIDI CC7 Volume (MSB).lua
--    [main] . > mpl_Remove selected takes MIDI CC8 Balance (MSB).lua
--    [main] . > mpl_Remove selected takes MIDI CC10 Pan position (MSB).lua
--    [main] . > mpl_Remove selected takes MIDI CC11 Expression (MSB).lua
--    [main] . > mpl_Remove selected takes MIDI CC64 Hold Pedal.lua
--    [main] . > mpl_Remove selected takes MIDI CC65 Portamento.lua
--    [main] . > mpl_Remove selected takes MIDI CC66 Sostenuto Pedal.lua
--    [main] . > mpl_Remove selected takes MIDI CC67 Soft Pedal.lua
--    [main] . > mpl_Remove selected takes MIDI CC68 Legato Pedal.lua
--    [main] . > mpl_Remove selected takes MIDI CC69 Hold 2 Pedal.lua
--    [main] . > mpl_Remove selected takes MIDI CC70 Sound Variation.lua
--    [main] . > mpl_Remove selected takes MIDI CC71 Resonance (Timbre).lua
--    [main] . > mpl_Remove selected takes MIDI CC72 Sound Release Time.lua
--    [main] . > mpl_Remove selected takes MIDI CC73 Sound Attack Time.lua
--    [main] . > mpl_Remove selected takes MIDI CC74 Frequency Cutoff (Brightness).lua
--    [main] . > mpl_Remove selected takes MIDI CC80 Decay.lua
--    [main] . > mpl_Remove selected takes MIDI CC81 Hi Pass Filter Frequency.lua
--    [main] . > mpl_Remove selected takes MIDI CC84 Portamento Amount.lua
--    [main] . > mpl_Remove selected takes MIDI CC91 Reverb Level.lua
--    [main] . > mpl_Remove selected takes MIDI CC92 Tremolo Level.lua
--    [main] . > mpl_Remove selected takes MIDI CC93 Chorus Level.lua
--    [main] . > mpl_Remove selected takes MIDI CC94 Detune Level.lua
--    [main] . > mpl_Remove selected takes MIDI CC95 Phaser Level.lua
--    [main] . > mpl_Remove selected takes MIDI CC120 All Sound Off.lua
--    [main] . > mpl_Remove selected takes MIDI CC121 All Controllers Off.lua
--    [main] . > mpl_Remove selected takes MIDI CC122 Local Keyboard.lua
--    [main] . > mpl_Remove selected takes MIDI CC123 All Notes Off.lua
--    [main] . > mpl_Remove selected takes MIDI CC124 Omni Mode Off.lua
--    [main] . > mpl_Remove selected takes MIDI CC125 Omni Mode On.lua
--    [main] . > mpl_Remove selected takes MIDI CC126 Mono Operation.lua
--    [main] . > mpl_Remove selected takes MIDI CC127 Poly Mode.lua
-- @changelog
--    # fix refresh arrange for non-in-project MIDI source
--    # add text events removing support
--    # fix special events remove for more than 3-byte messages (ex. ProgramChange)

  --NOT gfx NOT reaper
  
  
  local s_unpack = string.unpack
  local s_pack = string.pack
  --------------------------------------------------------------------
  function ParseScriptname()
    local fname = ({reaper.get_action_context()})[2]
    --local scr_title = 'mpl_Remove selected takes TextEvents'
    local scr_title = GetShortSmplName(fname:gsub('.lua', '')) 
    local exclude_msg_byte1 = 0xB
    local exclude_msg_byte2 = nil
    local leave_notes_only = false
    if scr_title:match('CC') then 
      exclude_msg_byte1 = 0xB 
      if scr_title:match('CC%d+') then exclude_msg_byte2 = tonumber(scr_title:match('CC(%d+)')) end
     elseif scr_title:match('ProgramChange') then 
      exclude_msg_byte1 = 0xC
     elseif scr_title:match('AfterTouch') then 
      exclude_msg_byte1 = 0xD      
     elseif scr_title:match('PitchWheel') then 
      exclude_msg_byte1 = 0xE
     elseif scr_title:match('TextEvents') then       
      exclude_msg_byte1 = 0xFF
      exclude_msg_byte2 = 0x06
     elseif scr_title:match('Remove selected takes all MIDI data except notes') then
      leave_notes_only = true
    end  
    return exclude_msg_byte1, exclude_msg_byte2, leave_notes_only, scr_title
  end
  --------------------------------------------------------------------
  function GetTruePPQLen(MIDIstring, MIDIlen)
    local stringPos = 1 
    local ppqpos = 0
    local ppqlen = 0
    local offset, flags, msg1
    while stringPos < MIDIlen do -- -12 to exclude final All-Notes-Off message
      offset, flags, msg1, stringPos = s_unpack("i4Bs4", MIDIstring, stringPos)
      ppqpos = ppqpos + offset 
      ppqlen = math.max(ppqlen,ppqpos)
    end 
    return ppqlen
  end
  --------------------------------------------------------------------
  function RemoveMIDIdata(exclude_msg_byte1, exclude_msg_byte2,leave_notes_only) 
    -- check time selection
      local ts_start, ts_end = reaper.GetSet_LoopTimeRange2( 0, false, 0, -1, -1, false )
      local timesel_cond = math.abs(ts_end - ts_start) > 0.001
      
    for i = 1 , CountSelectedMediaItems(0) do
      local item = GetSelectedMediaItem(0,i-1) 
      
      -- timesel outside item edges
        local item_pos =  GetMediaItemInfo_Value( item, 'D_POSITION' )
        local item_len =  GetMediaItemInfo_Value( item, 'D_LENGTH' ) 
        if timesel_cond == true and ts_start > item_pos + item_len then goto skipnextitem end
        if timesel_cond == true and ts_end < item_pos then goto skipnextitem end
      
      local take = GetActiveTake(item)
      if TakeIsMIDI(take) then RemoveMIDIdata_take(exclude_msg_byte1, exclude_msg_byte2,leave_notes_only, take, math.max(ts_start,item_pos),  math.min(ts_end,item_pos+item_len), timesel_cond, item_pos+item_len)  end
      ::skipnextitem::
    end
    
    UpdateArrange()
    
  end
  --------------------------------------------------------------------
  function RemoveMIDIdata_take_msgmod(msg1, ppqpos, leave_notes_only, exclude_msg_byte1, exclude_msg_byte2, timesel_cond, area_start, area_end, area_start2, area_end2)
    if msg1:len() ==3 then 
      local ALL_CC_REMOVE = leave_notes_only == true and not (msg1:byte(1)>>4 == 0x9 or msg1:byte(1)>>4 == 0x8)
      local SPEC_REMOVE = leave_notes_only == false and msg1:byte(1)>>4 == exclude_msg_byte1 and not exclude_msg_byte2
      local SPEC_CC_REMOVE = leave_notes_only == false and msg1:byte(1)>>4 == exclude_msg_byte1 and exclude_msg_byte2 and msg1:byte(2) == exclude_msg_byte2 
      local TIMESEL = timesel_cond == true and ((ppqpos >= area_start and ppqpos <= area_end) or (ppqpos >= area_start2 and ppqpos <= area_end2) )
      if (ALL_CC_REMOVE==true or SPEC_REMOVE==true or SPEC_CC_REMOVE==true) and (TIMESEL==true or timesel_cond == false) then msg1 = '' end
      return msg1
     else 
      local SPEC_REMOVE = msg1:byte(1)>>4 == exclude_msg_byte1
      local TXTEVT = msg1:byte(1) == exclude_msg_byte1 and exclude_msg_byte2 and msg1:byte(2) == exclude_msg_byte2
      local TIMESEL = timesel_cond == true and ((ppqpos >= area_start and ppqpos <= area_end) or (ppqpos >= area_start2 and ppqpos <= area_end2) )
      if (TXTEVT==true or SPEC_REMOVE==true) and (TIMESEL or timesel_cond == false) then  msg1 = '' end
      return msg1 
    end
  end
  --------------------------------------------------------------------
  function RemoveMIDIdata_take(exclude_msg_byte1, exclude_msg_byte2,leave_notes_only, take, ts_start, ts_end, timesel_cond, item_end)  
    -- init MIDI data
      local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
      local MIDIlen = MIDIstring:len()
      local offset, flags, msg1
      local ppqpos = 0 
      
    -- get PPQ area to check
       ppq_len = GetTruePPQLen(MIDIstring, MIDIlen) 
      local cross = false
      local ts_startppq = MIDI_GetPPQPosFromProjTime( take, ts_start )
      local ts_endppq = math.min(MIDI_GetPPQPosFromProjTime( take, ts_end ) , MIDI_GetPPQPosFromProjTime( take, item_end ))
      local iter1 = math.floor(ts_startppq / ppq_len) 
      local iter2 = math.floor(ts_endppq / ppq_len)
      local ppq_offs = iter1 * ppq_len
       area_start = ts_startppq - ppq_offs
       area_end = ts_endppq - ppq_len*iter2--math.min(area_start + (ts_endppq - ts_startppq), ppq_len) 
       area_start2 = area_start
       area_end2 = area_end
      if iter1 ~= iter2 then
        cross = true
        area_start = 0
        area_end = ts_endppq - ppq_len*iter2
        area_start2 = ts_startppq - ppq_offs
        area_end2 = ppq_len
      end
      
    -- put data iunto table
       evts = {}
      local i = 1
      local offset0
      local stringPos = 1 -- Position inside MIDIstring while parsing
      while stringPos < MIDIlen do
        offset, flags, msg1, stringPos = s_unpack("i4Bs4", MIDIstring, stringPos)
        if offset0 then offset = offset + offset0 offset0 =nil end
        if offset < 0 then offset0 = offset goto skipevt end
        ppqpos = ppqpos + offset
        evts[i] = {offset=offset, flags=flags, msg1=msg1, stringPos=stringPos,ppqpos=ppqpos}
        i = i+1
        ::skipevt::
      end
    
    -- loop evts
      local tableEvents = {}
      local idx = 1 -- Table key
      for i =1, #evts-1 do
        offset, flags, msg1,ppqpos = evts[i].offset, evts[i].flags, evts[i].msg1,evts[i].ppqpos
        msg1 = RemoveMIDIdata_take_msgmod(msg1, ppqpos, leave_notes_only, exclude_msg_byte1, exclude_msg_byte2, timesel_cond, area_start, area_end, area_start2, area_end2)
        tableEvents[idx] = s_pack("i4Bs4", offset, flags, msg1)
        idx = idx + 1
      end    
    
    -- store into take
      MIDI_SetAllEvts(take, table.concat(tableEvents)..s_pack("i4Bs4", evts[#evts].offset, evts[#evts].flags, evts[#evts].msg1))
      MIDI_Sort(take)   
  end

  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs) 
    local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' 
    if  reaper.file_exists( SEfunc_path ) then
      dofile(SEfunc_path) 
      if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end  
     else 
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) 
      if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end
    end   
  end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.5) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then 
      local exclude_msg_byte1, exclude_msg_byte2, leave_notes_only, scr_title = ParseScriptname()
      Undo_BeginBlock() 
      RemoveMIDIdata(exclude_msg_byte1, exclude_msg_byte2, leave_notes_only) 
      Undo_EndBlock(scr_title, -1)  
  end end
  