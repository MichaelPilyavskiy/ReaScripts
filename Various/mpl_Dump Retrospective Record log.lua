-- @description Dump Retrospective Record log
-- @version 1.01
-- @author MPL, Justin
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @about Dump recent MIDI messages log
-- @changelog 
--    # fix description, remove VF dependency


  function DumpRetrospectiveLog_CollectEvents()
    local t = {}
    local i,last_ts,item_len_spls = 0,0,0
    
    while true do
      local retval, buf, tsval, devIdx, projPos = reaper.MIDI_GetRecentInputEvent(i)
      if retval == 0 then break end
      if i > 0 and tsval < last_ts-4*48000 then break end -- 4sec of nothing, stop looking for more events
      
      i = i + 1
      
      if (devIdx & 0x10000) == 0 or devIdx == 0x1003e then
        devIdx=devIdx&0xFFFF
        if devIdx and not t[devIdx] then t[devIdx] = {} end
        t[devIdx][#t[devIdx] + 1] = {msg1= buf, ts = tsval, pp=projPos}
        last_ts = tsval
      end
    end
    for devIdx in pairs(t) do
      for i = 1,#t[devIdx] do
        local ts = t[devIdx][i].ts - last_ts
        t[devIdx][i].ts = ts
        item_len_spls = math.max(item_len_spls, ts)
      end
    end
    return t,  item_len_spls
  end
  -------------------------------------------
  function ApplyMIDIdata(take, midi_data_t, itempos, SR)
    local midistr = ''
    local ppq_cur, ppq_cur_last
    local lpos = -1
    for evt = #midi_data_t,1,-1 do
      local evt_t = midi_data_t[evt]
      local ppq_evt = math.floor(reaper.MIDI_GetPPQPosFromProjTime( take, itempos+ evt_t.ts / SR ))
      ppq_cur = ppq_evt
      if not ppq_cur_last then ppq_cur_last = ppq_cur end
      local str_per_msg = string.pack("i4BI4BBB", ppq_cur - ppq_cur_last, 0, 3, evt_t.msg1:byte(1),evt_t.msg1:byte(2),evt_t.msg1:byte(3))
      ppq_cur_last = ppq_cur
      midistr = midistr..str_per_msg
      if evt == #midi_data_t then lpos = evt_t.pp end
    end
    reaper.MIDI_SetAllEvts(take, midistr)
    reaper.MIDI_Sort(take)
    return lpos
  end
  -------------------------------------------
  function DumpRetrospectiveLog()
    -- get data
      local SR = tonumber(reaper.format_timestr_pos( 1, '', 4 ))
      local midi_t, item_len_spls = DumpRetrospectiveLog_CollectEvents()
    
    -- Create item at first selected track or new one if no track selected 
      local track = reaper.GetSelectedTrack(0,0)
      if not track then 
        reaper.InsertTrackAtIndex(  reaper.CountTracks( 0 ), 1 )
        track = reaper.GetTrack(0,reaper.CountTracks( 0 )-1)
      end 
    
    -- Add item
      local itempos = reaper.GetCursorPosition()
      local item =  reaper.CreateNewMIDIItemInProj( track,  itempos,  itempos + item_len_spls / SR)
    
    -- pass data to item
      local i = 1
      for devIdx in pairs(midi_t) do
        local retval, nameout = reaper.GetMIDIInputName( devIdx, '' )
        local take = reaper.GetActiveTake( item )
        if i ~= 1 then take = reaper.AddTakeToMediaItem( item ) end
        local retval, nameout = reaper.GetMIDIInputName( devIdx, '' )
        reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', nameout, 1 )
        local lpos = ApplyMIDIdata(take, midi_t[devIdx], itempos, SR)
        if lpos >= 0 then
          reaper.SetMediaItemPosition(item,lpos,false)
        end
        i = i + 1
      end
    
    -- update arrange
      reaper.UpdateArrange()
  end
  
  if tonumber(reaper.GetAppVersion():match('[%d%.]+')) >= 6.39 then DumpRetrospectiveLog() end
  