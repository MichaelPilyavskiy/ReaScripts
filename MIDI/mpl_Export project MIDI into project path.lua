-- @description Export project MIDI into project path
-- @version 1.0alpha2
-- @author MPL
-- @changelog
--    # fix tale PPQ different that default
--    # ignore 0xFF meta events

  -- [[debug search filter: NOT function NOT reaper NOT gfx NOT VF]]
  
  DATA2 = {
    ppq_step = 1,
    path_name = '!Midi',
    takes={}
          }

  ---------------------------------------------------------------------  
  function main() 
    -- collect takes
      for i =1 , CountSelectedMediaItems(0)do
        local item = GetSelectedMediaItem(0,i-1)
        local take = GetActiveTake(item)
        local track = GetMediaItemTrack( item )
        local retval, trname = GetTrackName( track )
        if take and ValidatePtr2( 0, take, 'MediaItem_Take*' ) and TakeIsMIDI(take) then
          DATA2.takes[#DATA2.takes+1] = 
          {
            take = take,
            item = item,
            track=track,
            name = trname,
          } 
        end
      end
      
    -- get takes data
      for i =1, #DATA2.takes do DATA2:MIDIEditor_GetEvts(DATA2.takes[i]) end
      
    -- build envelope
      for i =1, #DATA2.takes do DATA2:Expose_CC_pointsTables(DATA2.takes[i]) end
      
    -- interpolate using volume envelope
      for i =1, #DATA2.takes do DATA2:BuildPoints(DATA2.takes[i]) end
    
    -- set takes data
      for i =1, #DATA2.takes do DATA2:MIDIEditor_SetEvts(DATA2.takes[i]) end
      
    -- export to midi file
     for i =1, #DATA2.takes do DATA2:ExportMIDIFiles(DATA2.takes[i]) end
  end
  ---------------------------------------------------------------------  
  function DATA2:MIDIEditor_SetEvts(tk_t)
    local take = tk_t.take
    if not take then return end
    local t = tk_t.evts
      
    local str = ''
    local ppq_cur, ppq_last = 0,0
    
    -- discrete
    local max_ppq = 0
    for i = 1, #t-1 do     
      if not (t[i].remove and t[i].remove  == true) then 
        local ppq_cur = t[i].ppq_pos
        local offset = ppq_cur - ppq_last
        local str_per_msg = string.pack("i4Bs4", offset, t[i].flags&0xF , t[i].msg1) 
        str = str..str_per_msg
        ppq_last = ppq_cur
        max_ppq = math.max(max_ppq, ppq_cur)
      end
    end
    
    -- cc envelopes
    local CCt = tk_t.CCt
    for lane in pairs(CCt) do 
      for i = 1, #CCt[lane] do
        local env_t = CCt[lane]
        local ppq_cur = env_t[i].pos
        local val = env_t[i].val 
        local offset = ppq_cur - ppq_last
        local str_per_msg = ''
        local msgtype = (lane&0xF0)>>4
        if msgtype == 0xB or msgtype == 0xA then 
          local CC = (lane>>8)&0xFF
          if CC ~= 0 then str_per_msg = string.pack("i4BI4BBB", offset, 0, 3, lane&0xFF, (lane>>8)&0xFF, val) end
        end
        if msgtype == 0xE then 
          val = math.floor(val * (1<<14))
          str_per_msg = string.pack("i4BI4BBB", offset, 0, 3, lane&0xFF, val&0x7F, val>>7)  
        end
        if msgtype == 0xD then 
          str_per_msg = string.pack("i4BI4BBB", offset, 0, 3, lane&0xFF, val, 0)  
        end
        
        str = str..str_per_msg
        ppq_last = ppq_cur
      end
    end
    
    -- all note off
    local ppq_cur = t[#t].ppq_pos
    str = str..string.pack("i4Bs4", 0, t[#t].flags&0xF , t[#t].msg1)
    
    -- set / sort
    if tk_t.src_events then
      MIDI_SetAllEvts(take, str)
      MIDI_Sort(take) 
      local ret
      ret, tk_t.events_out = MIDI_GetAllEvts(take, "")
      MIDI_SetAllEvts(take, tk_t.src_events)
    end
  end
  ---------------------------------------------------------------------  
  function DATA2:BuildPoints(t) 
    local SR = VF_GetProjectSampleRate()
    local env = GetTrackEnvelopeByChunkName(  GetMediaItemTrack( t.item ), '<VOLENV2' )
    local scal_mode = GetEnvelopeScalingMode( env )
    local retval, env_chunk = GetEnvelopeStateChunk( env, '', false )
    for lane in pairs(t.CCt) do -- loop throgh envelopes 
      local msgtype = (lane&0xFF)>>4
      if not (msgtype == 0x8 or msgtype == 0x9) then 
      
        -- port CC env to track envelope
        local CCt = t.CCt[lane]
        local val
        DeleteEnvelopePointRangeEx( env, -1,0, math.huge) 
        for i = 1, #CCt do
          local shape = 1 -- square
          local flags = CCt[i].flags_high or 0
          if flags&16==16 then shape = 0 end -- linear
          if flags&32==32 then shape = 2 end -- slow start/end
          if flags&(16|32)==(16|32) then shape = 3 end -- fast start
          if flags&64==64 then shape = 4 end -- fast end
          if flags&(64|16)==(64|16) then shape = 5 end -- bezier
          val = CCt[i].val or 0 
          --if msgtype == 0xE then val = math.floor(val * 0.001) end
          InsertEnvelopePoint( env, CCt[i].pos, val, 5, CCt[i].bz_tension or 0, false, true )
        end
        Envelope_SortPoints(env)
        
        
        local endpos, last_value = CCt[#CCt].pos
        local st = CCt[1].pos
        CCt = {}
        for time = st, endpos, DATA2.ppq_step do
          local retval, value = Envelope_Evaluate( env, time, SR, 1 )
          if msgtype ~= 0xE then value = math.floor(value) end
          if not last_value or (last_value and last_value ~= value) then 
            table.insert(CCt, {pos = time, val = value})
          end
          last_value = value
        end
        t.CCt[lane] = CCt
      end
      
    end
    
   SetEnvelopeStateChunk( env, env_chunk, false )
  end
  ---------------------------------------------------------------------  
  function DATA2:Expose_CC_pointsTables(t)  
    local CCt = {}
    local evts = t.evts
    for i = 1, #evts do
      local msgtype = evts[i].msg1:byte(1)
      local byte2 = evts[i].msg1:byte(2)
      local byte3 = evts[i].msg1:byte(3)
      local val =0 
      local lane = 0
      
      if msgtype>>4 == 0xA then -- AT
        lane = msgtype + (byte2 << 8) 
        val = evts[i].msg1:byte(3)
      end
      
      if msgtype>>4 == 0xB and byte2 ~= 123 then--or msgtype>>4 == 0x9 or msgtype>>4 == 0x8 then -- CC
        lane = msgtype + (byte2 << 8) 
        val = evts[i].msg1:byte(3)
      end
      
      if msgtype>>4 == 0xE then -- pitch bend
        lane = msgtype-- + (byte2 << 8) 
        val = (evts[i].msg1:byte(2)) + (evts[i].msg1:byte(3)<<7)
        val = val/(1<<14)
      end
      
      if msgtype>>4 == 0xD then -- chan pres
        lane = msgtype 
        val = evts[i].msg1:byte(2)
      end
      if lane ~= 0 then
        if not CCt[lane] then CCt[lane] = {} end
        CCt[lane][#CCt[lane]+1] = {
                  pos = evts[i].ppq_pos, 
                  val = val,
                  msg1 = evts[i].msg1,
                  flags_high=evts[i].flags_high,
                  bz_tension=evts[i].bz_tension,
                  bz_type=evts[i].bz_type 
                  }
      end
    end
    t.CCt = CCt
  end
  -------------------------------------------------
  function DATA2:MIDIEditor_GetEvts(tk_t)
    local take = tk_t.take
    if not take then return end
    local evts = {}
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    if not gotAllOK then return end
    tk_t.src_events = MIDIstring
    local s_unpack = string.unpack
    local s_pack   = string.pack
    local MIDIlen = MIDIstring:len()
    local idx = 0    
    local offset, flags, msg1
    local ppq_pos = 0
    local nextPos, prevPos = 1, 1 
    
    local last_note_id = {}
    while nextPos <= MIDIlen do  
        prevPos = nextPos
        --offset, flags, msg1, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
        offset, flags, msg1, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
        ppq_pos = ppq_pos + offset
        local msgtype = msg1:byte(1)>>4
        local remove
        if msgtype == 0xA -- aftertouch
          or  (msgtype == 0xB and msg1:byte(2) ~=123)-- CC
          or  msgtype == 0xD -- CP
          or  msgtype == 0xE -- pitchbend
          or  msg1:byte(1) == 0xFF -- meta event, REMOVE COMPLETELY
          then 
          remove = true 
        end -- if CC 
        if msgtype == 0xF and  msg1:match('CCBZ') then
          evts[#evts].bz_type=msg1:byte(8)
          local bz_tension_int=
            msg1:byte(9)+
            (msg1:byte(10)<<8)+
            (msg1:byte(11)<<16)+
            (msg1:byte(12)<<24) 
          local sign = (bz_tension_int>>31)&1
          local E = (bz_tension_int>>23)&0xFF
          local fraction = 0
          for i = 1, 23 do
            local bid = 23-i
            local b = (bz_tension_int>>(bid-1))&1
            fraction = fraction + b*(2^(-i))
          end
          local bz_tension = ((-1)^sign) * (2^(E-127)) * (1+fraction)
          if math.abs(bz_tension) < 10^-15 then bz_tension = 0 end
          evts[#evts].bz_tension = bz_tension
          goto skip
        end 
        
        flags_high = flags&0x70 
        idx = idx + 1
        evts[idx] = {rawevt = s_pack("i4Bs4", offset, flags , msg1),
                            offset=offset, 
                            flags=flags, 
                            flags_high = flags_high,
                            msg1=msg1,
                            msgtype= msgtype,
                            ppq_pos = ppq_pos,
                            remove=remove
                            }
        ::skip::
      end
     tk_t.evts=evts
  end
  ----------------------------------------------------------------------
  function GetTakePPQ(item,take)
    local position = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local offset   = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
    local qn = reaper.TimeMap2_timeToQN(nil, position - offset)
    return reaper.MIDI_GetPPQPosFromProjQN(take, qn + 1)
  end
  ----------------------------------------------------------------------
  function DATA2:ExportMIDIFiles_FormChunk(events_raw,PPQ)
    -- header
    local chunk = 'MThd'
      -- header len
      ..string.char(0x00)
      ..string.char(0x00)
      ..string.char(0x00)
      ..string.char(0x06)
      -- file format
      ..string.char(0x00)
      ..string.char(0x00)
      -- number of tracks in the midi file.
      ..string.char(0x00)
      ..string.char(0x01)
      -- ticks
      ..string.char(PPQ>>8)
      ..string.char(PPQ&0xFF)
      -- track
      ..'MTrk'
    
    -- 
    local function makeoffset(offset)
      local str = ''
      --if ((offset>>21)&0x7F) > 0 then str = str..string.char(((offset>>21)&0x7F)|0x80) end
      if ((offset>>14)&0x7F) > 0 then str = str..string.char(((offset>>14)&0x7F)|0x80) end
      if ((offset>>7)&0x7F) > 0 then str = str.. string.char(((offset>>7)&0x7F)|0x80) end
      str = str..string.char((offset&0x7F) )
      return str
    end
    local events_chunk = ''
    local s_unpack = string.unpack
    local s_pack   = string.pack
    local MIDIlen = events_raw:len()
    local offset, flags, msg1
    local nextPos, prevPos = 1, 1  
    while nextPos <= MIDIlen do  
        prevPos = nextPos
        offset, flags, msg1, nextPos = s_unpack("i4Bs4", events_raw, prevPos)
        if (msg1:byte(1)>>4)==0xD then msg1 =msg1:sub(0,-2) end
        events_chunk = events_chunk..
          makeoffset(offset)..
          msg1
    end
    events_chunk = events_chunk
      ..string.char(0x00)
      ..string.char(0xFF)
      ..string.char(0x2F)
      ..string.char(0x00)
      
    -- add event length
    chunk = chunk
      ..string.char((events_chunk:len()>>24)&0xFF)
      ..string.char((events_chunk:len()>>16)&0xFF)
      ..string.char((events_chunk:len()>>8)&0xFF)
      ..string.char(events_chunk:len()&0xFF)
      ..events_chunk
    return chunk
  end
  ----------------------------------------------------------------------
  function DATA2:ExportMIDIFiles(tk_t)
    local take = tk_t.take
    local item = tk_t.item
    local name = tk_t.name
    local out_fp =GetProjectPath()..'/'..DATA2.path_name
    RecursiveCreateDirectory( out_fp, 0 )
    out_fp = out_fp..'/'..name..'.mid'
    
    local PPQ = GetTakePPQ(item,take)
    local chunk = DATA2:ExportMIDIFiles_FormChunk(tk_t.events_out, PPQ)
    
    f=io.open(out_fp, 'wb')
    f:write(chunk)
    f:close()
  end
  
                
                
                
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.42) if ret then local ret2 = VF_CheckReaperVrs(6.68,true) if ret2 then 
    reaper.Undo_BeginBlock2( 0 )
    main() 
    reaper.Undo_EndBlock2( 0, 'test', 0xFFFFFFFF )
  end end