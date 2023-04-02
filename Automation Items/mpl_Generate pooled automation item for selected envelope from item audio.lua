-- @description Generate pooled automation item for selected envelope from item audio
-- @version 1.01
-- @author MPL
-- @about
--    Select envelope, select item, run script
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # Store parameters
--    # Don`t clear envelope/AI
--    # Don`t pool AI
--    # Use envelope scaling
--    # Enclose AI with the latched value
--    # Use media item parent track instead selected one
--    # Use media item boundaries instead time selection
--    # Latch value on threshold fall


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

  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.41) if ret then local ret2 = VF_CheckReaperVrs(6,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Generate pooled automation item for selected envelope from item audio', 0xFFFFFFFF )
  end end    