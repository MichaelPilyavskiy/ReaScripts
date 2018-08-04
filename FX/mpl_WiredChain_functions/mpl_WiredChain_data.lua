-- @description WiredChain_data
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex



  ---------------------------------------------------  
  function Data_BuildRouting(conf, obj, data, refresh, mouse, routing_t )
    if not routing_t or not routing_t.src or not routing_t.dest then return end -- make sure sorce/destination exists
    if not (routing_t.src:match('mod_') and routing_t.dest:match('mod_')) then return end -- make sure src/dest is modules
    if routing_t.routingtype == 0 then
      Data_BuildRouting_Audio(conf, obj, data, refresh, mouse, routing_t )
    end
    refresh.data = true
    refresh.GUI = true
  end
 ---------------------------------------------------   
  function SetPin(track, fx_id, isOut_int, pin_id, chan, set)
    local pinflags = TrackFX_GetPinMappings ( track, fx_id, isOut_int, pin_id )
    local state =  pinflags&(2^(chan-1))==2^(chan-1) 
    if set == 0 then
      if state then pinflags = pinflags - 2^(chan-1) end
     else
      if not state then pinflags = pinflags + 2^(chan-1) end
    end
    TrackFX_SetPinMappings ( track, fx_id, isOut_int, pin_id, pinflags, 0 )
  end
  
  ---------------------------------------------------    
  function Data_BuildRouting_Audio(conf, obj, data, refresh, mouse, routing_t )
    local srcfxid = routing_t.src:match('fx_(%d+)')
    if srcfxid then srcfxid = tonumber(srcfxid) end
    local destfxid = routing_t.dest:match('fx_(%d+)')
    if destfxid then destfxid = tonumber(destfxid) end    
    local src_t = { isFX = routing_t.src:match('_fx_')~= nil,
              FXid = srcfxid,
              isOut= routing_t.src:match('_O_')~= nil,
              pin = math.floor(routing_t.src:match('_[IO]_(%d+)'))}
    local dest_t = { isFX = routing_t.dest:match('_fx_')~= nil,
              FXid = destfxid,
              isOut= routing_t.dest:match('_O_')~= nil,
              chan = math.floor(routing_t.dest:match('_[IO]_(%d+)'))}   
              
    -- link beetween FX
    if  src_t.isFX and dest_t.isFX then 
      if src_t.FXid < dest_t.FXid then -- valid FX order
        -- set on destination channel for source FX
        -- disable dest channel out for FX beetween        
        SetPin(data.tr, src_t.FXid-1, 1, src_t.pin-1, dest_t.chan, 1)
        for fx_id = src_t.FXid+1, lim(dest_t.FXid -1, src_t.FXid+1, math.huge) do
          if data.fx[fx_id] then
            for pin_id = 1, data.fx[fx_id].outpins do
              SetPin(data.tr, fx_id-1, 1, pin_id-1, dest_t.chan, 0)
            end
          end
        end
      end
    end

    -- if in is track in
    if  not src_t.isFX and dest_t.isFX then 
        -- set on destination channel for source FX
        -- disable dest channel out for FX up to destination FX  
        SetPin(data.tr, dest_t.FXid-1, 0, dest_t.chan-1, src_t.pin, 1)
        for fx_id = 0, dest_t.FXid-1 do
          if data.fx[fx_id] then
            for pin_id = 1, data.fx[fx_id].outpins do
              SetPin(data.tr, fx_id-1, 1, pin_id-1, src_t.pin, 0)
            end
          end
        end
    end 
        
    -- if out is track out
    if  src_t.isFX and not dest_t.isFX then 
        -- set on destination channel for source FX
        -- disable dest channel out for FX down to track out  
        SetPin(data.tr, src_t.FXid-1, 1, src_t.pin-1, dest_t.chan, 1)
        for fx_id = src_t.FXid+1, #data.fx do
          if data.fx[fx_id] then
            for pin_id = 1, data.fx[fx_id].outpins do
              SetPin(data.tr, fx_id-1, 1, pin_id-1, dest_t.chan, 0)
            end
          end
        end
    end    

    -- if through
    if not src_t.isFX and not dest_t.isFX then 
      -- disable dest channel out for FX down to track out  
      for fx_id = 1, #data.fx do
        for pin_id = 1, data.fx[fx_id].outpins do
          SetPin(data.tr, fx_id-1, 1, pin_id-1, src_t.pin, 0)
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
  function Data_Update(conf, obj, data, refresh, mouse)
    
    
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
          local pinmap = reaper.TrackFX_GetPinMappings( tr, i-1, 0, inpin-1 )
          pins.I[inpin] = pinmap
        end
        for outpin = 1, outpins do
          local pinmap = reaper.TrackFX_GetPinMappings( tr, i-1, 1, outpin-1 )
          pins.O[outpin] = pinmap
        end
        
      -- tracking channels to pins
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
        end
            
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
 

