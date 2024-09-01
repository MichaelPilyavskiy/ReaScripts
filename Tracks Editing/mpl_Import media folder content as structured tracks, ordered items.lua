-- @description Import media folder content as structured tracks, ordered items
-- @version 1.01
-- @author MPL
-- @website https://forum.cockos.com/showthread.php?t=188335
-- @about Scan folder media and add media items on named tracks obey paths structure
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
  function importstructure_AddMediaToFile(filepath, tr, pos)
    local curpos = pos or GetCursorPosition()
    local item = AddMediaItemToTrack( tr )
    local take = AddTakeToMediaItem( item )
    if not take then return end
    local pcm_src = PCM_Source_CreateFromFileEx( filepath, false )
    if not pcm_src then return end
    SetMediaItemTake_Source( take, pcm_src )
    local retval, lengthIsQN = reaper.GetMediaSourceLength( pcm_src )
    SetMediaItemInfo_Value( item, 'D_POSITION' , curpos )
    SetMediaItemInfo_Value( item, 'D_LENGTH' , retval )
    return pos + retval
  end
  -------------------------------------------------------------------
  function importstructure_AddTrackSetOnlySelected(trname0, isdir) 
    local trname = trname0 or 'Imported media'
    local track, id = GetSelectedTrack( 0, 0 ), 0
    if track then id =  CSurf_TrackToID( track, false ) end
    InsertTrackAtIndex( id, false )
    local new_tr = CSurf_TrackFromID( id+1, false )
    GetSetMediaTrackInfo_String( new_tr, 'P_NAME', trname, 1 )
    SetOnlyTrackSelected( new_tr )
    if isdir then 
      SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH',1 ) 
    end
    return new_tr
  end
  -------------------------------------------------------------------  
  function importstructure_ScanPath(files,path)-- modified https://forum.cockos.com/showpost.php?p=1991414&postcount=2
      
      local subdirindex, fileindex = 0,0    
      local path_child
      repeat
          path_child = reaper.EnumerateSubdirectories(path, subdirindex )
          if path_child then 
              files[path_child] = {}
              importstructure_ScanPath(files[path_child],path .. "/" .. path_child)
              fileindex = 0
              files[path_child].__files__ = {}
              repeat
                  fn = reaper.EnumerateFiles( path .. "/" .. path_child, fileindex )
                  if fn then table.insert(files[path_child].__files__, path .. "/" .. path_child..'/'..fn) end
                  fileindex = fileindex+1
              until not fn
          end
          subdirindex = subdirindex+1
      until not path_child  
  end
  -------------------------------------------------------------------  
  function importstructure_Add_files(files)
    importstructure_AddTrackSetOnlySelected(nil,true)
    local new_tr
    for path in spairs(files) do
      new_tr = importstructure_AddTrackSetOnlySelected(path, false)
      newpos = 0
      if files[path].__files__ then 
        for file in spairs(files[path].__files__) do
          newpos = importstructure_AddMediaToFile(files[path].__files__[file], new_tr, newpos)
        end
      end
    end
    if new_tr then SetMediaTrackInfo_Value( new_tr, 'I_FOLDERDEPTH',-1 )  end
  end
  -------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.95,true) if ret2 then
    local ret, dir = reaper.GetUserInputs('Paste source directory', 1, 'path,extrawidth=400', '')
    if not (ret and dir ~= '') then return end
    Undo_BeginBlock2( 0 )
    PreventUIRefresh( -1 )
    
    --dir = [[C:\Users\MPL_PC\Desktop\test]]
    files = {}
    importstructure_ScanPath(files,dir) 
    importstructure_Add_files(files)
    
    PreventUIRefresh( 1 )
    Undo_EndBlock2( 0, 'Import media as track structure', -1 )
  end