-- @description Add note into RS5k instance name on selected track
-- @version 1.0
-- @author MPL
-- @noindex
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


  local vrs = 'v1.0'
  
  --NOT gfx NOT reaper
--------------------------------------------------------------------
  function main()
    local track = GetSelectedTrack(0,0)
    if not track then return end
    
    cntfx =  TrackFX_GetCount(track) 
    for fx = 1, cntfx do
      local ret, fxname = reaper.TrackFX_GetFXName( track, fx-1, '' )
      if not fxname:match('Note %d+') then
        local MIDIpitch = math.floor(TrackFX_GetParamNormalized( track, fx-1, 3)*128) 
        SetFXName(track, fx-1, 'Note '..MIDIpitch..'_'..fxname)
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
      Undo_BeginBlock2( 0 )
      main() 
      Undo_EndBlock2( 0, 'Add note into RS5k instance name on selected track', -1 )
    end
  end