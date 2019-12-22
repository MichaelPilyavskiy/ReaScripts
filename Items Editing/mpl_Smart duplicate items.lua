-- @version 1.31
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Smart duplicate items
-- @changelog
--    # fix zero measure shift
  
  local data = {}
  
  function SmartDuplicateItems(data)
    if CountSelectedMediaItems(0) < 1 then return end
    CollectData(data)
    local measure_shift, end_fullbeatsmax = CalcMeasureShift(data)
    local increment_measure = OverlapCheck(data, measure_shift, end_fullbeatsmax)
    DuplicateItems(data,measure_shift+increment_measure)
  end
---------------------------------------------------------------------  
  function CollectData(data)
    for i = 1, CountSelectedMediaItems(0) do
      local item = GetSelectedMediaItem( 0, i-1 ) 
      local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local GUID = BR_GetMediaItemGUID( item ) 
      local pos_beats_t = {TimeMap2_timeToBeats( 0,pos )}
      local end_beats_t = {TimeMap2_timeToBeats( 0,pos+len )}
      data[i] = {src_tr =  GetMediaItem_Track( item ),
                chunk = ({GetItemStateChunk( item, '', false )})[2],
                group_ID = GetMediaItemInfo_Value( item, 'I_GROUPID'),
                col = GetMediaItemInfo_Value( item, 'I_CUSTOMCOLOR' ),
                pos_conv = {   pos_conv_beats = pos_beats_t [1],
                    pos_conv_measure = pos_beats_t [2],
                    pos_conv_fullbeats = pos_beats_t [4],
                    },
                end_conv = {   end_conv_beats = end_beats_t [1],
                    end_conv_measure = end_beats_t [2],
                    end_conv_fullbeats = end_beats_t [4],
                    },                 
                 GUID = BR_GetMediaItemGUID( item ) 
                 }
                 
    end
  end
---------------------------------------------------------------------   
  function CalcMeasureShift(data)
    local meas_min = math.huge
    local meas_max = 0
    local end_fullbeatsmax = 0
    for i = 1, #data do
      meas_min = math.min(meas_min, data[i].pos_conv.pos_conv_measure)
      meas_max = math.max(meas_max, data[i].end_conv.end_conv_measure)
      end_fullbeatsmax = math.max(end_fullbeatsmax, data[i].end_conv.end_conv_fullbeats)
    end
    local measure_shift = math.max(1,meas_max - meas_min)
    return measure_shift, end_fullbeatsmax
  end
---------------------------------------------------------------------   
  function OverlapCheck(data, measure_shift, end_fullbeatsmax)
    ClearConsole()
    for i = 1, #data do
      local shifted_pos = TimeMap2_beatsToTime( 0, data[i].pos_conv.pos_conv_beats, data[i].pos_conv.pos_conv_measure + measure_shift )
      if shifted_pos < TimeMap2_beatsToTime( 0, end_fullbeatsmax ) then  return 1 end
    end
    return 0
  end
---------------------------------------------------------------------    
  function DuplicateItems(data,measure_shift)
    for i = 1, #data do
      local new_it = AddMediaItemToTrack( data[i].src_tr )
      SetItemStateChunk( new_it, data[i].chunk, false )
      local new_pos = TimeMap2_beatsToTime( 0, data[i].pos_conv.pos_conv_beats, data[i].pos_conv.pos_conv_measure + measure_shift )
      local new_end = TimeMap2_beatsToTime( 0, data[i].pos_conv.pos_conv_beats, data[i].end_conv.end_conv_measure + measure_shift )
      SetMediaItemInfo_Value( new_it, 'D_POSITION', new_pos)
      SetMediaItemInfo_Value( new_it, 'D_LENGTH', new_end - new_pos)
      --SetMediaItemInfo_Value( new_it, 'I_CUSTOMCOLOR', data[i].col )
    end
  end

---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end
--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_CalibrateFont') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then 
    Undo_BeginBlock()
    SmartDuplicateItems(data)
    Undo_EndBlock("Smart duplicate items", 0)
  end