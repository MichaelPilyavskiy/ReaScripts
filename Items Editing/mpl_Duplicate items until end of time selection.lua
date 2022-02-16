-- @description Duplicate items until end of time selection
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init 

  function main()
    local tsstart, tsend = GetSet_LoopTimeRange2( 0, false, false, 0, 0, false )
    if tsend - tsstart < 0.01 then return end
    
    -- get source length
      local items_t = {}
      local bound_st, bound_end = math.huge, -math.huge
      for selitem =1,  CountSelectedMediaItems( 0 ) do
        local item = GetSelectedMediaItem( 0, selitem-1 )
        items_t[#items_t+1] = item
        local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
        local len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
        bound_st = math.min(bound_st, pos)
        bound_end = math.max(bound_end, pos+len) 
      end
      local bound_len = bound_end - bound_st
      if bound_len > 10^15 then return end
      
      
    -- get duplicates count
      local copies = math.ceil((tsend - bound_st) / bound_len)-1
    
    -- share duplicates
      ApplyNudge( 0,--project, 
                  0,--nudgeflag, 
                  5,--nudgewhat, 
                  21,--nudgeunits, 
                  1,--value, 
                  0,--reverse, 
                  copies)--copies ))
    
  end
  ---------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.84) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Duplicate items until end of time selection', 0 )
  end end