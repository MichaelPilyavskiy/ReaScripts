-- @description Rename selected tracks as first FX
-- @version 1.1
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # reduce FX name if possible
--    # use first instrument name if any
  
  script_title = "Rename selected tracks as first FX"
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function MPL_ReduceFXname(s)
    local s_out = s:match('[%:%/%s]+(.*)')
    if not s_out then return s end
    s_out = s_out:gsub('%(.-%)','') 
    if s_out:match('%/(.*)') then s_out = s_out:match('%/(.*)') end
    if not s_out then 
      return s 
     else 
      return s_out 
    end
  end
  ---------------------------------------------------  
  function RenameAsFX(track)
    local instr = TrackFX_GetInstrument( track )
    if instr >=0 then 
      local _, fx_name = TrackFX_GetFXName(track, instr, '')            
      GetSetMediaTrackInfo_String(track, 'P_NAME', MPL_ReduceFXname(fx_name), true)
      return
    end
    local _, fx_name = TrackFX_GetFXName(track, 0, '')            
    GetSetMediaTrackInfo_String(track, 'P_NAME', MPL_ReduceFXname(fx_name), true)
    
  end
  
  Undo_BeginBlock()
  for i = 1, CountSelectedTracks(0) do RenameAsFX(GetSelectedTrack(0,i-1)) end
  Undo_EndBlock(script_title, 0)
