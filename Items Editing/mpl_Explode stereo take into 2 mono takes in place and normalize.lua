-- @description Explode stereo take into 2 mono takes in place and normalize
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


  local vrs = 'v1.0'
  
  --NOT gfx NOT reaper
  function main(item)
    if  CountTakes( item ) ~= 1 then return end
    local take = GetActiveTake(item)
    if not take then return end
    local pcm_src = GetMediaItemTake_Source( take )
    if not pcm_src then return end
    
    local new_take = AddTakeToMediaItem( item )
    SetMediaItemTake_Source( new_take, pcm_src )
    reaper.SetMediaItemInfo_Value( item,'B_ALLTAKESPLAY', 1 )
    SetMediaItemTakeInfo_Value( take, 'D_PAN', -1 )
    SetMediaItemTakeInfo_Value( take, 'I_CHANMODE', 3 ) 
    SetMediaItemTakeInfo_Value( new_take, 'D_PAN', 1 )
    SetMediaItemTakeInfo_Value( new_take, 'I_CHANMODE', 4 )
     
    Action(40289) -- Item: Unselect all items
    SetMediaItemInfo_Value( item, 'B_UISEL', 1 )
    SetActiveTake( take )
    Action(40108) -- normalize
    SetActiveTake( new_take )
    Action(40108) -- normalize
    
    UpdateItemInProject( item ) 
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then 
      Undo_BeginBlock() 
      local t = {} for selitem = 1,  reaper.CountSelectedMediaItems( 0 ) do t[#t+1] = reaper.GetSelectedMediaItem( 0, selitem-1 ) end
      for i= 1, #t do main(t[i]) end
      Undo_EndBlock('Explode stereo take into 2 mono takes in place and normalize', 4) 
    end
  end
  