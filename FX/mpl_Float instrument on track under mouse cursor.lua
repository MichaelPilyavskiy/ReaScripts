-- @description Float instrument on track under mouse cursor
-- @version 1.07
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

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
  -------------------------------------------------------------------------------     
  function FloatInstrument(track, toggle)
    local vsti_id = TrackFX_GetInstrument(track)
    if vsti_id and vsti_id >= 0 then 
      if not toggle then 
        TrackFX_Show(track, vsti_id, 3) -- float
       else
        local is_float = TrackFX_GetOpen(track, vsti_id)
        if is_float == false then TrackFX_Show(track, vsti_id, 3) else TrackFX_Show(track, vsti_id, 2) end
      end 
      return true
    end
  end
  ---------------------------------------------------
  function VF_GetTrackUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local retval, info = reaper.GetTrackFromPoint( screen_x, screen_y )
    return retval
  end
  ---------------------------------------------------------------------
  function ApplyFunctionToTrackInTree(track, func) -- function return true stop search
    -- search tree
      local parent_track, ret2, ret3
      local track2 = track
      repeat
        parent_track = reaper.GetParentTrack(track2)
        if parent_track ~= nil then
          ret2 = func(parent_track )
          if ret2 then return end
          track2 = parent_track
        end
      until parent_track == nil    
      
    -- search sends
      local cnt_sends = GetTrackNumSends( track, 0)
      for sendidx = 1,  cnt_sends do
        dest_tr = BR_GetMediaTrackSendInfo_Track( track, 0, sendidx-1, 1 )
        ret3 = func(dest_tr )
        if ret3 then return  end
      end
  end
  ---------------------------------------------------
  local scr_title = 'Float instrument on track under mouse cursor'
  function main() 
    local tr = VF_GetTrackUnderMouseCursor()
    if tr then
      FloatInstrument(tr)
      ApplyFunctionToTrackInTree(tr, FloatInstrument)
    end
  end  
  ---------------------------------------------------
  if VF_CheckReaperVrs(5.981,true) then main()end