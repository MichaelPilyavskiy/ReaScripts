-- @version 1.0
-- @author mpl
-- @changelog
--   + init release

--[[
   * ReaScript Name: Toggle auto add last touched parameter to TCP
   * Lua script for Cockos REAPER
   * Author: Michael Pilyavskiy (mpl)
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
  ]]
  
  
  function Add_parameter_to_track_controls(tracknumber, fxnumber, paramnumber)
    track = reaper.GetTrack(0, tracknumber -1)
    if track == nil then return end
    reaper.SNM_AddTCPFXParm(track, fxnumber, paramnumber) 
  end
  
  ----------------------------------------------------------
  
  function run()
    _, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()    
    if last_tracknumber ~= nil then      
      if last_tracknumber ~= tracknumber
        or last_fxnumber ~= fxnumber
        or last_paramnumber ~= paramnumber then
          Add_parameter_to_track_controls(tracknumber, fxnumber, paramnumber)
      end
    end
    
    last_tracknumber = tracknumber
    last_fxnumber = fxnumber
    last_paramnumber = paramnumber
    
    reaper.defer(run)
  end
    
  ----------------------------------------------------------
  -- thanks to X-Raym for background script template:
  -- https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Templates/X-Raym_Background%20script.lua
  
  function SetButtonON()
    is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    state = reaper.GetToggleCommandStateEx( sec, cmd )
    reaper.SetToggleCommandState( sec, cmd, 1 ) -- Set ON
    reaper.RefreshToolbar2( sec, cmd )
  end
  
  function SetButtonOFF()
    is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
    state = reaper.GetToggleCommandStateEx( sec, cmd )
    reaper.SetToggleCommandState( sec, cmd, 0 ) -- Set OFF
    reaper.RefreshToolbar2( sec, cmd )
  end
  
  SetButtonON()
  run()
  reaper.atexit( SetButtonOFF )
