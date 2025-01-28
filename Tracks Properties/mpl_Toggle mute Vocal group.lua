-- @description Toggle mute Vocal group
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=207971
-- @about Toggle mute group tracks which contain "vocal" in their name
-- @changelog
--    + init


function main()
  for i = 1, reaper.CountTracks(-1) do
    local tr = reaper.GetTrack(-1,i-1)
    local ret, trname = reaper.GetTrackName(tr)
    local depth = reaper.GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' )
    if trname:lower():match('vocal') and depth == 1 then
      local B_MUTE = reaper.GetMediaTrackInfo_Value( tr, 'B_MUTE' )
      reaper.SetMediaTrackInfo_Value( tr, 'B_MUTE',B_MUTE~1 )
    end
  end 
  reaper.UpdateArrange()
end

reaper.Undo_BeginBlock2(-1)
main()
reaper.Undo_EndBlock2(-1, 'Toggle mute Vocal group', 0xFFFFFFFF)
