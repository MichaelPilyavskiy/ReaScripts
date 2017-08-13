-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Stretch selected MIDI notes positions by custom x
-- @changelog
--    + init

  local script_title = "Stretch selected MIDI notes positions by custom x"  
  for key in pairs(reaper) do _G[key]=reaper[key]  end
  
  function StretchSelectedNotes(f)    
    local midieditor =  MIDIEditor_GetActive()
    if not midieditor then return end
    local take =  MIDIEditor_GetTake( midieditor )
    if not take or not TakeIsMIDI(take) then return end
    local t = {}
    local str = ""
    local id = 0
    for i = 1, ({MIDI_CountEvts( take )  })[2] do
      local temp_t = ({MIDI_GetNote( take, i-1 ) })
      if temp_t[2] then 
        id = id +1
        if id == 1 then strtppq = temp_t[4] end
        --reaper.ShowConsoleMsg(t[i][4])
        MIDI_SetNote( take, i-1, temp_t[2],--sel
                                          temp_t[3],--mutedInOptional, 
                                          math.floor(f(temp_t[4]-strtppq,id)+strtppq),--startppqposInOptional, 
                                          math.floor(f(temp_t[4]-strtppq,id)+strtppq+f(temp_t[5]-temp_t[4]),id),--endppqposInOptional, 
                                          temp_t[6],--chanInOptional, 
                                          temp_t[7],--pitchInOptional, 
                                          temp_t[8],--velInOptional, 
                                          true)--noSortInOptional )
      end
    end     
    reaper.MIDI_Sort( take )   
  end  
  ---------------------------------------------------------------------
  function main()
    local retval, str_user_input = GetUserInputs( 'mpl_Stretch selected MIDI notes', 1, '', '*2' )
    if retval then 
      -- form function
        local func
        if not str_user_input:match('[%d%.]+') or not tonumber(str_user_input:match('[%d%.]+')) then return end -- if not contain number
        if str_user_input:match('/')or str_user_input:match('*') then 
          func = load("local x = ... id = ... return x"..str_user_input)
         else 
          func = load("local x = ... return x*"..tonumber(str_user_input:match('[%d%.]+'))) 
        end
        if not func then return end
        local test_ret = func(1,1)
        if not test_ret then return end
        Undo_BeginBlock()
        StretchSelectedNotes(func)
        Undo_EndBlock(script_title, 0)
    end
  end
  
  main()
  