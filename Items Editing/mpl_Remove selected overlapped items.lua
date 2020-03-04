-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Remove selected overlapped items
-- @changelog
--    # correct algorithm

  
  function main()
    local t = {}
    for i = 1, reaper.CountSelectedMediaItems(0) do
      local item = reaper.GetSelectedMediaItem( 0, i-1 )      
      local pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
      local len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
      t[#t+1] = {pos=pos,
                end_pos = pos+len,
                guid = reaper.BR_GetMediaItemGUID( item )}
    end
    
    ittoremove = {}
    for i = 1, #t do
      if t[i] then
        local pos_cur = t[i].pos
        local end_pos_cur = t[i].end_pos
        for j = 1, #t do
          if t[j] and j ~= i then
            local pos_check = t[j].pos
            local end_pos_check = t[j].end_pos
            if HasCross(pos_cur,end_pos_cur,pos_check,end_pos_check) then
              ittoremove[#ittoremove+1] = t[j].guid
              t[j] = nil
            end
          end
        end
      end
    end
    
    for i = 1, #ittoremove do
      local item = reaper.BR_GetMediaItemByGUID( 0, ittoremove[i] )
      if item then reaper.DeleteTrackMediaItem(  reaper.GetMediaItem_Track( item ), item ) end
    end
    
    reaper.UpdateArrange()
  end
  
  function HasCross(p1,p2, p3, p4)
    if  (p1<=p3 and p2>=p3) or 
        (p1<=p4 and p2>=p4) or 
        (p1>p3 and p2<p4) or
        (p1<p3 and p2>p4) then
      return true
    end
  end
  
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock("Remove selected overlapped items", 0)