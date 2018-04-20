-- @description Solo MIDI Editor active take track
-- @version 1.2
-- @author MPL 
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # changed to solo in place behaviour

  local scr_title = 'Solo MIDI Editor active take track'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 

----------------------------------------------------------
  function main()
    Undo_BeginBlock()
    local ME = MIDIEditor_GetActive()
    if not ME then return end
    local take = MIDIEditor_GetTake(ME)
    if not take then return end
    local take_track = GetMediaItemTake_Track(take)
    local is_solo = GetMediaTrackInfo_Value(take_track, 'I_SOLO')
    
    
    if is_solo == 1 or is_solo == 2 then 
      SetMediaTrackInfo_Value(take_track, 'I_SOLO',0)
      SetButtonOFF()
     else 
      SetButtonON()
      Main_OnCommand(40340,0) --Track: Unsolo all tracks
      SetMediaTrackInfo_Value(take_track, 'I_SOLO',2) 
    end
      
      -- deprecated//changed argument to 2 (solo in place)
    --[[local parent_track
    repeat  
      parent_track = GetParentTrack(take_track)
      if parent_track then
        SetMediaTrackInfo_Value(parent_track, 'I_SOLO', math.abs(is_solo-1))
        take_track = parent_track
      end
    until parent_track == nil ]]  
    Undo_EndBlock(scr_title, 1)
  end
----------------------------------------------------------
  -- http://github.com/ReaTeam/ReaScripts-Templates/blob/master/Templates/X-Raym_Background%20script.lua  
  
  -- Set ToolBar Button ON
  function SetButtonON()
    is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    state = reaper.GetToggleCommandStateEx( sec, cmd )
    reaper.SetToggleCommandState( sec, cmd, 1 ) -- Set ON
    reaper.RefreshToolbar2( sec, cmd )
  end
  
  -- Set ToolBar Button OFF
  function SetButtonOFF()
    is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    state = reaper.GetToggleCommandStateEx( sec, cmd )
    reaper.SetToggleCommandState( sec, cmd, 0 ) -- Set OFF
    reaper.RefreshToolbar2( sec, cmd )
  end
----------------------------------------------------------
  main()
