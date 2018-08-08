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
  function Data_ParseRouteStr(routing_t) local src_t, dest_t
    if routing_t.src then
      local srcfxid = routing_t.src:match('fx_(%d+)')
      if srcfxid then srcfxid = tonumber(srcfxid) end
      src_t = { isFX = routing_t.src:match('_fx_')~= nil,
              FXid = srcfxid,
              isOut= routing_t.src:match('_O_')~= nil,
              pin = math.floor(routing_t.src:match('_[IO]_(%d+)'))}      
    end
    if routing_t.dest then
      local destfxid = routing_t.dest:match('fx_(%d+)')
      if destfxid then destfxid = tonumber(destfxid) end   
      local chan = routing_t.dest:match('_[IO]_(%d+)')
      if chan then chan =  math.floor(chan) end
      dest_t = { isFX = routing_t.dest:match('_fx_')~= nil,
              FXid = destfxid,
              isOut= routing_t.dest:match('_O_')~= nil,
              chan = chan}        
    end
 
    return src_t, dest_t
  end
  ---------------------------------------------------    
  function Data_BuildRouting_Audio(conf, obj, data, refresh, mouse, routing_t )
    local src_t, dest_t = Data_ParseRouteStr(routing_t)
    local dest_chan = dest_t.chan
    
    local dest_chan0
    if conf.autoroutestereo == 1 then dest_chan0 = dest_chan + 1 end    
    if dest_chan0 > data.trchancnt then SetMediaTrackInfo_Value( data.tr, 'I_NCHAN', dest_chan0 + dest_chan0 % 2 ) end
    
    -- link beetween FX
    if  src_t.isFX and dest_t.isFX then 
      if src_t.FXid < dest_t.FXid then -- valid FX order
      
        -- set on destination channel for source FX      
        SetPin(data.tr, src_t.FXid, 1, src_t.pin, dest_t.chan, 1)
        if conf.autoroutestereo == 1 then SetPin(data.tr, src_t.FXid, 1, src_t.pin+1, dest_t.chan+1, 1) end  
        
        -- handle destination FX
          --SetPin(data.tr, dest_t.FXid, 0, dest_t.chan, src_t.pin, 1) -- 1.02
          for chan = 1, data.trchancnt do 
            SetPin(data.tr, dest_t.FXid, 0, dest_t.chan, chan, 0) 
            if conf.autoroutestereo == 1 then SetPin(data.tr, dest_t.FXid, 0, dest_t.chan+1, chan, 0) end
          end
          SetPin(data.tr, dest_t.FXid, 0, dest_t.chan,dest_t.chan, 1)
          if conf.autoroutestereo == 1 then SetPin(data.tr, dest_t.FXid, 0, dest_t.chan+1,dest_t.chan+1, 1) end
          
        -- clear output destination channel in beetween
        if dest_t.FXid - src_t.FXid > 1 then
          for fx_id = src_t.FXid+1, dest_t.FXid do
            for pin_id = 1, data.fx[fx_id].outpins do
              SetPin(data.tr, fx_id, 1, pin_id, dest_t.chan, 0)
              if conf.autoroutestereo == 1 then SetPin(data.tr, fx_id, 1, pin_id+1, dest_t.chan+1, 0) end
            end
          end
        end
        
       elseif src_t.FXid > dest_t.FXid then-- invalid order
        local inc = src_t.FXid-dest_t.FXid
        MPL_HandleFX(data.tr, dest_t.FXid, 2, inc )
        Data_Update(conf, obj, data, refresh, mouse)
        
        SetPin(data.tr, src_t.FXid-1, 1, src_t.pin, dest_t.chan, 1)
        if conf.autoroutestereo == 1 then SetPin(data.tr, src_t.FXid-1, 1, src_t.pin+1, dest_t.chan+1, 1) end
        --SetPin(data.tr, src_t.FXid, 0, dest_t.chan, src_t.pin, 1)
        
        for chan = 1, data.trchancnt do 
          SetPin(data.tr, src_t.FXid, 0, dest_t.chan, chan, 0) 
          if conf.autoroutestereo == 1 then SetPin(data.tr, src_t.FXid, 0, dest_t.chan+1, chan, 0)  end
        end
        SetPin(data.tr, src_t.FXid, 0, dest_t.chan,dest_t.chan, 1)
        if conf.autoroutestereo == 1 then SetPin(data.tr, src_t.FXid, 0, dest_t.chan+1,dest_t.chan+1, 1) end
      end
    end

    -- if in is track in
    if  not src_t.isFX and dest_t.isFX then 
        -- set on destination channel for source FX
        -- disable dest channel out for FX up to destination FX  
        for chan = 1, data.trchancnt do
          local int_set = 0 
          if chan == src_t.pin then int_set = 1 end
          SetPin(data.tr, dest_t.FXid, 0, dest_t.chan, chan, int_set)
          if conf.autoroutestereo == 1 then SetPin(data.tr, dest_t.FXid, 0, dest_t.chan+1, chan+1, int_set) end
        end
        -- clear beetween fx
        for fx_id = 0, dest_t.FXid-1 do
          if data.fx[fx_id] then
            for pin_id = 1, data.fx[fx_id].outpins do
              SetPin(data.tr, fx_id, 1, pin_id, src_t.pin, 0)
              if conf.autoroutestereo == 1 then SetPin(data.tr, fx_id, 1, pin_id+1, src_t.pin+1, 0) end
            end
          end
        end
    end 
        
    -- if out is track out
    if  src_t.isFX and not dest_t.isFX then 
        -- set on destination channel for source FX
        -- disable dest channel out for FX down to track out  
        SetPin(data.tr, src_t.FXid, 1, src_t.pin, dest_t.chan, 1)
        if conf.autoroutestereo == 1 then SetPin(data.tr, src_t.FXid, 1, src_t.pin+1, dest_t.chan+1, 1) end
        for fx_id = src_t.FXid+1, #data.fx do
          if data.fx[fx_id] then
          
            -- clear pins beetween src FX and track out
            for pin_id = 1, data.fx[fx_id].outpins do
              SetPin(data.tr, fx_id, 1, pin_id, dest_t.chan, 0)
              if conf.autoroutestereo == 1 then SetPin(data.tr, fx_id, 1, pin_id, dest_t.chan+1, 0) end
            end
            
          end
        end
    end    

    -- if through
    if not src_t.isFX and not dest_t.isFX then 
      -- disable dest channel out for FX down to track out  
      for fx_id = 1, #data.fx do
        for pin_id = 1, data.fx[fx_id].outpins do
          SetPin(data.tr, fx_id, 1, pin_id, src_t.pin, 0)
          if conf.autoroutestereo == 1 then SetPin(data.tr, fx_id, 1, pin_id+1, src_t.pin+1, 0) end
        end
      end
    end 
        
    
    --routingtype
    --[[ClearConsole()
    msg(routing_t.src)
    msg(routing_t.dest)]]
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
    local t = {}
    for key in pairs(obj) do  
      if type(obj[key]) == 'table' and key:match('fx_%d+$') and obj[key].is_selected ==true then
        fx_id = key:match('fx_(%d+)$')
        t[#t+1] = tonumber(fx_id)
      end
    end
    table.sort(t, function(a,b) return a>b end)
    for i = 1, #t do
      TrackFX_Delete(data.tr, t[i]-1)
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
            
      data.fx[i] = { GUID =  TrackFX_GetFXGUID( tr,i-1 ),
                    name = fxname,
                    reducedname = MPL_ReduceFXname(fxname),
                    inpins=inpins,
                    outpins =outpins,
                    pins = pins,
                    chantopins = chantopins
                  }
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
