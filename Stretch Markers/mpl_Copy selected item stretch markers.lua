-- @description Copy selected item stretch markers
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # use native chunk functions, REAPER 5.95pre3+

  -- NOT gfx NOT reaper
  local scr_title = 'Copy selected item stretch markers'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 


  -------------------------------------------------------
  function main()
    local item = GetSelectedMediaItem(0,0)
    if item then
      local tk = GetActiveTake( item )
      if tk then 
        
        local retval, chunk = GetItemStateChunk( item, '', false )
        local tk_GUID = BR_GetMediaItemTakeGUID( tk )
        local takeSTR = chunk:match(literalize(tk_GUID)..'.*SM.-\n')
        if takeSTR  then
          local reduce_str = takeSTR:match('SM.-\n') 
          if reduce_str then CF_SetClipboard('MPLSMCLIPBOARD\n'..reduce_str) end
        end
        
      end
    end
  end
  
---------------------------------------------------------------------
  function CheckFunctions(str_func)
    local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
    local f = io.open(SEfunc_path, 'r')
    if f then
      f:close()
      dofile(SEfunc_path)
      
      if not _G[str_func] then 
        reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
       else
        return true
      end
      
     else
      reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end  
  end
  ---------------------------------------------------
  function CheckReaperVrs(rvrs) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0)
      return
     else
      return true
    end
  end
  
  --------------------------------------------------------
  if not reaper.APIExists( 'CF_GetClipboard' ) then
    MB('Require SWS v2.9.5+', 'Error', 0)
   else
      local ret = CheckFunctions('Action') 
      local ret2 = CheckReaperVrs(5.95)    
      if ret and ret2 then main() end
  end
  
  
    
