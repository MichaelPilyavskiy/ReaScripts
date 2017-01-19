-- @description Toggle solo focused FX track
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init
  
  reaper.Undo_BeginBlock()
  local _, tracknumber = reaper.GetFocusedFX()
  local param = 'I_SOLO'
  if tracknumber >= 0 then 
    local tr =  reaper.CSurf_TrackFromID( tracknumber, false )
    local solo_state = reaper.GetMediaTrackInfo_Value( tr, param )
    reaper.SetMediaTrackInfo_Value( tr, param, math.abs(solo_state-1) )
    reaper.TrackList_AdjustWindows( false )
  end
  reaper.Undo_EndBlock('Toggle solo focused FX track', 0 )
