-- @version 1.01
-- @author MPL
-- @changelog
--    # fix ReaPack header
-- @description Generate MIDICC from audio take
-- @website http://forum.cockos.com/member.php?u=70694
  
    
  function m(s) reaper.ShowConsoleMsg(s)end
 
  ---------------------------------------------------------------------------------------------------------------------  
  function Get_take_data(item, window)
    if item == nil then return end
    local take = reaper.GetActiveTake(item)
    
    local item_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    
      local sum_t = {}
      local aa = {}
      aa.accessor = reaper.CreateTakeAudioAccessor(take)
      aa.src = reaper.GetMediaItemTake_Source(take)
      aa.numch = reaper.GetMediaSourceNumChannels(aa.src)
      aa.rate = reaper.GetMediaSourceSampleRate(aa.src) 
      
      aa.window_sec = window 
      size = math.ceil(aa.window_sec*aa.rate)
      
      for read_pos = 0, item_len, aa.window_sec do
                  
        aa.buffer = reaper.new_array(size*2)
        aa.buffer_com = reaper.new_array(size*2)
                     
        reaper.GetAudioAccessorSamples(
                          aa.accessor , --AudioAccessor
                          aa.rate, -- samplerate
                          aa.numch, -- numchannels
                          read_pos, -- starttime_sec
                          size, -- numsamplesperchannel
                          aa.buffer) --samplebuffer
                          
        -- merge buffers dy duplicating sum/2
          for i = 1, size*aa.numch - 1, aa.numch do
            aa.buffer_com[i] = (aa.buffer[i] + aa.buffer[i+1])/aa.numch
            aa.buffer_com[i+1] = 0
          end
                                            
               -- Get RMS sum in defined range
                  aa.buffer_com_t = aa.buffer_com.table(1,size, true)
                  sum_com = 0
                  for i = 1, size do
                    sum_com = sum_com + math.abs(aa.buffer_com_t[i])
                  end    
                  table.insert(sum_t, sum_com)
          
      end
    reaper.DestroyAudioAccessor(aa.accessor)

    -- normalize table
      local max_com = 0
      for i =1, #sum_t do max_com = math.max(max_com, sum_t[i]) end
      local com_mult = 1/max_com      
      for i =1, #sum_t do sum_t[i]= sum_t[i]*com_mult  end
      table.insert(sum_t, 1, 0)
      return sum_t, aa.window_sec
  end
  
  
  
  ---------------------------------------------------------------------------------------------------------------------
  
  function main ()
    local item = reaper.GetSelectedMediaItem(0,0)
    if item == nil then return end
    
    i_pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
    i_len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
    take =  reaper.GetActiveTake( item )
    if  reaper.TakeIsMIDI( take ) then return end
    
    _, cc_str =  reaper.GetUserInputs( 'CC', 1, '', '' )
    cc_id = tonumber(cc_str)
    _, window_ms =  reaper.GetUserInputs( 'RMS window', 1, '(seconds)', 0.05 )
    window_ms = tonumber(window_ms)
    if not cc_id or not  window_ms then return end
    
    t, window = Get_take_data(item, window_ms)
    
    track = reaper.GetMediaItem_Track(item)
    track_idx = reaper.CSurf_TrackToID( track, false )
    reaper.InsertTrackAtIndex( track_idx, true )
    reaper.TrackList_AdjustWindows( false )
    new_track = reaper.GetTrack(0, track_idx)
    new_item = reaper.CreateNewMIDIItemInProj( new_track, i_pos, i_pos+i_len )
    new_take =  reaper.GetActiveTake( new_item )
    
    function addCC(take, ppq, value)
      reaper.MIDI_InsertCC(take, 
                           false,--boolean selected, 
                           false,--boolean muted, 
                           ppq,--number ppqpos, 
                           176,--integer chanmsg, 
                           0,--integer chan, 
                           cc_id, 
                           value)
    end
    
    reaper.UpdateItemInProject(new_item)
    
    for i = 1, #t-10 do
      pos = i_pos + i_len*(i/#t)
      ppq = reaper.MIDI_GetPPQPosFromProjTime( new_take, pos )
      lin_val = math.floor(t[i]*127)
      addCC(new_take, ppq, lin_val)
      --m(pos)
    end
    reaper.Main_OnCommand( 40289, 0 ) -- unselect all
    reaper.SetMediaItemSelected( new_item, true )
    
    reaper.UpdateArrange()
  end
  
  
  main()