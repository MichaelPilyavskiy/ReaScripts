-- @description LearnEditor_data
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex
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
        --refresh.data = true
        refresh.GUI_onStart = true 
        refresh.GUI_WF = true       
       elseif ret == 2 then 
        refresh.conf = true
        --refresh.data = true
      end
  end
  ---------------------------------------------------------------------
  function Data_HandleTouchedObjects(conf, obj, data, refresh, mouse, oninitonly)
    if oninitonly then
    
      local retval, trid, fxid, paramid = reaper.GetLastTouchedFX()
      if retval == true then
        obj.touched = {trid = trid,
                       fxid=fxid+1,
                       paramid=paramid+1 }
      end
      
     else
     
      local retval, trid, fxid, paramid = reaper.GetLastTouchedFX()
      if retval == true then
        obj.touched = {trid = trid,
                       fxid=fxid+1,
                       paramid=paramid+1 }
      end
    end
  end
  -----------------------------------------------
  function Data_ModifyLearn(conf, data, trid,fx, param, remove ) 
      local tr= GetTrack(0,trid-1)
      if not tr then return end
      local retval, minval, maxval = reaper.TrackFX_GetParam( tr, fx-1, param-1 )
      if retval == -1 then MB('Something wrong with incoming data. Please report to the forum with attached RPP.', conf.mb_title, 0) return end
      
      local retval, tr_chunk = GetTrackStateChunk( tr, '', false )
      local fxGUID_check = TrackFX_GetFXGUID( tr, fx-1 )
      for fxchunk in tr_chunk:gmatch('(BYPASS.-WAK %d)') do
        local fxGUID = fxchunk:match('FXID (.-)\n')
        if not fxGUID then fxGUID = fxchunk:match('FXID_NEXT (.-)\n') end 
        if fxGUID:match(literalize(fxGUID_check):gsub('%s', '')) then
          local fxchunk_mod
          if remove ==true then 
            fxchunk_mod = fxchunk:gsub('(PARMLEARN '..(param-1)..'.-)\n', '') 
           else
            local learnMIDI = 
                      (data.paramdata[trid][fx][param].flagsMIDI<<14)+
                      data.paramdata[trid][fx][param].MIDI_Ch-1+
                      (data.paramdata[trid][fx][param].MIDI_msgtype<<4)+
                      (data.paramdata[trid][fx][param].MIDI_CC<<8)
            if data.paramdata[trid][fx][param].MIDI_Ch < 0 then learnMIDI = 0 end
            local modstr= 'PARMLEARN '..(param-1)..' '..
                  learnMIDI..' '..
                  data.paramdata[trid][fx][param].flags..' '..
                    data.paramdata[trid][fx][param].OSC_str..'\n'
                    --msg(modstr)
            fxchunk_mod = fxchunk:gsub('(PARMLEARN '..(param-1)..'.-)\n', modstr)
          end
          
          tr_chunk = tr_chunk:gsub(literalize(fxchunk), fxchunk_mod)
          
          SetTrackStateChunk( tr, tr_chunk, false )
          return
        end
      end
    
    
  end
  -----------------------------------------------
  function Data_ModifyMod(conf, data, trid,fx,param, remove )
      local tr= GetTrack(0,trid-1)
      if not tr then return end
      local retval, minval, maxval = reaper.TrackFX_GetParam( tr, fx-1, param-1 )
      if retval == -1 then MB('Something wrong with incoming data. Please report to the forum with attached RPP.', conf.mb_title, 0) return end
      
      local retval, tr_chunk = GetTrackStateChunk( tr, '', false )
      local fxGUID_check = TrackFX_GetFXGUID( tr, fx-1 )
      for fxchunk in tr_chunk:gmatch('(BYPASS.-WAK %d)') do
        local fxGUID = fxchunk:match('FXID (.-)\n')
        if not fxGUID then fxGUID = fxchunk:match('FXID_NEXT (.-)\n') end
  
        if fxGUID:match(literalize(fxGUID_check):gsub('%s', '')) then
          local fxchunk_mod
          if remove ==true then
            fxchunk_mod = fxchunk:gsub('(<PROGRAMENV '..(param-1)..'.->)\n', '')
           else
            local modstr= Data_ModifyMod_GetModStr(data.paramdata[trid][fx][param].modulation, param)
            fxchunk_mod = fxchunk:gsub('(<PROGRAMENV '..(param-1)..'.->)\n', modstr)
          end
          tr_chunk = tr_chunk:gsub(literalize(fxchunk), fxchunk_mod)
          local ret = SetTrackStateChunk( tr, tr_chunk, false )
          return
        end
      end
  end
  ---------------------------------------------------  
  function DataGetFocus(conf, obj, data, refresh, mouse) 
    --[[local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
    if retval then trid = tracknumber end]]
    local tr = reaper.GetLastTouchedTrack()
    if tr then trid = reaper.CSurf_TrackToID( tr, false ) end
    data.focus = {trid = trid}
  end
  ---------------------------------------------------
  function DataReadProject(conf, obj, data, refresh, mouse)
    DataGetFocus(conf, obj, data, refresh, mouse) 
    data.paramdata = {}
    data.cnt_tracks = CountTracks( 0 )
    for trackidx =1,  CountTracks( 0 ) do
      local tr =  GetTrack( 0, trackidx-1 )
      if tr then 
        local fx_cnt = TrackFX_GetCount( tr )
        local retval, tr_chunk = GetTrackStateChunk( tr, '', false )
        for fxchunk in tr_chunk:gmatch('(BYPASS.-WAK %d)') do
          local fxGUID = fxchunk:match('FXID (.-)\n')
          if not fxGUID then fxGUID = fxchunk:match('FXID_NEXT (.-)\n') end
          local ret, tr, fxid = VF_GetFXByGUID(fxGUID, tr)
          if ret then  -- for freezed VST
            local trcol =  reaper.GetTrackColor( tr )
            local retval, trname = reaper.GetTrackName( tr )
            local retval, fxname = reaper.TrackFX_GetFXName( tr, fxid, '' )
            fxid = fxid + 1 
            -- midi osc learn
            for line in fxchunk:gmatch('PARMLEARN(.-)\n') do
              local t0 = {} 
              for ssv in line:gmatch('[^%s]+') do 
                --ssv = ssv:match('[%d%.%/]+')
                if ssv and tonumber(ssv) then ssv = tonumber(ssv) end
                t0[#t0+1] = ssv 
              end
              if not tonumber(t0[1]) then t0[1] = tonumber(t0[1]:match('%d+')) end
              local par_idx = t0[1]+1
              local retval, paramname = reaper.TrackFX_GetParamName( tr, fxid-1, par_idx-1, '' )
              local isMIDI = t0[2] > 0
              local flags = t0[3]
              local flagsMIDI = (t0[2] >>14)&0x1F
              local OSC_str, MIDI_Ch, MIDI_CC
              if isMIDI==false then 
                MIDI_Ch = -1
                MIDI_msgtype = -1
                MIDI_CC = -1
                OSC_str = t0[4]
               else
                MIDI_Ch = (t0[2] & 0x0F)+1
                MIDI_msgtype = (t0[2]>>4)& 0x0F
                MIDI_CC = (t0[2]>>8)& 0xFF
                OSC_str = '' 
              end
              
              if not data.paramdata[trackidx]  then data.paramdata[trackidx] = {tr_ptr = tr,
                                                                                trcol=trcol,
                                                                                trname=trname,
                                                                                fx_cnt=fx_cnt} end
              if not data.paramdata[trackidx][fxid] then data.paramdata[trackidx][fxid] = {fxname=fxname} end
              if not data.paramdata[trackidx][fxid][par_idx] then data.paramdata[trackidx][fxid][par_idx] = {paramname=paramname} end
              data.paramdata[trackidx].has_learn = true
              data.paramdata[trackidx][fxid].has_learn = true
              data.paramdata[trackidx][fxid][par_idx].has_learn = true              
              local t = 
                                                {   has_learn = true,
                                                    OSC_str=OSC_str, 
                                                    MIDI_Ch=MIDI_Ch,
                                                    MIDI_CC=MIDI_CC,
                                                    MIDI_msgtype = MIDI_msgtype,
                                                    isMIDI=isMIDI,
                                                    flags = flags,
                                                    flagsMIDI = flagsMIDI,
                                                    chunk = line,
                                                    paramname = paramname}
              data.paramdata[trackidx][fxid][par_idx] = CopyTable(t)
              data.paramdata[trackidx].hasMIDI = true
            end
            
            
            -- parameter modulation
            for line in fxchunk:gmatch('(<PROGRAMENV.-)>') do
              local par_idx = tonumber(line:match('%d+')) + 1
              local retval, paramname = reaper.TrackFX_GetParamName( tr, fxid-1, par_idx-1, '' )
              if not data.paramdata[trackidx]  then data.paramdata[trackidx] = {tr_ptr = tr,
                                                                                trcol=trcol,
                                                                                trname=trname,
                                                                                fx_cnt=fx_cnt} end
              if not data.paramdata[trackidx][fxid] then data.paramdata[trackidx][fxid] = {fxname=fxname} end
              if not data.paramdata[trackidx][fxid][par_idx] then data.paramdata[trackidx][fxid][par_idx] = {paramname=paramname} end 
              data.paramdata[trackidx].has_mod = true
              data.paramdata[trackidx][fxid].has_mod = true
              data.paramdata[trackidx][fxid][par_idx].has_mod = true
              data.paramdata[trackidx][fxid][par_idx].modulation = DataReadProject_GetMod(line) 
            end    
          end
        end 
      end
    end
  end  
  -------------------------------------------------------------------- 
  function DataReadProject_GetVariables(t0, line, param)
    local paramline = line:match(param..' (.-)\n')
    if not paramline then return end
    local t = {}
    for val in paramline:gmatch('[^%s]+') do 
      if tonumber(val) then val = tonumber(val) end--elseif val:match('%:') then val =  val:match('%d+') end
      t[#t+1] = val 
    end
    
    for i = 1, #t do t0[param..i] = t[i] end
  end  
  -------------------------------------------------------------------- 
  function DataReadProject_GetMod(line)
    local t = {typelink = 2, chunk = line} 
    DataReadProject_GetVariables(t, line, 'PROGRAMENV')
    DataReadProject_GetVariables(t, line, 'PARAMBASE')
    DataReadProject_GetVariables(t, line, 'LFO')
    DataReadProject_GetVariables(t, line, 'LFOWT')
    DataReadProject_GetVariables(t, line, 'AUDIOCTL')
    DataReadProject_GetVariables(t, line, 'AUDIOCTLWT')
    DataReadProject_GetVariables(t, line, 'LFOSHAPE')
    DataReadProject_GetVariables(t, line, 'LFOSYNC')
    DataReadProject_GetVariables(t, line, 'LFOSPEED')
    DataReadProject_GetVariables(t, line, 'CHAN')
    DataReadProject_GetVariables(t, line, 'STEREO')
    DataReadProject_GetVariables(t, line, 'RMS')
    DataReadProject_GetVariables(t, line, 'DBLO')
    DataReadProject_GetVariables(t, line, 'DBHI')
    DataReadProject_GetVariables(t, line, 'X2')
    DataReadProject_GetVariables(t, line, 'Y2')
    DataReadProject_GetVariables(t, line, 'PLINK')
    DataReadProject_GetVariables(t, line, 'MIDIPLINK')
    DataReadProject_GetVariables(t, line, 'MODWND')
    return t
  end
  ----------------------------------------------------------------
  function Data_ModifyMod_GetModStrParam(t, tset, paramstr)
    if not t[paramstr..'1'] then return end
    local s = paramstr..' '
    for i = 1, 20 do
      if not t[paramstr..i] then break end
      s = s..t[paramstr..i]..' '
    end
    tset[#tset+1] = s
  end
----------------------------------------------------------------
  function Data_ModifyMod_GetModStr(t, param)   
    local tset = {}
    Data_ModifyMod_GetModStrParam(t, tset, 'PROGRAMENV')
    Data_ModifyMod_GetModStrParam(t, tset, 'PARAMBASE')
    Data_ModifyMod_GetModStrParam(t, tset, 'LFO')
    Data_ModifyMod_GetModStrParam(t, tset, 'LFOWT')
    Data_ModifyMod_GetModStrParam(t, tset, 'AUDIOCTL')
    Data_ModifyMod_GetModStrParam(t, tset, 'AUDIOCTLWT')
    Data_ModifyMod_GetModStrParam(t, tset, 'LFOSHAPE')
    Data_ModifyMod_GetModStrParam(t, tset, 'LFOSYNC')
    Data_ModifyMod_GetModStrParam(t, tset, 'LFOSPEED')
    Data_ModifyMod_GetModStrParam(t, tset, 'CHAN')
    Data_ModifyMod_GetModStrParam(t, tset, 'STEREO')
    Data_ModifyMod_GetModStrParam(t, tset, 'RMS')
    Data_ModifyMod_GetModStrParam(t, tset, 'DBLO')
    Data_ModifyMod_GetModStrParam(t, tset, 'DBHI')
    Data_ModifyMod_GetModStrParam(t, tset, 'X2')
    Data_ModifyMod_GetModStrParam(t, tset, 'Y2')
    Data_ModifyMod_GetModStrParam(t, tset, 'PLINK')
    Data_ModifyMod_GetModStrParam(t, tset, 'MIDIPLINK')
    Data_ModifyMod_GetModStrParam(t, tset, 'MODWND')  
    str = '<'..table.concat(tset,'\n')..'\n>\n'
    return str
  end
  ----------------------------------------------------------------
  function Data_Actions_Loop(conf, obj, data, refresh, mouse, func)
    for trackid=1,data.cnt_tracks do
      if not data.paramdata[trackid] then goto skipnextrack end 
      local tr = data.paramdata[trackid].tr_ptr
      for fxid in pairs(data.paramdata[trackid]) do      
        if type(fxid) ~= 'number' then goto skipnexfx end
        for param in pairs(data.paramdata[trackid][fxid]) do      
          if type(param) ~= 'number' then goto skipnexparam end
          -- do stuff
          func(trackid,fxid,param)
          ::skipnexparam::
        end 
        ::skipnexfx::
      end  
      ::skipnextrack:: 
    end  
    UpdateArrange()
  end
  ----------------------------------------------------------------
  function Data_Actions_SHOWARMENV(conf, obj, data, refresh, mouse, title, selectedonly)
    Undo_BeginBlock2( 0 )
    Data_Actions_Loop(conf, obj, data, refresh, mouse,
    function(trackid,fxid,param)
      local track = data.paramdata[trackid].tr_ptr
      if selectedonly==true then if not IsTrackSelected( track ) then return end end
      local fxenv = GetFXEnvelope( track, fxid-1, param-1, true )
      local BR_env = reaper.BR_EnvAlloc( fxenv, false )
      local _, _, _, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties( BR_env )
      reaper.BR_EnvSetProperties( BR_env, true, true, true, inLane, laneHeight, defaultShape, faderScaling )
      reaper.BR_EnvFree( BR_env, true )
    end)
    Undo_EndBlock2( 0,conf.mb_title..': '..title, -1 )
  end
  ----------------------------------------------------------------
  function Data_Actions_REMOVELEARN(conf, obj, data, refresh, mouse, title, remove_OSC)
    Undo_BeginBlock2( 0 )
    Data_Actions_Loop(conf, obj, data, refresh, mouse,
    function(trackid,fxid,param)
      local track = data.paramdata[trackid].tr_ptr
      if not IsTrackSelected( track ) then return end
      if data.paramdata[trackid][fxid][param].has_learn and (remove_OSC==true and data.paramdata[trackid][fxid][param].OSC_str ~= '') 
        or (remove_OSC==false and data.paramdata[trackid][fxid][param].MIDI_CC and  data.paramdata[trackid][fxid][param].MIDI_CC >=0) then 
        Data_ModifyLearn(conf, data, trackid,fxid,param, true )
      end
    end)
    Undo_EndBlock2( 0,conf.mb_title..': '..title, -1 )
    refresh.data = true
    refresh.GUI = true
  end  
  ----------------------------------------------------------------
  function Data_Actions_REMOVEMOD(conf, obj, data, refresh, mouse, title)
    Undo_BeginBlock2( 0 )
    Data_Actions_Loop(conf, obj, data, refresh, mouse,
    function(trackid,fxid,param)
      local track = data.paramdata[trackid].tr_ptr
      if not IsTrackSelected( track ) then return end
      if data.paramdata[trackid][fxid][param].modulation then Data_ModifyMod(conf, data, trackid,fxid,param, true ) end
    end)
    Undo_EndBlock2( 0,conf.mb_title..': '..title, -1 )
    refresh.data = true
    refresh.GUI = true
  end  
    
