-- @description Rename items on selected tracks incrementally
-- @version 1.0
-- @author MPL
-- @changelog
--    + init

  function main()
    for i = 1, CountSelectedTracks(0) do
      local track = GetSelectedTrack(0,i-1)
      retval, tr_name = reaper.GetTrackName( track )
      for itemidx=1, CountTrackMediaItems( track ) do
        local item = GetTrackMediaItem( track, itemidx-1 )
        local tk = GetActiveTake( item )
        if tk then
          GetSetMediaItemTakeInfo_String( tk, 'P_NAME', tr_name..'#'..itemidx, true )
        end
      end
    end
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.42) if ret then local ret2 = VF_CheckReaperVrs(6.68,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    reaper.UpdateArrange()
    Undo_EndBlock2( 0, 'Rename items on selected tracks incrementally', 0xFFFFFFFF )
  end end