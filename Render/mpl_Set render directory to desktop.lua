-- @description Set render directory to desktop
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @provides [windows] .
-- @changelog
--    # change header
 
  function GetDesktopPath() --https://forums.coronalabs.com/topic/59382-system-directories-on-windows-builds/
    local desktopPath = os.getenv("appdata")
    local appDataStart = string.find( desktopPath, "AppData" )
    if( appDataStart ) then
       desktopPath = string.sub( desktopPath, 1, appDataStart-1 )
       desktopPath = desktopPath .. "Desktop\\"
    end
    return true, desktopPath
  end
  -------------------
  function main()
    local ret, desktopPath = GetDesktopPath()
    if ret and GetOS():match('Win') then reaper.GetSetProjectInfo_String(0, 'RENDER_FILE', desktopPath, true) end
  end  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
-------------------------------------------------------------------- 
  local ret, ret2 = CheckFunctions('VF_CheckReaperVrs') 
  if ret then ret2 = VF_CheckReaperVrs(5.973) end
  if ret and ret2 then main() end