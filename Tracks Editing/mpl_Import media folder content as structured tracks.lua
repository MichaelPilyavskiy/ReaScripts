-- @description Import media folder content as structured tracks
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
  function CollectFiles_GetDirFilesRecursive(dir, path_t)
    local sub_dirs_cnt = 0
    repeat
      local sub_dir = reaper.EnumerateSubdirectories(dir, sub_dirs_cnt)
      if sub_dir then 
        path_t[sub_dir] = {} 
        AddTrackSetOnlySelected(sub_dir, true)
        CollectFiles_GetFiles(dir..'/'..sub_dir, path_t[sub_dir])
        
        -- set last track
          local last_tr = GetSelectedTrack(0,0)
          SetMediaTrackInfo_Value( last_tr, 'I_FOLDERDEPTH',-1 ) 
        
        CollectFiles_GetDirFilesRecursive(dir..'/'..sub_dir, path_t[sub_dir])
      end
      sub_dirs_cnt = sub_dirs_cnt + 1
    until not sub_dir
    
  end
  -------------------------------------------------------------------
  function CollectFiles_GetFiles(dir, path_t)
    local i = 0
    repeat
      local file = reaper.EnumerateFiles(dir, i)
      if file then
        i = i + 1
        local fileext = file:match('.-%.(.*)')
        if IsMediaExtension( fileext, false ) then 
          path_t[#path_t+1] =  file 
          AddMediaToFile(dir..'/'..file)
        end
      end
    until not file
  end
  -------------------------------------------------------------------
  function AddMediaToFile(filepath)
    local curpos = GetCursorPosition()
    local new_tr = AddTrackSetOnlySelected()
    local item = AddMediaItemToTrack( new_tr )
    local take = AddTakeToMediaItem( item )
    if not take then return end
    local pcm_src = PCM_Source_CreateFromFileEx( filepath, false )
    if not pcm_src then return end
    SetMediaItemTake_Source( take, pcm_src )
    local retval, lengthIsQN = reaper.GetMediaSourceLength( pcm_src )
    SetMediaItemInfo_Value( item, 'D_POSITION' , curpos )
    SetMediaItemInfo_Value( item, 'D_LENGTH' , retval )
    SetOnlyTrackSelected( new_tr )
    local trname = filepath:reverse():match('(.-)[%\\/]'):reverse()
    GetSetMediaTrackInfo_String( new_tr, 'P_NAME', trname, 1 )
  end
  -------------------------------------------------------------------
  function AddTrackSetOnlySelected(trname0, isdir)
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
  function CollectFiles(dir)
    local files = {}
    AddTrackSetOnlySelected(nil,true)
    
    CollectFiles_GetDirFilesRecursive(dir, files, has_files)
    CollectFiles_GetFiles(dir, files) 
    
    -- set last track
      local last_tr = GetSelectedTrack(0,0)
      SetMediaTrackInfo_Value( last_tr, 'I_FOLDERDEPTH',-2 ) 
      
    return files
  end
  -------------------------------------------------------------------  
  if VF_CheckReaperVrs(5.95,true)  then
    local ret, dir = reaper.GetUserInputs('Paste source directory', 1, 'path,extrawidth=400', '')
    if not (ret and dir ~= '') then return end
    Undo_BeginBlock2( 0 )
    PreventUIRefresh( -1 )
    --dir = [[C:\Users\MPL_PC\Desktop\New folder]]
    local files = CollectFiles(dir)
    
    
    PreventUIRefresh( 1 )
    Undo_EndBlock2( 0, 'Import media as track structure', -1 )
  end 