-- @description Go to first receive track (send source)
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--  # remove SWS dependency
  
  function main()
    local receive_id = 1 
    local tr = GetSelectedTrack(0,0)
    if not tr then  return end
    local receive_tr = GetTrackSendInfo_Value( tr, -1, receive_id-1, 'P_SRCTRACK' )
    if not (receive_tr and ValidatePtr(receive_tr, 'MediaTrack*'))then return end
    
    reaper.Main_OnCommand(40297,0) -- unselect all
    reaper.SetTrackSelected(receive_tr, true) 
    reaper.SetMixerScroll(receive_tr)
    reaper.Main_OnCommand(40913,0) -- arrange view to selected send  

  end

  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, "Go to first receive track", 0xFFFFFFFF )
  end end