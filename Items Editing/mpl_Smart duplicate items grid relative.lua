-- @description Smart duplicate items grid relative
-- @version 1.14
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # remove SWS dependency

  
  function main()
    count_sel_items = reaper.CountSelectedMediaItems(0)
    local floating_point_threshold = 0.000001
          
    if  count_sel_items ~= 0 then
    
      min_pos = math.huge
      max_pos = 0
      for i = 1, count_sel_items do
        item = reaper.GetSelectedMediaItem(0, i-1)
        if item ~= nil then
          item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
          item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
          min_pos= math.min(min_pos,item_pos)
          max_pos= math.max(max_pos,item_pos+item_len)
        end  
      end
      com_len = max_pos-min_pos   

      --closest_division = reaper.BR_GetClosestGridDivision(min_pos)
      closest_division, prev_div_pos, next_div_pos, is_next_closest = VF_GetClosestPrevNextGridDivision(min_pos)
      
      if math.abs(closest_division - min_pos) < floating_point_threshold then 
        prev_division = closest_division
      else 
        --prev_division = reaper.BR_GetPrevGridDivision(min_pos)
        prev_division = prev_div_pos
      end
      
      --closest_division2 = reaper.BR_GetClosestGridDivision(max_pos) 
      closest_division2, prev_div_pos2, next_div_pos2, is_next_closest = VF_GetClosestPrevNextGridDivision(max_pos)
      if math.abs(closest_division2 - max_pos) < floating_point_threshold then
        next_division = closest_division2
      else 
        --next_division = reaper.BR_GetNextGridDivision(max_pos) 
        next_division = next_div_pos2
      end  
      
      nudge_diff = com_len + (min_pos-prev_division)+(next_division-max_pos)
      reaper.ApplyNudge(0, 0, 5, 1, nudge_diff , 0, 1)   
    end     
  end
     
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Smart duplicate items grid relative', 0xFFFFFFFF )
  end end