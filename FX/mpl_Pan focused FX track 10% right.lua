-- @description Pan focused FX track 10% right
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init

  function F_limit(val,min,max)
    if val < min then return min end
    if val > max then return max end
    return val
  end   
    
  reaper.Undo_BeginBlock()
  local _, tracknumber = reaper.GetFocusedFX()
  local param = 'D_PAN'
  if tracknumber >= 0 then 
    local tr =  reaper.CSurf_TrackFromID( tracknumber, false )
    local val = reaper.GetMediaTrackInfo_Value( tr, param )    
    reaper.SetMediaTrackInfo_Value( tr, param,  F_limit(val + 0.1,-1,1) )
    reaper.TrackList_AdjustWindows( false )
  end
  reaper.Undo_EndBlock('Pan focused FX track 10% right', 0 )
  
