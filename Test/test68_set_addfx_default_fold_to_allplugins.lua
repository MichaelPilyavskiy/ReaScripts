-- ok for unknown reason this returns err value:
 -- string = reaper.SNM_GetIntConfigVar("lastview", 222)
 -- reaper.ShowConsoleMsg(string)
 
 -- this returns right value
 -- retval, string = reaper.BR_Win32_GetPrivateProfileString("REAPER-fxadd", "lastview", "0", reaper.GetResourcePath().. "\\REAPER.ini")
 -- reaper.ShowConsoleMsg(string)
 
 -- so, I try to write the value
  reaper.SNM_SetIntConfigVar("lastview", 0)
 -- reaper.BR_Win32_WritePrivateProfileString("REAPER-fxadd", "lastview", "0", reaper.GetResourcePath().. "\\REAPER.ini")  
