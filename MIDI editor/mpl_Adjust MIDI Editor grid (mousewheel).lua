-- @description Adjust MIDI Editor grid (mousewheel) 
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # change name
--   # invert adjusting [p=2282406]
 
  function msg(s) reaper.ShowConsoleMsg(s..'\n')end
  function main()
    local ME= reaper.MIDIEditor_GetActive()
    if not ME then return end
    local take =  reaper.MIDIEditor_GetTake( ME )
    if not take then return end
    local grid = reaper.MIDI_GetGrid( take ) / 4
    local _,_,_,_,_,_,mouse_scroll  = reaper.get_action_context()
    local dir = (mouse_scroll/math.abs(mouse_scroll))
    local out = grid*0.5^dir
    if out >= 1/128 and out <= 8 then
      reaper.SetMIDIEditorGrid( 0,out  )
    end
  end
  
  
  reaper.defer(main)