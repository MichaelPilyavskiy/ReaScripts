-- @description Sort selected tracks by color
-- @version 1.4.3
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
 
 
 
 
  function main()
  
    -- collect selected tracks
      tr_t = {}
      local cnt_seltr = CountSelectedTracks(0)
      if cnt_seltr == 0 then return end
      local tr = GetSelectedTrack(0,0)
      local insert_id = CSurf_TrackToID( tr, false ) 
              
      for i =1, cnt_seltr do
        local tr = GetSelectedTrack(0,i-1)
        tr_t[#tr_t+1] = {GUID = GetTrackGUID( tr ),
                        col = GetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR')}   
      end
    -- sort by col      
      table.sort(tr_t, function(a,b) return a.col<b.col end )
    
    for i = 1, #tr_t do
      --local tr = BR_GetMediaTrackByGUID( 0, tr_t[i].GUID )
      local tr = VF_GetMediaTrackByGUID( 0, tr_t[i].GUID )
      SetOnlyTrackSelected( tr )
      ReorderSelectedTracks(insert_id, 0)
    end
    
  end
  ------------------------------------------------------------------------------------------------------  
  function VF_GetMediaTrackByGUID(optional_proj, GUID)
    local optional_proj0 = optional_proj or 0
    for i= 1, CountTracks(optional_proj0) do tr = GetTrack(0,i-1 )if reaper.GetTrackGUID( tr ) == GUID then return tr end end
    local mast = reaper.GetMasterTrack( optional_proj0 ) if reaper.GetTrackGUID( mast ) == GUID then return mast end
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.78,true)  then 
    Undo_BeginBlock2( 0 )
    main() 
    Undo_EndBlock2( 0, "Sort all tracks by color", 0xFFFFFFFF )
  end 