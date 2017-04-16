-- @version 1.1
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Smart duplicate items
-- @changelog
--    # recoded to lua
--    # proper area checking
--    # calc nudge value in measures, ignore overlap with last item
--    + overlap checking

  function SmartDuplicateItems() 
    if reaper.CountSelectedMediaItems(0) < 1 then return end
    local t = {}
    local area_min = math.huge
    local area_max = 0
    for i = 1, reaper.CountSelectedMediaItems(0) do
      local item = reaper.GetSelectedMediaItem( 0, i-1 )  
      local pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
      local len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )    
      t[#t+1] = {pos=pos,len=len, guid = reaper.BR_GetMediaItemGUID( item )}
      area_min = math.min(area_min,pos )
      area_max = math.max(area_max, pos+len)
    end
    
    meas = ({ reaper.TimeMap2_timeToBeats( 0, area_max - area_min)})[2]
    
    reaper.ApplyNudge( 0, --project, 
                        0,--nudgeflag, 
                        5,--nudgewhat, 
                        16,--nudgeunits, 
                        meas, --value, 
                        0,--reverse, 
                        1)--copies )
    t = nil
    -- check for overlap
      t = {}
      for i = 1, reaper.CountMediaItems(0) do
        local item = reaper.GetMediaItem( 0, i-1 )
        t[#t+1]={guid = reaper.BR_GetMediaItemGUID( item ), 
                  pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' ),
                  sel =  reaper.IsMediaItemSelected( item )}
      end      
      for i = 1, #t do
        if t[i] and t[i].sel then 
          for j = 1, #t do
            if t[j] and j~=i then
              if math.abs(t[j].pos - t[i].pos) < 0.001 then
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
SmartDuplicateItems()
reaper.Undo_EndBlock("Smart duplicate items", 0)