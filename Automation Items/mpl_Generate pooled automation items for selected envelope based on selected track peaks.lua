-- @description Generate pooled automation items for selected envelope based on selected track peaks
-- @version 1.0
-- @author MPL
-- @about
--    Select envelope, selecte track, define time selection (contain media items on selected track), run script
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init


 ----------------------------------------------------------------------------  
  function BuildPointsFromTable(t, time_start, time_end)
    if not t then return end
    local env =  GetSelectedEnvelope( 0 )
    if not env then return end
    DeleteEnvelopePointRangeEx( env, -1, time_start, time_end )
    
    -- clear AI
    local clear_id = {}
    for autoitem_idx = 1,  CountAutomationItems( env ) do
      local AI_pos = GetSetAutomationItemInfo( env, autoitem_idx-1, 'D_POSITION', 0, false )
      local AI_len = GetSetAutomationItemInfo( env, autoitem_idx-1, 'D_LENGTH', 0, false )
      if    (AI_pos >= time_start and AI_pos <= time_end)
        or  (AI_pos + AI_len >= time_start and AI_pos + AI_len <= time_end)
        or (AI_pos < time_start and AI_pos + AI_len > time_end) then
        clear_id[#clear_id+1] = autoitem_idx          
      end
    end
    for i = #clear_id , 1, -1 do DeleteEnvelopePointRangeEx( env, clear_id[i]-1, -1, -1) end
    
    -- get max len
    local max_len = 0.1
    for i = 1, #t-1 do
      max_len = math.max(max_len, t[i+1].pos -  t[i].pos)
    end
    
    -- insert AI
    local pool_id
    for i = #t, 1, -1 do 
        if i == #t then
          local new_AI = InsertAutomationItem(env , -1, t[i].pos, max_len ) 
          pool_id = GetSetAutomationItemInfo(env, new_AI, "D_POOL_ID", 0, false)
          GetSetAutomationItemInfo( env, new_AI, 'D_LOOPSRC', 0, true )
          GetSetAutomationItemInfo( env, new_AI, 'D_LENGTH', time_end - t[i].pos, true )
          
        else
          InsertAutomationItem( env, pool_id, t[i].pos,  t[i+1].pos -  t[i].pos )  
          GetSetAutomationItemInfo( env, pool_id, 'D_LOOPSRC', 0, true )
        end
    end
    Envelope_SortPointsEx( env, -1 )
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
  ------------------------------------------------------------------------------------------------------
  function WDL_DB2VAL(x) return math.exp((x)*0.11512925464970228420089957273422) end  --https://github.com/majek/wdl/blob/master/WDL/db2val.h
  ----------------------------------------------------------------------------
  function FilterPeaks(t, threshold,hold_release)
    
    -- threshold
    local idremove = {}
    for i = 1, #t do  if t[i].val < threshold then  idremove[#idremove+1] = i  end end
    for i = #idremove, 1, -1 do table.remove(t,idremove[i]) end
    
    -- hold_release
    local cur_pos,last_cur_pos
    local idremove = {}
    for i = 1, #t do  
      cur_pos = t[i].pos
      if last_cur_pos and cur_pos - last_cur_pos  < hold_release then idremove[#idremove+1] = i end
      last_cur_pos = cur_pos
    end
    for i = #idremove, 1, -1 do table.remove(t,idremove[i]) end
  end
  ----------------------------------------------------------------------------
  function InsertTriggeredAI(window, threshold, hold_release)
    local ts_st, ts_end = GetSet_LoopTimeRange2( 0, false, false, 0, 0, false )
    if ts_end - ts_st < 0.001 then return end
    

    local tr = GetSelectedTrack( 0,0 )
    if not tr then return end
    local RMS_t = GetPeaks(tr,ts_st, ts_end, window )
    local threshold_linear = WDL_DB2VAL(threshold)
    FilterPeaks(RMS_t, threshold_linear,hold_release)
    BuildPointsFromTable(RMS_t,ts_st, ts_end )
  end
  ----------------------------------------------------------------------------  
  
  function main()
    local ret,str = GetUserInputs('', 3, 'window,threshold,hold_release','0.002,-20,0.05')
    if ret then 
      ui = {}
      for val in str:gmatch('[^,]+') do if tonumber(val) then ui[#ui+1]=tonumber(val) end end
      if #ui == 3 then InsertTriggeredAI(ui[1],ui[2],ui[3]) end
    end
  end
  
  
  ---------------------------------------------------------------------
    function CheckFunctions(str_func)
      local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'
      local f = io.open(SEfunc_path, 'r')
      if f then
        f:close()
        dofile(SEfunc_path)
        
        if not _G[str_func] then 
          reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0)
         else
          return true
        end
        
       else
        reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0)
      end  
    end
    ---------------------------------------------------
    function CheckReaperVrs(rvrs) 
      local vrs_num =  GetAppVersion()
      vrs_num = tonumber(vrs_num:match('[%d%.]+'))
      if rvrs > vrs_num then 
        reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0)
        return
       else
        return true
      end
    end
  --------------------------------------------------------------------  
    local ret = CheckFunctions('Action') 
    local ret2 = CheckReaperVrs(5.95)    
    if ret and ret2 then main() end