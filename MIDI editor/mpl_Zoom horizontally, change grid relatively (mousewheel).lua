-- @description Zoom horizontally, change grid relatively (mousewheel) 
-- @version 1.0
-- @author MPL
-- @changelog
--    + init port from arrange
--    # clean script structure
-- @website http://forum.cockos.com/member.php?u=70694

  function main()
    local ME  = MIDIEditor_GetActive()
    if not ME then return end
    local take =  MIDIEditor_GetTake( ME )
    local _,_,_,_,_,_,mouse_scroll  = get_action_context() 
    if mouse_scroll > 0 then 
      VF_Action(1011, 32060, ME)
     elseif mouse_scroll < 0 and mouse_scroll ~= -1  then 
      VF_Action(1012, 32060, ME) 
    end
    
    local ret, Hzoom = VF2_GetMEZoom(take)
    if not ret then return end
    local grid_division, swing, noteLen = MIDI_GetGrid ( take )
    local is_triplet = ((1/grid_division)/3)%1==0
    local t = { 
                {0.02,1},
                {0.07,2},
                {0.15,4},  
                {0.4,8},
                {0.8,16},
                {2,32},
                {4,64},
                {8,128},
                {16,256},
                }
    for i = 1, #t-1 do
      local zoom, div = t[i][1],t[i][2]
      if Hzoom > t[i][1] and Hzoom < t[i+1][1] then
        SetMIDIEditorGrid( 0, 1/div)
        if is_triplet then VF_Action(41004, 32060, ME) end
        if swing ~= 0 then VF_Action(41006, 32060, ME) end
        break
      end
    end
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing. Install it via Reapack (Action: browse packages)', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF2_GetMEZoom') 
  if ret then 
    local ret2 = VF_CheckReaperVrs(5.975,true)    
    if ret2 then VF_LoadLibraries() reaper.defer(main) end
  end
  
  
