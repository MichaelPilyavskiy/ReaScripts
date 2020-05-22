-- @description Set selected track FX outputs to incremental stereo pairs
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


  local vrs = 'v1.0'
  
  --NOT gfx NOT reaper
--------------------------------------------------------------------
  function main()
    local tr = GetSelectedTrack(0,0)
    if not tr then return end
    
    cntfx =  TrackFX_GetCount(tr)
    SetMediaTrackInfo_Value( tr, 'I_NCHAN',math.min(cntfx*2,64)  )
    
    for fx = 1, cntfx do
      TrackFX_SetPinMappings( tr, fx-1, 1, 0, 2^(fx-1), 0 )
      TrackFX_SetPinMappings( tr, fx-1, 1, 1, 2^(fx-1)<<1, 0 )
    end 
  end
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then main() end
  end