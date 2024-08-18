-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @description Set RS5k sample start offset based on sample peak
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


function main()
    local ret, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    local track = reaper.CSurf_TrackFromID( tracknumberOut, false )
    if not track then return end
    ret, fn = reaper.TrackFX_GetNamedConfigParm(track, fxnumberOut, "FILE0")
    if not ret then return end
    
    local data = {}
    
    local wind = 0.002
    local bsz = 2
    local buf = new_array(bsz)
    local pcmsrc = PCM_Source_CreateFromFile( fn )
    local peakrate =  GetMediaSourceSampleRate( pcmsrc )
    local numchannels = 1
    local numsamplesperchannel = 1
    local want_extra_type = 0
    local srclen, lengthIsQN = GetMediaSourceLength( pcmsrc )
    for starttime = 0, srclen, wind do
      PCM_Source_GetPeaks( pcmsrc, peakrate, starttime, numchannels, numsamplesperchannel, want_extra_type, buf )
      data[#data+1] = buf[1]
    end
    PCM_Source_Destroy( pcmsrc )
    
    local max_val = 0
    for i = 1, #data do data[i] = math.abs(data[i]) max_val = math.max(max_val, data[i]) end
    for i = 1, #data do data[i] = data[i]/max_val end -- normalize
    
    -- manage to get peak
      local peaktime_normal = 0
      for i = 1, #data do if data[i] == 1 then peaktime_normal = i*wind / srclen break end end
      
    
    if peaktime_normal ~= 0 then reaper.TrackFX_SetParamNormalized( track, fxnumberOut, 13, peaktime_normal ) end
  end

  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true)then 
    Undo_BeginBlock() 
    main() 
    Undo_EndBlock('Set RS5k sample start offset based on sample peak', 1) 
  end