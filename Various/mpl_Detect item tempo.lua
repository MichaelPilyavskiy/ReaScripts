-- @description Detect item tempo
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=273168
-- @provides
--    [main] . > mpl_Detect item tempo (share supposed beats as take markers).lua
--    [main] . > mpl_Detect item tempo (share supposed beats as stretch markers).lua
--    [main] . > mpl_Detect item tempo (share supposed beats as stretch markers, quantize to grid).lua
--    [main] . > mpl_Detect item tempo (share supposed beats as tempo markers).lua
-- @changelog
--    # fix various errors

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

  
  DATA2 ={ 
            Median_weightptscnt = 8,
            TimeOut =5, 
            tol_inner = 0.025,
            testing_beats = 8,
            LP_ratio = 0.2,
            FFT_size = 256,
            min_bpm = 90,
            max_bpm = 180,
            tolpre = 0.1,
            tolpost = 0.1,
          } 

  -------------------------------------------------------------------- 
  function DATA2:GetFunctionMedianPeaks(t)
    local sz = #t
    local L = 0.6 -- positive median weighting value 
    local m = DATA2.Median_weightptscnt--10 -- previous values  count
    local a = 0.2--  positive mean weighting value
    
    local w = 0.2 -- a weighting value
    local largest_peak = 0
    local N
    local median
    
    local thresh_t = {}
    local sz = #t
    local median, mean, meancnt
    for i = 1, sz do
      local val = t[i] 
      largest_peak = math.max(largest_peak, val)
      N = w * largest_peak
      
      median = 0
      mean = 0
      meancnt = 0
      local med_t = {}
      for j = i-m, i do
        if t[j] then
          local val_med = t[j]
          med_t[#med_t+1] = val_med
          meancnt = meancnt + 1
          mean = mean + val_med
        end
      end
      if meancnt > 0 then mean = mean / meancnt end
      table.sort(med_t)
      if #med_t>= 3 then median = med_t[math.floor(#med_t/2)] end
      
      thresh_t[i] = L * median + a * mean + N
    end
    
    return thresh_t
  end
  --------------------------------------------------------------------  
  function DATA2:GetComplexDomainOnsetEnvelope_GetDifference(buft)  -- buft is after fft real
    local out_t = {}
    out_t[1] = 0
    out_t[2] = 0
    local magnitude_targ,phase_targ
    for frame = 3, #buft do
      local t = buft[frame]
      local t_prev = buft[frame-1]
      local t_prev2 = buft[frame-2]
      local sz = #t
      local sum = 0
      local Euclidean_distance, Im1, Im2, Re1, Re2
      local hp = 2--math.floor(sz*0.02)
      local lp = sz - math.floor(sz*DATA2.LP_ratio)
      for bin = hp, lp do
        magnitude_targ = t_prev[bin].magnitude
        phase_targ = t_prev[bin].phase + (t_prev[bin].phase - t_prev2[bin].phase)
        
        Re2 = magnitude_targ * math.cos(phase_targ);
        Im2 = magnitude_targ * math.sin(phase_targ);
        
        Re1 = t[bin].magnitude * math.cos(t[bin].phase);
        Im1 = t[bin].magnitude * math.sin(t[bin].phase);
                
        Euclidean_distance = math.sqrt((Re2 - Re1)^2 + (Im2 - Im1)^2)
        sum = sum + Euclidean_distance *(1-bin/sz) -- weight to highs
      end
      
      out_t[frame] = (sum^3) * buft[frame].rms
    end
    
    return out_t
  end
  ---------------------------------------------------
  function CopyTable(orig)--http://lua-users.org/wiki/CopyTable
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[CopyTable(orig_key)] = CopyTable(orig_value)
          end
          setmetatable(copy, CopyTable(getmetatable(orig)))
      else -- number, string, boolean, etc
          copy = orig
      end
      return copy
  end 
  
  --------------------------------------------------------------------  
  function DATA2:GetComplexDomainOnsetEnvelope(item) 
    local CDOE_blocks = {} 
      
      DATA2.item_ptr = item
      DATA2.item_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      DATA2.item_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local take = GetActiveTake(item)
      if not take or TakeIsMIDI(take ) then return end 
      
    local pcm_src  =  GetMediaItemTake_Source( take )
    local SR = reaper.GetMediaSourceSampleRate( pcm_src ) 
    DATA2.SR = SR
    local FFTsz = DATA2.FFT_size
    local window_spls = FFTsz*2
    local window = window_spls / SR
    local samplebuffer = reaper.new_array(window_spls) 
    local t = {}
    local id = 0
    
    local accessor = CreateTakeAudioAccessor( take )
    DATA2.CDOE_window = window 
    DATA2.CDOE_len = seek_len
    
      local buft = {}
      local buftid = 0
      for pos_seek = 0, DATA2.item_len, window do
          local pos_seek0 = pos_seek 
          local rms = 0
          local rmscnt = 0
          reaper.GetAudioAccessorSamples( accessor, SR, 1, pos_seek0, window_spls, samplebuffer ) 
          samplebuffer.fft_real(FFTsz, true, 1 )
          local sum = 0
          local rms = 0
          local rmsid = 0
          local prev_Re = 0
          local prev_Im = 0 
          buftid =buftid + 1
          buft[buftid] = {}
          local bin2 = -1
          for bin = 1, FFTsz/2 do 
            bin2 = bin2 + 2
            local Re = samplebuffer[bin2]
            local Im = samplebuffer[bin2 + 1]
            local magnitude = math.sqrt(Re^2 + Im^2)
            rms = rms + magnitude
            rmscnt = rmscnt + 1
            local phase = math.atan(Im, Re)
            buft[buftid][bin] = {magnitude=magnitude,phase=phase}
          end
          buft[buftid].rms = rms / rmscnt
      end
      
      local t = DATA2:GetComplexDomainOnsetEnvelope_GetDifference(buft) 
    samplebuffer.clear( )
    reaper.DestroyAudioAccessor( accessor )
    return t
  end
  --------------------------------------------------------------------  
  function DATA2:GetItemTempoBeats(item)
    -- get complex domain onset envelope
      local CDOE = DATA2:GetComplexDomainOnsetEnvelope(item) 
    -- calc median
      local threshold_median = DATA2:GetFunctionMedianPeaks(CDOE) 
    -- filter CDOE2 by median
      local CDOE2 = CopyTable(CDOE) 
      for i = 1, #CDOE2-DATA2.Median_weightptscnt do if CDOE2[i] < threshold_median[i+2] then CDOE2[i] = 0 end end CDOE2[#CDOE2-1] = 0 CDOE2[#CDOE2] = 0
    -- filter CDOE2 first points weighting noise
      for i = 1, DATA2.Median_weightptscnt*2 do CDOE2[i]  = 0 end
      local lasttrig
      for i = 1, #CDOE2 do
        if CDOE2[i] > 0 and not lasttrig then 
          lasttrig = true 
         elseif lasttrig == true and CDOE2[i] > 0 then 
          CDOE2[i] = 0 
         elseif CDOE2[i] == 0 then lasttrig = nil
        end 
      end
    -- collect beats by block, build predicted beats map
      local beats_src, beats_dest = DATA2:BuildBeatMap(CDOE2)
      return beats_src,beats_dest
      
    --[[ src table
      env = GetTrackEnvelopeByChunkName(  reaper.GetMediaItemTrack( item ), '<PANENV2' )
      reaper.DeleteEnvelopePointRange( env, 0, math.huge )
      for i = 1, #beats_src do
        local pos = beats_src[i] .pos
        val = 1000
        reaper.InsertEnvelopePoint( env, pos+DATA2.item_pos-0.0001, 0, 0, 0, 0, true )
        reaper.InsertEnvelopePoint( env, pos+DATA2.item_pos, val, 0, 0, 0, true )
        reaper.InsertEnvelopePoint( env, pos+DATA2.item_pos+0.05, 0, 0, 0, 0, true )
        
      end
      reaper.Envelope_SortPoints( env )

      -- dest table
      local t2 = beats_dest
        env = GetTrackEnvelopeByChunkName(  reaper.GetMediaItemTrack( item ), '<VOLENV2' )
        reaper.DeleteEnvelopePointRange( env, 0, math.huge )
        for i = 1, #t2 do
          local pos = t2[i]
          local sust = 200
          reaper.InsertEnvelopePoint( env, pos+DATA2.item_pos, 1000, sust, 0, 0, true )
          reaper.InsertEnvelopePoint( env, pos+DATA2.item_pos+0.3, sust, 0, 0, 0, true )
          reaper.InsertEnvelopePoint( env, pos+DATA2.item_pos-0.0001, sust, 0, 0, 0, true )
        end
        reaper.Envelope_SortPoints( env )]]
        
  end
  --------------------------------------------------------------------  
  function DATA2:GetClusters(t, evt_src)
    -- https://ofai.at/papers/oefai-tr-2001-19.pdf Automatic Extraction of Tempo and Beat from Expressive Performances // Simon Dixon 
    local ClusterWidth = 0.01 
    local testing_beats = DATA2.testing_beats
    local clusters = {}
    
    -- define clusters
    for eventid = evt_src, evt_src+testing_beats do 
        for j = evt_src,evt_src + testing_beats do
          if eventid~=j then  
            local IOI = math.abs(t[j].pos - t[eventid].pos)
            local k
            for clustid = 1, #clusters do
            
              local RMSinterval = 0 for m = 1, #clusters[clustid].IOIs do RMSinterval = RMSinterval + clusters[clustid].IOIs[m]  end RMSinterval = RMSinterval / #clusters[clustid].IOIs  clusters[clustid].interval = RMSinterval
              
              if math.abs(clusters[clustid].interval - IOI) < ClusterWidth then 
                if not clusters[clustid].IOIs then clusters[clustid].IOIs = {} end
                clusters[clustid].IOIs[#clusters[clustid].IOIs+1] =IOI 
                k = true
              end
            end
            if not k then clusters[#clusters+1] = {interval = IOI, IOIs = {IOI}} end
          end
        end 
    end
    
      
    -- filter min/max bpm
      for i = 1, #clusters do
        interval = clusters[i].interval
        bpm = 60/clusters[i].interval
        min_bpm = DATA2.min_bpm
        max_bpm = DATA2.max_bpm
        while bpm < min_bpm do 
          bpm = bpm * 2
          interval =interval / 2 
        end
        while bpm > max_bpm do 
          bpm = bpm / 2
          interval =interval * 2 
        end
        clusters[i] = {interval=interval,bpm=bpm}
      end
      
    return clusters
  end
  --------------------------------------------------------------------  
  function DATA2:BuildBeatMap(t_in)
    local E = {}
     
    -- convert t_in into points 
    for i = 1, #t_in do if t_in[i] > 0 then E[#E+1] = {pos=(i-1)* DATA2.CDOE_window, val = t_in[i]} end end  
    
    local clusters = DATA2:GetClusters(E, 1)
    
    -- algo initialization
    DATA2.agents = {}
    local k = 0
    for clust_i = 1, #clusters do
      for event = 1, math.min(#E, DATA2.testing_beats) do
        k = k+ 1
        local Ti = clusters[clust_i].interval
        DATA2.agents[k] = { 
                            beatInterval = Ti,
                            history = {E[event].pos},
                            matches = 1,
                           }
      end
    end
    
    for i =1,  #E do
      for j = 1,#DATA2.agents do
        local tolpre = DATA2.tolpre * DATA2.agents[j].beatInterval
        local tolpost =DATA2.tolpost * DATA2.agents[j].beatInterval
         
        local cur_agent_position = DATA2.agents[j].history[#DATA2.agents[j].history] 
        while cur_agent_position + tolpost < E[i].pos do
          DATA2.agents[j].history[#DATA2.agents[j].history+1] = cur_agent_position + DATA2.agents[j].beatInterval
          cur_agent_position = cur_agent_position + DATA2.agents[j].beatInterval
        end
        
        if E[i].pos >= cur_agent_position - tolpre and E[i].pos<= cur_agent_position + tolpost then
          DATA2.agents[j].matches = DATA2.agents[j].matches + 1
          DATA2.agents[j].history[#DATA2.agents[j].history] = E[i].pos
        end 
      end
    end
    
    local best_match = 0
    for i = 1, #DATA2.agents do
      if DATA2.agents[i].matches > best_match then 
        best_match = DATA2.agents[i].matches 
        best_match_id = i
      end
    end
    
    
    local out_dest ={}
    local out_src = {}
    for i = 1, #E do out_src[#out_src+1] = E[i].pos end
    if best_match_id then out_dest = DATA2.agents[best_match_id].history end
    return out_src, out_dest
  end
  -------------------------------------------------------------------- 
  function Parsing_filename()
    local filename = ({reaper.get_action_context()})[2]
    local script_title = GetShortSmplName(filename):gsub('%.lua','')
    
    local is_takemarks = script_title:match('share supposed beats as take markers') ~= nil 
    local is_stretchmarks = script_title:match('share supposed beats as stretch markers') ~= nil 
    local is_tempomarks = script_title:match('share supposed beats as tempo markers') ~= nil 
    local quantize = script_title:match('quantize to grid') ~= nil 
    local params = {
      is_takemarks = is_takemarks,                      
      is_stretchmarks = is_stretchmarks,                      
      is_tempomarks = is_tempomarks,                      
      quantize = quantize,                      
                      }
    main(params)  
  end
  ---------------------------------------------------------------------------------------------------------------------
  function GetShortSmplName(path) 
    local fn = path
    fn = fn:gsub('%\\','/')
    if fn then fn = fn:reverse():match('(.-)/') end
    if fn then fn = fn:reverse() end
    return fn
  end
  --------------------------------------------------------------------  
  function ShareTakeMarkers(take, beats_dest)
    DeleteTakeStretchMarkers( take, 0, GetNumTakeMarkers( take ) )
    for i = 1, #beats_dest do SetTakeMarker( take, -1, '', beats_dest[i] ) end
    UpdateArrange()
  end
  --------------------------------------------------------------------  
  function ShareStretchMarkers(take, beats_dest, quantize, item_pos)
    for idx = GetTakeNumStretchMarkers( take ),1,-1 do DeleteTakeMarker( take, idx-1 ) end 
    
    if quantize then
      local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( 0, item_pos )
      fullbeats = math.ceil(fullbeats)
      for i = 1, #beats_dest do 
        local pos_out = TimeMap2_beatsToTime( 0,fullbeats  + i)-item_pos 
        SetTakeStretchMarker( take, -1, pos_out, beats_dest[i] ) 
      end
     else
      for i = 1, #beats_dest do SetTakeStretchMarker( take, -1, beats_dest[i] ) end
    end
    UpdateArrange()
  end
  --------------------------------------------------------------------  
  function ShareTempoMarkers(item_pos, beats_dest)
    -- clear
      for markerindex = CountTempoTimeSigMarkers( 0 ), 1,-1 do DeleteTempoTimeSigMarker( 0, markerindex ) end
    -- add
      for i = 1, #beats_dest-4,4 do
        local timepos = item_pos+beats_dest[i] - beats_dest[1]
        local bpm = 4*60/(beats_dest[i+4] - beats_dest[i])
        SetTempoTimeSigMarker( 0, -1, timepos, -1, -1, bpm, -1, -1, -1 )
        -- reaper.SetTempoTimeSigMarker( proj, ptidx, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo )
      end
      reaper.UpdateTimeline()
  end
  --------------------------------------------------------------------  
  function main(params)
    -- init source
      local item = GetSelectedMediaItem(0,0)  
      if not item then return end 
      local take = GetActiveTake(item)
      if not take or TakeIsMIDI(take ) then return end  
      local item_pos = GetMediaItemInfo_Value( item, 'D_POSITION' )
      local item_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      if item_len > 20 then
        local ret = MB( 'This operation will FREEZE REAPER for couple of seconds, depending on length of audio source. Save your project before running this script. Still want to perform calculation?', 'mpl Detect tempo', 3 )
        if ret ~= 6 then return end
      end 
      beats_src,beats_dest = DATA2:GetItemTempoBeats(item)
      if not beats_dest then return end
    -- do stuff
      Undo_BeginBlock2( 0 )
      if params.is_takemarks then ShareTakeMarkers(take, beats_dest) end
      if params.is_stretchmarks then ShareStretchMarkers(take, beats_dest, params.quantize, item_pos) end
      if params.is_tempomarks then ShareTempoMarkers(item_pos, beats_dest) end
      Undo_EndBlock2( 0, 'Detect item tempo', 0xFFFFFFFF )
  end 
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.68,true)  then Parsing_filename() end
  
  