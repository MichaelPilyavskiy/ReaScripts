-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @description List random impulse in directory for focused ReaVerb
-- @changelog
--    + search level up from parent folder
  
  local search_depth =3
  
  function GetFileList(cur_file_path)
    -- get search dir
      local cur_file_path = cur_file_path:gsub('\\', '/')
      local full_path = cur_file_path:match('"(.*)"')
      local search_path = full_path:match('(.*)[%/]')
      local i = 1
      local search_path_ready
      repeat
        search_path_ready = search_path
        search_path = search_path_ready:match('(.*)[%/]')
        i = i+1
      until i == search_depth or not search_path
    
    -- get files
      local subdir_id = 0
      local files = {}
      local dir
      repeat
        dir = reaper.EnumerateSubdirectories( search_path_ready, subdir_id )
        local file_id = 0 
        if dir then 
          repeat
            local file = reaper.EnumerateFiles( search_path_ready..'/'..dir, file_id )
            if file and file:match('%.wav') then files[#files+1] = search_path_ready..'/'..dir..'/'..file  end
            file_id = file_id+1
          until file == nil or file == ''
        end
        subdir_id = subdir_id+1
      until dir == nil or dir == ''
      
    return files
  end
------------------------------------------------------  
function main()
    local ret, tracknumberOut, _, fxnumberOut = reaper.GetFocusedFX()
    local track = reaper.CSurf_TrackFromID( tracknumberOut, false )
    if not track then return end
    local ret, fn0 = reaper.TrackFX_GetNamedConfigParm(track, fxnumberOut, "ITEM0")
    if not ret then return end
    
    local files = GetFileList(fn0)
    -- select file
      if #files < 2 then return end
      local trig_id = math.floor(math.random(#files-1))+1
      local trig_file = files[trig_id] 
      
      if trig_file then 
        trig_file = 'FILELDR "'..trig_file..'" 12'
        reaper.TrackFX_SetNamedConfigParm(track, fxnumberOut, "ITEM0", trig_file)
        reaper.TrackFX_SetNamedConfigParm(track, fxnumberOut, "DONE", "")
      end
  end


  reaper.Undo_BeginBlock()
  main(track)
  reaper.Undo_EndBlock('List random impulse in directory for focused ReaVerb', 1)