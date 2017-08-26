-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Quantize item length and stretch (4 beats snap)
-- @changelog
--    + init
  
  div = 4  
  
  local scr_nm = 'Quantize item length and stretch to closer 4 beats division'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function QuantizeItemLenRate(item, div)
    if not item then return end
    local len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
    local _, _, _, f_beats = TimeMap2_timeToBeats( proj, len)
    local closer_beat = q(f_beats, f_beats-f_beats % div, div + f_beats-f_beats % div)
    cur_ratio = GetMediaItemTakeInfo_Value( GetActiveTake(item), 'D_PLAYRATE')
    str_ratio = f_beats/closer_beat
    SetMediaItemTakeInfo_Value( GetActiveTake(item), 'D_PLAYRATE', cur_ratio*str_ratio )
    SetMediaItemInfo_Value( item,'D_LENGTH',len/str_ratio )
    UpdateArrange()
  end  
  function q(v, lim1, lim2) if v-lim1 < lim2-v then return lim1 else return lim2 end end
  
  Undo_BeginBlock()
  for i = 1, CountSelectedMediaItems(0) do
    local item = GetSelectedMediaItem(0,i-1)
    QuantizeItemLenRate(item, div)
  end
  Undo_EndBlock(scr_nm, 0 )