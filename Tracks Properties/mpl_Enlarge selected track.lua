-- @description Enlarge selected track
-- @version 1.03
-- @author mpl
-- @changelog
--    + toolbar indication / toggle state (X-Raym template used)
-- @website http://forum.cockos.com/member.php?u=70694

-- X-Raym template:
-- https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Templates/X-Raym_Background%20script.lua
--[[  changelog
  1.03 - 15.09.2016
    + toolbar indication / toggle state
  1.02 - 01.09.2016
    + init / recode from cubic13 idea
  ]]
--  original cubic13 idea http://forum.cockos.com/showthread.php?t=145949

  function EnlargeSelTrack()
    track = reaper.GetSelectedTrack(0, 0)
    if track then 
      track_guid = reaper.GetTrackGUID( track )
      if track then  
        if h_last and last_track_guid and last_track_guid ~= track_guid then 
          h_cur_last = reaper.GetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE")
          reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", h_last) 
          reaper.SetMixerScroll( track )
          if h_cur_last and last_track_guid then
            last_tr = reaper.BR_GetMediaTrackByGUID( 0, last_track_guid )
            if last_tr then reaper.SetMediaTrackInfo_Value(last_tr, "I_HEIGHTOVERRIDE", h_cur_last) end
          end
          reaper.TrackList_AdjustWindows( false )
          reaper.UpdateArrange()
        end
        h_cur = reaper.GetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE")
        h_last = h_cur
        last_track_guid = track_guid
      end
    end
    reaper.runloop(EnlargeSelTrack)
  end
  
  
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
  
  
  
  
  -- RUN
  SetButtonON()
  EnlargeSelTrack()
  reaper.atexit( SetButtonOFF )
