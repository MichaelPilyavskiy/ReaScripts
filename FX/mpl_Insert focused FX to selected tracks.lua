-- @version 1.0
-- @author MPL
-- @changelog
--   + init release
-- @description Insert focused FX to selected tracks
-- @website http://forum.cockos.com/member.php?u=70694
  
  function main()
    local ret, tracknumber, _, fxnumberOut = reaper.GetFocusedFX()
    if ret == 0 then return end
    local track = reaper.CSurf_TrackFromID(tracknumber, false)
    local _, fxname = reaper.TrackFX_GetFXName( track, fxnumberOut, '' )
    
    if fxname:find('/') then 
      fxname = fxname:reverse()
      fxname = fxname:sub(0,fxname:find('/') - 1)
      fxname = fxname:reverse()
     else
      fxname = fxname:match('%:.+'):sub(3)
    end
    
    for sel_tr = 1,  reaper.CountSelectedTracks( 0 ) do
      sel_track = reaper.GetSelectedTrack( 0, sel_tr-1 )
      if sel_track ~= track then reaper.TrackFX_AddByName( sel_track, fxname, false, -1 ) end
    end
  end
  
  main()
