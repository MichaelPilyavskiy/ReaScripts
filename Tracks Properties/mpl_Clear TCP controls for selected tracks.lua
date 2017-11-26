-- @description Clear TCP controls for selected tracks
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init port from mpl_LearnManager

  for key in pairs(reaper) do _G[key]=reaper[key]  end
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
  function ClearTCP(track, return_existed_only)
    if not track then return end
        local tr_chunk = eugen27771_GetTrackStateChunk( track )
        local t_ret = ''
        local t = {} for line in tr_chunk:gmatch('[^\r\n]+') do t[#t+1] = line  end
        for i = 1, #t do
          if t[i]:match('PARM_TCP') then 
            t[i] = '\n' 
          end
        end
        local out_chunk = table.concat(t, '\n'):gsub('(\n\n)', '')
        SetTrackStateChunk( track, out_chunk, true )
  end
  
  Undo_BeginBlock2( 0 )
  for i =1 , CountSelectedTracks(0) do
    track = GetSelectedTrack(0,i-1)
    ClearTCP(track)
  end
  reaper.Undo_EndBlock2( 0, 'Clear TCP controls for selected tracks', 0 )