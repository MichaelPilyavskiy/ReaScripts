-- @version 1.01
-- @author MPL
-- @changelog
--   + support parameters copypaste
-- @description Paste Focused FX data
-- @website http://forum.cockos.com/member.php?u=70694

function TrackFX_GetState(track, fx_id, buffer)
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
       
    local cnt_input_fx = reaper.TrackFX_GetCount( track ) 
        
    if fx_id -1 >= cnt_input_fx then return end
    local FX_state = table.concat(chunk_t, '\n', 
      fx_chunks_limits[fx_id][1]+1,
      fx_chunks_limits[fx_id][2]) 
    
    local Clear_FX_state = FX_state:match('[^>]+.')
    local Repl_FX_state = buffer:gsub('==FXDATA==',Clear_FX_state)
    
    local chunk_out = table.concat(chunk_t, '\n',1, fx_chunks_limits[fx_id][1]-1)
    chunk_out = chunk_out..'\n'..Repl_FX_state..'\n'
    chunk_out = chunk_out..table.concat(chunk_t, '\n',fx_chunks_limits[fx_id][2]+1)
    --reaper.ShowConsoleMsg(chunk_out)
    return chunk_out
  end
  ----------------------------------------------------------------------------
  function ApplyParams(track, fx, param_str) 
    local t = {}
    if param_str then
      for line in param_str:gmatch('[^%s]+') do
        t[#t+1] = tonumber(line)
      end
    end
    cnt = reaper.TrackFX_GetNumParams( track, fx )
    if cnt -1 == #t then
      for i =1 , cnt-1 do
        reaper.TrackFX_SetParam( track,  fx, i-1, t[i] )
      end
     else
      reaper.MB('Parameter count mismatch. Parameters will not be set.', 'Paste FX data', 0)
    end
  end
  ----------------------------------------------------------------------------
  local buffer = reaper.GetExtState( 'MPL_Copy_FX_Data', 'buf') 
  buf_params = reaper.GetExtState( 'MPL_Copy_FX_Data', 'buf_params') 
  local _, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
  if tracknumberOut >= 0 and fxnumberOut >= 0 then
  
    local track = reaper.CSurf_TrackFromID( tracknumberOut, false )  
    local chunk_out = TrackFX_GetState(track,fxnumberOut+1,buffer)
    if chunk_out then 
      --reaper.SetTrackStateChunk( track, chunk_out, true )
      reaper.UpdateArrange()
    end    
    if buf_params then
      ApplyParams(track,fxnumberOut, buf_params)
    end
  end
