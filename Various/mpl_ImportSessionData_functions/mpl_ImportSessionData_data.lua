-- @description ImportSessionData_data
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
       elseif ret == 2 then 
        refresh.conf = true
        refresh.data = true
      end
  end
  --------------------------------------------------- 
  function Data_GetParamsFromGUID(data, guid_check)
    if not data.cur_tracks then return false, '' end
    for i = 1,  #data.cur_tracks do
      if data.cur_tracks[i].GUID == guid_check then return true, i..': '..data.cur_tracks[i].tr_name,  data.cur_tracks[i].tr_col end
    end
  end
  --------------------------------------------------- 
  function Data_DefineFile(conf, obj, data, refresh, mouse)
    local retval, filenameNeed4096 = reaper.GetUserFileNameForRead(conf.lastrppsession, 'Import RPP session data', '.RPP' )
    if retval then conf.lastrppsession = filenameNeed4096 end
    refresh.conf = true
    refresh.GUI = true
  end
  --------------------------------------------------- 
  --[[f_unction Data_ParseRPP_ExtractChunks2(tr_chunks, t)
    local tr_id = 0
    local bracketslevel = 0
    for i = 1, #t do 
      local line = t[i]
      if    line:match('<TRACK') 
        or  line:match('<MASTERFXLIST') 
        or  line:match('<TEMPOENVEX')
        then 
        if tr_chunks[tr_id-1] then 
          local s = table.concat(tr_chunks[tr_id-1], '\n') 
          tr_chunks[tr_id-1] = s
        end
        bracketslevel = bracketslevel + 1 
        tr_id = tr_id + 1
      end
      
      if bracketslevel >0 then
        if line:match('>') and not line:match('%b<>') then bracketslevel = bracketslevel - 1 end
        if line:match('<') and not line:match('%b<>') then bracketslevel = bracketslevel + 1 end
      end        
      
      
      if bracketslevel > 0 then
        if not tr_chunks[tr_id] then tr_chunks[tr_id] = {} end
        tr_chunks[tr_id] [#tr_chunks[tr_id]+1] = line
      end 
    end
    local s = table.concat(tr_chunks[tr_id-1], '\n') 
    tr_chunks[tr_id-1] = s
    local s = table.concat(tr_chunks[tr_id], '\n') 
    tr_chunks[tr_id] = s
  end ]]
  --------------------------------------------------- 
  function Data_ParseRPP_ExtractChunks(tr_chunks, t)
    local tr_id = 0
    local bracketslevel = 0
    local init_parse, t_trackstart
    local params = {}
    for i = 1, #t do 
      local line = t[i]
      
      if line:match('<TRACK') 
        or line:match('<MASTERFXLIST') 
        or line:match('<TEMPOENVEX') 
        then 
        if line:match('<TRACK') and not t_trackstart then t_trackstart = i end
        tr_id = tr_id + 1
        init_parse = true
      end
      
      if init_parse == true
        and not line:match('<REAPER_PROJECT') 
        and not line:match('<POOLEDENV') 
        and line:match('<[A-Z%d]+') 
        and line:match('<[A-Z%d]+') == line:match('<[A-Z%d]+'):upper() 
        then
        bracketslevel = bracketslevel + 1
      end
      if bracketslevel > 0 and tr_id > 0 then
        if not tr_chunks[tr_id] then tr_chunks[tr_id] = {} end
        tr_chunks[tr_id] [#tr_chunks[tr_id]+1] = line
      end 
      
      if bracketslevel > 0 and init_parse == true and (line:find('>') == 1 or line:match('[%s]+>')) then bracketslevel = bracketslevel - 1 end 
      if bracketslevel == 0 and init_parse == true then init_parse = false end
    end
    
    -- convert tables into chunks
    for i = 1, #tr_chunks do
      local s = table.concat(tr_chunks[i], '\n') 
      tr_chunks[i] = s
    end
    return t_trackstart
  end 
  --------------------------------------------------- 
  function Data_ParseRPP_GetGlobalParam(t, t_trackstart, key, valid)  
    
    local mult_t = {}
    for i = 1, t_trackstart do
      local line = t[i]
      if line:match(key) then
        mult_t[#mult_t+1] = Data_ParseQM_String(line:match(key..'%s(.*)'))
        if key:match('MARKER') then
          local id = #mult_t
          for j = 4, #mult_t[id] do
            if type(mult_t[id][j]) == 'string' then 
              mult_t[id][3] = mult_t[id][3]..mult_t[id][j] 
             else
              for j2 =j-1, 4, -1 do
                test = mult_t[id]
                table.remove(mult_t[id], j2)
              end
              goto skip_regstr_valid
            end
          end
        end
        ::skip_regstr_valid::
        --[[local ts = {}
        local tid = 1
        local openpar = false
        for char in line:gmatch('.') do 
          if char:match('%s+') and openpar == false then tid = #ts + 1 char = ''
            elseif char:match('%s%"+') and openpar == false then openpar = true char = ''
            elseif char:match('%"%s') and openpar == true then openpar = false char = ''
          end
           
          if not ts[tid] then ts[tid] = '' end
          ts[tid] = ts[tid]..char
        end
        
        for i = 1, #ts do 
          local val = ts[i]:gsub('"','')
          if tonumber(val) then val = tonumber(val) end 
          ts[i] = val 
        end
        mult_t[#mult_t+1] = ts]]
        
      end
    end
    return mult_t 
  end
  function Data_ParseQM_String(text) --https://stackoverflow.com/questions/28664139/lua-split-string-into-words-unless-quoted
    local t = {}
    local spat, epat, buf, quoted = [=[^(['"])]=], [=[(['"])$]=]
    for str in text:gmatch("%S+") do
      local squoted = str:match(spat)
      local equoted = str:match(epat)
      local escaped = str:match([=[(\*)['"]$]=])
      if squoted and not quoted and not equoted then
        buf, quoted = str, squoted
      elseif buf and equoted == quoted and #escaped % 2 == 0 then
        str, buf, quoted = buf .. ' ' .. str, nil, nil
      elseif buf then
        buf = buf .. ' ' .. str
      end
      if not buf then 
        local val = str:gsub(spat,""):gsub(epat,"") 
        if tonumber(val) then val = tonumber(val) end
        t[#t+1] = val
      end
    end
    return t
  end
  --------------------------------------------------- 
  function Data_ParseRPP(conf, obj, data, refresh, mouse)  
    data.hasRPPdata = false
    local f = io.open(conf.lastrppsession, 'rb')
    if not f then return end
    local content = f:read('a')
    f:close()
    
    data.rppsession_path = GetParentFolder(conf.lastrppsession)
    local t = {} for line in content:gmatch('[^\r\n]+') do t[#t+1] = line end
    
    --
    
    local tr_chunks = {}
    local t_trackstart = Data_ParseRPP_ExtractChunks(tr_chunks, t) 
    if t_trackstart then 
      local marker_key = 'marker'
      data[marker_key] = Data_ParseRPP_GetGlobalParam(t, t_trackstart, 'MARKER', 1)
    end
    
    data.tr_chunks = {}    
    -- parse chunks
    local parse_str_limit = 500
    for i = 1, #tr_chunks do 
      local ch_str = tr_chunks[i]
      if type(ch_str) == 'string' then
        local tr_name = Data_ParseRPP_GetParam(ch_str, 'NAME', parse_str_limit)
        local tr_col = Data_ParseRPP_GetParam(ch_str, 'PEAKCOL', parse_str_limit)
        local _, ISBUS_t = Data_ParseRPP_GetParam(ch_str, 'ISBUS', parse_str_limit, 2)
        local AUXRECV = Data_ParseRPP_GetParam2(ch_str, 'AUXRECV')
        AUXRECV = Data_ParseRPP_ParseAUXRECV(AUXRECV)
        if tr_col == 16576 then tr_col = nil end
        local obj_type = ''
        if ch_str:match('<TRACK') then 
          obj_type = 'track'
          data.tr_chunks[#data.tr_chunks+1] = {chunk = ch_str,
                              tr_name = tr_name,
                              tr_col=tr_col,
                              dest = '',
                              I_FOLDERDEPTH=ISBUS_t[2],
                              obj_type=obj_type,
                              AUXRECV=AUXRECV}
         end                     
        if ch_str:match('<MASTERFXLIST') then 
          data.masterfxchunk = {chunk = ch_str}        
        end 
        if ch_str:match('<TEMPOENVEX') then 
          data.tempodata = Data_ParseRPP_GetTempo(ch_str)       --data. 
        end                                 
      end
    end
    
    
    data.hasRPPdata = true
    refresh.GUI = true
  end
  --------------------------------------------------------------------  
  function Data_ImportMasterStuff_FX(conf, obj, data, refresh, mouse, strategy)
    if not (strategy.master_stuff&1 == 1 or (strategy.master_stuff&1 == 0 and strategy.master_stuff&2 == 2)) then return end
    local mastertr = GetMasterTrack( 0 )
    local chunk_replace = data.masterfxchunk.chunk:gsub('MASTERFXLIST', 'FXCHAIN')
    local retval, cur_chunk = reaper.GetTrackStateChunk( mastertr, '', false )
    
    local i_start, i_end
    if not cur_chunk:match('<FXCHAIN') then 
      local out_ch = cur_chunk:reverse():gsub('>','', 1):reverse()..chunk_replace..'\n>'
      SetTrackStateChunk( mastertr, out_ch, false )
      return
    end
    
    -- parse current
    local t = {} for line in cur_chunk:gmatch('[^\r\n]+') do t[#t+1] = line end 
    local tr_chunks = {}
    local tr_id = 0
    local bracketslevel = 0
    for i = 1, #t do 
      local line = t[i]
      if line:match('<FXCHAIN') then i_start = i end
      if i_start and line:match('<[A-Z%d]+') and line:match('<[A-Z%d]+') == line:match('<[A-Z%d]+'):upper() then bracketslevel = bracketslevel + 1 end
      if i_start and line:find('>') == 1 or line:match('[%s]+>') then bracketslevel = bracketslevel - 1 end 
      if bracketslevel == 0 and i_start then i_end = i break end 
    end
    out_ch = table.concat(t,'\n',1,i_start-1)..'\n\n'..chunk_replace..'\n>\n'.. table.concat(t,'\n',i_end+1)
    --msg(out_ch)
    SetTrackStateChunk( mastertr, out_ch, false )
  end
  -------------------------------------------------------------------- 
  function Data_ImportTracks_NewTrack(data, i, insert_id)
    InsertTrackAtIndex( insert_id, false )
    local new_tr = GetTrack(0, insert_id)
    local new_chunk = data.tr_chunks[i].chunk
    local gGUID = genGuid('' ) 
    new_chunk = new_chunk:gsub('TRACK[%s]+.-\n', 'TRACK '..gGUID..'\n')
    new_chunk = new_chunk:gsub('AUXRECV .-\n', '\n')
    SetTrackStateChunk( new_tr, new_chunk, false )
    gGUID = GetTrackGUID( new_tr )
    data.tr_chunks[i].destGUID = gGUID
    return new_tr
  end
  --------------------------------------------------------------------  
  function Data_ImportTracks(conf, obj, data, refresh, mouse, strategy) 
    for i = 1, #data.tr_chunks do
    
      if data.tr_chunks[i].dest == -1 then  -- end of track list
        Data_ImportTracks_NewTrack(data, i, CountTracks( 0 ))
      elseif type(data.tr_chunks[i].dest) == 'string' and data.tr_chunks[i].dest ~= '' then  -- to specific track
        local dest_tr = VF_GetTrackByGUID(data.tr_chunks[i].dest)
        if dest_tr then 
          local tr_id = CSurf_TrackToID( dest_tr, false )
          -- set chunk
          if strategy.comchunk == 1 then
            
            local new_chunk = data.tr_chunks[i].chunk
            local gGUID = genGuid('' ) 
            new_chunk = new_chunk:gsub('TRACK .-\n', 'TRACK '..gGUID..'\n')
            new_chunk = new_chunk:gsub('AUXRECV .-\n', '\n')
            SetTrackStateChunk( dest_tr, new_chunk, false )
            gGUID = reaper.GetTrackGUID( dest_tr )
            data.tr_chunks[i].destGUID = gGUID
           else 
            local new_tr = Data_ImportTracks_NewTrack(data, i, tr_id)
            Data_ImportTracks_AppStr(conf, obj, data, refresh, mouse, strategy, new_tr, dest_tr) 
            data.tr_chunks[i].destGUID =  GetTrackGUID( dest_tr )
            DeleteTrack( new_tr )
          end
        end
       elseif data.tr_chunks[i].dest == -2 then
        
      end   
          
    end   
    Data_ImportTracks_Send(conf, obj, data, refresh, mouse, strategy) 
    if strategy.tritems&8==8 then Action(40047) end -- Peaks: Build any missing peaks
  end

  --------------------------------------------------- 
  function Data_ParseRPP_ParseAUXRECV(AUXRECV)
    local t = {}
    for i =1 , #AUXRECV do
      local line = AUXRECV[i]
      local valt = {}
      for val in line:gmatch('[^%s]+') do valt[#valt+1] = val end
      local ret_t = {}
      ret_t.src_id = tonumber(valt[1])
      ret_t.mode = tonumber(valt[2])
      ret_t.vol = tonumber(valt[3])
      ret_t.pan = tonumber(valt[4])
      ret_t.mute = tonumber(valt[5])
      ret_t.monosum = tonumber(valt[6])
      ret_t.phaseinv = tonumber(valt[7])
      ret_t.srcchan = tonumber(valt[8])
      ret_t.destchan = tonumber(valt[9])
      ret_t.panlaw = tonumber(valt[10]:match('[%d%.]+'))
      ret_t.midichan = tonumber(valt[11])
      ret_t.automode = tonumber(valt[12])
      t[#t+1] = ret_t
    end
    return t
  end
  -------------------------------------------------------------------- 
  function Data_ImportTracks_Send_SetData(conf, obj, data, refresh, mouse, strategy, new_tr, sendidx, auxt)
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'D_VOL', auxt.vol )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'B_MUTE', auxt.mute )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'B_PHASE', auxt.phaseinv )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'B_MONO', auxt.monosum )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'D_PAN', auxt.pan )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'D_PANLAW', auxt.panlaw )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_SENDMODE', auxt.mode )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_SRCCHAN', auxt.srcchan )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_DSTCHAN', auxt.destchan )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_AUTOMODE', auxt.automode )
    SetTrackSendInfo_Value( new_tr, 0, sendidx, 'I_MIDIFLAGS', auxt.midichan )
  end
  --------------------------------------------------------------------  
  function Data_ImportTracks_Send(conf, obj, data, refresh, mouse, strategy) 
    --if strategy.trsend&1 == 0 then return end
    for i = 1, #data.tr_chunks do
      if data.tr_chunks[i].dest~= '' and #data.tr_chunks[i].AUXRECV > 0 then
        for auxid = 1,#data.tr_chunks[i].AUXRECV do
          local tr_chunks_id = data.tr_chunks[i].AUXRECV[auxid].src_id+1
          if tr_chunks_id and data.tr_chunks[tr_chunks_id] then
            
            if data.tr_chunks[tr_chunks_id].dest == '' and strategy.trsend&2 ==2 then -- src track not added
            
                data.tr_chunks[tr_chunks_id].dest = -1
                local paste_send_at_ID = CountTracks( 0 )
                local new_tr = Data_ImportTracks_NewTrack(data, tr_chunks_id, paste_send_at_ID)
                local imported_dst_tr = VF_GetTrackByGUID(data.tr_chunks[i].destGUID) 
                local has_send = false 
                if strategy.trsend&16 ~=16 then
                  for sendidx =1,  GetTrackNumSends( imported_dst_tr, 0 ) do
                    local srctr0 = GetTrackSendInfo_Value( imported_dst_tr, 0, sendidx-1, 'P_SRCTRACK' )
                    if GetTrackGUID(srctr0) == GetTrackGUID(new_tr) then has_send = true end
                  end
                end 
                if not has_send then
                  local sendidx = CreateTrackSend( new_tr, imported_dst_tr )
                  Data_ImportTracks_Send_SetData(conf, obj, data, refresh, mouse, strategy, new_tr, sendidx, data.tr_chunks[i].AUXRECV[auxid])
                end
              
             elseif strategy.trsend&4 ==4 and type(data.tr_chunks[tr_chunks_id].dest) == 'string'   then -- if source track is imported to matched track--and type(data.tr_chunks[tr_chunks_id].dest) =='string'
             
               local imported_src_tr = VF_GetTrackByGUID(data.tr_chunks[tr_chunks_id].destGUID)
               local imported_dst_tr = VF_GetTrackByGUID(data.tr_chunks[i].destGUID) 
               if imported_src_tr and imported_dst_tr then
                 local has_send = false 
                 if strategy.trsend&16 ~=16 then
                   for sendidx =1,  GetTrackNumSends( imported_dst_tr, -1 ) do
                     local srctr0 = GetTrackSendInfo_Value( imported_dst_tr, -1, sendidx-1, 'P_SRCTRACK' )
                     if GetTrackGUID(srctr0 ) == GetTrackGUID(imported_src_tr ) then has_send = true end
                   end
                 end 
                 if not has_send then
                  local sendidx = CreateTrackSend( imported_src_tr, imported_dst_tr )
                  Data_ImportTracks_Send_SetData(conf, obj, data, refresh, mouse, strategy, imported_src_tr, sendidx, data.tr_chunks[i].AUXRECV[auxid])
                 end
                end
                
             elseif strategy.trsend&8 ==8 and  data.tr_chunks[tr_chunks_id].dest == -1 then -- if source track is imported as a new track
             
               local imported_src_tr = VF_GetTrackByGUID(data.tr_chunks[tr_chunks_id].destGUID)
               --reaper.SetTrackColor( imported_src_tr, 0 )
               local imported_dst_tr = VF_GetTrackByGUID(data.tr_chunks[i].destGUID)
               local has_send = false 
               if strategy.trsend&16 ~=16 then
                 for sendidx =1,  GetTrackNumSends( imported_dst_tr, -1 ) do
                   local srctr0 = GetTrackSendInfo_Value( imported_dst_tr, -1, sendidx-1, 'P_SRCTRACK' )
                   if GetTrackGUID(srctr0 ) == GetTrackGUID(imported_src_tr ) then has_send = true end
                 end
                end
               if not has_send then
                local sendidx = CreateTrackSend( imported_src_tr, imported_dst_tr )
                Data_ImportTracks_Send_SetData(conf, obj, data, refresh, mouse, strategy, imported_src_tr, sendidx, data.tr_chunks[i].AUXRECV[auxid])
               end              
               
             elseif data.tr_chunks[tr_chunks_id].dest == -2 and data.tr_chunks[tr_chunks_id].destGUID then -- if source track is only mark as source for send
                
               local imported_src_tr = VF_GetTrackByGUID(data.tr_chunks[tr_chunks_id].destGUID)
               local imported_dst_tr = VF_GetTrackByGUID(data.tr_chunks[i].destGUID)
               local has_send = false
               if strategy.trsend&16 ~=16 then
                 for sendidx =1,  GetTrackNumSends( imported_dst_tr, -1 ) do
                   local srctr0 = GetTrackSendInfo_Value( imported_dst_tr, -1, sendidx-1, 'P_SRCTRACK' )
                   if GetTrackGUID(srctr0 ) == GetTrackGUID(imported_src_tr ) then has_send = true end
                 end
               end
               if not has_send then
                local sendidx = CreateTrackSend( imported_src_tr, imported_dst_tr )
                Data_ImportTracks_Send_SetData(conf, obj, data, refresh, mouse, strategy, imported_src_tr, sendidx, data.tr_chunks[i].AUXRECV[auxid])
               end                
            end             
          end
        end
      end
    end
  end
  --------------------------------------------------------------------  
  function Data_ImportMasterStuff_Markers(conf, obj, data, refresh, mouse, strategy)   
    local marker_key = 'marker'
    
    --[[           &1 markers
                &2 markersreplace
                &4 regions
                &8 regionsreplace
                       
                ]]
    if not 
      (strategy.master_stuff&1 == 1 or 
        (strategy.master_stuff&1 == 0 and 
          (strategy.markers_flags&1 == 1 or strategy.markers_flags&4 == 4) 
          and data[marker_key]
        )
      ) then return end
      
    -- handle replace / aka remove old regions markers
    if (strategy.markers_flags&2 ==2 or strategy.markers_flags&8 ==8) then
      local retval, num_markers, num_regions = CountProjectMarkers( 0 )
      for i = num_markers+num_regions, 1,-1 do 
        local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i-1 )
        if (strategy.markers_flags&2 ==2 and isrgn ==false) or (strategy.markers_flags&8 ==8 and isrgn ==true) then DeleteProjectMarkerByIndex( 0, i-1 ) end
      end
    end
     
     
      for i = 1, #data[marker_key] do
        local flags = data[marker_key][i][4]
        local isrgn = flags &1==1
        local pos = data[marker_key][i][2]
        local rgnend = -1 if isrgn==true then rgnend =data[marker_key][i+1][2] end
        local name = data[marker_key][i][3]
        local color = data[marker_key][i][5]
        --[[if strategy.markers_flags&2==2 then
          if color~= 0 then
            local r, g, b = ColorFromNative( color )
            color = ColorToNative( b, g, r )|0x1000000
          end
        end]]
        local IDnumber = data[marker_key][i][1] 
        if (strategy.markers_flags&1 == 1 and isrgn==false) or 
          (strategy.markers_flags&4 == 4 and isrgn==true) or
          (strategy.master_stuff&1 ==1) and 
          IDnumber
          then 
          if (isrgn == true and pos < rgnend and rgnend ~= -1) or (isrgn == false and rgnend == -1)  then

            local markrgnidx = AddProjectMarker2( 0, 
                                      true, 
                                      1, 
                                      2, 
                                      '__reserved', 
                                      0, 
                                      0 )
            SetProjectMarkerByIndex2( 0, markrgnidx, isrgn, pos, rgnend, IDnumber, name, color, 0 )
          end
        end
        if is_reg == true then i = i+1 end
      end
      
    -- workaround to remove invisible temp marker
    local retval, num_markers, num_regions = CountProjectMarkers( 0 )
    for i = num_markers+num_regions, 1,-1 do 
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i-1 )
      if name == '__reserved' then DeleteProjectMarkerByIndex( 0, i-1 ) end
    end
  end
  --------------------------------------------------------------------
  function Data_ImportMasterStuff_Tempo(conf, obj, data, refresh, mouse, strategy)  
    if not (strategy.master_stuff&1 == 1 or (strategy.master_stuff&1 == 0 and strategy.master_stuff&4 == 4)) then return end
    if not data.tempodata then return end 
    for markerindex = CountTempoTimeSigMarkers( proj ), 1, -1 do DeleteTempoTimeSigMarker( 0, markerindex-1 ) end 
    for i = 1, #data.tempodata do
      local timesig_num = 0
      local timesig_denom = 0
      local lineartempo = false
      if data.tempodata[i].timesig_num and data.tempodata[i].timesig_denom then 
        timesig_num = data.tempodata[i].timesig_num
        timesig_denom = data.tempodata[i].timesig_denom
      end
      if data.tempodata[i].lineartempochange and data.tempodata[i].lineartempochange==true then lineartempo = data.tempodata[i].lineartempochange end
      reaper.SetTempoTimeSigMarker( 0, -1, data.tempodata[i].timepos, -1, -1, data.tempodata[i].bpm, timesig_num, timesig_denom, lineartempo )
    end
  end
  --------------------------------------------------------------------
  function Data_ParseRPP_GetTempo(ch_str) 
    local t = {chunk = ch_str}
    for line in ch_str:gmatch('[^\r\n]+') do
      if line:match('PT %d+') then
        local valt = {} for val in line:gmatch('[^%s]+') do valt[#valt+1] = val end
        local timepos = tonumber(valt[2])
        local bpm = tonumber(valt[3])
        local lineartempochange = tonumber(valt[4])&1==0
        local timesig_num, timesig_denom
        if valt[5] then
          local timesig = valt[5]
          timesig_num = timesig&0xFFFF
          timesig_denom = (timesig>>16)&0xFFFF
        end
        t[#t+1] = {timepos=timepos,
                  bpm=bpm,
                  lineartempochange=lineartempochange,
                  timesig_num=timesig_num,
                  timesig_denom=timesig_denom}
      end
    end
    return t
  end
  --------------------------------------------------------------------  
  function Data_ImportMasterStuff(conf, obj, data, refresh, mouse, strategy) 
    Data_ImportMasterStuff_FX(conf, obj, data, refresh, mouse, strategy) 
    Data_ImportMasterStuff_Markers(conf, obj, data, refresh, mouse, strategy)  
    Data_ImportMasterStuff_Tempo(conf, obj, data, refresh, mouse, strategy)  
  end 
  --------------------------------------------------------------------  
  function Data_ParseRPP_GetParam(ch_str, key, find_until, val_cnt)
    if not find_until then find_until = ch_str:len() end
    ch_str = ch_str:sub(0,find_until)
    local val
    local val_t = {}
    if val_cnt then 
      local pat = '%s[%d%p]+'
      local multiple_val_str = ch_str:match(key..'('..pat:rep(val_cnt)..')')
      --msg(multiple_val_str)
      if multiple_val_str then 
        for num in multiple_val_str:gmatch('[%d%p]+') do  val_t[#val_t+1] = tonumber(num) end
      end
    end
    if not val then val= ch_str:match(key..' %"(.-)%"') end -- string inside ""
    if not val then val = ch_str:sub(0,find_until):match(key..'%s([%a%p%d]+)\n') end
    if not val and ch_str:sub(0,find_until):match(key..' ""') then val = '' end
    if not val then val = '' end
    if tonumber(val) then val = tonumber(val) end
    return val, val_t
  end
  --------------------------------------------------------------------  
  function Data_ParseRPP_GetParam2(ch_str, key)
    local val_t = {}
    for line in ch_str:gmatch(key..' (.-)\n') do val_t[#val_t+1] = line end
    --[[if not ch_str then return end
    local val_t = {}
    for val in ch_str:gmatch('[^%s]+') do val_t[#val_t+1]=val end]]
    return val_t--val_t
  end  
  --------------------------------------------------------------------  
  function Data_DefineUsedTracks(conf, obj, data, refresh, mouse)
    for i2 = 1, #data.cur_tracks do
      data.cur_tracks[i2].used = nil
      for i = 1, #data.tr_chunks do
        if data.tr_chunks[i].dest == data.cur_tracks[i2].GUID then  
          data.cur_tracks[i2].used = i
        end
      end
    end
  end
  --------------------------------------------------------------------  
  function Data_CollectProjectTracks(conf, obj, data, refresh, mouse)
    local  retval, projfn = EnumProjects( -1 )
    --local projfn = GetShortSmplName(projfn)
    
    data.cur_project = projfn 
    data.cur_tracks = {}
    local folderlev = 0
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      local GUID = GetTrackGUID( tr )
      local tr_col =  GetTrackColor( tr )
      local folderd = GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' )
      data.cur_tracks[i] = {tr_name =  ({GetTrackName( tr )})[2],
                            GUID = GUID,
                            tr_col=tr_col,
                            folderd=folderd,
                            folderlev=folderlev
                            }
      folderlev = folderlev + folderd                            
    end
  end
  -------------------------------------------------------------------- 
  function Data_ClearDest(conf, obj, data, refresh, mouse, strategy, to_new_track) 
    local dest  = '' if to_new_track then dest = -1  end
    for i = 1, #data.tr_chunks do data.tr_chunks[i].dest = dest end 
    for i = 1, #data.cur_tracks do data.cur_tracks[i].used =  nil end 
  end  
  -------------------------------------------------------------------- 
  function Data_MatchDest(conf, obj, data, refresh, mouse, strategy, is_new, specificid) 
    if not data.tr_chunks then return end
    local i0 = 1
    local cnt = #data.tr_chunks
    if specificid then 
      cnt = specificid
      i0 = specificid
    end
    
    for i = i0, cnt do 
      if conf.match_flags&1 == 0 then 
        data.tr_chunks[i].dest = Data_MatchDestSub1(conf, obj, data, refresh, mouse, strategy, data.tr_chunks[i].tr_name, is_new, i) 
       else
        data.tr_chunks[i].dest = Data_MatchDestSub2(conf, obj, data, refresh, mouse, strategy, data.tr_chunks[i].tr_name, is_new, i) 
      end
    end 
  end
  -------------------------------------------------------------------- 
  function Data_MatchDestSub1(conf, obj, data, refresh, mouse, strategy, tr_name, is_new, id_src) 
    if not tr_name then return '' end
    if tr_name == '' then return '' end
    tr_name = tostring(tr_name)
    if tr_name:match('Track %d+') then return '' end
    
    --if data.cur_tracks[id_src].folderd 
    local is_new_val = -1
    local t = {}
    local cnt_match0, cnt_match, last_biggestmatch = 0, 0
    
    for word in tr_name:gmatch('[^%s]+') do t[#t+1] = literalize(word:lower():gsub('%s+','')) end
    for trid = 1, #data.cur_tracks do 
      if not data.cur_tracks[trid].used then
        local tr_name_CUR = data.cur_tracks[trid].tr_name:lower()
        if tr_name_CUR ~= '' and not tr_name_CUR:match('track %d+') then
          cnt_match0 = 0
          for i = 1, #t do if tr_name_CUR:match(t[i]) then cnt_match0 = cnt_match0 + 1 end end
          if cnt_match0 == #t then
            data.cur_tracks[trid].used = id_src 
            if not is_new then return data.cur_tracks[trid].GUID  else return is_new_val end
          end
          if cnt_match0 > cnt_match then last_biggestmatch = trid end 
          cnt_match = cnt_match0
        end
      end
    end
    if last_biggestmatch then 
      data.cur_tracks[last_biggestmatch].used = id_src
      if not is_new then return data.cur_tracks[last_biggestmatch].GUID   else return is_new_val end
    end
    
    return ''
  end
  -------------------------------------------------------------------- 
  function Data_MatchDestSub2(conf, obj, data, refresh, mouse, strategy, tr_name, is_new, id_src) 
    if not tr_name then return '' end
    if tr_name == '' then return '' end
    tr_name = tostring(tr_name)
    if tr_name:match('Track %d+') then return '' end
    
    --if data.cur_tracks[id_src].folderd
    local is_new_val = -1
    local t = {}
    local cnt_match0, cnt_match, last_biggestmatch = 0, 0
    for trid = 1, #data.cur_tracks do
      --if not data.cur_tracks[trid].used then
        local tr_name_CUR = data.cur_tracks[trid].tr_name
        if conf.match_flags&2==0 then tr_name_CUR = tr_name_CUR:lower() end
        if tr_name_CUR ~= '' and not tr_name_CUR:match('rack %d+') then
          if conf.match_flags&2==0 then tr_name = tr_name:lower() end
          if tr_name_CUR:match(tr_name) then
            data.cur_tracks[trid].used = id_src
            if not is_new then return data.cur_tracks[trid].GUID  else return is_new_val end
          end
        end
      --end
    end
    
    return ''
  end
  -------------------------------------------------------------------- 
  function Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, key)
      local val = GetMediaTrackInfo_Value( src_tr,key )
      SetMediaTrackInfo_Value( dest_tr, key, val )  
  end
  -------------------------------------------------------------------- 
  function Data_ImportTracks_AppStr_ItSub(data, it, item_data, strategy)
    SetItemStateChunk( it, item_data.chunk, false )
    
    for takeidx = 1,  #item_data.tk_data do
      local take =  GetTake( it, takeidx-1 )
      if not TakeIsMIDI( take ) then
        local fn = item_data.tk_data[takeidx].filename
        
        if not fn:match('[%/%\\]') and strategy.tritems&4==4 then -- relink files to full paths
          fn = data.rppsession_path..'/'..fn 
          local  pcmsrc = PCM_Source_CreateFromFile( fn )
          if pcmsrc then SetMediaItemTake_Source( take, pcmsrc ) end
          --PCM_Source_Destroy( pcmsrc )
        end
        
        --[[if strategy.tritems&16==16 then -- copy sources to path
          local path_pr = GetParentFolder(data.cur_project) 
          local dest_path = path_pr..'/'..conf.sourceimportpath
          
        end]]
        
      end      
    end
    
  end
  -------------------------------------------------------------------- 
  function Data_ImportTracks_AppStr_It(data, src_tr, dest_tr, strategy)
    local item_data = {}
    for itemidx = 1,  CountTrackMediaItems( src_tr ) do
      local item = GetTrackMediaItem( src_tr, itemidx-1 )
      local retval, chunk = reaper.GetItemStateChunk( item, '', false )
      
      local tk_data = {}
      for takeidx = 1,  CountTakes( item ) do
        local take =  GetTake( item, takeidx-1 )
        --if not TakeIsMIDI( take ) then
        local source=  GetMediaItemTake_Source( take )
        local filename = reaper.GetMediaSourceFileName( source, '' )
        tk_data[takeidx] = {filename = filename}
        --end
      end
      item_data[#item_data+1] = {chunk=chunk, tk_data = tk_data}
    end
    
    if strategy.tritems&2==2 then -- remove dest tr items
      for itemidx = CountTrackMediaItems( dest_tr ), 1, -1 do 
        local item = GetTrackMediaItem( dest_tr, itemidx-1 )
        DeleteTrackMediaItem(  dest_tr, item) 
      end
    end
    
    for itemidx = 1,  #item_data do
      local it = AddMediaItemToTrack( dest_tr )
      Data_ImportTracks_AppStr_ItSub(data, it, item_data[itemidx], strategy)
    end   
    
  end
  -------------------------------------------------------------------- 
  function Data_ImportTracks_AppStr(conf, obj, data, refresh, mouse, strategy, src_tr, dest_tr)
    -- complete
    if strategy.comchunk == 1 then
      -- get stuff from track
      local retval, outchunk = reaper.GetTrackStateChunk( src_tr, '', false )
      -- set needed stuff
      SetTrackStateChunk( dest_tr, outchunk, false )
      return
    end
    
    -- track chain
    if strategy.fxchain&1 == 1 then
      local dest_cnt = TrackFX_GetCount( dest_tr )
      if strategy.fxchain&2 == 0 then  for dest_fx = dest_cnt, 1, -1 do  TrackFX_Delete( dest_tr, dest_fx-1 ) end end
      for src_fx = 1, TrackFX_GetCount( src_tr ) do TrackFX_CopyToTrack( src_tr, src_fx-1, dest_tr, dest_cnt + src_fx, false ) end
    end

    -- track properties
    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&2 == 2) then
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'D_VOL')
    end    
    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&4 == 4) then
      --if ValidatePtr2( 0, src_tr, 'MediaTrack*' ) and ValidatePtr2( 0, dest_tr, 'MediaTrack*' ) then msg(1) end
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'D_PAN')
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'D_WIDTH')
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'D_DUALPANL')
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'D_DUALPANR')
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'I_PANMODE')
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'D_PANLAW')
    end  
    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&8 == 8) then 
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'B_PHASE')   
    end  
    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&16 == 16) then  
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'I_RECINPUT')
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'I_RECMODE') 
    end 
    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&32 == 32) then    
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'I_RECMON')
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'I_RECMONITEMS')
    end 
    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&64 == 64) then    
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'B_MAINSEND')
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'C_MAINSEND_OFFS')
    end     
    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&128 == 128) then  
      Data_ImportTracks_AppStr_SetTrVal(src_tr, dest_tr, 'I_CUSTOMCOLOR')
    end     
     
    -- tr items
    if strategy.tritems&1 == 1 then    
      Data_ImportTracks_AppStr_It(data, src_tr, dest_tr, strategy)
    end    
       
  end
  
  --------------------------------------------------------------------  
  function Data_Import(conf, obj, data, refresh, mouse, strategy)   
    if  strategy.comchunk&1==0 
        and strategy.tritems&1==1 
        and strategy.tritems&16==16 
        and data.cur_project == '' 
        then MB( 'Importing source data to project with no folder is not allowed', conf.mb_title, 0) return 
      else
        Data_ImportMasterStuff(conf, obj, data, refresh, mouse, strategy)
        Data_ImportTracks(conf, obj, data, refresh, mouse, strategy)
    end
  end
