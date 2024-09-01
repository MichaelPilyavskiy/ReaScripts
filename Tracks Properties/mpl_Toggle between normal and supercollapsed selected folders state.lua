-- @description Toggle between normal and supercollapsed selected folders state
-- @version 1.01
-- @author MPL
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
    local tr = GetSelectedTrack(0,0)
    local state = GetMediaTrackInfo_Value( tr, 'I_FOLDERCOMPACT' )
    if state > 0 then state = 0 else state = 2 end
    SetMediaTrackInfo_Value( tr, 'I_FOLDERCOMPACT',state )
    
    for seltrackidx = 1,  CountSelectedTracks( 0 ) do
      local tr = GetSelectedTrack( 0, seltrackidx-1 ) 
      if GetMediaTrackInfo_Value( tr, 'I_FOLDERDEPTH') == 1 then
        SetMediaTrackInfo_Value( tr, 'I_FOLDERCOMPACT',state )
      end
    end
  end
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.975,true)then 
      Undo_BeginBlock2( 0 )
      main()
      Undo_EndBlock2( 0, 'Toggle between normal and supercollapsed selected folders state', -1 )
  end