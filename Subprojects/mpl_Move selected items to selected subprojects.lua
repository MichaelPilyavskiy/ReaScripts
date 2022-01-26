-- @description Move selected items to selected subprojects
-- @version 1.0
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    + init

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
      t[#t+1] = {ptr = item, GUID =  VF_GetItemGUID(item) , subproj = subproj, itemchunk = itemchunk}
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
  function VF_CheckFunctions(vrs) local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path) if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end  else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0)  if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end    end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(2.8) if ret then local ret2 = VF_CheckReaperVrs(5.95,true) if ret2 then
    Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    main(max_check, threshold_dB, minslicelen_sec, window_sec)
    PreventUIRefresh( -1 )
    Undo_EndBlock2( 0, 'mpl Move selected items to selected subprojects', -1 )
  end end