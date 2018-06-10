-- @description Paste and replace stretch markers to selected items
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  -- NOT gfx NOT reaper
  local scr_title = 'Paste and replace stretch markers to selected items'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 


  -------------------------------------------------------
  function main()
     buf = reaper.CF_GetClipboard('' )
    if not buf:match('MPLSMCLIPBOARD') then return end
    SEstr = buf:match('MPLSMCLIPBOARD(.*)')
    for i = 1, CountSelectedMediaItems() do
      local item = GetSelectedMediaItem(0,i-1)
      if item then
        local tk = GetActiveTake( item )
        if tk then 
          local chunk = eugen27771_GetObjStateChunk( item)
          local tk_GUID = BR_GetMediaItemTakeGUID( tk )
          local takeSTR = chunk:match(literalize(tk_GUID)..'.*SM.-\n')
          if takeSTR  then
            local reduce_str = takeSTR:match('SM.-\n') 
            if reduce_str then 
              takeSTR_new = takeSTR:gsub(literalize(reduce_str),SEstr )
              chunk = chunk:gsub(literalize(takeSTR), takeSTR_new)
              SetItemStateChunk( item, chunk, false )
            end
           else
            -- if take does not contain SM
            chunk = chunk:gsub(literalize(tk_GUID), tk_GUID..'\n'..SEstr)
            SetItemStateChunk( item, chunk, false )
            
          end  
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
        Undo_BeginBlock()
        main()
        Undo_EndBlock( scr_title, -1 )
      end
     else
      MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end    
  end
  
