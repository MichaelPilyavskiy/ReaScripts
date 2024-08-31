-- @description Change pan for item under mouse cursor active take (mousewheel)
-- @version 1.03
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
     
  --NOT gfx NOT reaper
  ------------------------------------------------------------------------------------------------------
  function VF_GetItemTakeUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local item , take = reaper.GetItemFromPoint( screen_x, screen_y, true )
    return item , take
  end
--------------------------------------------------------------------
  function main()
    local is_new_value,filename,sectionID,cmdID,mode,resolution,val = get_action_context()
    if val == 0 or not is_new_value then return end
    if val > 0 then val = 1 else val = -1 end
    
    local incr = 0.05
    
     item = VF_GetItemTakeUnderMouseCursor()
    if not item then return end
    
    local take = GetActiveTake(item)
    if not take then return end
    local tkpan = GetMediaItemTakeInfo_Value( take, 'D_PAN' )
    local tkpan_out = lim(tkpan + val*incr,-1,1)
    SetMediaItemTakeInfo_Value( take, 'D_PAN', tkpan_out )
    UpdateItemInProject( item )
  end
--------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.95,true) then 
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock("Change pan for item under mouse cursor", 0)
  end   
