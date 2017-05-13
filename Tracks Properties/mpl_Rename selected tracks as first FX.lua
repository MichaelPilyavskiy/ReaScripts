--[[
   * ReaScript Name: Rename selected tracks as first FX
   * Lua script for Cockos REAPER
   * Author: MPL
   * Author URI: http://forum.cockos.com/member.php?u=70694
   * Licence: GPL v3
   * Version: 1.0
  ]]

script_title = "Rename selected tracks as first FX"
  
  reaper.Undo_BeginBlock()
  
  count_tracks = reaper.CountSelectedTracks(0)
       
  if  count_tracks ~= nil then
    for i = 1, count_tracks do
      track = reaper.GetSelectedTrack(0,i-1)
      if track ~= nil then
        fx_count =  reaper.TrackFX_GetCount(track)
        if fx_count >= 1 then
          retval, fx_name =  reaper.TrackFX_GetFXName(track, 0, '')
          fx_name_cut = fx_name:match('[%:].*'):sub(3)
          reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', fx_name_cut, true)
        end
      end
    end
  end     
      
      
reaper.UpdateArrange()
reaper.Undo_EndBlock(script_title, 0)
