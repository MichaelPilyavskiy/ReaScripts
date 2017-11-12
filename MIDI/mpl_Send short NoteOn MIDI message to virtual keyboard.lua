-- @description Send short NoteOn MIDI message to virtual keyboard
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   + init
-- @metapackage
-- @provides
--   [main] . > Send NoteOn to VK, pitch 48 C3.lua
--   [main] . > Send NoteOn to VK, pitch 49 C#3.lua
--   [main] . > Send NoteOn to VK, pitch 50 D3.lua
--   [main] . > Send NoteOn to VK, pitch 51 D#3.lua
--   [main] . > Send NoteOn to VK, pitch 52 E3.lua
--   [main] . > Send NoteOn to VK, pitch 53 F3.lua
--   [main] . > Send NoteOn to VK, pitch 54 F#3.lua
--   [main] . > Send NoteOn to VK, pitch 55 G3.lua
--   [main] . > Send NoteOn to VK, pitch 56 G#3.lua
--   [main] . > Send NoteOn to VK, pitch 57 A3.lua
--   [main] . > Send NoteOn to VK, pitch 58 A#3.lua
--   [main] . > Send NoteOn to VK, pitch 59 B3.lua
--   [main] . > Send NoteOn to VK, pitch 60 C4.lua
--   [main] . > Send NoteOn to VK, pitch 61 C#4.lua
--   [main] . > Send NoteOn to VK, pitch 62 D4.lua
--   [main] . > Send NoteOn to VK, pitch 63 D#4.lua
--   [main] . > Send NoteOn to VK, pitch 64 E4.lua
--   [main] . > Send NoteOn to VK, pitch 65 F4.lua
--   [main] . > Send NoteOn to VK, pitch 66 F#4.lua
--   [main] . > Send NoteOn to VK, pitch 67 G4.lua
--   [main] . > Send NoteOn to VK, pitch 68 G#4.lua
--   [main] . > Send NoteOn to VK, pitch 69 A4.lua
--   [main] . > Send NoteOn to VK, pitch 70 A#4.lua
--   [main] . > Send NoteOn to VK, pitch 71 B4.lua
--   [main] . > Send NoteOn to VK, pitch 72 C5.lua



local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local MIDIpitch = tonumber(name:match("pitch (%d+)"))
local MIDICh = 0
local velocity = 100
reaper.StuffMIDIMessage( 0, '0x9'..string.format("%x", MIDICh), MIDIpitch, velocity)

t0 = os.clock()
function run()
  t = os.clock()
  if t - t0 < 0.2 then reaper.defer(run) else   reaper.StuffMIDIMessage( 0, '0x8'..string.format("%x", MIDICh), MIDIpitch, velocity) end
end

run()