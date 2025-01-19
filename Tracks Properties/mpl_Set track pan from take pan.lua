-- @description Set track pan from take pan
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--    + init

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  
  function main()
    for itidx = 1, CountMediaItems(-1) do
      local item = reaper.GetMediaItem(-1,itidx-1)
      if IsMediaItemSelected(item) then 
        local take = GetActiveTake( item )
        if take and not TakeIsMIDI( take ) then 
          local D_PAN = GetMediaItemTakeInfo_Value( take, 'D_PAN' )
          --local I_CHANMODE = GetMediaItemTakeInfo_Value( take, 'I_CHANMODE' )
          
          --if I_CHANMODE >=2 then
            local tr = GetMediaItemTake_Track( take )
            SetMediaTrackInfo_Value( tr, 'D_PAN', D_PAN )
            SetMediaItemTakeInfo_Value( take, 'D_PAN',0 )
          --end
        end
      end
    end
  end
  
  Undo_BeginBlock2( -1 )
  main()
  Undo_EndBlock2( -1, 'Set take pan to parent track pan', 0xFFFFFFFF )