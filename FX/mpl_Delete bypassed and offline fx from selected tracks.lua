-- @version 1.0
-- @author mpl
-- @changelog
--   + init release

 --[[
    * ReaScript Name: Delete bypassed and offline fx from selected tracks
    * Lua script for Cockos REAPER
    * Author: Michael Pilyavskiy (mpl)
    * Author URI: http://forum.cockos.com/member.php?u=70694
    * Licence: GPL v3
   ]] 
  
  
  function main()
    local chunk, chunk_opened,is_bypassed,is_offline
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
          
          -- delete chunk if bypass/offline
            for i = 1, #fx_chunks_limits do
              is_bypassed = chunk_t[fx_chunks_limits[i][1]]:sub(8,8)
              is_offline =  chunk_t[fx_chunks_limits[i][1]]:sub(10,10)
              if is_bypassed + is_offline >= 1 then
                for k = fx_chunks_limits[i][1], fx_chunks_limits[i][2] do
                  chunk_t[k] = ''
                end
              end
            end
          
          -- return chunk
            chunk = table.concat(chunk_t,'\n')
            chunk = chunk:gsub('[%\n]+','\n') -- delete empty lines
            --reaper.ShowConsoleMsg("")
            --reaper.ShowConsoleMsg(chunk)
            reaper.SetTrackStateChunk(track, chunk)
            
        end
      end
    end
  end
  
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock('Delete bypassed and offline fx from selected tracks', 0)
