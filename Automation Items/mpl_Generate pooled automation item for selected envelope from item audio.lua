-- @description Generate pooled automation item for selected envelope from item audio
-- @version 1.02
-- @author MPL
-- @about
--    Select envelope, select item, run script
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
  
 ----------------------------------------------------------------------------  
  function BuildPointsFromTable(t, time_start, time_end, threshold_linear, env)
    if not t then return end
    
    local scaling_mode = GetEnvelopeScalingMode( env )
    local autoitem_idx = InsertAutomationItem(env , -1,time_start, time_end-time_start ) 
    local val = 0
    local latch = 0
    local latch_on 
    for i = 1, #t do 
      if t[i].val > threshold_linear then 
        if latch_on then 
          InsertEnvelopePointEx( env, autoitem_idx, t[i].pos-10^-14, latch, 0, 0, 0, true )
        end
        val = ScaleToEnvelopeMode( scaling_mode, t[i].val  )
        InsertEnvelopePointEx( env, autoitem_idx, t[i].pos, val, 0, 0, 0, true )
        latch = val 
        latch_on = nil
       else
        latch_on = true
      end
    end
    InsertEnvelopePointEx( env, autoitem_idx, time_end-0.001, 0, 0, 0, 0, true ) -- enclose boundary with latched value
    
    Envelope_SortPointsEx( env,autoitem_idx )
    UpdateArrange()
  end
  ----------------------------------------------------------------------------
  function GetPeaks(track ,ts_st, ts_end,window )
    local t = {}
    local accessor = CreateTrackAudioAccessor( track )
    
    local proj_SR = tonumber(format_timestr_len( 1, '', 0, 4 ))
    local buf_sz= math.floor(proj_SR * window)
    
    for pos = ts_st, ts_end, window do 
      local buf = new_array(buf_sz)
      GetAudioAccessorSamples( accessor, proj_SR, 1, pos, buf_sz, buf )
      local sum = 0
      local cnt = 0
      for spl = 1, buf_sz do
        if buf[spl] then 
          cnt = cnt + 1
          sum = sum + math.abs(buf[spl])
        end
      end
      t[#t+1] = {pos = pos, val = sum/cnt}
      buf.clear()
    end
    DestroyAudioAccessor( accessor )
    return t
  end
  ----------------------------------------------------------------------------
  function InsertTriggeredAI(window, threshold)
    --[[local ts_st, ts_end = GetSet_LoopTimeRange2( 0, false, false, 0, 0, false )
    if ts_end - ts_st < 0.001 then return end]]
    it = GetSelectedMediaItem(0,0)
    if not it then return end
    local pos = GetMediaItemInfo_Value( it, 'D_POSITION' )
    local len = GetMediaItemInfo_Value( it, 'D_LENGTH' )
    ts_st, ts_end = pos, pos+len
    
    local tr =  GetMediaItemTrack( it )--GetSelectedTrack( 0,0 )
    if not tr then return end
    local RMS_t = GetPeaks(tr,ts_st, ts_end, window )
    local threshold_linear = WDL_DB2VAL(threshold)
    
    local env =  GetSelectedEnvelope( 0 )
    if not env then MB('No envelope selected', '',0)return end
    
    BuildPointsFromTable(RMS_t,ts_st, ts_end, threshold_linear, env )
  end
  ----------------------------------------------------------------------------  
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  function main()
    local in_str =  reaper.GetExtState( 'MPL_GenAIfromAudio', 'cs_parm' )
    if in_str == '' then in_str = '0.01,-60' end
    local ret,str = GetUserInputs('', 2, 'window,threshold',in_str)
    if ret then 
      ui = {}
      for val in str:gmatch('[^,]+') do if tonumber(val) then ui[#ui+1]=tonumber(val) end end
      if #ui == 2 then 
        InsertTriggeredAI(ui[1],ui[2])
        SetExtState( 'MPL_GenAIfromAudio', 'cs_parm', str, true )
      end
    end
  end
  ----------------------------------------------------------------------------  
  if VF_CheckReaperVrs(6,true) then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Generate pooled automation item for selected envelope from item audio', 0xFFFFFFFF )
  end     