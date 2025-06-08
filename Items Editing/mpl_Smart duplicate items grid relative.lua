-- @description Smart duplicate items grid relative
-- @version 1.18
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # fix precision while searching active tempo marker
--    # fix calculating nudge with various tempo



  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
    function msg(s)  if not s then return end  if type(s) == 'boolean' then if s then s = 'true' else  s = 'false' end end ShowConsoleMsg(s..'\n') end 
  --------------------------------------------------------------------  
  function main()
    local floating_point_threshold = 0.000001
    local group_t = CollectGroupData(nudge_diff)
    if #group_t==0 then return end
    local min_pos, max_pos, com_len = GetComLength()
    
    _, division = reaper.GetSetProjectGrid( 0, false, 0, 0, 0)  
     _, _, _, fullbeats_st = reaper.TimeMap2_timeToBeats( 0, min_pos )
     _, _, _, fullbeats_end = reaper.TimeMap2_timeToBeats( 0, max_pos )
    
    local tsmarker = FindTempoTimeSigMarker( 0, min_pos+0.01)
    local retval1, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = GetTempoTimeSigMarker( 0, tsmarker )
    if retval1 == false or timesig_num == -1 then
      local test_time = TimeMap2_beatsToTime( 0, 0, 1 )
       _, _, _, _, timesig_denom = TimeMap2_timeToBeats( 0, test_time )
    end
    
    -- find x = how much ceiling grid divisions is inside selection 
    local div_inside_area = math.ceil((fullbeats_end - fullbeats_st) / (division*timesig_denom))
    local shift_beats = div_inside_area*(division*timesig_denom)
    local min_pos_new = TimeMap2_beatsToTime( 0, fullbeats_st + shift_beats)
    
    local nudge_diff = min_pos_new - min_pos --TimeMap2_beatsToTime( 0, shift_beats, 0 )
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
        --SetMediaItemInfo_Value( it, 'I_CUSTOMCOLOR',ColorToNative(1,255,1)|0x1000000 ) 
      end 
    end
  end
    ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.78,true)then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Smart duplicate items grid relative', 0xFFFFFFFF )
  end 
  