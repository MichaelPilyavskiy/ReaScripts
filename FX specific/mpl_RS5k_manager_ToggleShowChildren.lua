-- @description RS5k_manager_ToggleShowChildren
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @noindex
-- @changelog
--    + init



-- toggle show TC/MCP state of rs5k children
function main()
  local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
  local laststate = reaper.GetToggleCommandStateEx( sec, cmd )
  if laststate == -1 then laststate = 1 end
  reaper.SetToggleCommandState( sec, cmd, laststate~1 ) 
  reaper.RefreshToolbar2( sec, cmd ) 
  for i = 1, reaper.CountTracks(-1) do
    local track = reaper.GetTrack(-1,i-1)
    local ret, TYPE_REGCHILD =    reaper.GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_TYPE_REGCHILD', 0, false)    TYPE_REGCHILD = (tonumber(TYPE_REGCHILD) or 0)==1
    local ret, TYPE_DEVICE = reaper.GetSetMediaTrackInfo_String( track, 'P_EXT:MPLRS5KMAN_TYPE_DEVICE', 0, false) TYPE_DEVICE = (tonumber(TYPE_DEVICE) or 0)==1
    if TYPE_REGCHILD or TYPE_DEVICE then 
      reaper.SetMediaTrackInfo_Value( track, 'B_SHOWINMIXER', laststate~1 )
      reaper.SetMediaTrackInfo_Value( track, 'B_SHOWINTCP', laststate~1 )
    end
  end
  reaper.TrackList_AdjustWindows( false )
end

main()
