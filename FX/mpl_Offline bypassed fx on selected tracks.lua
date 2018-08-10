-- @version 1.0
-- @author MPL
-- @description Offline bypassed fx on selected tracks
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init

  
  --------------------------------------------------------------------
  function main()
    Undo_BeginBlock()
    for i =1, CountSelectedTracks(0) do 
      local tr = GetSelectedTrack(0,i-1)
      for fx = TrackFX_GetCount( tr ), 1, -1 do
        local is_byp = TrackFX_GetEnabled( tr, fx-1 )
        if not is_byp then TrackFX_SetOffline( tr, fx-1, 1 ) end
      end
    end
    Undo_EndBlock('Offline bypassed fx on selected tracks', 0)
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
    local ret = CheckFunctions('MPL_ReduceFXname') 
    local ret2 = CheckReaperVrs(5.95)    
    if ret and ret2 then main() end
    