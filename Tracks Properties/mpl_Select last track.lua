-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Select last track
-- @changelog
--    + init

    tr = reaper.GetTrack(0,reaper.CountTracks(0)-1)
    if tr then reaper.SetOnlyTrackSelected( tr ) end