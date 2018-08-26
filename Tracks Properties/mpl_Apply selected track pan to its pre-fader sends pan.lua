-- @description Apply selected track pan to its pre-fader sends pan
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  function main()
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      ApplyPan(tr)
    end
  end
-----------------------------------------------------------------------------------------    
  function ApplyPan(tr)
    local pan = GetMediaTrackInfo_Value( tr, 'D_PAN' )
    -- if dual
    if GetMediaTrackInfo_Value( tr, 'I_PANMODE') == 6 then 
       L= GetMediaTrackInfo_Value( tr, 'D_DUALPANL')
       R= GetMediaTrackInfo_Value( tr, 'D_DUALPANR')
       pan = math.max(math.min(L+R, 1), -1)
    end
    -- apply sends pan
    for sendidx =1,  GetTrackNumSends( tr, 0 ) do
      if GetTrackSendInfo_Value( tr, 0, sendidx-1, 'I_SENDMODE' ) == 3 then
        SetTrackSendInfo_Value( tr, 0, sendidx-1, 'D_PAN', pan )
      end
    end
  end
-----------------------------------------------------------------------------------------  
    function CheckFunctions(str_func)
      local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
      local f = io.open(SEfunc_path, 'r')
      if f then
        f:close()
        dofile(SEfunc_path)
        
        if not _G[str_func] then 
          reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
         else
          Undo_BeginBlock2( 0 )
          main()
          Undo_EndBlock( 'Apply track pan to pre-fader sends', -1 )
        end        
       else
        reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
      end  
    end
  --------------------------------------------------------------------
  CheckFunctions('SetFXName')    
  
  
  