-- @description Toggle bypass all spectral edits in selected items
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # use external functions
--    # respect solo check


  -- NOT gfx NOT reaper
  local scr_title = 'Toggle bypass all spectral edits in selected items'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 

  -------------------------------------------------------
  function BypassSEstate(data)
    for key in pairs(data) do
      if data[key].edits then
        
        for se_id  =1 , #data[key].edits do
          local bypass = data[key].edits[se_id].bypass&1
          local solo = data[key].edits[se_id].bypass&2
          if bypass == 0 then 
            data[key].edits[se_id].bypass = solo + 1 
           elseif bypass == 1 then 
            data[key].edits[se_id].bypass = solo 
          end
        end
        
      end
    end
  end
  -------------------------------------------------------
  function main()
    for i = 1, CountSelectedMediaItems(0) do 
      local item = GetSelectedMediaItem(0,i-1)
      local ret, data = GetSpectralData(item)    
      BypassSEstate(data)
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
