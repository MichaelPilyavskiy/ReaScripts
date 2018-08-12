-- @description WiredChain_data
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
  ---------------------------------------------------  
  function Data_BuildRouting(conf, obj, data, refresh, mouse, routing_t )
    if not routing_t or not routing_t.src or not routing_t.dest then return end -- make sure sorce/destination exists
    if not (routing_t.src:match('mod_') and routing_t.dest:match('mod_')) or (routing_t.src:match('_I_')) then return end -- make sure src/dest is modules
    
    if routing_t.routingtype == 0 then
      Data_BuildRouting_Audio(conf, obj, data, refresh, mouse, routing_t )
    end
    
    refresh.data = true
    refresh.GUI = true
  end
 ---------------------------------------------------   
  function SetPin(track, fx_id, isOut_int, pin_id, chan, set) 
    -- chan is 1 based
    local pinflags, high32 = TrackFX_GetPinMappings ( track, fx_id-1, isOut_int, pin_id-1 )

    if chan < 64 then 
      local state =  pinflags&(2^(chan-1))==2^(chan-1) 
      if set == 0 then
        if state then pinflags = pinflags - 2^(chan-1) end
       else
        if not state then pinflags = pinflags + 2^(chan-1) end
      end
      
      TrackFX_SetPinMappings ( track, fx_id-1, isOut_int, pin_id-1, pinflags, 0 )
     else
      chan = chan - 63
      
      local state =  high32&(2^(chan-1))==2^(chan-1) 
      if set == 0 then
        if state then high32 = high32 - 2^(chan-1) end
       else
        if not state then high32 = high32 + 2^(chan-1) end
      end
      
      TrackFX_SetPinMappings ( track, fx_id-1, isOut_int, pin_id-1, pinflags, high32 )      
    end
  end

  ---------------------------------------------------    
  function Data_BuildRouting_Audio(conf, obj, data, refresh, mouse, routing_t )
    local src_t = obj[routing_t.src]
    local dest_t = obj[routing_t.dest]

    local src_pin = src_t.pin_idx
    local src_type = src_t.pin_type -- 0 FX 1 track
    local src_idxFX = src_t.pin_idxFX
    
    local dest_pin = dest_t.pin_idx
    local dest_type = dest_t.pin_type -- 0 FX 1 track
    local dest_idxFX = dest_t.pin_idxFX
    
    local dest_chan = math.max(src_pin, dest_pin)
    
    if dest_chan > data.trchancnt then SetMediaTrackInfo_Value( data.tr, 'I_NCHAN', dest_chan + dest_chan % 2 ) end
    if conf.autoroutestereo == 1 then 
      if dest_chan+1 > data.trchancnt then SetMediaTrackInfo_Value( data.tr, 'I_NCHAN', dest_chan+1 + (dest_chan+1) % 2 ) end end
    
    -- link beetween FX
    if src_type == 0 and dest_type == 0 then 
    
      -- clear output destination channel in other pins on source FX
      for outpin = 1, data.fx[src_idxFX].outpins do
        SetPin(data.tr, src_idxFX, 1, outpin, dest_chan, 0)
        if conf.autoroutestereo == 1 then SetPin(data.tr,src_idxFX, 1, outpin, dest_pin+1, 0) end
      end
      -- clear source pin
      for trch = 1, data.trchancnt do
        SetPin(data.tr, src_idxFX, 1, src_pin, trch, 0)
      end
      
      
      if src_idxFX < dest_idxFX then -- valid FX order
      
        -- set on destination channel for source FX      
        SetPin(data.tr, src_idxFX, 1, src_pin, dest_chan, 1)
        if conf.autoroutestereo == 1 then SetPin(data.tr, src_idxFX, 1, src_pin+1, dest_chan+1, 1) end  
        
        -- handle destination FX
          -- clear pins
          --SetPin(data.tr, dest_idxFX, 0, dest_t.chan, src_pin, 1) -- 1.02
          for chan = 1, data.trchancnt do 
            SetPin(data.tr, dest_idxFX, 0, dest_pin, chan, 0) 
            if conf.autoroutestereo == 1 then SetPin(data.tr, dest_idxFX, 0,dest_pin+1, chan, 0) end
          end
          -- set pin
          SetPin(data.tr, dest_idxFX, 0, dest_pin,dest_chan, 1)
          if conf.autoroutestereo == 1 then SetPin(data.tr, dest_idxFX, 0, dest_pin+1,dest_chan+1, 1) end
          
        -- clear output destination channel in beetween
          if dest_idxFX - src_idxFX > 1 then
            for fx_id = src_idxFX+1, dest_idxFX-1 do
              for pin_id = 1, data.fx[fx_id].outpins do
                SetPin(data.tr, fx_id, 1, pin_id, dest_chan, 0)
                if conf.autoroutestereo == 1 then SetPin(data.tr, fx_id, 1, pin_id+1, dest_chan+1, 0) end
              end
            end
          end
        
       elseif src_idxFX > dest_idxFX then-- invalid order
        local inc = src_idxFX-dest_idxFX
        MPL_HandleFX(data.tr, dest_idxFX, 2, inc )
        Data_Update(conf, obj, data, refresh, mouse)
        -- source
        SetPin(data.tr, src_idxFX-1, 1, src_pin, dest_chan, 1)
        if conf.autoroutestereo == 1 then SetPin(data.tr, src_idxFX-1, 1, src_pin+1, dest_chan+1, 1) end
        -- destination
        for chan = 1, data.trchancnt do 
          SetPin(data.tr, src_idxFX, 0, dest_pin, chan, 0) 
          if conf.autoroutestereo == 1 then SetPin(data.tr, src_idxFX, 0, dest_pin+1, chan, 0)  end
        end
        SetPin(data.tr, src_idxFX, 0, dest_pin,dest_chan, 1)
        if conf.autoroutestereo == 1 then SetPin(data.tr, src_idxFX, 0, dest_pin+1,dest_chan+1, 1) end
      end
    end

    -- if in is track in
    if src_type == 1 and dest_type == 0 then 
        -- set on destination channel for source FX
        -- disable dest channel out for FX up to destination FX  
        for chan = 1, data.trchancnt do
          local int_set = 0 
          if chan == dest_chan then int_set = 1 end
          SetPin(data.tr, dest_idxFX, 0, dest_pin, chan, int_set)
          if conf.autoroutestereo == 1 then SetPin(data.tr, dest_idxFX, 0, dest_pin+1, chan+1, int_set) end
        end
        -- clear beetween fx
        for fx_id = 0, dest_idxFX-1 do
          if data.fx[fx_id] then
            for pin_id = 1, data.fx[fx_id].outpins do
              SetPin(data.tr, fx_id, 1, pin_id, dest_chan, 0)
              if conf.autoroutestereo == 1 then SetPin(data.tr, fx_id, 1, pin_id+1, dest_chan+1, 0) end
            end
          end
        end
    end 
        
    -- if out is track out
    if src_type == 0 and dest_type == 1 then 
    
        -- set on destination channel for source FX
        -- disable dest channel out for FX down to track out  
        
        for fx_id = src_idxFX, #data.fx do
          if data.fx[fx_id] then          
            -- clear pins beetween src FX and track out
            for pin_id = 1, data.fx[fx_id].outpins do
              SetPin(data.tr, fx_id, 1, pin_id, dest_chan, 0)
              if conf.autoroutestereo == 1 then SetPin(data.tr, fx_id, 1, pin_id, dest_chan+1, 0) end
            end            
          end
        end
        
        SetPin(data.tr, src_idxFX, 1, src_pin, dest_chan, 1)
        if conf.autoroutestereo == 1 then SetPin(data.tr, src_idxFX, 1, src_pin+1, dest_chan+1, 1) end
    end    

    -- if through
    if src_type == 1 and dest_type == 1 then 
      -- disable dest channel out for FX down to track out  
      for fx_id = 1, #data.fx do
        for pin_id = 1, data.fx[fx_id].outpins do
          SetPin(data.tr, fx_id, 1, pin_id, src_pin, 0)
          if conf.autoroutestereo == 1 then SetPin(data.tr, fx_id, 1, pin_id+1, src_pin+1, 0) end
        end
      end
    end 
        
  end
  ---------------------------------------------------  
  function CheckUpdates(obj, conf, refresh)
  
    -- force by proj change state
      obj.SCC =  GetProjectStateChangeCount( 0 ) 
      if not obj.lastSCC then 
        refresh.GUI_onStart = true  
        refresh.data = true
       elseif obj.lastSCC and obj.lastSCC ~= obj.SCC then 
        --if conf.dev_mode == 1 then msg(obj.SCC..'2') end
        refresh.data = true
        refresh.GUI = true
        refresh.GUI_WF = true
      end 
      obj.lastSCC = obj.SCC
      
    -- window size
      local ret = HasWindXYWHChanged(obj)
      if ret == 1 then 
        refresh.conf = true 
        refresh.data = true
        refresh.GUI_onStart = true 
        refresh.GUI_WF = true       
       elseif ret == 2 then 
        refresh.conf = true
        refresh.data = true
      end
  end
  ---------------------------------------------------
  function Data_Update_ExtState_ProjData_Load (conf, obj, data, refresh, mouse)
    if not data.tr then return end
    local retval, extstr = GetProjExtState( 0, conf.ES_key, 'FXPOS' )
    if not retval then return end
    data.ext_data = {}
    for line in extstr:gmatch('[^\r\n]+') do
      local t = {} 
      for val in line:gmatch('[^%s]+') do t[#t+1] = val end
      if #t == 4 then 
        local trGUID = t[1]
        local fxGUID = t[2]
        local fxx = t[3]
        local fxy = t[4]
        if not data.ext_data[trGUID] then data.ext_data[trGUID] = {} end
        if not data.ext_data[trGUID][fxGUID] then data.ext_data[trGUID][fxGUID] = {} end
        data.ext_data[trGUID][fxGUID].x = tonumber(fxx)
        data.ext_data[trGUID][fxGUID].y = tonumber(fxy)
      end
    end
    
  end 
  ---------------------------------------------------
  function Data_Update_ExtState_ProjData_Save (conf, obj, data, refresh, mouse)
    if not data.tr or not data.ext_data then return end
    local str = ''
    for trGUID in pairs(data.ext_data) do
      for fxGUID in pairs(data.ext_data[trGUID]) do
        str = str..trGUID..' '..fxGUID..' '..math.floor(data.ext_data[trGUID][fxGUID].x)..' '..math.floor(data.ext_data[trGUID][fxGUID].y)..'\n'
      end      
    end
    SetProjExtState( 0, conf.ES_key, 'FXPOS', str )
  end 
  ---------------------------------------------------
  function Data_DeleteSelectedFX(conf, obj, data, refresh, mouse)
    Undo_BeginBlock()
    local t = {}
    local cnt, ids_table = Obj_CountSelectedObjects(conf, obj, data, refresh, mouse)
    for sel_fx = 1, cnt do 
      local key = ids_table[sel_fx] 
      local fx_id = key:match('fx_(%d+)')
      t[#t+1] = tonumber(fx_id)
    end
    table.sort(t, function(a,b) return a>b end)
    for i = 1, #t do  TrackFX_Delete(data.tr, t[i]-1)  end
    Undo_EndBlock2(0, 'WiredChain - remove FX', -1 )
  end
  ---------------------------------------------------  
  function Data_AddReplaceFX(conf, obj, data, refresh, mouse)
        if obj.textbox.match_t 
          and obj.textbox.matched_id
          and obj.textbox.match_t [obj.textbox.matched_id] then
            local name = obj.textbox.match_t [obj.textbox.matched_id].name
            local plugtype = obj.textbox.match_t [obj.textbox.matched_id].plugtype
            local reduced_name = obj.textbox.match_t [obj.textbox.matched_id].reduced_name
            if plugtype == 4 then name = 'JS:'..name end
            ret = TrackFX_AddByName( data.tr, name, false, -1 )
            if ret < 0 and reduced_name then  TrackFX_AddByName( data.tr, reduced_name, false, -1 ) end
            local new_GUID =  TrackFX_GetFXGUID( data.tr, #data.fx )
            if ret< 0  then goto skip_replace end
            
            if obj.textbox.is_replace then
              local fx_id = obj.textbox.is_replace +1
              MPL_HandleFX(data.tr, fx_id, 1)
              MPL_HandleFX(data.tr, #data.fx, 2, -(#data.fx-fx_id)+1)
              -- set pins
              if data.fx[fx_id].inpins then 
                for pin = 1, data.fx[fx_id].inpins do  TrackFX_SetPinMappings( data.tr, fx_id-1, 0, pin-1 , data.fx[fx_id].pins.I[pin], 0)  end
              end
              if data.fx[fx_id].outpins then 
                for pin = 1, data.fx[fx_id].outpins do TrackFX_SetPinMappings( data.tr, fx_id-1, 1, pin-1 , data.fx[fx_id].pins.O[pin], 0)  end
              end  
              -- handle_xy    
              if obj['fx_'..fx_id] then
                if not data.ext_data[data.GUID] then data.ext_data[data.GUID] = {} end
                if not data.ext_data[data.GUID][new_GUID] then data.ext_data[data.GUID][new_GUID] = {} end
                data.ext_data[data.GUID][new_GUID].x = obj['fx_'..fx_id].x
                data.ext_data[data.GUID][new_GUID].y = obj['fx_'..fx_id].y
                Data_Update_ExtState_ProjData_Save (conf, obj, data, refresh, mouse)
              end 
              
                
             else -- NOT replace
              if new_GUID then
                if not data.ext_data[data.GUID] then data.ext_data[data.GUID] = {} end
                if not data.ext_data[data.GUID][new_GUID] then data.ext_data[data.GUID][new_GUID] = {} end
                data.ext_data[data.GUID][new_GUID].x = mouse.x - conf.struct_xshift
                data.ext_data[data.GUID][new_GUID].y = mouse.y - conf.struct_yshift
                Data_Update_ExtState_ProjData_Save (conf, obj, data, refresh, mouse)      
              end             
            end
            
          ::skip_replace::
          obj.textbox.enable = false
          refresh.GUI = true
          refresh.data = true
         else
          obj.textbox.enable = false
        end
    end  
  ---------------------------------------------------
  function Data_Update(conf, obj, data, refresh, mouse)
    data.chan_lim = 32
    local tr = GetSelectedTrack(0,0)
    if not tr then return end
    
    data.tr = tr
    local retval, trname = GetTrackName( tr, '' )
    data.trname = trname
    data.trchancnt = GetMediaTrackInfo_Value( tr, 'I_NCHAN' )
    data.GUID = reaper.GetTrackGUID( tr )
    
    
    data.fx = {}
    local cnt_flow = 0
    local cnt_flow_id
    for i = 1,  TrackFX_GetCount( tr ) do
      local fxname = ({TrackFX_GetFXName( tr, i-1, '' )})[2]
      
      -- check pins
        local pins = {I={},O={}}
        local retval, inpins, outpins = TrackFX_GetIOSize( tr, i-1 )
        for inpin = 1, inpins do
          local pinmap, high32 = reaper.TrackFX_GetPinMappings( tr, i-1, 0, inpin-1 )
          pins.I[inpin] = pinmap --+ high32<<32
        end
        for outpin = 1, outpins do
          local pinmap, high32 = reaper.TrackFX_GetPinMappings( tr, i-1, 1, outpin-1 )
          pins.O[outpin] = pinmap --+ high32<<32
        end
        
      --[[ tracking channels to pins
        local chantopins = {}
        for chan = 1, data.trchancnt do
          for pinI = 1, #pins.I do
            if pins.I[pinI]&(2^(chan-1))==(2^(chan-1)) then
              if not chantopins[chan] then chantopins[chan] = {} end
              if not chantopins[chan].I then chantopins[chan].I = {} end
              chantopins[chan].I[#chantopins[chan].I+1] = pinI
            end
          end
          for pinO = 1, #pins.O do
            if pins.O[pinO]&(2^(chan-1))==(2^(chan-1)) then
              if not chantopins[chan] then chantopins[chan] = {} end
              if not chantopins[chan].O then chantopins[chan].O = {} end
              chantopins[chan].O[#chantopins[chan].O+1] = pinO
            end
          end          
        end]]
      local enabled = TrackFX_GetEnabled(tr,i-1)
      if enabled then   
        cnt_flow = cnt_flow + 1
        cnt_flow_id = i 
      end
      data.fx[i] = { GUID =  TrackFX_GetFXGUID( tr,i-1 ),
                    name = fxname,
                    reducedname = MPL_ReduceFXname(fxname),
                    inpins=inpins,
                    outpins =outpins,
                    pins = pins,
                    chantopins = chantopins,
                    offline = TrackFX_GetOffline(tr,i-1),
                    enabled = enabled,
                  }
    end
    
    -- check solo state 
    if #data.fx > 1 and cnt_flow == 1 and cnt_flow_id then
      data.fx[cnt_flow_id].is_solo = true
    end
  end    
    
    
    --[[
    B_MUTE : bool * : mute flag
    B_PHASE : bool * : invert track phase
    IP_TRACKNUMBER : int : track number (returns zero if not found, -1 for master track) (read-only, returns the int directly)
    I_SOLO : int * : 0=not soloed, 1=solo, 2=soloed in place. also: 5=solo-safe solo, 6=solo-safe soloed in place
    I_FXEN : int * : 0=fx bypassed, nonzero = fx active
    I_RECARM : int * : 0=not record armed, 1=record armed
    I_RECINPUT : int * : record input. <0 = no input, 0..n = mono hardware input, 512+n = rearoute input, 1024 set for stereo input pair. 4096 set for MIDI input, if set, then low 5 bits represent channel (0=all, 1-16=only chan), then next 6 bits represent physical input (63=all, 62=VKB)
    I_RECMODE : int * : record mode (0=input, 1=stereo out, 2=none, 3=stereo out w/latcomp, 4=midi output, 5=mono out, 6=mono out w/ lat comp, 7=midi overdub, 8=midi replace
    I_RECMON : int * : record monitor (0=off, 1=normal, 2=not when playing (tapestyle))
    I_RECMONITEMS : int * : monitor items while recording (0=off, 1=on)
    I_AUTOMODE : int * : track automation mode (0=trim/off, 1=read, 2=touch, 3=write, 4=latch)
    I_SELECTED : int * : track selected? 0 or 1
    I_WNDH : int * : current TCP window height (Read-only)
    I_FOLDERDEPTH : int * : folder depth change (0=normal, 1=track is a folder parent, -1=track is the last in the innermost folder, -2=track is the last in the innermost and next-innermost folders, etc
    I_FOLDERCOMPACT : int * : folder compacting (only valid on folders), 0=normal, 1=small, 2=tiny children
    I_MIDIHWOUT : int * : track midi hardware output index (<0 for disabled, low 5 bits are which channels (0=all, 1-16), next 5 bits are output device index (0-31))
    I_PERFFLAGS : int * : track perf flags (&1=no media buffering, &2=no anticipative FX)
    I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x100000 (i.e. ColorToNative(r,g,b)|0x100000). If you do not |0x100000, then it will not be used (though will store the color anyway).
    I_HEIGHTOVERRIDE : int * : custom height override for TCP window. 0 for none, otherwise size in pixels
    D_VOL : double * : trim volume of track (0 (-inf)..1 (+0dB) .. 2 (+6dB) etc ..)
    D_PAN : double * : trim pan of track (-1..1)
    D_WIDTH : double * : width of track (-1..1)
    D_DUALPANL : double * : dualpan position 1 (-1..1), only if I_PANMODE==6
    D_DUALPANR : double * : dualpan position 2 (-1..1), only if I_PANMODE==6
    I_PANMODE : int * : pan mode (0 = classic 3.x, 3=new balance, 5=stereo pan, 6 = dual pan)
    D_PANLAW : double * : pan law of track. <0 for project default, 1.0 for +0dB, etc
    P_ENV : read only, returns TrackEnvelope *, setNewValue=<VOLENV, <PANENV, etc
    B_SHOWINMIXER : bool * : show track panel in mixer -- do not use on master
    B_SHOWINTCP : bool * : show track panel in tcp -- do not use on master
    B_MAINSEND : bool * : track sends audio to parent
    C_MAINSEND_OFFS : char * : track send to parent channel offset
    B_FREEMODE : bool * : track free-mode enabled (requires UpdateTimeline() after changing etc)
    C_BEATATTACHMODE : char * : char * to one char of beat attached mode, -1=def, 0=time, 1=allbeats, 2=beatsposonly
    F_MCP_FXSEND_SCALE : float * : scale of fx+send area in MCP (0.0=smallest allowed, 1=max allowed)
    F_MCP_SENDRGN_SCALE : float * : scale of send area as proportion of the fx+send total area (0=min allow, 1=max)
    ]]
 
  function MPL_HandleFX(track, fx_id, action, increment_move)
    -- 5.95pre3
    if action == 0 then -- duplicate
      TrackFX_CopyToTrack(track, fx_id-1, track, fx_id-1, false)
     elseif action == 1 then -- remove
      TrackFX_Delete(track, fx_id-1)
     elseif action == 2 then -- move  
      TrackFX_CopyToTrack(track, fx_id-1, track, fx_id+increment_move-1, true)
    end
    
    --[[local chunk = eugen27771_GetObjStateChunk(track)    
    -- get fx block
      local t = {}
      local fx_block
      local relay
      for line in chunk:gmatch('[^\r\n]+') do
        t[#t+1] = line
        if line:match('<FXCHAIN$') then 
          fx_block = '' 
          relay = -1 
        end
        if fx_block then 
          if line:match('>') then relay = relay - 1 end
          if line:match('<') then relay = relay + 1 end
          fx_block = fx_block..'\n'..line
        end
        if relay == -1 then break end
      end    
      if not ( fx_block and fx_block ~= '') then return end
    -- split by FX
      local fx_chunks = {}
      local fxGUIDs = {}
      for fx_chunk in fx_block:gmatch('BYPASS.-WAK') do 
        fxGUIDs[#fxGUIDs+1] = fx_chunk:match('FXID%s{.-}')
        fx_chunks[#fx_chunks+1] = fx_chunk 
      end
    -- mod
      local str_replace = fx_block
      if action == 0 then -- duplicate
        local chunk2insert = fx_chunks[fx_id]
        chunk2insert = chunk2insert:gsub('FXID%s{.-}', 'FXID '..genGuid('' ))
        table.insert(fx_chunks, fx_id , chunk2insert)  
       elseif action == 1 then -- remove
        table.remove(fx_chunks, fx_id )        
       elseif action == 2 then -- move  
        local temp_entry = fx_chunks[fx_id]
        table.remove(fx_chunks, fx_id )  
        table.insert(fx_chunks, fx_id+increment_move , temp_entry) 
        for i = 1, #fx_chunks do
          fx_chunks[i] = fx_chunks[i]:gsub('FXID%s{.-}', fxGUIDs[i])
        end
      end
      str_replace = table.concat(fx_chunks,'\n') 
    local out_chunk = chunk:gsub(literalize(fx_block), '\n<FXCHAIN\n'..str_replace..'\n>')
    --msg(out_chunk)
    SetTrackStateChunk(track, out_chunk, true)]]
    
  end
