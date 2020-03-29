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
      if data.cur_tracks[i].GUID == guid_check then return true, data.cur_tracks[i].tr_name,  data.cur_tracks[i].tr_col end
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
  function Data_ParseRPP_ExtractChunks2(tr_chunks, t)
    local tr_id = 0
    local bracketslevel = 0
    for i = 1, #t do 
      local line = t[i]
      if    line:match('<TRACK') 
        or  line:match('<MASTERFXLIST') 
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
  end 
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
      --msg(line)
      if line:match(key) then 
        local ts = {}
        local tid = 1
        local openpar = false
        for char in line:gmatch('.') do 
          if char:match('%s+') and openpar == false then tid = #ts + 1 char = ''
            elseif char:match('%"+') and openpar == false then openpar = true char = ''
            elseif char:match('%"+') and openpar == true then openpar = false char = ''
          end
           
          if not ts[tid] then ts[tid] = '' end
          ts[tid] = ts[tid]..char
        end
        
        for i = 1, #ts do 
          local val = ts[i]:gsub('"','')
          if tonumber(val) then val = tonumber(val) end 
          ts[i] = val 
        end
        mult_t[#mult_t+1] = ts
        
      end
    end
    return mult_t 
  end
  --------------------------------------------------- 
  function Data_ParseRPP(conf, obj, data, refresh, mouse)  
    data.hasRPPdata = false
    local f = io.open(conf.lastrppsession, 'rb')
    if not f then return end
    local content = f:read('a')
    f:close()
    local t = {} for line in content:gmatch('[^\r\n]+') do t[#t+1] = line end
    
    --
    
    local tr_chunks = {}
    local t_trackstart = Data_ParseRPP_ExtractChunks(tr_chunks, t) 
    if t_trackstart then 
      --msg(project_header_chunk)
      --data.PROJOFFS = Data_ParseRPP_GetGlobalParamDec(project_header_chunk, 'PROJOFFS', 1)
      data.MARKER = Data_ParseRPP_GetGlobalParam(t, t_trackstart, 'MARKER', 1)
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
      end
    end
    
    --for 
    data.hasRPPdata = true
    refresh.GUI = true
  end
  
  
  --[[tr_chunks = {}
  tr_id = 0
  local bracketslevel = 0
  for i = 1, #t do 
    if t[i]:match('<TRACK') then 
      if tr_chunks[tr_id-1] and type(tr_chunks[tr_id-1]) == 'table' then tr_chunks[tr_id-1] = table.concat(tr_chunks[tr_id-1], '\n') end 
      track_open = true
      tr_id = tr_id + 1 
      tr_chunks[tr_id] = {}
      tr_chunks[tr_id] [#tr_chunks[tr_id] + 1] = t[i]
     elseif tr_id >= 1 and t[i]:match('>') and not t[i]:match('<') and track_open == true then
      tr_chunks[tr_id] [#tr_chunks[tr_id] + 1] = t[i]
      tr_chunks[tr_id] = table.concat(tr_chunks[tr_id], '\n') 
      track_open = false
     elseif track_open == true then
      tr_chunks[tr_id] [#tr_chunks[tr_id] + 1] = t[i]
    end
  end]]
  --------------------------------------------------------------------  
  function Data_ImportMasterFX(conf, obj, data, refresh, mouse, strategy)
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
  function Data_Import(conf, obj, data, refresh, mouse, strategy) 
    Data_ImportMasterStuff(conf, obj, data, refresh, mouse, strategy)  
    for i = 1, #data.tr_chunks do
      if data.tr_chunks[i].dest == -1 then  -- end of track list
        InsertTrackAtIndex( CountTracks( 0 ), false )
        local new_tr = GetTrack(0, CountTracks( 0 )-1)
        SetTrackStateChunk( new_tr, data.tr_chunks[i].chunk, false )
      end 
      
      if type(data.tr_chunks[i].dest) == 'string' and data.tr_chunks[i].dest ~= '' then  -- to specific track
        local dest_tr = VF_GetTrackByGUID(data.tr_chunks[i].dest)
        if dest_tr then 
          local tr_id = CSurf_TrackToID( dest_tr, false )
          -- add new track
          --local tr_id = CountTracks( 0 )
          InsertTrackAtIndex( tr_id, false )
          local new_tr = GetTrack(0, tr_id)
          -- set chunk
          SetTrackStateChunk( new_tr, data.tr_chunks[i].chunk, false ) 
          Data_ImportAppStrategy(conf, obj, data, refresh, mouse, strategy, new_tr, dest_tr) 
          -- remove track
          DeleteTrack( new_tr )
          --reaper.SetTrackColor( new_tr, 0 )
        end
      end       
    end
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
    ch_str = ch_str:match(key..' (.-)\n')
    --[[if not ch_str then return end
    local val_t = {}
    for val in ch_str:gmatch('[^%s]+') do val_t[#val_t+1]=val end]]
    return ch_str--val_t
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
    local projfn = GetShortSmplName(projfn)
    data.cur_project = projfn 
    data.cur_tracks = {}
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      local GUID = GetTrackGUID( tr )
      local tr_col =  GetTrackColor( tr )
      data.cur_tracks[i] = {tr_name =  ({GetTrackName( tr )})[2],
                            GUID = GUID,
                            tr_col=tr_col}
    end
  end
  -------------------------------------------------------------------- 
  function Data_ClearDest(conf, obj, data, refresh, mouse, strategy) 
    for i = 1, #data.tr_chunks do data.tr_chunks[i].dest = '' end 
    for i = 1, #data.cur_tracks do data.cur_tracks[i].used =  nil end 
  end  
  -------------------------------------------------------------------- 
  function Data_MatchDest(conf, obj, data, refresh, mouse, strategy, is_new, specificid) 
    if not data.tr_chunks then return end
    if not specificid then 
      for i = 1, #data.tr_chunks do data.tr_chunks[i].dest = Data_MatchDestSub(conf, obj, data, refresh, mouse, strategy, data.tr_chunks[i].tr_name, is_new, i) end 
     else 
      data.tr_chunks[specificid].dest = Data_MatchDestSub(conf, obj, data, refresh, mouse, strategy, data.tr_chunks[specificid].tr_name, is_new, specificid)
    end
  end
  -------------------------------------------------------------------- 
  function Data_MatchDestSub(conf, obj, data, refresh, mouse, strategy, tr_name, is_new, id_src) 
    if not tr_name then return '' end
    if tr_name == '' then return '' end
    tr_name = tostring(tr_name)
    if tr_name:match('Track %d+') then return '' end
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
  function Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, key)
      local val = GetMediaTrackInfo_Value( src_tr,key )
      SetMediaTrackInfo_Value( dest_tr, key, val )  
  end
  -------------------------------------------------------------------- 
  function Data_ImportAppStrategy_ImportItems(src_tr, dest_tr, strategy)
    local chunks = {}
    for itemidx = 1,  CountTrackMediaItems( src_tr ) do
      local item = GetTrackMediaItem( src_tr, itemidx-1 )
      local retval, chunk = reaper.GetItemStateChunk( item, '', false )
      chunks[#chunks+1] = chunk
    end
    
    if strategy.tritems&2==2 then -- remove dest tr items
      for itemidx = CountTrackMediaItems( dest_tr ), 1, -1 do 
        local item = GetTrackMediaItem( dest_tr, itemidx-1 )
        DeleteTrackMediaItem(  dest_tr, item) 
      end
    end
    
    for itemidx = 1,  #chunks do
      local it = AddMediaItemToTrack( dest_tr )
      SetItemStateChunk( it, chunks[itemidx], false )
    end    
    
  end
  -------------------------------------------------------------------- 
  function Data_ImportAppStrategy(conf, obj, data, refresh, mouse, strategy, src_tr, dest_tr)
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
      Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, 'D_VOL')
    end    
    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&4 == 4) then
      Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, 'D_PAN')
      Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, 'D_WIDTH')
      Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, 'D_DUALPANL')
      Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, 'D_DUALPANR')
      Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, 'I_PANMODE')
      Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, 'D_PANLAW')
    end  
    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&8 == 8) then 
      Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, 'B_PHASE')   
    end  
    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&16 == 16) then  
      Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, 'I_RECINPUT')
      Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, 'I_RECMODE') 
    end 
    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&32 == 32) then    
      Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, 'I_RECMON')
      Data_ImportAppStrategy_SetTrackVal(src_tr, dest_tr, 'I_RECMONITEMS')
    end 
  
    -- tr items
    if strategy.tritems&1 == 1 then    
      Data_ImportAppStrategy_ImportItems(src_tr, dest_tr, strategy)
    end     
    
       
  end
  
