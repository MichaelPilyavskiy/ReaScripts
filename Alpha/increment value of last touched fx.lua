n = 0.01 -- set to -0.01 or something for decrement
retval, trackid, fxid, paramid = reaper.GetLastTouchedFX()
if retval ~= nil then
track = reaper.GetTrack(0, trackid-1)
value = reaper.TrackFX_GetParamNormalized(track, fxid, paramid)
newval = value + n
reaper.TrackFX_SetParamNormalized(track, fxid, paramid, newval) 
end
