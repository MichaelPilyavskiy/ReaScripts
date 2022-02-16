-- @description Set active take color darker
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init 
  function collim(val) return math.min(math.max(val, 0), 255) end
  function main()
    local it = reaper.GetSelectedMediaItem(0,0)
    if not it then return end
    tk = reaper.GetActiveTake(it)
    if not tk then return end
    local cust_col = reaper.GetMediaItemTakeInfo_Value( tk, 'I_CUSTOMCOLOR' )
     r, g, b = reaper.ColorFromNative( cust_col )
    local diff = 5
    reaper.SetMediaItemTakeInfo_Value( tk, 'I_CUSTOMCOLOR' , reaper.ColorToNative(collim( r-diff), collim(g-diff), collim(b-diff) )|0x1000000)
    reaper.UpdateItemInProject( it )
  end
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.84) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Set active take color darker', 0 )
  end end