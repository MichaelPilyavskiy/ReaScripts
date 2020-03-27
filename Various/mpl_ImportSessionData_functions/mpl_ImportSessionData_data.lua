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
    local retval, filenameNeed4096 = reaper.GetUserFileNameForRead('', 'Import RPP session data', '.RPP' )
    if retval then conf.lastrppsession = filenameNeed4096 end
    refresh.conf = true
    refresh.GUI = true
  end

  --------------------------------------------------- 
  function Data_ParseRPP(conf, obj, data, refresh, mouse)  
    data.hasRPPdata = false
    local f = io.open(conf.lastrppsession, 'rb')
    if not f then return end
    local content = f:read('a')
    f:close()
    local t = {} for line in content:gmatch('[^\r\n]+') do t[#t+1] = line end
    
    local tr_chunks = {}
    local tr_id = 0
    local bracketslevel = 0
    for i = 1, #t do 
      local line = t[i]
      if line:match('<TRACK') then 
        if tr_chunks[tr_id-1] then 
          local s = table.concat(tr_chunks[tr_id-1], '\n') 
          tr_chunks[tr_id-1] = s
        end
        bracketslevel = bracketslevel + 1 
        tr_id = tr_id + 1
      end
      
      if bracketslevel >0 then
        if line:match('>') and not line:match('%b<>') then bracketslevel = bracketslevel - 1 end
      end
      if bracketslevel >0 then
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
        
    data.tr_chunks = {}    
    -- parse chunks
    for i = 1, #tr_chunks do 
      local ch_str = tr_chunks[i]
      if type(ch_str) == 'string' then
        local tr_name = Data_ParseRPP_GetParam(ch_str, 'NAME', 300)
        local tr_col = Data_ParseRPP_GetParam(ch_str, 'PEAKCOL')
        if tr_col == 16576 then tr_col = nil end
        data.tr_chunks[i] = {chunk = ch_str,
                              tr_name = tr_name,
                              tr_col=tr_col,
                              dest = ''} 
      end
    end
    
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
  function Data_Import(conf, obj, data, refresh, mouse, strategy) 
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
          PreventUIRefresh( 1 )
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
          PreventUIRefresh( -1 )
        end
      end       
    end
  end
  --------------------------------------------------------------------  
  function Data_ParseRPP_GetParam(ch_str, key, find_until)
    if not find_until then find_until = ch_str:len() end
    local val = ch_str:sub(0,find_until):match(key..' %"(.-)%"')
    if not val then val = ch_str:sub(0,find_until):match(key..'%s([%a%p%d]+)\n') end
    if not val and ch_str:sub(0,find_until):match(key..' ""') then val = '' end
    if not val then val = '' end
    if tonumber(val) then val = tonumber(val) end
    return val
  end
  --------------------------------------------------------------------  
  function Data_CollectProjectTracks(conf, obj, data, refresh, mouse)
    local  retval, projfn = EnumProjects( -1 )
    projfn = GetShortSmplName(projfn)
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
  function Data_ImportAppStrategy(conf, obj, data, refresh, mouse, strategy, src_tr, dest_tr)
    -- complete
    if strategy.comchunk == 1 then
      -- get stuff from track
      local retval, outchunk = reaper.GetTrackStateChunk( src_tr, '', false )
      -- set needed stuff
      SetTrackStateChunk( dest_tr, outchunk, false )
      return
    end
    
    if strategy.fxchain&1 == 1 then
      local dest_cnt = TrackFX_GetCount( dest_tr )
      for src_fx = 1, TrackFX_GetCount( src_tr ) do
        TrackFX_CopyToTrack( src_tr, src_fx-1, dest_tr, dest_cnt + src_fx, false )
      end
    end

    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&2 == 2) then
      local val = GetMediaTrackInfo_Value( src_tr, 'D_VOL' )
      SetMediaTrackInfo_Value( dest_tr, 'D_VOL', val )
    end    
    if strategy.trparams&1 == 1 or (strategy.trparams&1 == 0 and strategy.trparams&4 == 4) then
      local val = GetMediaTrackInfo_Value( src_tr, 'D_PAN' )
      SetMediaTrackInfo_Value( dest_tr, 'D_PAN', val )
      local val = GetMediaTrackInfo_Value( src_tr, 'D_WIDTH' )
      SetMediaTrackInfo_Value( dest_tr, 'D_WIDTH', val )
      local val = GetMediaTrackInfo_Value( src_tr, 'D_DUALPANL' )
      SetMediaTrackInfo_Value( dest_tr, 'D_DUALPANL', val )
      local val = GetMediaTrackInfo_Value( src_tr, 'D_DUALPANR' )
      SetMediaTrackInfo_Value( dest_tr, 'D_DUALPANR', val )
      local val = GetMediaTrackInfo_Value( src_tr, 'I_PANMODE' )
      SetMediaTrackInfo_Value( dest_tr, 'I_PANMODE', val )
      local val = GetMediaTrackInfo_Value( src_tr, 'D_PANLAW' )
      SetMediaTrackInfo_Value( dest_tr, 'D_PANLAW', val )      
    end     
    
  end
