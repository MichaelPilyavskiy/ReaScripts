-- @description Rename active take as (itemname)_bounce_(date time)
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init 

  function main()
    local it = GetSelectedMediaItem(0,0)
    if not it then return end
    tk = GetActiveTake(it)
    if not tk then return end
    local retval, takename = reaper.GetSetMediaItemTakeInfo_String( tk, 'P_NAME', '', 0 )
    takename = takename:gsub('render ', '')
    local new_name = takename..'_bounce_'..os.date()
    GetSetMediaItemTakeInfo_String( tk, 'P_NAME', new_name, 1)
  end
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.84) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Rename active take as (itemname)_bounce_(date time)', 0 )
  end end
  