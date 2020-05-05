-- @description Tape start selected items
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
 
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
      SetTakeStretchMarkerSlope( take, stid,0.99/rate )
      SetMediaItemInfo_Value( item, 'D_LENGTH', it_len*2 )
      SetMediaItemTakeInfo_Value( take, 'D_PLAYRATE',rate/2)
    end 
    
    UpdateItemInProject( item )
  end  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
-------------------------------------------------------------------- 
  local ret, ret2 = CheckFunctions('VF_CheckReaperVrs') 
  if ret then ret2 = VF_CheckReaperVrs(5.973) end
  if ret and ret2 then 
    Undo_BeginBlock2( 0 )
    for i=1, CountSelectedMediaItems(0) do
      local it =  GetSelectedMediaItem(0,i-1)
      main(it) 
    end
    UpdateArrange()
    Undo_EndBlock2( 0, 'Tape start selected items', -1 )
  end