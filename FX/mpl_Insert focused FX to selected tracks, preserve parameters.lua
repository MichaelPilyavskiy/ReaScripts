-- @version 1.0
-- @author MPL
-- @changelog
--   + init release
-- @description Insert focused FX to selected tracks, preserve parameters
-- @website http://forum.cockos.com/member.php?u=70694
  
  function main()
    ret, tracknumber, _, fxnumberOut = reaper.GetFocusedFX()
    if ret == 0 then return end
    local track = reaper.CSurf_TrackFromID(tracknumber, false)
    _, fxname = reaper.TrackFX_GetFXName( track, fxnumberOut, '' )
    
    local parm_t = {}
    for i = 1, reaper.TrackFX_GetNumParams( track, fxnumberOut ) do
      local val = reaper.TrackFX_GetParam( track, fxnumberOut, i-1 )
      parm_t[#parm_t+1] = val
    end
    
    if fxname:find('/') then 
      fxname = fxname:reverse()
      fxname = fxname:sub(0,fxname:find('/') - 1)
      fxname = fxname:reverse()
     else
      fxname = fxname:match('%:.+'):sub(3)
    end
    
    for sel_tr = 1,  reaper.CountSelectedTracks( 0 ) do
      sel_track = reaper.GetSelectedTrack( 0, sel_tr-1 )
      if sel_track ~= track then 
        new_fx_id = reaper.TrackFX_AddByName( sel_track, fxname, false, -1 ) 
        for i = 1, reaper.TrackFX_GetNumParams( sel_track, new_fx_id ) do        
          reaper.TrackFX_SetParam( sel_track, new_fx_id, i-1, parm_t[i] )
        end        
      end
    end
  end
  
  main()
