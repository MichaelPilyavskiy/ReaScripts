-- @description Pan focused FX track at center
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init  
    
  reaper.Undo_BeginBlock()
  local _, tracknumber = reaper.GetFocusedFX()
  local param = 'D_PAN'
  if tracknumber >= 0 then 
    local tr =  reaper.CSurf_TrackFromID( tracknumber, false )
    reaper.SetMediaTrackInfo_Value( tr, param,  0 )
    reaper.TrackList_AdjustWindows( false )
  end
  reaper.Undo_EndBlock('Pan focused FX track at center', 0 )
  
