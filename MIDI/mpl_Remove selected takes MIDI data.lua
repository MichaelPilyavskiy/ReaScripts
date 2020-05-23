-- @description Remove selected takes MIDI data
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix ppq convertion
--    # fix script names for proper reapack indexing
-- @metapackage
-- @provides
--    [main] . > mpl_Remove selected takes all MIDI data except notes.lua
--    [main] . > mpl_Remove selected takes ProgramChange.lua
--    [main] . > mpl_Remove selected takes AfterTouch.lua
--    [main] . > mpl_Remove selected takes PitchWheel.lua
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


  local vrs = 'v1.01'
  
  --NOT gfx NOT reaper
  
  
  local s_unpack = string.unpack
  local s_pack = string.pack
  --------------------------------------------------------------------
  function ParseScriptname()
    local fname = ({reaper.get_action_context()})[2]
    local scr_title = GetShortSmplName(fname:gsub('.lua', '')) 
    local exclude_msg_byte1 = 0xB
    local exclude_msg_byte2 = nil
    if scr_title:match('CC') then 
      exclude_msg_byte1 = 0xB 
      if scr_title:match('CC%d+') then exclude_msg_byte2 = tonumber(scr_title:match('CC(%d+)')) end
     elseif scr_title:match('ProgramChange') then 
      exclude_msg_byte1 = 0xC
     elseif scr_title:match('AfterTouch') then 
      exclude_msg_byte1 = 0xD      
     elseif scr_title:match('PitchWheel') then 
      exclude_msg_byte1 = 0xE
     elseif scr_title:match('Remove selected takes all MIDI data except notes') then
      leave_notes_only = true
    end  
    return exclude_msg_byte1, exclude_msg_byte2, leave_notes_only, scr_title
  end
  --------------------------------------------------------------------
  function RemoveMIDIdata(exclude_msg_byte1, exclude_msg_byte2) 
    local timesel_cond = true
    local ts_start, ts_end = reaper.GetSet_LoopTimeRange2( 0, false, 0, -1, -1, false )
    if math.abs(ts_end - ts_start) < 0.001 then timesel_cond = false end
    for i = 1 , CountSelectedMediaItems(0) do
      local item = GetSelectedMediaItem(0,i-1)
      local take = GetActiveTake(item)
      if TakeIsMIDI(take) then 
        local tableEvents = {}
        local idx = 0 -- Table key
        local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
        local MIDIlen = MIDIstring:len()
        local stringPos = 1 -- Position inside MIDIstring while parsing
        local offset, flags, msg1
        local ppqpos = 0
        while stringPos < MIDIlen-12 do -- -12 to exclude final All-Notes-Off message
          offset, flags, msg1, stringPos = s_unpack("i4Bs4", MIDIstring, stringPos)
          ppqpos = ppqpos + offset
          if msg1:len() > 1 
            and ( (not leave_notes_only 
                    and msg1:byte(1)>>4 == exclude_msg_byte1 
                    and (not exclude_msg_byte2 or exclude_msg_byte2 and msg1:byte(2) == exclude_msg_byte2)
                   )
                  or 
                   (leave_notes_only == true and not (msg1:byte(1)>>4 == 0x9 or msg1:byte(1)>>4 == 0x8) )
                ) then
            
            local msg_pos = MIDI_GetProjTimeFromPPQPos( take, ppqpos )
            if timesel_cond == false or (timesel_cond == true and msg_pos > ts_start and msg_pos < ts_end) then msg1 = '' end
          end
          idx = idx + 1
          tableEvents[idx] = s_pack("i4Bs4", offset, flags, msg1)
        end 
        MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
        MIDI_Sort(take)    
      end
    end
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then 
       exclude_msg_byte1, exclude_msg_byte2, leave_notes_only, scr_title = ParseScriptname()
      Undo_BeginBlock() 
      RemoveMIDIdata(exclude_msg_byte1, exclude_msg_byte2, leave_notes_only) 
      Undo_EndBlock(scr_title, 4) 
    end
  end
  