-- @description Remove all spectral edits from selected items active takes
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # use external functions


  -- NOT gfx NOT reaper
  local scr_title = 'Remove all spectral edits from selected items active takes'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 

  -------------------------------------------------------
  function RemoveData(data, tk_id)
    for key in pairs(data) do
      if data[key].edits then
        if data[tk_id+1] and data[tk_id+1].edits then data[tk_id+1] = {} end
      end
    end
  end
  -------------------------------------------------------
  function main()
    for i = 1, CountSelectedMediaItems(0) do 
      local item = GetSelectedMediaItem(0,i-1)
      local tk = GetActiveTake( item )
      local tk_id = GetMediaItemTakeInfo_Value( tk, 'IP_TAKENUMBER' )
      local ret, data = GetSpectralData(item)    
      RemoveData(data, tk_id)
      if ret then SetSpectralData(item, data) end
    end
  end
  
  
  
  --------------------------------------------------------
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
  
  
  
