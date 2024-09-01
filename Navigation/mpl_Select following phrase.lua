-- @description Select following phrase
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
  local minslicelen_sec = 0.5-- sec
  local window_sec = 0.05
  local offs = 0.1
  -------------------------------------------------------------------  
  function GetNextPhrasePos(data, threshold_dB, minslicelen_sec, window_sec)
     cnt_ids_check = math.floor(minslicelen_sec / window_sec)
    local cnt = 0
    for i = 1, #data do
      if cnt >= cnt_ids_check and data[i].RMS_db > threshold_dB then 
        return data[i].pos
      end
      if data[i].RMS_db < threshold_dB then 
        cnt = cnt + 1 
       else
        cnt = 0 
      end
    end 
  end
  -------------------------------------------------------------------  
  function GetAudioData(parent_track, edge_start, edge_end, max_check, window_sec)
    local edge_end = math.min(edge_end, edge_start + max_check) 
    local accessor = CreateTrackAudioAccessor( parent_track )
    local data = {}
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
  function main(max_check, threshold_dB, minslicelen_sec, window_sec) 
    local item = GetSelectedMediaItem(0,0)
    if not item then return end 
    local take = GetActiveTake(item)
    if not take then return end
    if TakeIsMIDI( take ) then return end
    
    local parent_track = GetMediaItemTrack( item )
    local curpos = GetCursorPosition()
    local itempos = GetMediaItemInfo_Value( item, 'D_POSITION' )
    local itemlen = GetMediaItemInfo_Value( item, 'D_LENGTH' )
    if curpos > itempos+itemlen then return end
    local data = GetAudioData(parent_track, curpos, itempos+itemlen, max_check, window_sec)
    local nextpos = GetNextPhrasePos(data, threshold_dB, minslicelen_sec, window_sec)
    if nextpos then 
      GetSet_LoopTimeRange2( 0, 1, false, curpos, nextpos-offs, true )
      SetEditCurPos( nextpos-offs, true, true ) 
    end
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
  if VF_CheckReaperVrs(5.95,true)then
    Undo_BeginBlock2( 0 )
    main(max_check, threshold_dB, minslicelen_sec, window_sec)
    PreventUIRefresh( 1 )
    Undo_EndBlock2( 0, 'mpl Select following phrase', -1 )
  end