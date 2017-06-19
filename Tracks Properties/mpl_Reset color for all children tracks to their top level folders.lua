-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description Reset color for all children tracks to their top level folders
-- @website http://forum.cockos.com/member.php?u=70694

  for key in pairs(reaper) do _G[key]=reaper[key]  end  
  
  function main()
    for i = 1, CountTracks() do
      tr = GetTrack(0, i-1)
      depth = GetTrackDepth(tr)
      if depth == 0 then 
        col = GetTrackColor( tr )
       else
        reaper.SetMediaTrackInfo_Value( tr, 'I_CUSTOMCOLOR', col )
      end
    end
  end
  
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock("Reset color for all children tracks to their top level folders", 0) 
  