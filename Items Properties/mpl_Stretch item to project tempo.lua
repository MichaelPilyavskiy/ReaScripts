-- @description Stretch item to project tempo
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # ask before stretch

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


  DATA ={}
  DATA2 ={}
  
  --------------------------------------------------------------------  
  function DATA2:ProcessTable_Oversample(t, os)
    local sz= #t
    local t_new = {}
    t_newID = 0 
    for i = 1, sz do 
      local diff = 0
      if t[i+1] then diff = t[i+1] - t[i] end
      for ratio = 1, os do
        t_newID = t_newID + 1
        t_new[t_newID] = t[i] + diff* ratio / os
      end
    end
    return t_new
  end
  --------------------------------------------------------------------  
  function DATA2:ProcessTable_Expand(t)
    local sz= #t
    for i = 1, sz do t[i] = t[i]^2 end
  end  
  --------------------------------------------------------------------  
  function DATA2:GetComplexDomainOnsetEnvelope_GetDifference(buft)  -- buft is after fft real
    local out_t = {}
    out_t[1] = 0
    out_t[2] = 0
    
    for frame = 3, #buft do
      local t = buft[frame]
      local t_prev = buft[frame-1]
      local t_prev2 = buft[frame-2]
      local sz = #t
      local sum = 0
      local Euclidean_distance, Im1, Im2, Re1, Re2
      local hp = 1--math.floor(sz*0.02)
      local lp = sz - math.floor(sz*0.1)
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
      
      out_t[frame] = sum * buft[frame].rms
    end
    
    return out_t
  end
  --------------------------------------------------------------------  
  function DATA2:GetRMSPeakRatio(t) 
    local rms = 0 
    local peak = 0
    local sz = #t
    local val
    for  i = 1,sz do
      val = t[i]
      rms = rms + val
      peak = math.max(peak, val)
    end
    rms = rms / sz
    return rms, peak
  end
  --------------------------------------------------------------------  
  function DATA2:GetComplexDomainOnsetEnvelope(item) 
    local CDOE_blocks = {}
    
      
      DATA2.item_ptr = item
      DATA2.item_len = GetMediaItemInfo_Value( item, 'D_LENGTH' )
      local take = GetActiveTake(item)
      if not take or TakeIsMIDI(take ) then return end 
      
    local pcm_src  =  GetMediaItemTake_Source( take )
    local SR = reaper.GetMediaSourceSampleRate( pcm_src ) 
    DATA2.SR = SR
    local seek_len = math.min(6,DATA2.item_len)
    local FFTsz = 256
    local window_spls = FFTsz*2
    local window = window_spls / SR
    local samplebuffer = reaper.new_array(window_spls) 
    local t = {}
    local id = 0
    
    local accessor = CreateTakeAudioAccessor( take )
    DATA.CDOE_window = window
    DATA.CDOE_len = seek_len
    
    for block_pos = 0, DATA2.item_len, seek_len do
      local pos_start = block_pos-- or 0
      local pos_end = pos_start + seek_len
      local buft = {}
      local buftid = 0
      for pos_seek = pos_start, pos_end, window do
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
      --VF2_NormalizeT(t)
      local rms, peak = DATA2:GetRMSPeakRatio(t)
      CDOE_blocks[#CDOE_blocks+1] = {t =t, pos = block_pos,rms=rms, peak=peak}
    end
    
    samplebuffer.clear( )
    reaper.DestroyAudioAccessor( accessor )
    
    --[[msg(#CDOE_blocks)
    if DATA2.item_len ~= 0 and DATA2.item_len < seek_len then
      local copy_times = math.floor(seek_len / DATA2.item_len)
      local CDOE_blocks_src = CopyTable(CDOE_blocks)
      for i = 1, copy_times do
        for block = 1, #CDOE_blocks_src do
          CDOE_blocks[#CDOE_blocks+1] = CDOE_blocks_src[block]
        end
      end
      msg(#CDOE_blocks_src)
      
    end]]
    return CDOE_blocks
  end
  -------------------------------------------------------------------- 
  function DATA2:GetAutocorellation(t) 
    local ACF_out = {}
    local sz = #t
    for offs =0, sz-1 do
      local sum = 0
      for j = 1, sz do
        if t [j+offs] then sum = sum + t[j] * t [j+offs] end
      end
      ACF_out[offs+1] = sum
    end
    return ACF_out
  end
  --------------------------------------------------------------------  
  function DATA2:GaussianWeighting(t,tempo_human_mid0, bt0, fftmode)
    local window = DATA.CDOE_window
    local sz = #t
    local bt = bt0 or 1.4 -- octaves
    local tempo_human_mid = tempo_human_mid0 or 120
    for i = 1, sz do
      local cur_tempo = 60/(window*(i-1))
      local temp = -0.5 * (  (math.log(cur_tempo/tempo_human_mid,2)) / bt) ^2
      if not fftmode then
        t[i] = math.exp(temp) * t[i]
       else
        local Re = t[i].real
        local Im = t[i].imaginary
        local magnitude = math.exp(temp) * (math.sqrt(Re^2 + Im^2))
        local phase = math.atan(Im, Re)
        t[i].real = magnitude * math.cos(phase);
        t[i].imaginary = magnitude * math.sin(phase);
      end
    end
    return t
  end
  -------------------------------------------------------------------- 
  function DATA2:FFT(t)
    local sz = #t
    local samplebuffer = reaper.new_array(t,sz) 
    local t = {}
    samplebuffer.fft_real(sz, true, 1 )
    
    for bin = 1, sz do
      if (bin-1)*2 + 1 <= sz then 
        local Re = samplebuffer[(bin-1)*2 + 1]
        local Im = samplebuffer[(bin-1)*2 + 2]
        t[bin] = {real = Re, imaginary = Im, magn = math.sqrt(Re^2 + Im^2)}
      end
    end
    
    samplebuffer.clear()
    
    return t
  end
  --------------------------------------------------------------------  
  function DATA2:PrepareForFFT(t)    -- quantize to power of 2
      local sz = #t
      local init_sz = sz
      local active
      for i = 32, 0, -1 do
        if not active and sz&(2^i) == (2^i) then
          active = true
         elseif active == true and sz&(2^i) == (2^i) then
          sz = sz~(2^i)
        end 
      end
      
    for i = sz+1, init_sz do t[i] = nil end
  end
  -------------------------------------------------------------------- 
  function DATA2:GetFunctionMedianPeaks(t)
    local peaks = {}
    local sz = #t
    local L = 0.1 -- positive median weighting value 
    local m = math.floor(sz*0.01) -- previous values count
    local a = 1-- positive mean weighting value
    
    local w = 0.001 -- a weighting value
    local largest_peak = 0
    local N
    local median
    
    local thresh_t = {}
    local sz = #t
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
    VF2_NormalizeT(thresh_t)
    VF2_NormalizeT(t)
    for i = 1, sz do
      if t[i] > thresh_t[i] and thresh_t[i] > 0.1 then 
        peaks[#peaks+1] = i
      end
    end
    
    
    return peaks,thresh_t
  end
  ---------------------------------------------------------------------------------------------------------------------
  function VF2_NormalizeT(t, key)
    local m = 0 
    for i in pairs(t) do 
      if not key then 
        m = math.max(math.abs(t[i]),m) 
       else
        m = math.max(math.abs(t[i][key]),m) 
      end
    end
    for i in pairs(t) do 
      if not key then
        t[i] = t[i] / m 
       else 
        t[i][key] = t[i][key] / m 
      end
    end
  end 
  -------------------------------------------------------------------- 
  function DATA2:iFFT(t)
    local sz = #t
    
    local FFT_src = {}
    local tid = 0
    for bin = 1, sz do
      tid = tid + 1
      FFT_src[tid] = t[bin].real
      tid = tid + 1
      FFT_src[tid] = t[bin].imaginary
    end
    
    local samplebuffer = reaper.new_array(FFT_src) 
    samplebuffer.ifft_real(#FFT_src, true, 1 )
    samplebuffer.resize(#FFT_src)
    t = samplebuffer.table()
    --table.insert(t,1,0) -- compensate DC / niquist
    return t
  end
  --------------------------------------------------------------------  
  function DATA2:GetMostLikelyOffset(t, min_offs, max_offs)
    local sz= #t
    
    -- get max value
    local max_val = 0
    local val
    for offs = min_offs, max_offs do 
      local sum = 0
      val = t[offs]
      if not val then return end
      if val > max_val then id = offs end
      max_val = math.max(max_val, val)
    end
    out_id = id
    if not out_id then return end
    -- confirm
      local area = 20
      for fineoffs = out_id-area, out_id+area, 0.1 do
        local sum = 0
        local max_val_local = 0
        for ratio= 1, 4 do
          if t[math.floor(fineoffs * ratio)] then 
            val = t[math.floor(fineoffs * ratio)]
            sum = sum + val
          end
        end
        if sum  > max_val then 
          out_id =fineoffs  
        end
        max_val = math.max(max_val, sum)
      end
    return out_id
  end 
  -------------------------------------------------------------------- 
  function DATA2:GetCDOEShift(CDOE, ACF_offset)
    if not ACF_offset then return end
    local bestoffs = 0
    local max_sum = 0
    local sz = #CDOE
    local max_ratio = math.floor(sz / ACF_offset) 
    for offs = 1, ACF_offset do
      local sum = 0 
      local max_val = 0
      for ratio = 0, max_ratio-1 do
        local id = math.floor(offs + ACF_offset * ratio)
        sum = sum + CDOE[id]
        max_val = math.max(max_val, CDOE[id])
      end
      if sum * max_val > max_sum then bestoffs = offs end
      max_sum = math.max(max_sum, sum*max_val)
    end
    
    -- confirm
      local area = 10
      local sums_t = {}
      for fineoffs = bestoffs-area, bestoffs+area, 0.1 do
        local sum = 0
        for ratio= 1, 6 do
          if CDOE[math.floor(fineoffs * ratio)] then 
            val = CDOE[math.floor(fineoffs * ratio)]
            sum = sum + val
          end
        end
        sums_t[#sums_t+1] = sum
        if sum  > max_sum then 
          bestoffs =fineoffs  
        end
        max_val = math.max(max_sum, sum)
      end
    
    
    return bestoffs
  end
  --------------------------------------------------------------------  
  function DATA2:GetItemTempo(item)
    -- init output
      local bpm, beatoffs_sec = 0,0
    -- detection limits
      local min_bpm = 70
      local max_bpm = 200      
      
    -- get complex domain onset envelope
      local CDOE_blocks = DATA2:GetComplexDomainOnsetEnvelope(item)
      if not CDOE_blocks then return end
    -- calculate beats
      for i = 1, #CDOE_blocks do
        local CDOE = CDOE_blocks[i].t
        -- get autocorellation / weight
          local ACF = DATA2:GetAutocorellation(CDOE)
          local ACF_GW = DATA2:GaussianWeighting(ACF, 120, 2) 
          DATA2:PrepareForFFT(ACF_GW)
        -- oversample
          local os = 16
          for i = 1 ,#ACF_GW do ACF_GW[i] = ACF_GW[i]end
          local ACF_GW_OS = DATA2:ProcessTable_Oversample(ACF_GW, os)
        --- do FFT / filter
          local FFT_OS = DATA2:FFT(ACF_GW_OS)
          local FFT_GW_OS = DATA2:GaussianWeighting(FFT_OS,  80, 3, true)
        -- do iFFT / multiply by filtered iFFT ACF 
          local ACF_iFFT = DATA2:iFFT(FFT_GW_OS)
          for i = 1, #ACF_GW_OS do ACF_GW_OS[i] = ACF_GW_OS[i] * (math.max(ACF_iFFT[i]*0.01, 0)) end
        -- get offset.
          local ACF_offset_max = math.floor(os* (60 / min_bpm) / DATA.CDOE_window)
          local ACF_offset_min = math.floor(os* (60 / max_bpm) / DATA.CDOE_window) 
          local ACF_offset = DATA2:GetMostLikelyOffset(ACF_GW_OS, ACF_offset_min, ACF_offset_max)
        -- get shift
          local CDOE_OS = DATA2:ProcessTable_Oversample(CDOE, os)
          local ACF_shift, sum2rms = DATA2:GetCDOEShift(CDOE_OS, ACF_offset)
        -- get BPM 
          if not ACF_offset then return end
          local bpm = os * 60/ (DATA.CDOE_window * ACF_offset)
          local max_bpm2 = 200
          if bpm > max_bpm2 then bpm = bpm / 2 end 
          local beat_sec = DATA.CDOE_window * ACF_offset / os
          local beat_offs_sec = DATA.CDOE_window * ((ACF_shift / os)-1)
          CDOE_blocks[i].beat_sec = beat_sec
          CDOE_blocks[i].beat_offs_sec = beat_offs_sec
          CDOE_blocks[i].bpm = bpm 
          CDOE_blocks[i].sum2rms = sum2rms 
      end
      
      
    -- build beats
      local beatmarks = {} 
      for i = 1, #CDOE_blocks do --#CDOE_blocks do
        local pos = CDOE_blocks[i].pos
        local beat_sec = CDOE_blocks[i].beat_sec
        local beat_offs_sec = CDOE_blocks[i].beat_offs_sec
        for beat = 0, 32 do
          pos_out =  beat*beat_sec + beat_offs_sec 
          if pos_out <  DATA.CDOE_len then 
            beatmarks[#beatmarks+1] = {bpm = CDOE_blocks[i].bpm, pos =  pos+ pos_out}
          end
        end
      end
    
    -- calc tempo estimation
      local tempo_bpm = DATA2:ExtractTempoCorrelation(beatmarks)
      if tempo_bpm then  return math_q(tempo_bpm*2)/2 end
  end
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
  ---------------------------------------------------------------------------------------------------------------------
    function math_q(num)  if math.abs(num - math.floor(num)) < math.abs(num - math.ceil(num)) then return math.floor(num) else return math.ceil(num) end end
  
  -------------------------------------------------------------------- 
  function DATA2:ExtractTempoCorrelation(beatmarks)
    local q_sz = 200
    local max_tempo = 200
    local sz = #beatmarks
    local corr_sz = max_tempo*q_sz
    local tempo_corellation = {} for i = 1, corr_sz do tempo_corellation[i] = 0 end
    for i = 1, sz do
      tid = math.floor(beatmarks[i].bpm*q_sz)
      tempo_corellation[tid] = (tempo_corellation[tid] or 0) + 1
    end
    local trig = 0
    for i= 1, corr_sz do 
      if tempo_corellation[i] > 0 and trig  == 0 then 
        trig = tempo_corellation[i] 
      elseif tempo_corellation[i] > 0 and trig > 0 then 
        --trig = tempo_corellation[i] 
       elseif trig > 0 then
        trig = trig - 0.1
        tempo_corellation[i] = trig
      end
      trig = math.max(trig,0)
    end
    local doubled_t = CopyTable(tempo_corellation)
    --collapse
    local tempo = 0
    for i= 1, corr_sz do 
      local dtval = doubled_t[math.floor(i*2)]
      if  dtval and dtval~=0 then tempo_corellation[i] = tempo_corellation[i] * dtval  end
    end
    local max = 0 
    for i= 1, corr_sz do 
      if tempo_corellation[i] > max then tempo = i / q_sz end 
      max = math.max(max, tempo_corellation[i])
    end
    return tempo
  end
  --------------------------------------------------------------------  
  function main()
    -- init source
      local item = GetSelectedMediaItem(0,0)  
      if not item then return end 
      local take = GetActiveTake(item)
      if not take or TakeIsMIDI(take ) then return end 
       tempo_bpm = DATA2:GetItemTempo(item)
      if tempo_bpm then
      
        local ret = MB('Stretch item with tempo '..tempo_bpm..'?','Stretch to tempo',3 )
        if ret == 6 then 
          local  master_tempo = Master_GetTempo()
          local rate =  master_tempo / tempo_bpm
          if rate  < 0.6 then 
            tempo_bpm = tempo_bpm /2 
           elseif rate  > 1.4 then 
            tempo_bpm = tempo_bpm *2 
          end
          local rate =  master_tempo / tempo_bpm
          local cur_rate = GetMediaItemTakeInfo_Value( take, 'D_PLAYRATE' )
          SetMediaItemTakeInfo_Value( take, 'D_PLAYRATE', cur_rate *rate  )
          SetMediaItemInfo_Value( item, 'D_LENGTH',DATA2.item_len/rate  )
          reaper.UpdateArrange()
          reaper.Undo_BeginBlock2( 0 )
          reaper.Undo_EndBlock2( 0, 'Stretch item to tempo', 0xFFFFFFFF )
        end
      end
  end 
  if VF_CheckReaperVrs(6.68,true)  then main() end
  
  