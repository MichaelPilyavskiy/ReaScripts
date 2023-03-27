-- @description Toggle solo focused FX track
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   # Use solo in place
  
  reaper.Undo_BeginBlock()
  local _, tracknumber = reaper.GetFocusedFX()
  local param = 'I_SOLO'
  if tracknumber >= 0 then 
    local tr =  reaper.CSurf_TrackFromID( tracknumber, false )
    local solo_state = reaper.GetMediaTrackInfo_Value( tr, param )
    local recarmstate = 0
    if solo_state > 0 then 
      solo_state = 0 
     else 
      solo_state = 2 
      recarmstate = 1
    end
    reaper.SetMediaTrackInfo_Value( tr, param, solo_state )
    reaper.SetMediaTrackInfo_Value( tr, 'I_RECARM', recarmstate )
    reaper.TrackList_AdjustWindows( false )
  end
  reaper.Undo_EndBlock('Toggle solo focused FX track', 0 )