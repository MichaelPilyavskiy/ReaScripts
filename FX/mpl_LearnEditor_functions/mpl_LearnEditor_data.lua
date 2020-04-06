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
        refresh.data = true
        refresh.GUI_onStart = true 
        refresh.GUI_WF = true       
       elseif ret == 2 then 
        refresh.conf = true
        refresh.data = true
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
  function Data_ModifyLearn(conf, data, trid,fx,param, remove )
    if remove ==true then
      tr= GetTrack(0,trid-1)
      if not tr then return end
      local retval, minval, maxval = reaper.TrackFX_GetParam( tr, fx-1, param-1 )
      if retval == -1 then MB('Something wrong with incoming data. Please report to the forum with attached RPP.', conf.mb_title, 0) return end
      
      local retval, tr_chunk = GetTrackStateChunk( tr, '', false )
      local fxGUID_check = TrackFX_GetFXGUID( tr, fx-1 )
      for fxchunk in tr_chunk:gmatch('(BYPASS.-WAK %d)') do
        local fxGUID = fxchunk:match('FXID (.-)\n')
        if not fxGUID then fxGUID = fxchunk:match('FXID_NEXT (.-)\n') end

        if fxGUID:match(literalize(fxGUID_check):gsub('%s', '')) then
          local fxchunk_mod = fxchunk:gsub('(PARMLEARN '..(param-1)..'.-)\n', '')
          tr_chunk = tr_chunk:gsub(literalize(fxchunk), fxchunk_mod)
          SetTrackStateChunk( tr, tr_chunk, false )
          return
        end
      end
    end
  end
  -----------------------------------------------
  function Data_ModifyMod(conf, data, trid,fx,param, remove )
    if remove ==true then
      tr= GetTrack(0,trid-1)
      if not tr then return end
      local retval, minval, maxval = reaper.TrackFX_GetParam( tr, fx-1, param-1 )
      if retval == -1 then MB('Something wrong with incoming data. Please report to the forum with attached RPP.', conf.mb_title, 0) return end
      
      local retval, tr_chunk = GetTrackStateChunk( tr, '', false )
      local fxGUID_check = TrackFX_GetFXGUID( tr, fx-1 )
      for fxchunk in tr_chunk:gmatch('(BYPASS.-WAK %d)') do
        local fxGUID = fxchunk:match('FXID (.-)\n')
        if not fxGUID then fxGUID = fxchunk:match('FXID_NEXT (.-)\n') end
  
        if fxGUID:match(literalize(fxGUID_check):gsub('%s', '')) then
          local fxchunk_mod = fxchunk:gsub('(<PROGRAMENV '..(param-1)..'.->)\n', '')
          tr_chunk = tr_chunk:gsub(literalize(fxchunk), fxchunk_mod)
          SetTrackStateChunk( tr, tr_chunk, false )
          return
        end
      end
    end
  end
  -----------------------------------------------
  function Data_ParamListBuild(conf, obj, data, refresh, mouse, runcollapsed)
    local tr_cs = 0.8
    local fxfull_cs = 0.7
    local fxcoll_cs = 0.2
    local paramfull_cs = 1
    local paramcoll_cs = 0.2
    
    local alpha_backfx = 0.2
    local alpha_back_ch = 0.1
    local alpha_backfxcol = 0.4
    local alpha_back_chcol = 0.3  
     
    --  local retval, fxname = reaper.TrackFX_GetFXName( tr, fxid, '' )
    --  local trGUID = reaper.GetTrackGUID( tr )
    --  local retval, trname = reaper.GetTrackName( tr )
    local build_t = {}
    for trid in spairs(data.paramdata) do 
      local def = 0
      if runcollapsed then def = 1 end
      if not obj.collapsed_states[trid] then obj.collapsed_states[trid] = def elseif obj.touched and obj.touched.trid and obj.touched.trid == trid then obj.collapsed_states[trid] = 0 end    
    end
    
    for trid in spairs(data.paramdata) do 
      -- track entry
      local tr = CSurf_TrackFromID( trid, false )
      if not tr then return end
      local retval, trname = reaper.GetTrackName( tr )
      local trcol =  reaper.GetTrackColor( tr )
      if trcol == 0 then trcol = nil end
      local tid = #build_t+1
      local txt = trid..': '..trname
      local is_tr_selected = obj.touched and obj.touched.trid and obj.touched.trid == trid
      if obj.collapsed_states[trid] == 0 then txt = '↓ '..txt else txt = '→ '..txt end
      build_t[tid] = {--CopyTable(data.paramdata[trid])
                      tpobj = 1,
                      show = tr_cs,
                      txt = txt,
                      align_txt = 1,
                      level = 0,
                      font = obj.GUI_fontsz2,
                      colint = trcol,
                      is_selected = is_tr_selected,
                      alpha_back = 0.7,
                      func = function() 
                              obj.collapsed_states[trid] = math.abs(1-obj.collapsed_states[trid]) 
                              if conf.expand_onetrackonly == 1 then
                                for trid0 in pairs(obj.collapsed_states) do 
                                  if trid0 and tonumber(trid0) and  tonumber(trid0) == tonumber(trid) then 
                                    obj.collapsed_states[trid0] = 0 
                                   else 
                                    obj.collapsed_states[trid0] = 1 
                                  end 
                                end
                              end
                              refresh.data = true
                              refresh.GUI = true 
                            end
                    }
      
      for fxid in spairs(data.paramdata[trid]) do
        local retval, fxname = reaper.TrackFX_GetFXName( tr, fxid-1, '' )
        local tid = #build_t+1
        local CS = fxfull_cs
        local txt = fxname--fxid..': '..fxname
        alpha_back = alpha_backfx
        if obj.collapsed_states[trid] == 1 then 
          CS = fxcoll_cs
          txt = ''
          alpha_back = alpha_backfxcol
        end
        build_t[tid] = {--CopyTable(data.paramdata[trid])
                        tpobj = 2,
                        show = CS,
                        txt = txt,
                        txt_colint = trcol,
                        align_txt = 1,
                        data_trid = trid,
                        data_fxid = fxid,
                        data_paramid = -1,
                        level = 1,
                        alpha_back = alpha_back,
                        font = obj.GUI_fontsz3,
                        func = function() end,
                        is_selected = obj.touched and obj.touched.trid and obj.touched.fxid and obj.touched.trid == trid and obj.touched.fxid == fxid,
                      }
        for param in spairs(data.paramdata[trid][fxid]) do
          local has_learn = data.paramdata[trid][fxid][param].has_learn
          local has_mod = data.paramdata[trid][fxid][param].has_mod
            local txt_a = 0.8
            local retval, paramname = TrackFX_GetParamName( tr, fxid-1, param-1, '' )
            local offline = false
            if paramname == '' then 
              paramname= ' <offline>'
              offline = true
              txt_a = 0.4
            end
            local tid = #build_t+1
            local CS = paramfull_cs
            local txt = '#'..param..': '..paramname
            local txt_MIDI,txt_OSC = '',''
            local flags, flagsMIDI = 0, 0
            if data.paramdata[trid][fxid][param].has_learn then 
              if data.paramdata[trid][fxid][param].isMIDI then 
                txt_MIDI = 'Ch '..data.paramdata[trid][fxid][param].MIDI_Ch..' CC '..data.paramdata[trid][fxid][param].MIDI_CC 
                flagsMIDI = data.paramdata[trid][fxid][param].flagsMIDI
              end
              if not data.paramdata[trid][fxid][param].isMIDI then txt_OSC = data.paramdata[trid][fxid][param].OSC_str end
              flags = data.paramdata[trid][fxid][param].flags
            end
            local alpha_back = alpha_back_ch
            if obj.collapsed_states[trid] == 1 then 
              CS = paramcoll_cs
              txt = ''
              alpha_back = alpha_backch_col
            end
            if (conf.showflag~=1 and has_learn==true)  then CS = 0 end--or offline
            if (conf.showflag~=2 and has_mod==true)  then CS = 0 end--or offline
            build_t[tid] = {--CopyTable(data.paramdata[trid])
                            tpobj = 3,
                            show = CS,
                            offline = offline,
                            txt = txt,
                            txt_MIDI = txt_MIDI,
                            txt_OSC = txt_OSC,
                            has_learn = has_learn,
                            flags_learn = flags,
                            flagsMIDI=flagsMIDI,
                            align_txt = 1,
                            txt_a = txt_a,
                            data_trid = trid,
                            data_fxid = fxid,
                            data_paramid = param,
                            alpha_back = alpha_back,
                            collapsed = obj.collapsed_states[trid] ~= 0,
                            level = 2,
                            font = obj.GUI_fontsz3,
                            func = function()
                                     local valpar = TrackFX_GetParam(  tr, fxid-1, param-1 ) 
                                     TrackFX_EndParamEdit( tr, fxid-1, param-1, valpar)
                                     Action(41144)
                                     refresh.data = true
                                   end,
                            func_MIDI = function() end,
                            func_OSC = function() end,
                            func_flags1 = function() end, -- selected/focused/visible
                            func_flags2 = function() end, -- softtakeover
                            func_flagsMIDI = function() end, -- softtakeover
                            is_selected = obj.touched and obj.touched.trid and obj.touched.fxid and obj.touched.paramid and 
                                          obj.touched.trid == trid and obj.touched.fxid == fxid and obj.touched.paramid == param,
                          }
        end
      end
      
    end
    --return build_t
    obj.build_t = build_t
  end
  ---------------------------------------------------
  function DataReadProject(conf, obj, data, refresh, mouse) 
    data.paramdata = {}
    for trackidx =1,  CountTracks( 0 ) do
      local tr =  GetTrack( 0, trackidx-1 )
      if tr then 
        local retval, tr_chunk = GetTrackStateChunk( tr, '', false )
        for fxchunk in tr_chunk:gmatch('(BYPASS.-WAK %d)') do
          local fxGUID = fxchunk:match('FXID (.-)\n')
          if not fxGUID then fxGUID = fxchunk:match('FXID_NEXT (.-)\n') end
          local ret, tr, fxid = VF_GetFXByGUID(fxGUID, tr)
          if ret then  -- for freezed VST
            fxid = fxid + 1 
            -- midi osc learn
            for line in fxchunk:gmatch('PARMLEARN(.-)\n') do
              local t = {} 
              for ssv in line:gmatch('[^%s]+') do if tonumber(ssv) then ssv = tonumber(ssv) end t[#t+1] = ssv end
              local par_idx = t[1]+1
              local retval, paramname = reaper.TrackFX_GetParamName( tr, fxid, par_idx-1, '' )
              local isMIDI = t[2] > 0
              local flags = t[3]
              local flagsMIDI = (t[2] >>14)&0x1F
              local OSC_str, MIDI_Ch, MIDI_CC
              if isMIDI==false then 
                OSC_str = t[4]
               else
                MIDI_Ch = 1 + (t[2] & 0x0F)
                MIDI_CC = 1 + ((t[2]& 0xF0) >> 7)
                OSC_str = '' 
              end
              
              if not data.paramdata[trackidx]  then data.paramdata[trackidx] = {} end
              if not data.paramdata[trackidx][fxid] then data.paramdata[trackidx][fxid] = {} end
              if not data.paramdata[trackidx][fxid][par_idx] then data.paramdata[trackidx][fxid][par_idx] = {} end
              local t = 
                                                {   has_learn = true,
                                                    OSC_str=OSC_str, 
                                                    MIDI_Ch=MIDI_Ch,
                                                    MIDI_CC=MIDI_CC,
                                                    isMIDI=isMIDI,
                                                    flags = flags,
                                                    flagsMIDI = flagsMIDI,
                                                    chunk = line,
                                                    paramname = paramname}
              data.paramdata[trackidx][fxid][par_idx] = CopyTable(t)
            end
            
            -- parameter modulation
            for line in fxchunk:gmatch('<PROGRAMENV(.-)>') do
              local par_idx = tonumber(line:match('%d+')) + 1
              if not data.paramdata[trackidx]  then data.paramdata[trackidx] = {} end
              if not data.paramdata[trackidx][fxid] then data.paramdata[trackidx][fxid] = {} end
              if not data.paramdata[trackidx][fxid][par_idx] then data.paramdata[trackidx][fxid][par_idx] = {} end
              --data.paramdata[trackidx].has_mod = true
              --data.paramdata[trackidx][fxid].has_mod = true
              data.paramdata[trackidx][fxid][par_idx].has_mod = true
              data.paramdata[trackidx][fxid][par_idx].modulation = {typelink =2, chunk = line}
s=[[
 18 0
PARAMBASE 0.111
LFO 1
LFOWT 1 1
AUDIOCTL 1
AUDIOCTLWT 1 1
PLINK 1 -100 26 0
MIDIPLINK 0 0 160 34
LFOSHAPE 0
LFOSYNC 0 0 0
LFOSPEED 0.049536 0
CHAN 1
STEREO 0
RMS 300 300
DBLO -24
DBHI 0
X2 0.144737
Y2 0.703196
]]
            end    
          end
        end 
      end
    end
  end  

