-- @description Monitor selected track with track 1
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335 
-- @changelog
--    # remove SWS dependency
--    # cleanup


  
  function main()
    local track = GetTrack(0,0)
    local sel_track = GetSelectedTrack(0,0)
    if not (track and ValidatePtr(track,'MediaTrack*') and sel_track and ValidatePtr(sel_track,'MediaTrack*') and sel_track ~= track) then return end
        
    local dest_tr_exists
    for i =1, GetTrackNumSends(sel_track, 0) do
      dest_tr =  GetTrackSendInfo_Value(sel_track, 0, i-1, 'P_DESTTRACK')
      if dest_tr == track then dest_tr_exists = i-1 break end
    end
    
    if dest_tr_exists then RemoveTrackSend(sel_track, 0, dest_tr_exists) else CreateTrackSend(sel_track, track)  end
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Monitor selected track with track 1', 0xFFFFFFFF )
  end end