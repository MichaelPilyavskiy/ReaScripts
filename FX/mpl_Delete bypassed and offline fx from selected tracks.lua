-- @version 1.1
-- @author MPL
-- @changelog
--   # prevent deleting bypassed fx with bypass envelope
-- @description Delete bypassed fx from selected tracks
-- @website http://forum.cockos.com/member.php?u=70694
  
  function main()
    local chunk, chunk_opened--,is_bypassed,is_offline
    local counttracks = reaper.CountSelectedTracks(0)
    if counttracks ~= nil then
      for tr_id = 1, counttracks do
        local track = reaper.GetSelectedTrack(0,tr_id-1)
        if track ~= nil then
          _, chunk = reaper.GetTrackStateChunk(track, '')
          
          local chunk_t = {}
          -- chain table
            for line in chunk:gmatch("[^\n]+") do  table.insert(chunk_t, line)  end
            
          -- extract fx chunks limits
            fx_chunks = {}
            local fx_ch_op
            for i = 1, #chunk_t do
              if chunk_t[i]:find('<FXCHAIN') then fx_ch_op = true end
              if chunk_t[i]:find('<FXCHAIN_REC') then fx_ch_op = false end
              if fx_ch_op then
                if chunk_t[i]:find('BYPASS') ~= nil then
                  chunk_opened = true
                  fx_chunks[#fx_chunks+1] = {str='',lim1 = i}
                end
                if chunk_opened then fx_chunks[#fx_chunks].str = fx_chunks[#fx_chunks].str..'\n'..chunk_t[i] end
                if chunk_t[i]:find('WAK') ~= nil and chunk_opened then 
                  chunk_opened = false 
                  fx_chunks[#fx_chunks].lim2 = i
                end
              end
            end
            
          -- add/edit chunks
            if #fx_chunks > 0 then
              -- loop chunks
                out_chunk = table.concat(chunk_t, '\n', 1, fx_chunks[1].lim1-1)
                
                for fx = 1, #fx_chunks do
                  local fx_chunk = table.concat(chunk_t, '\n', fx_chunks[fx].lim1, fx_chunks[fx].lim2)
                  is_bypassed = tonumber(chunk_t[fx_chunks[fx].lim1 ]:sub(8,8))
                  bypass_env = fx_chunk:match('<PARMENV '..'[%d]+'..':bypass')
                  if is_bypassed ~= 1 or bypass_env then 
                    out_chunk = out_chunk..'\n'..table.concat(chunk_t, '\n', fx_chunks[fx].lim1, fx_chunks[fx].lim2)
                  end
                  --is_offline =  chunk_t[fx_chunks_limits[i][1] ]:sub(10,10)
                end
                
                out_chunk = out_chunk..'\n'..table.concat(chunk_t, '\n', fx_chunks[#fx_chunks].lim2+1)
                --reaper.ShowConsoleMsg("")
                --reaper.ShowConsoleMsg(out_chunk)
                reaper.SetTrackStateChunk(track, out_chunk)
            end
            
        end
      end
    end
  end
  
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock('Delete bypassed fx from selected tracks', 0)