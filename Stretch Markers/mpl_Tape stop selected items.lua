-- @description Tape stop selected items
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
 
  function main(item)
    -- get data
      local it_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local it_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local take = GetActiveTake(item)
      if not take or (take and TakeIsMIDI(take)) then return end
      local src= GetMediaItemTake_Source( take )
      local src_len = GetMediaSourceLength( src )
      local rate  = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
      local stoffst  = GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
    
    -- remove alll markers
      DeleteTakeStretchMarkers( take, 0, GetTakeNumStretchMarkers( take ))
      stid = SetTakeStretchMarker( take, -1, 0, 0 )
      endid = SetTakeStretchMarker( take, -1, it_len*rate, it_len*rate )
    
    if stid and endid then 
      SetTakeStretchMarkerSlope( take, stid,-0.99/rate )
      SetMediaItemInfo_Value( item, 'D_LENGTH', it_len*2 )
      SetMediaItemTakeInfo_Value( take, 'D_PLAYRATE',rate/2)
    end 
    
    UpdateItemInProject( item )
  end  
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.973) then 
    Undo_BeginBlock2( 0 )
    for i=1, CountSelectedMediaItems(0) do
      local it =  GetSelectedMediaItem(0,i-1)
      main(it) 
    end
    UpdateArrange()
    Undo_EndBlock2( 0, 'Tape stop selected items', -1 )
  end