-- @description Change volume for item under mouse cursor (mousewheel)
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # update for use with REAPER 5.981+
     
  --NOT gfx NOT reaper
  
--------------------------------------------------------------------
  function main()
    local is_new_value,filename,sectionID,cmdID,mode,resolution,val = get_action_context()
    if val == 0 or not is_new_value then return end
    if val > 0 then val = 1 else val = -1 end
    
    local incr = 0.1 -- dB
    
     item = VF_GetItemTakeUnderMouseCursor()
    if not item then return end
    
    local it_vol = GetMediaItemInfo_Value( item, 'D_VOL' )
    local it_vol_db = WDL_VAL2DB(it_vol)
    local it_vol_out = math.max(WDL_DB2VAL(it_vol_db + val*incr),0)
    SetMediaItemInfo_Value( item, 'D_VOL' ,it_vol_out )
    UpdateItemInProject( item )
  end
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end

--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_GetItemTakeUnderMouseCursor') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then 
    script_title = "Change volume for item under mouse cursor"
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock(script_title, 0)
  end   
