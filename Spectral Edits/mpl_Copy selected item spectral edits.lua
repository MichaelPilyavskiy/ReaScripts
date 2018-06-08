-- @description Copy selected item spectral edits
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  -- NOT gfx NOT reaper
  local scr_title = 'Copy selected item spectral edits'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 


  -------------------------------------------------------
  function main()
    local item = GetSelectedMediaItem(0,0)
    if item then
      local tk = GetActiveTake( item )
      if tk then 
        local tk_ID = GetMediaItemTakeInfo_Value( tk, 'IP_TAKENUMBER' )
        local ret, data = GetSpectralData(item)
        if data and data[tk_ID+1] and data[tk_ID+1].edits then
          local str = 'MPLSPECTRALEDITCLIPBOARD\n'
          for i = 1 , #data[tk_ID+1].edits do
            str = str..data[tk_ID+1].edits[i].chunk_str..'\n'
          end
          if str ~= 'MPLSPECTRALEDITCLIPBOARD\n' then CF_SetClipboard( str ) end
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
      --Undo_BeginBlock()
      main()
      --Undo_EndBlock( scr_title, -1 )
     else
      MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end    
  end
  
