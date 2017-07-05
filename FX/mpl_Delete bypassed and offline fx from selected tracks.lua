-- @version 1.2
-- @author MPL
-- @changelog
--   # recoded for FX deleting via SWS API and smarter offline and bypass checking
-- @description Delete bypassed fx from selected tracks
-- @website http://forum.cockos.com/member.php?u=70694
  
  function RemoveBypassOfflineFX(track)
    if not track then return end
    local _, chunk = reaper.GetTrackStateChunk(track, '')
    local t = {}
    for line in chunk:gmatch('[^\r\n]+') do  table.insert(t, line)  end
    local fx = {}
    local fxGUID
    for i =  #t, 1, -1 do
      if t[i]:match('FXID') then ch_search = true fxGUID = t[i]:match("%{.+%}") end
      if ch_search and t[i]:match('BYPASS') then
        ch_search = nil
        if fxGUID then fx[fxGUID] = tonumber(t[i]:match('%d %d %d'):gsub(' ', ''),2) end
      end
    end    
    for fx_id = reaper.TrackFX_GetCount( track ), 1, -1 do
      local GUID = reaper.TrackFX_GetFXGUID( track, fx_id-1 )
      msg(GUID)
      if fx[GUID] and fx[GUID] > 0 then reaper.SNM_MoveOrRemoveTrackFX( track, fx_id-1, 0 ) end
    end
    
  end
  --------------------------------------------------------------------
  reaper.Undo_BeginBlock()
  for i =1, reaper.CountSelectedTracks(0) do 
    local tr = reaper.GetSelectedTrack(0,i-1)
    if tr then RemoveBypassOfflineFX(tr) end
  end
  RemoveBypassOfflineFX()
  reaper.Undo_EndBlock('Delete bypassed fx from selected tracks', 0)