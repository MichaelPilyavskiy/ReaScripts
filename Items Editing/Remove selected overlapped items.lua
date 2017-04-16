-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Remove selected overlapped items
-- @changelog
--    + init

  
  function main()
    local t = {}
    for i = 1, reaper.CountSelectedMediaItems(0) do
      local item = reaper.GetSelectedMediaItem( 0, i-1 )      
      t[#t+1] = {pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' ),
                guid = reaper.BR_GetMediaItemGUID( item )}
    end
    
    for i = 1, #t do
      if t[i] then
        local pos_cur = t[i].pos
        for j = 1, #t do
          if t[j] and j ~= i then
            local pos_check = t[j].pos
            if math.abs(pos_check-pos_cur) < 0.001 then
              local item = reaper.BR_GetMediaItemByGUID( 0, t[j].guid )
              if item then reaper.DeleteTrackMediaItem(  reaper.GetMediaItem_Track( item ), item ) end
              t[j] = nil
            end
          end
        end
      end
    end
    
    reaper.UpdateArrange()
  end
  
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock("Remove selected overlapped items", 0)