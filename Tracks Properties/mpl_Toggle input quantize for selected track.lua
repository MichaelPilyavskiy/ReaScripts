  --[[
     * ReaScript Name: Toggle input quantize for selected track
     * Lua script for Cockos REAPER
     * Author: MPL
     * Author URI: http://forum.cockos.com/member.php?u=70694
     * Licence: GPL v3
     * Version: 1.0
    ]]
    
    
    _,_,sectionID,cmdID = reaper.get_action_context()
  
  function main () local track, state, chunk
    track = reaper.GetSelectedTrack(0,0)
    if track == nil then return end
    _, chunk = reaper.GetTrackStateChunk(track, "")
    if chunk:find('INQ 1 ') ~= nil then 
      chunk = chunk:gsub('INQ 1 ', 'INQ 0 ')
      reaper.SetToggleCommandState(sectionID, cmdID, 0)
      state = false
     else
      chunk = chunk:gsub('INQ 0 ', 'INQ 1 ')
      reaper.SetToggleCommandState(sectionID, cmdID, 1)
      state = true
    end
    reaper.SetTrackStateChunk(track, chunk)
    --reaper.MB(chunk, '', 0)
    return state
  end
  
  reaper.Undo_BeginBlock()
  state = main()
  if state then
    script_title = 'Turn on input quantize for selected track'
   else
    script_title = 'Turn off input quantize for selected track'
  end
  reaper.Undo_EndBlock(script_title, 0)
