-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Stretch selected MIDI notes positions by x0.5
-- @changelog
--    + init

  x = 0.5
  local script_title = "Stretch selected MIDI notes positions by x0.5"
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end
  function StretchSelectedNotes()
    local midieditor =  MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  MIDIEditor_GetTake( midieditor )
    if not take or not TakeIsMIDI(take) then return end
    local t = {}
    local str = ""
    local cnt = 0
    for i = 1, ({MIDI_CountEvts( take )  })[2] do
      local temp_t = ({MIDI_GetNote( take, i-1 ) })
      if temp_t[2] then 
        cnt = cnt +1
        if cnt == 1 then strtppq = temp_t[4] end
        --reaper.ShowConsoleMsg(t[i][4])
        MIDI_SetNote( take, i-1, temp_t[2],--sel
                                          temp_t[3],--mutedInOptional, 
                                          math.floor((temp_t[4]-strtppq)*x+strtppq),--startppqposInOptional, 
                                          math.floor((temp_t[4]-strtppq)*x+strtppq+(temp_t[5]-temp_t[4])*x),--endppqposInOptional, 
                                          temp_t[6],--chanInOptional, 
                                          temp_t[7],--pitchInOptional, 
                                          temp_t[8],--velInOptional, 
                                          true)--noSortInOptional )
      end
    end     
    reaper.MIDI_Sort( take )   
  end  
  
  reaper.Undo_BeginBlock()
  StretchSelectedNotes()
  reaper.Undo_EndBlock(script_title, 0)