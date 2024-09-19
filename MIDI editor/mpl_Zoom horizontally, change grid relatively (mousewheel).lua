-- @description Zoom horizontally, change grid relatively (mousewheel) 
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  -------------------------------------------------------------------
    function VF2_GetMEZoom(take)
      local Hzoom
      if not take then return end
      local item =  GetMediaItemTake_Item( take )
      if not item then return end
      local _, chunk = reaper.GetItemStateChunk( item, "", false )
      
      local active_take
      for line in chunk:gmatch('[^\r\n]+') do
        if line:match('GUID (.*)') then 
           local testGUID = line:match('GUID (%{.*%})')--:gsub('[%{%}]','')
           local testtake = GetMediaItemTakeByGUID( 0, testGUID )
          if testtake and testtake == take then active_take = true end 
        end
        if active_take and line:match('CFGEDITVIEW') then 
          Hzoom = line:match('CFGEDITVIEW [%-%.%d]+ ([%-%.%d]+)')
          Hzoom=tonumber(Hzoom)
          if Hzoom then return true, Hzoom end
        end
      end
    end 
    ---------------------------------------------------
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
  ------------------------------------------------------------------------------------------------------
  function VF_Action(s, sectionID, ME )  
    if sectionID == 32060 and ME then 
      MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
     else
      Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
    end
  end  
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true) then reaper.defer(main) end
  
  