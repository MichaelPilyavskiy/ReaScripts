-- @description Toggle bypass all spectral edits in selected items active takes
-- @version 1.04
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # use external functions
--    # respect solo check

  -- NOT gfx NOT reaper
  local scr_title = 'Toggle bypass all spectral edits in selected items active takes'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 

  -------------------------------------------------------
  function BypassSEstate(data, tk_id)
    if  data[tk_id+1] and data[tk_id+1].edits then
    
      for se_id  =1 , #data[tk_id+1].edits do
        local bypass = data[tk_id+1].edits[se_id].bypass&1
        local solo = data[tk_id+1].edits[se_id].bypass&2
        if bypass == 0 then 
          data[tk_id+1].edits[se_id].bypass = solo + 1 
         elseif bypass == 1 then 
          data[tk_id+1].edits[se_id].bypass = solo 
        end
      end
      
    end
  end
  -------------------------------------------------------
  function main()
    for i = 1, CountSelectedMediaItems(0) do 
      local item = GetSelectedMediaItem(0,i-1)
      local tk = GetActiveTake( item )
      local tk_id = GetMediaItemTakeInfo_Value( tk, 'IP_TAKENUMBER' )
       ret, data = GetSpectralData(item)    
      BypassSEstate(data, tk_id)
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
  
