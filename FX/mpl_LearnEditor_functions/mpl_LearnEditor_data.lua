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
                OSC_str = t0[4]
               else
                MIDI_Ch = 1 + (t0[2] & 0x0F)
                MIDI_CC = (t0[2]>>8)& 0x0F
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
                                                    isMIDI=isMIDI,
                                                    flags = flags,
                                                    flagsMIDI = flagsMIDI,
                                                    chunk = line,
                                                    paramname = paramname}
              data.paramdata[trackidx][fxid][par_idx] = CopyTable(t)
              data.paramdata[trackidx].hasMIDI = true
            end
            
            
            
            -- parameter modulation
            for line in fxchunk:gmatch('<PROGRAMENV(.-)>') do
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

