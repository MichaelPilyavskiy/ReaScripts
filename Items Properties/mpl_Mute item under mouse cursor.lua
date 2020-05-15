-- @description Mute item under mouse cursor
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
     
  --NOT gfx NOT reaper
  
--------------------------------------------------------------------
  function main()
    local item = VF_GetItemTakeUnderMouseCursor()
    if not item then return end
    SetMediaItemInfo_Value( item, 'B_MUTE' ,1 )
    UpdateItemInProject( item )
  end
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_GetProjIDByPath') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then     
      reaper.Undo_BeginBlock() 
      main()
      reaper.Undo_EndBlock("Mute item under mouse cursor", 0)
    end
  end