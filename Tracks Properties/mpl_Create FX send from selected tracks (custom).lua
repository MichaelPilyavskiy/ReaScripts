-- @description Create FX send from selected tracks (custom)
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # if bus FX, move before first selected track

  ----------------------------------------------------------------------
  function main()
    --local firsttrackid
    if reaper.CountSelectedTracks(0) == 1 then
      VF2_CreateFXTrack(reaper.GetSelectedTrack( 0,0 ))
     elseif reaper.CountSelectedTracks(0) > 1 then
      local seltr_ptrs = {}
      for i = 1, reaper.CountSelectedTracks(0) do 
        local tr = reaper.GetSelectedTrack( 0, i-1 )
        seltr_ptrs[#seltr_ptrs+1]=tr
        if i == 1 then firsttrackid = i end
        if i == reaper.CountSelectedTracks(0) then VF2_CreateFXTrack(tr, seltr_ptrs, firsttrackid) end
      end 
    end
  end
  
   
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end  else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0)  if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end    end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.71) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then 
    reaper.Undo_BeginBlock2( 0 )
    main()
    reaper.Undo_EndBlock2( 0, 'Create send from selected tracks (custom)', -1 )
  end end
