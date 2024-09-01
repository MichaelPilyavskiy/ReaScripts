-- @description Set render directory to desktop
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

 
  function GetDesktopPath() --https://forums.coronalabs.com/topic/59382-system-directories-on-windows-builds/
    if GetOS():lower():match('win') then 
      local desktopPath = os.getenv("appdata")
      local appDataStart = string.find( desktopPath, "AppData" )
      if( appDataStart ) then
         desktopPath = string.sub( desktopPath, 1, appDataStart-1 )
         desktopPath = desktopPath .. "Desktop\\"
      end
      return true, desktopPath
    end
    
    if GetOS():lower():match('mac') then 
      local desktopPath = os.getenv("HOME")..'/Desktop'
      return true, desktopPath
    end
    
  end
  -------------------
  function main()
    local ret, desktopPath = GetDesktopPath()
    if ret then reaper.GetSetProjectInfo_String(0, 'RENDER_FILE', desktopPath, true) end
  end  
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.973) then main() end