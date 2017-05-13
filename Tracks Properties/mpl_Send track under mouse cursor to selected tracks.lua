--[[
   * ReaScript Name: Send track under mouse cursor to selected tracks
   * Lua script for Cockos REAPER
   * Author: MPL
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
  script_title = "Send track under mouse cursor to selected tracks"
  
  function main()
  
    -- get source track
      window, segment, details = reaper.BR_GetMouseCursorContext()
      if segment == "track" then
        src_track = reaper.BR_GetMouseCursorContext_Track()
      end      
    
    track = reaper.GetSelectedTrack(0,0)
    if src_track == nil or track == nil then return end
    
    reaper.Undo_BeginBlock()
    
    -- get dest tracks
      count_tracks = reaper.CountSelectedTracks(0)
      if count_tracks ~= nil then
        for i = 1, count_tracks do
          track = reaper.GetSelectedTrack(0,i-1)
          if track ~= nil then
            reaper.SNM_AddReceive(src_track, track, -1)
          end
        end  
      end
      
    reaper.TrackList_AdjustWindows(false)
    reaper.Undo_EndBlock(script_title, 0)   
  end 

main()
