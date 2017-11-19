-- @description Add channel strip controls to selected tracks
-- @about
--    Adds ReaEQ, ReaComp and JS Delay to the end of FX chain and also put some controls to TCP/MCP
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

  local scr_title = 'Add channel strip controls to selected tracks'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  --NOT gfx NOT reaper
  
  ---------------------------------------------------
  function eugen27771_GetTrackStateChunk(track)
    if not track then return end
    local fast_str, track_chunk
    fast_str = SNM_CreateFastString("")
    if SNM_GetSetObjectState(track, fast_str, false, false) then track_chunk = SNM_GetFastString(fast_str) end
    SNM_DeleteFastString(fast_str)  
    return track_chunk
  end 
  ---------------------------------------------------
  function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  ---------------------------------------------------
  function literalize(str) -- http://stackoverflow.com/questions/1745448/lua-plain-string-gsub
     if str then  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end) end
  end
  -----------------------------------------------------------------------
  function SetFXName(track, fx, new_name)
    if not new_name then return end
    local edited_line,edited_line_id, segm
    -- get ref guid
      if not track or not tonumber(fx) then return end
      local FX_GUID = TrackFX_GetFXGUID( track, fx )
      if not FX_GUID then return else FX_GUID = FX_GUID:gsub('-',''):sub(2,-2) end
      local plug_type = TrackFX_GetIOSize( track, fx )
    -- get chunk t
      local chunk = eugen27771_GetTrackStateChunk(track)--reaper.GetTrackStateChunk( track, '', false )
      local t = {} for line in chunk:gmatch("[^\r\n]+") do t[#t+1] = line end
    -- find edit line
      local search
      for i = #t, 1, -1 do
        local t_check = t[i]:gsub('-','')
        if t_check:find(FX_GUID) then search = true  end
        if t[i]:find('<') and search and not t[i]:find('JS_SER') then
          edited_line = t[i]:sub(2)
          edited_line_id = i
          break
        end
      end
    -- parse line
      if not edited_line then return end
      local t1 = {}
      for word in edited_line:gmatch('[%S]+') do t1[#t1+1] = word end
      local t2 = {}
      for i = 1, #t1 do
        segm = t1[i]
        if not q then t2[#t2+1] = segm else t2[#t2] = t2[#t2]..' '..segm end
        if segm:find('"') and not segm:find('""') then if not q then q = true else q = nil end end
      end
      
      if not (plug_type == 2 or plug_type == 3) then return end
      if plug_type == 2 then t2[3] = '"'..new_name..'"' end -- if JS
      if plug_type == 3 then t2[5] = '"'..new_name..'"' end -- if VST
  
      local out_line = table.concat(t2,' ')
      t[edited_line_id] = '<'..out_line
      local out_chunk = table.concat(t,'\n')
      SetTrackStateChunk( track, out_chunk, true )
      UpdateArrange()
  end
  ---------------------------------------------------  
  function main(tr)    
  
    -- eq
      local fxId_EQ = TrackFX_AddByName( tr, 'ReaEQ ChanStrip', false, 0 )
      if fxId_EQ < 0 then
        fxId_EQ  = TrackFX_AddByName( tr, 'ReaEQ', false, -1 )
        SetFXName(tr, fxId_EQ, 'ReaEQ ChanStrip')
        TrackFX_SetParamNormalized( tr, fxId_EQ, 1, 0 ) -- ls gain
        TrackFX_SetParamNormalized( tr, fxId_EQ, 10, 0 ) -- hs gain
        SNM_AddTCPFXParm( tr, fxId_EQ, 0 ) -- low shelf
        SNM_AddTCPFXParm( tr, fxId_EQ, 9 ) -- high shelf
      end 
         
    -- reacomp
      fxId_ReaComp = TrackFX_AddByName( tr, 'ReaComp ChanStrip', false, 0 )
      if fxId_ReaComp < 0 then
        fxId_ReaComp  = TrackFX_AddByName( tr, 'ReaComp', false, -1 )
        SetFXName(tr, fxId_ReaComp, 'ReaComp ChanStrip')
        SNM_AddTCPFXParm( tr, fxId_ReaComp, 0 ) -- thresh
        SNM_AddTCPFXParm( tr, fxId_ReaComp, 1 ) -- ratio
        --SNM_AddTCPFXParm( tr, fxId_ReaComp, 2 ) -- release
        SNM_AddTCPFXParm( tr, fxId_ReaComp, 3 ) -- release
      end
      
    -- delay
      local fxId_del = TrackFX_AddByName( tr, 'Delay ChanStrip', false, 0 )
      if fxId_del < 0 then
        fxId_del  = TrackFX_AddByName( tr, 'time_adjustment', false, -1 )
        SetFXName(tr, fxId_del, 'Delay ChanStrip')
        SNM_AddTCPFXParm( tr, fxId_del, 0 ) -- low shelf
      end           
  end
  ---------------------------------------------------
  Undo_BeginBlock()
  for i = 1, CountSelectedTracks(0) do
    tr = GetSelectedTrack(0,i-1)
    main(tr)
  end
  Undo_EndBlock(scr_title, 1)