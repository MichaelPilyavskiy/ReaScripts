-- @description Rename selected tracks as first FX
-- @version 1.2
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # use VF rename function
  
  script_title = "Rename selected tracks as first FX"
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
---------------------------------------------------  
  function RenameAsFX(track)
    local instr = TrackFX_GetInstrument( track )
    if instr >=0 then 
      local _, fx_name = TrackFX_GetFXName(track, instr, '')
      GetSetMediaTrackInfo_String(track, 'P_NAME', MPL_ReduceFXname(fx_name), true)
      return
    end
    local _, fx_name = TrackFX_GetFXName(track, 0, '')            
    GetSetMediaTrackInfo_String(track, 'P_NAME', MPL_ReduceFXname(fx_name), true)
    
  end
--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then
    Undo_BeginBlock()
    for i = 1, CountSelectedTracks(0) do RenameAsFX(GetSelectedTrack(0,i-1)) end
    Undo_EndBlock(script_title, 0)
  end  
