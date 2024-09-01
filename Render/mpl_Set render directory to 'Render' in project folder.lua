-- @description Set render directory to 'Render' in project folder
-- @version 1.01
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
 
  -------------------
  function main()
    local pr_path = GetProjectPathEx( 0, '' )
    GetSetProjectInfo_String(0, 'RENDER_FILE', pr_path..'/Render', true)
  end  
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.973)then main() end