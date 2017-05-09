-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Apply FX without sends, offline FX
-- @changelog
--    # prevent overlap with last item or itself
  
  function ApplyFX()
    item = reaper.GetSelectedMediaItem(0,0) 
    if not item then return end
    tr = reaper.GetMediaItem_Track( item )
    if not tr then return end
    reaper.SetOnlyTrackSelected( tr )
    
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_MUTESENDS'), 0) -- SWS: Mute all sends from selected track(s)
    reaper.Main_OnCommand(40209,0 ) -- Item: Apply track/take FX to items
    reaper.Main_OnCommand(40535,0 ) -- Track: Set all FX offline for selected tracks
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_UNMUTESENDS'), 0)
  end
  
  ApplyFX()
