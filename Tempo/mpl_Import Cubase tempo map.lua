  --[[
     * ReaScript Name: Import Cubase tempo map
     * Lua script for Cockos REAPER
     * Author: Michael Pilyavskiy (mpl)
     * Author URI: http://forum.cockos.com/member.php?u=70694
     * Licence: GPL v3
     * Description:
     * Version: 1.0
    ]]
  
  function msg(s) reaper.ShowConsoleMsg(s) end
  
  function main()
    local track, item, take, c_tr
    -- ask for file
      retval, f_name = reaper.GetUserFileNameForRead('', 'Import Cubase tempo map', 'smt')
      if not retval then return end
      
    
    -- read file
      local file = io.open(f_name)
      local content = file:read('a')
      file:close()
        
    -- extract whole file
      local  t = {}
      for line in content:gmatch('[^\n]+') do t[#t+1] = line  end
    
    --------------------------------------------------------------------
    --------------------------------------------------------------------
    
    -- extract tempo objects
      local t2 = {}
      local obj_r = false
      local j = 1
      for i =1, #t do
        if t[i]:find('<obj class="MTempoEvent"')~= nil then 
          obj_r = true 
        end
        if t[i]:find('</obj>')~= nil then 
          obj_r = false 
          j = j +1 
        end
        if obj_r then 
          if t2[j] == nil then t2[j] = '' end
          t2[j] = t2[j]..'\n'..t[i] 
        end
      end
    
    -- convert objects to values
      local obj = {}
      for i =1 , #t2 do
        local t4 = {}
        for word in t2[i]:gmatch('[%d%.]+') do t4[#t4+1] = word end
        obj[#obj+1] = {}
        obj[#obj].bpm = tonumber(t4[2])
        obj[#obj].beat = tonumber(t4[3])/1920
      end
    
      
    -- add tempo markers
      for i = 1, #obj do
        local time = reaper.TimeMap2_beatsToTime(0, obj[i].beat*4)
        reaper.SetTempoTimeSigMarker(0,--ReaProject proj, 
                                      -1,--integer ptidx, 
                                      time, --number timepos, 
                                      -1,--measures, --integer measurepos, 
                                      -1,--obj[i].beat, --number beatpos, 
                                      obj[i].bpm, 
                                      0,--integer timesig_num, 
                                      0,--integer timesig_denom, 
                                      false) --boolean lineartempo)]] 
      end
    
    --------------------------------------------------------------------
    --------------------------------------------------------------------
      
    -- extract time signatures
      local ts_chunk = content:match('<list name="SignatureEvent".*</list>')
      local ts_chunk_t = {}
      for line in ts_chunk:gmatch('[^\n]+') do ts_chunk_t[#ts_chunk_t+1] = line  end
      
      local  ts = {}
      local obj_r = false
      local j = 1
      for i =1, #ts_chunk_t do
        if ts_chunk_t[i]:find('<obj class="MTimeSignatureEvent"')~= nil then 
          obj_r = true 
        end
        if ts_chunk_t[i]:find('</obj>')~= nil then 
          obj_r = false 
          j = j +1 
        end
        if obj_r then 
          if ts[j] == nil then ts[j] = '' end
          ts[j] = ts[j]..'\n'..ts_chunk_t[i] 
        end
      end
      
      local obj_ts = {}
      for i =1 , #ts do
        local  t4 = {}
        for word in ts[i]:gmatch('[%d%.]+') do t4[#t4+1] = word end
        obj_ts[#obj_ts+1] = {}
        obj_ts[#obj_ts].Bar = tonumber(t4[2])
        obj_ts[#obj_ts].Numerator = tonumber(t4[3])
        obj_ts[#obj_ts].Denominator = tonumber(t4[4])
        obj_ts[#obj_ts].Position_beat = tonumber(t4[5])/1920
      end
      
    -- add tempo markers
      for i = 1, #obj_ts do
        local time = reaper.TimeMap2_beatsToTime(0, obj_ts[i].Position_beat*4)
        local bpm = reaper.TimeMap2_GetNextChangeTime(0, time)
        reaper.SetTempoTimeSigMarker(0,--ReaProject proj, 
                                      -1,--integer ptidx, 
                                      time, --number timepos, 
                                      -1,--measures, --integer measurepos, 
                                      -1,--obj[i].beat, --number beatpos, 
                                      -1, 
                                      obj_ts[i].Numerator,--integer timesig_num, 
                                      obj_ts[i].Denominator,--integer timesig_denom, 
                                      false) --boolean lineartempo)]] 
      end      
    --------------------------------------------------------------------
    --------------------------------------------------------------------
    
    -- update
      reaper.UpdateTimeline()
      reaper.UpdateArrange()
      
  end
  
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(-1)
  main()
  reaper.PreventUIRefresh(1)
  reaper.Undo_EndBlock('Import Cubase tempo map', 0)
  
