-- @description Rename items on selected tracks incrementally
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
  ---------------------------------------------------
  function main()
    for i = 1, CountSelectedTracks(0) do
      local track = GetSelectedTrack(0,i-1)
      retval, tr_name = reaper.GetTrackName( track )
      for itemidx=1, CountTrackMediaItems( track ) do
        local item = GetTrackMediaItem( track, itemidx-1 )
        local tk = GetActiveTake( item )
        if tk then
          GetSetMediaItemTakeInfo_String( tk, 'P_NAME', tr_name..'#'..itemidx, true )
        end
      end
    end
  end
  ----------------------------------------------------------------------
  if VF_CheckReaperVrs(6.68,true)then 
    Undo_BeginBlock2( 0 )
    main() 
    reaper.UpdateArrange()
    Undo_EndBlock2( 0, 'Rename items on selected tracks incrementally', 0xFFFFFFFF )
  end