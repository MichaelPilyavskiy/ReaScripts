-- @version 1.0
-- @author mpl
-- @changelog
--   + init
-- @description Copy Focused FX data
-- @website http://forum.cockos.com/member.php?u=70694

  function TrackFX_GetState(track, fx_id, on)
    -- fx_id 1-based
    local chunk,chunk_opened      
    -- chain table
      _, chunk = reaper.GetTrackStateChunk(track, '')
      local chunk_t = {}
      for line in chunk:gmatch("[^\n]+") do  table.insert(chunk_t, line)  end      
    -- extract fx chunks limits
      local fx_chunks_limits = {}
      for i = 1, #chunk_t do
        if chunk_t[i]:find('BYPASS') ~= nil then
          chunk_opened = true
          table.insert(fx_chunks_limits, {i})
        end
        if chunk_t[i]:find('WAK') ~= nil and chunk_opened then
          chunk_opened = false
          fx_chunks_limits[#fx_chunks_limits][2]=i
        end            
      end        
      
    cnt_input_fx = reaper.TrackFX_GetCount( track ) 
        
    if fx_id -1 >= cnt_input_fx then return end
    FX_state = table.concat(chunk_t, '\n', 
      fx_chunks_limits[fx_id][1],
      fx_chunks_limits[fx_id][2])    
    local temp_s = ''
    
    local temp_t = {}
    for line in FX_state:gmatch("[^\r\n]+") do
      if not already_skipped and line:find('<') then 
        skip = true
        already_skipped = true
       elseif line:find('>') then 
        skip = false 
      end
      if not skip then temp_t[#temp_t+1] =line end
    end
    temp_t[2] = '==FXDATA=='
    return table.concat(temp_t, '\n')
  end
  
  ----------------------------------------------------------------------------
  _, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
  if tracknumberOut >= 0 and fxnumberOut >= 0 then
    _, tracknumberOut, fxnumberOut = reaper.GetLastTouchedFX()
    track = reaper.CSurf_TrackFromID( tracknumberOut, false )
    temp_s = TrackFX_GetState(track,fxnumberOut+1)
    reaper.ShowConsoleMsg(temp_s)
    reaper.SetExtState( 'MPL_Copy_FX_Data', 'buf', temp_s, false )
  end
