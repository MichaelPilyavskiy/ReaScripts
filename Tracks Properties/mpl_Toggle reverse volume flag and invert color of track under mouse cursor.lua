-- @description Toggle reverse volume flag and invert color of track under mouse cursor
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # remove SWS dependency
--    # use native API
--    # correctly handle followed mask
--    # support 64 groups

  
  ----------------------------------------------------------------------
  function main()
    local track = VF_GetTrackUnderMouseCursor()
    if not track then return end
    
     local followmask32 = GetSetTrackGroupMembership( track, 'VOLUME_FOLLOW', 0, 0 )
     local mask32 = GetSetTrackGroupMembership( track, 'VOLUME_REVERSE', 0, 0 )
     GetSetTrackGroupMembership( track, 'VOLUME_REVERSE', 0xFFFFFFFF,mask32~followmask32 )
     local followmask64 = GetSetTrackGroupMembershipHigh( track, 'VOLUME_FOLLOW', 0, 0 )
     local mask64 = GetSetTrackGroupMembershipHigh( track, 'VOLUME_REVERSE', 0, 0 )
     GetSetTrackGroupMembershipHigh( track, 'VOLUME_REVERSE', 0xFFFFFFFF,mask64~followmask64 )
     
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
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.60) if ret then local ret2 = VF_CheckReaperVrs(6.78,true) if ret2 then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, 'Toggle reverse volume flag and invert color of track under mouse cursor', 0xFFFFFFFF )
  end end    