-- @version 1.0
-- @author MPL
-- @changelog
--   + init
-- @description Convert selected looped items to multiple splits
-- @website http://forum.cockos.com/member.php?u=70694


  function ConvLoopToSplit(item)
    -- get item/take/src info
    if not item then return end
    local take = reaper.GetActiveTake(item)
    local src = reaper.GetMediaItemTake_Source( take )
    local src_len, IsQN = reaper.GetMediaSourceLength( src )
    local it = {pos =   reaper.GetMediaItemInfo_Value( item, 'D_POSITION' ),
          pos_end =   reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )+reaper.GetMediaItemInfo_Value( item, 'D_POSITION' ),
          rate = reaper.GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' ),
          s_offs = reaper.GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
            }    
    
    -- split if MIDI take
    if IsQN then      
      local src_start = it.pos-it.s_offs/it.rate
      local src_start_QN = reaper.TimeMap2_timeToQN( 0, src_start )      
      local split_pos_QN = src_start_QN
      local new_item = item
      while reaper.TimeMap2_QNToTime( 0, split_pos_QN ) < it.pos_end do        
        split_pos_QN = split_pos_QN + src_len/it.rate
        local split_pos = reaper.TimeMap2_QNToTime( 0, split_pos_QN )
        if split_pos > it.pos and split_pos < it.pos_end then new_item = reaper.SplitMediaItem( new_item, split_pos )  end
      end 
     else
      local src_start = it.pos-it.s_offs/it.rate   
      local split_pos = src_start
      local new_item = item
      while split_pos < it.pos_end do        
        split_pos = split_pos + src_len/it.rate
        if split_pos > it.pos and split_pos < it.pos_end then new_item = reaper.SplitMediaItem( new_item, split_pos )  end
      end 
    end
    
    -- update GUI
    reaper.UpdateArrange()
  end
  
  reaper.Undo_BeginBlock()
  t = {}
  for i = 1, reaper.CountSelectedMediaItems(0) do t[#t+1] = reaper.GetSelectedMediaItem(0,i-1) end
  for i = 1, #t do ConvLoopToSplit(t[i]) end
  reaper.Undo_EndBlock("Convert selected looped items to multiple splits", 0) 