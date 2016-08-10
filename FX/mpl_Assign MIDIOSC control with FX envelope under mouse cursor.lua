-- @description Assign MIDIOSC control with FX envelope under mouse cursor
-- @version 1.0
-- @author mpl
-- @changelog
--    + init release
-- @website http://forum.cockos.com/member.php?u=70694


  --osc = '/1/fader4'
  --is_soft_takeover = 0
  --midiCC = 12
  --midiChan = 1
  
    
    
    
----------------------------------------------------------------------------
  function msg(s) reaper.ShowConsoleMsg(s..'\n') end 
----------------------------------------------------------------------------   
  function GetEnvelopeUnderMouseCursor() local fx_ID
    -- allocate track FX envelope
      reaper.BR_GetMouseCursorContext()
      local envelope = reaper.BR_GetMouseCursorContext_Envelope()
      if not envelope then return end
      local br_env = reaper.BR_EnvAlloc( envelope, false )
      local _, chunk = reaper.GetEnvelopeStateChunk( envelope, '' )
    -- check envelope is FX envelope 
       if not chunk:find('PARMENV' ) then return end
       
    -- get env track
      local track = reaper.BR_EnvGetParentTrack( br_env )  
      
    --get param ID
      local param_ID = chunk:match('[%d]+')
      if not param_ID or not tonumber(param_ID) then return end
      param_ID = tonumber(param_ID)
      
    -- get FX ID
      local _, env_name = reaper.GetEnvelopeName( envelope, '' )
      local sl = env_name:find("/")
      if not sl then return end
      local par_name = env_name:sub(0, sl -3 )
      local fx_name = env_name:sub(sl +2 )
      if fx_name:find('/') then fx_name = fx_name:sub(fx_name:reverse():find('/')) end  
      for i = 1,  reaper.TrackFX_GetCount( track ) do
        local _, t_fx_name = reaper.TrackFX_GetFXName( track, i-1, '' )
        t_fx_name= t_fx_name:match('[^%a%:]+.*'):sub(2)
        if t_fx_name:find('/') then t_fx_name = t_fx_name:sub(1+-t_fx_name:reverse():find('/')) end
        if t_fx_name:find(fx_name) then fx_ID = i-1 break end
      end
      
    return track, fx_ID, param_ID
  end
  
----------------------------------------------------------------------------
  
  function TrackFX_GetSetMIDIOSCLearn(track, fx_index, param_id, is_set, string_midiosc)
    -- is_set == 0 - get
    -- is_set == -1 - remove all learn from pointed parameter    
    -- return midichan,midicc, osclearn
    -- if in_chan == -1 then remove learn for current param
    if fx_index == nil then return end
    fx_index = fx_index+1 -- 0-based    
                  --param_id 0-based                  
    local out_midi_num, chunk,exists, guid_id,chunk_t,i,fx_chunks_t,fx_count,
      fx_guid,param_count,active_fx_chunk,active_fx_chunk_old,active_fx_chunk_t,
      out_t,midiChannel,midiCC,insert_begin,insert_end,active_fx_chunk_new,main_chunk,temp_s
      
    if track == nil then reaper.ReaScriptError('MediaTrack not found') return end
    _, chunk = reaper.GetTrackStateChunk(track, '')      
    --reaper.ShowConsoleMsg(chunk)
    if reaper.TrackFX_GetCount(track) == 0 then reaper.ReaScriptError('There is no FX on track') return end
    if fx_index > reaper.TrackFX_GetCount(track) then reaper.ReaScriptError('FX index > Number of FX') return end
    -- get com table
      main_chunk = {}
      for line in chunk:gmatch("[^\n]+") do 
        table.insert(main_chunk, line)
      end      
    -- get fx chunks
      chunk_t= {}
      temp_s = nil
      i = 1
      for line in chunk:gmatch("[^\n]+") do 
        if temp_s ~= nil then temp_s = temp_s..'\n'..line end
        if line:find('BYPASS') ~= nil then
          temp_s = i..'\n'..line
        end
        if line:find('WAK') ~= nil then  
          table.insert(chunk_t, temp_s..'\n'..i)  
          temp_s = nil 
        end
        i = i +1
      end    
    -- filter fx chain, ignore rec/item
      fx_chunks_t = {}
      fx_count = reaper.TrackFX_GetCount(track)
      for i = 1, fx_count do
        fx_guid = reaper.TrackFX_GetFXGUID(track, i-1)
        for k = 1, #chunk_t do
          if chunk_t[k]:find(fx_guid:sub(-2)) ~= nil then table.insert(fx_chunks_t, chunk_t[k]) end
        end
      end
      if #fx_chunks_t ~= fx_count then return nil end
      if fx_index > fx_count then reaper.ReaScriptError('FX index > Number of FX')  return end      
      param_count = reaper.TrackFX_GetNumParams(track, fx_index-1)
      if param_id+1 > param_count then reaper.ReaScriptError('Parameter index > Number of parameters') return end
    -- filter active chunk
      active_fx_chunk = fx_chunks_t[fx_index]
      active_fx_chunk_old = active_fx_chunk
    -- extract table
      active_fx_chunk_t = {}
      for line in active_fx_chunk:gmatch("[^\n]+") do table.insert(active_fx_chunk_t, line) end
    -- get first param
      for i = 1, #active_fx_chunk_t do
        if active_fx_chunk_t[i]:find('PARMLEARN '..param_id..' ') then exists = i break end
      end    
      if is_set == 0 then -- GET 
        if exists == nil then reaper.ReaScriptError('There is no learn for current parameter') return end
        -- form out table
          out_t = {}
          for word in active_fx_chunk_t[exists]:gsub('PARMLEARN ', ''):gmatch('[^%s]+') do
            table.insert(out_t, word)
          end
        -- convert
          midiChannel = out_t[2] & 0x0F
          midiCC = out_t[2] >> 8   
        return midiChannel + 1, midiCC, out_t[4] 
      end
      if is_set == 1 then -- SET  midi
        if string_midiosc ~= nil and string_midiosc ~= '' then
        -- add to active_fx_chunk_t
          for i = 1, #active_fx_chunk_t do if active_fx_chunk_t[i]:find('FXID ') then guid_id = i break end end
          table.insert(active_fx_chunk_t, guid_id+1,
          'PARMLEARN '..param_id..' '..string_midiosc)
        end 
      end
      if is_set == -1 then -- remove current parameters learn
        for i = 1, #active_fx_chunk_t do if active_fx_chunk_t[i]:find('PARMLEARN '..param_id..' ') then 
              active_fx_chunk_t[i] = ''
            end
          end       
      end
      if is_set == -1 or is_set == 1 then
        -- return fx chunk table to chunk
          insert_begin = active_fx_chunk_t[1]
          insert_end = active_fx_chunk_t[#active_fx_chunk_t]
          active_fx_chunk_new = table.concat(active_fx_chunk_t, '\n', 2, #active_fx_chunk_t-1)
        -- delete_chunk lines
          for i = insert_begin, insert_end do
            table.remove(main_chunk, insert_begin)
          end
        -- insert new fx chunk
          table.insert(main_chunk, insert_begin, active_fx_chunk_new)
        -- clean chunk table from empty lines
          local out_chunk = table.concat(main_chunk, '\n')
          local out_chunk_clean = out_chunk:gsub('\n\n', '')
          --reaper.ShowConsoleMsg(out_chunk_clean)
          reaper.SetTrackStateChunk(track, table.concat(main_chunk, '\n')) 
      end
  end  
-------------------------------------------------------------------------------  
  function CheckGivenControls(osc,midiCC, midiChan, is_soft_takeover) local str
    if not osc then osc = '' end
    if not is_soft_takeover then is_soft_takeover = 0 end
    if midiCC and midiChan then midi = (midiCC << 8) | 0xB0 + midiChan - 1 end
    if not midi then str = '0 0 '..osc else str = midi ..' '..is_soft_takeover ..' '..osc end
    return str
  end  
------------------------------------------------------------------------------
  function AssignControl(e_track, e_fx_ID, e_param_ID, str)
      -- assign control
        TrackFX_GetSetMIDIOSCLearn( e_track, 
                                    e_fx_ID, --fx_index 0 -based,
                                    e_param_ID, --param_id 0-based
                                    1, --is_set
                                    str --string_midiosc
                                    )
        -- store last learned track/fx/param
        reaper.SetProjExtState( 0, 'MPL_assign_ctrl', 'last_track_ID',  reaper.CSurf_TrackToID( e_track, false ) )                         
        reaper.SetProjExtState( 0, 'MPL_assign_ctrl', 'last_FX_ID',  e_fx_ID )   
        reaper.SetProjExtState( 0, 'MPL_assign_ctrl', 'last_param_ID',  e_param_ID ) 
  end
------------------------------------------------------------------------------- 
  function ErasePreviousAssign()
    --local last_track_ID, last_FX_ID, last_param_ID
    _, last_track_ID = reaper.GetProjExtState( 0, 'MPL_assign_ctrl', 'last_track_ID' )
    _, last_FX_ID = reaper.GetProjExtState( 0, 'MPL_assign_ctrl', 'last_FX_ID' )
    _, last_param_ID = reaper.GetProjExtState( 0, 'MPL_assign_ctrl', 'last_param_ID' )
          
    last_track_ID = tonumber(last_track_ID)
    last_FX_ID = tonumber(last_FX_ID)
    last_param_ID = tonumber(last_param_ID)
          
    if last_track_ID and last_FX_ID and last_param_ID then
      local last_track = reaper.CSurf_TrackFromID( last_track_ID, false )
      if last_track then 
        TrackFX_GetSetMIDIOSCLearn( last_track, 
                                    last_FX_ID, --fx_index 0 -based,
                                    last_param_ID, --param_id 0-based
                                    -1)
      end
    end    
  end  
-------------------------------------------------------------------------------    
  function FirstTimeMsg()
    reaper.MB(
[[Edit script MANUALLY:
  1. Open Action List
  2. Select 'mpl_Assign MIDI or OSC control with FX envelope under mouse cursor.lua'
  3. Press ReaScript: Edit.
  4. After ReaPack header edit MIDI or OSC fields (uncomment if needed).
      '--' mean commented line so to uncomment simply erase it
  5. UNLEARN given control if you have something learned to it.
  6. Use with FX envelope under mouse cursor
      ]],'MPL Assign ctrl',0) 
  end   
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------
 
  function main()
    e_track, e_fx_ID, e_param_ID = GetEnvelopeUnderMouseCursor() 
    if not osc and not midi and not is_soft_takeover then    -- if  not edited
      FirstTimeMsg()
     else   
      str = CheckGivenControls(osc,midiCC, midiChan, is_soft_takeover)
      if not str then return end     
      retval = reaper.GetProjExtState( 0, 'MPL_assign_ctrl', 'last_track_ID' )      
      if retval == 0 then -- first time
        AssignControl(e_track, e_fx_ID, e_param_ID, str)
       else
        ErasePreviousAssign(str)
        AssignControl(e_track, e_fx_ID, e_param_ID, str)          
      end
    end 
  end                           
    
    
    main()
