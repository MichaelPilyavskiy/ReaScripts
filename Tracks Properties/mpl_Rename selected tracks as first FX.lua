-- @description Rename selected tracks as first FX
-- @version 1.03
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent
--    # do not rename if new name is clear

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  
---------------------------------------------------------------------
  function RenameAsFX(track)
    local instr = TrackFX_GetInstrument( track )
    if instr >=0 then 
      local _, fx_name = TrackFX_GetFXName(track, instr, '') 
      fx_name = MPL_ReduceFXname(fx_name)
      if fx_name ~= '' then GetSetMediaTrackInfo_String(track, 'P_NAME', fx_name, true) end
      return
    end
    
    local _, fx_name = TrackFX_GetFXName(track, 0, '')     
    fx_name = MPL_ReduceFXname(fx_name)
    if fx_name ~= '' then GetSetMediaTrackInfo_String(track, 'P_NAME', fx_name, true) end
    
  end
  ---------------------------------------------------------------------
  function MPL_ReduceFXname(s)
    local s_out = s:match('[%:%/%s]+(.*)')
    if not s_out then return s end
    s_out = s_out:gsub('%(.-%)','') 
    --if s_out:match('%/(.*)') then s_out = s_out:match('%/(.*)') end
    local pat_js = '.*[%/](.*)'
    if s_out:match(pat_js) then s_out = s_out:match(pat_js) end  
    if not s_out then return s else 
      if s_out ~= '' then return s_out else return s end
    end
  end
--------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.95,true) then
    Undo_BeginBlock()
    for i = 1, CountSelectedTracks(0) do RenameAsFX(GetSelectedTrack(0,i-1)) end
    Undo_EndBlock("Rename selected tracks as first FX", 0)
  end  
