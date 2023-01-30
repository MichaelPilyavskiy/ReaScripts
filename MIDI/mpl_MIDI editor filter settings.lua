-- @description MIDI editor filter settings
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @provides [main=main,midi_editor] .
-- @metapackage
-- @provides
--    [main] . > mpl_MIDI editor filter settings - toggle channel 1.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 2.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 3.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 4.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 5.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 6.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 7.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 8.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 9.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 10.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 11.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 12.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 13.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 14.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 15.lua
--    [main] . > mpl_MIDI editor filter settings - toggle channel 16.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 1.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 2.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 3.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 4.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 5.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 6.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 7.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 8.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 9.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 10.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 11.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 12.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 13.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 14.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 15.lua
--    [main] . > mpl_MIDI editor filter settings - draw events on channel 16.lua
-- @changelog
--    + init 

  
  function main(take,settings) 
    if not take then return end
    local item = GetMediaItemTake_Item( take )
    if not item then return end 
    local retval, str = reaper.GetItemStateChunk( item, '', false )
    local evtfilt = str:match('EVTFILTER.-\n')
     evtfilt_t = {} for val in evtfilt:gmatch('[^%s]+') do evtfilt_t[#evtfilt_t+1] = tonumber(val) or val end table.remove(evtfilt_t,1)
    
    if settings.toggle then -- toggle channel / all channels
      if settings.chan then if settings.chan >=1 and settings.chan<= 16 then evtfilt_t[1] = evtfilt_t[1]~(1<<(settings.chan-1)) end end
     elseif settings.draw then
      if settings.chan then if settings.chan >=1 and settings.chan<= 16 then 
        evtfilt_t[6] = settings.chan -1
        evtfilt_t[1] = evtfilt_t[1]|(1<<(settings.chan-1))
      end end
    end
    --if settings_t
    --[[
    //  field 1, int (16-bit mask), state of channel checkboxes
    //    0000000000000000 (0)     - "All" is checked, 1-16 unchecked
    //    1111111111111111 (65536) - "All" is checked along with 1-16
    //    1000000000000001 (32769) -  1 (LSB) and 16 (MSB) are selected
    //    etc.
    //  field 2, int, Event type
    //    -1  = <all>
    //    144 = Note
    //    160 = Poly Aftertouch
    //    176 = Control Change (CC)
    //    192 = Program Change (PC)
    //    208 = Channel Aftertouch
    //    224 = Pitch
    //    240 = Sysex/Meta
    //  field 3, int, parameter field (range: 0-127)
    //  field 4, int, value Low field (range: 0-127)
    //  field 5, int, value High field (range: 0-127)
    //  field 6, int, draw events on channel setting (range: 0-15)
    //  field 7, int (bool), enable filter
    ]]
    table.insert(evtfilt_t,1,'EVTFILTER')
    ouchunk = str:gsub(literalize(evtfilt),table.concat(evtfilt_t,' ')..'\n') 
    reaper.SetItemStateChunk( item, ouchunk, false )
  end
  ---------------------------------------------------------------------  
  function Parse_filename()
    local filename = ({reaper.get_action_context()})[2]
    local script_title = (GetShortSmplName(filename) or filename):gsub('%.lua','')
    
    script_title = [[mpl_MIDI editor filter settings - draw events on channel 11]]
    
    local script_title_out = script_title
    local script_title_short = script_title:match('mpl_MIDI editor filter settings %- (.*)') 
    
    if script_title_short:match('toggle channel %d+') then 
      local chan = script_title_short:match('toggle channel (%d+)') local chan = tonumber(chan)
      if chan then  return true, script_title_out, { toggle = true, chan = chan } end
     elseif script_title_short:match('draw events on channel %d+') then 
      local chan = script_title_short:match('draw events on channel (%d+)') local chan = tonumber(chan)
      if chan then  return true, script_title_out, { draw = true, chan = chan } end
    end
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.50) if ret then local ret2 = VF_CheckReaperVrs(6.37,true) if ret2 then 
    
    local ret, script_title_out, settings_t = Parse_filename()
    if not ret then return end
    
    Undo_BeginBlock2( 0 )
    local ME = reaper.MIDIEditor_GetActive()
    if ME then
      --take = reaper.MIDIEditor_GetTake(ME)
      for takeindex = 1, 100 do
        local take = MIDIEditor_EnumTakes( ME, takeindex-1, true) 
        if not take then break end
        main(take,settings_t) 
      end
     else
      for i = 1, CountSelectedMediaItems(0) do
        local item = GetSelectedMediaItem(0,i-1)
        local take = GetActiveTake(item) 
        if take then main(take,settings_t) end
      end
    end 
    Undo_EndBlock2( 0, script_title_out, 0xFFFFFFFF )
  end end