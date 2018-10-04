-- @description Add ReaEQ to selected tracks (ignore default preset)
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # use HP/LP instead shelfs, REAPER 5.90+ [p=2042020]

  local scr_title = 'Add ReaEQ to selected tracks (with low and high shelf TCP)'
  --NOT gfx NOT reaper
  ---------------------------------------------------  
  function main_sub(tr)    
  
      fxId_EQ  = TrackFX_AddByName( tr, 'ReaEQ', false, 1 )
      TrackFX_SetParamNormalized( tr, fxId_EQ, 0, 0.0001 ) -- lp F
      TrackFX_SetParamNormalized( tr, fxId_EQ, 1, 0 ) -- lp gain
      TrackFX_SetParamNormalized( tr, fxId_EQ, 9, 0.9999 ) -- hp gain
      TrackFX_SetParamNormalized( tr, fxId_EQ, 10, 0 ) -- hp gain
      TrackFX_SetNamedConfigParm( tr, fxId_EQ, 'BANDTYPE0', 4 )
      TrackFX_SetNamedConfigParm( tr, fxId_EQ, 'BANDTYPE3', 3 )
      SNM_AddTCPFXParm( tr, fxId_EQ, 0 ) -- lp
      SNM_AddTCPFXParm( tr, fxId_EQ, 9 ) -- hp
  end
  ---------------------------------------------------
  function main()
    Undo_BeginBlock()
    for i = 1, CountSelectedTracks(0) do
      tr = GetSelectedTrack(0,i-1)
      main_sub(tr)
    end
    TrackList_AdjustWindows( false )
    Undo_EndBlock(scr_title, 1)
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
      local ret2 = CheckReaperVrs(5.90)    
      if ret and ret2 then main() end