-- @description Insert focused FX to selected tracks, preserve parameters
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + obey master track
--    + use native direct copy FX API (REAPER 5.95+)

  function main()
    local ret, tracknumber, _, src_fx = GetFocusedFX()
    if ret == 0 then return end
    local src_track = CSurf_TrackFromID(tracknumber, false)
    if tracknumber ==0 then src_track =  GetMasterTrack( 0 ) end
    
    for sel_tr = 1,  CountSelectedTracks( 0 ) do
      local dest_track = GetSelectedTrack( 0, sel_tr-1 )
      if dest_track ~= track then 
        TrackFX_CopyToTrack( src_track, src_fx, dest_track, TrackFX_GetCount( dest_track ), false )    
      end
    end  
  end  
---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
    local ret = CheckFunctions('VF_CalibrateFont') 
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then main() end