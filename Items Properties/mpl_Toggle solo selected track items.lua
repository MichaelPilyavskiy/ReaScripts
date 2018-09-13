-- @description Toggle solo selected track items
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

 function SoloItem()
    local item = reaper.GetSelectedMediaItem(0,0)
    if not item then return end
    local par_tr = reaper.GetMediaItem_Track( item )
    local cnt_trit = reaper.CountTrackMediaItems( par_tr )
    local mute_cnt= 0
    for itemidx = 1,  cnt_trit do
      local trit_ptr = reaper.GetTrackMediaItem( par_tr, itemidx-1 )
      local mute = reaper.GetMediaItemInfo_Value( trit_ptr, 'B_MUTE' )==0
      if not mute then mute_cnt = mute_cnt + 1 end
    end
    for itemidx = 1,  cnt_trit do
      local trit_ptr = reaper.GetTrackMediaItem( par_tr, itemidx-1 )
      if mute_cnt == 0 then state =  math.abs(1-reaper.GetMediaItemInfo_Value( trit_ptr, 'B_UISEL')) else state = 0 end
      reaper.SetMediaItemInfo_Value( trit_ptr, 'B_MUTE', state )
    end
    reaper.UpdateArrange()
  end
    
  SoloItem()