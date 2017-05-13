-- @version 1.0
-- @author MPL
-- @description Create snap offset at maximum peak in first second of take
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init


  function main()
    local item = reaper.GetSelectedMediaItem(0, 0)
    if not item then return end
    local take = reaper.GetActiveTake(item)
    if reaper.TakeIsMIDI(take) then return end
    local source = reaper.GetMediaItemTake_Source(take)
    
    local accessor = reaper.CreateTakeAudioAccessor(take)
    local samplerate = reaper.GetMediaSourceSampleRate(source)
    local channels = reaper.GetMediaSourceNumChannels(source)
    local start_pos = 0
    local samples = samplerate
    local buf_size = samples -- first 1 second
    local buffer = reaper.new_array(buf_size*channels)
    
    reaper.GetAudioAccessorSamples(accessor, samplerate, channels, start_pos, samples, buffer)
    local sample_max, max_peak_sample, sample_max0 = 0
    for i = 1, buf_size do
     local sample = math.abs(buffer[i]) 
     sample_max = math.max(sample, sample_max)
     if sample_max ~= sample_max0 -- if max peak value is changed
        then max_peak_sample = i/channels end
     sample_max0 = sample_max
    end
    
    local snap_offset_position = max_peak_sample / samplerate
    reaper.DestroyAudioAccessor(accessor)
    reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", snap_offset_position)
    reaper.UpdateArrange() 
  end
  
  local script_title = "Create snap offset at maximum peak in first second of take"
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock(script_title, 0)