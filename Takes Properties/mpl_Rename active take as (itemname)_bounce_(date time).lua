-- @description Rename active take as (itemname)_bounce_(date time)
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

  function main()
    local it = GetSelectedMediaItem(0,0)
    if not it then return end
    tk = GetActiveTake(it)
    if not tk then return end
    local retval, takename = reaper.GetSetMediaItemTakeInfo_String( tk, 'P_NAME', '', 0 )
    takename = takename:gsub('render ', '')
    local new_name = takename..'_bounce_'..os.date()
    GetSetMediaItemTakeInfo_String( tk, 'P_NAME', new_name, 1)
  end
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true) then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Rename active take as (itemname)_bounce_(date time)', 0 )
  end
  