-- @description Smart duplicate items, use measure shift
-- @version 1.34
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

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
  --------------------------------------------------------------------  
  
  local data = {}
  
  function main()
    if CountSelectedMediaItems(0) < 1 then return end
    mpl_SDI_CollectData(data)
    local measure_shift, end_fullbeatsmax = mpl_SDI_CalcMeasureShift(data)
    local increment_measure = mpl_SDI_OverlapCheck(data, measure_shift, end_fullbeatsmax)
    mpl_SDI_DuplicateItems(data,measure_shift+increment_measure)
  end
---------------------------------------------------------------------  
  function mpl_SDI_CollectData(data) 
    for i = 1, CountSelectedMediaItems(0) do
      local item = GetSelectedMediaItem( 0, i-1 ) 
      local pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      --local GUID = BR_GetMediaItemGUID( item ) 
      local retval, GUID = reaper.GetSetMediaItemInfo_String( item, 'GUID', '', 0 )
      local pos_beats_t = {TimeMap2_timeToBeats( 0,pos )}
      local end_beats_t = {TimeMap2_timeToBeats( 0,pos+len )}
      data[i] = {src_tr =  GetMediaItem_Track( item ),
                chunk = ({GetItemStateChunk( item, '', false )})[2],
                len =len,
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
                 GUID = GUID
                 }
                 
    end
  end
---------------------------------------------------------------------   
  function mpl_SDI_CalcMeasureShift(data) 
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
  function mpl_SDI_OverlapCheck(data, measure_shift, end_fullbeatsmax) 
    for i = 1, #data do
      local shifted_pos = TimeMap2_beatsToTime( 0, data[i].pos_conv.pos_conv_beats, data[i].pos_conv.pos_conv_measure + measure_shift )
      if shifted_pos < TimeMap2_beatsToTime( 0, end_fullbeatsmax ) then  return 1 end
    end
    return 0
  end
---------------------------------------------------------------------    
  function mpl_SDI_DuplicateItems(data,measure_shift) 
    for i = 1, #data do
      local new_it = AddMediaItemToTrack( data[i].src_tr )
      SetItemStateChunk( new_it, data[i].chunk, false )
      local new_pos = TimeMap2_beatsToTime( 0, data[i].pos_conv.pos_conv_beats, data[i].pos_conv.pos_conv_measure + measure_shift )
      local new_end = TimeMap2_beatsToTime( 0, data[i].pos_conv.pos_conv_beats, data[i].end_conv.end_conv_measure + measure_shift )
      SetMediaItemInfo_Value( new_it, 'D_POSITION', new_pos)
      --SetMediaItemInfo_Value( new_it, 'I_CUSTOMCOLOR', data[i].col )
    end
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.78,true) then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Smart duplicate items', 0xFFFFFFFF )
  end 