-- @description Add pre-fx control to selected tracks TCP
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  function main()
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      AddTCPPreAmp(tr)
    end
  end
-----------------------------------------------------------------------------------------    
  function AddTCPPreAmp(tr)
    fx_id = TrackFX_AddByName( tr, 'volume_pan', false, 1 )
    if fx_id < 0 then return end
    TrackFX_CopyToTrack(tr, fx_id, tr, 0, true) -- make first
    SNM_AddTCPFXParm( tr, 0, 0 )
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

--------------------------------------------------------------------  
  local ret = CheckFunctions('Action') 
  local ret2 = CheckReaperVrs(5.95)    
  if ret and ret2 then main() end