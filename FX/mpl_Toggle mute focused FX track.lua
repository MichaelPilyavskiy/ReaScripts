-- @description Toggle mute focused FX track
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init
  
  reaper.Undo_BeginBlock()
  local _, tracknumber = reaper.GetFocusedFX()
  local param = 'B_MUTE'
  if tracknumber >= 0 then 
    local tr =  reaper.CSurf_TrackFromID( tracknumber, false )
    local state = reaper.GetMediaTrackInfo_Value( tr, param )
    reaper.SetMediaTrackInfo_Value( tr, param, math.abs(state-1) )
    reaper.TrackList_AdjustWindows( false )
  end
  reaper.Undo_EndBlock('Toggle mute focused FX track', 0 )
