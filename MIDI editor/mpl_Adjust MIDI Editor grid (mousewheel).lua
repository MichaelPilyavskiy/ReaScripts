-- @description Adjust MIDI Editor grid (mousewheel) 
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # limit maximum to 1
 
  function main()
    local ME= reaper.MIDIEditor_GetActive()
    if not ME then return end
    local take =  reaper.MIDIEditor_GetTake( ME )
    if not take then return end
    local grid = reaper.MIDI_GetGrid( take ) / 4
    local _,_,_,_,_,_,mouse_scroll  = reaper.get_action_context()
    local dir = (mouse_scroll/math.abs(mouse_scroll))
    local out = grid*0.5^dir
    if out >= 1/128 and out <= 1 then
      reaper.SetMIDIEditorGrid( 0,out  )
    end
  end
  
  
  reaper.defer(main)