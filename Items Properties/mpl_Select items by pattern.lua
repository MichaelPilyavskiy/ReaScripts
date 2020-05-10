-- @description Select items by pattern
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

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
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_GetProjIDByPath') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then main() end
  end