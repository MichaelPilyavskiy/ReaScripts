-- @description Copy selected item stretch markers
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  -- NOT gfx NOT reaper
  local scr_title = 'Copy selected item stretch markers'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 


  -------------------------------------------------------
  function main()
    local item = GetSelectedMediaItem(0,0)
    if item then
      local tk = GetActiveTake( item )
      if tk then 
        
        local chunk = eugen27771_GetObjStateChunk(item)
        local tk_GUID = BR_GetMediaItemTakeGUID( tk )
        local takeSTR = chunk:match(literalize(tk_GUID)..'.*SM.-\n')
        if takeSTR  then
          local reduce_str = takeSTR:match('SM.-\n') 
          if reduce_str then CF_SetClipboard('MPLSMCLIPBOARD\n'..reduce_str) end
        end
        
      end
    end
  end
  
  
  --------------------------------------------------------
  if not APIExists( 'CF_GetClipboard' ) then
    MB('Require SWS v2.9.5+', 'Error', 0)
   else
    SEfunc_path = GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
    local f = io.open(SEfunc_path, 'r')
    if f then
      f:close()
      dofile(SEfunc_path)
      
      if not eugen27771_GetObjStateChunk then 
        MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
       else
        --Undo_BeginBlock()
        main()
        --Undo_EndBlock( scr_title, -1 )
      end
      
     else
      MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end    
  end
  
