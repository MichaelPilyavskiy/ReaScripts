-- @description Unlock selected items for 30 seconds
-- @version 1.02
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


  time = 30 -- time in seconds you need for pause 
  ----------------------------------------------------------------------
  function unlock_item() -- store item_t table
    for i = 1, CountSelectedMediaItems(0) do
      local item = GetSelectedMediaItem(0, i-1)
      SetMediaItemInfo_Value(item, "C_LOCK", 0)
      UpdateItemInProject(item)
      local retval, itGUID = GetSetMediaItemInfo_String( item, 'GUID', '', 0 )
      item_t[#item_t+1] = itGUID
    end 
  end
  ----------------------------------------------------------------------
  function timer() if time_precise() - TS0 < time then defer(timer) else atexit(lock_item) end end
  ----------------------------------------------------------------------
  function lock_item() 
    for i = 1, #item_t do
      local item = VF_GetMediaItemByGUID(0,item_t[i]) -- get item from table    
      if ValidatePtr(item, 'MediaItem*') then
        --SetMediaItemInfo_Value(item, "B_UISEL", 1)
        SetMediaItemInfo_Value(item, "C_LOCK", 1)
        UpdateItemInProject(item)
      end
    end  
  end
  ---------------------------------------------------------------------
  function VF_GetMediaItemByGUID(optional_proj, itemGUID)
    local optional_proj0 = optional_proj or 0
    local itemCount = CountMediaItems(optional_proj);
    for i = 1, itemCount do
      local item = GetMediaItem(0, i-1);
      local retval, stringNeedBig = GetSetMediaItemInfo_String(item, "GUID", '', false)
      if stringNeedBig  == itemGUID then return item end
    end
  end  
  if VF_CheckReaperVrs(6.78,true)  then 
    item_t = {} -- table for selected items 
    TS0 = time_precise()
    unlock_item() 
    timer()
  end