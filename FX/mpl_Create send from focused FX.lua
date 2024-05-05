-- @description Create send from focused FX
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + Select receive track after execution
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_ReduceFXname(s)
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
  ----------------------------------------------------------------------
  function main()
    local retval, trackidx, itemidx, takeidx, fxidx, parm = reaper.GetTouchedOrFocusedFX( 1 )
    if not retval then return end
    if itemidx ~= -1 then return end
    if trackidx <0 then return end 
    
    local tr = GetTrack(0,trackidx) 
    local retval, fxname = TrackFX_GetFXName( tr, fxidx ) 
    
    if fxidx&(1<<24)>0 then return end -- no support for input FX
    if fxidx&(1<<25)>0 then return end -- no support for FX container
    
    local outID = trackidx+1 
    InsertTrackAtIndex( outID, false )
    local dest_track = GetTrack(0,outID)
    CreateTrackSend( tr, dest_track )
    TrackFX_CopyToTrack( tr, fxidx, dest_track, 0, true ) 
    local fxname = VF_ReduceFXname(fxname)
    GetSetMediaTrackInfo_String( dest_track, 'P_NAME', fxname, true ) 
    reaper.SetOnlyTrackSelected( dest_track )
  end
    ----------------------------------------------------------------------
  Undo_BeginBlock2( 0 )
  main()
  Undo_EndBlock2( 0, 'Create send from focused FX', 0xFFFFFFFF )