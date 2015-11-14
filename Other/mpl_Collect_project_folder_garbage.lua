  script_title = "mpl Collect project folder garbage"  
  reaper.Undo_BeginBlock()

  ret = reaper.MB('Do you want to collect current project folder garbage (NO UNDO) ?',
     'Collect project folder garbage', 1)
  -----------------------------------------------
  
    function cut_file(src_path, dest_path)    
    -- get src
    file = io.open (src_path, 'r')
    if file ~= nil then
      content = file:read("*all")
      io.close (file)
      -- write copy to dst
      file = io.open (dest_path, 'w')
      file:write(content)
      io.close (file)
      -- remove
      os.remove(src_path)
    end
  end
  
  -----------------------------------------------
  
  function move_by_ext(filename, ext, dest_folder)
    if filename ~= nil then
      filename_len = string.len(filename)
      filename_L = string.lower(filename)
      ext_L = string.lower(ext)
      st_find0, st_find = string.find(filename_L, ext_L)
      
      if st_find == filename_len then
        cut_file(project_path..'/'..filename, project_path..dest_folder..'/'..filename) 
      end
    end    
  end
  
  -----------------------------------------------
    
  project_path = reaper.GetProjectPath("")
  _, project_name = reaper.EnumProjects(-1, '')
  project_path = string.gsub(project_path, "\\", '/')
  project_name = string.gsub(project_name, "\\", '/')
    reaper.RecursiveCreateDirectory(project_path..'/Backup/', 1)
    reaper.RecursiveCreateDirectory(project_path..'/Audio/', 1)
    reaper.RecursiveCreateDirectory(project_path..'/MIDI/', 1)
    reaper.RecursiveCreateDirectory(project_path..'/Old versions/', 1)
    reaper.RecursiveCreateDirectory(project_path..'/Peaks/', 1)
        
  -----------------------------------------------
  
  i = 1
  files = {}
  repeat
    str_address = reaper.EnumerateFiles(project_path, i-1)
    files[i] = str_address
    i = i + 1
  until str_address == nil
  
  -----------------------------------------------
  t1 = {}
  if files ~= nil then
    for i = 1, #files do
      
      -- Reaper stuff
        move_by_ext(files[i], 'reapeaks', '/Peaks')
        move_by_ext(files[i], '-bak', '/Backup')
        if project_path..'/'..files[i] ~= project_name then
          move_by_ext(files[i], '.RPP', '/Old versions') end
        
      -- Other stuff
        move_by_ext(files[i], '.wav', '/Audio')
        move_by_ext(files[i], '.flac','/Audio') 
        move_by_ext(files[i], '.ogg', '/Audio')  
        move_by_ext(files[i], '.mp3', '/Audio')      
        move_by_ext(files[i], '.mid', '/MIDI')
        move_by_ext(files[i], '.midi','/MIDI')
    end
  end
  
  -----------------------------------------------
  
  reaper.Undo_EndBlock(script_title, 1)
  
