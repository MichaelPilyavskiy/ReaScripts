-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description Generate reabank from focused FX
-- @website http://forum.cockos.com/member.php?u=70694

  
  function main()  
    -- get fx info
      local _, track_id, _, fx_id = reaper.GetFocusedFX()
      if not track_id or not fx_id then return end
      if track_id == 0 then track =  reaper.GetMasterTrack( 0 )
        else track = reaper.CSurf_TrackFromID( track_id, false )  end
      if not track then return end
      _, fx_name = reaper.TrackFX_GetFXName(track, fx_id, '')
      fx_name = fx_name:sub(fx_name:find('[%:]+')+2, -1):match('[%a]+')
    
    -- save def preset / get count presets in dropdown menu
      cur_preset_id, numberOfPresets = reaper.TrackFX_GetPresetIndex(track, fx_id)
    
    -- form header
    com = 
[[
// .reabank bank/program (patch) information
// A bank entry lists the MSB, LSB, and bank name
// for all the patches that follow, until the next bank entry.

]]..
        
'Bank 0 0 '..fx_name..' 001-'..numberOfPresets..'\n'
        
    reaper.TrackFX_SetPresetByIndex(track, fx_id , 0)
    for k = 1, numberOfPresets do
      _, presetname = reaper.TrackFX_GetPreset(track, fx_id, '')
      com = com..'\n'..(k-1)..' '..presetname
      reaper.TrackFX_NavigatePresets(track, fx_id, 1)
    end
    
    -- restore preset
      reaper.TrackFX_SetPresetByIndex(track,fx_id , cur_preset_id)
    return com   
  end
  
  
  ret = reaper.MB('Depending on plugin and number of presets this action can take a few seconds to execute. Continue?', 
  'mpl Generate reabank from focused  FX', 4)
  if ret == 6 then
    com_string = main()
    reaper.ClearConsole()
    reaper.ShowConsoleMsg(com_string)
  end
