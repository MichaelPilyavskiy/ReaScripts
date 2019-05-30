-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description Explode selected track RS5k instances to new tracks
-- @noindex
-- @changelog
--    #header

  local scr_nm = 'Explode selected track RS5k instances to new tracks'
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  function msg(s) ShowConsoleMsg(s) end
  ------------------------------------------------------------------------
  function Extract_rs5k_tChunks(tr)
    local _, chunk = GetTrackStateChunk(tr, '', false)
    local t = {}
    for fx_chunk in chunk:gmatch('BYPASS(.-)WAK') do 
      if fx_chunk:match('<(.*)') and fx_chunk:match('<(.*)'):match('reasamplomatic.dll') then 
        t[#t+1] = 'BYPASS 0 0 0\n<'..fx_chunk:match('<(.*)') ..'WAK 0'
      end
    end
    return t
  end
  ------------------------------------------------------------------------  
  function AddChunkToTrack(tr, chunk)
    local _, chunk_ch = GetTrackStateChunk(tr, '', false)
    -- add fxchain if not exists
    if not chunk_ch:match('FXCHAIN') then 
      chunk_ch = chunk_ch:sub(0,-3)..[=[
<FXCHAIN
SHOW 0
LASTSEL 0
DOCKED 0
>
>]=]
    end
    chunk_ch = chunk_ch:gsub('DOCKED %d', chunk)
    SetTrackStateChunk(tr, chunk_ch, false)
  end
  ------------------------------------------------------------------------  
  function RenameTrAsFirstInstance(track)
    local fx_count =  reaper.TrackFX_GetCount(track)
    if fx_count >= 1 then
      local retval, fx_name =  reaper.TrackFX_GetFXName(track, 0, '')      
      local fx_name_cut = fx_name:match(': (.*)')
      if fx_name_cut then fx_name = fx_name_cut end
      reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', fx_name, true)
    end
  end
  ------------------------------------------------------------------------
  tr = GetSelectedTrack(0,0)
  if tr then 
    tr_id = CSurf_TrackToID( tr,false )
    Undo_BeginBlock2( 0 )
    ch = Extract_rs5k_tChunks(tr)
    if ch and #ch > 0 then 
      for i = #ch, 1, -1 do 
        InsertTrackAtIndex( tr_id, false )
        local child_tr = GetTrack(0,tr_id)
        AddChunkToTrack(child_tr, ch[i])
        RenameTrAsFirstInstance(child_tr)
      end
    end
    reaper.Undo_EndBlock2( 0, scr_nm, 0 )
  end