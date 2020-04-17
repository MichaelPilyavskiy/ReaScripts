-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Explode selected track RS5k instances to new tracks
-- @noindex
-- @changelog
--    # remove chunking code, use native TrackFX_CopyToTrack, which increase performance
--    # move FX instead copying
--    # use improved FX name reducer
--    # Create MIDI send from parent track

 ------------------------------------------------------------------------  
  function RenameTrAsFirstInstance(track)
    local fx_count =  TrackFX_GetCount(track)
    if fx_count >= 1 then
      local retval, fx_name =  TrackFX_GetFXName(track, 0, '')
      reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', MPL_ReduceFXname(fx_name), true)
    end
  end
  ------------------------------------------------------------------------
  function main()
    local src_track = GetSelectedTrack(0,0)
    if not src_track then  return end
    local tr_id = CSurf_TrackToID( src_track,false )
    for src_fx = TrackFX_GetCount( src_track ), 1, -1 do 
      InsertTrackAtIndex( tr_id, false )
      local dest_track = GetTrack(0,tr_id)
      TrackFX_CopyToTrack( src_track, src_fx-1, dest_track, 0, true )
      s_id = CreateTrackSend( src_track, dest_track ) 
      SetTrackSendInfo_Value( src_track, 0, s_id, 'I_SRCCHAN', -1 )
      SetTrackSendInfo_Value( src_track, 0, s_id, 'I_MIDIFLAGS', 0 )
      RenameTrAsFirstInstance(dest_track)
    end
  end
  
  ---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
  --------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  if ret then
    local ret2 = VF_CheckReaperVrs(5.95,true)    
    if ret and ret2 then Undo_BeginBlock2( 0 ) main() reaper.Undo_EndBlock2( 0, 'Explode selected track RS5k instances to new tracks', 0 ) end
  end
