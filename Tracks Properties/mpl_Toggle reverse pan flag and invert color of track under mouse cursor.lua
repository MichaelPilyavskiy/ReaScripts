-- @description Toggle reverse pan flag and invert color of track under mouse cursor
-- @version 1.03
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
  ---------------------------------------------------
  function VF_GetTrackUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local retval, info = reaper.GetTrackFromPoint( screen_x, screen_y )
    return retval
  end
  ----------------------------------------------------------------------
  function main()
    local track = VF_GetTrackUnderMouseCursor()
    if not track then return end
    
     local followmask32 = GetSetTrackGroupMembership( track, 'PAN_FOLLOW', 0, 0 )
     local mask32 = GetSetTrackGroupMembership( track, 'PAN_REVERSE', 0, 0 )
     GetSetTrackGroupMembership( track, 'PAN_REVERSE', 0xFFFFFFFF,mask32~followmask32 )
     local followmask64 = GetSetTrackGroupMembershipHigh( track, 'PAN_FOLLOW', 0, 0 )
     local mask64 = GetSetTrackGroupMembershipHigh( track, 'PAN_REVERSE', 0, 0 )
     GetSetTrackGroupMembershipHigh( track, 'PAN_REVERSE', 0xFFFFFFFF,mask64~followmask64 )
     
    -- invert track color
      local trackcolor = reaper.GetTrackColor(track)
      local R,G,B = reaper.ColorFromNative(trackcolor)
      local is_default_color = false
      if  R== 0 and G== 0 and B== 0 then is_default_color = true end
      -- prevent default color change
      if is_default_color == false then
        local R_inv, G_inv, B_inv = 255 - R, 255 - G, 255- B
        local trackcolor_inv = reaper.ColorToNative(R_inv, G_inv, B_inv)
        reaper.SetTrackColor(track, trackcolor_inv)
      end  
      
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.78,true)  then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Toggle reverse pan flag and invert color of track under mouse cursor', 0xFFFFFFFF )
  end   