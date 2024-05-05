-- @description Move selected tracks to the end of receives folder
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
  
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function DefineReceiveFolder()
    local candidatesGUID = {}
    
    -- check for parent + filter by names
    multiple_FX_coincidence = 0
    for i = 1, CountTracks(0) do
      local tr  = GetTrack(0,i-1)
      if  GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' ) == 1 then
        local retval, trname = GetSetMediaTrackInfo_String( tr, 'P_NAME', '', false )
        local retval, trGUID = GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
        trname = trname:lower()
        if trname:match('aux') or trname:match('send') or trname:match('receive') or trname:match('fx') then
          if trname:match('fx') then multiple_FX_coincidence = multiple_FX_coincidence + 1 end
          candidatesGUID[#candidatesGUID+1] = {trGUID=trGUID,trname=trname}
        end
      end
    end
    
    if #candidatesGUID == 0 then MB('Receive folders not found', 'Move selected track to the end of receives folder', 0)return end
    if #candidatesGUID == 1 then return candidatesGUID[1].trGUID end
    
    -- there is one or no "FX" folders - select one NOT contain FX
    if multiple_FX_coincidence <=1 then
      for i = 1, #candidatesGUID do 
        if not candidatesGUID[i].trname:match('fx') then return candidatesGUID[i].trGUID end 
      end
    end
    
    -- there is one or no "FX" folders + both contain "FX" - select one contain 'aux/receive/sends'
    if multiple_FX_coincidence >1 then
      for i = 1, #candidatesGUID do 
        local trname = candidatesGUID[i].trname
        if trname:match('aux') or trname:match('send') or trname:match('receive') then return candidatesGUID[i].trGUID end 
      end
    end
    
    
    MB('Receive folders not found', 'Move selected track to the end of receives folder', 0)
  end
  ---------------------------------------------------
  function main()
    local tr = GetSelectedTrack(0,0)
    if not tr then return end
    
    receive_folderGUID = DefineReceiveFolder()
    if not receive_folderGUID then return end
    
     sel_tracks = {}
    for i = 1, CountSelectedTracks(0) do  
      local tr = GetSelectedTrack(0,i-1)
      sel_tracks[#sel_tracks+1] = GetTrackGUID( tr ) 
    end
    
    for i = 1, #sel_tracks do
      MoveTrackToFolder(sel_tracks[i], receive_folderGUID)
    end
    
    for i = 1, #sel_tracks do
      local src_tr = VF_GetTrackByGUID(sel_tracks[i], 0) 
      SetTrackSelected( src_tr, true )
    end
    
    
    
  end
  --------------------------------------------------
  function VF_GetTrackByGUID(giv_guid, reaproj)
    if not (giv_guid and giv_guid:gsub('%p+','')) then return end
    for i = 1, CountTracks(reaproj or 0) do
      local tr = GetTrack(reaproj or 0,i-1)
      --local GUID = reaper.GetTrackGUID( tr )
      local retval, GUID = reaper.GetSetMediaTrackInfo_String( tr, 'GUID', '', false )
      if GUID:gsub('%p+','') == giv_guid:gsub('%p+','') then return tr end
    end
  end
  ----------------------------------------------------------------------
  function MoveTrackToFolder(srcGUID,folderGUID)
    if not (srcGUID and folderGUID) then return end
    
    local src_tr = VF_GetTrackByGUID(srcGUID, 0)
    local folder_tr = VF_GetTrackByGUID(folderGUID, 0)
    if GetMediaTrackInfo_Value( folder_tr, 'I_FOLDERDEPTH' ) ~= 1 then return end
    
    -- find last track in folder
    local fold_trID = CSurf_TrackToID( folder_tr, false )
    local cnttr = CountTracks(0)
    local level = 0
    for i = fold_trID, cnttr do
      local tr  = GetTrack(0,i-1)
      level = level + GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH' )
      if level == 0 then beforeTrackIdx = i break end
    end
    
    reaper.SetOnlyTrackSelected( src_tr )
    
    if not beforeTrackIdx then return end
    ReorderSelectedTracks( beforeTrackIdx, 0 )
    local pre_src_tr = GetTrack(0,beforeTrackIdx-2)
    SetMediaTrackInfo_Value( pre_src_tr, 'I_FOLDERDEPTH',0 )
    SetMediaTrackInfo_Value( src_tr, 'I_FOLDERDEPTH',-1 )
  end
  ----------------------------------------------------------------------
  Undo_BeginBlock2( 0 )
  main()
  Undo_EndBlock2( 0, 'Move selected tracks to the end of receives folder', 0xFFFFFFFF )