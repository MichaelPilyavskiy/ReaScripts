-- @description Move cursor to previous phrase in items
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
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

  local max_check = 60 -- formward audio data check
  local threshold_dB = -20 -- dB
  local threshold_dB2 = -50 -- dB afte rpharese fadeout
  local minslicelen_sec = 0.5-- sec
  local window_sec = 0.05
  
  -------------------------------------------------------------------  
  function GetPrevPhrasePos(data, threshold_dB, minslicelen_sec, window_sec, threshold_dB2)
     cnt_ids_check = math.floor(minslicelen_sec / window_sec)
    local cnt = 0
    for i = #data, 1, -1 do
      if cnt >= cnt_ids_check and data[i].RMS_db > threshold_dB then 
        if last_positive_id and math.abs(last_positive_id - #data)>5 then  return data[last_positive_id-1].pos end
      end
      if data[i].RMS_db < threshold_dB then 
        cnt = cnt + 1 
       else
        last_positive_id = i
        cnt = 0 
      end
    end 
  end
  -------------------------------------------------------------------  
  function GetAudioData(parent_track, edge_start, edge_end, max_check, window_sec)
    local edge_end = math.min(edge_end, edge_start + max_check) 
    local accessor = CreateTrackAudioAccessor( parent_track )
     data = {}
    local id = 0
    local SR_spls = tonumber(reaper.format_timestr_pos( 1-reaper.GetProjectTimeOffset( 0,false ), '', 4 )) -- get sample rate obey project start offset
    local bufsz = math.ceil(window_sec * SR_spls)
  -- loop stuff 
    for pos = edge_start, edge_end, window_sec do 
      local samplebuffer = new_array(bufsz);
      GetAudioAccessorSamples( accessor, SR_spls, 1, pos, bufsz, samplebuffer )
      local samplebuffer_t = samplebuffer.table()
      samplebuffer.clear()
      local sum = 0 for i = 1, bufsz do sum = sum + math.abs(samplebuffer_t[i]) end 
      id = id + 1
      data[id] = {RMS_db=WDL_VAL2DB(sum / bufsz), pos = pos}
    end
    DestroyAudioAccessor( accessor )
    return data
  end
  -------------------------------------------------------------------  
  function main(max_check, threshold_dB, minslicelen_sec, window_sec, threshold_dB2) 
    local item = GetSelectedMediaItem(0,0)
    if not item then return end 
    local take = GetActiveTake(item)
    if not take then return end
    if TakeIsMIDI( take ) then return end
    local parent_track = GetMediaItemTrack( item )
    local curpos = GetCursorPosition()
    local itempos = GetMediaItemInfo_Value( item, 'D_POSITION' )
    if itempos > curpos then return end
    local data = GetAudioData(parent_track, itempos, curpos, max_check, window_sec)
    local prevpos = GetPrevPhrasePos(data, threshold_dB, minslicelen_sec, window_sec, threshold_dB2)
    if prevpos then SetEditCurPos( prevpos, true, true ) end
  end
  ------------------------------------------------------------------------------------------------------
  function WDL_VAL2DB(x, reduce)   --https://github.com/majek/wdl/blob/master/WDL/db2val.h
    if not x or x < 0.0000000298023223876953125 then return -150.0 end
    local v=math.log(x)*8.6858896380650365530225783783321
    if v<-150.0 then return -150.0 else 
      if reduce then 
        return string.format('%.2f', v)
       else 
        return v 
      end
    end
  end
  -------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.95,true)  then
    Undo_BeginBlock2( 0 )
    main(max_check, threshold_dB, minslicelen_sec, window_sec, threshold_dB2)
    PreventUIRefresh( 1 )
    Undo_EndBlock2( 0, 'mpl Move cursor to next phrase in items', -1 )
  end 