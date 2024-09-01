-- @description Set active take color darker
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
  
  function collim(val) return math.min(math.max(val, 0), 255) end
  function main()
    local it = reaper.GetSelectedMediaItem(0,0)
    if not it then return end
    tk = reaper.GetActiveTake(it)
    if not tk then return end
    local cust_col = reaper.GetMediaItemTakeInfo_Value( tk, 'I_CUSTOMCOLOR' )
     r, g, b = reaper.ColorFromNative( cust_col )
    local diff = 5
    reaper.SetMediaItemTakeInfo_Value( tk, 'I_CUSTOMCOLOR' , reaper.ColorToNative(collim( r-diff), collim(g-diff), collim(b-diff) )|0x1000000)
    reaper.UpdateItemInProject( it )
  end
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true) then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Set active take color darker', 0 )
  end