-- @description Delete x characters from selected track names
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # rebuild in lua, this will fix non-unicode issues
--    + store last enterd values

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
  function deletecharsfromname()
    local in_st = GetExtState( 'mpl_removexcharfromtrname', 'in_st' ) if in_st == '' then in_st = 0 end
    local in_end = GetExtState( 'mpl_removexcharfromtrname', 'in_end' ) if in_end == '' then in_end = 0 end
    
    local ret, retvals_csv = reaper.GetUserInputs( 'Delete x characters from track names', 2, "symbols from start, symbols from end,separator=;", in_st..';'..in_end )
    if not ret then return end
    in_st, in_end = retvals_csv:match('(%d+);(%d+)')
    
    if in_st then in_st = tonumber(in_st) end
    if in_end then in_end = tonumber(in_end) end
    
    if in_st then SetExtState( 'mpl_removexcharfromtrname', 'in_st', in_st, true ) end
    if in_end then SetExtState( 'mpl_removexcharfromtrname', 'in_end', in_end, true ) end
    
    local trackcount = CountSelectedTracks(-1); 
    for i = 1, trackcount do
      local track = GetSelectedTrack(-1, i-1)
       retval, P_NAME = GetSetMediaTrackInfo_String( track, "P_NAME", '', false )
      if in_st then P_NAME = P_NAME:sub(in_st+1) end
      if in_end then P_NAME = P_NAME:sub(0,-in_end-1) end
      GetSetMediaTrackInfo_String( track, "P_NAME", P_NAME, true )
    end
  
    TrackList_AdjustWindows(0);
    UpdateArrange()
  end
--------------------------------------------------------------------  
  if VF_CheckReaperVrs(7.31,true) then 
    reaper.Undo_BeginBlock() 
    deletecharsfromname()
    reaper.Undo_EndBlock("Delete x characters from selected track names", 0xFFFFFFFF) 
  end   