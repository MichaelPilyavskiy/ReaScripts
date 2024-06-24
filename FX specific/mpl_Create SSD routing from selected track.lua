-- @description Create SSD routing from selected track
-- @version 1.0
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  --------------------------------------------------------------------------------------
  function main() 
    local track = GetSelectedTrack(0,0) 
    if not track then return end
    local trackID = reaper.CSurf_TrackToID( track, false )
    SetMediaTrackInfo_Value( track, 'I_NCHAN',48 )
    SetMediaTrackInfo_Value( track, 'B_MAINSEND',0 )
    local ret, srcname = GetSetMediaTrackInfo_String( track, 'P_NAME', '', false )
    
    
    local offs = 0
    for i = 1, 32 do
      reaper.InsertTrackAtIndex( trackID+offs, false )
      local dest_tr = GetTrack(0,trackID+offs) 
      offs=offs+1
      local new_id = CreateTrackSend( track, dest_tr )
      if i <= 16 then
        
        GetSetMediaTrackInfo_String( dest_tr, 'P_NAME', 'out '..i..' st', true )
        SetTrackSendInfo_Value( track, 0, new_id, 'I_SRCCHAN', (i-1)*2)
       else 
        GetSetMediaTrackInfo_String( dest_tr, 'P_NAME', 'out '..i..' mn', true )
        SetTrackSendInfo_Value( track, 0, new_id, 'I_SRCCHAN', (31 + i-16)|1024)
      end
    end
    
    
    InsertTrackAtIndex( trackID-1, false )
    local par_tr = GetTrack(0,trackID-1) 
    SetMediaTrackInfo_Value( par_tr, 'I_FOLDERDEPTH',1 )
    SetMediaTrackInfo_Value( par_tr, 'I_FOLDERCOMPACT',2 )
    GetSetMediaTrackInfo_String( par_tr, 'P_NAME', srcname, true )
    local last_tr = GetTrack(0,trackID+32) 
    SetMediaTrackInfo_Value( last_tr, 'I_FOLDERDEPTH',-1 )
    GetSetMediaTrackInfo_String( track, 'P_NAME', srcname..' (src)', true )
  end

  
    Undo_BeginBlock()
    reaper.PreventUIRefresh( 1 )
    main()
    reaper.PreventUIRefresh( -1 )
    Undo_EndBlock('Create SSD routing', 0xFFFFFF)  
  