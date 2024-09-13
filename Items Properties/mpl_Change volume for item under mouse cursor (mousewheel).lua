-- @description Change volume for item under mouse cursor (mousewheel)
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF imndependent
     
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
      
      local incr = 0.1 -- dB
      
       item = VF_GetItemTakeUnderMouseCursor()
      if not item then return end
      
      local it_vol = GetMediaItemInfo_Value( item, 'D_VOL' )
      local it_vol_db = WDL_VAL2DB(it_vol)
      local it_vol_out = math.max(WDL_DB2VAL(it_vol_db + val*incr),0)
      SetMediaItemInfo_Value( item, 'D_VOL' ,it_vol_out )
      UpdateItemInProject( item )
    end
      function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    ------------------------------------------------------------------------------------------------------
    function WDL_VAL2DB(x, reduce)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
      if not x or x < 0.0000000298023223876953125 then return -150.0 end
      local v=math.log(x)*8.6858896380650365530225783783321
      if v<-150.0 then return -150.0 else 
        if reduce then 
          return string.format('%.2f', v)
         else 
          return v 
        end
      end
    end
  ------------------------------------------------------------------------------------------------------
  function VF_lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
--------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.95,true) then 
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock("Change volume for item under mouse cursor", 0)
  end     