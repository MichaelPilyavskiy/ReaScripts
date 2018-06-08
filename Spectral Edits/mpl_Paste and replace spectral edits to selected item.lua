-- @description Paste and replace spectral edits to selected items
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  -- NOT gfx NOT reaper
  local scr_title = 'Paste and replace spectral edits to selected items'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 


  -------------------------------------------------------
  function main()
    local buf = reaper.CF_GetClipboard('' )
    if not buf:match('MPLSPECTRALEDITCLIPBOARD') then return end
    SEstr = buf:match('MPLSPECTRALEDITCLIPBOARD(.*)')
    for i = 1, CountSelectedMediaItems() do
      local item = GetSelectedMediaItem(0,0)
      if item then
        local tk = GetActiveTake( item )
        if tk then 
          local tk_ID = GetMediaItemTakeInfo_Value( tk, 'IP_TAKENUMBER' )
           data = {[tk_ID+1] = {edits={{}}}}
           SetSpectralData(item, data, SEstr)
        
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
      Undo_BeginBlock()
      main()
      Undo_EndBlock( scr_title, -1 )
     else
      MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
    end    
  end
  
