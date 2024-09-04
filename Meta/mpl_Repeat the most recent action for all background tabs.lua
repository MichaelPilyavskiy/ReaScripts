-- @description Repeat the most recent action for all background tabs
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showpost.php?p=2806828&postcount=26
-- @changelog
--    + init


reaper.PreventUIRefresh( 1 )
local curproj_ptr, projfn = reaper.EnumProjects( -1 )
for proj_idx = 0, 128 do
  local proj_ptr, projfn = reaper.EnumProjects( proj_idx )
  if not proj_ptr then break end
  if proj_ptr ~=  curproj_ptr then 
    reaper.SelectProjectInstance( proj_ptr )
    reaper.Main_OnCommand( 2999, 0 ) -- Action: Repeat the most recent action
  end
end
reaper.SelectProjectInstance( curproj_ptr )
reaper.PreventUIRefresh( -1 )