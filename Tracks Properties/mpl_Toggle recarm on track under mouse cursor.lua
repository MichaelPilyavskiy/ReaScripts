-- @description Toggle recarm on track under mouse cursor
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # comment ClearAllRecArmed()


  function main()
    local track = VF_GetTrackUnderMouseCursor()
    if track ~= nil then  
      if reaper.GetMediaTrackInfo_Value(track, 'I_RECARM') == 0 then
        --reaper.ClearAllRecArmed()
        reaper.SetMediaTrackInfo_Value(track, 'I_RECARM',1)
       else
        --reaper.ClearAllRecArmed()
        reaper.SetMediaTrackInfo_Value(track, 'I_RECARM',0)
      end  
    end
  end

  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Toggle recarm on track under mouse cursor', 0xFFFFFFFF )
  end end