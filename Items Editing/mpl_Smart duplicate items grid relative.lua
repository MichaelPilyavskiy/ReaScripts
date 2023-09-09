-- @description Smart duplicate items grid relative
-- @version 1.15
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--   # use more sophisticated approach


      -------------------------------------------------------
  function main()
    local floating_point_threshold = 0.000001
    local group_t = CollectGroupData(nudge_diff)
    if #group_t==0 then return end
    local min_pos, max_pos, com_len = GetComLength()
    
    _, division = reaper.GetSetProjectGrid( 0, false, 0, 0, 0)  
     _, _, _, fullbeats_st = reaper.TimeMap2_timeToBeats( 0, min_pos )
     _, _, _, fullbeats_end = reaper.TimeMap2_timeToBeats( 0, max_pos )
    
    local tsmarker = FindTempoTimeSigMarker( 0, min_pos )
    local retval1, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = GetTempoTimeSigMarker( 0, tsmarker )
    if retval1 == false or timesig_num == -1 then
      local test_time = TimeMap2_beatsToTime( 0, 0, 1 )
       _, _, _, _, timesig_denom = TimeMap2_timeToBeats( 0, test_time )
    end
    
    -- find x = how much ceiling grid divisions is inside selection 
    local div_inside_area = math.ceil((fullbeats_end - fullbeats_st) / (division*timesig_denom))
    local shift_beats = div_inside_area*(division*timesig_denom)
    local nudge_diff = TimeMap2_beatsToTime( 0, shift_beats, 0 )
    AppNudgeToGroupedItems(nudge_diff, group_t)
  end
  ----------------------------------------------------------------------
  function GetComLength()
    local min_pos = math.huge
    local max_pos = 0
    local count_sel_items = reaper.CountSelectedMediaItems(0)
    for i = 1, count_sel_items do
      item = reaper.GetSelectedMediaItem(0, i-1)
      if item ~= nil then
        item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        min_pos= math.min(min_pos,item_pos)
        max_pos= math.max(max_pos,item_pos+item_len)
      end  
    end
    local com_len = max_pos-min_pos 
    return min_pos, max_pos, com_len
  end
  ----------------------------------------------------------------------
  function CollectGroupData(nudge_diff)
    -- save group IDs
    local group_t = {} 
    local count_sel_items = reaper.CountSelectedMediaItems(0)
    for selitem =1, count_sel_items do
      local it =  reaper.GetSelectedMediaItem( 0, selitem-1 )
      local tk = GetActiveTake(it)
      retval, tkGUID = reaper.GetSetMediaItemTakeInfo_String( tk, 'GUID', '', false )
      local gr_ID = reaper.GetMediaItemInfo_Value( it, 'I_GROUPID' )
      group_t[ #group_t+1] ={tkGUID=tkGUID,gr_ID=gr_ID}
    end
    return group_t
  end
  ----------------------------------------------------------------------
  function AppNudgeToGroupedItems(nudge_diff, group_t)
    if nudge_diff == 0 then return end
    reaper.ApplyNudge(0, 0, 5, 1, nudge_diff , 0, 1)   
    for i =1, #group_t do 
      local tk = reaper.GetMediaItemTakeByGUID( 0, group_t[i].tkGUID )
      local valid = ValidatePtr(tk,'MediaTake*')
      if valid then 
        local it = reaper.GetMediaItemTake_Item( tk)
        SetMediaItemInfo_Value( it, 'I_GROUPID',group_t[i].gr_ID ) 
        SetMediaItemInfo_Value( it, 'I_CUSTOMCOLOR',ColorToNative(1,255,1)|0x1000000 ) 
      end 
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
  