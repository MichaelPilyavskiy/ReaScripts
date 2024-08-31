-- @description Select items by pattern
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
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
  ---------------------------------------------------
  function main()
    local retval, seq = GetUserInputs( 'Select items by pattern', 1, 'pattern (s=select, u=unselect)', 'ssss' )
    if retval then  
      item_ptrs = {} for selitem = 1,  CountSelectedMediaItems( 0 ) do item_ptrs[#item_ptrs+1] =  GetSelectedMediaItem( 0, selitem-1 ) end
      parsed_t = {} for char in seq:gmatch('%a') do local val = 0 if char=='s' then val = 1 end parsed_t[#parsed_t+1] = val end
      for i = 1, #item_ptrs do local ptid =1+(i-1)%#parsed_t if parsed_t[ptid] then SetMediaItemInfo_Value(item_ptrs[i], "B_UISEL",parsed_t[ptid]) end end
      UpdateArrange()
    end
  end
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true) then main() end