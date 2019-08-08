-- @description Copy selection area of take under mouse cursor to new track
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # update for use with REAPER 5.981+


function main()
  reaper.PreventUIRefresh(1)
  local startOut, endOut = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  if startOut ~= nil and endOut ~= nil then
    local item,take = VF_GetItemTakeUnderMouseCursor()
    if item and take then
      reaper.Main_OnCommand(40289, 0) -- unselect all items
      reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
      takenum = reaper.GetMediaItemTakeInfo_Value(take,"IP_TAKENUMBER")
      itempos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") 
      itemlen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") 
      if  itempos >= startOut and itempos < endOut 
        or startOut >= itempos and startOut < itempos+itemlen-- and endOut <= itempos+itemlen 
       then
        reaper.ApplyNudge(0, 2, 5, 0, 1, false, 1)  
        track = reaper.GetMediaItemTake_Track(take)
        tracknum = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        reaper.InsertTrackAtIndex(tracknum, false)
        dest_track = reaper.GetTrack(0, tracknum)
        reaper.TrackList_AdjustWindows(false)
        reaper.MoveMediaItemToTrack(item, dest_track)
        reaper.SetActiveTake(take)
        reaper.Main_OnCommand(40131, 0) -- crop to active take    
        reaper.SetMediaItemInfo_Value(item, "D_POSITION",itempos)
        reaper.BR_SetItemEdges(item, startOut, endOut)   
      end   
    end
  end  
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end


---------------------------------------------------------------------
  function CheckFunctions(str_func) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua' local f = io.open(SEfunc_path, 'r')  if f then f:close() dofile(SEfunc_path) if not _G[str_func] then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to newer version', '', 0) else return true end  else reaper.MB(SEfunc_path:gsub('%\\', '/')..' missing', '', 0) end   end

--------------------------------------------------------------------  
  local ret = CheckFunctions('VF_GetItemTakeUnderMouseCursor') 
  local ret2 = VF_CheckReaperVrs(5.95,true)    
  if ret and ret2 then 
    script_title = "Copy selection area of take under mouse cursor to new track"
    reaper.Undo_BeginBlock() 
    main()
    reaper.Undo_EndBlock(script_title, 0)
  end 
