-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Fit selected notes to MIDI item edges
-- @changelog
--    + init

  local script_title = "Fit selected notes to MIDI item edges"
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end
  function StretchSelectedNotes()
    local midieditor =  MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  MIDIEditor_GetTake( midieditor )
    local item =  GetMediaItemTake_Item( take )
    e_item = GetMediaItemInfo_Value( item, 'D_POSITION' )+GetMediaItemInfo_Value( item, 'D_LENGTH' )
    end_ppq = MIDI_GetPPQPosFromProjTime( take, e_item )
    if not take or not TakeIsMIDI(take) then return end
    for i = 1, ({MIDI_CountEvts( take )  })[2] do
      local temp_t = ({MIDI_GetNote( take, i-1 ) })
      if temp_t[2] then 
        MIDI_SetNote( take, i-1, temp_t[2],--sel
                                          temp_t[3],--mutedInOptional, 
                                          0,--startppqposInOptional, 
                                          end_ppq,--endppqposInOptional, 
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