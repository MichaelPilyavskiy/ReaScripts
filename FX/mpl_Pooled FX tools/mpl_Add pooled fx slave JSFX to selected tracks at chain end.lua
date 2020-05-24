-- @description Add pooled fx slave JSFX to selected tracks at chain end
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @noindex
-- @changelog
--    + init

  --NOT gfx NOT reaper
  ------------------------------------------------------------------------ 
  local jsfx_name = 'POOL FX slave.jsfx'
  function main()
    for i = 1, CountSelectedTracks(0) do
      local track = GetSelectedTrack(0,i-1)
      ret, tr_name = GetSetMediaTrackInfo_String( track, 'P_NAME', '', 0 )
      if not tr_name:match('POOL FX%d+ master') then
        local ret = TrackFX_AddByName( track, jsfx_name, false, 0 )
        if ret < 0 then 
          ret = TrackFX_AddByName( track, jsfx_name, false, 1 ) 
        end
        if ret < 0 then MB(jsfx_name..' is missing.\nPlease install it via ReaPack from MPL repository (Action List/Browse packages)', 'Error', 0) return end
      end
    end
  end
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then 
      Undo_BeginBlock() 
      main()
      Undo_EndBlock('Add pooled fx slave JSFX to selected tracks at chain end', -1) 
    end
  end
  
