-- @description Move selected items to selected subprojects
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
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

  -------------------------------------------------------------------  
  function main(max_check, threshold_dB, minslicelen_sec, window_sec) 
    local currentproj = reaper.EnumProjects( 0) 
    t = {}
    -- collect and check selected items
      for i = 1, CountSelectedMediaItems(0) do
        local item = GetSelectedMediaItem(0,i-1)  
        local retval, itemchunk = reaper.GetItemStateChunk( item, '', false )
        local subproj
        if item then 
          local take =  GetActiveTake( item )
          if take then 
            local src = GetMediaItemTake_Source( take )
            subproj = GetSubProjectFromSource( src )
          end
        end
      local retval, GUID = reaper.GetSetMediaItemInfo_String( item, 'GUID', '', 0 )
      t[#t+1] = {ptr = item, GUID =  GUID , subproj = subproj, itemchunk = itemchunk}
      end
     
    -- share items to subprojects
      for i = 1 ,#t do
        if t[i].subproj == nil then  -- if item
        
          for j = 1, #t do  
            if t[j].subproj then  -- if subproj
                local reaproj =  t[j].subproj
                SelectProjectInstance( reaproj )
                InsertTrackAtIndex( CountTracks(0), false )
                 newtrid = CountTracks( 0 )
                local new_tr = GetTrack(0, newtrid -1)
                local new_it = AddMediaItemToTrack( new_tr )
                SetItemStateChunk( new_it, t[i].itemchunk, false )
                reaper.DeleteTrackMediaItem( GetMediaItemTrack( t[i].ptr ), t[i].ptr )
                SelectProjectInstance(currentproj )
            end
          end 
          
        end
      end
    
  end
  -------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.95,true)  then
    Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    main(max_check, threshold_dB, minslicelen_sec, window_sec)
    PreventUIRefresh( -1 )
    Undo_EndBlock2( 0, 'mpl Move selected items to selected subprojects', -1 )
  end 