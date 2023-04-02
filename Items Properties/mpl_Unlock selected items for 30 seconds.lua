-- @description Unlock selected items for 30 seconds
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--  # update ReaPack header
--  # overall cleanup
--  # better handle item validation


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
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    item_t = {} -- table for selected items 
    TS0 = time_precise()
    unlock_item() 
    timer()
  end end